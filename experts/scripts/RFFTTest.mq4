//+------------------------------------------------------------------+
//|                                                     RFFTTest.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property link      ""
#include <RFFT.mqh>

int start() {
  int i;
  int n = 16;
  double in[16];
  double out[32];
  
  // Test 1: in = 0, 1, 0, 1, ...
  for (i = 0; i < n; i++) {
    in[i] = i % 2;
  }
  DoRealFastFourierTransform(out, in, n);
  for (i = 0; i < n * 2; i++) {
    Print("out[", i, "] = ", out[i]);
  }

  // Test 2: in = 0, 1, 2, 3, 0, 1, 2, 3, 0, ...
  for (i = 0; i < n; i++) {
    in[i] = i % 4;
  }
  DoRealFastFourierTransform(out, in, n);
  for (i = 0; i < n * 2; i++) {
    Print("out[", i, "] = ", out[i]);
  }

  // Test 3
  in[0] = 3;
  in[1] = 1;
  in[2] = 4;
  in[3] = 1;
  in[4] = 5;
  in[5] = 9;
  in[6] = 2;
  in[7] = 6;
  in[8] = 5;
  in[9] = 3;
  in[10] = 5;
  in[11] = 8;
  in[12] = 9;
  in[13] = 7;
  in[14] = 9;
  in[15] = 3;
  DoRealFastFourierTransform(out, in, n);
  for (i = 0; i < n * 2; i++) {
    Print("out[", i, "] = ", out[i]);
  }

  return(0);
}

