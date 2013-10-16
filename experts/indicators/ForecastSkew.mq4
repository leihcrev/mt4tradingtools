// ForecastSkew
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#define INDICATOR_NAME "ForecastSkew"

#property indicator_separate_window
#property indicator_buffers 8

#property indicator_level1 1
#property indicator_level2 -1

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>
#include <LambertW.mqh>

#define Thresholds 8

// Input parameters
extern double Threshold1   = 0.00265;
extern double Threshold2   = 0.00133;
extern double Threshold3   = 0.00067;
extern double Threshold4   = 0.00034;
extern double Threshold5   = 0.00017;
extern double Threshold6   = 0.00009;
extern double Threshold7   = 0.00005;
extern double Threshold8   = 0.00003;
extern double ForecastTick = 0.01;
extern int    MaxBars      = 28800;

// Variables
double   threshold[0];
int      mode[0];
double   overshootLevel[0];
double   currentLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
bool     reliable[0];
double   xAtOSL0[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

int      reliables = 0.0;

color    colors[] = {
  C'0x77, 0x77, 0xff',
  C'0x77, 0xdd, 0xff',
  C'0x77, 0xff, 0xdd',
  C'0x77, 0xff, 0xbb',
  C'0xbb, 0xff, 0x77',
  C'0xbb, 0xff, 0x77',
  C'0xff, 0xbb, 0x77',
  C'0xff, 0x77, 0x77'
};

// Buffers
double Skewness1[];
double Skewness2[];
double Skewness3[];
double Skewness4[];
double Skewness5[];
double Skewness6[];
double Skewness7[];
double Skewness8[];

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(currentLevel, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(reliable, Thresholds);
  ArrayResize(xAtOSL0, Thresholds);

  IndicatorShortName(INDICATOR_NAME);

  IndicatorDigits(8);

  SetIndexBuffer(0, Skewness1);
  SetIndexBuffer(1, Skewness2);
  SetIndexBuffer(2, Skewness3);
  SetIndexBuffer(3, Skewness4);
  SetIndexBuffer(4, Skewness5);
  SetIndexBuffer(5, Skewness6);
  SetIndexBuffer(6, Skewness7);
  SetIndexBuffer(7, Skewness8);

  threshold[0] = Threshold1;
  threshold[1] = Threshold2;
  threshold[2] = Threshold3;
  threshold[3] = Threshold4;
  threshold[4] = Threshold5;
  threshold[5] = Threshold6;
  threshold[6] = Threshold7;
  threshold[7] = Threshold8;

  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);

  for (int th = 0; th < Thresholds; th++) {
    double ECDFBase = OvershootECDF_MultiRefer(th, index, level, count, 0.0);
    double ECDFTarget = OvershootECDF_MultiRefer(th, index, level, count, 1.0);
    double OSP = (1.0 - ECDFTarget) / (1.0 - ECDFBase);
    xAtOSL0[th] = (1.0 - OSP) / OSP;

    SetIndexLabel(th, "Skew(" + DoubleToStr(threshold[th] * 100, 3) + "%)");
    SetIndexStyle(th, DRAW_HISTOGRAM, STYLE_SOLID, 3, colors[th]);
  }

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
    InitializePrintVariables();
  }

  UpdateDCOS(0, (Bid + Ask) / 2.0, spread);

  PrintVariables();

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
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        mode[th] = 1;
        dcPrice[th] = extremaPrice[th] * (1.0 + threshold[th]);
        extremaPrice[th] = x;
        currentLevel[th] = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel[th];
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
      }
      else {
        currentLevel[th] = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel[th]) {
          overshootLevel[th] = currentLevel[th];
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
        currentLevel[th] = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel[th];
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
      }
      else {
        currentLevel[th] = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel[th]) {
          overshootLevel[th] = currentLevel[th];
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
  CalculateSkewness(Skewness1, 0, i, OSP, x, spread);
  CalculateSkewness(Skewness2, 1, i, OSP, x, spread);
  CalculateSkewness(Skewness3, 2, i, OSP, x, spread);
  CalculateSkewness(Skewness4, 3, i, OSP, x, spread);
  CalculateSkewness(Skewness5, 4, i, OSP, x, spread);
  CalculateSkewness(Skewness6, 5, i, OSP, x, spread);
  CalculateSkewness(Skewness7, 6, i, OSP, x, spread);
  CalculateSkewness(Skewness8, 7, i, OSP, x, spread);
}

double GetOSP(int th) {
  double ECDFBase = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th]);
  double ECDFTarget = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th] + 1.0);
  if (ECDFBase == 1.0) {
    return(0.0);
  }

  double OSP = (1.0 - ECDFTarget) / (1.0 - ECDFBase);
  double x = (1.0 - OSP) / OSP;
  if (true) {
    x = MathPow(x / xAtOSL0[th], currentLevel[th] - overshootLevel[th] + 1.0) * xAtOSL0[th];
  }
  OSP = 1.0 / (x + 1.0);
  return(OSP);
}

void CalculateSkewness(double &Skewness[], int th, int i, double &OSP[], double price, double spread) {
  Skewness[i] = CalculateProbability(price / ForecastTick * threshold[th], OSP[th]);
  if (mode[th] == -1) {
    Skewness[i] = 1.0 - Skewness[i];
  }
  Skewness[i] -= 0.5;

  // Normalize [(spread / 2) / (x * threshold)] to 1.0
  Skewness[i] /= (spread / 2.0) / (price * threshold[th]);
}

/**
 * ニュートン法で確率を逆算する.
 */
double CalculateProbability(double N, double OSP) {
  static double eInv = 0.36787944; // MathExp(-1);

  double C = MathPow(OSP, 1.0 / N);
  if (C == N / (N + 1)) {
    return(0.5);
  }

  double x;
  if (OSP > eInv) {
    x = 4999.0 / 5001.0;
  }
  else {
    x = 5001.0 / 4999.0;
  }
  double d = f(x, N, C) / fd(x, N);
  while (MathAbs(d) > 0.00000001) {
    x -= d;
    if (x <= 0) {
      Print("Negative x detected: x=", x, ", N=", N, ", OSP=", OSP);
      return(1.0);
    }
    if (x == 1) {
      Print("x == 1: N=", N, ", OSP=", OSP);
      return(0.5);
    }
    double fd = fd(x, N);
    d = f(x, N, C) / fd;
  }
  return(1.0 / (x + 1.0));
}

/**
 * 確率変換関数.
 */
double f(double x, double N, double C) {
  double xN = MathPow(x, N);
  double xNPlus1 = xN * x;
  return((1 - xN) / (1 - xNPlus1) - C);
}

/**
 * 確率変換関数の1階微分.
 */
double fd(double x, double N) {
  double xNMinus1 = MathPow(x, N - 1);
  double xN = xNMinus1 * x;
  double xNPlus1 = xN * x;
  double dividend = xNMinus1 * (N * (x - 1) - x * (xN - 1));
  return(dividend / (xNPlus1 - 1) / (xNPlus1 - 1));
}

#define OBJNAME_PREF "ForecastSkew_"

void InitializePrintVariables() {
  for (int th = 0; th < Thresholds; th++) {
    string objname = OBJNAME_PREF + (th + 1);
    ObjectCreate(objname, OBJ_LABEL, WindowFind(INDICATOR_NAME), 0, 0);
    ObjectSet(objname, OBJPROP_XDISTANCE, 0);
    ObjectSet(objname, OBJPROP_YDISTANCE, 12 * (th + 1) + 6);
  }
}

void PrintVariables() {
  double max = WindowPriceMax(WindowFind(INDICATOR_NAME));
  double min = WindowPriceMin(WindowFind(INDICATOR_NAME));
  double d = (max - min) / (Thresholds + 1);
  for (int th = 0; th < Thresholds; th++) {
    string objname = OBJNAME_PREF + (th + 1);
    string text = DoubleToStr(threshold[th] * 100, 3) + "%:";
    if (mode[th] == 1) {
      text = text + "+/";
    }
    else {
      text = text + "-/";
    }
    text = text + DoubleToStr(overshootLevel[th], 2) + "/";
    if (currentLevel[th] > 0) {
      text = text + " ";
    }
    text = text + DoubleToStr(currentLevel[th], 2);
    ObjectSetText(objname, text, 8, "Lucida Console", colors[th]);
  }
}

