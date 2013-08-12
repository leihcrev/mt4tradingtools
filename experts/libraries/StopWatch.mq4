//+------------------------------------------------------------------+
//|                                                    StopWatch.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 KIKUCHI Shunsuke"
#property library

static int swTagCount;
static string swTags[0];
static int swCumulativeMillis[0];
static int swLatestTimestamp;

/**
 * Initialize stop watch.
 */
void StopWatchInitialize(string tags[]) {
  if (!IsTesting()) {
    return;
  }
  swTagCount = ArraySize(tags);
  ArrayResize(swTags, swTagCount);
  ArrayCopy(swTags, tags);
  ArrayResize(swCumulativeMillis, swTagCount);
  ArrayInitialize(swCumulativeMillis, 0);
  swLatestTimestamp = GetTickCount();
}

/**
 * Split stop watch.
 */
void StopWatchSplit(int tagIndex) {
  if (!IsTesting()) {
    return;
  }
  int now = GetTickCount();
  swCumulativeMillis[tagIndex] += now - swLatestTimestamp;
  swLatestTimestamp = now;
}

/**
 * Output result of the stop watch.
 */
void StopWatchOutputResult() {
  if (!IsTesting()) {
    return;
  }
  for (int i = 0; i < swTagCount; i++) {
    Print(swTags[i], "=", swCumulativeMillis[i]);
  }
}

