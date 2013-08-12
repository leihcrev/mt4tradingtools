//+------------------------------------------------------------------+
//|                                                        Tweet.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 KIKUCHI Shunsuke"
#property library

#import "shell32.dll"
int ShellExecuteA(int hWnd, int lpVerb, string lpFile, string lpParameters, int lpDirectory, int nCmdShow);
#import

string TweetConsolePath = "C:\\Program Files\\TweetConsole\\twtcnsl.exe";

/**
 * Tweet position opening message.
 */
void TweetOpenPosition(int ticket, string comment) {
  if (IsOptimization()) {
    return;
  }

  if (comment != "") {
    comment = " (" + comment + ")";
  }

  OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
  Tweet("Strategy "
    + OrderMagicNumber()
    + comment
    + " - Open position: "
    + StringSubstr(Symbol(), 0, 6)
    + " "
    + GetBuySellString(OrderType())
    + "@"
    + DoubleToStr(OrderOpenPrice(), Digits)
  );

  return;
}

/**
 * Tweet position closing message.
 */
void TweetClosePosition(int ticket, string comment) {
  if (IsOptimization()) {
    return;
  }

  OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY);
  double openPrice = OrderOpenPrice();
  double closePrice = OrderClosePrice();
  double pips = (closePrice - openPrice) / Point * (-1 * (OrderType() == OP_SELL) + (OrderType() == OP_BUY));
  double scale = 0;
  if (Digits == 3 || Digits == 5) {
    pips /= 10.0;
    scale = 1;
  }
  string winLose;

  if (pips > 0) {
    winLose = "Win";
  }
  else if (pips < 0) {
    winLose = "Lose";
    pips *= -1;
  }
  else {
    winLose = "(Even)";
  }

  if (comment != "") {
    comment = " (" + comment + ")";
  }

  Tweet("Strategy "
    + OrderMagicNumber()
    + comment
    + " - Close position: "
    + StringSubstr(Symbol(), 0, 6)
    + " "
    + GetBuySellString(1 - OrderType())
    + "@"
    + DoubleToStr(closePrice, Digits)
    + " (Open price = "
    + DoubleToStr(openPrice, Digits)
    + " / "
    + DoubleToStr(pips, scale)
    + " pips "
    + winLose
    + ")"
  );

  return;
}

/**
 * Return string indicates buy/sell.
 *   orderType == OP_BUY: "Buy"
 *   orderType == OP_SELL: "Sell"
 *   otherwise: ""
 */
string GetBuySellString(int orderType) {
  if (orderType == OP_BUY) {
    return("Buy");
  }
  else if (orderType == OP_SELL) {
    return("Sell");
  }
  
  return("");
}

/**
 * Tweet message(msg).
 */
void Tweet(string msg) {
  if (IsOptimization()) {
    return;
  }

  if (IsTesting()) {
    Print(msg);
  }
  else {
    if (!IsDllsAllowed()) {
      return;
    }
    ShellExecuteA(0, 0, TweetConsolePath, "/t \"" + msg + "\"", 0, 0);
  }
  
  return;
}

/**
 * Tweet take profit or stop loss message.
 */
void TweetTakeProfitOrStopLoss(string symbol, int magicNumber) {
  if (IsOptimization()) {
    return;
  }

  int i;
  static string pKey[256];
  static int pValue[256];
  static datetime pCloseTime[256];
  static int pMax = 0;
  int pIndex = -1;
  for (int pi = 0; pi < pMax; pi++) {
    if (pKey[pi] == symbol + magicNumber) {
      pIndex = pi;
      break;
    }
  }
  if (pIndex == -1) {
    pIndex = pMax;
    pMax++;
    pKey[pIndex] = symbol + magicNumber;
    pCloseTime[pIndex] = 0;
    pValue[pIndex] = OrdersHistoryTotal();
    for (i = 0; i < OrdersHistoryTotal(); i++) {
      OrderSelect(i, SELECT_BY_POS, MODE_HISTORY);
      if (OrderSymbol() != symbol || OrderMagicNumber() != magicNumber) {
        continue;
      }
      if (OrderCloseTime() == 0) {
        pValue[pIndex] = OrderTicket();
        return;
      }
    }
    return;
  }
  
  int newPValue = OrdersHistoryTotal();
  datetime newPCloseTime = TimeCurrent() - 1;
  for (i = OrdersHistoryTotal() - 1; i >= pValue[pIndex]; i--) {
    OrderSelect(i, SELECT_BY_POS, MODE_HISTORY);
    if (OrderSymbol() != symbol || OrderMagicNumber() != magicNumber) {
      continue;
    }
    if (OrderCloseTime() == 0) {
      newPValue = OrderTicket();
      continue;
    }
    if (OrderCloseTime() <= pCloseTime[pIndex] && OrderCloseTime() > newPCloseTime) {
      continue;
    }
    double cp = OrderClosePrice();
    double tp = OrderTakeProfit();
    double sl = OrderStopLoss();
    if (OrderType() == OP_BUY && cp != 0 && tp != 0 && cp >= tp
      || OrderType() == OP_SELL && cp != 0 && tp != 0 && cp <= tp) {
      TweetClosePosition(OrderTicket(), "Take profit");
    }
    else if (OrderType() == OP_BUY && cp != 0 && sl != 0 && cp <= sl
      || OrderType() == OP_SELL && cp != 0 && sl != 0 && cp >= sl) {
      TweetClosePosition(OrderTicket(), "Stop loss");
    }
  }

  pValue[pIndex] = newPValue;
  pCloseTime[pIndex] = newPCloseTime;
  return;
}

