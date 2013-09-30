// LambertW
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

#define PRECISION 0.00000001

/**
 * Calculate branch 0 of Lambert's W function.
 */
double LambertW0(double x) {
  if (x == 0.0) {
    return(0.0);
  }
  else {
    double q = x + MathExp(-1);
    if (q == 0.0) {
      return(-1.0);
    }
    else {
      double W;
      if (x < 1.0) {
        double p = MathSqrt(1.0 * MathExp(1) * q);
        W = -1.0 + p * (1.0 + p * (-1.0 / 3.0 + p * 11.0 / 72.0));
      }
      else {
        W = MathLog(x);
        if (x > 3.0) {
          W -= MathLog(W);
        }
      }
      return(LambertW_Fritsch(x, W));
    }
  }
}

/**
 * Calculate branch -1 of Lambert's W function.
 */
double LambertWm1(double x) {
  if (x == 0.0) {
    return(0.0);
  }
  else {
    double q = x + MathExp(-1);
    if (q == 0.0) {
      return(-1.0);
    }
    else {
      double l1 = MathLog(-x);
      double l2 = MathLog(-l1);
      return(LambertW_Fritsch(x, l1 - l2 + l2 / l1));
    }
  }
}

double LambertW_Fritsch(double x, double W) {
  double z = MathLog(x / W) - W;
  double q = 2 * (1 + W) * (1 + W + 2 * z / 3);
  double eps = z / (1 + W) * (q - z) / (q - 2 * z);
  while (PRECISION < MathAbs(eps)) {
    W += W * eps;
    z = MathLog(x / W) - W;
    q = 2 * (1 + W) * (1 + W + 2 * z / 3);
    eps = z / (1 + W) * (q - z) / (q - 2 * z);
  }
  return(W);
}

