mt4tradingtools
===============
This is a set of trading tools for MetaTrader4.

- Strategy1
This is an Expert Advisor of MetaTrader4.
This EA takes the position when `overshoot' detected and closes when `overshoot' exhausted.

Usage:
1. Checkout codes
    Checkout all codes from `https://github.com/leihcrev/mt4tradingtools'.
2. Install
    Stop MT4.
    Copy all files under experts directory to `%%PROGRAMFILES%%\(MT4 Directory)\experts'.
3. Start EA
    Start MT4.
    Open M1 chart of USDJPY.
    Drag and drop Strategy1USDJPY in `Navigator - Expert Advisors' on the chart.
    Setting dialog will open, configure as below.
      Common tab
        Common
          Long & Short positions
          v Enable alerts
           - Disable alert once hit
        Live Trading
          v Allow live trading
           - Ask manual confirmation
        Safety
          - Allow DLL imports
           - Confirm DLL function calls
          v Allow import of external experts
      Inputs tab
        Do not modified.
    Push OK button.
    Press Expert Advisors button on tool bar. Green play mark will shown.
4. Check behavior
    `Strategy1USDJPY(^_^)' will shown on top right corner of the chart.

