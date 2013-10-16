// DirectionalChange
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

/**
 * Update DC status.
 * Return true when DC occured.
 */
bool UpdateDCStatus(double logPrice, int th, double &threshold[], int &mode[], double &extremaPrice[], double &dcPrice[], double &currentLevel[], double &overshootLevel[]) {
  if (mode[th] == -1) {
    if (logPrice < extremaPrice[th]) {
      extremaPrice[th] = logPrice;
    }
    if (logPrice - extremaPrice[th] >= threshold[th]) {
      mode[th] = 1;
      dcPrice[th] = extremaPrice[th] + threshold[th];
      extremaPrice[th] = logPrice;
      currentLevel[th] = (logPrice - dcPrice[th]) / threshold[th];
      overshootLevel[th] = currentLevel[th];
      return(true);
    }
    else {
      currentLevel[th] = (dcPrice[th] - logPrice) / threshold[th];
      if (currentLevel[th] > overshootLevel[th]) {
        overshootLevel[th] = currentLevel[th];
      }
      return(false);
    }
  }
  else {
    if (logPrice > extremaPrice[th]) {
      extremaPrice[th] = logPrice;
    }
    if (extremaPrice[th] - logPrice >= threshold[th]) {
      mode[th] = -1;
      dcPrice[th] = extremaPrice[th] - threshold[th];
      extremaPrice[th] = logPrice;
      currentLevel[th] = (dcPrice[th] - logPrice) / threshold[th];
      overshootLevel[th] = currentLevel[th];
      return(true);
    }
    else {
      currentLevel[th] = (logPrice - dcPrice[th]) / threshold[th];
      if (currentLevel[th] > overshootLevel[th]) {
        overshootLevel[th] = currentLevel[th];
      }
      return(false);
    }
  }
}

