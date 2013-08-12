//+------------------------------------------------------------------+
//|                                               MarketActivity.mq4 |
//|                                 Copyright 2012, KIKUCHI Shunsuke |
//|                           http://sites.google.com/site/leihcrev/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_buffers 4
#property indicator_color1 White
#property indicator_color2 Blue
#property indicator_color3 Green
#property indicator_color4 Red
#property indicator_level1 1

#include <DateTime.mqh>

// Input parameters
// Index 1: East Asian, 2: European, 3: American
extern double GMTOffset = 9.0;

// Internal parameters
double a_0     = 0.0334;
double omega_1 = 0.0001402;
double omega_2 = 0.0005369;
double omega_3 = 0.0018730;
double open_1  = -254; // -04:14 in minutes.
double open_2  =  415; //  06:55 in minutes.
double open_3  =  708; //  11:48 in minutes.
double close_1 =  523; //  08:43 in minutes.
double close_2 = 1000; //  16:40 in minutes.
double close_3 = 1370; //  22:50 in minutes.
double m_1     =  215; //  03:35 in minutes.
double m_2     =  662; //  11:02 in minutes.
double d_1     = 1.01;
double d_2     = 1.51;
double s_1     = -257; // -04:17 in minutes.
double s_2     = 1043; //  17:23 in minutes.
double s_3     = 2095; //  34:55 in minutes.
double omegamid_1;
double omegamid_2;
double omegamid_3;
double GMTOffsetSeconds;
double JSTOffsetSeconds;
double JSTHolidayOffsetSeconds;

// Buffers
double Activity[];
double Activity1[];
double Activity2[];
double Activity3[];

int init() {
  open_1 /= 60.0;
  open_2 /= 60.0;
  open_3 /= 60.0;
  close_1 /= 60.0;
  close_2 /= 60.0;
  close_3 /= 60.0;
  m_1 /= 60.0;
  m_2 /= 60.0;
  s_1 /= 60.0;
  s_2 /= 60.0;
  s_3 /= 60.0;
  omegamid_1 = omega_1 / ((open_1 + close_1) / 2.0 - s_1);
  omegamid_2 = omega_2 / ((open_2 + close_2) / 2.0 - s_2);
  omegamid_3 = omega_3 / ((open_3 + close_3) / 2.0 - s_3);
  d_1 *= d_1;
  d_2 *= d_2;

  GMTOffsetSeconds = GMTOffset * 60 * 60;
  JSTOffsetSeconds = 9 * 60 * 60;
  JSTHolidayOffsetSeconds = open_1 * 60 * 60;

  IndicatorBuffers(4);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
  SetIndexBuffer(0, Activity);
  SetIndexStyle(1, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(1, Activity1);
  SetIndexStyle(2, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(2, Activity2);
  SetIndexStyle(3, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(3, Activity3);
  IndicatorShortName("MarketActivity");
  SetIndexLabel(0, "MarketActivity");
  SetIndexLabel(1, "East Asian (Blue)");
  SetIndexLabel(2, "European (Green)");
  SetIndexLabel(3, "American (Red)");
  return(0);
}

int start() {
  for (int i = Bars - IndicatorCounted() - 1; i >= 0; i--) {
    if (Activity[i] != EMPTY_VALUE) {
      continue;
    }
    datetime gmt = Time[i] - GMTOffsetSeconds;
    int w = TimeDayOfWeek(gmt);
    if (w == 0) {
      w = 6;
    }
    else {
      w--;
    }
    double t = ((w * 24 + TimeHour(gmt)) * 60 + TimeMinute(gmt)) / 60.0;
    datetime jst = gmt + JSTOffsetSeconds;

    if (MathMod(t + 9, 168) >= 120) {
      Activity1[i] = 0;
    }
    else {
      double T_1 = MathMod(t + 9, 24) - 9;
      if (T_1 < open_1) {
        Activity1[i] = 0;
      }
      else if (T_1 > close_1) {
        Activity1[i] = 0;
      }
      else if (IsTokyoHoliday(jst - JSTHolidayOffsetSeconds)) {
        Activity1[i] = 0;
      }
      else {
        Activity1[i] = omegamid_1 * (T_1 - open_1) * (T_1 - open_1) * (T_1 - close_1) * (T_1 - close_1) * (T_1 - s_1) * ((T_1 - m_1) * (T_1 - m_1) + d_1);
      }
    }

    if (MathMod(t + 0, 168) >= 120) {
      Activity2[i] = 0;
    }
    else {
      double T_2 = MathMod(t + 0, 24) - 0;
      if (T_2 < open_2) {
        Activity2[i] = 0;
      }
      else if (T_2 > close_2) {
        Activity2[i] = 0;
      }
      else if (IsTargetHoliday(jst)) {
        Activity2[i] = 0;
      }
      else {
        Activity2[i] = omegamid_2 * (T_2 - open_2) * (T_2 - open_2) * (T_2 - close_2) * (T_2 - close_2) * (T_2 - s_2) * ((T_2 - m_2) * (T_2 - m_2) + d_2);
      }
    }

    if (MathMod(t - 5, 168) >= 120) {
      Activity3[i] = 0;
    }
    else {
      double T_3 = MathMod(t - 5, 24) + 5;
      if (T_3 < open_3) {
        Activity3[i] = 0;
      }
      else if (T_3 > close_3) {
        Activity3[i] = 0;
      }
      else if (IsNewyorkHoliday(jst)) {
        Activity3[i] = 0;
      }
      else {
        Activity3[i] = omegamid_3 * (T_3 - open_3) * (T_3 - open_3) * (T_3 - close_3) * (T_3 - close_3) * (T_3 - s_3);
      }
    }

    Activity[i] = a_0 + Activity1[i] + Activity2[i] + Activity3[i];
  }

  return(0);
}

