// Ku-chart-Plus: Ku-chart for 8 currencies with EMA mode
#property copyright "Copyright 2011, 2012, 2013 Ku-chan, fai, KIKUCHI Shunsuke"
#property link      "http://d.hatena.ne.jp/fai_fx/, https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 Blue      // EUR
#property indicator_color2 Yellow    // USD
#property indicator_color3 Red       // JPY
#property indicator_color4 Pink      // CHF
#property indicator_color5 Orange    // GBP
#property indicator_color6 Green     // AUD
#property indicator_color7 Brown     // CAD
#property indicator_color8 DarkGreen // NZD
#property indicator_level1  0.5
#property indicator_level2 -0.5
#property indicator_level3  1.0
#property indicator_level4 -1.0
#property indicator_level5  1.5
#property indicator_level6 -1.5
#property indicator_level7  2.0
#property indicator_level8 -2.0

#define INDNAME "Ku-chart+"

#include <IndicatorUtils.mqh>
#include <DateTime.mqh>

// Parameters
extern int    MaxBars    = 10080;
extern string Mode_Usage = "0: Simple, reset daily / 1: Simple, reset weekly / 2-: EMA";
extern int    Mode       = 1440;
extern double GMTOffset  = 9.0;
extern int    MAPeriod   = 60;

// Currency pairs
//               EUR                        USD                        JPY                        CHF                        GBP                        AUD                        CAD                        NZD
/* EUR */
/* USD */ string sEURUSD = "EURUSD";
/* JPY */ string sEURJPY = "EURJPY"; string sUSDJPY = "USDJPY";
/* CHF */ string sEURCHF = "EURCHF"; string sUSDCHF = "USDCHF"; string sCHFJPY = "CHFJPY";
/* GBP */ string sEURGBP = "EURGBP"; string sGBPUSD = "GBPUSD"; string sGBPJPY = "GBPJPY"; string sGBPCHF = "GBPCHF";
/* AUD */ string sEURAUD = "EURAUD"; string sAUDUSD = "AUDUSD"; string sAUDJPY = "AUDJPY"; string sAUDCHF = "AUDCHF"; string sGBPAUD = "GBPAUD";
/* CAD */ string sEURCAD = "EURCAD"; string sUSDCAD = "USDCAD"; string sCADJPY = "CADJPY"; string sCADCHF = "CADCHF"; string sGBPCAD = "GBPCAD"; string sAUDCAD = "AUDCAD";
/* NZD */ string sEURNZD = "EURNZD"; string sNZDUSD = "NZDUSD"; string sNZDJPY = "NZDJPY"; string sNZDCHF = "NZDCHF"; string sGBPNZD = "GBPNZD"; string sAUDNZD = "AUDNZD"; string sNZDCAD = "NZDCAD";

// Indicator Buffers
double EURAV[];
double USDAV[];
double JPYAV[];
double CHFAV[];
double GBPAV[];
double AUDAV[];
double CADAV[];
double NZDAV[];

// Module variables
bool BarChecked;
double r, r_;
double scale;

int init() {
  IndicatorShortName(INDNAME);

  SetIndexStyle(0, DRAW_LINE, EMPTY, GetWidth("EUR"));
  SetIndexBuffer(0, EURAV);
  SetIndexLabel(0, "EUR");
  SetIndexStyle(1, DRAW_LINE, EMPTY, GetWidth("USD"));
  SetIndexBuffer(1, USDAV);
  SetIndexLabel(1, "USD");
  SetIndexStyle(2, DRAW_LINE, EMPTY, GetWidth("JPY"));
  SetIndexBuffer(2, JPYAV);
  SetIndexLabel(2, "JPY");
  SetIndexStyle(3, DRAW_LINE, EMPTY, GetWidth("CHF"));
  SetIndexBuffer(3, CHFAV);
  SetIndexLabel(3, "CHF");
  SetIndexStyle(4, DRAW_LINE, EMPTY, GetWidth("GBP"));
  SetIndexBuffer(4, GBPAV);
  SetIndexLabel(4, "GBP");
  SetIndexStyle(5, DRAW_LINE, EMPTY, GetWidth("AUD"));
  SetIndexBuffer(5, AUDAV);
  SetIndexLabel(5, "AUD");
  SetIndexStyle(6, DRAW_LINE, EMPTY, GetWidth("CAD"));
  SetIndexBuffer(6, CADAV);
  SetIndexLabel(6, "CAD");
  SetIndexStyle(7, DRAW_LINE, EMPTY, GetWidth("NZD"));
  SetIndexBuffer(7, NZDAV);
  SetIndexLabel(7, "NZD");

  BarChecked = false;

  scale = 1.0;
  if (Mode >= 2) {
    r = (Mode - 1.0) / (Mode + 1.0);
    r_ = 1.0 - r;
    scale = MathSqrt(261.0 * 24 * 60 / Period());
  }

  return(0);
}

int GetWidth(string ccy) {
  if (StringFind(Symbol(), ccy) == -1) {
    return(1);
  }
  return(2);
}

int deinit() {
  for (int i = 0; i < ObjectsTotal(); i++) {
    string ID = ObjectName(i);
    if (StringFind(ID, INDNAME) != -1) {
      ObjectDelete(ID);
    }
  }
  return(0);
}

double GetLogReturn(string sym1, datetime now, datetime begin, int min) {
  int shift1 = iBarShift(sym1, 0, now);
  if (shift1 > min) {
    shift1 = min - 1;
  }
  int shift2 = iBarShift(sym1, 0, begin);
  if (shift2 > min) {
    shift2 = min - 1;
  }
  return(GetLogReturnShift(sym1, shift1, shift2, min));
}

double GetLogReturnShift(string sym1, int shift1, int shift2, int min) {
  double v1 = iMA(sym1, NULL, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, shift1);
  double v2 = iMA(sym1, NULL, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, shift2);

  if (v1 == 0 || v2 == 0) {
    return(EMPTY_VALUE);
  }

  return(MathLog(v1 / v2) * scale * 100.0);
}

int start() {
  double EURUSD, EURJPY, EURCHF, EURGBP, USDJPY, USDCHF, GBPUSD, CHFJPY, GBPCHF, GBPJPY, AUDUSD, AUDCHF, AUDJPY, GBPAUD, EURAUD, AUDCAD, USDCAD, GBPCAD, EURCAD, CADCHF, CADJPY, NZDUSD, NZDCHF, NZDJPY, GBPNZD, EURNZD, NZDCAD, AUDNZD;
  int min = CheckBars();

  for (int i = MathMin(MaxBars, GetBarsToBeCalculated(IndicatorCounted(), 0)); i >= 0; i--) {
    if (i > min) {
      EURAV[i] = EMPTY_VALUE;
      USDAV[i] = EMPTY_VALUE;
      JPYAV[i] = EMPTY_VALUE;
      CHFAV[i] = EMPTY_VALUE;
      GBPAV[i] = EMPTY_VALUE;
      AUDAV[i] = EMPTY_VALUE;
      CADAV[i] = EMPTY_VALUE;
      NZDAV[i] = EMPTY_VALUE;
      continue;
    }
    if (Mode >= 2) {
      // EMA mode
      EURUSD = GetLogReturnShift(sEURUSD, i, i+1, min);
      EURJPY = GetLogReturnShift(sEURJPY, i, i+1, min);
      EURCHF = GetLogReturnShift(sEURCHF, i, i+1, min);
      EURGBP = GetLogReturnShift(sEURGBP, i, i+1, min);
      USDJPY = GetLogReturnShift(sUSDJPY, i, i+1, min);
      USDCHF = GetLogReturnShift(sUSDCHF, i, i+1, min);
      GBPUSD = GetLogReturnShift(sGBPUSD, i, i+1, min);
      CHFJPY = GetLogReturnShift(sCHFJPY, i, i+1, min);
      GBPCHF = GetLogReturnShift(sGBPCHF, i, i+1, min);
      GBPJPY = GetLogReturnShift(sGBPJPY, i, i+1, min);
      AUDUSD = GetLogReturnShift(sAUDUSD, i, i+1, min);
      AUDCHF = GetLogReturnShift(sAUDCHF, i, i+1, min);
      AUDJPY = GetLogReturnShift(sAUDJPY, i, i+1, min);
      GBPAUD = GetLogReturnShift(sGBPAUD, i, i+1, min);
      EURAUD = GetLogReturnShift(sEURAUD, i, i+1, min);
      AUDCAD = GetLogReturnShift(sAUDCAD, i, i+1, min);
      USDCAD = GetLogReturnShift(sUSDCAD, i, i+1, min);
      GBPCAD = GetLogReturnShift(sGBPCAD, i, i+1, min);
      EURCAD = GetLogReturnShift(sEURCAD, i, i+1, min);
      CADCHF = GetLogReturnShift(sCADCHF, i, i+1, min);
      CADJPY = GetLogReturnShift(sCADJPY, i, i+1, min);
      NZDUSD = GetLogReturnShift(sNZDUSD, i, i+1, min);
      NZDCHF = GetLogReturnShift(sNZDCHF, i, i+1, min);
      NZDJPY = GetLogReturnShift(sNZDJPY, i, i+1, min);
      GBPNZD = GetLogReturnShift(sGBPNZD, i, i+1, min);
      EURNZD = GetLogReturnShift(sEURNZD, i, i+1, min);
      NZDCAD = GetLogReturnShift(sNZDCAD, i, i+1, min);
      AUDNZD = GetLogReturnShift(sAUDNZD, i, i+1, min);

      double prev = EURAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      EURAV[i] = prev * r + (         EURUSD +EURJPY +EURCHF +EURGBP +EURAUD +EURCAD +EURNZD) / 7.0 * r_;
      prev = USDAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      USDAV[i] = prev * r + (-EURUSD         +USDJPY +USDCHF -GBPUSD -AUDUSD +USDCAD -NZDUSD) / 7.0 * r_;
      prev = JPYAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      JPYAV[i] = prev * r + (-EURJPY -USDJPY         -CHFJPY -GBPJPY -AUDJPY -CADJPY -NZDJPY) / 7.0 * r_;
      prev = CHFAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      CHFAV[i] = prev * r + (-EURCHF -USDCHF +CHFJPY         -GBPCHF -AUDCHF -CADCHF -NZDCHF) / 7.0 * r_;
      prev = GBPAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      GBPAV[i] = prev * r + (-EURGBP +GBPUSD +GBPCHF +GBPJPY         +GBPAUD +GBPCAD +GBPNZD) / 7.0 * r_;
      prev = AUDAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      AUDAV[i] = prev * r + (-EURAUD +AUDUSD +AUDJPY +AUDCHF -GBPAUD         +AUDCAD +AUDNZD) / 7.0 * r_;
      prev = CADAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      CADAV[i] = prev * r + (-EURCAD -USDCAD +CADJPY +CADCHF -GBPCAD -AUDCAD         -NZDCAD) / 7.0 * r_;
      prev = NZDAV[i+1];
      if (prev == EMPTY_VALUE) {
        prev = 0.0;
      }
      NZDAV[i] = prev * r + (-EURNZD +NZDUSD +NZDJPY +NZDCHF -GBPNZD -AUDNZD +NZDCAD        ) / 7.0 * r_;
    }
    else {
      // Simple mode
      datetime now = Time[i];
      double TimeOffset = -GMTOffset - 5.0 + 7.0; // 5.0: EST=GMT-5, 7.0: convert -1+17:00 EST to +0:00:00
      if (IsNewyorkSummerTimeSeason(now)) {
        TimeOffset += 1.0;
      }
      datetime begin = MathFloor((now + TimeOffset * 3600) / 86400) * 86400;
      if (Mode == 1) {
        begin -= (TimeDayOfWeek(begin) - 1) * 86400;
      }
      begin -= TimeOffset * 3600;

      EURUSD = GetLogReturn(sEURUSD, now, begin, min);
      EURJPY = GetLogReturn(sEURJPY, now, begin, min);
      EURCHF = GetLogReturn(sEURCHF, now, begin, min);
      EURGBP = GetLogReturn(sEURGBP, now, begin, min);
      USDJPY = GetLogReturn(sUSDJPY, now, begin, min);
      USDCHF = GetLogReturn(sUSDCHF, now, begin, min);
      GBPUSD = GetLogReturn(sGBPUSD, now, begin, min);
      CHFJPY = GetLogReturn(sCHFJPY, now, begin, min);
      GBPCHF = GetLogReturn(sGBPCHF, now, begin, min);
      GBPJPY = GetLogReturn(sGBPJPY, now, begin, min);
      AUDUSD = GetLogReturn(sAUDUSD, now, begin, min);
      AUDCHF = GetLogReturn(sAUDCHF, now, begin, min);
      AUDJPY = GetLogReturn(sAUDJPY, now, begin, min);
      GBPAUD = GetLogReturn(sGBPAUD, now, begin, min);
      EURAUD = GetLogReturn(sEURAUD, now, begin, min);
      AUDCAD = GetLogReturn(sAUDCAD, now, begin, min);
      USDCAD = GetLogReturn(sUSDCAD, now, begin, min);
      GBPCAD = GetLogReturn(sGBPCAD, now, begin, min);
      EURCAD = GetLogReturn(sEURCAD, now, begin, min);
      CADCHF = GetLogReturn(sCADCHF, now, begin, min);
      CADJPY = GetLogReturn(sCADJPY, now, begin, min);
      NZDUSD = GetLogReturn(sNZDUSD, now, begin, min);
      NZDCHF = GetLogReturn(sNZDCHF, now, begin, min);
      NZDJPY = GetLogReturn(sNZDJPY, now, begin, min);
      GBPNZD = GetLogReturn(sGBPNZD, now, begin, min);
      EURNZD = GetLogReturn(sEURNZD, now, begin, min);
      NZDCAD = GetLogReturn(sNZDCAD, now, begin, min);
      AUDNZD = GetLogReturn(sAUDNZD, now, begin, min);

      EURAV[i] = (         EURUSD +EURJPY +EURCHF +EURGBP +EURAUD +EURCAD +EURNZD) / 7.0;
      USDAV[i] = (-EURUSD         +USDJPY +USDCHF -GBPUSD -AUDUSD +USDCAD -NZDUSD) / 7.0;
      JPYAV[i] = (-EURJPY -USDJPY         -CHFJPY -GBPJPY -AUDJPY -CADJPY -NZDJPY) / 7.0;
      CHFAV[i] = (-EURCHF -USDCHF +CHFJPY         -GBPCHF -AUDCHF -CADCHF -NZDCHF) / 7.0;
      GBPAV[i] = (-EURGBP +GBPUSD +GBPCHF +GBPJPY         +GBPAUD +GBPCAD +GBPNZD) / 7.0;
      AUDAV[i] = (-EURAUD +AUDUSD +AUDJPY +AUDCHF -GBPAUD         +AUDCAD +AUDNZD) / 7.0;
      CADAV[i] = (-EURCAD -USDCAD +CADJPY +CADCHF -GBPCAD -AUDCAD         -NZDCAD) / 7.0;
      NZDAV[i] = (-EURNZD +NZDUSD +NZDJPY +NZDCHF -GBPNZD -AUDNZD +NZDCAD        ) / 7.0;
    }
  }

  SetLabel("EUR", EURAV[0]);
  SetLabel("USD", USDAV[0]);
  SetLabel("JPY", JPYAV[0]);
  SetLabel("CHF", CHFAV[0]);
  SetLabel("GBP", GBPAV[0]);
  SetLabel("AUD", AUDAV[0]);
  SetLabel("CAD", CADAV[0]);
  SetLabel("NZD", NZDAV[0]);

  return(0);
}

void SetLabel(string sym, double val) {
  if (ObjectCreate(INDNAME + sym, OBJ_TEXT, WindowFind(INDNAME), Time[0], val)) {
    ObjectSetText(INDNAME + sym, sym, 6, "Small Fonts", White);
  }
  else {
    ObjectMove(INDNAME + sym, 0, Time[0], val);
  }
}

void CheckBarsBySymbol(string sym, string &msg, int &min, int &total) {
  int b = iBars(sym, 0);
  if (b < MaxBars) {
    if (b < min) {
      min = b;
    }
    msg = msg + " " + sym + ":" + b;
    total += MaxBars - b;
  }
}

int CheckBars() {
  if (BarChecked) {
    return(MaxBars);
  }

  string msg = "";
  int min = MaxBars;
  int total = 0;
  CheckBarsBySymbol(sEURUSD, msg, min, total);
  CheckBarsBySymbol(sEURJPY, msg, min, total);
  CheckBarsBySymbol(sEURCHF, msg, min, total);
  CheckBarsBySymbol(sEURGBP, msg, min, total);
  CheckBarsBySymbol(sUSDJPY, msg, min, total);
  CheckBarsBySymbol(sUSDCHF, msg, min, total);
  CheckBarsBySymbol(sGBPUSD, msg, min, total);
  CheckBarsBySymbol(sCHFJPY, msg, min, total);
  CheckBarsBySymbol(sGBPJPY, msg, min, total);
  CheckBarsBySymbol(sGBPCHF, msg, min, total);
  CheckBarsBySymbol(sAUDUSD, msg, min, total);
  CheckBarsBySymbol(sAUDCHF, msg, min, total);
  CheckBarsBySymbol(sAUDJPY, msg, min, total);
  CheckBarsBySymbol(sGBPAUD, msg, min, total);
  CheckBarsBySymbol(sEURAUD, msg, min, total);
  CheckBarsBySymbol(sAUDCAD, msg, min, total);
  CheckBarsBySymbol(sUSDCAD, msg, min, total);
  CheckBarsBySymbol(sGBPCAD, msg, min, total);
  CheckBarsBySymbol(sEURCAD, msg, min, total);
  CheckBarsBySymbol(sCADCHF, msg, min, total);
  CheckBarsBySymbol(sCADJPY, msg, min, total);
  CheckBarsBySymbol(sNZDUSD, msg, min, total);
  CheckBarsBySymbol(sNZDCHF, msg, min, total);
  CheckBarsBySymbol(sNZDJPY, msg, min, total);
  CheckBarsBySymbol(sGBPNZD, msg, min, total);
  CheckBarsBySymbol(sEURNZD, msg, min, total);
  CheckBarsBySymbol(sNZDCAD, msg, min, total);
  CheckBarsBySymbol(sAUDNZD, msg, min, total);

  string ID = INDNAME + "msg";
  if (total > 0) {
    msg = total + msg;
    ObjectCreate(ID, OBJ_LABEL, WindowFind(INDNAME), 0, 0);
    ObjectSet(ID, OBJPROP_XDISTANCE, 2);
    ObjectSet(ID, OBJPROP_YDISTANCE, 24);
    ObjectSetText(ID, msg, 8, "Times New Roman", White);
  }
  else {
    ObjectDelete(ID);
    BarChecked = true;
  }

  return(min);
}

