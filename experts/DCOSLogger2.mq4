// DCOSLogger2 (Not trade)
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#include <DirectionalChange.mqh>

// Input parameters
extern double ThresholdBase = 0.00292;
extern int    Thresholds    = 10;

// Module variables
double threshold[1];
bool reliable[1];

int mode[1];
double dcPrice[1];
double extremaPrice[1];
double currentLevel[1];
double overshootLevel[1];

double prevExtremaPrice[1];

int handle;
datetime latest;

void OnTick() {
  datetime now = TimeCurrent();
  if (TimeDay(latest) != TimeDay(now)) {
    Print(TimeToStr(now, TIME_DATE));
  }
  latest = now;

  int prevMode = mode[0];
  double prevOvershootLevel = overshootLevel[0];

  double x = MathLog((Bid + Ask) / 2.0);
  for (int i = 0; i < Thresholds; i++) {
    double pep = extremaPrice[i];
    if (UpdateDCStatus(x, i, threshold, mode, extremaPrice, dcPrice, currentLevel, overshootLevel)) {
      reliable[i] = true;
      prevExtremaPrice[i] = pep;
    }
  }

  if (reliable[0]) {
    if (mode[0] != prevMode || overshootLevel[0] != prevOvershootLevel) {
      int count = 0;
      for (int j = 1; j < Thresholds; j++) {
        if (prevExtremaPrice[0] == prevExtremaPrice[j]) {
          count++;
        }
      }
      FileWrite(handle, StringSetChar(StringSetChar(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'), mode[0], overshootLevel[0], count);
    }
  }

  return;
}

int OnInit() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(reliable, Thresholds);

  ArrayResize(mode, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(currentLevel, Thresholds);
  ArrayResize(overshootLevel, Thresholds);

  ArrayResize(prevExtremaPrice, Thresholds);

  double x = MathLog((MarketInfo(Symbol(), MODE_BID) + MarketInfo(Symbol(), MODE_ASK)) / 2.0);
  for (int i = 0; i < Thresholds; i++) {
    threshold[i] = ThresholdBase * MathPow(1.0 - MathExp(-1.0), i);
    reliable[i] = false;
    
    mode[i] = 1;
    dcPrice[i] = x;
    extremaPrice[i] = x;
    currentLevel[i] = 0;
    overshootLevel[i] = 0;

    prevExtremaPrice[i] = 0;
  }

  handle = FileOpen("DCOS_" + Symbol() + ".csv", FILE_CSV|FILE_WRITE, ',');
  if (handle < 1) {
    Print(GetLastError());
  }
  FileWrite(handle, "TIME", "MODE", "OSLEVEL", "COUNT");
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  FileClose(handle);
  return;
}
