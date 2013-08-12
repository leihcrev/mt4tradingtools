//+------------------------------------------------------------------+
//|                                             DynamicThetaTime.mq4 |
//|                                                 KIKUCHI Shunsuke |
//|                          https://sites.google.com/site/leihcrev/ |
//+------------------------------------------------------------------+
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"
#property library

// c = ?, tau = 30 days = 30 * 24 * 60 = 43200, tau_short = 30 minutes = 30, delta = 5 minutes = 5, m = 8, a_0 = 0.001, s_0 = 0.000
double GetActivity(double c, int tau, int tau_short, int delta, int m, double a_0, double s_0, string symbol, int t) {
  return(a_0 + (s_0 + GetHolidayFactor(symbol, t)) * GetIWMA(c, tau, tau_short, delta, m, symbol, t));
}

// TODO: Should implement.
double GetHolidayFactor(string symbol, int t) {
  return(1.0);
}

double GetIWMA(double c, int tau, int tau_short, int delta, int m, string symbol, int t) {
  double IWEMA = GetIWEMA(tau, tau_short, delta, m, symbol, t);
  return(c * IWEMA * IWEMA);
}

double GetIWEMA(int tau, int tau_short, int delta, int m, string symbol, int t) {
  return(GetIWEMAIterated(2 * tau / (m + 1), tau, tau_short, delta, m, symbol, t));
}

double GetIWEMAIterated(double tau_dash, int tau, int tau_short, int delta, int k, string symbol, int t) {
  datetime time = iTime(symbol, PERIOD_M1, t);
  int i = GetCacheIndex(symbol, time, k);
  if (IsCached(i, k)) {
    return(GetIWEMAIteratedFromCache(i, k));
  }
  double result;
  datetime timeOneWeekAgo = time - 604800; // 604800 = 7 * 24 * 60 * 60
  int tOneWeekAgo = iBarShift(symbol, PERIOD_M1, timeOneWeekAgo);
  double mu = MathExp(-(delta / tau_dash));
  if (k == 1) {
    double vsm = GetSmoothedVolatility(tau_short, delta, symbol, t);
    if (tOneWeekAgo > tau) { // 10080 = 7 * 24 * 60
      result = vsm;
    }
    else {
      result = mu * GetIWEMAIterated(tau_dash, tau, tau_short, delta, 1, symbol, tOneWeekAgo) + (1.0 - mu) * vsm;
    }
  }
  else {
    double IWEMA_kMinus1 = GetIWEMAIterated(tau_dash, tau, tau_short, delta, k - 1, symbol, t);
    if (tOneWeekAgo > tau) { // 10080 = 7 * 24 * 60
      result = IWEMA_kMinus1;
    }
    else {
      result = mu * GetIWEMAIterated(tau_dash, tau, tau_short, delta, k, symbol, tOneWeekAgo) + (1.0 - mu) * IWEMA_kMinus1;
    }
  }
  PutIWEMAIteratedToCache(i, k, result);
  return(result);
}

int GetCacheIndex(string symbol, datetime time, int k) {
  datetime start = iTime(symbol, PERIOD_M1, iBars(symbol, PERIOD_M1) - 1);
  return((time - start) / 60);
}

bool Cached1[];
bool Cached2[];
bool Cached3[];
bool Cached4[];
bool Cached5[];
bool Cached6[];
bool Cached7[];
bool Cached8[];

bool IsCached(int i, int k) {
  switch (k) {
  case 1:
    if (ArraySize(Cached1) <= i) {
      return(false);
    }
    return(Cached1[i]);
  case 2:
    if (ArraySize(Cached2) <= i) {
      return(false);
    }
    return(Cached2[i]);
  case 3:
    if (ArraySize(Cached3) <= i) {
      return(false);
    }
    return(Cached3[i]);
  case 4:
    if (ArraySize(Cached4) <= i) {
      return(false);
    }
    return(Cached4[i]);
  case 5:
    if (ArraySize(Cached5) <= i) {
      return(false);
    }
    return(Cached5[i]);
  case 6:
    if (ArraySize(Cached6) <= i) {
      return(false);
    }
    return(Cached6[i]);
  case 7:
    if (ArraySize(Cached7) <= i) {
      return(false);
    }
    return(Cached7[i]);
  case 8:
    if (ArraySize(Cached8) <= i) {
      return(false);
    }
    return(Cached8[i]);
  }
}

double Cache1[];
double Cache2[];
double Cache3[];
double Cache4[];
double Cache5[];
double Cache6[];
double Cache7[];
double Cache8[];

double GetIWEMAIteratedFromCache(int i, int k) {
  switch (k) {
  case 1:
    return(Cache1[i]);
  case 2:
    return(Cache2[i]);
  case 3:
    return(Cache3[i]);
  case 4:
    return(Cache4[i]);
  case 5:
    return(Cache5[i]);
  case 6:
    return(Cache6[i]);
  case 7:
    return(Cache7[i]);
  case 8:
    return(Cache8[i]);
  }
}

void PutIWEMAIteratedToCache(int i, int k, double IWEMA) {
  switch (k) {
  case 1:
    if (ArraySize(Cached1) <= i) {
      ArrayResize(Cached1, i + i / 10 + 1);
      ArrayResize(Cache1, i + i / 10 + 1);
    }
    Cache1[i] = IWEMA;
    Cached1[i] = true;
    return;
  case 2:
    if (ArraySize(Cached2) <= i) {
      ArrayResize(Cached2, i + i / 10 + 1);
      ArrayResize(Cache2, i + i / 10 + 1);
    }
    Cache2[i] = IWEMA;
    Cached2[i] = true;
    return;
  case 3:
    if (ArraySize(Cached3) <= i) {
      ArrayResize(Cached3, i + i / 10 + 1);
      ArrayResize(Cache3, i + i / 10 + 1);
    }
    Cache3[i] = IWEMA;
    Cached3[i] = true;
    return;
  case 4:
    if (ArraySize(Cached4) <= i) {
      ArrayResize(Cached4, i + i / 10 + 1);
      ArrayResize(Cache4, i + i / 10 + 1);
    }
    Cache4[i] = IWEMA;
    Cached4[i] = true;
    return;
  case 5:
    if (ArraySize(Cached5) <= i) {
      ArrayResize(Cached5, i + i / 10 + 1);
      ArrayResize(Cache5, i + i / 10 + 1);
    }
    Cache5[i] = IWEMA;
    Cached5[i] = true;
    return;
  case 6:
    if (ArraySize(Cached6) <= i) {
      ArrayResize(Cached6, i + i / 10 + 1);
      ArrayResize(Cache6, i + i / 10 + 1);
    }
    Cache6[i] = IWEMA;
    Cached6[i] = true;
    return;
  case 7:
    if (ArraySize(Cached7) <= i) {
      ArrayResize(Cached7, i + i / 10 + 1);
      ArrayResize(Cache7, i + i / 10 + 1);
    }
    Cache7[i] = IWEMA;
    Cached7[i] = true;
    return;
  case 8:
    if (ArraySize(Cached8) <= i) {
      ArrayResize(Cached8, i + i / 10 + 1);
      ArrayResize(Cache8, i + i / 10 + 1);
    }
    Cache8[i] = IWEMA;
    Cached8[i] = true;
    return;
  }
}

double GetSmoothedVolatility(int tau_short, int delta, string symbol, int t) {
  double v = 0;
  for (int i = t; i < t + 2 * delta; i++) {
    v += GetRegularVolatility(tau_short, delta, symbol, i);
  }
  return(v / (2.0 * delta));
}

double GetRegularVolatility(int tau_short, int delta, string symbol, int t) {
  int n = tau_short / (2 * delta);
  double x = 0;
  for (int i = 0; i < n; i++) {
    double x_t = GetLogMidPrice(symbol, t);
    double x_tMinus2DeltaI = GetLogMidPrice(symbol, t + 2 * delta * i);
    x += MathPow(x_t - x_tMinus2DeltaI, 2.0);
  }
  return(MathSqrt(x / n));
}

double GetLogMidPrice(string symbol, int t) {
  double spread = MarketInfo(symbol, MODE_ASK) - MarketInfo(symbol, MODE_BID);
  double bid = iClose(symbol, PERIOD_M1, t);
  double ask = bid + spread;
  return((MathLog(bid) + MathLog(ask)) / 2.0);
}

