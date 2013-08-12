// SMQ: The scale of Market Quakes
#property copyright "KIKUCHI Shunsuke"
#property link      "https://sites.google.com/site/leihcrev/"

#property indicator_separate_window
#property indicator_buffers 4

#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 Lime
#property indicator_color4 LightGreen
#property indicator_style1 0
#property indicator_style2 0
#property indicator_style3 0
#property indicator_style4 0
#property indicator_width1 2
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#property indicator_level1 1
#property indicator_level2 2
#property indicator_level3 3
#property indicator_level4 4
#property indicator_level5 5
#property indicator_level6 6
#property indicator_level7 -5

#include <IndicatorUtils.mqh>
#include <RFFT.mqh>

#define SMQ_PERIOD  128
#define SMQ_PERIOD2 256

// Input parameters
extern int InitialBars       = 32768;
extern int DeltaSMQMA.Period = 15;

// Variables
double   threshold[100];
int      mode[100]; // 1: up, -1: down
double   overshootLevel[100];
double   extremaPrice[100];
double   dcPrice[100];
bool     isInitialized = false;
double   DeltaSMQMA.r;

// Buffers
double SMQ[];
double DeltaSMQ[];
double DeltaSMQMA[];
double Delta2SMQMA[];
double OSPA[];
double Trend[];
double Accuracy[];

int init() {
  IndicatorShortName("SMQ");

  IndicatorBuffers(7);

  SetIndexLabel(0, "SMQ");
  SetIndexBuffer(0, SMQ);
  SetIndexLabel(1, "DeltaSMQ");
  SetIndexBuffer(1, DeltaSMQ);
  SetIndexLabel(2, "DeltaSMQMA");
  SetIndexBuffer(2, DeltaSMQMA);
  SetIndexLabel(3, "Delta2SMQMA");
  SetIndexBuffer(3, Delta2SMQMA);

  // Invisible buffers
  SetIndexStyle(4, DRAW_NONE);
  SetIndexBuffer(4, OSPA);
  SetIndexStyle(5, DRAW_NONE);
  SetIndexBuffer(5, Trend);
  SetIndexStyle(6, DRAW_NONE);
  SetIndexBuffer(6, Accuracy);

  for (int th = 0; th < 100; th++) {
    threshold[th] = 0.0005 * (th + 1);
  }

  DeltaSMQMA.r = (DeltaSMQMA.Period - 1.0) / (DeltaSMQMA.Period + 1.0);

  return(0);
}

int deinit() {
  return(0);
}

int start() {
  double currentLevel;
  int th;
  double FFTin[SMQ_PERIOD];
  double FFTout[SMQ_PERIOD2];
  int j;
  double avg, re, im, abs;

  if (!isInitialized) {
    isInitialized = true;
    int b = MathMin(InitialBars, Bars);
    for (th = 0; th < 100; th++) {
      mode[th] = 0;
      overshootLevel[th] = 0.0;
      extremaPrice[th] = High[b - 1];
      dcPrice[th] = extremaPrice[th];
    }

    for (int i = b - 1; i >= 0; i--) {
      OSPA[i] = 0.0;
      Trend[i] = 0.0;
      Accuracy[i] = 0.0;
      SMQ[i] = 0.0;
      for (th = 0; th < 100; th++) {
        if (mode[th] == -1) {
          if (Low[i] < extremaPrice[th]) {
            extremaPrice[th] = Low[i];
          }
          if ((High[i] - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
            mode[th] = 1;
            extremaPrice[th] = High[i];
            dcPrice[th] = Low[i];
            overshootLevel[th] = 0;
          }
          else {
            currentLevel = (dcPrice[th] - High[i]) / dcPrice[th] / threshold[th];
            if (overshootLevel[th] < currentLevel) {
              overshootLevel[th] = currentLevel;
            }
          }
        }
        else {
          if (High[i] > extremaPrice[th]) {
            extremaPrice[th] = High[i];
          }
          if ((Low[i] - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
            mode[th] = -1;
            extremaPrice[th] = Low[i];
            dcPrice[th] = High[i];
            overshootLevel[th] = 0;
          }
          else {
            currentLevel = (Low[i] - dcPrice[th]) / dcPrice[th] / threshold[th];
            if (overshootLevel[th] < currentLevel) {
              overshootLevel[th] = currentLevel;
            }
          }
        }
        if (mode[th] == 0) {
          OSPA[i] += 0.5;
          Trend[i] += 0.5;
        }
        else {
          OSPA[i] += 1.0 - 1.0 / MathPow(MathExp(1.0), overshootLevel[th]);
          if (mode[th] == 1) {
            Trend[i]++;
          }
          Accuracy[i] += 1.0;
        }
      }
      ArrayCopy(FFTin, OSPA, 0, i, SMQ_PERIOD);
      avg = 0.0;
      for (j = 0; j < SMQ_PERIOD; j++) {
        avg += FFTin[j];
      }
      avg /= SMQ_PERIOD;
      for (j = 0; j < SMQ_PERIOD; j++) {
        FFTin[j] -= avg;
      }
      DoRealFastFourierTransform(FFTout, FFTin, SMQ_PERIOD);
      for (j = 0; j < SMQ_PERIOD; j++) {
        re = FFTout[j * 2];
        im = FFTout[j * 2 + 1];
        abs = MathSqrt(re * re + im * im);
        SMQ[i] += abs / (j + 1);
      }
      SMQ[i] /= SMQ_PERIOD;
      DeltaSMQ[i] = (SMQ[i] - SMQ[i+1]) * 100;
      DeltaSMQMA[i] = DeltaSMQMA[i+1] * DeltaSMQMA.r + DeltaSMQ[i] * (1.0 - DeltaSMQMA.r);
      Delta2SMQMA[i] = Delta2SMQMA[i+1] * DeltaSMQMA.r + (DeltaSMQ[i] - DeltaSMQ[i+1]) * (1.0 - DeltaSMQMA.r) * 10.0;
    }
  }

  double x = (Bid + Ask) / 2.0;
  OSPA[0] = 0.0;
  Trend[0] = 0.0;
  Accuracy[0] = 0.0;
  SMQ[0] = 0.0;
  for (th = 0; th < 100; th++) {
    if (mode[th] == -1) {
      if (x < extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] >= threshold[th]) {
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
    else {
      if (x > extremaPrice[th]) {
        extremaPrice[th] = x;
      }
      if ((x - extremaPrice[th]) / extremaPrice[th] <= -threshold[th]) {
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
    if (mode[th] == 0) {
      OSPA[0] += 0.5;
      Trend[0] += 0.5;
    }
    else {
      OSPA[0] += 1.0 - 1.0 / MathPow(MathExp(1.0), overshootLevel[th]);
      if (mode[th] == 1) {
        Trend[0]++;
      }
      Accuracy[0] += 1.0;
    }
  }
  ArrayCopy(FFTin, OSPA, 0, 0, SMQ_PERIOD);
  avg = 0.0;
  for (j = 0; j < SMQ_PERIOD; j++) {
    avg += FFTin[j];
  }
  avg /= SMQ_PERIOD;
  for (j = 0; j < SMQ_PERIOD; j++) {
    FFTin[j] -= avg;
  }
  DoRealFastFourierTransform(FFTout, FFTin, SMQ_PERIOD);
  for (j = 0; j < SMQ_PERIOD; j++) {
    re = FFTout[j * 2];
    im = FFTout[j * 2 + 1];
    abs = MathSqrt(re * re + im * im);
    SMQ[0] += abs / (j + 1);
  }
  SMQ[0] /= SMQ_PERIOD;
  DeltaSMQ[0] = (SMQ[0] - SMQ[1]) * 100;
  DeltaSMQMA[0] = DeltaSMQMA[1] * DeltaSMQMA.r + DeltaSMQ[0] * (1.0 - DeltaSMQMA.r);
  Delta2SMQMA[0] = Delta2SMQMA[1] * DeltaSMQMA.r + (DeltaSMQ[0] - DeltaSMQ[1]) * (1.0 - DeltaSMQMA.r) * 10.0;

  return(0);
}

