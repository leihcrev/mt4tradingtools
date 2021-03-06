#property version "1.0"
#property copyright "Copyright 2014 TheMoney.jp"
#property link      "http://themoney.jp"
#property description "経済指標発表予定をプロットします。"

#property strict

#property indicator_chart_window

// Windows APIs for accessing the Internet
#include <WinUser32.mqh>
#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string sAgent,int lAccessType, string sProxyName = "", string sProxyBypass = "", int lFlags = 0);
int InternetOpenUrlW(int hInternetSession,string sUrl, string sHeaders = "",int lHeadersLength = 0, int lFlags = 0,int lContext = 0);
int InternetReadFile(int hFile,int &sBuffer[],int lNumBytesToRead, int &lNumberOfBytesRead[]);
int InternetCloseHandle(int hInet);
#import

// Parameters
input string FFCalURL = "http://cdn.forexfactory.com/ffcal_week_this.xml"; // ForexFactory Calendar URL

// Global variables
datetime latestDatetime = 0;

int OnInit() {
  if (!IsDllsAllowed()) {
    Print("DLL の使用を許可してください。");
    return(INIT_FAILED);
  }
  latestDatetime = 0;
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  int n = ObjectsTotal();
  for (int i = n - 1; i >= 0; i--) {
    string name = ObjectName(i);
    if (StringFind(name, "ForexFactoryNews_", 0) == 0) {
      ObjectDelete(name);
    }
  }
}

class News {
public:
  string id;
  string title;
  string country;
  string date;
  string time;
  string impact;
  string forecast;
  string previous;
  datetime timestamp;
  void clear() {
    id = "";
    title = "";
    country = "";
    date = "";
    time = "";
    impact = "";
    forecast = "";
    previous = "";
    timestamp = 0;
  }

  void Format() {
    date = GetCDATA(date);
    time = GetCDATA(time);
    impact = GetCDATA(impact);
    forecast = GetCDATA(forecast);
    previous = GetCDATA(previous);
    ParseDatetime();
    id = "ForexFactoryNews_" + TimeToString(timestamp);
  }

  string GetCDATA(string s) {
    int p1 = StringFind(s, "<![CDATA[");
    if (p1 < 0) {
      return(s);
    }
    int p2 = StringFind(s, "]]>", p1);
    if (p2 < 0) {
      return(s);
    }
    return(StringSubstr(s, p1 + 9, p2 - p1 - 9));
  }

  void ParseDatetime() {
    if (date == "") {
      return;
    }
    string d[3];
    StringSplit(date, '-', d);
    string datestr = d[2] + "." + d[0] + "." + d[1];

    string timestr = "";
    if (time != "") {
      string tmp[2];
      StringSplit(time, ':', tmp);
      long h = StringToInteger(tmp[0]);
      string m = StringSubstr(tmp[1], 0, StringLen(tmp[1]) - 2);
      string ap = StringSubstr(tmp[1], StringLen(tmp[1]) - 2);
      if (ap == "pm") {
        h += 12;
      }
      timestr = " " + IntegerToString(h) + ":" + m;
    }
    timestamp = StringToTime(datestr + timestr);
    // GMT to JST
    timestamp += (int) DetectServerTimeOffset(TimeCurrent(), TimeGMT());
  }

  string GetText() {
    return(StringConcatenate(country, " ", title));
  }

  string GetTooltip() {
    return(StringConcatenate(title,
                             previous == "" ? "" : ("\nPrevious:" + previous),
                             forecast == "" ? "" : ("\nForecast:" + forecast)));
  }
};

long DetectServerTimeOffset(const datetime servertime, const datetime gmt) {
  static long prevOffset = -128;
  long result = servertime - gmt;
  result = (long) MathRound(((double) result) / 1800) * 1800;
  if (prevOffset != result) {
    PrintFormat("ServerTime is GMT%+3.1f", ((double) result) / 3600);
  }
  prevOffset = result;
  return(result);
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[]) {
  if (time[0] == latestDatetime) {
    return(rates_total);
  }
  // Print(TimeToString(time[0], TIME_DATE | TIME_SECONDS));
  latestDatetime = time[0];

  string content = Fetch(FFCalURL);
  string buffer[];
  Split(content, '>', buffer);

  string tags[];
  int startPos[][2];
  int endPos[][2];
  Parse(tags, startPos, endPos, buffer);

  News news;
  int st[2];
  int en[2];
  for (int i = 0; i < ArraySize(tags); i++) {
    string tag = tags[i];

    if (tag == "<weeklyevents>") {
    }
    else if (tag == "</weeklyevents>") {
    }
    else if (tag == "<event>") {
      news.clear();
      st[0] = -1;
      st[1] = -1;
    }
    else if (tag == "</event>") {
      news.Format();
      Plot(news);
    }
    else if (tag == "<title>" || tag == "<country>" || tag == "<date>" || tag == "<time>" || tag == "<impact>" || tag == "<forecast>" || tag == "<previous>") {
      st[0] = endPos[i][0];
      st[1] = endPos[i][1];
    }
    else if (tag == "</title>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.title = GetContent(buffer, st, en);
    }
    else if (tag == "</country>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.country = GetContent(buffer, st, en);
    }
    else if (tag == "</date>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.date = GetContent(buffer, st, en);
    }
    else if (tag == "</time>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.time = GetContent(buffer, st, en);
    }
    else if (tag == "</impact>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.impact = GetContent(buffer, st, en);
    }
    else if (tag == "</forecast>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.forecast = GetContent(buffer, st, en);
    }
    else if (tag == "</previous>") {
      en[0] = startPos[i][0];
      en[1] = startPos[i][1];
      news.previous = GetContent(buffer, st, en);
    }
  }
  return(0);
}

void Plot(News &news) {
  long chartId = ChartID();
  if (ObjectFind(chartId, news.id) >= 0) {
    string text = ObjectGetString(chartId, news.id, OBJPROP_TEXT);
    if (StringFind(text, news.GetText()) >= 0) {
      return;
    }
    if (news.impact == "Holiday") {
      ObjectSetInteger(chartId, news.id, OBJPROP_COLOR, clrPink);
    }
    else if (news.impact == "High") {
      ObjectSetInteger(chartId, news.id, OBJPROP_COLOR, clrRed);
    }
    else if (news.impact == "Medium") {
      color currentColor = (color) ObjectGetInteger(chartId, news.id, OBJPROP_COLOR);
      if (currentColor == clrGreen) {
        ObjectSetInteger(chartId, news.id, OBJPROP_COLOR, clrOrange);
      }
    }
    ObjectSetString(chartId, news.id, OBJPROP_TEXT, text + "," + news.GetText());
    ObjectSetString(chartId, news.id, OBJPROP_TOOLTIP, ObjectGetString(chartId, news.id, OBJPROP_TEXT) + "\n" + news.GetTooltip());
    return;
  }

  ObjectCreate(chartId, news.id, OBJ_TREND, 0, news.timestamp, 0, news.timestamp, 1.7976931348623158e+308);
  color col = clrWhite;
  if (news.impact == "Holiday") {
    col = clrPink;
  }
  else if (news.impact == "High") {
    col = clrRed;
  }
  else if (news.impact == "Medium") {
    col = clrOrange;
  }
  else if (news.impact == "Low") {
    col = clrGreen;
  }
  ObjectSetInteger(chartId, news.id, OBJPROP_COLOR, col);
  ObjectSetString(chartId, news.id, OBJPROP_TEXT, news.GetText());
  ObjectSetString(chartId, news.id, OBJPROP_TOOLTIP, news.GetTooltip());
  ObjectSetInteger(chartId, news.id, OBJPROP_BACK, true);
}

void Split(string inputStr, ushort divider, string &buffer[]) {
  if (inputStr == "") {
    ArrayResize(buffer, 0);
    return;
  }

  int rows = 0;
  ushort c;
  string strRow, work[32768];
  int inputStringLen = StringLen(inputStr);
  for (int i = 0; i < inputStringLen; i++) {
    c = StringGetCharacter(inputStr, i);
    strRow = strRow + CharToStr((uchar) c);
    work[rows] = strRow;
    if (c == divider) {
      rows++;
      strRow = "";
    }
  }
  if (rows > 0) {
    ArrayResize(buffer, rows);
    ArrayCopy(buffer, work, 0, 0, rows);
  }
}

#define BUFFER_SIZE 8192
string Fetch(string url) {
  int inetTr = InternetAttemptConnect(0);
  if (inetTr != 0) {
    Print("インターネットに接続できません。");
    return("");
  }

  int hInternetSession = InternetOpenW("Microsoft Internet Explorer", 0, "", "", 0);
  if (hInternetSession <= 0) {
    Print("インターネット接続が開けません。");
    return("");
  }

  int hURL = InternetOpenUrlW(hInternetSession, url, "", 0, 0, 0);
  if (hURL <= 0) {
    Print(url + " が開けません。");
    InternetCloseHandle(hInternetSession);
    return("");
  }

  int cBuffer[BUFFER_SIZE];
  int dwBytesRead[1];
  string result = "";

  while (!IsStopped()) {
    ArrayFill(cBuffer, 0, BUFFER_SIZE, 0);
    bool bResult = InternetReadFile(hURL, cBuffer, sizeof(cBuffer), dwBytesRead);
    int n = dwBytesRead[0];
    if (n == 0) {
      break;
    }

    string str = "";
    int len = 0;
    for (int i = 0; i < BUFFER_SIZE; i++) {
      str = str + CharToStr((uchar) ( cBuffer[i]        & 0x000000FF));
      if (++len == n) {
        break;
      }
      str = str + CharToStr((uchar) ((cBuffer[i] >>  8) & 0x000000FF));
      if (++len == n) {
        break;
      }
      str = str + CharToStr((uchar) ((cBuffer[i] >> 16) & 0x000000FF));
      if (++len == n) {
        break;
      }
      str = str + CharToStr((uchar) ((cBuffer[i] >> 24) & 0x000000FF));
      if (++len == n) {
        break;
      }
    }
    result = result + str;
  }

  InternetCloseHandle(hInternetSession);
  return(result);
}

void StorePosition(int &st[][], int &en[][], int t, int stLine, int stPos, int enLine, int enPos) {
  st[t][0] = stLine;
  st[t][1] = stPos;

  en[t][0] = enLine;
  en[t][1] = enPos;
}

#define CAPACITY_UNIT 16384
void Parse(string &result[], int &st[][], int &en[][], string &src[]) {
  ArrayResize(result, CAPACITY_UNIT);
  ArrayResize(st, CAPACITY_UNIT);
  ArrayResize(en, CAPACITY_UNIT);
   
  int t = 0, currPos = 0;
  int capacity = CAPACITY_UNIT;
  int rows = ArraySize(src);
  string tag;
  for (int i = 0; i < rows; ) {
    if (t >= capacity) {
      capacity += CAPACITY_UNIT;
      ArrayResize(result, capacity);
      ArrayResize(st, capacity);
      ArrayResize(en, capacity);
    }

    string row = src[i];
    int posOpen = StringFind(row, "<", currPos);
    if (posOpen == -1) {
      currPos = 0;
      i++;
      continue;
    }

    int posSpace = StringFind(row, " ", posOpen);
    int posClose = StringFind(row, ">", posOpen);
    if (posClose != -1) {
      if (posSpace == -1 || posSpace > posClose) {
        tag = StringSubstr(row, posOpen, posClose - posOpen) + ">";
      }
      else {
        tag = StringSubstr(row, posOpen, posSpace - posOpen) + ">";
      }
      result[t] = tag;
      StorePosition(st, en, t, i, posOpen, i, posClose + 1);
      t++;
      currPos = posClose;
    }
    else if (posSpace == -1) {
      tag = StringSubstr(row, posOpen) + ">";
      result[t] = tag;
      while (posClose == -1) {
        i++;
        row = src[i];
        posClose = StringFind(row, ">");
      }
      StorePosition(st, en, t, i, posOpen, i, posClose + 1);
      t++;
      currPos = posClose;
    }
  }
  ArrayResize(result, t);
}
  
string GetContent(string &src[], int &st[2], int &en[2]) {
  string res = "";
  for (int i = st[0]; i <= en[0]; i++) {
    string row = src[i];
    if (i == st[0] && en[0] > st[0]) {
      res = res + StringSubstr(row, st[1]);
    }
    if (i > st[0] && i < en[0]) {
      res = res + row;
    }
    if (en[0] > st[0] && i == en[0]) {
      if (en[1] > 0) {
        res = res + StringSubstr(row, 0, en[1]);
      }
    }
    if (en[0] == st[0] && i == en[0]) {
      if (en[1] - st[1] > 0) {
        res = res + StringSubstr(row, st[1], en[1] - st[1]);
      }
    }
  }
  return(res);   
}  
