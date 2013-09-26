// DCOSLogger (Not trade)
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#include <DirectionalChange.mqh>

// Input parameters
extern double ThresholdTick = 0.00001;
extern int    Thresholds    = 3000;

// Module variables
double threshold[0];
bool reliable[0];

int mode[0];
double dcPrice[0];
double extremaPrice[0];
double currentLevel[0];
double overshootLevel[0];

int handle;
datetime latest;

void start() {
  datetime now = TimeCurrent();
  if (TimeDay(latest) != TimeDay(now)) {
    Print(TimeToStr(now, TIME_DATE));
  }
  latest = now;

  double x = MathLog((Bid + Ask) / 2.0);
  for (int i = 0; i < Thresholds; i++) {
    int prevMode = mode[i];
    double prevOvershootLevel = overshootLevel[i];

    if (UpdateDCStatus(x, i, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel)) {
      if (reliable[i]) {
        FileWrite(handle, StringSetChar(StringSetChar(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'), DoubleToStr(x, Digits + 1), DoubleToStr(threshold[i], 5), prevMode, prevOvershootLevel);
      }
      else {
        reliable[i] = true;
      }
    }
  }

  return(0);
}

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(reliable, Thresholds);

  ArrayResize(mode, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(currentLevel, Thresholds);
  ArrayResize(overshootLevel, Thresholds);

  double x = MathLog((MarketInfo(Symbol(), MODE_BID) + MarketInfo(Symbol(), MODE_ASK)) / 2.0);
  for (int i = 0; i < Thresholds; i++) {
    threshold[i] = ThresholdTick * (i + 1);
    reliable[i] = false;
    
    mode[i] = 1;
    dcPrice[i] = x;
    extremaPrice[i] = x;
    currentLevel[i] = 0;
    overshootLevel[i] = 0;
  }

  handle = FileOpen("DCOS_" + Symbol() + ".csv", FILE_CSV|FILE_WRITE, ',');
  if (handle < 1) {
    Print(GetLastError());
  }
  FileWrite(handle, "TIME", "PRICE", "THRESHOLD", "MODE", "OSLEVEL");
  return(0);
}

int deinit() {
  FileClose(handle);
  return(0);
}

