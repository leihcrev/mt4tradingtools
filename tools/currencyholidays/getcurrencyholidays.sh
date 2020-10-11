#!/bin/sh
curl -b cookie.dat -c cookie.dat -L --data 'TadiServer=TPASS&TadiUrl=%2Ftestdx%2Fcurr_hols.call&in_CUR_CODE='$1'&in_holiday_year='$2'&in_output_fmt=CSV' 'https://dxtra.markets.reuters.com/dx/dxnrequest.aspx?RequestName=TadiPost'
rm cookie.dat
