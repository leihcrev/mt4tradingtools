// DCOSLogger (Not trade)
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

// Input parameters
extern double DCThreshold         =  0.00264;

// Module variables
int mode = 0;
double dcPrice;
double extremaPrice;
double overshootLevel;
double currentLevel;
double dcSMQ = 0.0;
int handle;

void start() {
  double SMQ = iCustom(Symbol(), Period(), "OSPA", 3, 0);
  double x = MathLog((Bid + Ask) / 2.0);
  double prevMode = mode;

  if (mode == -1) {
    if (x < extremaPrice) {
      extremaPrice = x;
    }
    if (x - extremaPrice >= DCThreshold) {
      Log(x, dcSMQ, SMQ);
      mode = 1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = 0;
      overshootLevel = 0;
      dcSMQ = SMQ;
    }
    else {
      currentLevel = (dcPrice - x) / DCThreshold;
      if (currentLevel > overshootLevel) {
        overshootLevel = currentLevel;
      }
    }
  }
  else if (mode == 1) {
    if (x > extremaPrice) {
      extremaPrice = x;
    }
    if (extremaPrice - x >= DCThreshold) {
      Log(x, dcSMQ, SMQ);
      mode = -1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = 0;
      overshootLevel = 0;
      dcSMQ = SMQ;
    }
    else {
      currentLevel = (x - dcPrice) / DCThreshold;
      if (currentLevel > overshootLevel) {
        overshootLevel = currentLevel;
      }
    }
  }
  else {
    mode = 1;
    extremaPrice = x;
    dcPrice = x;
    currentLevel = 0;
    overshootLevel = 0;
  }
  return(0);
}

void Log(double price, double dcSMQ, double SMQ) {
  if (dcSMQ == 0.0) {
    return;
  }
  FileWrite(handle, mode, overshootLevel, StringSetChar(StringSetChar(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'), DoubleToStr(MathExp(price), Digits + 1), dcSMQ, SMQ);
}

int init() {
  handle = FileOpen("DCOS_" + Symbol() + "_" + DoubleToStr(DCThreshold, 5) + ".csv", FILE_CSV|FILE_WRITE, ',');
  if (handle < 1) {
    Print(GetLastError());
  }
  FileWrite(handle, "MODE", "OSLEVEL", "TIME", "PRICE", "DCSMQ", "SMQ");
  return(0);
}

int deinit() {
  FileClose(handle);
  return(0);
}

