// WinningRatioMultiLevel
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#define INDICATOR_NAME "WinningRatioMultiLevel"

#property indicator_separate_window
#property indicator_buffers 7

#property indicator_level1 0.5

#property indicator_color1 Gray
#property indicator_color2 Yellow
#property indicator_color3 White
#property indicator_color4 Red
#property indicator_color5 Red
#property indicator_color6 Lime
#property indicator_color7 Lime

#property indicator_style4 2
#property indicator_style5 2
#property indicator_style6 2
#property indicator_style7 2

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>
#include <LambertW.mqh>

// Input parameters
extern double BaseThreshold = 0.00265;
extern double ThresholdTick = 0.00053;
extern double Thresholds    = 11;
extern int    MaxBars       = 28800;

// Variables
double   threshold[0];
int      mode[0];
double   overshootLevel[0];
double   currentLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
bool     reliable[0];
double   h[0];
double   xAtOSL0[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

int      reliables = 0.0;

datetime latest = 0;

// Buffers
double WinningRatioBase[];
double WinningRatioAverage[];
double WinningRatioReliable[];
double LongFavorLine[];
double ShortFavorLine[];
double WinningRatioMin[];
double WinningRatioMax[];

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(currentLevel, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(reliable, Thresholds);
  ArrayResize(h, Thresholds);
  ArrayResize(xAtOSL0, Thresholds);

  IndicatorShortName(INDICATOR_NAME);

  IndicatorDigits(8);
  
  SetIndexBuffer(0, WinningRatioBase);
  SetIndexLabel(0, "WR(BaseThreshold)");
  SetIndexBuffer(1, WinningRatioAverage);
  SetIndexLabel(1, "WR(Average)");
  SetIndexBuffer(2, WinningRatioReliable);
  SetIndexLabel(2, "WR(Most reliable)");
  SetIndexBuffer(3, LongFavorLine);
  SetIndexLabel(3, "LongFavorLine");
  SetIndexBuffer(4, ShortFavorLine);
  SetIndexLabel(4, "ShortFavorLine");
  SetIndexBuffer(5, WinningRatioMin);
  SetIndexLabel(5, "WR(min)");
  SetIndexBuffer(6, WinningRatioMax);
  SetIndexLabel(6, "WR(max)");

  int th;
  for (th = 0; th < Thresholds; th++) {
    threshold[th] = BaseThreshold + ThresholdTick * th;
  }
  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);
  for (th = 0; th < Thresholds; th++) {
    h[th] = BaseThreshold / threshold[th];

    double BaseWinningRatio = CalculateWinningRatio(th, 0);
    xAtOSL0[th] = BaseWinningRatio / (1.0 - BaseWinningRatio);
  }

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double spread = Ask - Bid;

  if (!isInitialized) {
    isInitialized = true;
    latest = Time[0];
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

  latest = Time[0];

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
  double wrf[0];
  ArrayResize(wrf, Thresholds);
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
    wrf[th] = CalculateWinningRatioFixed(th);
  }
  UpdateWinningRatioBuffer(i, wrf);
  UpdateFavorLine(i, x, spread);
}

double CalculateWinningRatioFixed(int th) {
  double winningRatio = CalculateWinningRatio(th, overshootLevel[th]);

  double x = (1.0 - winningRatio) / winningRatio;
  x = MathPow(x / xAtOSL0[th], currentLevel[th] - overshootLevel[th] + 1.0) * xAtOSL0[th];
  winningRatio = 1.0 / (x + 1.0);

  if (mode[th] == -1) {
    winningRatio = 1.0 - winningRatio;
  }
  return(winningRatio);
}

double CalculateWinningRatio(int th, double l) {
  double ECDFBase = OvershootECDF_MultiRefer(th, index, level, count, l);
  double ECDFTarget = OvershootECDF_MultiRefer(th, index, level, count, l + h[th]);
  double OSP = MathPow((1.0 - ECDFTarget) / (1.0 - ECDFBase), 1.0 / h[th]);
  double logOSP = MathLog(OSP);
  double lamb;
  if (OSP < MathExp(-1)) {
    lamb = LambertW0(OSP * logOSP);
  }
  else {
    lamb = LambertWm1(OSP * logOSP);
  }
  return(1.0 / (MathPow(logOSP / lamb, h[th]) + 1.0));
}

void UpdateWinningRatioBuffer(int i, double &wrf[]) {
  double min = 1.0;
  double max = 0.0;
  double avg = 0.0;
  double samples = 0.0;
  double maxs = 0.0;
  double maxp = 0.0;
  for (int th = 0; th < Thresholds; th++) {
    if (!reliable[th]) {
      continue;
    }
    if (wrf[th] < min) {
      min = wrf[th];
    }
    if (wrf[th] > max) {
      max = wrf[th];
    }
    double lambda = overshootLevel[th] - currentLevel[th];
    if (lambda > 1.0 - h[th]) {
      continue;
    }
    double s = count[index[th] - 1] * (1.0 - OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th]));
    avg += wrf[th] * s;
    samples += s;
    if (s > maxs) {
      maxs = s;
      maxp = wrf[th];
    }
    if (latest != Time[0]) {
      Print("threshold[", th , "]=", threshold[th], "/s=", s);
    }
  }
  if (samples == 0.0) {
    avg = 0.5;
    maxp = 0.5;
  }
  else {
    avg /= samples;
  }

  WinningRatioMin[i] = min;
  WinningRatioMax[i] = max;
  WinningRatioBase[i] = wrf[0];
  WinningRatioAverage[i] = avg;
  WinningRatioReliable[i] = maxp;
}

void UpdateFavorLine(int i, double x, double spread) {
  double d = spread / BaseThreshold / 2.0 / x;
  LongFavorLine[i] = 0.5 + d;
  ShortFavorLine[i] = 0.5 - d;
}

