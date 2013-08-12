//+------------------------------------------------------------------+
//|                                                        Tweet.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "Tweet.ex4"

/**
 * Tweet position opening message.
 */
void TweetOpenPosition(int ticket, string comment);

/**
 * Tweet position closing message.
 */
void TweetClosePosition(int ticket, string comment);

/**
 * Tweet message(msg).
 */
void Tweet(string msg);

/**
 * Tweet take profit or stop loss message.
 */
void TweetTakeProfitOrStopLoss(string symbol, int magicNumber);

