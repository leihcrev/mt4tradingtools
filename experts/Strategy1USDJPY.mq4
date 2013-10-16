// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00265;
extern double OSAgainstEntryLevel =  1.463593;
extern double OSAgainstStopOffset =  2.264798;
extern double OSFollowEntryLevel  = 99.999;
extern double OSFollowStopLevel   = 99.999;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.3000;
extern double WorstLoss           = -8000;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

