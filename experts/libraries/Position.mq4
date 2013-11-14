//+------------------------------------------------------------------+
//|                                                     Position.mq4 |
//|                                                 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "KIKUCHI Shunsuke"
#property library

#include <Tweet.mqh>
#include <stdlib.mqh>

/**
 * Take position immediatly.
 */
bool TakePosition(string symbol, int magic, int op, double lots, int stopLossPips, int takeProfitPips, int slippage, string comment) {
  double orderPrice;
  double stopLossPrice = 0.0;
  double takeProfitPrice = 0.0;

  color c;

  RefreshRates();
  if (op == OP_BUY) {
    orderPrice = Ask;
    if (stopLossPips != 0) {
      stopLossPrice = Ask - stopLossPips * MarketInfo(symbol, MODE_POINT);
    }
    if (takeProfitPips != 0) {
      takeProfitPrice = Ask + takeProfitPips * MarketInfo(symbol, MODE_POINT);
    }
    c = Lime;
  }
  else if (op == OP_SELL) {
    orderPrice = Bid;
    if (stopLossPips != 0) {
      stopLossPrice = Bid + stopLossPips * MarketInfo(symbol, MODE_POINT);
    }
    if (takeProfitPips != 0) {
      takeProfitPrice = Bid - takeProfitPips * MarketInfo(symbol, MODE_POINT);
    }
    c = Red;
  }
  else {
    return(false);
  }

  int ticket = OrderSend(symbol, op, lots, orderPrice, slippage, 0.0, 0.0, comment, magic, 0, c);
  int lastError = GetLastError();
  if (ticket > 0) {
    TweetOpenPosition(ticket, comment);
    if (stopLossPips != 0 || takeProfitPips != 0) {
      OrderModify(ticket, 0.0, stopLossPrice, takeProfitPrice, 0);
      lastError = GetLastError();
      if (lastError != 0) {
        Print("TakePosition(", symbol, ", ", magic, ", ", op, ", ", lots, ", ", stopLossPips, ", ", takeProfitPips, ", ", slippage, ", ", comment, "): error occured when trying to modify order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
        Print("MarginRequired=", MarketInfo(symbol, MODE_MARGINREQUIRED), ", stopLossPrice=", stopLossPrice, ", takeProfitPrice=", takeProfitPrice);
      }
    }
  }
  else {
    Print("TakePosition(", symbol, ", ", magic, ", ", op, ", ", lots, ", ", stopLossPips, ", ", takeProfitPips, ", ", slippage, ", ", comment, "): error occured when trying to modify order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
    Print("MarginRequired=", MarketInfo(symbol, MODE_MARGINREQUIRED), ", stopLossPrice=", stopLossPrice, ", takeProfitPrice=", takeProfitPrice);
    return(false);
  }

  return(true);
}

/**
 * Close position immediatly.
 */
void ClosePosition(string symbol, int magic, int op, string comment) {
  if (op == -1) {
    ClosePosition(symbol, magic, OP_BUY, comment);
    ClosePosition(symbol, magic, OP_SELL, comment);
    return;
  }

  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    for (int try = 0; try < 10; try++) {
      OrderSelect(i, SELECT_BY_POS);
      if (OrderSymbol() == symbol && OrderMagicNumber() == magic && OrderType() == op) {
        RefreshRates();
        double orderPrice;
        if (op == OP_BUY) {
          orderPrice = Bid;
        }
        else if (op == OP_SELL) {
          orderPrice = Ask;
        }
        OrderClose(OrderTicket(), OrderLots(), orderPrice, 10, Blue);
        int lastError = GetLastError();
        if (lastError == 0) {
          TweetClosePosition(OrderTicket(), comment);
          break;
        }
        else {
          Print("ClosePosition(", symbol, ", ", magic, ", ", op, ", ", comment, "): error occured when trying to close order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
        }
      }
    }
  }

  return;
}

/**
 * Get total of position lots.
 */
double GetPositionLots(string symbol, int magic, int op) {
  double currentLots = 0.0;
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          currentLots += OrderLots();
        }
      }
    }
  }
  return(currentLots);
}

/**
 * Return true if position exists.
 */
bool HasPosition(string symbol, int magic, int op) {
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          return(true);
        }
      }
    }
  }
  return(false);
}

/**
 * Return optimal lots.
 */
double GetOptimalLots(string symbol, double weight, int stopLossPips) {
  double requiredAssetPerLot = MarketInfo(symbol, MODE_MARGINREQUIRED) + stopLossPips * MarketInfo(symbol, MODE_TICKVALUE);
  double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
  double optimalLots = MathFloor(AccountBalance() * weight / requiredAssetPerLot / lotStep) * lotStep;
  return(NormalizeDouble(optimalLots, MarketInfo(symbol, MODE_DIGITS)));
}

/**
 * Return optimal lots by OptimalF.
 */
double GetLotsByOptimalF(double OptimalF, double WorstLoss, double SL) {
  // Calculate optional lot size
  double lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
  double l = -AccountBalance() * OptimalF / WorstLoss / lotSize;

  // Check leverage
  int leverage = AccountLeverage();
  double mid = (Ask + Bid) / 2.0;
  double requiredMargin = mid * (lotSize / leverage + SL * lotSize);
  string ccy = StringSubstr(Symbol(), 3, 3);
  if (AccountCurrency() != ccy) {
    requiredMargin = requiredMargin * (MarketInfo(ccy + AccountCurrency(), MODE_ASK) + MarketInfo(ccy + AccountCurrency(), MODE_BID)) / 2.0;
  }
  if (requiredMargin * l > AccountBalance()) {
    l = AccountBalance() / requiredMargin;
  }
  
  // Round
  double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
  l = MathFloor(l / lotStep) * lotStep;

  return(l);
}

/**
 * Move stop loss to break even when market price is over threshold (+/- market price * breakEvenThresholdPercent).
 */
void MoveStopLossToBreakEven(string symbol, int magic, int op, double breakEvenThresholdPercent) {
  if (breakEvenThresholdPercent < 0.0) {
    return;
  }
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          if (OrderType() == OP_BUY) {
            if (OrderOpenPrice() <= OrderStopLoss()) {
              continue;
            }
            if (Ask < OrderOpenPrice() * (1.0 + breakEvenThresholdPercent / 100.0)) {
              continue;
            }
          }
          else if (OrderType() == OP_SELL) {
            if (OrderOpenPrice() >= OrderStopLoss()) {
              continue;
            }
            if (Bid > OrderOpenPrice() * (1.0 - breakEvenThresholdPercent / 100.0)) {
              continue;
            }
          }
          else {
            continue;
          }
          OrderModify(OrderTicket(), 0.0, OrderOpenPrice(), OrderTakeProfit(), OrderExpiration());
          int lastError = GetLastError();
          if (lastError != 0) {
            Print("MoveStopLossToBreakEven(", symbol, ", ", magic, ", ", op, ", ", breakEvenThresholdPercent, "): error occured when trying to modify order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
          }
        }
      }
    }
  }
}

/**
 * Move stop loss and take profit by a half-life.
 */
void MoveSLAndTPByHalfLife(string symbol, int magic, int op, int halfLifePeriodMinutes) {
  static datetime lastChecked = 0;
  if (halfLifePeriodMinutes <= 0) {
    return;
  }
  if (lastChecked == 0) {
    lastChecked = Time[0];
    return;
  }
  if (lastChecked == Time[0]) {
    return;
  }
  lastChecked = Time[0];
  double factor = MathPow(2, - (0.0 + Period()) / halfLifePeriodMinutes) / Point;
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          if (OrderType() != OP_BUY) {
            if (OrderType() != OP_SELL) {
              continue;
            }
          }
          double newTakeProfit = OrderOpenPrice() + MathRound((OrderTakeProfit() - OrderOpenPrice()) * factor) * Point;
          double newStopLoss = OrderOpenPrice() + MathRound((OrderStopLoss() - OrderOpenPrice()) * factor) * Point;
          if (MathAbs(OrderTakeProfit() - newTakeProfit) >= Point || MathAbs(OrderStopLoss() - newStopLoss) >= Point) {
            OrderModify(OrderTicket(), 0.0, newStopLoss, newTakeProfit, OrderExpiration());
            int lastError = GetLastError();
            if (lastError != 0) {
              Print("MoveSLAndTPByHalfLife(", symbol, ", ", magic, ", ", op, ", ", halfLifePeriodMinutes, "): error occured when trying to modify order. ",
                "OrderModify(", OrderTicket(), ", 0.0, ", newStopLoss, ", ", newTakeProfit, ", ", OrderExpiration(), ") -> GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
              Print("factor=", factor);
              Print("Target position: buy/sell=", OrderType(), ", open price=", OrderOpenPrice(), ", S/L=", OrderStopLoss(), ", T/P=", OrderTakeProfit(), ", Market=", Bid, "/", Ask);
            }
          }
        }
      }
    }
  }
}

/**
 * Trailing stop.
 */
void Trail(string symbol, int magic, int op, double distancePercentUnderBE, double distancePercentOverBE) {
  static datetime lastChecked = 0;
  if (distancePercentUnderBE == 0.0) {
    if (distancePercentOverBE == 0.0) {
      return;
    }
  }
  if (lastChecked == 0) {
    lastChecked = Time[0];
    return;
  }
  if (lastChecked == Time[0]) {
    return;
  }
  lastChecked = Time[0];
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          double newStopLoss;
          if (OrderType() == OP_BUY) {
            if (OrderOpenPrice() > Bid) {
              newStopLoss = NormalizeDouble(Bid * (1.0 - distancePercentUnderBE / 100.0), Digits);
            }
            else {
              newStopLoss = NormalizeDouble(Bid * (1.0 - distancePercentOverBE / 100.0), Digits);
            }
            if (newStopLoss < OrderStopLoss()) {
              continue;
            }
          }
          else if (OrderType() == OP_SELL) {
            if (OrderOpenPrice() < Ask) {
              newStopLoss = NormalizeDouble(Ask * (1.0 + distancePercentUnderBE / 100.0), Digits);
            }
            else {
              newStopLoss = NormalizeDouble(Ask * (1.0 + distancePercentOverBE / 100.0), Digits);
            }
            if (newStopLoss > OrderStopLoss()) {
              continue;
            }
          }
          else {
            continue;
          }
          if (MathAbs(OrderStopLoss() - newStopLoss) >= Point) {
            OrderModify(OrderTicket(), 0.0, newStopLoss, OrderTakeProfit(), OrderExpiration());
            int lastError = GetLastError();
            if (lastError == 0) {
              Print("Trail(", symbol, ", ", magic, ", ", op, ", ", distancePercentUnderBE, ", ", distancePercentOverBE, "): done successfully.");
            }
            else {
              Print("Trail(", symbol, ", ", magic, ", ", op, ", ", distancePercentUnderBE, ", ", distancePercentOverBE, "): error occured when trying to modify order. ",
                "OrderModify(", OrderTicket(), ", 0.0, ", newStopLoss, ", ", OrderTakeProfit(), ", ", OrderExpiration(), ") -> GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
              Print("Target position: buy/sell=", OrderType(), ", open price=", OrderOpenPrice(), ", S/L=", OrderStopLoss(), ", T/P=", OrderTakeProfit(), ", Market=", Bid, "/", Ask);
            }
          }
        }
      }
    }
  }
}

/**
 * Trailing-stop by fixed Risk/Reward ratio.
 */
void TrailByFixedRiskRewardRatio(string symbol, int magic, int op, double riskRewardRatio) {
  static datetime lastChecked = 0;
  if (riskRewardRatio == 0.0) {
    return;
  }
  if (lastChecked == 0) {
    lastChecked = Time[0];
    return;
  }
  if (lastChecked == Time[0]) {
    return;
  }
  lastChecked = Time[0];
  for (int i = 0; i < OrdersTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS);
    if (OrderMagicNumber() == magic) {
      if (OrderSymbol() == symbol) {
        if (op == -1 || op == OrderType()) {
          double newStopLoss;
          if (OrderTakeProfit() == 0.0) {
            continue;
          }
          if (OrderStopLoss() == 0.0) {
            continue;
          }
          if (OrderType() == OP_BUY) {
            newStopLoss = NormalizeDouble(Bid - (OrderTakeProfit() - Bid) / riskRewardRatio, Digits);
            if (newStopLoss < OrderStopLoss()) {
              continue;
            }
          }
          else if (OrderType() == OP_SELL) {
            newStopLoss = NormalizeDouble(Ask + (Ask - OrderTakeProfit()) / riskRewardRatio, Digits);
            if (newStopLoss > OrderStopLoss()) {
              continue;
            }
          }
          else {
            continue;
          }
          if (MathAbs(OrderStopLoss() - newStopLoss) >= Point) {
            OrderModify(OrderTicket(), 0.0, newStopLoss, OrderTakeProfit(), OrderExpiration());
            int lastError = GetLastError();
            if (lastError == 0) {
              Print("TrailByFixedRiskRewardRatio(", symbol, ", ", magic, ", ", op, ", ", riskRewardRatio, "): done successfully.");
            }
            else {
              Print("TrailByFixedRiskRewardRatio(", symbol, ", ", magic, ", ", op, ", ", riskRewardRatio, "): error occured when trying to modify order. ",
                "OrderModify(", OrderTicket(), ", 0.0, ", newStopLoss, ", ", OrderTakeProfit(), ", ", OrderExpiration(), ") -> GetLastError()=", lastError);
              Print("Target position: buy/sell=", OrderType(), ", open price=", OrderOpenPrice(), ", S/L=", OrderStopLoss(), ", T/P=", OrderTakeProfit(), ", Market=", Bid, "/", Ask);
            }
          }
        }
      }
    }
  }
}

