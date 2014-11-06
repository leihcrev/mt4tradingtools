//+------------------------------------------------------------------+
//|                                                     DateTime.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "DateTime.ex4"

/**
 * Return true if given datetime(dt) is Tokyo holiday.
 */
bool IsTokyoHoliday(datetime dt);

/**
 * Return true if given datetime(dt) is TARGET holiday.
 */
bool IsTargetHoliday(datetime dt);

/**
 * Return true if given datetime(dt) is New York holiday.
 */
bool IsNewyorkHoliday(datetime dt);

/**
 * Return true if given datetime(dt) is Sydney holiday.
 */
bool IsSydneyHoliday(datetime dt);

/**
 * Return true if given datetime(dt) is in Newyork summer time season.
 */
bool IsNewyorkSummerTimeSeason(datetime dt);

/**
 * Return true if given datetime(dt) is in London summer time season.
 */
bool IsLondonSummerTimeSeason(datetime dt);

/**
 * Return true if given datetime(dt) is in Sydney summer time season.
 */
bool IsSydneySummerTimeSeason(datetime dt);

/**
 * Return last day of given month.
 */
int GetLastDayOfMonth(datetime dt);

/**
 * Return true if given datetime(dt) is NFP day.
 */
bool IsNFPDay(datetime dt);

/**
 * Return next weekend datetime.
 */
datetime GetNextWeekendDatetime(datetime now, double GMTOffsetHours);

