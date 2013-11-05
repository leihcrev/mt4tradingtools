// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00290;
extern double OSAgainstEntryLevel =  2.02074610;
extern double OSAgainstStopOffset =  1.15002551;
extern double OSFollowEntryLevel  = 99.999;
extern double OSFollowStopLevel   = 99.999;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.16043148; // * 0.81367524
extern double WorstLoss           = -4200;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

