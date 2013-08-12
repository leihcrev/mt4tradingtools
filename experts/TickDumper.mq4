//+------------------------------------------------------------------+
//|                                                   TickDumper.mq4 |
//|                                                 KIKUCHI Shunsuke |
//|                          https://sites.google.com/site/leihcrev/ |
//+------------------------------------------------------------------+
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

int fh;
double prevBid, prevAsk;

int init() {
  fh = FileOpen(Symbol() + ".csv", FILE_CSV | FILE_WRITE, ',');
  if (fh < 1) {
    Print("Cannot open file.");
  }
  FileWrite(fh, "Year", "Month", "DayOfMonth", "DayOfWeek", "Hour", "Minute", "Seconds", "Bid", "Ask", "Bid diff", "Ask diff");
  return(0);
}

int deinit() {
  FileClose(fh);
  return(0);
}

int start() {
//  if (prevBid == Bid && prevAsk == Ask) {
//    return(0);
//  }
  datetime now = TimeCurrent();
  FileWrite(fh, TimeYear(now), TimeMonth(now), TimeDay(now), TimeDayOfWeek(now), TimeHour(now), TimeMinute(now), TimeSeconds(now), Bid, Ask, Bid - prevBid, Ask - prevAsk);
  FileFlush(fh);
  prevBid = Bid;
  prevAsk = Ask;
  return(0);
}

