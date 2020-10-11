#!/bin/sh
for ccy in `cat currencies.txt`; do
	echo $ccy
	for year in `cat years.txt`; do
		echo $year
		./getcurrencyholidays.sh $ccy $year >$ccy-$year.csv
		sleep 1
	done
done
