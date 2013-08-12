// Strategy1
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#include <Position.mqh>
#include <Tweet.mqh>
#include <DateTime.mqh>

// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.002649;
extern double OSAgainstEntryLevel =  1.460;
extern double OSAgainstStopOffset =  2.234;
extern double OSFollowEntryLevel  =  7.470;
extern double OSFollowStopLevel   =  8.760;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 5;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.3103;
extern double WorstLoss           = -7200;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

// Module variables
double FollowSLFactor;
double OSAgainstStopLevel;
// -- For directional change
int mode = 0;
double dcPrice;
double extremaPrice;
double overshootLevel;
double currentLevel;
bool againstEntried = false;
bool followEntried = false;

// -- For avoid weekend
datetime NextWeekendDatetime = 0;

void start() {
  TweetTakeProfitOrStopLoss(Symbol(), MagicNumber);

  UpdateDCOS();

  datetime now = TimeCurrent();
  if (now > NextWeekendDatetime + 60) {
    NextWeekendDatetime = GetNextWeekendDatetime(now, GMTOffset);
    Print("Update NextWeekendDatetime: ", TimeToStr(NextWeekendDatetime, TIME_DATE | TIME_SECONDS));
  }
  if (now > NextWeekendDatetime - WeekendMarginSecs) {
    ClosePosition(Symbol(), MagicNumber, EMPTY, "Close on weekend");
    return(0);
  }

  if (overshootLevel < OSAgainstEntryLevel && overshootLevel < OSFollowEntryLevel) {
    ClosePosition(Symbol(), MagicNumber, EMPTY, "Close by directional change");
    return(0);
  }
  double lots, l;
  bool isSuccess = true;
  if (mode == -1) {
    if (!againstEntried) { if (currentLevel > OSAgainstEntryLevel) { if (overshootLevel < OSAgainstStopLevel) { if (!HasPosition(Symbol(), MagicNumber, OP_BUY )) {
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        isSuccess = isSuccess && TakePosition(Symbol(), MagicNumber, OP_BUY , l, Ask * DCThreshold * (OSAgainstStopLevel - currentLevel) / Point, 0, 20, "Take position against overshoot");
      }
      againstEntried = isSuccess;
    } } } }
    if (followEntried ) {
      if (overshootLevel > OSFollowStopLevel) {
        ClosePosition(Symbol(), MagicNumber, OP_SELL, "Close by too overshoot");
      }
    }
    else if (currentLevel > OSFollowEntryLevel ) { if (overshootLevel < OSFollowStopLevel ) { if (!HasPosition(Symbol(), MagicNumber, OP_SELL)) {
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        isSuccess = isSuccess && TakePosition(Symbol(), MagicNumber, OP_SELL, l, Bid * FollowSLFactor , 0, 20, "Take position follow overshoot" );
      }
      followEntried = isSuccess;
    } } }
  }
  else if (mode ==  1) {
    if (!againstEntried) { if (currentLevel > OSAgainstEntryLevel) { if (overshootLevel < OSAgainstStopLevel) { if (!HasPosition(Symbol(), MagicNumber, OP_SELL)) {
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        isSuccess = isSuccess && TakePosition(Symbol(), MagicNumber, OP_SELL, l, Bid * DCThreshold * (OSAgainstStopLevel - currentLevel) / Point, 0, 20, "Take position against overshoot");
      }
      againstEntried = isSuccess;
    } } } }
    if (followEntried ) {
      if (overshootLevel > OSFollowStopLevel) {
        ClosePosition(Symbol(), MagicNumber, OP_BUY, "Close by too overshoot");
      }
    }
    else if (currentLevel > OSFollowEntryLevel ) { if (overshootLevel < OSFollowStopLevel ) { if (!HasPosition(Symbol(), MagicNumber, OP_BUY )) {
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        isSuccess = isSuccess && TakePosition(Symbol(), MagicNumber, OP_BUY , l, Ask * FollowSLFactor , 0, 20, "Take position follow overshoot" );
      }
      followEntried = isSuccess;
    } } }
  }

  return(0);
}

void UpdateDCOS() {
  double x = MathLog((Bid + Ask) / 2.0);
  double prevMode = mode;

  if (mode == -1) {
    if (x < extremaPrice) {
      extremaPrice = x;
    }
    if (x - extremaPrice >= DCThreshold) {
      mode = 1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = 0;
      overshootLevel = 0;
      againstEntried = false;
      followEntried = false;
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
      mode = -1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = 0;
      overshootLevel = 0;
      againstEntried = false;
      followEntried = false;
    }
    else {
      currentLevel = (x - dcPrice) / DCThreshold;
      if (currentLevel > overshootLevel) {
        overshootLevel = currentLevel;
      }
    }
  }
  else {
    // Detect latest EXT
    double loext = x;
    double hiext = x;
    double loglo, loghi;
    for (int i = 0; i < Bars; i++) {
      loglo = MathLog(Low[i]);
      loghi = MathLog(High[i]);
      if (loglo < loext) {
        loext = loglo;
        mode = 1;
      }
      if (loghi > hiext) {
        hiext = loghi;
        mode = -1;
      }
      if (hiext - loext >= DCThreshold) {
        if (mode == 1) {
          extremaPrice = hiext;
        }
        else if (mode == -1) {
          extremaPrice = loext;
        }
        break;
      }
    }
    // Detect latest DC
    for (; i < Bars; i++) {
      loglo = MathLog(Low[i]);
      loghi = MathLog(High[i]);
      if (mode == 1) {
        if (loglo < loext) {
          loext = loglo;
          mode = 1;
        }
        if (loghi - loext >= DCThreshold) {
          dcPrice = loext + DCThreshold;
          overshootLevel = (extremaPrice - dcPrice) / DCThreshold;
          break;
        }
      }
      else {
        if (loghi > hiext) {
          hiext = loghi;
          mode = -1;
        }
        if (hiext - loglo >= DCThreshold) {
          dcPrice = hiext - DCThreshold;
          overshootLevel = (dcPrice - extremaPrice) / DCThreshold;
          break;
        }
      }
    }

    againstEntried = false;
    followEntried = false;
  }

  if (!IsTesting() && !IsOptimization()) {
    string comment = "";
    if (mode == 1) {
      comment = comment + "Mode: UP";
    }
    else {
      comment = comment + "Mode: DOWN";
    }
    comment = comment + " / Overshoot level: " + DoubleToStr(overshootLevel, 2);
    comment = comment + " / Current level: " + DoubleToStr(currentLevel, 2);
    comment = comment + "\n";

    comment = comment + "DC: " + DoubleToStr(MathExp(dcPrice), Digits);
    comment = comment + " / EXT: " + DoubleToStr(MathExp(extremaPrice), Digits);
    comment = comment + "\n";

    comment = comment + "Next DC: " + DoubleToStr(MathExp(extremaPrice - mode * DCThreshold), Digits);
    comment = comment + " / Next action: ";
    if (overshootLevel <= OSAgainstEntryLevel) {
      if (mode == 1) {
        comment = comment + "AGAINST SELL @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * OSAgainstEntryLevel), Digits);
      }
      else {
        comment = comment + "AGAINST BUY @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * OSAgainstEntryLevel), Digits);
      }
    }
    else if (overshootLevel > OSAgainstEntryLevel && overshootLevel <= OSAgainstStopLevel) {
      comment = comment + "TAKE PROFIT @ " + DoubleToStr(MathExp(extremaPrice - mode * DCThreshold), Digits);
      if (mode == 1) {
        comment = comment + " / STOP LOSS @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * OSAgainstStopLevel), Digits);
      }
      else {
        comment = comment + " / STOP LOSS @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * OSAgainstStopLevel), Digits);
      }
    }
    else if (overshootLevel > OSAgainstStopLevel && overshootLevel <= OSFollowEntryLevel) {
      if (mode == 1) {
        comment = comment + "FOLLOW BUY @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * OSFollowEntryLevel), Digits);
      }
      else {
        comment = comment + "FOLLOW SELL @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * OSFollowEntryLevel), Digits);
      }
    }
    else if (overshootLevel > OSFollowEntryLevel && overshootLevel <= OSFollowStopLevel) {
      if (mode == 1) {
        comment = comment + "TAKE PROFIT @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * OSFollowStopLevel), Digits);
      }
      else {
        comment = comment + "TAKE PROFIT @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * OSFollowStopLevel), Digits);
      }
      comment = comment + " / STOP LOSS @ " + DoubleToStr(MathExp(extremaPrice - mode * DCThreshold), Digits);
    }
    else {
      comment = comment + "NONE";
    }
    comment = comment + "\n";

    comment = comment + "Optimal lots: " + DoubleToStr(GetLots(), 2);
    comment = comment + "\n";

    Comment(comment);
  }
}

int init() {
  OSAgainstStopLevel = OSAgainstEntryLevel + OSAgainstStopOffset;

  NextWeekendDatetime = GetNextWeekendDatetime(TimeCurrent(), GMTOffset);
  FollowSLFactor = DCThreshold / Point;
  return(0);
}

int deinit() {
  return(0);
}

double GetLots() {
  if (Lots == 0.0) {
    return(GetLotsByOptimalF(OptimalF, WorstLoss, DCThreshold * OSAgainstStopOffset));
  }
  return(Lots);
}

