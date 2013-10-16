// WinningRatio
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#define INDICATOR_NAME "WinningRatio"

#property indicator_separate_window
#property indicator_buffers 6

#property indicator_minimum 0
#property indicator_maximum 1
#property indicator_level1 0.5

#property indicator_color1 White
#property indicator_color2 Blue
#property indicator_color3 Lime
#property indicator_color4 Lime
#property indicator_color5 Red
#property indicator_color6 Red

#property indicator_style2 2
#property indicator_style3 2
#property indicator_style4 2
#property indicator_style5 2
#property indicator_style6 2

#include <IndicatorUtils.mqh>
#include <DirectionalChange.mqh>
#include <OvershootECDF.mqh>
#include <LambertW.mqh>

// Input parameters
extern double Threshold      = 0.00265;
extern double ExpectedProfit = 0.02;
extern int    MaxBars        = 28800;

// Variables
double   threshold[1];
int      mode[1];
double   overshootLevel[1];
double   currentLevel[1];
double   extremaPrice[1];
double   dcPrice[1];
bool     isInitialized = false;

double   level[0];
int      count[0];

double   ECDFBase;

// Buffers
double WinningRatio[];
double ForecastHeight[];
double LongEntryLine[];
double ShortEntryLine[];
double LongExitLine[];
double ShortExitLine[];

int init() {
  IndicatorShortName(INDICATOR_NAME);

  IndicatorDigits(8);
  
  SetIndexBuffer(0, WinningRatio);
  SetIndexLabel(0, "WinningRatio");
  SetIndexBuffer(1, ForecastHeight);
  SetIndexLabel(1, "ForecastHeight");
  SetIndexBuffer(2, LongEntryLine);
  SetIndexLabel(2, "LongEntryLine");
  SetIndexBuffer(3, ShortEntryLine);
  SetIndexLabel(3, "ShortEntryLine");
  SetIndexBuffer(4, LongExitLine);
  SetIndexLabel(4, "LongExitLine");
  SetIndexBuffer(5, ShortExitLine);
  SetIndexLabel(5, "ShortExitLine");

  threshold[0] = Threshold;
  OvershootECDF_Read(Symbol(), Threshold, level, count);

  if (Bars < MaxBars) {
    Print("MaxBars is modified. (", MaxBars, " -> ", Bars, ")");
    MaxBars = Bars;
  }
  Print("WinningRatio(", DoubleToStr(Threshold, 8), ", ", DoubleToStr(ExpectedProfit, 8), ", ", MaxBars, ") initialized.");
  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double spread = Ask - Bid;
  if (spread == 0.0) {
    Print("spread is zero!");
  }
  if (!isInitialized) {
    isInitialized = true;

    mode[0] = 0;
    overshootLevel[0] = 0.0;
    extremaPrice[0] = MathLog(High[MaxBars - 1] + spread / 2.0);
    dcPrice[0] = extremaPrice[0];
    ECDFBase = OvershootECDF_Refer(level, count, overshootLevel[0]);

    Print("DCOS initializing. (threshold=", DoubleToStr(threshold[0], 8), ", mode=", mode[0], ", overshootLevel=", overshootLevel[0], ", currentLevel=", currentLevel[0], ", dcPrice=", DoubleToStr(dcPrice[0], 8), ", extremaPrice=", DoubleToStr(extremaPrice[0], 8), ")");
    for (int i = MaxBars - 1; i >= 0; i--) {
      double prices[4];
      GetPricesFromBar(prices, i, spread);
      for (int j = 0; j < 4; j++) {
        if (UpdateDCStatus(MathLog(prices[j]), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel)) {
          ECDFBase = OvershootECDF_Refer(level, count, overshootLevel[0]);
        }
        UpdateBuffer(i, prices[j], spread);
      }
    }
    Print("DCOS initialized. (threshold=", DoubleToStr(threshold[0], 8), ", mode=", mode[0], ", overshootLevel=", overshootLevel[0], ", currentLevel=", currentLevel[0], ", dcPrice=", DoubleToStr(dcPrice[0], 8), ", extremaPrice=", DoubleToStr(extremaPrice[0], 8), ")");
  }

  double mid = (Bid + Ask) / 2.0;
  if (UpdateDCStatus(MathLog(mid), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel)) {
    ECDFBase = OvershootECDF_Refer(level, count, overshootLevel[0]);
  }
  UpdateBuffer(i, mid, spread);

  return(0);
}

void UpdateBuffer(int i, double x, double spread) {
  ForecastHeight[i] = currentLevel[0] - overshootLevel[0] + 1.0;
  double ECDFTarget = OvershootECDF_Refer(level, count, overshootLevel[0] + ForecastHeight[i]);
  double OSP = MathPow((1.0 - ECDFTarget) / (1.0 - ECDFBase), 1.0 / ForecastHeight[i]);
  double logOSP = MathLog(OSP);
  double lamb;
  if (OSP == MathExp(-1)) {
    WinningRatio[i] = 0.5;
  }
  else {
    if (OSP < MathExp(-1)) {
      lamb = LambertW0(OSP * logOSP);
    }
    else {
      lamb = LambertWm1(OSP * logOSP);
    }
    WinningRatio[i] = 1.0 / (MathPow(logOSP / lamb, ForecastHeight[i]) + 1.0);
    if (mode[0] == -1) {
      WinningRatio[i] = 1.0 - WinningRatio[i];
    }
  }

  double d = (ExpectedProfit + spread) / Threshold / ForecastHeight[i] / 2.0 / x;
  if (d > 0.5) {
    d = 0.5;
  }
  LongEntryLine[i] = 0.5 + d;
  ShortEntryLine[i] = 0.5 - d;

  d = spread / Threshold / ForecastHeight[i] / 2.0 / x;
  LongExitLine[i] = 0.5 + d;
  ShortExitLine[i] = 0.5 - d;
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

