// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00340;
extern double OSAgainstEntryLevel =  2.12555593;
extern double OSAgainstStopOffset =  1.36364738;
extern double OSDrawdownFilter    =  0.70655036;
extern bool   EntryAfterFiltered  = true;
extern int    ContinuityThreshold = 999;
extern datetime UseContinuityFrom = D'2010.10.25 00:00:00';
extern bool   MoveSLWhenDD        = false;
extern double SLDistanceWhenDD    =  0.000;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.29409386; // ComfortableF=0.22815533, Leverage25F=0.14707142
extern double WorstLoss           = -0.79055301;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

