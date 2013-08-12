// ShowMarketInfo.mq4
#property copyright "Leihcrev"
#property link      "kikuchi@xper.jp"

// MODE_LOW 1 Low day price. 
// MODE_HIGH 2 High day price. 
// MODE_TIME 5 The last incoming tick time (last known server time). 
// MODE_BID 9 Last incoming bid price. For the current symbol, it is stored in the predefined variable Bid 
// MODE_ASK 10 Last incoming ask price. For the current symbol, it is stored in the predefined variable Ask 
// MODE_POINT 11 Point size in the quote currency. For the current symbol, it is stored in the predefined variable Point 
// MODE_DIGITS 12 Count of digits after decimal point in the symbol prices. For the current symbol, it is stored in the predefined variable Digits 
// MODE_SPREAD 13 Spread value in points. 
// MODE_STOPLEVEL 14 Stop level in points. 
// MODE_LOTSIZE 15 Lot size in the base currency. 
// MODE_TICKVALUE 16 Tick value in the deposit currency. 
// MODE_TICKSIZE 17 Tick size in the quote currency. 
// MODE_SWAPLONG 18 Swap of the long position. 
// MODE_SWAPSHORT 19 Swap of the short position. 
// MODE_STARTING 20 Market starting date (usually used for futures). 
// MODE_EXPIRATION 21 Market expiration date (usually used for futures). 
// MODE_TRADEALLOWED 22 Trade is allowed for the symbol. 
// MODE_MINLOT 23 Minimum permitted amount of a lot. 
// MODE_LOTSTEP 24 Step for changing lots. 
// MODE_MAXLOT 25 Maximum permitted amount of a lot. 
// MODE_SWAPTYPE 26 Swap calculation method. 0 - in points; 1 - in the symbol base currency; 2 - by interest; 3 - in the margin currency. 
// MODE_PROFITCALCMODE 27 Profit calculation mode. 0 - Forex; 1 - CFD; 2 - Futures. 
// MODE_MARGINCALCMODE 28 Margin calculation mode. 0 - Forex; 1 - CFD; 2 - Futures; 3 - CFD for indices. 
// MODE_MARGININIT 29 Initial margin requirements for 1 lot. 
// MODE_MARGINMAINTENANCE 30 Margin to maintain open positions calculated for 1 lot. 
// MODE_MARGINHEDGED 31 Hedged margin calculated for 1 lot. 
// MODE_MARGINREQUIRED 32 Free margin required to open 1 lot for buying. 
// MODE_FREEZELEVEL 33 Order freeze level in points. If the execution price lies within the range defined by the freeze level, the order cannot be modified, cancelled or closed. 

int start() {
  Print("LOW=", MarketInfo(Symbol(), MODE_LOW));
  Print("HIGH=", MarketInfo(Symbol(), MODE_HIGH));
  Print("TIME=", MarketInfo(Symbol(), MODE_TIME));
  Print("BID=", MarketInfo(Symbol(), MODE_BID));
  Print("ASK=", MarketInfo(Symbol(), MODE_ASK));
  Print("POINT=", MarketInfo(Symbol(), MODE_POINT));
  Print("DIGITS=", MarketInfo(Symbol(), MODE_DIGITS));
  Print("SPREAD=", MarketInfo(Symbol(), MODE_SPREAD));
  Print("STOPLEVEL=", MarketInfo(Symbol(), MODE_STOPLEVEL));
  Print("LOTSIZE=", MarketInfo(Symbol(), MODE_LOTSIZE));
  Print("TICKVALUE=", MarketInfo(Symbol(), MODE_TICKVALUE));
  Print("TICKSIZE=", MarketInfo(Symbol(), MODE_TICKSIZE));
  Print("SWAPLONG=", MarketInfo(Symbol(), MODE_SWAPLONG));
  Print("SWAPSHORT=", MarketInfo(Symbol(), MODE_SWAPSHORT));
  Print("STARTING=", MarketInfo(Symbol(), MODE_STARTING));
  Print("EXPIRATION=", MarketInfo(Symbol(), MODE_EXPIRATION));
  Print("TRADEALLOWED=", MarketInfo(Symbol(), MODE_TRADEALLOWED));
  Print("MINLOT=", MarketInfo(Symbol(), MODE_MINLOT));
  Print("LOTSTEP=", MarketInfo(Symbol(), MODE_LOTSTEP));
  Print("MAXLOT=", MarketInfo(Symbol(), MODE_MAXLOT));
  Print("SWAPTYPE=", MarketInfo(Symbol(), MODE_SWAPTYPE));
  Print("PROFITCALCMODE=", MarketInfo(Symbol(), MODE_PROFITCALCMODE));
  Print("MARGINCALCMODE=", MarketInfo(Symbol(), MODE_MARGINCALCMODE));
  Print("MARGININIT=", MarketInfo(Symbol(), MODE_MARGININIT));
  Print("MARGINMAINTENANCE=", MarketInfo(Symbol(), MODE_MARGINMAINTENANCE));
  Print("MARGINHEDGED=", MarketInfo(Symbol(), MODE_MARGINHEDGED));
  Print("MARGINREQUIRED=", MarketInfo(Symbol(), MODE_MARGINREQUIRED));
  Print("FREEZELEVEL=", MarketInfo(Symbol(), MODE_FREEZELEVEL));
  return(0);
}

