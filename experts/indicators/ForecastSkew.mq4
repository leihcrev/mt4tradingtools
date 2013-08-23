// ForecastSkew
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 3

#property indicator_color1 Lime
#property indicator_width1 2
#property indicator_color2 Red
#property indicator_width2 2
#property indicator_color3 White
#property indicator_width3 1

#include <IndicatorUtils.mqh>
#include <OvershootECDF.mqh>

// Input parameters
extern double ThresholdStart  = 0.00010;
extern double ThresholdTick   = 0.00001;
extern int    Thresholds      = 50;
extern int    MaxBars         = 28800;

// Variables
double   threshold[0];
int      mode[0];
double   overshootLevel[0];
double   extremaPrice[0];
double   dcPrice[0];
double   evenOvershootLevel[0];
double   skewness[0];
bool     reliable[0];
bool     isInitialized = false;

int      index[0];
double   level[0];
int      count[0];

int      reliables = 0.0;

double   ReverseNapier;

// Buffers
double UpwardSkewness[];
double DownwardSkewness[];
double Skewness[];

int init() {
  ArrayResize(threshold, Thresholds);
  ArrayResize(mode, Thresholds);
  ArrayResize(overshootLevel, Thresholds);
  ArrayResize(extremaPrice, Thresholds);
  ArrayResize(dcPrice, Thresholds);
  ArrayResize(evenOvershootLevel, Thresholds);
  ArrayResize(skewness, Thresholds);
  ArrayResize(reliable, Thresholds);

  IndicatorShortName("ForecastSkew");

  IndicatorDigits(8);

  SetIndexLabel(0, "UpwardSkewness");
  SetIndexBuffer(0, UpwardSkewness);
  SetIndexStyle(0, DRAW_HISTOGRAM);
  SetIndexLabel(1, "DownwardSkewness");
  SetIndexBuffer(1, DownwardSkewness);
  SetIndexStyle(1, DRAW_HISTOGRAM);
  SetIndexLabel(2, "Skewness");
  SetIndexBuffer(2, Skewness);

  SetLevelValue(0, 1);
  SetLevelValue(1, -1);

  for (int th = 0; th < Thresholds; th++) {
    threshold[th] = ThresholdStart + ThresholdTick * th;
  }

  OvershootECDF_MultiRead(Symbol(), threshold, index, level, count);

  ReverseNapier = 1.0 / MathExp(1.0);

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double spread = Ask - Bid;

  if (!isInitialized) {
    isInitialized = true;
    for (int th = 0; th < Thresholds; th++) {
      mode[th] = 0;
      overshootLevel[th] = 0.0;
      extremaPrice[th] = High[MaxBars - 1] + spread / 2.0;
      dcPrice[th] = extremaPrice[th];
    }

    for (int i = MaxBars - 1; i >= 0; i--) {
      double prices[4];
      GetPricesFromBar(prices, i, spread);
      for (int j = 0; j < 4; j++) {
        UpdateDCOS(prices[j]);
      }
      UpdateBuffers(i, prices[3], spread);
    }
  }

  double x = (Bid + Ask) / 2.0;
  UpdateDCOS(x);
  UpdateBuffers(0, x, spread);

  return(0);
}

void GetPricesFromBar(double &prices[], int i, double spread) {
  spread /= 2.0;
  prices[0] = Open[i] + spread;
  prices[3] = Close[i] + spread;
  if (Open[i] < Close[i]) {
    prices[1] = Low[i] + spread;
    prices[2] = High[i] + spread;
  }
  else {
    prices[1] = High[i] + spread;
    prices[2] = Low[i] + spread;
  }
}

void UpdateDCOS(double x) {
  for (int th = 0; th < Thresholds; th++) {
    double currentLevel;
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
        mode[th] = 1;
        dcPrice[th] = extremaPrice[th] * (1.0 + threshold[th]);
        extremaPrice[th] = x;
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
        evenOvershootLevel[th] = GetEvenOvershootLevel(th);
      }
      else {
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
          evenOvershootLevel[th] = GetEvenOvershootLevel(th);
        }
      }
    } // end if (mode[th] == -1)
    else {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
        mode[th] = -1;
        dcPrice[th] = extremaPrice[th] * (1.0 - threshold[th]);
        extremaPrice[th] = x;
        currentLevel = (dcPrice[th] - x) / dcPrice[th] / threshold[th];
        overshootLevel[th] = currentLevel;
        if (!reliable[th]) {
          reliable[th] = true;
          reliables++;
        }
        evenOvershootLevel[th] = GetEvenOvershootLevel(th);
      }
      else {
        currentLevel = (x - dcPrice[th]) / dcPrice[th] / threshold[th];
        if (overshootLevel[th] < currentLevel) {
          overshootLevel[th] = currentLevel;
          evenOvershootLevel[th] = GetEvenOvershootLevel(th);
        }
      }
    } // end else (mode[th] == -1)
    if (reliable[th]) {
      double DCDistance = 1.0 + currentLevel - overshootLevel[th];
      double OSDistance = DCDistance * (evenOvershootLevel[th] - overshootLevel[th]);
      skewness[th] = mode[th] * (OSDistance - DCDistance) / 2.0;
    }
    else {
      skewness[th] = 0.0;
    }
  }
}

double GetEvenOvershootLevel(int th) {
  double p = OvershootECDF_MultiRefer(th, index, level, count, overshootLevel[th]);
  return(OvershootECDF_MultiReverseRefer(th, index, level, count, 1.0 - (1.0 - p) * ReverseNapier));
}

void UpdateBuffers(int i, double x, double spread) {
  double hiext = 0.0, loext = 0.0;
  double upReward = 0.0, downRisk = 0.0;
  double downReward = 0.0, upRisk = 0.0;
  double s = 0.0;

  for (int th = 0; th < Thresholds; th++) {
    s += skewness[th] * x / spread * threshold[th];
    if (s > hiext) {
      hiext = s;
    }
    if (s < loext) {
      loext = s;
    }
    if (loext > -1.0) {
      if (s + downReward > upReward + downRisk) {
        upReward = s;
        downRisk = loext;
      }
    } 
    if (hiext < 1.0) {
      if (s + upReward < downReward + upRisk) {
        downReward = s;
        downRisk = hiext;
      }
    }
    if (loext < -1.0 && hiext > 1.0) {
      break;
    }
  }
  UpwardSkewness[i] = MathMax(0, upReward + downRisk);
  DownwardSkewness[i] = MathMin(0, downReward + upRisk);
  Skewness[i] = (upReward + downRisk) + (downReward + upRisk);

/*
  double upReward = 0.0, downRisk = 0.0;
  double downReward = 0.0, upRisk = 0.0;
  int upLength = 1, downLength = 1;

  double s = 0.0;
  for (int th = 0; th < Thresholds; th++) {
    s += skewness[th] * threshold[th];
    if (s + downReward > upReward + downRisk) {
      upReward = s;
      downRisk = downReward;
      upLength = th + 1;
    }
    if (s + upReward < downReward + upRisk) {
      downReward = s;
      upRisk = upReward;
      downLength = th + 1;
    }
  }
  UpwardSkewness[i] = x / spread * MathMax(0, upReward + downRisk) / upLength;
  DownwardSkewness[i] = x / spread * MathMin(0, downReward + upRisk) / downLength;
  Skewness[i] = x / spread * ((upReward + downRisk) / upLength + (downReward + upRisk) / downLength);
*/

/*
  double risk, reward, s;
  int th;

  Skewness[i] = 0;

  risk = 0;
  reward = 0;
  for (th = 0; th < Thresholds; th++) {
    s = skewness[th];
    if (s < risk) {
      risk = s;
    }
    if (risk * threshold[th] < -spread) {
      break;
    }
    if (s > reward) {
      reward = s;
    }
  }
  if (reward == 0.0) {
    UpwardSkewness[i] = 0.0;
  }
  else {
    reward = reward * threshold[th];
    UpwardSkewness[i] = MathMax(0, reward);
    Skewness[i] += reward;
  }

  risk = 0;
  reward = 0;
  for (th = 0; th < Thresholds; th++) {
    s = skewness[th];
    if (s > risk) {
      risk = s;
    }
    if (risk * threshold[th] > spread) {
      break;
    }
    if (s < reward) {
      reward = s;
    }
  }
  if (reward == 0.0) {
    DownwardSkewness[i] = 0.0;
  }
  else {
    reward = reward * threshold[th];
    DownwardSkewness[i] = MathMin(0, reward);
    Skewness[i] += reward;
  }
*/
}

