//+------------------------------------------------------------------+
//|                                                    StopWatch.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "StopWatch.ex4"

/**
 * Initialize stop watch.
 */
void StopWatchInitialize(string tags[]);

/**
 * Split stop watch.
 */
void StopWatchSplit(int tagIndex);

/**
 * Output result of the stop watch.
 */
void StopWatchOutputResult();

