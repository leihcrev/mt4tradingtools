#!/bin/sh
if [ $# -eq 2 ]; then
	years=`seq $1 $2`
elif [ $# -eq 1 ]; then
	years=$1
else
	years=`cat years.txt`
fi
for ccy in `cat currencies.txt`; do
	echo $ccy
	for year in $years; do
		echo $year
		./getcurrencyholidays.sh $ccy $year >$ccy-$year.csv
		sleep 1
	done
done
