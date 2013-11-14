// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00375;
extern double OSAgainstEntryLevel =  2.52563289;
extern double OSAgainstStopOffset =  0.55455986;
extern double OSDrawdownFilter    =  1.00000000;
extern bool   EntryAfterFiltered  = false;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.08811605; // ComfortableF=0.06121128, Leverage25F=unknown
extern double WorstLoss           = -0.36463861;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

