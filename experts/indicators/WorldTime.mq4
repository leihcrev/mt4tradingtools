#property copyright "Copyright 2014, TheMoney.jp"
#property link      "http://themoney.jp"
#property version   "1.00"
#property strict
#property indicator_chart_window

#include <DateTime.mqh>

// Parameters
extern color AUColor = clrDarkGreen;
extern color JPColor = clrDarkRed;
extern color GBColor = clrDarkBlue;
extern color USColor = clrDarkGoldenrod;
extern long  AUOpen  = -1;               // AU market open  hour in GMT
extern long  AUClose =  8;               // AU market close hour in GMT
extern long  JPOpen  =  0;               // JP market open  hour in GMT
extern long  JPClose =  9;               // JP market close hour in GMT
extern long  GBOpen  =  8;               // GB market open  hour in GMT
extern long  GBClose = 17;               // GB market close hour in GMT
extern long  USOpen  = 13;               // US market open  hour in GMT
extern long  USClose = 22;               // US market close hour in GMT

int OnInit() {
  if (Period() >= PERIOD_D1) {
    Print("Intraday chart required.");
    return(INIT_FAILED);
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
  static bool initialized;
  if (!initialized) {
    RemoveObjects();
    initialized = true;
  }

  long offset = DetectServerTimeOffset(TimeCurrent(), TimeGMT());
  datetime timeFrom = time[WindowFirstVisibleBar()] - offset + 9 * 3600; // JST
  bool isNYDST = IsNewyorkSummerTimeSeason(timeFrom);
  if (isNYDST) {
    timeFrom -= 6 * 3600;
  }
  else {
    timeFrom -= 7 * 3600;
  }
  timeFrom = StringToTime(TimeToString(timeFrom, TIME_DATE)); // TradeDate
  datetime timeTo = timeFrom + MathCeil((double) (WindowBarsPerChart() * Period()) / 1440) * 86400;
  for (datetime t = timeFrom; t < timeTo; t += 86400) {
    Plot("AU", t, IsSydneyHoliday(t) , IsSydneySummerTimeSeason(t) , offset, AUOpen, AUClose, AUColor);
    Plot("JP", t, IsTokyoHoliday(t)  , false                       , offset, JPOpen, JPClose, JPColor);
    Plot("GB", t, IsTargetHoliday(t) , IsLondonSummerTimeSeason(t) , offset, GBOpen, GBClose, GBColor);
    Plot("US", t, IsNewyorkHoliday(t), IsNewyorkSummerTimeSeason(t), offset, USOpen, USClose, USColor);
  }

  return(rates_total);
}

void OnDeinit(const int reason) {
  RemoveObjects();
}

void RemoveObjects() {
  int n = ObjectsTotal();
  for (int i = n - 1; i >= 0; i--) {
    string objName = ObjectName(i);
    if (StringFind(objName, WindowExpertName() + " ") == 0) {
      ObjectDelete(objName);
    }
  }
}

long DetectServerTimeOffset(const datetime servertime, const datetime gmt) {
  static long prevOffset = -128;
  long result = servertime - gmt;
  result = (long) MathRound(((double) result) / 1800) * 1800;
  if (prevOffset != result) {
    PrintFormat("ServerTime is GMT%+2.0f", ((double) result) / 3600);
  }
  prevOffset = result;
  return(result);
}

void Plot(const string region, const datetime serverTime, const bool isHoliday, const bool isDST, const long offset, long open, long close, const color clr) {
  string strDate = TimeToString(serverTime, TIME_DATE);
  if (isHoliday) {
    Print(region + " " + strDate + " is holiday");
    return;
  }

  long cid = ChartID();

  string objName = WindowExpertName() + " " + region + " " + strDate;
  if (ObjectFind(cid, objName) >= 0) {
    return;
  }

  if (isDST) {
    open--;
    close--;
  }
  datetime baseTime = StringToTime(strDate);
  datetime openTime  = baseTime + open  * 3600 + offset;
  datetime closeTime = baseTime + close * 3600 + offset;

  ObjectCreate(cid, objName, OBJ_RECTANGLE, 0, openTime, 0, closeTime, 65535);
  ObjectSet(objName, OBJPROP_STYLE, STYLE_SOLID);
  ObjectSet(objName, OBJPROP_COLOR, clr);
  ObjectSet(objName, OBJPROP_BACK, true);
}
