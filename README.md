mt4tradingtools
===============
This is a set of trading tools for MetaTrader4.

# Strategy1
This is an Expert Advisor of MetaTrader4.
This EA takes the position when *overshoot* detected and closes when *overshoot* exhausted.

## Usage
1. Checkout codes
 * Checkout all codes from https://github.com/leihcrev/mt4tradingtools
2. Install
 * For older than build 600
    - Stop MT4 if running
    - Copy all files under experts directory to `%%PROGRAMFILES%%\MT4 Directory\experts`
    - Start MT4
 * For build 600 and newer
    - Start MT4
    - Click File - Open Data Folder
    - Copy `experts\*.mq4` to Experts in the above folder
    - Copy `experts\files\*.*` to Files
    - Do in the same manner for include, indicators, libraries, scripts.
3. Start EA
 * Open M1 chart of USDJPY
 * Drag and drop Strategy1USDJPY in *Navigator - Expert Advisors* on the chart
 * Setting dialog will open, configure as below

        ```
        Common tab
            Common
                Long & Short positions
                v Enable alerts
                    _ Disable alert once hit
            Live Trading
                v Allow live trading
                    _ Ask manual confirmation
            Safety
                _ Allow DLL imports
                    _ Confirm DLL function calls
                v Allow import of external experts
        Inputs tab
            Do not modified.
        ```

 * Push OK button
 * Press Expert Advisors button on tool bar, green play mark will shown
4. Check behavior
 * `Strategy1USDJPY :)` will shown on top right corner of the chart
