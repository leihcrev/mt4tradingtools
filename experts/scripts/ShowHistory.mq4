// ShowHistory.mq4
#property copyright "Valmars, Leihcrev"
#property link      "valmars@bk.ru, kikuchi@xper.jp"

// Input parameters
extern color BuyColor     = Blue;
extern color SellColor    = Red;
extern color PendingColor = Yellow;

int start() {
  int i;

  // Delete old objects
  ObjectsDeleteAll(0, OBJ_ARROW);
  for (i = ObjectsTotal(); i >= 0 ; i--) {
    string objname = ObjectName(i);
    if (ObjectType(objname) == OBJ_TREND) {
      ObjectDelete(objname); 
    }
  }

  // Plot open trades
  for (i = 0; i < OrdersTotal(); i++) {     
    OrderSelect(i, SELECT_BY_POS);
    PlotOpenTrade(true);
  }

  // Plot historical trades
  for (i = 0; i < OrdersHistoryTotal(); i++) {
    OrderSelect(i, SELECT_BY_POS, MODE_HISTORY);
    PlotOpenTrade(false);
    PlotCloseTrade();
  }

  return(0);
}

void PlotOpenTrade(bool isAlive) {
  if (OrderSymbol() != Symbol()) {
    return;
  }

  string Name;
  int Arrow;
  double Color;

  switch (OrderType()) {
  case OP_BUY:
    Arrow = 1;
    Color = BuyColor;
    Name = "open buy";
    break;         
  case OP_SELL:
    Arrow = 2;
    Color = SellColor;
    Name = "open sell";
    break;
  case OP_BUYLIMIT:
    Arrow = 1;
    Color = PendingColor;
    Name = "open buy limit";
    break; 
  case OP_BUYSTOP:
    Arrow = 1;
    Color = PendingColor;
    Name = "open buy stop"; 
    break; 
  case OP_SELLLIMIT:
    Arrow = 2;
    Color = PendingColor;
    Name = "open sell limit";
    break; 
  case OP_SELLSTOP:
    Arrow = 2;
    Color = PendingColor;
    Name = "open sell stop";
    break; 
  }
  Name = OrderTicket() + " " + Name + " " + DoubleToStr(OrderLots(), 2) + " " + 
    OrderSymbol() + " at " + DoubleToStr(OrderOpenPrice(), MarketInfo(OrderSymbol(), MODE_DIGITS));
  ObjectCreate(Name, OBJ_ARROW, 0, OrderOpenTime(), OrderOpenPrice());
  ObjectSet(Name, OBJPROP_ARROWCODE, Arrow); 
  ObjectSet(Name, OBJPROP_COLOR, Color);
  ObjectSetText(Name, TimeToStr(OrderOpenTime(), TIME_DATE | TIME_SECONDS) + " " + OrderComment());

  datetime closetime = TimeCurrent();
  if (!isAlive) {
    closetime = OrderCloseTime();
  }
  // Limit line
  if (OrderTakeProfit() != 0.0) {
    Name = OrderTicket() + " take profit at " + DoubleToStr(OrderTakeProfit(), MarketInfo(OrderSymbol(), MODE_DIGITS));
    ObjectCreate(Name, OBJ_TREND, 0, OrderOpenTime(), OrderTakeProfit(), closetime, OrderTakeProfit());
    ObjectSet(Name, OBJPROP_STYLE, STYLE_DASH); 
    ObjectSet(Name, OBJPROP_WIDTH, 1);
    ObjectSet(Name, OBJPROP_RAY, isAlive);
    ObjectSet(Name, OBJPROP_COLOR, Lime);
  }

  // Stop line
  if (OrderStopLoss() != 0.0) {
    Name = OrderTicket() + " stop loss at " + DoubleToStr(OrderStopLoss(), MarketInfo(OrderSymbol(), MODE_DIGITS));
    ObjectCreate(Name, OBJ_TREND, 0, OrderOpenTime(), OrderStopLoss(), closetime, OrderStopLoss());
    ObjectSet(Name, OBJPROP_STYLE, STYLE_DASH); 
    ObjectSet(Name, OBJPROP_WIDTH, 1);
    ObjectSet(Name, OBJPROP_RAY, isAlive);
    ObjectSet(Name, OBJPROP_COLOR, Red);
  }
}

void PlotCloseTrade() {
  if (OrderSymbol() != Symbol()) {
    return;
  }

  string Name;
  double Color;

  switch (OrderType()) {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
    Color = SellColor;
    Name = "close sell"; 
    break;         
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
    Color = BuyColor;
    Name = "close buy";
    break; 
  }
  Name = OrderTicket() + " " + Name + " " + DoubleToStr(OrderLots(), 2) + " " + 
    OrderSymbol() + " at " + DoubleToStr(OrderOpenPrice(), MarketInfo(OrderSymbol(), MODE_DIGITS));
  ObjectCreate(Name, OBJ_ARROW, 0, OrderCloseTime(), OrderClosePrice());
  ObjectSet(Name, OBJPROP_ARROWCODE, 3); 
  ObjectSet(Name, OBJPROP_COLOR, Color);
  ObjectSetText(Name, TimeToStr(OrderOpenTime(), TIME_DATE | TIME_SECONDS));

  // Link open trade and close trade
  switch (OrderType()) {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
    Color = BuyColor;
    break;         
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
    Color = SellColor;
    break; 
  }
  Name = OrderTicket() + " " + DoubleToStr(OrderOpenPrice(), MarketInfo(OrderSymbol(), MODE_DIGITS)) +
    "->" + DoubleToStr(OrderClosePrice(), MarketInfo(OrderSymbol(), MODE_DIGITS));
  ObjectCreate(Name, OBJ_TREND, 0, OrderOpenTime(), OrderOpenPrice(), OrderCloseTime(), OrderClosePrice());
  ObjectSet(Name, OBJPROP_STYLE, STYLE_DOT); 
  ObjectSet(Name, OBJPROP_WIDTH, 1);
  ObjectSet(Name, OBJPROP_RAY, false);
  ObjectSet(Name, OBJPROP_COLOR, Color); 
}

