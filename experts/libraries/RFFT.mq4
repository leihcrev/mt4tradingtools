// RFFT.mq4
#property copyright "KIKUCHI Shunsuke"
#property link      "http://sites.google.com/site/leihcrev/"
#property library

#define pi 3.14159265358979323846

/**
 * Do fact Fourier transform for real number.
 *
 * @param out Array reference of result. Length needs 2 * nn.
 * @param in Array of real number.
 * @param nn Number of real numbers.
 */
void DoRealFastFourierTransform(double& out[], double in[], int nn) {
  double tempr, tempi;
  int i, j;

  int n = 2 * nn;
  ArrayResize(out, n);
  for (i = 0; i < nn; i++) {
    out[i * 2    ] = in[i];
    out[i * 2 + 1] = 0.0;
  }

  if (nn == 1) {
    return;
  }

  int m;
  j = 0;
  for (i = 0; i < n; i += 2) {
    if (j > i) {
      tempr = out[j];
      out[j] = out[i];
      out[i] = tempr;
    }
    
    for (m = nn; m >= 2 && (j + 1) > m; m /= 2) {
      j -= m;
    }
    j += m;
  }

  int istep;
  for (int mmax = 2; mmax < n; mmax = istep) {
    istep = 2 * mmax;
    double theta = 2.0 * pi / mmax;
    double wpr = - 2.0 * MathPow(MathSin(0.5 * theta), 2);
    double wpi = MathSin(theta);
    double wr = 1.0;
    double wi = 0.0;
    for (int ii = 1; ii <= mmax / 2; ii++) {
      m = 2 * ii - 1;
      for (int jj = 0; jj <= (n - m) / istep; jj++) {
        i = m + jj * istep;
        j = i + mmax;
        tempr = wr * out[j - 1] - wi * out[j    ];
        tempi = wr * out[j    ] + wi * out[j - 1];
        out[j - 1] = out[i - 1] - tempr;
        out[j    ] = out[i    ] - tempi;
        out[i - 1] += tempr;
        out[i    ] += tempi;
      }
      double wtemp = wr;
      wr = wr * wpr - wi    * wpi + wr;
      wi = wi * wpr + wtemp * wpi + wi;
    }
    mmax = istep;
  }

  double h1r, h1i, h2r, h2i, wrs, wis;
  double twr, twi, twpr, twpi, twtemp;
  double ttheta = 2.0 * pi / n;
  twpr = - 2.0 * MathPow(MathSin(0.5 * ttheta), 2);
  twpi = MathSin(ttheta);
  twr = 1.0 + twpr;
  twi = twpi;
  for (ii = 2; ii <= nn / 2 + 1; ii++) {
    int i1 = 2 * (ii - 1);
    int i2 = n - i1;
    wrs = twr;
    wis = twi;
    h1r =   (out[i1    ] + out[i2    ]) / 2;
    h1i =   (out[i1 + 1] - out[i2 + 1]) / 2;
    h2r =   (out[i1 + 1] + out[i2 + 1]) / 2;
    h2i = - (out[i1    ] - out[i2    ]) / 2;
    out[i1    ] =   h1r + wrs * h2r - wis * h2i;
    out[i1 + 1] = - h1i - wrs * h2i - wis * h2r;
    out[i2    ] =   h1r - wrs * h2r + wis * h2i;
    out[i2 + 1] =   h1i - wrs * h2i - wis * h2r;
    twtemp = twr;
    twr = twr * twpr - twi    * twpi + twr;
    twi = twi * twpr + twtemp * twpi + twi;
  }
  h1r = out[0];
  out[0] = h1r + out[1];
  out[1] = 0; // h1r - out[1];
}

