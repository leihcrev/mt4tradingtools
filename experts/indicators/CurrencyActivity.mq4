// CurrencyActivity: Activity of 8 currencies computed from volume
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

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
#property indicator_level1 -2
#property indicator_level2 -1
#property indicator_level3 0
#property indicator_level4 1
#property indicator_level5 2

#define INDNAME "CurrencyActivity"

#include <IndicatorUtils.mqh>

// Parameters
extern int    MaxBars    = 10080;

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
double EUR[];
double USD[];
double JPY[];
double CHF[];
double GBP[];
double AUD[];
double CAD[];
double NZD[];

// Module variables
bool BarChecked;

int init() {
  IndicatorShortName(INDNAME);

  SetIndexStyle(0, DRAW_LINE, EMPTY, GetWidth("EUR"));
  SetIndexBuffer(0, EUR);
  SetIndexLabel(0, "EUR");
  SetIndexStyle(1, DRAW_LINE, EMPTY, GetWidth("USD"));
  SetIndexBuffer(1, USD);
  SetIndexLabel(1, "USD");
  SetIndexStyle(2, DRAW_LINE, EMPTY, GetWidth("JPY"));
  SetIndexBuffer(2, JPY);
  SetIndexLabel(2, "JPY");
  SetIndexStyle(3, DRAW_LINE, EMPTY, GetWidth("CHF"));
  SetIndexBuffer(3, CHF);
  SetIndexLabel(3, "CHF");
  SetIndexStyle(4, DRAW_LINE, EMPTY, GetWidth("GBP"));
  SetIndexBuffer(4, GBP);
  SetIndexLabel(4, "GBP");
  SetIndexStyle(5, DRAW_LINE, EMPTY, GetWidth("AUD"));
  SetIndexBuffer(5, AUD);
  SetIndexLabel(5, "AUD");
  SetIndexStyle(6, DRAW_LINE, EMPTY, GetWidth("CAD"));
  SetIndexBuffer(6, CAD);
  SetIndexLabel(6, "CAD");
  SetIndexStyle(7, DRAW_LINE, EMPTY, GetWidth("NZD"));
  SetIndexBuffer(7, NZD);
  SetIndexLabel(7, "NZD");

  BarChecked = false;

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

void AddVolume(string sym, double &ccy1[], string ccy1convsym, double &ccy2[], string ccy2convsym, int shift) {
  double v = iVolume(sym, 0, shift);
  double ccy1conv = 1.0;
  if (ccy1convsym != "") {
    ccy1conv = iClose(ccy1convsym, 0, shift);
  }
  double ccy2conv = 1.0;
  if (ccy2convsym != "") {
    ccy2conv = iClose(ccy2convsym, 0, shift);
  }
  ccy1[shift] += v * ccy1conv;
  ccy2[shift] += v * ccy2conv * iClose(sym, 0, shift);
}

int start() {
  int min = CheckBars();

  for (int i = MathMin(MaxBars, GetBarsToBeCalculated(IndicatorCounted(), 0)); i >= 0; i--) {
    if (i > min) {
      EUR[i] = EMPTY_VALUE;
      USD[i] = EMPTY_VALUE;
      JPY[i] = EMPTY_VALUE;
      CHF[i] = EMPTY_VALUE;
      GBP[i] = EMPTY_VALUE;
      AUD[i] = EMPTY_VALUE;
      CAD[i] = EMPTY_VALUE;
      NZD[i] = EMPTY_VALUE;
      continue;
    }
    EUR[i] = 0;
    USD[i] = 0;
    JPY[i] = 0;
    CHF[i] = 0;
    GBP[i] = 0;
    AUD[i] = 0;
    CAD[i] = 0;
    NZD[i] = 0;
    AddVolume(sEURUSD, EUR, sEURJPY, USD, sUSDJPY, i);
    AddVolume(sEURJPY, EUR, sEURJPY, JPY, "", i);
    AddVolume(sEURCHF, EUR, sEURJPY, CHF, sCHFJPY, i);
    AddVolume(sEURGBP, EUR, sEURJPY, GBP, sGBPJPY, i);
    AddVolume(sUSDJPY, USD, sUSDJPY, JPY, "", i);
    AddVolume(sUSDCHF, USD, sUSDJPY, CHF, sCHFJPY, i);
    AddVolume(sGBPUSD, GBP, sGBPJPY, USD, sUSDJPY, i);
    AddVolume(sCHFJPY, CHF, sCHFJPY, JPY, "", i);
    AddVolume(sGBPCHF, GBP, sGBPJPY, CHF, sCHFJPY, i);
    AddVolume(sGBPJPY, GBP, sGBPJPY, JPY, "", i);
    AddVolume(sAUDUSD, AUD, sAUDJPY, USD, sUSDJPY, i);
    AddVolume(sAUDCHF, AUD, sAUDJPY, CHF, sCHFJPY, i);
    AddVolume(sAUDJPY, AUD, sAUDJPY, JPY, "", i);
    AddVolume(sGBPAUD, GBP, sGBPJPY, AUD, sAUDJPY, i);
    AddVolume(sEURAUD, EUR, sEURJPY, AUD, sAUDJPY, i);
    AddVolume(sAUDCAD, AUD, sAUDJPY, CAD, sCADJPY, i);
    AddVolume(sUSDCAD, USD, sUSDJPY, CAD, sCADJPY, i);
    AddVolume(sGBPCAD, GBP, sGBPJPY, CAD, sCADJPY, i);
    AddVolume(sEURCAD, EUR, sEURJPY, CAD, sCADJPY, i);
    AddVolume(sCADCHF, CAD, sCADJPY, CHF, sCHFJPY, i);
    AddVolume(sCADJPY, CAD, sCADJPY, JPY, "", i);
    AddVolume(sNZDUSD, NZD, sNZDJPY, USD, sUSDJPY, i);
    AddVolume(sNZDCHF, NZD, sNZDJPY, CHF, sCHFJPY, i);
    AddVolume(sNZDJPY, NZD, sNZDJPY, JPY, "", i);
    AddVolume(sGBPNZD, GBP, sGBPJPY, NZD, sNZDJPY, i);
    AddVolume(sEURNZD, EUR, sEURJPY, NZD, sNZDJPY, i);
    AddVolume(sNZDCAD, NZD, sNZDJPY, CAD, sCADJPY, i);
    AddVolume(sAUDNZD, AUD, sAUDJPY, NZD, sNZDJPY, i);
    double avg = (EUR[i] + USD[i] + JPY[i] + CHF[i] + GBP[i] + AUD[i] + CAD[i] + NZD[i]) / 8.0;
    EUR[i] = MathLog(EUR[i] / avg) / MathLog(2.0);
    USD[i] = MathLog(USD[i] / avg) / MathLog(2.0);
    JPY[i] = MathLog(JPY[i] / avg) / MathLog(2.0);
    CHF[i] = MathLog(CHF[i] / avg) / MathLog(2.0);
    GBP[i] = MathLog(GBP[i] / avg) / MathLog(2.0);
    AUD[i] = MathLog(AUD[i] / avg) / MathLog(2.0);
    CAD[i] = MathLog(CAD[i] / avg) / MathLog(2.0);
    NZD[i] = MathLog(NZD[i] / avg) / MathLog(2.0);
  }

  SetLabel("EUR", EUR[0]);
  SetLabel("USD", USD[0]);
  SetLabel("JPY", JPY[0]);
  SetLabel("CHF", CHF[0]);
  SetLabel("GBP", GBP[0]);
  SetLabel("AUD", AUD[0]);
  SetLabel("CAD", CAD[0]);
  SetLabel("NZD", NZD[0]);

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

