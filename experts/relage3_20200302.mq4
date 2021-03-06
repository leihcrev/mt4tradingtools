//+------------------------------------------------------------------+
//|                                             relage3_20200302.mq4 |
//|                        Copyright 2020, relage3, VIRTUE LLC Japan |
//|                                           https://www.virtue.llc |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, relage3, VIRTUE LLC Japan"
#property link        "https://www.virtue.llc"
#property version     "1.00"
#property description "・直近安/高値から[エントリ逆行Pips]だけ上昇/下降したところで、買/売エントリ (サイズは[初期ロットサイズ])"
#property description "・エントリ後、直近高/安値から[エントリ逆行Pips]だけ下降/上昇したら、ドテン"
#property description "・エントリ後、[ナンピン順行Pips]だけ上昇/下降するごとにナンピン買/売 (サイズは[ナンピンロットサイズ]、深さは[ナンピン回数])"
#property description "・全ての玉に対して、[利確価格(買/売)]または[利確Pips]から計算される価格のうち近い方をLIMITとして入れる"
#property description "・[利確価格(買/売)]に触ったらEA終了まで買/売エントリはしない"
#property description "・全ての玉に対して[損切Pips]に基づくSTOPを入れる ([トレーリングストップ]有効時は[トレーリングストップ幅Pips]分上昇/下降したとき)"

// TODO
// ・TakeProfitPriceLong/Short に触ったときに当該サイドのポジションを建てるのをやめる

#property strict
#include <stdlib.mqh>

// Custom types
enum StageType {
  WaitForEntry,
  HoldLong,
  HoldShort
};

// Input parameters
input double EntryAgainstPips = 30.0;                  // エントリ逆行Pips
input double EntryLots = 0.1;                          // 初期ロットサイズ
input double NanpinFollowPips = 20.0;                  // ナンピン順行Pips
input double NanpinLots = 0.1;                         // ナンピンロットサイズ
input int    NanpinDepth = 15;                         // ナンピン回数
input double TakeProfitPips = 100.0;                   // 利確Pips
input double TakeProfitPriceLong = 120.000;            // 利確価格(買)
input double TakeProfitPriceShort = 100.000;           // 利確価格(売)
input double StopLossPips = -10.0;                     // 損切Pips
input bool   BreakEvenMode = true;                     // トレーリングストップ
input double BreakEvenTriggerPips = 60.0;              // トレーリングストップ幅Pips
input double SlippagePips = 0.1;                       // スリッページ pips
input int    MagicNumber = 20200302;                   // マジックナンバー
input bool   Debug = true;                             // デバッグモード

// Module variables
double PipsToPoint;
StageType Stage;
double LowExtPrice;
double HighExtPrice;
int PositionCount;
bool buyFinished = false;
bool sellFinished = false;

//+------------------------------------------------------------------+
//| 価格変動時処理                                                   |
//+------------------------------------------------------------------+
void OnTick() {
// 打ち止め判定
  if (Bid >= TakeProfitPriceLong) {
    buyFinished = true;
  }
  if (Ask <= TakeProfitPriceShort) {
    sellFinished = true;
  }
// 取引
  if (Stage == WaitForEntry || Stage == HoldShort) {
    if (LowExtPrice > Ask) {
      LowExtPrice = Ask;
      LogDebug("LowExtPrice=" + DoubleToString(LowExtPrice, Digits));
    }
    Entry(OP_BUY);
  }
  if (Stage == WaitForEntry || Stage == HoldLong) {
    if (HighExtPrice < Bid) {
      HighExtPrice = Bid;
      LogDebug("HighExtPrice=" + DoubleToString(HighExtPrice, Digits));
    }
    Entry(OP_SELL);
  }
  if (Stage == HoldLong) {
    Nanpin(OP_BUY);
  }
  if (Stage == HoldShort) {
    Nanpin(OP_SELL);
  }
  if (BreakEvenMode) {
    if (Stage == HoldLong) {
      BreakEven(OP_BUY);
    } else if (Stage == HoldShort) {
      BreakEven(OP_SELL);
    }
  }
}

//+------------------------------------------------------------------+
//| エントリを判断・実行し、エントリしたら逆サイドは全決済           |
//+------------------------------------------------------------------+
void Entry(const int op) {
// エントリ判断・実行
  if ((op == OP_BUY && Ask - LowExtPrice > EntryAgainstPips * PipsToPoint * Point) ||
      (op == OP_SELL && HighExtPrice - Bid > EntryAgainstPips * PipsToPoint * Point)) {
    if (SettleAll()) {
      Stage = WaitForEntry;
      if (TakePosition(op, EntryLots)) {
        if (op == OP_BUY) {
          Stage = HoldLong;
          HighExtPrice = Bid;
        } else {
          Stage = HoldShort;
          LowExtPrice = Ask;      
        }
        PositionCount = 0;
      }
    }
  }
}

//+------------------------------------------------------------------+
//| ナンピン判断・実行                                               |
//+------------------------------------------------------------------+
void Nanpin(const int op) {
// ナンピン回数判定
  if (PositionCount >= NanpinDepth) {
    return;
  }
// ナンピン価格計算
  double heightPips = (PositionCount + 1) * NanpinFollowPips + EntryAgainstPips;
// ナンピン判断・実行
  if ((op == OP_BUY && Ask - LowExtPrice > heightPips * PipsToPoint * Point) ||
      (op == OP_SELL && HighExtPrice - Bid > heightPips * PipsToPoint * Point)) {
    if (TakePosition(op, NanpinLots)) {
      PositionCount ++;
    }
  }
}

//+------------------------------------------------------------------+
//| ポジションを取る                                                 |
//+------------------------------------------------------------------+
bool TakePosition(const int op, const double lots) {
// 打ち止め判定
  if ((op == OP_BUY && buyFinished) || (op == OP_SELL && sellFinished)) {
    return true;
  }
// LIMIT 価格の計算
  double limitPrice;
  if (op == OP_BUY) {
    limitPrice = Ask + TakeProfitPips * PipsToPoint * Point;
    if (limitPrice > TakeProfitPriceLong) {
      limitPrice = TakeProfitPriceLong;
    }
  } else {
    limitPrice = Bid - TakeProfitPips * PipsToPoint * Point;
    if (limitPrice < TakeProfitPriceShort) {
      limitPrice = TakeProfitPriceShort;
    }
  }
// STOP 価格の計算
  double stopPrice = 0.0;
  if (!BreakEvenMode) {
    if (op == OP_BUY) {
      stopPrice = Ask - StopLossPips * PipsToPoint * Point;
    } else {
      stopPrice = Bid + StopLossPips * PipsToPoint * Point;
    }
  }
// 発注
  if (!OrderSend(Symbol(), op, lots, op == OP_BUY ? Ask : Bid, (int) (SlippagePips * PipsToPoint), NormalizeDouble(stopPrice, Digits), NormalizeDouble(limitPrice, Digits), WindowExpertName() + " Entry", MagicNumber)) {
    int lastError = GetLastError();
    Print("TakePosition(", op, "): Cannot send order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
    return false;
  }
  return true;
}

//+------------------------------------------------------------------+
//| MagicNumber に基づいて全決済                                     |
//+------------------------------------------------------------------+
bool SettleAll() {
  int lastError;
  for (int i = OrdersTotal() - 1; i >= 0; i--) {
    if (!OrderSelect(i, SELECT_BY_POS)) {
      Print("SettleAll(): Cannot select order.");
      return false;
    }
    if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
      RefreshRates();
      double orderPrice = OrderType() == OP_BUY ? Bid : Ask;
      if (!OrderClose(OrderTicket(), OrderLots(), orderPrice, (int) (SlippagePips * PipsToPoint))) {
        Print("SettleAll(): Cannot close position.");
        return false;
      }
      lastError = GetLastError();
      if (lastError != 0) {
        Print("SettleAll(): Error occured when trying to close order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
      }
    }
  }
  return true;
}

//+------------------------------------------------------------------+
//| ブレイクイーブン処理を判断・実行する                             |
//+------------------------------------------------------------------+
void BreakEven(const int op) {
  if (!BreakEvenMode) {
    return;
  }
  for (int i = 0; i < OrdersTotal(); i++) {
    if (!OrderSelect(i, SELECT_BY_POS)) {
      Print("BreakEven(", op, "): Cannot select order.");
      return;
    }
    if (OrderMagicNumber() == MagicNumber) {
      if (OrderSymbol() == Symbol()) {
        if (op == OrderType()) {
          double sl;
          if (OrderType() == OP_BUY && OrderOpenPrice() + BreakEvenTriggerPips * PipsToPoint * Point <= Bid) {
            sl = OrderOpenPrice() - StopLossPips * PipsToPoint * Point;
            if (OrderStopLoss() != 0.0 && sl <= OrderStopLoss()) {
              continue;
            }
          } else if (OrderType() == OP_SELL && OrderOpenPrice() - BreakEvenTriggerPips * PipsToPoint * Point >= Ask) {
            sl = OrderOpenPrice() + StopLossPips * PipsToPoint * Point;
            if (OrderStopLoss() != 0.0 && sl >= OrderStopLoss()) {
              continue;
            }
          } else {
            continue;
          }
          if (!OrderModify(OrderTicket(), 0.0, sl, OrderTakeProfit(), OrderExpiration())) {
            int lastError = GetLastError();
            if (lastError != 0) {
              Print("BreakEven(", op, "): Error occured when trying to modify order. GetLastError()=", lastError, "(", ErrorDescription(lastError), ")");
            }
          }
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//| 起動時処理 (パラメータのチェック、状態の初期化)                  |
//+------------------------------------------------------------------+
int OnInit() {
// Pips ←→ Point 換算係数
  PipsToPoint = Digits == 3 || Digits == 5 ? 10.0 : 1.0;
  LogDebug("OnInit(): PipsToPoint=" + DoubleToString(PipsToPoint, 1));
// トレーリングストップに関するパラメータのチェック
  double stopLevelPoint = MarketInfo(Symbol(), MODE_STOPLEVEL);
  LogDebug("OnInit(): stopLevelPoint=" + DoubleToString(stopLevelPoint, 1));
  if (!BreakEvenMode && StopLossPips * PipsToPoint <= stopLevelPoint) {
    InvalidParam("トレーリングストップ無効時は、損切Pipsは" + DoubleToString(stopLevelPoint / PipsToPoint, 1) + "以上にしてください。");
    return(INIT_PARAMETERS_INCORRECT);
  }
// ステージ
  Stage = WaitForEntry;
// 安値/高値
  LowExtPrice = Ask;
  HighExtPrice = Bid;
  LogDebug("OnInit(): LowExtPrice=" + DoubleToString(LowExtPrice, Digits) + "/HighExtPrice=" + DoubleToString(HighExtPrice, Digits));
// 初期化正常終了
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 終了時処理                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//| 不適切なパラメータについて警告表示する                           |
//+------------------------------------------------------------------+
void InvalidParam(const string msg) {
  Print(msg);
  Alert(msg);
}

//+------------------------------------------------------------------+
//| デバッグモード時のみデバッグメッセージを出力する                 |
//+------------------------------------------------------------------+
void LogDebug(const string msg) {
  if (Debug) {
    Print(msg);
  }
}
//+------------------------------------------------------------------+
