// DCOSLogger (Not trade)
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#include <DirectionalChange.mqh>

// Input parameters
extern double ThresholdTick = 0.00001;
extern int    Thresholds    = 3000;

// Module variables
double threshold[0];
int mode[0];
double dcPrice[0];
double extremaPrice[0];
double overshootLevel[0];
bool reliable[0];
int handle;
datetime latest;

void start() {
  datetime now = TimeCurrent();
  if (TimeDay(latest) != TimeDay(now)) {
    Print(TimeToStr(now, TIME_DATE));
  }
  latest = now;

  int tmpMode;
  double tmpExtremaPrice, tmpDcPrice, tmpCurrentLevel, tmpOvershootLevel;
  int prevMode;
  double prevOvershootLevel;

  double x = (Bid + Ask) / 2.0;

  for (int i = 0; i < Thresholds; i++) {
    tmpMode = mode[i];
    tmpExtremaPrice = extremaPrice[i];
    tmpDcPrice = dcPrice[i];
    tmpOvershootLevel = overshootLevel[i];

    bool dcOccured = UpdateDCStatus(x, threshold[i],
      tmpMode, tmpExtremaPrice, tmpDcPrice, tmpCurrentLevel, tmpOvershootLevel,
      prevMode, tmpExtremaPrice, tmpDcPrice, tmpCurrentLevel, prevOvershootLevel); 
    
    if (dcOccured) {
      if (reliable[i]) {
        FileWrite(handle, DoubleToStr(threshold[i], 5), prevMode, prevOvershootLevel, StringSetChar(StringSetChar(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'), DoubleToStr(x, Digits + 1));
      }
      else {
        reliable[i] = true;
      }
    }
    
    mode[i] = tmpMode;
    extremaPrice[i] = tmpExtremaPrice;
    dcPrice[i] = tmpDcPrice;
    overshootLevel[i] = tmpOvershootLevel;
  }

  return(0);
}

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(reliable, Thresholds);

  for (int i = 0; i < Thresholds; i++) {
    threshold[i] = ThresholdTick * (i + 1);
    reliable[i] = false;
  }

  handle = FileOpen("DCOS_" + Symbol() + ".csv", FILE_CSV|FILE_WRITE, ',');
  if (handle < 1) {
    Print(GetLastError());
  }
  FileWrite(handle, "THRESHOLD", "MODE", "OSLEVEL", "TIME", "PRICE");
  return(0);
}

int deinit() {
  FileClose(handle);
  return(0);
}

