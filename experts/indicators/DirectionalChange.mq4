// DirectionalChange
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_minimum 0

#property indicator_color1 Green
#property indicator_width1 2
#property indicator_color2 Red
#property indicator_width2 2

#include <IndicatorUtils.mqh>

#define OBJNAME_TPLINE "Take Profit Line"

// Input parameters
extern double Threshold         = 0.002649;
extern double AgainstEntryLevel = 1.460;
extern double AgainstStopLevel  = 3.694;
extern double FollowEntryLevel  = 7.470;
extern double FollowStopLevel   = 8.760;

// Variables
int      mode; // 1: up, -1: down
double   overshootLevel;
double   extremaPrice;
datetime extremaTime;
double   dcPrice;
double   dcTime;
bool     isInitialized = false;

// Buffers
double OSLevelU[];
double OSLevelD[];

int init() {
  SetIndexLabel(0, "Up OS");
  SetIndexBuffer(0, OSLevelU);
  SetIndexStyle(0, DRAW_HISTOGRAM);

  SetIndexLabel(1, "Down OS");
  SetIndexBuffer(1, OSLevelD);
  SetIndexStyle(1, DRAW_HISTOGRAM);

  SetLevelValue(0, AgainstEntryLevel);
  SetLevelValue(1, AgainstStopLevel);
  SetLevelValue(2, FollowEntryLevel);
  SetLevelValue(3, FollowStopLevel);

  return(0);
}

int deinit() {
  if (!IsOptimization() && !IsTesting()) {
    ObjectsDeleteAll(0, OBJ_TEXT);
  }
  ObjectDelete(OBJNAME_TPLINE);

  return(0);
}

int start() {
  int prevMode;
  double prevLevel;

  if (!isInitialized) {
    isInitialized = true;
    mode = 1;
    overshootLevel = 0.0;
    extremaPrice = High[Bars - 1];
    extremaTime = Time[Bars - 1];
    dcPrice = extremaPrice;
    dcTime = extremaTime;

    double spread = (Ask - Bid) / 2.0;

    for (int i = Bars - 1; i >= 0; i--) {
      // Update normal overshoot level
      prevMode = mode;
      prevLevel = overshootLevel;
      double hi = High[i] - spread;
      double lo = Low[i] + spread;
      if (mode == -1) {
        if (Open[i] < Close[i]) { if (lo < extremaPrice) {
          extremaPrice = lo;
          extremaTime = Time[i];
          MoveExtremaLabel(extremaTime, extremaPrice);
        } }
        if ((hi - extremaPrice) / extremaPrice >= Threshold) {
          PutOldExtremaLabel(extremaTime, extremaPrice);
          mode = 1;
          extremaPrice = hi;
          extremaTime = Time[i];
          dcPrice = lo;
          dcTime = Time[i];
          overshootLevel = 0;
          PutDCLabel(mode, dcTime, dcPrice);
          MoveExtremaLabel(extremaTime, extremaPrice);
        }
        else {
          overshootLevel = (dcPrice - hi) / dcPrice / Threshold;
          if (overshootLevel <= prevLevel) {
            overshootLevel = prevLevel;
          }
        }
        if (Open[i] >= Close[i]) { if (lo < extremaPrice) {
          extremaPrice = lo;
          extremaTime = Time[i];
          MoveExtremaLabel(extremaTime, extremaPrice);
        } }
      }
      else {
        if (Open[i] > Close[i]) { if (hi > extremaPrice) {
          extremaPrice = hi;
          extremaTime = Time[i];
          MoveExtremaLabel(extremaTime, extremaPrice);
        } }
        if ((lo - extremaPrice) / extremaPrice <= -Threshold) {
          PutOldExtremaLabel(extremaTime, extremaPrice);
          mode = -1;
          extremaPrice = lo;
          extremaTime = Time[i];
          dcPrice = hi;
          dcTime = Time[i];
          overshootLevel = 0;
          PutDCLabel(mode, dcTime, dcPrice);
          MoveExtremaLabel(extremaTime, extremaPrice);
        }
        else {
          overshootLevel = (lo - dcPrice) / dcPrice / Threshold;
          if (overshootLevel <= prevLevel) {
            overshootLevel = prevLevel;
          }
        }
        if (Open[i] <= Close[i]) { if (hi > extremaPrice) {
          extremaPrice = hi;
          extremaTime = Time[i];
          MoveExtremaLabel(extremaTime, extremaPrice);
        } }
      }
      if (prevMode == mode && overshootLevel > 0 && MathFloor(prevLevel) != MathFloor(overshootLevel)) {
        PutOSLabel(MathFloor(overshootLevel), Time[i], (hi + lo) / 2.0);
      }
      if (mode == 1) {
        OSLevelU[i] = overshootLevel;
        OSLevelD[i] = EMPTY_VALUE;
      }
      else {
        OSLevelU[i] = EMPTY_VALUE;
        OSLevelD[i] = overshootLevel;
      }
    }
  }

  double x = (Bid + Ask) / 2.0;
  prevMode = mode;
  prevLevel = overshootLevel;

  // Update normal overshoot level
  if (mode == -1) {
    if (x < extremaPrice) {
      extremaPrice = x;
      extremaTime = TimeCurrent();
      MoveExtremaLabel(extremaTime, extremaPrice);
    }
    if ((x - extremaPrice) / extremaPrice >= Threshold) {
      PutOldExtremaLabel(extremaTime, extremaPrice);
      mode = 1;
      extremaPrice = x;
      extremaTime = TimeCurrent();
      dcPrice = x;
      dcTime = extremaTime;
      overshootLevel = 0;
      PutDCLabel(mode, dcTime, dcPrice);
      MoveExtremaLabel(extremaTime, extremaPrice);
    }
    else {
      overshootLevel = (dcPrice - x) / dcPrice / Threshold;
      if (overshootLevel <= prevLevel) {
        overshootLevel = prevLevel;
      }
    }
  }
  else {
    if (x > extremaPrice) {
      extremaPrice = x;
      extremaTime = TimeCurrent();
      MoveExtremaLabel(extremaTime, extremaPrice);
    }
    if ((x - extremaPrice) / extremaPrice <= -Threshold) {
      PutOldExtremaLabel(extremaTime, extremaPrice);
      mode = -1;
      extremaPrice = x;
      extremaTime = TimeCurrent();
      dcPrice = x;
      dcTime = extremaTime;
      overshootLevel = 0;
      PutDCLabel(mode, dcTime, dcPrice);
      MoveExtremaLabel(extremaTime, extremaPrice);
    }
    else {
      overshootLevel = (x - dcPrice) / dcPrice / Threshold;
      if (overshootLevel <= prevLevel) {
        overshootLevel = prevLevel;
      }
    }
  }
  if (prevMode == mode && overshootLevel > 0 && MathFloor(prevLevel) != MathFloor(overshootLevel)) {
    PutOSLabel(MathFloor(overshootLevel), TimeCurrent(), x);
  }
  if (mode == 1) {
    OSLevelU[0] = overshootLevel;
    OSLevelD[0] = EMPTY_VALUE;
  }
  else {
    OSLevelU[0] = EMPTY_VALUE;
    OSLevelD[0] = overshootLevel;
  }

  if (overshootLevel > AgainstEntryLevel) { if (overshootLevel < AgainstStopLevel) {
    double price = extremaPrice * (1.0 - mode * Threshold) + mode * (Ask - Bid) / 2.0;
    if (ObjectFind(OBJNAME_TPLINE) == -1) {
      ObjectCreate(OBJNAME_TPLINE, OBJ_HLINE, 0, 0, price);
      ObjectSet(OBJNAME_TPLINE, OBJPROP_COLOR, Lime);
    }
    else {
      ObjectSet(OBJNAME_TPLINE, OBJPROP_PRICE1, price);
    }
  } }
  if (overshootLevel < AgainstEntryLevel || overshootLevel > AgainstStopLevel) {
    ObjectDelete(OBJNAME_TPLINE);
  }

  return(0);
}

void MoveExtremaLabel(double time, double price) {
  if (!IsTesting() && !IsOptimization()) {
    ObjectDelete("Extrema");
    ObjectCreate("Extrema", OBJ_TEXT, 0, time, price);
    ObjectSetText("Extrema", "EXT", 6, "Small Fonts", White);
  }
}

void PutOldExtremaLabel(double time, double price) {
  if (!IsTesting() && !IsOptimization()) {
    string objectId = "Extrema at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
    ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
    ObjectSetText(objectId, "EXT", 6, "Small Fonts", White);
  }
}

void PutDCLabel(int m, double time, double price) {
  if (!IsTesting() && !IsOptimization()) {
    string objectId = "Directional change at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
    ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
    string label;
    if (mode == 1) {
      label = "DC(UP)";
    }
    else {
      label = "DC(DOWN)";
    }
    ObjectSetText(objectId, label, 6, "Small Fonts", White);
  }
}

void PutOSLabel(int level, double time, double price) {
  if (!IsTesting() && !IsOptimization()) {
    string objectId = "Overshoot level " + level + " at " + TimeToStr(time, TIME_DATE | TIME_SECONDS);
    ObjectCreate(objectId, OBJ_TEXT, 0, time, price);
    ObjectSetText(objectId, "OS(" + level + ")", 6, "Small Fonts", White);
  }
}

