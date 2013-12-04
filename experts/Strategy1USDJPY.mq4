// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00292;
extern double OSAgainstEntryLevel =  1.23438700;
extern double OSAgainstStopOffset =  1.90137109;
extern double OSDrawdownFilter    =  0.66426088;
extern bool   EntryAfterFiltered  = true;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.31316174; // ComfortableF=0.28803008, Leverage25F=0.17428598
extern double WorstLoss           = -0.68849934;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

