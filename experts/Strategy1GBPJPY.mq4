// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00860;
extern double OSAgainstEntryLevel =  1.41;
extern double OSAgainstStopOffset =  0.655;
extern double OSDrawdownFilter    =  1.00000000;
extern bool   EntryAfterFiltered  = false;
extern int    ContinuityThreshold = 999;
extern datetime UseContinuityFrom = D'2010.10.25 00:00:00';
extern bool   MoveSLWhenDD        = false;
extern double SLDistanceWhenDD    =  0.000;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.17944935; // ComfortableF=0.14160003, Leverage25F=unknown
extern double WorstLoss           = -1.40447650;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

