#include <OvershootECDF.mqh>

int start() {
  double level[0];
  int count[0];
  OvershootECDF_Read("OvershootECDF_USDJPY_0.002649", level, count);
//  for (int i = 0; i < ArraySize(level); i++) {
//    Print("level=", level[i], "/count=", count[i]);
//  }

  for (double osl = 0; osl < 10; osl += 0.1) {
    double p = OvershootECDF_Refer(level, count, osl);
    double prev = OvershootECDF_ReverseRefer(level, count, p);
    double pp = 1.0 - (1.0 - p) / MathExp(1);
    double pprev = OvershootECDF_ReverseRefer(level, count, pp);
    Print("level=", osl, "/p=", p, "/prev=", prev, "/pp=", pp, "/pprev=", pprev);
  }
}

