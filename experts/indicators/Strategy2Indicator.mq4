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

void OnDeinit(const int reason) {
  HideLine("Strategy2Buy");
  HideLine("Strategy2Sell");
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

  double buyMA, sellMA, buyWPR, sellWPR, buyCCI, sellCCI;
  EstimateRangeByMA(0, buyMA, sellMA);
  EstimateRangeByWPR(0, buyWPR, sellWPR);
  EstimateRangeByCCI(0, buyCCI, sellCCI);
//  Print("MA: ", buyMA, "/", sellMA, ", WPR: ", buyWPR, "/", sellWPR, ", CCI: ", buyCCI, "/", sellCCI);
  double buyLine = MathMin(buyWPR, buyCCI);
  double sellLine = MathMax(sellWPR, sellCCI);
  string comment = "Buy: ";
  if (buyLine > buyMA) {
    PlotLine("Strategy2Buy", buyLine, clrLime);
    comment = comment + DoubleToString(buyLine, Digits);
  }
  else {
    HideLine("Strategy2Buy");
    comment = comment + "-";
  }
  IndicatorSetString(INDICATOR_LEVELTEXT, 2, comment);
  comment = "Sell: ";
  if (sellLine < sellMA) {
    PlotLine("Strategy2Sell", sellLine, clrRed);
    comment = comment + DoubleToString(sellLine, Digits);
  }
  else {
    HideLine("Strategy2Sell");
    comment = comment + "-";
  }
  IndicatorSetString(INDICATOR_LEVELTEXT, 0, comment);

  return(rates_total);
}

void PlotLine(const string objname, const double price, const color clr) {
  if (ObjectFind(objname) == -1) {
    ObjectCreate(objname, OBJ_HLINE, 0, 0, price);
    ObjectSet(objname, OBJPROP_COLOR, clr);
    ObjectSetString(ChartID(), objname, OBJPROP_TEXT, objname);
    ObjectSetInteger(ChartID(), objname, OBJPROP_BACK, true);
  }
  else {
    ObjectSet(objname, OBJPROP_PRICE1, price);
  }
}

void HideLine(const string objname) {
  if (ObjectFind(objname) == -1) {
    return;
  }
  ObjectDelete(objname);
}

/**
 * Buy : price > buyThreshold
 * Sell: price < sellThreshold
 */
void EstimateRangeByMA(const int shift, double &buyThreshold, double &sellThreshold) {
  // SMMA[i] = (SMMA[i+1] * N - SMMA[i+1] + Close[i]) / N
  //         = (SMMA[i+1] * (N - 1) + Close[i]) / N
  // Buy:
  // 　 Close[i] > SMMA'[i] + Slippage
  // → Close[i] > (SMMA[i+1] * (N - 1) + Close[i]) / N + Slippage
  // → Close[i] * N > SMMA[i+1] * (N - 1) + Close[i] + Slippage * N
  // → Close[i] * (N - 1) > SMMA[i+1] * (N - 1) + Slippage * N
  // ∴ BuyThresholdPrice = SMMA[i+1] + Slippage * N / (N - 1)
  // Sell:
  // 　 Close[i] < SMMA'[i] - Slippage
  // → Close[i] < (SMMA[i+1] * (N - 1) + Close[i]) / N - Slippage
  // → Close[i] * N < SMMA[i+1] * (N - 1) + Close[i] - Slippage * N
  // → Close[i] * (N - 1) < SMMA[i+1] * (N - 1) - Slippage * N
  // ∴ SellThresholdPrice = SMMA[i+1] - Slippage * N / (N - 1)
  double gap = MA_Slippage * Pips * MA_Period / (MA_Period - 1);
  buyThreshold = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMMA, PRICE_CLOSE, shift + 1) + gap;
  sellThreshold = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMMA, PRICE_CLOSE, shift + 1) - gap;
}

/**
 * Buy : price < buyThreshold
 * Sell: price > sellThreshold
 */
void EstimateRangeByWPR(const int shift, double &buyThreshold, double &sellThreshold) {
  // WPR[i] = (HIGHEST - CLOSE) / (HIGHEST - LOWEST) * -100
  // Buy:
  // 　 WPR'[i] < WPR_OpenLevel - 100
  // → (HIGHEST - CLOSE) / (HIGHEST - LOWEST) * -100 < WPR_OpenLevel - 100
  // → (HIGHEST - CLOSE) / (HIGHEST - LOWEST) > 1 - WPR_OpenLevel / 100
  // → (MAX(CLOSE, HIGHEST) - CLOSE) / (MAX(CLOSE, HIGHEST) - MIN(CLOSE, LOWEST)) > 1 - WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) / (MAX(0, HIGHEST - CLOSE) - MIN(0, LOWEST - CLOSE)) > 1 - WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) > (MAX(0, HIGHEST - CLOSE) - MIN(0, LOWEST - CLOSE)) * (1 - WPR_OpenLevel / 100)
  // → MAX(0, HIGHEST - CLOSE) > MAX(0, HIGHEST - CLOSE) * (1 - WPR_OpenLevel / 100) - MIN(0, LOWEST - CLOSE) * (1 - WPR_OpenLevel / 100)
  // → MAX(0, HIGHEST - CLOSE) - MAX(0, HIGHEST - CLOSE) * (1 - WPR_OpenLevel / 100) > -MIN(0, LOWEST - CLOSE) * (1 - WPR_OpenLevel / 100)
  // → MAX(0, HIGHEST - CLOSE) * (-WPR_OpenLevel / 100) < MIN(0, LOWEST - CLOSE) * (1 - WPR_OpenLevel / 100)
  // → if CLOSE >= HIGHEST then FALSE!, because...
  // 　  0 < (LOWEST - CLOSE) * (1 - WPR_OpenLevel / 100)
  // 　  CLOSE < LOWEST → always false!
  // → if CLOSE <= LOWEST then TRUE!, because...
  // 　  (HIGHEST - CLOSE) * (-WPR_OpenLevel / 100) < 0
  // 　  HIGHEST > CLOSE → always true!
  // → if LOWEST < CLOSE < HIGHEST
  // 　  (HIGHEST - CLOSE) * (-WPR_OpenLevel / 100) < (LOWEST - CLOSE) * (1 - WPR_OpenLevel / 100)
  // 　  HIGHEST - CLOSE > (LOWEST - CLOSE) * (1 - 1/(WPR_OpenLevel / 100))
  // 　  HIGHEST - CLOSE > LOWEST * (1 - 1/(WPR_OpenLevel / 100)) - CLOSE * (1 - 1/(WPR_OpenLevel / 100))
  // 　  CLOSE * (1 - 1/(WPR_OpenLevel / 100)) - CLOSE > LOWEST * (1 - 1/(WPR_OpenLevel / 100)) - HIGHEST
  // 　  CLOSE / (WPR_OpenLevel / 100) < HIGHEST - LOWEST * (1 - 1/(WPR_OpenLevel / 100))
  // 　  CLOSE < HIGHEST * (WPR_OpenLevel / 100) - LOWEST * (WPR_OpenLevel / 100 - 1)
  // 　  CLOSE < HIGHEST * (WPR_OpenLevel / 100) + LOWEST * (1 - WPR_OpenLevel / 100)
  //     If CLOSE <= LOWEST then above condition is true too.
  // ∴ Buy condition: CLOSE < HIGHEST * (WPR_OpenLevel / 100) + LOWEST * (1 - WPR_OpenLevel / 100)
  // Sell:
  // 　 WPR'[i] > -WPR_OpenLevel
  // → (HIGHEST - CLOSE) / (HIGHEST - LOWEST) * -100 > -WPR_OpenLevel
  // → (HIGHEST - CLOSE) / (HIGHEST - LOWEST) < WPR_OpenLevel / 100
  // → (MAX(CLOSE, HIGHEST) - CLOSE) / (MAX(CLOSE, HIGHEST) - MIN(CLOSE, LOWEST)) < WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) / (MAX(0, HIGHEST - CLOSE) - MIN(0, LOWEST - CLOSE)) < WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) < (MAX(0, HIGHEST - CLOSE) - MIN(0, LOWEST - CLOSE)) * WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) < MAX(0, HIGHEST - CLOSE) * WPR_OpenLevel / 100 - MIN(0, LOWEST - CLOSE) * WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) - MAX(0, HIGHEST - CLOSE) * WPR_OpenLevel / 100 < -MIN(0, LOWEST - CLOSE) * WPR_OpenLevel / 100
  // → MAX(0, HIGHEST - CLOSE) * (WPR_OpenLevel / 100 - 1) > MIN(0, LOWEST - CLOSE) * WPR_OpenLevel / 100
  // → if CLOSE >= HIGHEST then TRUE!, because...
  // 　  0 > (LOWEST - CLOSE) * WPR_OpenLevel / 100
  // 　  CLOSE > LOWEST → always true!
  // → if CLOSE <= LOWEST then FALSE!, because...
  // 　  (HIGHEST - CLOSE) * (WPR_OpenLevel / 100 - 1) > 0
  // 　  HIGHEST < CLOSE → always false!
  // → if LOWEST < CLOSE < HIGHEST
  // 　  (HIGHEST - CLOSE) * (WPR_OpenLevel / 100 - 1) > (LOWEST - CLOSE) * WPR_OpenLevel / 100
  // 　  (HIGHEST - CLOSE) * (1 - 1/(WPR_OpenLevel / 100)) > LOWEST - CLOSE
  // 　  HIGHEST * (1 - 1/(WPR_OpenLevel / 100)) - CLOSE * (1 - 1/(WPR_OpenLevel / 100)) > LOWEST - CLOSE
  // 　  CLOSE - CLOSE * (1 - 1/(WPR_OpenLevel / 100)) > LOWEST - HIGHEST * (1 - 1/(WPR_OpenLevel / 100))
  // 　  CLOSE / (WPR_OpenLevel / 100) > LOWEST - HIGHEST * (1 - 1/(WPR_OpenLevel / 100))
  // 　  CLOSE > LOWEST * (WPR_OpenLevel / 100) - HIGHEST * (WPR_OpenLevel / 100 - 1)
  // 　  CLOSE > LOWEST * (WPR_OpenLevel / 100) + HIGHEST * (1 - WPR_OpenLevel / 100)
  //     If CLOSE >= HIGHEST then above condition is true too.
  // ∴ Sell condition: CLOSE > LOWEST * (WPR_OpenLevel / 100) + HIGHEST * (1 - WPR_OpenLevel / 100)
  double WPRFactor = WPR_OpenLevel / 100;
  double highest = High[iHighest(Symbol(), Period(), MODE_HIGH, WPR_Period, shift)];
  double lowest = Low[iLowest(Symbol(), Period(), MODE_LOW, WPR_Period, shift)];
  buyThreshold = highest * WPRFactor + lowest * (1.0 - WPRFactor);
  sellThreshold = lowest * WPRFactor + highest * (1.0 - WPRFactor);
}

/**
 * Buy : 
 * Sell: 
 */
void EstimateRangeByCCI(const int shift, double &buyThreshold, double &sellThreshold) {
  // TP[i] = (HIGH[i] + LOW[i] + CLOSE[i]) / 3
  // D[i] = TP[i] - Sum(TP[i+N-1]～TP[i])/N
  // CCI[i  ] = Sum(D[i+N-1]～D[i  ])/N * 0.015 / D[i  ]
  // CCI[i+1] = Sum(D[i+N  ]～D[i+1])/N * 0.015 / D[i+1]
  // CCI[i  ] = (Sum(D[i+N  ]～D[i+1])/N - D[i+N]/N + D[i]/N) * 0.015 / D[i  ]
  //          = Sum(D[i+N  ]～D[i+1])/N * 0.015 / D[i  ] - (D[i+N]/N - D[i]/N) * 0.015 / D[i  ]
  //          = Sum(D[i+N  ]～D[i+1])/N * 0.015 / D[i+1] * D[i+1] / D[i  ] - (D[i+N]/N - D[i]/N) * 0.015 / D[i  ]
  //          = CCI[i+1] * D[i+1] / D[i] - (D[i+N] - D[i]) / N * 0.015 / D[i]
  //          = CCI[i+1] * D[i+1] / D[i] - (D[i+N] / D[i] - 1) / N * 0.015
  // Buy:
  // 　 CCI'[i] < -CCI_Level
  // → CCI[i+1] * D[i+1] / D'[i] - (D[i+N] / D'[i] - 1) / N * 0.015 < -CCI_Level
  // → CCI[i+1] * D[i+1] - (D[i+N] - D'[i]) / N * 0.015 < -CCI_Level * D'[i] (D'[i] > 0)
  // || CCI[i+1] * D[i+1] - (D[i+N] - D'[i]) / N * 0.015 > -CCI_Level * D'[i] (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] - D'[i] < -CCI_Level * D'[i] * N / 0.015 (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] - D'[i] > -CCI_Level * D'[i] * N / 0.015 (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] < D'[i] - CCI_Level * D'[i] * N / 0.015 (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] > D'[i] - CCI_Level * D'[i] * N / 0.015 (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] < D'[i] * (1 - CCI_Level * N / 0.015) (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] > D'[i] * (1 - CCI_Level * N / 0.015) (D'[i] < 0)
  // Maybe 1 - CCI_Level * N / 0.015 < 0
  // → D'[i] < (CCI[i+1] * D[i+1] * N / 0.015 - D[i+N]) / (1 - CCI_Level * N / 0.015) (D'[i] > 0)
  // || D'[i] > (CCI[i+1] * D[i+1] * N / 0.015 - D[i+N]) / (1 - CCI_Level * N / 0.015) (D'[i] < 0)
  // Sell:
  // 　 CCI'[i] > CCI_Level
  // → CCI[i+1] * D[i+1] / D'[i] - (D[i+N] / D'[i] - 1) / N * 0.015 > CCI_Level
  // → CCI[i+1] * D[i+1] - (D[i+N] - D'[i]) / N * 0.015 > CCI_Level * D'[i] (D'[i] > 0)
  // || CCI[i+1] * D[i+1] - (D[i+N] - D'[i]) / N * 0.015 < CCI_Level * D'[i] (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] - D'[i] > CCI_Level * D'[i] * N / 0.015 (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] - D'[i] < CCI_Level * D'[i] * N / 0.015 (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] > D'[i] + CCI_Level * D'[i] * N / 0.015 (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] < D'[i] + CCI_Level * D'[i] * N / 0.015 (D'[i] < 0)
  // → CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] > D'[i] * (1 + CCI_Level * N / 0.015) (D'[i] > 0)
  // || CCI[i+1] * D[i+1] * N / 0.015 - D[i+N] < D'[i] * (1 + CCI_Level * N / 0.015) (D'[i] < 0)
  // Always 1 + CCI_Level * N / 0.015 > 0
  // → D'[i] < (CCI[i+1] * D[i+1] * N / 0.015 - D[i+N]) / (1 + CCI_Level * N / 0.015) (D'[i] > 0)
  // || D'[i] > (CCI[i+1] * D[i+1] * N / 0.015 - D[i+N]) / (1 + CCI_Level * N / 0.015) (D'[i] < 0)
  double tmp = iCCI(Symbol(), Period(), CCI_Period, PRICE_TYPICAL, shift+1) * CalculateD(shift+1) * CCI_Period / 0.015 - CalculateD(shift+CCI_Period);
  double buyD  = tmp / (1 - CCI_Level * CCI_Period / 0.015);
  double sellD = tmp / (1 + CCI_Level * CCI_Period / 0.015);
  // D'[i] → TP'[i]
  // D'[i] = TP'[i] - Sum(TP[i+N-1]～TP[i+1]) / N - TP'[i] / N
  //       = TP'[i] * (1 - 1/N) - Sum(TP[i+N-1]～TP[i+1]) / N
  // TP'[i] * (1 - 1/N) = D'[i] + Sum(TP[i+N-1]～TP[i+1]) / N
  // TP'[i] = (D'[i] + Sum(TP[i+N-1]～TP[i+1]) / N) / (1 - 1/N)
  //        = (D'[i] + Sum(TP[i+N-1]～TP[i+1]) / N) / ((N-1)/N)
  //        = (D'[i] + Sum(TP[i+N-1]～TP[i+1]) / N) * N / (N-1)
  //        = (D'[i] * N + Sum(TP[i+N-1]～TP[i+1])) / (N-1)
  //        = (D'[i] * N + Sum(TP[i+N-1]～TP[i+1]) / (N-1) * (N-1)) / (N-1)
  //        = D'[i] * N / (N-1) + Sum(TP[i+N-1]～TP[i+1]) / (N-1)
  double buyTP  = buyD  * CCI_Period / (CCI_Period - 1) + iMA(Symbol(), Period(), CCI_Period - 1, 0, MODE_SMA, PRICE_TYPICAL, shift+1);
  double sellTP = sellD * CCI_Period / (CCI_Period - 1) + iMA(Symbol(), Period(), CCI_Period - 1, 0, MODE_SMA, PRICE_TYPICAL, shift+1);
  // TP'[i] → CLOSE'[i]
  // TP'[i] = (HIGH'[i] + LOW'[i] + CLOSE'[i]) / 3
  //        = (MAX(HIGH[i], CLOSE'[i]) + MIN(LOW[i], CLOSE'[i]) + CLOSE'[i]) / 3
  // if CLOSE'[i] > HIGH[i] then TP'[i] = (2 * CLOSE'[i] + LOW[i] ) / 3
  //                          → 3 * TP'[i] = 2 * CLOSE'[i] + LOW[i]
  //                          → 3 * TP'[i] - LOW[i] = 2 * CLOSE'[i]
  //                          → CLOSE'[i] = (3 * TP'[i] - LOW[i]) / 2
  // if CLOSE'[i] < LOW[i]  then TP'[i] = (2 * CLOSE'[i] + HIGH[i]) / 3
  //                          → CLOSE'[i] = (3 * TP'[i] - HIGH[i]) / 2
  // else                        TP'[i] = (HIGH[i] + LOW[i] + CLOSE'[i]) / 3
  //                          → CLOSE'[i] = 3 * TP'[i] - HIGH[i] - LOW[i]

  // TODO: TP' to CLOSE'
  buyThreshold = buyTP;
  sellThreshold = sellTP;
}

double CalculateD(const int shift) {
  return iMA(Symbol(), Period(), 1, 0, MODE_SMA, PRICE_TYPICAL, shift) - iMA(Symbol(), Period(), CCI_Period, 0, MODE_SMA, PRICE_TYPICAL, shift);
}
