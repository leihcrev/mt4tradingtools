// ForecastRange: Forecast range by Overshoot Level
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_chart_window
#property indicator_buffers 4

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
extern double TargetThreshold = 0.00530;
extern int    Steps           = 14;
extern bool   Exponential     = false;
extern bool   Debug           = false;

// Variables
double   threshold[0];
int      mode[0]; // 1: up, -1: down
double   overshootLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

// Buffers
double Upper[];
double Forecast[];
double Lower[];
double Threshold[];

int init() {
  if (Steps < 1 || Steps > 16) {
    Print("Illegal Steps.");
    return(1);
  }

  ArrayResize(threshold, Steps);
  ArrayResize(mode, Steps);
  ArrayResize(overshootLevel, Steps);
  ArrayResize(extremaPrice, Steps);
  ArrayResize(dcPrice, Steps);

  IndicatorShortName("ForecastRange");

  IndicatorDigits(8);

  int shift = Steps + 1;

  SetIndexLabel(0, "Upper");
  SetIndexBuffer(0, Upper);
  SetIndexShift(0, shift);
  SetIndexStyle(0, DRAW_SECTION);
  SetIndexLabel(1, "Forecast");
  SetIndexBuffer(1, Forecast);
  SetIndexShift(1, shift);
  SetIndexStyle(1, DRAW_SECTION);
  SetIndexLabel(2, "Lower");
  SetIndexBuffer(2, Lower);
  SetIndexShift(2, shift);
  SetIndexStyle(2, DRAW_SECTION);
  SetIndexLabel(3, "Threshold");
  SetIndexBuffer(3, Threshold);
  SetIndexShift(3, shift);
  SetIndexStyle(3, DRAW_NONE);

  // threshold[] = TargetThreshold / {2^(Steps - 1), 2^(Steps - 2), ..., 2^0}
  for (int th = 0; th < Steps; th++) {
    if (Exponential) {
      threshold[th] = TargetThreshold / MathPow(2.0, Steps - th - 1);
    }
    else {
      threshold[th] = TargetThreshold * (th + 1) / Steps;
    }
    threshold[th] = MathRound(threshold[th] / 0.00001) * 0.00001;
    if (threshold[th] == 0) {
      threshold[th] = 0.00001;
    }
  }

  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);

  if (Debug) {
    string debug = "index: ";
    for (th = 0; th < Steps; th++) {
      debug = StringConcatenate(debug, "[", index[th], "]");
    }
    debug = StringConcatenate(debug, "/level: ", ArraySize(level), "/count: ", ArraySize(count));
    Print(debug);
  }

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double currentLevel;
  int th, j;

  if (!isInitialized) {
    isInitialized = true;
    for (th = 0; th < Steps; th++) {
      mode[th] = 0;
      overshootLevel[th] = 0.0;
      extremaPrice[th] = High[Bars - 1];
      dcPrice[th] = extremaPrice[th];
    }

    for (int i = Bars - 1; i >= 0; i--) {
      for (th = 0; th < Steps; th++) {
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

  double x = MathSqrt(Bid * Ask);
  double prices[];
  ArrayResize(prices, MathPow(2.0, Steps + 1) - 1);
  prices[0] = x;
  for (th = 0; th < Steps; th++) {
    // Update overshoot level
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

    // Forecast
    for (j = MathPow(2.0, th) - 1; j < MathPow(2.0, th + 1) - 1; j++) {
      int m = mode[th];
      double dc = dcPrice[th];
      double ext = extremaPrice[th];
      double cl = currentLevel;
      double osl = overshootLevel[th];

      // Simulate price evolution
      for (int th2 = 0; th2 < th; th2++) {
        int pow = MathPow(2.0, th - th2);
        double price = prices[(j + 1) / pow - 1];
        if (m == -1) {
          if (price < extremaPrice[th]) {
            ext = price;
          }
          if ((price - ext) / ext >= threshold[th]) {
            m = 1;
            dc = ext * (1.0 + threshold[th]);
            cl = (price - ext) / ext / threshold[th] - 1.0;
            osl = cl;
          }
          else {
            cl = (dc - price) / dc / threshold[th];
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
            dc = ext * (1.0 - threshold[th]);
            cl = (ext - price) / ext / threshold[th] - 1.0;
            osl = cl;
          }
          else {
            cl = (price - dc) / dc / threshold[th];
            if (osl < cl) {
              osl = cl;
            }
          }
        }
      }

      // Forecast prices
      double DCDistance = 1.0 + cl - osl;
      double p = OvershootECDF_MultiRefer(th, index, level, count, osl);
      double evenp = 1.0 - (1.0 - p) / MathExp(1);
      double evenosl = OvershootECDF_MultiReverseRefer(th, index, level, count, evenp);
      double OSDistance = DCDistance * (evenosl - osl);
      double u, l;
      if (m == 1) {
        prices[j * 2 + 1] = prices[j] + prices[j] * threshold[th] * OSDistance;
        prices[j * 2 + 2] = prices[j] - prices[j] * threshold[th] * DCDistance;
      }
      else {
        prices[j * 2 + 1] = prices[j] + prices[j] * threshold[th] * DCDistance;
        prices[j * 2 + 2] = prices[j] - prices[j] * threshold[th] * OSDistance;
      }
    }
  }

  // Update Buffer
  th = 0;
  int n;
  int idx = Steps - th;
  Upper[idx] = prices[1];
  Lower[idx] = prices[2];
  Forecast[idx] = (Upper[idx] + Lower[idx]) / 2.0;
  Threshold[idx] = threshold[th];
  for (th = 1; th < Steps; th++) {
    idx = Steps - th;
    Upper[idx] = 0.0;
    Lower[idx] = 0.0;
    ArraySort(prices, MathPow(2.0, th + 1), MathPow(2.0, th + 1) - 1, MODE_DESCEND);
    for (j = MathPow(2.0, th + 1) - 1; j < MathPow(2.0, th + 1) - 1 + MathPow(2.0, th); j++) {
      Upper[idx] += prices[j];
    }
    for (j = MathPow(2.0, th + 1) - 1 + MathPow(2.0, th); j < MathPow(2.0, th + 2) - 1; j++) {
      Lower[idx] += prices[j];
    }
    for (int k = 0; k < th; k++) {
      Upper[idx] /= 2.0;
      Lower[idx] /= 2.0;
    }
    Forecast[idx] = (Upper[idx] + Lower[idx]) / 2.0;
    Threshold[idx] = threshold[th];
  }

  Upper[Steps + 1] = EMPTY_VALUE;
  Forecast[Steps + 1] = EMPTY_VALUE;
  Lower[Steps + 1] = EMPTY_VALUE;
  Threshold[Steps + 1] = EMPTY_VALUE;

  return(0);
}

