####################################
#some consts:
min=1000*60
hour=1000*60*60
day=24*hour
NEWLINE=$'\n'
#SERVER_DOMAIN="lichess.org"
SERVER_DOMAIN="localhost:9663"
PROTOCOL="http"

#Epoch timestamp: 1621641600
#Timestamp in milliseconds: 1621641600000
#Date and time (GMT): Saturday, May 22, 2021 0:00:00 
may22_midnight=1621641600000


####################################
# schedule related variables:
. ./schedule.init.sh

####################################
# arguments:
apikey1=$1 
apikey2=$2 #needed only if user is limited to 12 tournaments per day and we want to use 2 alts instead. 

iter=$3 # meaning days after May 22 2021. The script is supposed to be ran every day. Just increment this param for each daily execution to determine the date+times of the tournaments based on it
#12


####################################
# init:
startDate=$((may22_midnight + day*iter)) #That would be 00:00 of the day of interest, realtive to which all hours from the table above will be an offset
output_dirname="./json_responses/iter_$iter"
mkdir -p $output_dirname

####################################
# create the tournaments:
for x in $( seq 0 $((numoftour-1)) )
do
	echo "============================================================"
	echo "= $x  ======================================================"

	ts=$(( startDate+(starthour[x]*hour)+startmins[x]*min ))

	echo "$ts ${durminute[x]} ${clockTime[x]} ${clockIncr[x]}"
	
	# which key to use to avoid the 12 per user limit:
	key=$apikey1
	if [ $x -gt 8 ]
	then
		key=$apikey2
	fi

	url="$PROTOCOL://$SERVER_DOMAIN/api/tournament";
	
	actualCmd="curl -s -X POST -H \"Authorization: Bearer $key\" -d 'name=Underground+ZH+Hourly&conditions.teamMember.teamId=underground-crazyhouse-hourly-arenas&clockTime=${clockTime[x]}&clockIncrement=${clockIncr[x]}&minutes=${durminute[x]}&startDate=$ts&variant=crazyhouse&description=[https://iwantzh.github.io/](https://iwantzh.github.io/)+redirects+you+to+the+currently+running+ZH+arena.+There+is+always+one+24/7%0A%0AList+of+all+ZH+tournaments:+[https://iwantzh.github.io/list.html](https://iwantzh.github.io/list.html)' $url"

	echo "$actualCmd"

	#########################################################
	#create tournaments - get json response

	responseJson=$(eval $actualCmd)

	echo $'\e[1;33m'$responseJson$'\e[0m'

	echo $responseJson > "$output_dirname/$ts.json"


done

