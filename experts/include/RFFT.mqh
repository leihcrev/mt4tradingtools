//+------------------------------------------------------------------+
//|                                                         RFFT.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "RFFT.ex4"

/**
 * Do fact Fourier transform for real number.
 *
 * @param out Array reference of result. Length needs 2 * nn.
 * @param in Array of real number.
 * @param nn Number of real numbers.
 */
void DoRealFastFourierTransform(double& out[], double in[], int nn);

