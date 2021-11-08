#!/bin/bash

#Epoch timestamp: 1636329600
#Timestamp in milliseconds: 1636329600000
#Date and time (GMT): Monday, November 8, 2021 0:00:00 
nov08_midnight=1636329600000

# The week that starts on nov08, will have the elite tournament on Saturday, 13th Nov. Meaning next one will be Fridat, and so on alternating
# In other words, on even weeks counting since nov8 we have Saturdays, and on odd weeks - Fridays

####################################
#some consts:
min=1000*60
hour=1000*60*60
day=24*hour
week=7*day

batch_size=$1 #how many future dates for elite tournaments to generate

now=$(date +%s) #now in seconds epoch format
now=$((now * 1000)) # now in ms

echo "now= $now"
echo "nov08_midnight= $nov08_midnight"

next_week_start=$nov08_midnight
week_num_since_nov8=0

while [[ $now -gt next_week_start ]]; do
	next_week_start=$((next_week_start+week))
	week_num_since_nov8=$((week_num_since_nov8+1))
done

echo "next_week_start= $next_week_start"
echo "week_num_since_nov8= $week_num_since_nov8"


future_elite_days=()

for x in $( seq 0 $((batch_size-1)) )
do
	odd_even=$(((week_num_since_nov8+x)%2))
	next_elite_day=$((next_week_start + week*x + 5*day - odd_even*day + 19*hour)) # todo daylight saving? currently we switched to winter time and suddenly new arenas are at 22 instead of 21 sofia time. for now setting to 21 sofia time (19 gmt) but not sure what is desired time and of course this is ot gonna work when we switch again to summer time
    future_elite_days+=($next_elite_day)
done

printf "array size is %d\n" "${#future_elite_days[@]}"

for x in $( seq 0 $((${#future_elite_days[@]}-1)) )
do
    ts_in_sec=$((${future_elite_days[x]}/1000))
    echo $(date -d @$ts_in_sec)
done

echo end
