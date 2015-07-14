#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots 7

#property indicator_level1  1
#property indicator_level2  0
#property indicator_level3  -1

#property indicator_label1  "MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "WPR"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCyan
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "ATR ON"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLime
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "ATR OFF"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

#property indicator_label5  "CCI"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "Signal Buy"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrLime
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "Signal Sell"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrRed
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

input int    MaxBars         = 1000;  // Max bars for calculation
input int    MA_Period       = 158;   // Signal - MA period
input double MA_Slippage     = 30.0;  // Signal - MA slippage
input int    WPR_Period      = 8;     // Signal - WPR period
input double WPR_OpenLevel   = 5.0;   // Signal - WPR open level
input double WPR_CloseLevel  = 60.0;  // Signal - WPR close level
input int    ATR_Period      = 28;    // Signal - ATR period
input double ATR_StopLevel   = 2.0;   // Signal - ATR stop level
input int    CCI_Period      = 12;    // Signal - CCI period
input double CCI_Level       = 95.0;  // Signal - CCI level

double BufMA[];
double BufWPR[];
double BufATROn[];
double BufATROff[];
double BufCCI[];
double BufSignalBuy[];
double BufSignalSell[];

double Pips;

int OnInit() {
  SetIndexBuffer(0, BufMA);
  SetIndexBuffer(1, BufWPR);
  SetIndexBuffer(2, BufATROn);
  SetIndexBuffer(3, BufATROff);
  SetIndexBuffer(4, BufCCI);
  SetIndexBuffer(5, BufSignalBuy);
  SetIndexBuffer(6, BufSignalSell);

  SetIndexArrow(5, 241);
  SetIndexArrow(6, 242);

  IndicatorSetString(INDICATOR_LEVELTEXT, 0, "Sell");
  IndicatorSetString(INDICATOR_LEVELTEXT, 2, "Buy");

  if (Digits < 4) {
    Pips = 0.01;
  }
  else {
    Pips = 0.0001;
  }

  return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
  int limit = rates_total - prev_calculated;
  if (prev_calculated == 0) {
    if (limit >= MaxBars) {
      limit = MaxBars - 1;
    }
  }
  else {
    limit++;
  }

  for (int i = limit - 1; i >= 0; i--) {
  	double ma = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMMA, PRICE_CLOSE, i);
  	double wpr = iWPR(Symbol(), Period(), WPR_Period, i);
	  double atr = iATR(Symbol(), Period(), ATR_Period, i);
	  double cci = iCCI(Symbol(), Period(), CCI_Period, PRICE_TYPICAL, i);

    BufMA[i] = (ma - close[i]) / (MA_Slippage * Pips);
    BufWPR[i] = (wpr + 50.0) / (50.0 - WPR_OpenLevel);
    BufATROn[i] = atr > ATR_StopLevel * Pips ? 0 : EMPTY_VALUE;
    BufATROff[i] = atr > ATR_StopLevel * Pips ? EMPTY_VALUE : 0;
    BufCCI[i] = cci / CCI_Level;

    if (BufMA[i+1] < -1 && BufWPR[i+1] < -1 && BufATROn[i+1] == 0 && BufCCI[i+1] < -1) {
      BufSignalBuy[i] = -2;
    }
    if (BufMA[i+1] > 1 && BufWPR[i+1] > 1 && BufATROn[i+1] == 0 && BufCCI[i+1] > 1) {
      BufSignalSell[i] = 2;
    }
  }

  return(rates_total);
}
