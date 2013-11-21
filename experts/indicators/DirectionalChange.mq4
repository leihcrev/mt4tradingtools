// DirectionalChange
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -1

#property indicator_color1 Green
#property indicator_width1 2
#property indicator_color2 Red
#property indicator_width2 2
#property indicator_color3 Gray
#property indicator_width3 1
#property indicator_color4 White
#property indicator_width4 1

#include <IndicatorUtils.mqh>
#include <DirectionalChange.mqh>

#define OBJNAME_AGAINST_ENTRY_LINE "Against Entry Line"
#define OBJNAME_DCLINE "Take Profit Line"

// Input parameters
extern double DCThreshold         = 0.00292;
extern double OSAgainstEntryLevel = 1.23495337;
extern double OSAgainstStopOffset = 1.89756012;
extern double OSDrawdownFilter    = 0.66424134;

// Variables
double   threshold[1];
int      mode[1]; // 1: up, -1: down
double   currentLevel[1];
double   overshootLevel[1];
double   extremaPrice[1];
double   dcPrice[1];
datetime extremaTime;
double   peak;
double   drawdown;
bool     entried;

double   OSAgainstStopLevel;
bool     initialized = false;

// Buffers
double OSLevelU[];
double OSLevelD[];
double OSLevel[];
double EffectiveOSLevel[];

int init() {
  SetIndexLabel(0, "Up OS");
  SetIndexBuffer(0, OSLevelU);
  SetIndexStyle(0, DRAW_HISTOGRAM);

  SetIndexLabel(1, "Down OS");
  SetIndexBuffer(1, OSLevelD);
  SetIndexStyle(1, DRAW_HISTOGRAM);

  SetIndexLabel(2, "OS Level");
  SetIndexBuffer(2, OSLevel);
  SetIndexStyle(2, DRAW_LINE);

  SetIndexLabel(3, "Effective OS Level");
  SetIndexBuffer(3, EffectiveOSLevel);
  SetIndexStyle(3, DRAW_LINE);

  SetLevelValue(0, OSAgainstEntryLevel);
  SetLevelValue(1, OSAgainstStopLevel);
  SetLevelValue(2, -1.0);

  OSAgainstStopLevel = OSAgainstEntryLevel + OSAgainstStopOffset;

  return(0);
}

int deinit() {
  if (!IsOptimization() && !IsTesting()) {
    ObjectsDeleteAll(0, OBJ_TEXT);
    ObjectDelete(OBJNAME_DCLINE);
  }

  return(0);
}

int start() {
  int prevMode;
  double prevExtremaPrice;
  double prevLevel;
  double dd;
  double m;

  if (!initialized) {
    initialized = true;

    threshold[0] = DCThreshold;
    mode[0] = 1;
    overshootLevel[0] = 0.0;
    extremaPrice[0] = High[Bars - 1];
    dcPrice[0] = extremaPrice[0];
    peak = 0;
    drawdown = 0;

    double spread = (MarketInfo(Symbol(), MODE_ASK) - MarketInfo(Symbol(), MODE_BID)) / 2.0;

    for (int i = Bars - 1; i >= 0; i--) {
      double prices[4];
      GetPricesFromBar(prices, i, spread);
      for (int j = 0; j < 4; j++) {
        prevMode = mode[0];
        prevLevel = overshootLevel[0];
        prevExtremaPrice = extremaPrice[0];
        UpdateDCStatus(MathLog(prices[j]), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel);
        if (mode[0] != prevMode) {
          peak = 0;
          drawdown = 0;
          entried = false;
        }
        dd = overshootLevel[0] - currentLevel[0];
        if (dd > drawdown) {
          peak = overshootLevel[0];
          drawdown = dd;
        }
        if (!IsTesting() && !IsOptimization()) {
          if (mode[0] == prevMode) {
            // DC is not occured
            if (extremaPrice[0] != prevExtremaPrice) {
              // EXT is updated
              extremaTime = Time[i];
              MoveExtremaLabel(extremaTime, extremaPrice[0]);
            }
            if (overshootLevel[0] > 0 && MathFloor(prevLevel) != MathFloor(overshootLevel[0])) {
              // OS is updated
              PutOSLabel(MathFloor(overshootLevel[0]), Time[i], prices[j]);
            }
          }
          else {
            // DC is occured
            PutOldExtremaLabel(extremaTime, prevExtremaPrice);
            extremaTime = Time[i];
            PutDCLabel(mode[0], extremaTime, dcPrice[0]);
            MoveExtremaLabel(extremaTime, extremaPrice[0]);
          }
        }
      }

      if (mode[0] == 1) {
        OSLevelU[i] = overshootLevel[0];
        OSLevelD[i] = EMPTY_VALUE;
      }
      else {
        OSLevelU[i] = EMPTY_VALUE;
        OSLevelD[i] = overshootLevel[0];
      }
      OSLevel[i] = currentLevel[0];
      EffectiveOSLevel[i] = currentLevel[0];
      if (drawdown > OSDrawdownFilter) {
        EffectiveOSLevel[i] += drawdown - peak - 1.0;
      }
      if (EffectiveOSLevel[i] > OSAgainstEntryLevel) {
        entried = true;
      }
    }
  }

  double x = (Bid + Ask) / 2.0;
  prevMode = mode[0];
  prevLevel = overshootLevel[0];
  prevExtremaPrice = extremaPrice[0];
  UpdateDCStatus(MathLog(x), 0, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel);
  if (mode[0] != prevMode) {
    peak = 0;
    drawdown = 0;
    entried = false;
  }
  dd = overshootLevel[0] - currentLevel[0];
  if (dd > drawdown) {
    peak = overshootLevel[0];
    drawdown = dd;
  }
  if (mode[0] == 1) {
    OSLevelU[0] = overshootLevel[0];
    OSLevelD[0] = EMPTY_VALUE;
  }
  else {
    OSLevelU[0] = EMPTY_VALUE;
    OSLevelD[0] = overshootLevel[0];
  }
  OSLevel[0] = currentLevel[0];
  m = 0;
  EffectiveOSLevel[0] = currentLevel[0];
  if (drawdown > OSDrawdownFilter) {
    m = drawdown - peak - 1.0;
    EffectiveOSLevel[0] += m;
  }
  if (EffectiveOSLevel[0] > OSAgainstEntryLevel) {
    entried = true;
  }

  if (!IsTesting() && !IsOptimization()) {
    if (mode[0] == prevMode) {
      // DC is not occured
      if (extremaPrice[0] != prevExtremaPrice) {
        // EXT is updated
        extremaTime = TimeCurrent();
        MoveExtremaLabel(extremaTime, extremaPrice[0]);
      }
      if (overshootLevel[0] > 0 && MathFloor(prevLevel) != MathFloor(overshootLevel[0])) {
        // OS is updated
        PutOSLabel(MathFloor(overshootLevel[0]), TimeCurrent(), x);
      }
    }
    else {
      // DC is occured
      PutOldExtremaLabel(extremaTime, prevExtremaPrice);
      extremaTime = TimeCurrent();
      PutDCLabel(mode[0], extremaTime, dcPrice[0]);
      MoveExtremaLabel(extremaTime, extremaPrice[0]);
    }

    double price = MathExp(extremaPrice[0] - mode[0] * DCThreshold) + mode[0] * (Ask - Bid) / 2.0;
    if (ObjectFind(OBJNAME_DCLINE) == -1) {
      ObjectCreate(OBJNAME_DCLINE, OBJ_HLINE, 0, 0, price);
      ObjectSet(OBJNAME_DCLINE, OBJPROP_COLOR, Blue);
    }
    else {
      ObjectSet(OBJNAME_DCLINE, OBJPROP_PRICE1, price);
    }

    if (entried) {
      ObjectDelete(OBJNAME_AGAINST_ENTRY_LINE);
    }
    else {
      if (overshootLevel[0] < OSAgainstEntryLevel - m) {
        price = MathExp(dcPrice[0] + mode[0] * DCThreshold * (OSAgainstEntryLevel - m));
        if (ObjectFind(OBJNAME_AGAINST_ENTRY_LINE) == -1) {
          ObjectCreate(OBJNAME_AGAINST_ENTRY_LINE, OBJ_HLINE, 0, 0, price);
          ObjectSet(OBJNAME_AGAINST_ENTRY_LINE, OBJPROP_COLOR, Lime);
        }
        else {
          ObjectSet(OBJNAME_AGAINST_ENTRY_LINE, OBJPROP_PRICE1, price);
        }
      }
    }
  }

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

void MoveExtremaLabel(double time, double logprice) {
  ObjectDelete("Extrema");
  double price = MathExp(logprice);
  ObjectCreate("Extrema", OBJ_TEXT, 0, time, price);
  ObjectSetText("Extrema", "EXT(" + DoubleToStr(price, Digits) + ")", 6, "Small Fonts", White);
}

void PutOldExtremaLabel(double time, double logprice) {
  string objectId = "Extrema at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
  double price = MathExp(logprice);
  ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
  ObjectSetText(objectId, "EXT(" + DoubleToStr(price, Digits) + ")", 6, "Small Fonts", White);
}

void PutDCLabel(int m, double time, double logprice) {
  string objectId = "Directional change at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
  double price = MathExp(logprice);
  ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
  string label;
  if (m == 1) {
    label = "DC UP(" + DoubleToStr(price, Digits) + ")";
  }
  else {
    label = "DC DOWN(" + DoubleToStr(price, Digits) + ")";
  }
  ObjectSetText(objectId, label, 6, "Small Fonts", White);
}

void PutOSLabel(int level, double time, double price) {
  string objectId = "Overshoot level " + level + " at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
  ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
  ObjectSetText(objectId, "OS(" + level + ")", 6, "Small Fonts", White);
}

