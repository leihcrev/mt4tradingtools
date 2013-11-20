// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00292;
extern double OSAgainstEntryLevel =  1.23497290;
extern double OSAgainstStopOffset =  1.90148972;
extern double OSDrawdownFilter    =  0.66426088;
extern bool   EntryAfterFiltered  = true;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.31263570; // ComfortableF=0.28753574, Leverage25F=0.17434972
extern double WorstLoss           = -0.68875114;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

