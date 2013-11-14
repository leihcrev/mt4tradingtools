// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00270;
extern double OSAgainstEntryLevel =  1.41703145;
extern double OSAgainstStopOffset =  1.85423170;
extern double OSDrawdownFilter    =  0.72434017;
extern bool   EntryAfterFiltered  = true;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.33785301; // ComfortableF=0.28642024, Leverage25F=0.15731962
extern double WorstLoss           = -0.62143139;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

