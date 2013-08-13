// OvershootECDFCreator: Create ECDF data of overshoot level
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#define THRESHOLDS     1000
#define THRESHOLD_TICK 0.00001
#define LEVELS         10000
#define LEVEL_TICK     0.01

// Variables
double   threshold[THRESHOLDS];
int      mode[THRESHOLDS]; // 1: up, -1: down
double   overshootLevel[THRESHOLDS];
double   extremaPrice[THRESHOLDS];
double   dcPrice[THRESHOLDS];
int      score[THRESHOLDS][LEVELS];
int      total[THRESHOLDS];

int init() {
  for (int th = 0; th < THRESHOLDS; th++) {
    threshold[th] = THRESHOLD_TICK * (th + 1);
    total[th] = 0;
    for (int level = 0; level < LEVELS; level++) {
      score[th][level] = 0;
    }
  }
  return(0);
}

int deinit() {
  int level;
  string row;

  int handle = FileOpen("OvershootECDF_" + Symbol() + ".csv", FILE_WRITE);

  row = "\"threshold-level\"";
  for (level = 0; level < LEVELS; level++) {
    row = row + "," + DoubleToStr(level * LEVEL_TICK, -MathFloor(MathLog(LEVEL_TICK) / MathLog(10.0)));
  }
  FileWrite(handle, row);

  double cumsumscore;
  for (int th = 0; th < THRESHOLDS; th++) {
    cumsumscore = 0.0;
    row = DoubleToStr(threshold[th], -MathFloor(MathLog(THRESHOLD_TICK) / MathLog(10.0)));
    for (level = 0; level < LEVELS; level++) {
      int s = score[th][level];
      if (s == 0) {
        row = row + ",";
        continue;
      }
      cumsumscore += s;
      row = row + "," + (cumsumscore / total[th]);
      if (cumsumscore == total[th]) {
        break;
      }
    }
    FileWrite(handle, row);
    FileFlush(handle);
  }

  FileClose(handle);
  return(0);
}

int start() {
//  static datetime prevtime;
//  if (prevtime != Time[0] && TimeDay(Time[1]) != TimeDay(Time[0])) {
//    Print(TimeToStr(Time[0], TIME_DATE | TIME_SECONDS));
//  }
//  prevtime = Time[0];

  double currentLevel;
  int level;
  double x = (Bid + Ask) / 2.0;
  for (int th = 0; th < THRESHOLDS; th++) {
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        level = MathFloor(overshootLevel[th] / LEVEL_TICK);
        if (level >= LEVELS) {
          level = LEVELS - 1;
        }
        score[th][level]++;
        total[th]++;

        mode[th] = 1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        overshootLevel[th] = 0;
      }
      else {
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    }
    else if (mode[th] == 1) {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
        level = MathFloor(overshootLevel[th] / LEVEL_TICK);
        if (level >= LEVELS) {
          level = LEVELS - 1;
        }
        score[th][level]++;
        total[th]++;

        mode[th] = -1;
        extremaPrice[th] = x;
        dcPrice[th] = x;
        overshootLevel[th] = 0;
      }
      else {
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
        }
      }
    }
    else {
      mode[th] = 1;
      extremaPrice[th] = x;
      dcPrice[th] = x;
      overshootLevel[th] = 0;
    }
  }

  return(0);
}

