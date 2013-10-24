// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00255;
extern double OSAgainstEntryLevel =  2.417783;
extern double OSAgainstStopOffset =  1.499925;
extern double OSFollowEntryLevel  = 99.999;
extern double OSFollowStopLevel   = 99.999;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.1545;
extern double WorstLoss           = -4800;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

