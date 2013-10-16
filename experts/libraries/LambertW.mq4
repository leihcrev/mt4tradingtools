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
    else if (q < 0) {
      Print("LambertW0(x=", DoubleToStr(x, 8), "): x should be > -1/e.");
      return(-1.0);
    }
    else {
      double W;
      if (x < 1.0) {
        double p = MathSqrt(2.0 * MathExp(1) * q);
        W = -1.0 + p * (1.0 + p * (-1.0 / 3.0 + p * 11.0 / 72.0));
      }
      else {
        W = MathLog(x);
        if (x > 3.0) {
          W -= MathLog(W);
        }
      }
      return(LambertW_Fritsch("LambertW0(x=" + DoubleToStr(x, 8) + ")", x, W));
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
    else if (q < 0) {
      Print("LambertWm1(x=", DoubleToStr(x, 8), "): x should be > -1/e.");
      return(-1.0);
    }
    else {
      double l1 = MathLog(-x);
      double l2 = MathLog(-l1);
      return(LambertW_Fritsch("LambertWm1(x=" + DoubleToStr(x, 8) + ")", x, l1 - l2 + l2 / l1));
    }
  }
}

double LambertW_Fritsch(string caller, double x, double W) {
  if (W == 0.0) {
    Print(caller, " -> LambertW_Fritsch(x=", DoubleToStr(x, 8), ", W=", DoubleToStr(W, 8), "): W should not be 0.");
  }
  if (x / W < 0) {
    Print(caller, " -> LambertW_Fritsch(x=", DoubleToStr(x, 8), ", W=", DoubleToStr(W, 8), "): x and W shoule be same sign.");
  }
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

