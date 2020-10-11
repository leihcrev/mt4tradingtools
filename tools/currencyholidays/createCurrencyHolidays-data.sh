#!/bin/sh
for ccy in `cat currencies.txt`; do
	echo "\"$ccy\", {"
	for year in `cat years.txt`; do
		filename=$ccy-$year.csv
		if [ -f $filename ]; then
			while read line; do
				IFS=, read yy mm dd nm <<<"$line"
				if [ "$yy" = $year ]; then
					mm=`case $mm in
						"JAN") echo 01 ;;
						"FEB") echo 02 ;;
						"MAR") echo 03 ;;
						"APR") echo 04 ;;
						"MAY") echo 05 ;;
						"JUN") echo 06 ;;
						"JUL") echo 07 ;;
						"AUG") echo 08 ;;
						"SEP") echo 09 ;;
						"OCT") echo 10 ;;
						"NOV") echo 11 ;;
						"DEC") echo 12 ;;
					esac`
					nm=`echo "$nm" |sed -e 's/"//g'`
					echo "{D'$yy.$mm.$dd',\"$nm\"},"
				fi
			done <$filename
		fi
	done
	echo "},"
done
