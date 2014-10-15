// Input parameters
extern string StrategyParameters  = "==== Strategy parameters ====";
extern double DCThreshold         =  0.00299;
extern double OSAgainstEntryLevel =  1.59;
extern double OSAgainstStopOffset =  1.00;
extern double OSDrawdownFilter    =  0.63212056;
extern bool   EntryAfterFiltered  = true;
extern int    ContinuityThreshold = 0;
extern datetime UseContinuityFrom = D'2010.10.25 00:00:00';
extern bool   MoveSLWhenDD        = false;
extern double SLDistanceWhenDD    =  0.170;
extern double GMTOffset           =  9.0;
extern double WeekendMarginSecs   = 0;
extern string OrderParameters     = "==== Order parameters ====";
extern double OptimalF            = 0.07497417;
extern double Leverage            = 25.0;
extern double Lots                = 0.0;
extern int    MagicNumber         = 1;

#include <Strategy1.mqh>

