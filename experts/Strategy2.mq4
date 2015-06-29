#property strict

#include <stdlib.mqh>
#include <stderror.mqh> 

// Input parameters
// -- Signal
input int    MA_Period       = 136;   // Signal - MA period
input int    MA_Slippage     = 24;    // Signal - MA slippage
input int    WPR_Period      = 16;    // Signal - WPR period
input int    WPR_OpenLevel   = 5;     // Signal - WPR open level
input int    WPR_CloseLevel  = 80;    // Signal - WPR close level
input int    ATR_Period      = 40;    // Signal - ATR period
input int    ATR_StopLevel   = 4;     // Signal - ATR stop level
input int    CCI_Period      = 20;    // Signal - CCI period
input int    CCI_Level       = 100;   // Signal - CCI level
input int    CloseOnlyProfit = 8;     // Signal - Close only profit
// -- Order management
input double StopLoss        = 35;    // Order management - Stop loss
input double TakeProfit      = 25;    // Order management - Take profit
input int    TrailingStop    = 5;     // Order management - Trailing stop
input int    TrailingStep    = 0;     // Order management - Trailing step
input int    WaitSeconds     = 960;   // Order management - Wait seconds since order sent
input int    SlippagePoints  = 3;     // Order management - Slippage points
input double MaxSpread       = 2.0;   // Order management - Max spread
input double Lots            = 1.00;  // Order management - Lots
input double PercentageMM    = 10.0;  // Order management - Money usage(%)
input int    MagicNumber     = 2;     // Order management - Magic number

// Module variables
int    Slippage = 3;
double Pips;
int    WPR_OpenLevel_Buy;
int    WPR_OpenLevel_Sell;
int    WPR_CloseLevel_Buy;
int    WPR_CloseLevel_Sell;
int    CCI_Level_Buy;
int    CCI_Level_Sell;

void OnTick() {
  SetStopLossTakeProfit(StopLoss, TakeProfit);

	int signal = 0;
	double wpr = iWPR(Symbol(), Period(), WPR_Period, 1);
	double atr = iATR(Symbol(), Period(), ATR_Period, 1);
	if (atr > ATR_StopLevel * Pips) {
  	double ma = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMMA, PRICE_CLOSE, 1);
	  double cci = iCCI(Symbol(), Period(), CCI_Period, PRICE_TYPICAL, 1);
    if (Close[1] > ma + MA_Slippage * Pips && wpr < WPR_OpenLevel_Buy && cci < CCI_Level_Buy) {
      signal = 1;
	  }
    if (Close[1] < ma - MA_Slippage * Pips && wpr > WPR_OpenLevel_Sell && cci > CCI_Level_Sell) {
   	  signal = -1;
    }
	}

  // Close position
	int ordersTotal = 0;
  for (int pos = 0; pos < OrdersTotal(); pos++) {
    if (!OrderSelect(pos, SELECT_BY_POS, MODE_TRADES)) {
      continue;
    }
    if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) {
      continue;
    }
    if (OrderType() == OP_BUY) {
      if (signal != 1 && wpr > WPR_CloseLevel_Buy && (CloseOnlyProfit < 0 || Bid > OrderOpenPrice() + CloseOnlyProfit * Pips)) {
        if (!OrderClose(OrderTicket(), OrderLots(), Bid, Slippage)) {
          Print("OrderClose failed with error: ", ErrorDescription(GetLastError()));
          ordersTotal++;
        }
      }
      else {
        ordersTotal++;
      }
    }
    else if (OrderType() == OP_SELL) {
      if (signal != -1 && wpr < WPR_CloseLevel_Sell && (CloseOnlyProfit < 0 || Ask < OrderOpenPrice() - CloseOnlyProfit * Pips)) {
        if (!OrderClose(OrderTicket(), OrderLots(), Ask, Slippage)) {
          Print("OrderClose failed with error: ", ErrorDescription(GetLastError()));
          ordersTotal++;
        }
      }
      else {
        ordersTotal++;
      }
    }
  }

  // Open position
	static datetime timeOrderSent;
	datetime now = TimeCurrent();
	if (ordersTotal == 0 && now >= timeOrderSent + WaitSeconds && Ask - Bid <= MaxSpread * Pips) {
  	if (signal == 1) {
	    if (OrderSend(Symbol(), OP_BUY, GetLots(), Ask, Slippage, 0, 0, "Strategy2", MagicNumber, 0) < 0) {
      	Print("OrderSend failed with error: ", ErrorDescription(GetLastError()));
	    }
    	timeOrderSent = now;
	  }
  	else if (signal == -1) {
	    if (OrderSend(Symbol(), OP_SELL, GetLots(), Bid, Slippage, 0, 0, "Strategy2", MagicNumber, 0) < 0) {
      	Print("OrderSend failed with error: ", ErrorDescription(GetLastError()));
	    }
	    timeOrderSent = now;
	  }
  }
}

void SetStopLossTakeProfit(const double sl, const double tp){
  for (int i = 0; i < OrdersTotal(); i++) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      continue;
    }
    if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) {
      continue;
    }
    double slPrice = OrderStopLoss();
    double tpPrice = OrderTakeProfit();
    double tmp;
    if (OrderType() == OP_BUY) {
      if (slPrice == 0) {
        slPrice = NormalizeDouble(Ask - sl * Pips, Digits);
      }
      if (tpPrice == 0) {
        tpPrice = NormalizeDouble(Ask + tp * Pips, Digits);
      }
      if (TrailingStop > 0 && NormalizeDouble(Ask - TrailingStep * Pips, Digits) > NormalizeDouble(OrderOpenPrice() + TrailingStop * Pips, Digits)) {
        tmp = NormalizeDouble(Bid - TrailingStop * Pips, Digits);
        if (NormalizeDouble(OrderStopLoss(), Digits) < tmp || slPrice == 0) {
          slPrice = tmp;
        }
      }
    }
    else if (OrderType() == OP_SELL) {
      if (slPrice == 0) {
        slPrice = NormalizeDouble(Bid + sl * Pips, Digits);
      }
      if (tpPrice == 0) {
        tpPrice = NormalizeDouble(Bid - tp * Pips, Digits);
      }
      if (TrailingStop > 0 && NormalizeDouble(Bid + TrailingStep * Pips, Digits) < NormalizeDouble(OrderOpenPrice() - TrailingStop * Pips, Digits)) {
        tmp = NormalizeDouble(Ask + TrailingStop * Pips, Digits);
        if (NormalizeDouble(OrderStopLoss(), Digits) > tmp || slPrice == 0) {
          slPrice = tmp;
        }
      }
    }
    if (slPrice != OrderStopLoss() || tpPrice != OrderTakeProfit()) {
      if (!OrderModify(OrderTicket(), OrderOpenPrice(), slPrice, tpPrice, 0)) {
        Print("OrderModify failed with error: ", ErrorDescription(GetLastError()), "/Bid=", Bid, "/Ask=", Ask, "/slPrice=", slPrice, "/tpPrice=", tpPrice);
      }
    }
  }
}

void OnInit() {
  if (Digits == 3 || Digits == 5) {
    Slippage = SlippagePoints * 10;
  }
  else {
    Slippage = SlippagePoints;
  }
  if (Digits < 4) {
    Pips = 0.01;
  }
  else {
    Pips = 0.0001;
  }

  WPR_OpenLevel_Buy   =  WPR_OpenLevel  - 100;
  WPR_OpenLevel_Sell  = -WPR_OpenLevel;
  WPR_CloseLevel_Buy  = -WPR_CloseLevel;
  WPR_CloseLevel_Sell =  WPR_CloseLevel - 100;
  CCI_Level_Buy       = -CCI_Level;
  CCI_Level_Sell      =  CCI_Level;
}
 
void OnDeinit(const int reason) {
}

double GetLots() { 
  if (Lots == 0.0) {
    double a = (PercentageMM * AccountFreeMargin() / MarketInfo(Symbol(), MODE_LOTSIZE));
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    a =  MathFloor(a / lotStep) * lotStep;
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    if (a > maxLot) {
      return(maxLot);
    }
    else {
      double minLot = MarketInfo(Symbol(), MODE_MINLOT);   
      if (a < minLot) {
        return(minLot);
      }
    }
    return(a);
  }    
  return(Lots);
}

double OnTester() {
  int n = OrdersHistoryTotal();
  double hpr[1];
  ArrayResize(hpr, n);

  // Calculate HPR
  double lossRatio = 0;
  for (int i = 0; i < n; i++) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
      continue;
    }
    double r = OrderClosePrice() - OrderOpenPrice();
    if (OrderType() == OP_SELL) {
      r = -r;
    }
    hpr[i] = r / (OrderOpenPrice() * StopLoss * Pips);
    double loss = StopLoss * Pips / OrderOpenPrice();
    if (loss > lossRatio) {
      lossRatio = loss;
    }
  }

  // Calculate sup of OptimalF
  double supF = 25.0 * lossRatio;

  return(MathLog(OptimizeTWR(n, hpr, supF)));
}

double OptimizeTWR(int n, double &hpr[], double supF) {
  double f_inf = 0.0;
  double f = (f_inf + supF) / 2.0;
  double f_sup = supF;
  double eps = 0.00000001;
  
  double twr_inf = CalculateTWR(n, hpr, f_inf);
  double twr = CalculateTWR(n, hpr, f);
  double twr_sup = CalculateTWR(n, hpr, f_sup);
  while (f_sup - f_inf > eps) {
    Print(f_inf, "<", f, "<", f_sup, "/", twr_inf, " ", twr, " ", twr_sup);
    if (twr_inf <= twr && twr <= twr_sup) {
      f_inf = f;
      twr_inf = twr;
      f = f_sup;
      twr = twr_sup;
      f_sup = f_sup + (f_sup - f_inf);
      if (f_sup > supF) {
        f_sup = supF;
      }
      twr_sup = CalculateTWR(n, hpr, f_sup);
    }
    else if (twr_inf <= twr && twr >= twr_sup) {
      f_inf = f_inf + (f - f_inf) / 2.0;
      twr_inf = CalculateTWR(n, hpr, f_inf);
      f_sup = f_sup - (f_sup - f) / 2.0;
      twr_sup = CalculateTWR(n, hpr, f_sup);
    }
    else {
      f_sup = f;
      twr_sup = twr;
      f = f_inf;
      twr = twr_inf;
      f_inf = f_inf - (f_sup - f_inf);
      if (f_inf < 0.0) {
        f_inf = 0.0;
      }
      twr_inf = CalculateTWR(n, hpr, f_inf);
    }
  }

  Print("OptimalF=", f, "/TWR=", twr);
  return(twr);
}

double CalculateTWR(int n, double &hpr[], double f) {
  double twr = 1.0;
  for (int i = 0; i < n; i++) {
    twr *= 1.0 + hpr[i] * f;
  }
  if (MathIsValidNumber(twr)) {
    return(twr);
  }
  return(0);
}
