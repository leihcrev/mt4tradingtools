// ERLS.mq4
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Red

#include <IndicatorUtils.mqh>

// Input parameters
extern double    r = 0.5;
extern int       cutAhead = 10;

// Buffers
double ERLS[];
double Y[];
double Z[];

// Module variables
double r1;
double r2;
double r3;
double rd;
bool   initialized = false;

int init() {
  IndicatorBuffers(3);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID);
  SetIndexBuffer(0, ERLS);
  SetIndexStyle(1, DRAW_NONE);
  SetIndexBuffer(1, Y);
  SetIndexStyle(2, DRAW_NONE);
  SetIndexBuffer(2, Z);
  IndicatorShortName("ERLS");
  SetIndexLabel(0, "ERLS");
  SetIndexLabel(1, "(Y)");
  SetIndexLabel(2, "(Z)");

  r1 = 1 / (1-r);
  r2 = r / ((1-r) * (1-r));
  r3 = r * (1+r) / ((1-r) * (1-r) * (1-r));
  rd = r1 * r3 - r2 * r2;

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  if (!initialized) {
    initialized = true;
    for (int j = 1; j <= cutAhead; j++) {
      Y[Bars - j] = 0;
      Z[Bars - j] = 0;
    }
  }

  int n = GetBarsToBeCalculated(IndicatorCounted(), cutAhead);

  for (int i = n - 1; i >= 0; i--) {
    Y[i] = r * Y[i + 1] + Close[i];
    Z[i] = r * (Z[i + 1] + Y[i + 1]);
    ERLS[i] = (r3 * Y[i] - r2 * Z[i]) / rd;
  }

  return(0);
}

