// ForecastRange: Forecast range by Overshoot Level
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_chart_window
#property indicator_buffers 8

#property indicator_color1 Gray
#property indicator_color2 Blue
#property indicator_color3 Gray
#property indicator_style1 0
#property indicator_style2 0
#property indicator_style3 0
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>

// Input parameters
extern double thresholdTick = 0.00005;

// Variables
double   threshold[100];
int      mode[100]; // 1: up, -1: down
double   overshootLevel[100];
double   extremaPrice[100];
double   dcPrice[100];
bool     isInitialized = false;
double   thresholdContribution[100];

// Buffers
double Upper[];
double Forecast[];
double Lower[];
double ThresholdBuffer[];
double ModeBuffer[];
double OSLevelBuffer[];
double DCDistanceBuffer[];
double OSDistanceBuffer[];

int init() {
  IndicatorShortName("ForecastRange");

  IndicatorDigits(8);

  SetIndexLabel(0, "Upper");
  SetIndexBuffer(0, Upper);
  SetIndexShift(0, 101);
  SetIndexLabel(1, "Forecast");
  SetIndexBuffer(1, Forecast);
  SetIndexShift(1, 101);
  SetIndexLabel(2, "Lower");
  SetIndexBuffer(2, Lower);
  SetIndexShift(2, 101);

  SetIndexLabel(3, "Threshold");
  SetIndexBuffer(3, ThresholdBuffer);
  SetIndexShift(3, 101);
  SetIndexStyle(3, DRAW_NONE);
  SetIndexLabel(4, "Mode");
  SetIndexBuffer(4, ModeBuffer);
  SetIndexShift(4, 101);
  SetIndexStyle(4, DRAW_NONE);
  SetIndexLabel(5, "OSLevel");
  SetIndexBuffer(5, OSLevelBuffer);
  SetIndexShift(5, 101);
  SetIndexStyle(5, DRAW_NONE);
  SetIndexLabel(6, "DCDistance");
  SetIndexBuffer(6, DCDistanceBuffer);
  SetIndexShift(6, 101);
  SetIndexStyle(6, DRAW_NONE);
  SetIndexLabel(7, "OSDistance");
  SetIndexBuffer(7, OSDistanceBuffer);
  SetIndexShift(7, 101);
  SetIndexStyle(7, DRAW_NONE);

  double cb = 0.0;
  for (int i = 1; i <= 100; i++) {
    cb += MathSqrt(i);
  }
  for (int th = 0; th < 100; th++) {
    threshold[th] = thresholdTick * (th + 1);
    thresholdContribution[th] = 1.0;
  }

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double currentLevel;
  int th;
  int j;

  if (!isInitialized) {
    isInitialized = true;
    for (th = 0; th < 100; th++) {
      mode[th] = 0;
      overshootLevel[th] = 0.0;
      extremaPrice[th] = High[Bars - 1];
      dcPrice[th] = extremaPrice[th];
    }

    for (int i = Bars - 1; i >= 0; i--) {
      for (th = 0; th < 100; th++) {
        if (mode[th] == -1) {
          if (Low[i] < extremaPrice[th]) {
            extremaPrice[th] = Low[i];
          }
          if ((High[i] - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
            mode[th] = 1;
            extremaPrice[th] = High[i];
            dcPrice[th] = Low[i];
            overshootLevel[th] = 0;
          }
          else {
            currentLevel = (dcPrice[th] - High[i]) / dcPrice[th] / threshold[th];
            if (overshootLevel[th] < currentLevel) {
              overshootLevel[th] = currentLevel;
            }
          }
        }
        else {
          if (High[i] > extremaPrice[th]) {
            extremaPrice[th] = High[i];
          }
          if ((Low[i] - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
            mode[th] = -1;
            extremaPrice[th] = Low[i];
            dcPrice[th] = High[i];
            overshootLevel[th] = 0;
          }
          else {
            currentLevel = (Low[i] - dcPrice[th]) / dcPrice[th] / threshold[th];
            if (overshootLevel[th] < currentLevel) {
              overshootLevel[th] = currentLevel;
            }
          }
        }
      }
    }
  }

  double x = (Bid + Ask) / 2.0;
  for (th = 0; th < 100; th++) {
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        mode[th] = 1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        overshootLevel[th] = 0;
        currentLevel = 0.0;
      }
      else {
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    }
    else {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
        mode[th] = -1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        overshootLevel[th] = 0;
        currentLevel = 0.0;
      }
      else {
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    }

    // Update buffers
    double sp = (Ask - Bid) / 2.0;
    double price = x;
    int m = mode[th];
    double ext = extremaPrice[th];
    double cl = currentLevel;
    double osl = overshootLevel[th];
    int idx = 100 - th;
    if (th != 0) {
      price = Forecast[idx + 1];
      if (m == -1) {
        if (price < extremaPrice[th]) {
          ext = price;
        }
        if ((price - ext) / ext >= threshold[th]) {
          m = 1;
          cl = (price - ext) / ext / threshold[th] - 1.0;
          osl = cl;
        }
        else {
          cl = (dcPrice[th] - price) / dcPrice[th] / threshold[th];
          if (osl < cl) {
            osl = cl;
          }
        }
      }
      else {
        if (price > ext) {
          ext = price;
        }
        if ((price - ext) / ext <= -threshold[th]) {
          m = -1;
          cl = (ext - price) / ext / threshold[th] - 1.0;
          osl = cl;
        }
        else {
          cl = (price - dcPrice[th]) / dcPrice[th] / threshold[th];
          if (osl < cl) {
            osl = cl;
          }
        }
      }
    }
    ThresholdBuffer[idx] = threshold[th];
    OSLevelBuffer[idx] = cl;
    DCDistanceBuffer[idx] = 1.0 + cl - osl;
    OSDistanceBuffer[idx] = DCDistanceBuffer[idx] * (GetEvenOvershootLevel(Symbol(), threshold[th], osl) - osl);
    double DCDistance = price * threshold[th] * DCDistanceBuffer[idx];
    double OSDistance = price * threshold[th] * OSDistanceBuffer[idx];
    if (m == 1) {
      Upper[idx] = price + OSDistance - sp;
      Lower[idx] = price - DCDistance - sp;
      ModeBuffer[idx] = 1;
    }
    else {
      Upper[idx] = price + DCDistance - sp;
      Lower[idx] = price - OSDistance - sp;
      ModeBuffer[idx] = -1;
    }
    Forecast[idx] = MathSqrt(Upper[idx] * Lower[idx]);
  }
  Upper[0] = EMPTY_VALUE;
  Forecast[0] = EMPTY_VALUE;
  Lower[0] = EMPTY_VALUE;
  Upper[101] = EMPTY_VALUE;
  Forecast[101] = EMPTY_VALUE;
  Lower[101] = EMPTY_VALUE;

  return(0);
}

