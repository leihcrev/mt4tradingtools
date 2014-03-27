// Strategy1
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"
#property strict

#include <Position.mqh>
#include <Tweet.mqh>
#include <DateTime.mqh>

// Module variables
double OSAgainstStopLevel;
// -- For directional change
int mode = 0;
double dcPrice;
double extremaPrice;
double currentLevel;
double overshootLevel;
double overshootLevelPeak;
double overshootLevelDrawdown;
bool entried = false;

double modifiedCL;
double modifiedOL;

// -- For tick continuity
int tickContinuity = 0;
int continuitySide = 0;
double previousMid = 0.0;

// -- For avoid weekend
datetime NextWeekendDatetime = 0;

int start() {
  TweetTakeProfitOrStopLoss(Symbol(), MagicNumber);

  UpdateDCOS();
  CountTickContinuity();

  if (WeekendMarginSecs != 0) {
    datetime now = TimeCurrent();
    if (now > NextWeekendDatetime + 60) {
      NextWeekendDatetime = GetNextWeekendDatetime(now, GMTOffset);
      Print("Update NextWeekendDatetime: ", TimeToStr(NextWeekendDatetime, TIME_DATE | TIME_SECONDS));
    }
    if (now > NextWeekendDatetime - WeekendMarginSecs) {
      ClosePosition(Symbol(), MagicNumber, EMPTY, "Close on weekend");
      return(0);
    }
  }

  if (entried) {
    if (MoveSLWhenDD && overshootLevel - currentLevel > OSDrawdownFilter) {
      for (int pos = OrdersTotal(); pos >= 0; pos--) {
        if (!OrderSelect(pos, SELECT_BY_POS)) {
          continue;
        }
        double sign = OrderType() == OP_BUY ? 1 : 0;
        double sl = NormalizeDouble(MathExp(extremaPrice) + sign * SLDistanceWhenDD, Digits);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && sign * (OrderStopLoss() - sl) < 0) {
          if (!OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), OrderExpiration())) {
            Print("Cannot modify StopLoss. ticket=", OrderTicket());
          }
        }
      }
    }
    return(0);
  }
  if (overshootLevel < OSAgainstEntryLevel) {
    ClosePosition(Symbol(), MagicNumber, EMPTY, "Close by directional change");
    return(0);
  }

  double lots, l = 0.0;
  bool isSuccess = true, tpresult;
  if (mode == -1) {
    if (modifiedCL > OSAgainstEntryLevel && modifiedOL < OSAgainstStopLevel) {
      if (TimeCurrent() < UseContinuityFrom || continuitySide >= 0 || tickContinuity < ContinuityThreshold) {
        for (lots = GetLots() - GetPositionLots(Symbol(), MagicNumber, OP_BUY); lots > 0; lots -= l) {
          l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
          tpresult = TakePosition(Symbol(), MagicNumber, OP_BUY , l, Ask * DCThreshold * (OSAgainstStopLevel - modifiedCL) * MathPow(10, Digits), 0, 20, "Take position against overshoot");
          isSuccess = isSuccess && tpresult;
        }
        entried = isSuccess;
      }
    }
  }
  else if (mode ==  1) {
    if (modifiedCL > OSAgainstEntryLevel && modifiedOL < OSAgainstStopLevel) {
      if (TimeCurrent() < UseContinuityFrom || continuitySide <= 0 || tickContinuity < ContinuityThreshold) {
        for (lots = GetLots() - GetPositionLots(Symbol(), MagicNumber, OP_SELL); lots > 0; lots -= l) {
          l = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
          tpresult = TakePosition(Symbol(), MagicNumber, OP_SELL, l, Bid * DCThreshold * (OSAgainstStopLevel - modifiedCL) * MathPow(10, Digits), 0, 20, "Take position against overshoot");
          isSuccess = isSuccess && tpresult;
        }
        entried = isSuccess;
      }
    }
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
      overshootLevelPeak = 0;
      overshootLevelDrawdown = 0;
      entried = false;
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
      overshootLevelPeak = 0;
      overshootLevelDrawdown = 0;
      entried = false;
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
    int i;
    for (i = 0; i < Bars; i++) {
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

    entried = false;
  }

  double dd = overshootLevel - currentLevel;
  if (dd > overshootLevelDrawdown) {
    overshootLevelPeak = overshootLevel;
    overshootLevelDrawdown = dd;
  }
  modifiedCL = currentLevel;
  modifiedOL = overshootLevel;
  double m = 0;
  if (overshootLevelDrawdown > OSDrawdownFilter) {
    if (EntryAfterFiltered) {
      m = overshootLevelDrawdown - overshootLevelPeak - 1.0;
      modifiedCL = currentLevel + m;
      modifiedOL = overshootLevel + m;
    }
    else {
      modifiedCL = OSAgainstStopLevel;
      modifiedOL = OSAgainstStopLevel;
    }
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
    if (!entried && modifiedOL < OSAgainstEntryLevel) {
      if (mode == 1) {
        comment = comment + "AGAINST SELL @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * (OSAgainstEntryLevel - m)), Digits);
      }
      else {
        comment = comment + "AGAINST BUY @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * (OSAgainstEntryLevel - m)), Digits);
      }
    }
    else if (entried && modifiedOL > OSAgainstEntryLevel && modifiedOL < OSAgainstStopLevel) {
      comment = comment + "TAKE PROFIT @ " + DoubleToStr(MathExp(extremaPrice - mode * DCThreshold), Digits);
      if (mode == 1) {
        comment = comment + " / STOP LOSS @ " + DoubleToStr(MathExp(dcPrice + DCThreshold * (OSAgainstStopLevel - m)), Digits);
      }
      else {
        comment = comment + " / STOP LOSS @ " + DoubleToStr(MathExp(dcPrice - DCThreshold * (OSAgainstStopLevel - m)), Digits);
      }
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

void CountTickContinuity() {
  double currentMid = (Bid + Ask) / 2.0;
  if (currentMid == previousMid) {
    return;
  }

  if (continuitySide > 0) {
    if (previousMid < currentMid) {
      tickContinuity++;
    }
    else {
      continuitySide = -1;
      tickContinuity = 1;
    }
  }
  else if (continuitySide < 0) {
    if (previousMid > currentMid) {
      tickContinuity++;
    }
    else {
      continuitySide = 1;
      tickContinuity = 1;
    }
  }
  else {
    if (previousMid != 0.0) {
      continuitySide = previousMid < currentMid ? 1 : previousMid > currentMid ? -1 : 0;
      tickContinuity = 1;
    }
  }

  previousMid = currentMid;
}

int init() {
  OSAgainstStopLevel = OSAgainstEntryLevel + OSAgainstStopOffset;
  NextWeekendDatetime = GetNextWeekendDatetime(TimeCurrent(), GMTOffset);
  return(0);
}

int deinit() {
  if (!IsTesting()) {
    return(0);
  }
  int handle = FileOpen("Strategy1Log.csv", FILE_CSV | FILE_WRITE, ',');
  int n = OrdersHistoryTotal();
  for (int i = 0; i < n; i++) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
      continue;
    }
    int ot = 3, ct = 1;
    if (OrderType() == OP_SELL) {
      ot = 1;
      ct = 3;
    }
    FileWrite(handle,
      StringSetChar(StringSetChar(TimeToStr(OrderOpenTime(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'),
      ot,
      DoubleToString(OrderOpenPrice(), Digits)
    );
    FileWrite(handle,
      StringSetChar(StringSetChar(TimeToStr(OrderCloseTime(), TIME_DATE | TIME_SECONDS), 4, '-'), 7, '-'),
      ct,
      DoubleToString(OrderOpenPrice(), Digits)
    );
  }
  FileClose(handle);
  return(0);
}

double GetLots() {
  if (Lots == 0.0) {
    return(GetLotsByOptimalF(OptimalF, WorstLoss, DCThreshold * OSAgainstStopOffset));
  }
  return(Lots);
}

