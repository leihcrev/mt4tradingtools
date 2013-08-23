// Strategy2
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#include <Position.mqh>
#include <Tweet.mqh>

// Input parameters
extern string StrategyParameters = "==== Strategy parameters ====";
extern double ThresholdStart     = 0.00010;
extern double ThresholdTick      = 0.00001;
extern int    Thresholds         = 50;
extern int    MaxBars            = 28800;
extern double EntryLine          = 2;
extern double CloseLineOffset    = 1;
extern string OrderParameters    = "==== Order parameters ====";
extern double OptimalF           = 0.1000;
extern double WorstLoss          = -10000;
extern double Lots               = 1.0;
extern int    MagicNumber        = 2;

// Module variables
double CloseLine;

void start() {
  TweetTakeProfitOrStopLoss(Symbol(), MagicNumber);

  double skewUp = iCustom(Symbol(), Period(), "ForecastSkew", ThresholdStart, ThresholdTick, Thresholds, MaxBars, 0, 0);
  double skewDown = iCustom(Symbol(), Period(), "ForecastSkew", ThresholdStart, ThresholdTick, Thresholds, MaxBars, 1, 0);
  double skew = iCustom(Symbol(), Period(), "ForecastSkew", ThresholdStart, ThresholdTick, Thresholds, MaxBars, 2, 0);

  double lots, l;
  if (HasPosition(Symbol(), MagicNumber, OP_BUY)) {
    if (skew < CloseLine) {
      ClosePosition(Symbol(), MagicNumber, OP_BUY, "Market is not skewed");
    }
  }
  else {
    if (skewUp > EntryLine && skewDown == 0.0) {
      ClosePosition(Symbol(), MagicNumber, OP_SELL, "Doten");
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        TakePosition(Symbol(), MagicNumber, OP_BUY, l, 0, 0, 0, "Market is skewed upward");
      }
    }
  }
  if (HasPosition(Symbol(), MagicNumber, OP_SELL)) {
    if (skew > -CloseLine) {
      ClosePosition(Symbol(), MagicNumber, OP_BUY, "Market is not skewed");
    }
  }
  else {
    if (skewDown < -EntryLine && skewUp == 0.0) {
      ClosePosition(Symbol(), MagicNumber, OP_BUY, "Doten");
      for (lots = GetLots(); lots > 0; lots -= l) {
        l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
        TakePosition(Symbol(), MagicNumber, OP_SELL, l, 0, 0, 0, "Market is skewed downward");
      }
    }
  }
  
  return(0);
}

int init() {
  CloseLine = EntryLine - CloseLineOffset;
  return(0);
}

int deinit() {
  return(0);
}

double GetLots() {
  if (Lots == 0.0) {
    return(GetLotsByOptimalF(OptimalF, WorstLoss, 0));
  }
  return(Lots);
}

