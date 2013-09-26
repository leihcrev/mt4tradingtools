// DirectionalChange
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

/**
 * Update DC status.
 * Return true when DC occured.
 */
bool UpdateDCStatus(double currentPrice, double threshold,
    int &mode, double &extremaPrice, double &dcPrice, double &currentLevel, double &overshootLevel,
    int &prevMode, double &prevExtremaPrice, double &prevDcPrice, double &prevCurrentLevel, double &prevOvershootLevel) {
  prevMode = mode;
  prevExtremaPrice = extremaPrice;
  prevDcPrice = dcPrice;
  prevCurrentLevel = currentLevel;
  prevOvershootLevel = overshootLevel;

  double x = MathLog(currentPrice);
  double newlevel;
  bool ret = false;
  if (mode == -1) {
    if (x < extremaPrice) {
      extremaPrice = x;
    }
    if (x - extremaPrice >= threshold) {
      newlevel = (x - dcPrice) / threshold;
      mode = 1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = newlevel;
      overshootLevel = newlevel;
      ret = true;
    }
    else {
      currentLevel = (dcPrice - x) / threshold;
      if (currentLevel > overshootLevel) {
        overshootLevel = currentLevel;
      }
    }
  }
  else {
    if (x > extremaPrice) {
      extremaPrice = x;
    }
    if (extremaPrice - x >= threshold) {
      newlevel = (dcPrice - x) / threshold;
      mode = -1;
      extremaPrice = x;
      dcPrice = x;
      currentLevel = newlevel;
      overshootLevel = newlevel;
      ret = true;
    }
    else {
      currentLevel = (x - dcPrice) / threshold;
      if (currentLevel > overshootLevel) {
        overshootLevel = currentLevel;
      }
    }
  }
  return(ret);
}

