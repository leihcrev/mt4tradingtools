//+------------------------------------------------------------------+
//|                                                   StackTrace.mqh |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#import "StackTrace.ex4"

/**
 * Push to call stack.
 */
void PushCallStack(string s);

/**
 * Pop from call stack.
 */
void PopCallStack(string result);

/**
 * Print call stack.
 */
void PrintCallStack();

