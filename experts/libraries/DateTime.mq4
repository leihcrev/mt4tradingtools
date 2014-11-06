//+------------------------------------------------------------------+
//|                                                     DateTime.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 KIKUCHI Shunsuke"
#property library

/**
 * Return true if given datetime(dt) is Tokyo holiday.
 */
bool IsTokyoHoliday(datetime dt) {
  // Sunday and Saturday are holiday
  int w = TimeDayOfWeek(dt);
  if (w == 0 || w == 6) {
    return(true);
  }

  // Japanese holiday
  int m = TimeMonth(dt);
  int d = TimeDay(dt);
  if (_IsTokyoHoliday(TimeYear(dt), m, d, w)) {
    return(true);
  }

  // Monday makeup holiday
  if (dt >= D'1973.4.12' && w == 1) {
    datetime yesterday = dt - 86400;
    if (_IsTokyoHoliday(TimeYear(yesterday), TimeMonth(yesterday), TimeDay(yesterday), 0)) {
      return(true);
    }
  }

  // Tokyo bank holiday
  if ((m == 1 && (d == 2 || d == 3)) || (m == 12 && d == 31)) {
    return(true);
  }

  return(false);
}

/**
 * Return true if given date specified by year(y), month(m), day(d) and w(day of week) is Tokyo holiday.
 */
bool _IsTokyoHoliday(int y, int m, int d, int w) {
  switch (m) {
    case 1:
      if (d == 1) {
        return(true);
      }
      else if (y >= 2000 && w == 1 && 8 <= d && d <= 14) {
        return(true);
      }
      else if (y < 2000 && d == 15) {
        return(true);
      }
      return(false);
    case 2:
      if (y >= 1967 && d == 11) {
        return(true);
      }
      else if (y == 1989 && d == 24) {
        return(true);
      }
      return(false);
    case 3:
      if (d == GetDayOfVernalEquinox(y)) {
        return(true);
      }
      return(false);
    case 4:
      if (y >= 1989 && d == 29) {
        return(true);
      }
      else if (y == 1959 && d == 10) {
        return(true);
      }
      return(false);
    case 5:
      if (d == 3 || d == 5) {
        return(true);
      }
      else if (y >= 1986 && d == 4) {
        return(true);
      }
      return(false);
    case 6:
      if (y == 1993 && d == 9) {
        return(true);
      }
      return(false);
    case 7:
      if (y >= 2003 && w == 1 && 15 <= d && d <= 21) {
        return(true);
      }
      else if (y >= 1996 && y < 2003 && d == 20) {
        return(true);
      }
      return(false);
    case 8:
      return(false);
    case 9:
      int dayOfAutumnalEquinox = GetDayOfAutumnalEquinox(y);
      if (d == dayOfAutumnalEquinox) {
        return(true);
      }
      else if (y >= 2003 && w == 1 && 15 <= d && d <= 21) {
        return(true);
      }
      else if (y >= 2003 && w == 2 && d == dayOfAutumnalEquinox - 1) {
        return(true);
      }
      else if (y >= 1966 && y < 2003 && d == 15) {
        return(true);
      }
      return(false);
    case 10:
      if (y >= 2000 && w == 1 && 8 <= d && d <= 14) {
        return(true);
      }
      else if (y >= 1966 && y < 2000 && d == 10) {
        return(true);
      }
      return(false);
    case 11:
      if (d == 3) {
        return(true);
      }
      else if (d == 23) {
        return(true);
      }
      else if (y == 1990 && d == 12) {
        return(true);
      }
      return(false);
    case 12:
      if (y >= 1989 && d == 23) {
        return(true);
      }
      return(false);
  }
  return(false);
}

/**
 * Return the day of the vernal equinox of a given year.
 */
int GetDayOfVernalEquinox(int y) {
  if (y <= 1979) {
    return(MathFloor(20.8357 + (0.242194 * (y - 1980)) - MathFloor((y - 1983) / 4)));
  }
  else if (y <= 2099) {
    return(MathFloor(20.8431 + (0.242194 * (y - 1980)) - MathFloor((y - 1980) / 4)));
  }
  else if (y <= 2150) {
    return(MathFloor(21.851  + (0.242194 * (y - 1980)) - MathFloor((y - 1980) / 4)));
  }

  return(0);
}

/**
 * Return the day of the autumnal equinox of a given year.
 */
int GetDayOfAutumnalEquinox(int y) {
  if (y <= 1979) {
    return(MathFloor(23.2588 + (0.242194 * (y - 1980)) - MathFloor((y - 1983) / 4)));
  }
  else if (y <= 2099) {
    return(MathFloor(23.2488 + (0.242194 * (y - 1980)) - MathFloor((y - 1980) / 4)));
  }
  else if (y <= 2150) {
    return(MathFloor(24.2488 + (0.242194 * (y - 1980)) - MathFloor((y - 1980) / 4)));
  }

  return(0);
}

/**
 * Return true if given datetime(dt) is TARGET holiday.
 */
bool IsTargetHoliday(datetime dt) {
  // Sunday and Saturday are holiday
  int w = TimeDayOfWeek(dt);
  if (w == 0 || w == 6) {
    return(true);
  }

  // TARGET holiday
  int y = TimeYear(dt);
  int m = TimeMonth(dt);
  int d = TimeDay(dt);
  switch (m) {
    case 1:
      if (d == 1) {
        return(true);
      }
      return(false);
    case 2:
      return(false);
    case 3:
      int easterSundayCandidateDay = d + 2;
      int easterSundayCandidateMonth = m;
      if (easterSundayCandidateDay > 31) {
        easterSundayCandidateDay -= 31;
        easterSundayCandidateMonth++;
      }
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      easterSundayCandidateDay = d - 1;
      easterSundayCandidateMonth = m;
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      return(false);
    case 4:
      easterSundayCandidateDay = d + 2;
      easterSundayCandidateMonth = m;
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      easterSundayCandidateDay = d - 1;
      easterSundayCandidateMonth = m;
      if (easterSundayCandidateDay < 1) {
        easterSundayCandidateDay += 31;
        easterSundayCandidateMonth--;
      }
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      return(false);
    case 5:
      if (d == 1) {
        return(true);
      }
      return(false);
    case 6:
      return(false);
    case 7:
      return(false);
    case 8:
      return(false);
    case 9:
      return(false);
    case 10:
      return(false);
    case 11:
      return(false);
    case 12:
      if (d == 25 || d == 26) {
        return(true);
      }
      return(false);
  }

  return(false);
}

/**
 * Return true if given day is the day of the Easter Sunday.
 */
bool IsEasterSunday(int year, int month, int day) {
  int a = year % 19;
  int b = year / 100;
  int c = year % 100;
  int d = b / 4;
  int e = b % 4;
  int f = (b + 8) / 25;
  int g = (b - f + 1) / 3;
  int h = (19 * a + b - d - g + 15) % 30;
  int i = c / 4;
  int k = c % 4;
  int l = (32 + 2 * e + 2 * i - h - k) % 7;
  int m = (a + 11 * h + 22 * l) / 451;
  int easterSundayMonth = (h + l - 7 * m + 114) / 31;
  int easterSundayDay = ((h + l - 7 * m + 114) % 31) + 1;

  if (month == easterSundayMonth && day == easterSundayDay) {
    return(true);
  }
  return(false);
}

/**
 * Return true if given datetime(dt) is New York holiday.
 */
bool IsNewyorkHoliday(datetime dt) {
  // Sunday and Saturday are holiday
  int w = TimeDayOfWeek(dt);
  if (w == 0 || w == 6) {
    return(true);
  }

  // Newyork holiday
  int d = TimeDay(dt);
  switch (TimeMonth(dt)) {
    case 1:
      if (d == 1) {
        return(true);
      }
      else if (d == 2 && w == 1) {
        return(true);
      }
      else if (w == 1 && 15 <= d && d <= 21) {
        return(true);
      }
      return(false);
    case 2:
      if (w == 1 && 15 <= d && d <= 21) {
        return(true);
      }
      return(false);
    case 3:
      return(false);
    case 4:
      return(false);
    case 5:
      if (w == 1 && 25 <= d && d <= 31) {
        return(true);
      }
      return(false);
    case 6:
      return(false);
    case 7:
      if (d == 4) {
        return(true);
      }
      else if (d == 5 && w == 1) {
        return(true);
      }
      return(false);
    case 8:
      return(false);
    case 9:
      if (w == 1 && 1 <= d && d <= 7) {
        return(true);
      }
      return(false);
    case 10:
      if (w == 1 && 8 <= d && d <= 14) {
        return(true);
      }
      return(false);
    case 11:
      if (d == 11) {
        return(true);
      }
      else if (d == 12 && w == 1) {
        return(true);
      }
      else if (w == 4 && 22 <= d && d <= 28) {
        return(true);
      }
      return(false);
    case 12:
      if (d == 25) {
        return(true);
      }
      else if (d == 26 && w == 1) {
        return(true);
      }
      return(false);
  }

  return(false);
}

/**
 * Return true if given datetime(dt) is Sydney holiday.
 */
bool IsSydneyHoliday(datetime dt) {
  // Sunday and Saturday are holiday
  int w = TimeDayOfWeek(dt);
  if (w == 0 || w == 6) {
    return(true);
  }

  // Sydney holiday
  int y = TimeYear(dt);
  int m = TimeMonth(dt);
  int d = TimeDay(dt);
  switch (TimeMonth(dt)) {
    case 1:
      if (d == 1) {
        return(true);
      }
      else if (d == 2 && w == 1) {
        return(true);
      }
      else if (d == 26) {
        return(true);
      }
      else if (d == 27 && w == 1) {
        return(true);
      }
      return(false);
    case 2:
      return(false);
    case 3:
      int easterSundayCandidateDay = d + 2;
      int easterSundayCandidateMonth = m;
      if (easterSundayCandidateDay > 31) {
        easterSundayCandidateDay -= 31;
        easterSundayCandidateMonth++;
      }
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      easterSundayCandidateDay = d - 1;
      easterSundayCandidateMonth = m;
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      return(false);
    case 4:
      easterSundayCandidateDay = d + 2;
      easterSundayCandidateMonth = m;
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      easterSundayCandidateDay = d - 1;
      easterSundayCandidateMonth = m;
      if (easterSundayCandidateDay < 1) {
        easterSundayCandidateDay += 31;
        easterSundayCandidateMonth--;
      }
      if (IsEasterSunday(y, easterSundayCandidateMonth, easterSundayCandidateDay)) {
        return(true);
      }
      if (d == 25) {
        return(true);
      }
      else if (d == 26 && (w == 1 || IsEasterSunday(y, 4, 24))) {
        return(true);
      }
      return(false);
    case 5:
      return(false);
    case 6:
      if (w == 1 && 8 <= d && d <= 14) {
        return(true);
      }
      return(false);
    case 7:
      return(false);
    case 8:
      if (w == 1 && 1 <= d && d <= 7) {
        return(true);
      }
      return(false);
    case 9:
      return(false);
    case 10:
      if (w == 1 && 1 <= d && d <= 7) {
        return(true);
      }
      return(false);
    case 11:
      return(false);
    case 12:
      if (d == 25) {
        return(true);
      }
      else if (d == 26) {
        return(true);
      }
      else if ((w == 1 || w == 2) && d == 27) {
        return(true);
      }
      else if ((w == 1 || w == 2) && d == 28) {
        return(true);
      }
      return(false);
  }

  return(false);
}

/**
 * Return true if given datetime(dt) is in Newyork summer time season.
 */
bool IsNewyorkSummerTimeSeason(datetime dt) {
  int y;
  switch (TimeMonth(dt)) {
    case 1:
    case 2:
      return(false);
    case 3:
      y = TimeYear(dt);
      if (y < 2007 || (y >= 2007 && TimeDay(dt) - TimeDayOfWeek(dt) < 8)) {
        return(false);
      }
      return(true);
    case 4:
      if (TimeYear(dt) < 2007 && TimeDay(dt) - TimeDayOfWeek(dt) < 1) {
        return(false);
      }
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
      return(true);
    case 10:
      y = TimeYear(dt);
      if (y >= 2007 || (y < 2007 && TimeDay(dt) - TimeDayOfWeek(dt) < 25)) {
        return(true);
      }
      return(false);
    case 11:
      if (TimeYear(dt) >= 2007 && TimeDay(dt) - TimeDayOfWeek(dt) < 1) {
        return(true);
      }
    case 12:
      return(false);
  }
  return(false);
}

/**
 * Return true if given datetime(dt) is in London summer time season.
 */
bool IsLondonSummerTimeSeason(datetime dt) {
  switch (TimeMonth(dt)) {
    case 1:
    case 2:
      return(false);
    case 3:
      if (TimeDay(dt) - TimeDayOfWeek(dt) < 25) {
        return(false);
      }
      return(true);
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
      return(true);
    case 10:
      if (TimeDay(dt) - TimeDayOfWeek(dt) < 25) {
        return(true);
      }
      return(false);
    case 11:
    case 12:
      return(false);
  }
  return(false);
}

/**
 * Return true if given datetime(dt) is in Sydney summer time season.
 */
bool IsSydneySummerTimeSeason(datetime dt) {
  switch (TimeMonth(dt)) {
    case 1:
    case 2:
    case 3:
      return(true);
    case 4:
      if (TimeDay(dt) - TimeDayOfWeek(dt) < 8) {
        return(false);
      }
      return(true);
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
      return(false);
    case 10:
      if (TimeDay(dt) - TimeDayOfWeek(dt) < 8) {
        return(false);
      }
      return(true);
    case 11:
    case 12:
      return(true);
  }
  return(false);
}

/**
 * Return last day of given month.
 */
int GetLastDayOfMonth(datetime dt) {
  switch (TimeMonth(dt)) {
    case 1:
      return(31);
    case 2:
      int y = TimeYear(dt);
      return(28 + (y % 4 == 0) - (y % 100 == 0) + (y % 400 == 0));
    case 3:
      return(31);
    case 4:
      return(30);
    case 5:
      return(31);
    case 6:
      return(30);
    case 7:
      return(31);
    case 8:
      return(31);
    case 9:
      return(30);
    case 10:
      return(31);
    case 11:
      return(30);
    case 12:
      return(31);
  }
  return(0);
}

/**
 * Return true if given datetime(dt) is NFP day.
 */
bool IsNFPDay(datetime dt) {
  if (TimeMonth(dt) == 12) {
    if (TimeDay(dt) == 31) {
      return(false);
    }
  }
  if (TimeDayOfWeek(dt) == 5 && !_IsNFPHoliday(dt)) {
    return(_IsNFPFriday(dt));
  }
  if (TimeDayOfWeek(dt) == 4 && !_IsNFPHoliday(dt) && _IsNFPHoliday(dt + 86400)) {
    return(_IsNFPFriday(dt + 86400));
  }
  if (TimeDayOfWeek(dt) == 3 && !_IsNFPHoliday(dt) && _IsNFPHoliday(dt + 86400) && _IsNFPHoliday(dt + 172800)) {
    return(_IsNFPFriday(dt + 172800));
  }
  return(false);
}

bool _IsNFPHoliday(datetime dt) {
  if (IsNewyorkHoliday(dt)) {
    return(true);
  }
  if (TimeMonth(dt) == 7 && TimeDay(dt) == 3 && TimeDayOfWeek(dt) == 5) {
    return(true);
  }
  return(false);
}

bool _IsNFPFriday(datetime dt) {
  int m = TimeMonth(dt);
  int d;
  if (m == 1) {
    d = TimeDay(dt - 1987200); /* 86400 * (7 * 3 + 2) */
  }
  else {
    d = TimeDay(dt - 1814400); /* 86400 * 7 * 3 */
  }
  return(d >= 11 && d <= 17);
}

/**
 * Return next weekend datetime.
 */
datetime GetNextWeekendDatetime(datetime now, double GMTOffsetHours) {
  datetime jst = now - (GMTOffsetHours - 9.0) * 3600.0;

  // Convert to 00:00 origin
  jst -= (7.0 - IsNewyorkSummerTimeSeason(jst)) * 3600;
  
  // Round floor
  jst -= TimeHour(jst) * 3600 + TimeMinute(jst) * 60 + TimeSeconds(jst);

  // Shift to Saturday
  int w = 6 - TimeDayOfWeek(jst);
  if (w == 0) {
    w = 7;
  }
  jst += w * 86400;

  // Shift to NYCL
  jst += (7.0 - IsNewyorkSummerTimeSeason(jst)) * 3600;

  return(jst + (GMTOffsetHours - 9.0) * 3600);
}

