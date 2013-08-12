//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "Position.ex4"

/**
 * Take position immediatly.
 */
bool TakePosition(string symbol, int magic, int op, double lots, int stopLossPips, int takeProfitPips, int slippage, string comment);

/**
 * Close position immediatly.
 */
void ClosePosition(string symbol, int magic, int op, string comment);

/**
 * Get total of position lots.
 */
double GetPositionLots(string symbol, int magic, int op);

/**
 * Return optimal lots by OptimalF.
 */
double GetLotsByOptimalF(double OptimalF, double WorstLoss, double SL);

/**
 * Return true if position exists.
 */
bool HasPosition(string symbol, int magic, int op);

/**
 * Return optimal lots.
 */
double GetOptimalLots(string symbol, double weight, int stopLossPips);

/**
 * Move stop loss to break even when market price is over threshold (+/- market price * breakEvenThresholdPercent).
 */
void MoveStopLossToBreakEven(string symbol, int magic, int op, double breakEvenThresholdPercent);

/**
 * Move stop loss and take profit by a half-life.
 */
void MoveSLAndTPByHalfLife(string symbol, int magic, int op, int halfLifePeriodMinutes);

/**
 * Trailing stop.
 */
void Trail(string symbol, int magic, int op, double distancePercentUnderBE, double distancePercentOverBE);

/**
 * Trailing-stop by fixed Risk/Reward ratio.
 */
void TrailByFixedRiskRewardRatio(string symbol, int magic, int op, double riskRewardRatio);

