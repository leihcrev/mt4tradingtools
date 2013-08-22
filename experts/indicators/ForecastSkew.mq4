// ForecastSkew
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 3

#property indicator_maximum  0.1
#property indicator_minimum -0.1

#property indicator_color1 White
#property indicator_width1 1

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>

// Input parameters
extern double ThresholdTick   = 0.00005;
extern int    Thresholds      = 100;
extern int    MaxBars         = 28800;

// Variables
double   threshold[0];
int      mode[0];
double   overshootLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
double   evenOvershootLevel[0];
double   skewness[0];
bool     reliable[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

int      reliables = 0.0;

double   ReverseNapier;

// Buffers
double Skewness[];
double Accuracy[];
double Continuity[];

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(evenOvershootLevel, Thresholds);
  ArrayResize(skewness, Thresholds);
  ArrayResize(reliable, Thresholds);

  IndicatorShortName("ForecastSkew");

  IndicatorDigits(8);

  SetIndexLabel(0, "Skewness");
  SetIndexBuffer(0, Skewness);
  SetIndexLabel(1, "Accuracy");
  SetIndexBuffer(1, Accuracy);
  SetIndexStyle(1, DRAW_NONE);
  SetIndexLabel(2, "Continuity");
  SetIndexBuffer(2, Continuity);
  SetIndexStyle(2, DRAW_NONE);

  for (int th = 0; th < Thresholds; th++) {
    threshold[th] = ThresholdTick * (th + 1);
  }

  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);

  ReverseNapier = 1.0 / MathExp(1.0);

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double spread = Ask - Bid;

  if (!isInitialized) {
    isInitialized = true;
    SetLevelValue(0, spread);
    SetLevelValue(1, -spread);
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
        UpdateDCOS(prices[j]);
      }
      UpdateBuffer(i, Close[i], spread);
    }
  }

  double x = (Bid + Ask) / 2.0;
  UpdateDCOS(x);
  UpdateBuffer(0, x, spread);

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

void UpdateDCOS(double x) {
  for (int th = 0; th < Thresholds; th++) {
    double currentLevel;
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        mode[th] = 1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        currentLevel = 0.0;
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
        evenOvershootLevel[th] = GetEvenOvershootLevel(th);
      }
      else {
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
          evenOvershootLevel[th] = GetEvenOvershootLevel(th);
        }
      }
    } // end if (mode[th] == -1)
    else {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
        mode[th] = -1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        currentLevel = 0.0;
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
        evenOvershootLevel[th] = GetEvenOvershootLevel(th);
      }
      else {
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
          evenOvershootLevel[th] = GetEvenOvershootLevel(th);
        }
      }
    } // end else (mode[th] == -1)
    if (reliable[th]) {
      double DCDistance = 1.0 + currentLevel - overshootLevel[th];
      double OSDistance = DCDistance * (evenOvershootLevel[th] - overshootLevel[th]);
      skewness[th] = mode[th] * (OSDistance - DCDistance) / 2.0;
    }
    else {
      skewness[th] = 0.0;
    }
  }
}

double GetEvenOvershootLevel(int th) {
  double p = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th]);
  return(OvershootECDF_MultiReverseRefer(th, index, level, count, 1.0 - (1.0 - p) * ReverseNapier));
}

void UpdateBuffer(int i, double x, double spread) {
  int updown = 0;
  Skewness[i] = 0;
  for (int th = 0; th < Thresholds; th++) {
    if (x * threshold[th] < spread) {
      continue;
    }
    if (updown > 0) {
      if (skewness[th] < 0.0) {
        break;
      }
    }
    else if (updown < 0.0) {
      if (skewness[th] > 0.0) {
        break;
      }
    }
    else {
      if (skewness[th] > 0.0) {
        updown = 1;
      }
      else if (skewness[th] < 0.0) {
        updown = -1;
      }
    }
    double s = skewness[th] * threshold[th] * x;
    if (updown * s > updown * Skewness[i]) {
      Skewness[i] = s;
    }
  }
  Accuracy[i] = 100.0 * reliables / Thresholds;
  Continuity[i] = th;
}

