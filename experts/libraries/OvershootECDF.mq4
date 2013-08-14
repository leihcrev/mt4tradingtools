// OvershootECDF
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

string symbol = "";
double ecdf[1000][10000];
double evenOSLevel[1000][10000];
int thresholds;
double thresholdTick;
int levels;
double levelTick;

/**
 * Return overshoot ECDF.
 */
double GetOvershootECDF(string sym, double threshold, double overshootLevel) {
  OvershootECDF_Initialize(sym);
  int th = threshold / thresholdTick;
  if (th >= thresholds) {
    return(0.0);
  }
  int level = overshootLevel / levelTick;
  if (level >= levels) {
    return(1.0);
  }
  return(ecdf[th][level]);
}

/**
 * Return even overshoot level.
 */
double GetEvenOvershootLevel(string sym, double threshold, double overshootLevel) {
  OvershootECDF_Initialize(sym);
  int th = threshold / thresholdTick;
  if (th >= thresholds) {
    return(0.0);
  }
  int level = overshootLevel / levelTick;
  if (level >= levels) {
    return(1.0);
  }
  return(evenOSLevel[th][level]);
}

void OvershootECDF_Initialize(string sym) {
  if (sym == symbol) {
    return;
  }
  symbol = sym;

  Print("Initializing");
  int handle = FileOpen("OvershootECDF_" + symbol + ".dat", FILE_READ | FILE_BIN);
  thresholds = FileReadInteger(handle);
  thresholdTick = FileReadDouble(handle);
  levels = FileReadInteger(handle);
  levelTick = FileReadDouble(handle);
  for (int th = 0; th < thresholds; th++) {
    int level;
    for (level = 0; level < levels; level++) {
      ecdf[th][level] = FileReadDouble(handle);
    }
    for (level = 0; level < levels; level++) {
      evenOSLevel[th][level] = FileReadDouble(handle);
    }
  }
  FileClose(handle);
  Print("Initialized");
}

