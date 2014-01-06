// WinningRatio
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#define INDICATOR_NAME "WinningRatio"

#property indicator_separate_window
#property indicator_buffers 1

#property indicator_maximum 0.6
#property indicator_minimum 0.4
#property indicator_level1 0.5

#property indicator_color1 White

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
extern int    MaxBars        = 28800;

// Variables
double   threshold[1];
int      mode[1];
double   overshootLevel[1];
double   currentLevel[1];
double   extremaPrice[1];
double   dcPrice[1];
double   drawdown;
bool     isInitialized = false;

double   level[0];
int      count[0];

double   Height;
double   HeightInv;

// Buffers
double WinningRatio[];

int init() {
  IndicatorShortName(INDICATOR_NAME);

  IndicatorDigits(8);
  
  SetIndexBuffer(0, WinningRatio);
  SetIndexLabel(0, "WinningRatio");

  threshold[0] = Threshold;
  OvershootECDF_Read(Symbol(), Threshold, level, count);

  if (Bars < MaxBars) {
    Print("MaxBars is modified. (", MaxBars, " -> ", Bars, ")");
    MaxBars = Bars;
  }
  
  Height = 1.0 - MathExp(-1.0);
  HeightInv = 1.0 / Height;

  Print("WinningRatio(", DoubleToStr(Threshold, 8), ", ", MaxBars, ") initialized.");
  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double spread = Ask - Bid;

  if (!isInitialized) {
    isInitialized = true;

    mode[0] = 0;
    overshootLevel[0] = 0.0;
    extremaPrice[0] = MathLog(High[MaxBars - 1] + spread / 2.0);
    dcPrice[0] = extremaPrice[0];

    Print("DCOS initializing. (threshold=", DoubleToStr(threshold[0], 8), ", mode=", mode[0], ", overshootLevel=", overshootLevel[0], ", currentLevel=", currentLevel[0], ", dcPrice=", DoubleToStr(dcPrice[0], 8), ", extremaPrice=", DoubleToStr(extremaPrice[0], 8), ")");
    for (int i = MaxBars - 1; i >= 0; i--) {
      double prices[4];
      GetPricesFromBar(prices, i, spread);
      for (int j = 0; j < 4; j++) {
        UpdateDCStatus(MathLog(prices[j]), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel);
        UpdateBuffer(i, prices[j], spread);
      }
    }
    Print("DCOS initialized. (threshold=", DoubleToStr(threshold[0], 8), ", mode=", mode[0], ", overshootLevel=", overshootLevel[0], ", currentLevel=", currentLevel[0], ", dcPrice=", DoubleToStr(dcPrice[0], 8), ", extremaPrice=", DoubleToStr(extremaPrice[0], 8), ")");
  }

  double mid = (Bid + Ask) / 2.0;
  UpdateDCStatus(MathLog(mid), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel);
  UpdateBuffer(i, mid, spread);

  return(0);
}

void UpdateBuffer(int i, double x, double spread) {
  double dd = overshootLevel[0] - currentLevel[0];
  if (dd == 0.0) {
    drawdown = 0.0;
  }
  else if (dd > drawdown) {
    if (dd > Height) {
      drawdown = Height;
    }
    else {
      drawdown = dd;
    }
  }

  double OSP = MathPow(
                  (1.0 - OvershootECDF_Refer(level, count, overshootLevel[0] + Height))
                / (1.0 - OvershootECDF_Refer(level, count, overshootLevel[0]))
                , HeightInv);
  double logOSP = MathLog(OSP);
  double lamb;
  if (OSP < MathExp(-1)) {
    lamb = LambertW0(OSP * logOSP);
  }
  else {
    lamb = LambertWm1(OSP * logOSP);
  }
  double WR = 1.0 / (MathPow(logOSP / lamb, Height) + 1.0);
  WR = WR - (WR - 0.5) * drawdown / Height;
  if (mode[0] == -1) {
    WR = 1.0 - WR;
  }
  WinningRatio[i] = WR;
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

