// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00340;
extern double OSAgainstEntryLevel =  2.12177734;
extern double OSAgainstStopOffset =  1.36894531;
extern double OSDrawdownFilter    =  0.70648437;
extern bool   EntryAfterFiltered  = false;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.29162664; // ComfortableF=0.22811993, Leverage25F=0.14755137
extern double WorstLoss           = -0.79313289;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

