//+------------------------------------------------------------------+
//|                                               IndicatorUtils.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 KIKUCHI Shunsuke"
#property library

/**
 * Return the number of bars to be calculated.
 */
int GetBarsToBeCalculated(int indicatorCounted, int minimumBars) {
  if (indicatorCounted < 0) {
    return(0);
  }

  int n = Bars - minimumBars;
  if (n < 0) {
    return(0);
  }

  int m = Bars - (indicatorCounted - 1);
  if (m < n) {
    return(m);
  }
  return(n);
}

