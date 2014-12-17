// ShowHistory.mq4
#property strict

// Input parameters
input bool  PlotAll      = false;
input color BuyColor     = Blue;
input color SellColor    = Red;
input color PendingColor = Yellow;

void OnStart() {
  string prefix = WindowExpertName() + "_";
  DeleteAll(prefix);
  datetime plotFrom = Time[WindowFirstVisibleBar()];

  // Plot open trades
  for (int i = 0; i < OrdersTotal(); i++) {     
    if (!OrderSelect(i, SELECT_BY_POS)) {
      continue;
    }
    if (OrderSymbol() != Symbol()) {
      continue;
    }
    PlotOpenTrade(prefix, plotFrom, true);
  }

  // Plot historical trades
  for (int i = 0; i < OrdersHistoryTotal(); i++) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
      continue;
    }
    if (OrderSymbol() != Symbol()) {
      continue;
    }
    PlotOpenTrade(prefix, plotFrom, false);
    PlotCloseTrade(prefix, plotFrom);
  }
}

void DeleteAll(const string prefix) {
  long cid = ChartID();
  for (int i = ObjectsTotal(); i >= 0; i--) {
    string objname = ObjectName(i);
    if (ObjectFind(cid, objname) >= 0 && StringFind(objname, prefix) == 0) {
      ObjectDelete(cid, objname);
    }
  }
}

void PlotOpenTrade(const string prefix, const datetime plotFrom, bool isAlive) {
  if (OrderCloseTime() != 0 && OrderCloseTime() < plotFrom) {
    return;
  }

  int arrowCode = 1;
  double arrowColor = PendingColor;

  switch (OrderType()) {
  case OP_BUY:
    arrowCode = 1;
    arrowColor = BuyColor;
    break;         
  case OP_SELL:
    arrowCode = 2;
    arrowColor = SellColor;
    break;
  case OP_BUYLIMIT:
    arrowCode = 1;
    arrowColor = PendingColor;
    break; 
  case OP_BUYSTOP:
    arrowCode = 1;
    arrowColor = PendingColor;
    break; 
  case OP_SELLLIMIT:
    arrowCode = 2;
    arrowColor = PendingColor;
    break; 
  case OP_SELLSTOP:
    arrowCode = 2;
    arrowColor = PendingColor;
    break; 
  }
  string objname = prefix + "Open_" + IntegerToString(OrderTicket());
  ObjectCreate(objname, OBJ_ARROW, 0, OrderOpenTime(), OrderOpenPrice());
  ObjectSet(objname, OBJPROP_ARROWCODE, arrowCode); 
  ObjectSet(objname, OBJPROP_COLOR, arrowColor);
  ObjectSetText(objname, TimeToStr(OrderOpenTime(), TIME_DATE | TIME_SECONDS) + " " + OrderComment());

  datetime closetime = TimeCurrent();
  if (!isAlive) {
    closetime = OrderCloseTime();
  }
  // Limit line
  if (OrderTakeProfit() != 0.0) {
    objname = prefix + "TakeProfit_" + IntegerToString(OrderTicket());
    ObjectCreate(objname, OBJ_TREND, 0, OrderOpenTime(), OrderTakeProfit(), closetime, OrderTakeProfit());
    ObjectSet(objname, OBJPROP_STYLE, STYLE_DASH); 
    ObjectSet(objname, OBJPROP_WIDTH, 1);
    ObjectSet(objname, OBJPROP_RAY, isAlive);
    ObjectSet(objname, OBJPROP_COLOR, Lime);
  }

  // Stop line
  if (OrderStopLoss() != 0.0) {
    objname = prefix + "StopLoss_" + IntegerToString(OrderTicket());
    ObjectCreate(objname, OBJ_TREND, 0, OrderOpenTime(), OrderStopLoss(), closetime, OrderStopLoss());
    ObjectSet(objname, OBJPROP_STYLE, STYLE_DASH); 
    ObjectSet(objname, OBJPROP_WIDTH, 1);
    ObjectSet(objname, OBJPROP_RAY, isAlive);
    ObjectSet(objname, OBJPROP_COLOR, Red);
  }
}

void PlotCloseTrade(const string prefix, const datetime plotFrom) {
  if (OrderCloseTime() != 0 && OrderCloseTime() < plotFrom) {
    return;
  }

  double arrowColor = PendingColor;

  switch (OrderType()) {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
    arrowColor = SellColor;
    break;         
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
    arrowColor = BuyColor;
    break; 
  }
  string objname = prefix + "Close_" + IntegerToString(OrderTicket());
  ObjectCreate(objname, OBJ_ARROW, 0, OrderCloseTime(), OrderClosePrice());
  ObjectSet(objname, OBJPROP_ARROWCODE, 3); 
  ObjectSet(objname, OBJPROP_COLOR, arrowColor);
  ObjectSetText(objname, TimeToStr(OrderOpenTime(), TIME_DATE | TIME_SECONDS));

  // Link open trade and close trade
  arrowColor = arrowColor == BuyColor ? SellColor : BuyColor;
  objname = prefix + "Link_" + IntegerToString(OrderTicket());
  ObjectCreate(objname, OBJ_TREND, 0, OrderOpenTime(), OrderOpenPrice(), OrderCloseTime(), OrderClosePrice());
  ObjectSet(objname, OBJPROP_STYLE, STYLE_DOT); 
  ObjectSet(objname, OBJPROP_WIDTH, 1);
  ObjectSet(objname, OBJPROP_RAY, false);
  ObjectSet(objname, OBJPROP_COLOR, arrowColor); 
}
