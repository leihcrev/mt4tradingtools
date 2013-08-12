//+------------------------------------------------------------------+
//|                                        DynamicMarketActivity.mq4 |
//|                                 Copyright 2012, KIKUCHI Shunsuke |
//|                           http://sites.google.com/site/leihcrev/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"

#property stacksize 1048576

#property indicator_separate_window
#property indicator_minimum 0
//#property indicator_maximum 1
#property indicator_buffers 5
#property indicator_color1 White
#property indicator_color2 Blue
#property indicator_color3 Green
#property indicator_color4 Red
#property indicator_color5 Purple
#property indicator_level1 1

#include <IndicatorUtils.mqh>
#include <DateTime.mqh>

// Input parameters
extern    int tau       = 43200;  // In minutes (43200 minutes = 720 hours = 30 days).
extern    int tau_s.mul = 3;      // tau_s = tau_s.mul * Period() * 2.
extern    int m         = 8;      // Use the mth order approximation of IWMA. Maximum is 8.
extern double a_0       = 0.001;  // Small positive constant assureing that a(t) is always strictly positive.
extern double s_0       = 0.000;  // Market independent momentary share.
extern double w_0       = 0.010;  // Background activity.
extern double w_1       = 0.3125; // EastAsian Market Weight
extern    int s_1       = 0;      // EastAsian Market Time Shift (00:00)
extern    int t_o_1     = 270;    // EastAsian Market Open Time (06:00-01:30 JST)
extern double g_o_1     = 4.0000; // EastAsian Market Opening Slope
extern    int t_c_1     = 945;    // EastAsian Market Close Time (17:15-01:30 JST)
extern double g_c_1     = 4.0000; // EastAsian Market Closing Slope
extern double w_2       = 0.3125; // European Market Weight
extern    int s_2       = -540;   // European Market Time Shift (-09:00)
extern    int t_o_2     = 240;    // European Market Open Time (05:30-01:30 BST)
extern double g_o_2     = 4.0000; // European Market Opening Slope
extern    int t_c_2     = 990;    // European Market Close Time (18:00-01:30 BST)
extern double g_c_2     = 4.0000; // European Market Closing Slope
extern double w_3       = 0.3125; // American Market Weight
extern    int s_3       = -840;   // American Market Time Shift (-14:00)
extern    int t_o_3     = 270;    // American Market Open Time (06:00-01:30 EST)
extern double g_o_3     = 4.0000; // American Market Opening Slope
extern    int t_c_3     = 990;    // American Market Close Time (18:00-01:30 EST)
extern double g_c_3     = 4.0000; // American Market Closing Slope
extern double w_4       = 0.0625; // Australian Market Weight
extern    int s_4       = 180;    // Australian Market Time Shift (+03:00)
extern    int t_o_4     = 270;    // Australian Market Open Time (06:00-01:30 EST)
extern double g_o_4     = 4.0000; // Australian Market Opening Slope
extern    int t_c_4     = 990;    // Australian Market Close Time (18:00-01:30 EST)
extern double g_c_4     = 4.0000; // Australian Market Closing Slope

// Memo:
// Sydney   Market: 06:00 - 15:00 JST -> 03:00 - 15:00 0.0625
// Tokyo    Market: 09:00 - 18:00 JST -> 06:00 - 17:15 0.3125
// London   Market: 16:00 - 25:00 JST -> 14:30 - 27:00 0.3125
// New York Market: 21:00 - 30:00 JST -> 20:00 - 32:00 0.3125

// Buffers
int components = 4; // component 1: EastAsian, 2: European, 3: American, 4: Australian
double Activity[];
double Activity1[];
double Activity2[];
double Activity3[];
double Activity4[];
double ActivityModified[];
double mu;
double _1MinusMu;
int tauSeconds;
int _2Period;
double w[5];
int s[5];
int t_o[5];
double g_o[5];
int t_c[5];
double g_c[5];

bool Cached1[];
bool Cached2[];
bool Cached3[];
bool Cached4[];
bool Cached5[];
bool Cached6[];
bool Cached7[];
bool Cached8[];
double Cache1[];
double Cache2[];
double Cache3[];
double Cache4[];
double Cache5[];
double Cache6[];
double Cache7[];
double Cache8[];

bool VCached[];
double VCache[];

double OFCache[5][1440];
bool OFCached[5][1440];

double sumA = 0.0;
datetime timeSumAFrom = 0;
datetime timeSumATo = 0;

double omega[];

int init() {
  IndicatorBuffers(6);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(0, ActivityModified);
  SetIndexStyle(1, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(1, Activity1);
  SetIndexStyle(2, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(2, Activity2);
  SetIndexStyle(3, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(3, Activity3);
  SetIndexStyle(4, DRAW_LINE, STYLE_DASH);
  SetIndexBuffer(4, Activity4);
  SetIndexStyle(5, DRAW_NONE);
  SetIndexBuffer(5, Activity);
  IndicatorShortName("DynamicMarketActivity");
  SetIndexLabel(0, "DynamicMarketActivity");
  SetIndexLabel(1, "East Asian (Blue)");
  SetIndexLabel(2, "European (Green)");
  SetIndexLabel(3, "American (Red)");
  SetIndexLabel(4, "Australian (Purple)");
  SetIndexLabel(5, "Volatility");

  SetLevelValue(0, Period());

  double tau_dash = 2 * tau / (m + 1);
  mu = MathExp(-(10080 / tau_dash)); // 7200 = 5 * 24 * 60, 10080 = 7 * 24 * 60
  _1MinusMu = 1.0 - mu;
  tauSeconds = tau * 60;

  _2Period = 2 * Period();

  w[0] = w_0;
  w[1] = w_1;
  w[2] = w_2;
  w[3] = w_3;
  w[4] = w_4;
  s[0] = s_0 * 60;
  s[1] = s_1 * 60;
  s[2] = s_2 * 60;
  s[3] = s_3 * 60;
  s[4] = s_4 * 60;
  t_o[1] = t_o_1;
  t_o[2] = t_o_2;
  t_o[3] = t_o_3;
  t_o[4] = t_o_4;
  g_o[1] = g_o_1;
  g_o[2] = g_o_2;
  g_o[3] = g_o_3;
  g_o[4] = g_o_4;
  t_c[1] = t_c_1;
  t_c[2] = t_c_2;
  t_c[3] = t_c_3;
  t_c[4] = t_c_4;
  g_c[1] = g_c_1;
  g_c[2] = g_c_2;
  g_c[3] = g_c_3;
  g_c[4] = g_c_4;
  
  ArrayResize(Cached1, Bars);
  ArrayResize(Cached2, Bars);
  ArrayResize(Cached3, Bars);
  ArrayResize(Cached4, Bars);
  ArrayResize(Cached5, Bars);
  ArrayResize(Cached6, Bars);
  ArrayResize(Cached7, Bars);
  ArrayResize(Cached8, Bars);
  ArrayResize(Cache1, Bars);
  ArrayResize(Cache2, Bars);
  ArrayResize(Cache3, Bars);
  ArrayResize(Cache4, Bars);
  ArrayResize(Cache5, Bars);
  ArrayResize(Cache6, Bars);
  ArrayResize(Cache7, Bars);
  ArrayResize(Cache8, Bars);

  ArrayResize(VCached, iBars(Symbol(), PERIOD_M1));
  ArrayResize(VCache, iBars(Symbol(), PERIOD_M1));

  ArrayResize(omega, Period() * 2);
  for (int i = 0; i < Period() * 2; i++) {
    omega[i] = GetOmega(i - Period());
  }

  return(0);
}

int deinit() {
  return(0);
}

double GetOmega(int x) {
  double result = 0.0;
  if (-Period() < x && x < 0) {
    result = 1.0 + ((x + 0.0) / Period());
  }
  else if (x == 0) {
    result = 1.0;
  }
  else if (0 < x && x < Period()) {
    result = 1.0 - ((x + 0.0) / Period());
  }
  return(result);
}

// TODO: DST
int start() {
  int n = GetBarsToBeCalculated(IndicatorCounted(), tau / Period() + 1);
  int max = ArraySize(Activity);
  for (int i = n - 1; i >= 0; i--) {
    double IWEMA = GetIWEMAIterated(m, i, Time[i]);
    double IWMA = IWEMA * IWEMA;
    double sf[5];
    GetShareFactor(sf, i);
    Activity1[i] = sf[1] * IWMA;
    Activity2[i] = sf[2] * IWMA;
    Activity3[i] = sf[3] * IWMA;
    Activity4[i] = sf[4] * IWMA;
    Activity[i] = a_0 + sf[0] * IWMA + Activity1[i] + Activity2[i] + Activity3[i] + Activity4[i];

    ActivityModified[i] = Activity[i];

//    double dividend = GetActivityAverage(i, max);
//    if (dividend > 0.0) {
//      ActivityModified[i] = Activity[i] / dividend;
//      Activity1[i] /= dividend;
//      Activity2[i] /= dividend;
//      Activity3[i] /= dividend;
//      Activity4[i] /= dividend;
//    }
  }
  return(0);
}

/*
double GetActivityAverage(int i, int max) {
string debugMessage = "sumAct=" + sumA + "/From=" + timeSumAFrom + "/To=" + timeSumATo;
  datetime timeOneWeekAgo = Time[i] - 604800; // 604800 = 7 * 24 * 60 * 60
  int indexOneWeekAgo = iBarShift(Symbol(), Period(), timeOneWeekAgo);
  if (indexOneWeekAgo > max || i == indexOneWeekAgo) {
    indexOneWeekAgo = max;
  }
  
  int addFrom = 0;
  int addTo = -1;
  int j;
  if (timeSumAFrom <= timeOneWeekAgo || Time[i + 2] <= timeSumATo) { // timeSumATo < timeSumAFrom <= timeOneWeekAgo < Time[i + 2] or timeOneWeekAgo < Time[i + 2] <= timeSumATo < timeSumAFrom
    sumA = 0.0;
    addFrom = i + 2;
    addTo = indexOneWeekAgo;
  }
  else {
    int indexSumAFrom = iBarShift(Symbol(), Period(), timeSumAFrom);
    int indexSumATo = iBarShift(Symbol(), Period(), timeSumATo);
    if (timeSumATo < timeOneWeekAgo) { // timeSumATo < timeOneWeekAgo < timeSumAFrom < Time[i + 2]
debugMessage = debugMessage + "/MinusLoop(indexOneWeekAgo(" + indexOneWeekAgo + ")<=j<indexSumATo(" + indexSumATo + "))";
      for (j = indexOneWeekAgo; j < indexSumATo; j++) {
        sumA -= Activity[j];
debugMessage = debugMessage + "-" + j + "(" + Activity[j] + ")";
      }
      addFrom = i + 2;
      addTo = indexSumAFrom;
    }
    else { // timeOneWeekAgo < timeSumATo < Time[i + 2] < timeSumAFrom
debugMessage = debugMessage + "/MinusLoop(timeSumAFrom(" + timeSumAFrom + ")<=j<=i+2(" + (i + 2) + "))";
      for (j = timeSumAFrom; j <= i + 2; j++) {
        sumA -= Activity[j];
debugMessage = debugMessage + "-" + j + "(" + Activity[j] + ")";
      }
      addFrom = indexSumATo;
      addTo = indexOneWeekAgo;
    }
  }
debugMessage = debugMessage + "/PlusLoop(addFrom(" + addFrom + ")<=j<addTo(" + addTo + "))";
  for (j = addFrom; j < addTo; j++) {
    sumA += Activity[j];
debugMessage = debugMessage + "+" + j + "(" + Activity[j] + ")";
  }

  timeSumAFrom = Time[i + 2];
  timeSumATo = Time[indexOneWeekAgo];

  double result = (sumA + Activity[i] + Activity[i + 1]) / (indexOneWeekAgo - i) / Period();
debugMessage = debugMessage + "/Result=" + result;
Print(debugMessage);

  return(result);
}
*/

void GetShareFactor(double &result[], int t) {
  int i;
  double openingFunction[5];
  openingFunction[0] = w[0];
  double sumOpenFactor = 0.0;
  datetime time;
  for (i = 1; i <= components; i++) {
    time = Time[t] + s[i];
    if (i == 3) {
      bool isSummerTime = IsNewyorkSummerTimeSeason(Time[t]);
      if (isSummerTime) {
        time += 3600;
      }
    }
    openingFunction[i] = w[i] * GetOpeningFunction(i, time);
    sumOpenFactor += openingFunction[i];
  }
  double sumResult = 0.0;
  time = Time[t] + 21600; // 21600 = 6h * 60 * 60
  for (i = 0; i <= components; i++) {
    double hf = GetHolidayFactor(i, time);
    result[i] = hf * openingFunction[i] / (w[0] + sumOpenFactor);
    sumResult += result[i];
  }
  return(result);
}

double GetHolidayFactor(int component, datetime time) {
  double result = 1.0;

  switch (component) {
  case 0:
    break;
  case 1:
    if (IsTokyoHoliday(time)) { // 21600 = 6h * 60 * 60
      result = 0.0;
    }
    break;
  case 2:
    if (IsTargetHoliday(time)) {
      result = 0.0;
    }
    break;
  case 3:
    if (IsNewyorkHoliday(time)) {
      result = 0.0;
    }
    break;
  case 4:
    if (IsSydneyHoliday(time)) {
      result = 0.0;
    }
    break;
  }
  return(result);
}

double GetOpeningFunction(int component, datetime time) {
  int t = TimeHour(time) * 60 + TimeMinute(time);
  if (OFCached[component][t]) {
    return(OFCache[component][t]);
  }
  double openFactor  = 1.0 / (1.0 + MathExp(-g_o[component] * (t - t_o[component]) / 60.0));
  double closeFactor = 1.0 / (1.0 + MathExp(-g_c[component] * (t_c[component] - t) / 60.0));
  double result = openFactor * closeFactor;
  OFCache[component][t] = result;
  OFCached[component][t] = true;
  return(result);
}

double GetIWEMAIterated(int k, int t, datetime now) {
  double result;

  int i;
  if (t != 0 && t != 1) {
    i = Bars - t - 1; /* Calculate cache index */
    if (IsCached(i, k)) {
      result = GetIWEMAIteratedFromCache(i, k);
      return(result);
    }
  }
  datetime timeOneWeekAgo = Time[t] - 604800; // 604800 = 7 * 24 * 60 * 60
  if (now - timeOneWeekAgo > tauSeconds) {
    return(0.0);
  }
  int indexOneWeekAgo = iBarShift(Symbol(), Period(), timeOneWeekAgo);
  if (t == indexOneWeekAgo) {
    return(0.0);
  }

  double IWEMAOneWeekAgo = GetIWEMAIterated(k, indexOneWeekAgo, now);
  result = GetSmoothedVolatility(t);
  for (int j = 2; j <= k; j++) {
    if (t != 0 && t != 1 && IsCached(i, j)) {
      result = GetIWEMAIteratedFromCache(i, j);
    }
    else {
      result = mu * IWEMAOneWeekAgo + _1MinusMu * result;
      if (t != 0 && t != 1) {
        PutIWEMAIteratedToCache(i, j, result);
      }
    }
  }

  if (t != 0 && t != 1) {
    PutIWEMAIteratedToCache(i, k, result);
  }

  return(result);
}

bool IsCached(int i, int k) {
  bool result = false;

  switch (k) {
  case 1:
    if (ArraySize(Cached1) > i) {
      result = Cached1[i];
    }
    break;
  case 2:
    if (ArraySize(Cached2) > i) {
      result = Cached2[i];
    }
    break;
  case 3:
    if (ArraySize(Cached3) > i) {
      result = Cached3[i];
    }
    break;
  case 4:
    if (ArraySize(Cached4) > i) {
      result = Cached4[i];
    }
    break;
  case 5:
    if (ArraySize(Cached5) > i) {
      result = Cached5[i];
    }
    break;
  case 6:
    if (ArraySize(Cached6) > i) {
      result = Cached6[i];
    }
    break;
  case 7:
    if (ArraySize(Cached7) > i) {
      result = Cached7[i];
    }
    break;
  case 8:
    if (ArraySize(Cached8) > i) {
      result = Cached8[i];
    }
    break;
  }
  
  return(result);
}

double GetIWEMAIteratedFromCache(int i, int k) {
  double result;
  switch (k) {
  case 1:
    result = Cache1[i];
    break;
  case 2:
    result = Cache2[i];
    break;
  case 3:
    result = Cache3[i];
    break;
  case 4:
    result = Cache4[i];
    break;
  case 5:
    result = Cache5[i];
    break;
  case 6:
    result = Cache6[i];
    break;
  case 7:
    result = Cache7[i];
    break;
  case 8:
    result = Cache8[i];
    break;
  }
  return(result);
}

void PutIWEMAIteratedToCache(int i, int k, double IWEMA) {
  switch (k) {
  case 1:
    if (ArraySize(Cached1) <= i) {
      ArrayResize(Cached1, i + i / 2 + 1);
      ArrayResize(Cache1, i + i / 2 + 1);
    }
    Cache1[i] = IWEMA;
    Cached1[i] = true;
    break;
  case 2:
    if (ArraySize(Cached2) <= i) {
      ArrayResize(Cached2, i + i / 2 + 1);
      ArrayResize(Cache2, i + i / 2 + 1);
    }
    Cache2[i] = IWEMA;
    Cached2[i] = true;
    break;
  case 3:
    if (ArraySize(Cached3) <= i) {
      ArrayResize(Cached3, i + i / 2 + 1);
      ArrayResize(Cache3, i + i / 2 + 1);
    }
    Cache3[i] = IWEMA;
    Cached3[i] = true;
    break;
  case 4:
    if (ArraySize(Cached4) <= i) {
      ArrayResize(Cached4, i + i / 2 + 1);
      ArrayResize(Cache4, i + i / 2 + 1);
    }
    Cache4[i] = IWEMA;
    Cached4[i] = true;
    break;
  case 5:
    if (ArraySize(Cached5) <= i) {
      ArrayResize(Cached5, i + i / 2 + 1);
      ArrayResize(Cache5, i + i / 2 + 1);
    }
    Cache5[i] = IWEMA;
    Cached5[i] = true;
    break;
  case 6:
    if (ArraySize(Cached6) <= i) {
      ArrayResize(Cached6, i + i / 2 + 1);
      ArrayResize(Cache6, i + i / 2 + 1);
    }
    Cache6[i] = IWEMA;
    Cached6[i] = true;
    break;
  case 7:
    if (ArraySize(Cached7) <= i) {
      ArrayResize(Cached7, i + i / 2 + 1);
      ArrayResize(Cache7, i + i / 2 + 1);
    }
    Cache7[i] = IWEMA;
    Cached7[i] = true;
    break;
  case 8:
    if (ArraySize(Cached8) <= i) {
      ArrayResize(Cached8, i + i / 2 + 1);
      ArrayResize(Cache8, i + i / 2 + 1);
    }
    Cache8[i] = IWEMA;
    Cached8[i] = true;
    break;
  }
}

double GetSmoothedVolatility(int tM5) {
  int tM1 = iBarShift(Symbol(), PERIOD_M1, Time[tM5]);
  double result;

  int start = tM1 - (Period() - 1);
  if (start < 0) {
    start = 0;
  }
  int finish = tM1 + (Period() - 1);
  int tMax = iBars(Symbol(), PERIOD_M1) - 1;
  if (finish > tMax) {
    finish = tMax;
  }
  double sumOmega = 0.0;
  double sumVolatility = 0.0;
  for (int t = start; t <= finish; t++) {
    double o = omega[t - tM1 + Period()];
    sumOmega += o;
    sumVolatility += o * GetVolatility(t);
  }
  if (sumOmega == 0.0) {
    result = 0.0;
  }
  else {
    result = sumVolatility / sumOmega;
  }

  return(result);
}

double GetVolatility(int t) {
  int tMax = iBars(Symbol(), PERIOD_M1) - 1;
  double p1, p2, pLogDiff, sum, result;
  int cacheIndex;
  if (t != 0 && t != 1) {
    cacheIndex = tMax - t; /* Calculate VCache index */
    if (ArraySize(VCached) <= cacheIndex) {
      if (VCached[cacheIndex]) {
        result = VCache[cacheIndex];
        return(result);
      }
    }
  }
  int n = tau_s.mul * _2Period;
  if (t + n > tMax) {
    result = 0.0;
    return(result);
  }
  p1 = iClose(Symbol(), PERIOD_M1, t);
  int i;
  for (i = 0; i < n; i++, t++) {
    p2 = iClose(Symbol(), PERIOD_M1, t);
    pLogDiff = MathLog(p2 / p1);
    sum += pLogDiff * pLogDiff;
    p1 = p2;
  }
  result = MathSqrt(sum / i) * 16384.0;
  if (t != 0 && t != 1) {
    if (ArraySize(VCached) <= cacheIndex) {
      ArrayResize(VCached, cacheIndex + cacheIndex / 2 + 1);
      ArrayResize(VCache, cacheIndex + cacheIndex / 2 + 1);
    }
    VCache[cacheIndex] = result;
    VCached[cacheIndex] = true;
  }
  return(result);
}

