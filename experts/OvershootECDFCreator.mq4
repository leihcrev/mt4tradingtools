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

  int handle = FileOpen("OvershootECDF_" + Symbol() + ".dat", FILE_WRITE | FILE_BIN);
  FileWriteInteger(handle, THRESHOLDS);
  FileWriteDouble(handle, THRESHOLD_TICK);
  FileWriteInteger(handle, LEVELS);
  FileWriteDouble(handle, LEVEL_TICK);

  double idealp = 1.0 - 1.0 / MathExp(1.0);
  double cumsumscore;
  double ecdf[LEVELS];
  for (int th = 0; th < THRESHOLDS; th++) {
    cumsumscore = 0.0;
    for (level = 0; level < LEVELS; level++) {
      cumsumscore += score[th][level];
      ecdf[level] = cumsumscore / total[th];
      FileWriteDouble(handle, ecdf[level]);
    }
    
    for (level = 0; level < LEVELS; level++) {
      double basep = ecdf[level];
      if (basep == 1.0) {
        FileWriteDouble(handle, level * LEVEL_TICK + 1.0);
        continue;
      }
      int targetLevel = level + (1.0 / LEVEL_TICK);
      if (targetLevel >= LEVELS) {
        targetLevel = LEVELS - 1;
      }
      double targetp = ecdf[targetLevel];
      if ((targetp - basep) / (1.0 - basep) < idealp) {
        while ((targetp - basep) / (1.0 - basep) < idealp) {
          targetLevel++;
          if (targetLevel >= LEVELS) {
            break;
          }
          targetp = ecdf[targetLevel];
        }
      }
      else {
        while ((targetp - basep) / (1.0 - basep) > idealp) {
          targetLevel--;
          if (targetLevel <= 0) {
            break;
          }
          targetp = ecdf[targetLevel];
        }
      }
      FileWriteDouble(handle, targetLevel * LEVEL_TICK);
    }
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

