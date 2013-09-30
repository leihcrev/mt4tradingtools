#include <LambertW.mqh>

void start() {
  Print("p,w,w0,wm1");
  for (double p = 0.01; p < 1; p += 0.01) {
    double w0 = 1 / (MathLog(p) / LambertW0(p * MathLog(p)) + 1);
    double wm1 = 1 / (MathLog(p) / LambertWm1(p * MathLog(p)) + 1);
    double w;
    if (p < MathExp(-1)) {
      w = w0;
    }
    else {
      w = wm1;
    }
    Print(p, ",", w, ",", w0, ",", wm1);
  }
}

