#property copyright "Copyright 2014 TheMoney.jp"
#property link      "http://themoney.jp"
#property version   "1.00"

#property strict

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_buffers 9
#property indicator_plots   8

#property indicator_level1  5
#property indicator_level2  10
#property indicator_level3  15
#property indicator_level4  20
#property indicator_level5  25
#property indicator_level6  30
#property indicator_level7  35
#property indicator_level8  40

#property indicator_label1  "RV1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  C'0x11,0x00,0x77'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "RV2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'0x55,0x00,0x99'
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "RV3"
#property indicator_type3   DRAW_LINE
#property indicator_color3  C'0x99,0x00,0x99'
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "RV4"
#property indicator_type4   DRAW_LINE
#property indicator_color4  C'0xcc,0x00,0x77'
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

#property indicator_label5  "RV5"
#property indicator_type5   DRAW_LINE
#property indicator_color5  C'0xdd,0x22,0x11'
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "RV6"
#property indicator_type6   DRAW_LINE
#property indicator_color6  C'0xee,0x55,0x00'
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "RV7"
#property indicator_type7   DRAW_LINE
#property indicator_color7  C'0xff,0x88,0x00'
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

#property indicator_label8  "RV8"
#property indicator_type8   DRAW_LINE
#property indicator_color8  C'0xff,0xbb,0x11'
#property indicator_style8  STYLE_SOLID
#property indicator_width8  2

input int      MaxBars  = 16384;
input int      Period1  = 5;
input int      Period2  = 15;
input int      Period3  = 30;
input int      Period4  = 60;
input int      Period5  = 120;
input int      Period6  = 360;
input int      Period7  = 720;
input int      Period8  = 1440;
input bool     RV1Label = false;
input bool     RV2Label = false;
input bool     RV3Label = false;
input bool     RV4Label = true;
input bool     RV5Label = false;
input bool     RV6Label = false;
input bool     RV7Label = false;
input bool     RV8Label = true;

double         RV1Buffer[];
double         RV2Buffer[];
double         RV3Buffer[];
double         RV4Buffer[];
double         RV5Buffer[];
double         RV6Buffer[];
double         RV7Buffer[];
double         RV8Buffer[];
double         RVarBuffer[];

double m1;
double m2;
double m3;
double m4;
double m5;
double m6;
double m7;
double m8;

int OnInit() {
  SetIndexBuffer(0, RV1Buffer);
  SetIndexBuffer(1, RV2Buffer);
  SetIndexBuffer(2, RV3Buffer);
  SetIndexBuffer(3, RV4Buffer);
  SetIndexBuffer(4, RV5Buffer);
  SetIndexBuffer(5, RV6Buffer);
  SetIndexBuffer(6, RV7Buffer);
  SetIndexBuffer(7, RV8Buffer);
  SetIndexBuffer(8, RVarBuffer, INDICATOR_CALCULATIONS);
  SetIndexLabel(8, "RVar");

  double ybars = 261 * 1440 / Period();
  m1 = ybars / Period1;
  m2 = ybars / Period2;
  m3 = ybars / Period3;
  m4 = ybars / Period4;
  m5 = ybars / Period5;
  m6 = ybars / Period6;
  m7 = ybars / Period7;
  m8 = ybars / Period8;

  return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]) {
  int limit = rates_total - prev_calculated;
  if (prev_calculated == 0) {
    if (limit >= MaxBars) {
      limit = MaxBars - 1;
    }
  }
  else {
    limit++;
  }

  int startindex = rates_total - 1;
  for (int i = limit - 1; i >= 0; i--) {
    if (i + 1 > startindex) {
      continue;
    }
    double logreturn = MathLog(close[i] / close[i + 1]);
    RVarBuffer[i] = logreturn * logreturn;

    double sumRVar = 0.0;
    int j = 0;

    if (i + Period1 > startindex) {
      continue;
    }
    for (; j < Period1; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV1Buffer[i] = MathSqrt(sumRVar * m1) * 100;

    if (i + Period2 > startindex) {
      continue;
    }
    for (; j < Period2; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV2Buffer[i] = MathSqrt(sumRVar * m2) * 100;

    if (i + Period3 > startindex) {
      continue;
    }
    for (; j < Period3; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV3Buffer[i] = MathSqrt(sumRVar * m3) * 100;

    if (i + Period4 > startindex) {
      continue;
    }
    for (; j < Period4; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV4Buffer[i] = MathSqrt(sumRVar * m4) * 100;

    if (i + Period5 > startindex) {
      continue;
    }
    for (; j < Period5; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV5Buffer[i] = MathSqrt(sumRVar * m5) * 100;

    if (i + Period6 > startindex) {
      continue;
    }
    for (; j < Period6; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV6Buffer[i] = MathSqrt(sumRVar * m6) * 100;

    if (i + Period7 > startindex) {
      continue;
    }
    for (; j < Period7; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV7Buffer[i] = MathSqrt(sumRVar * m7) * 100;

    if (i + Period8 > startindex) {
      continue;
    }
    for (; j < Period8; j++) {
      sumRVar += RVarBuffer[i + j];
    }
    RV8Buffer[i] = MathSqrt(sumRVar * m8) * 100;
  }

  if (RV1Label) {
    SetLabel(Period1, RV1Buffer[0]);
  }
  if (RV2Label) {
    SetLabel(Period2, RV2Buffer[0]);
  }
  if (RV3Label) {
    SetLabel(Period3, RV3Buffer[0]);
  }
  if (RV4Label) {
    SetLabel(Period4, RV4Buffer[0]);
  }
  if (RV5Label) {
    SetLabel(Period5, RV5Buffer[0]);
  }
  if (RV6Label) {
    SetLabel(Period6, RV6Buffer[0]);
  }
  if (RV7Label) {
    SetLabel(Period7, RV7Buffer[0]);
  }
  if (RV8Label) {
    SetLabel(Period8, RV8Buffer[0]);
  }
   
  return(rates_total);
}

void SetLabel(const int p, const double rv) {
  string caption = GetTimeWindowCaption(p);
  string objName = WindowExpertName() + "_" + IntegerToString(p);
  if (ObjectCreate(ChartID(), objName, OBJ_TEXT, ChartWindowFind(), Time[0], rv)) {
    ObjectSetInteger(ChartID(), objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
  }
  else {
    ObjectMove(ChartID(), objName, 0, Time[0], rv);
  }
  ObjectSetText(objName, StringConcatenate(caption, ":", DoubleToString(rv, 2), "%"), 6, "Small Fonts", clrWhite);
}

string GetTimeWindowCaption(const int p) {
  if (p % 60 == 0) {
    int h = p / 60;
    if (h % 24 == 0) {
      int d = h / 24;
      return(StringConcatenate(d, " day", d == 1 ? "" : "s"));
    }
    return(StringConcatenate(h, " hour", h == 1 ? "" : "s"));
  }
  else {
    return(StringConcatenate(p, " min", p == 1 ? "" : "s"));
  }
}
