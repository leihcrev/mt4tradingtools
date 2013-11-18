// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00292;
extern double OSAgainstEntryLevel =  1.23495337;
extern double OSAgainstStopOffset =  1.89756012;
extern double OSDrawdownFilter    =  0.66424134;
extern bool   EntryAfterFiltered  = true;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.31098729; // ComfortableF=0.28602817, Leverage25F=0.17399242
extern double WorstLoss           = -0.68733966;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

