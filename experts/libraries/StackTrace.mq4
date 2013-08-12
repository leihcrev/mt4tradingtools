//+------------------------------------------------------------------+
//|                                                   StackTrace.mq4 |
//|                                  Copyright 2012 KIKUCHI Shunsuke |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 KIKUCHI Shunsuke"
#property library

string callstack[];
int callstack_index = 0;

/**
 * Push to call stack.
 */
void PushCallStack(string s) {
//  if (ArraySize(callstack) <= callstack_index) {
//    ArrayResize(callstack, callstack_index + 1);
//  }
//  callstack[callstack_index] = s;
//  callstack_index ++;
//  Print(s);
}

/**
 * Pop from call stack.
 */
void PopCallStack(string result) {
//  callstack_index --;
//  Print(callstack[callstack_index] + " = " + result);
}

/**
 * Print call stack.
 */
void PrintCallStack() {
  string result = "Depth: " + callstack_index;
  for (int i = callstack_index - 1; i >= 0; i--) {
    result = result + "<-" + callstack[i];
  }
  Print(result);
}

