// ForecastSkew
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 1

#property indicator_level1 0.5

#property indicator_color1 White
#property indicator_width1 1

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>

// Input parameters
extern double ThresholdStart  = 0.0002;
extern double ThresholdTick   = 0.0002;
extern int    Thresholds      = 10;
extern double ForecastTick    = 0.01;
extern double TargetWidth     = 2.0;
extern int    MaxBars         = 14400; // 28800;

// Variables
double   threshold[0];
int      mode[0];
double   overshootLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
bool     reliable[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

int      reliables = 0.0;

// Buffers
double Skewness[];
double OvershootProbability[];

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(reliable, Thresholds);

  IndicatorShortName("ForecastSkew");

  IndicatorBuffers(2);
  IndicatorDigits(8);

  SetIndexLabel(0, "Skewness");
  SetIndexBuffer(0, Skewness);
  SetIndexLabel(1, "OvershootProbability");
  SetIndexBuffer(1, OvershootProbability);
  SetIndexStyle(1, DRAW_NONE);

  for (int th = 0; th < Thresholds; th++) {
    threshold[th] = ThresholdStart + ThresholdTick * th;
  }

  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  static double spread;

  if (!isInitialized) {
    isInitialized = true;
    spread = Ask - Bid;
    for (int th = 0; th < Thresholds; th++) {
      mode[th] = 0;
      overshootLevel[th] = 0.0;
      extremaPrice[th] = High[MaxBars - 1] + spread / 2.0;
      dcPrice[th] = extremaPrice[th];
    }

    for (int i = MaxBars - 1; i >= 0; i--) {
      double prices[4];
      GetPricesFromBar(prices, i, spread);
      for (int j = 0; j < 4; j++) {
        UpdateDCOS(i, prices[j], spread);
      }
    }
  }

  UpdateDCOS(0, (Bid + Ask) / 2.0, spread);

  return(0);
}

void GetPricesFromBar(double &prices[], int i, double spread) {
  spread /= 2.0;
  prices[0] = Open[i] + spread;
  prices[3] = Close[i] + spread;
  if (Open[i] < Close[i]) {
    prices[1] = Low[i] + spread;
    prices[2] = High[i] + spread;
  }
  else {
    prices[1] = High[i] + spread;
    prices[2] = Low[i] + spread;
  }
}

void UpdateDCOS(int i, double x, double spread) {
  double OSP[0];
  ArrayResize(OSP, Thresholds);
  for (int th = 0; th < Thresholds; th++) {
    double currentLevel;
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        mode[th] = 1;
        dcPrice[th] = extremaPrice[th] * (1.0 + threshold[th]);
        extremaPrice[th] = x;
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
      }
      else {
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    } // end if (mode[th] == -1)
    else {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
        mode[th] = -1;
        dcPrice[th] = extremaPrice[th] * (1.0 - threshold[th]);
        extremaPrice[th] = x;
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
      }
      else {
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    } // end else (mode[th] == -1)

    // Calculate Skewness
    if (reliable[th]) {
      OSP[th] = GetOSP(th);
    }
    else {
      OSP[th] = MathExp(-1.0);
    }
  }
  CalculateSkewness(i, OSP, x, spread);
}

double GetOSP(int th) {
  double ECDFBase = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th]);
  double ECDFTarget = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th] + 1.0);
  double OSP;
  if (ECDFBase == 1.0) {
    OSP = 0.0;
  }
  else {
    OSP = (1.0 - ECDFTarget) / (1.0 - ECDFBase);
  }
  return(OSP);
}

void CalculateSkewness(int i, double &OSP[], double price, double spread) {
  Skewness[i] = 0.0;
  OvershootProbability[i] = 0.0;
  for (int th = 0; th < Thresholds; th++) {
    double p = CalculateProbability(price / ForecastTick * threshold[th], OSP[th]);
    if (mode[th] == -1) {
      p = 1.0 - p;
    }
    Skewness[i] += p;
    OvershootProbability[i] += OSP[th];
  }
  Skewness[i] /= Thresholds;
  OvershootProbability[i] /= Thresholds;
}

double CalculateProbability(double N, double OSP) {
  double C = MathPow(OSP, 1.0 / N);
  if (C == N / (N + 1)) {
    return(0.5);
  }

  double x;
  if (OSP > MathExp(-1)) {
    x = 4999.0 / 5001.0;
  }
  else {
    x = 5001.0 / 4999.0;
  }
  double d = f(x, N, C) / fd(x, N);
  while (MathAbs(d) > 0.00000001) {
    x -= d;
    if (x <= 0) {
      return(1.0);
    }
    if (x == 1) {
      return(0.5);
    }
    double fd = fd(x, N);
    d = f(x, N, C) / fd;
  }
  return(1.0 / (x + 1.0));
}

double f(double x, double N, double C) {
  double xN = MathPow(x, N);
  double xNPlus1 = xN * x;
  return((1 - xN) / (1 - xNPlus1) - C);
}

double fd(double x, double N) {
  double xNMinus1 = MathPow(x, N - 1);
  double xN = xNMinus1 * x;
  double xNPlus1 = xN * x;
  double dividend = xNMinus1 * (N * (x - 1) - x * (xN - 1));
  return(dividend / (xNPlus1 - 1) / (xNPlus1 - 1));
}

