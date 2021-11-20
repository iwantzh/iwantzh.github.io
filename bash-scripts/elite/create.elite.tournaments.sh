SERVER_DOMAIN="lichess.org"
PROTOCOL="https"
#SERVER_DOMAIN="localhost:9663"
#PROTOCOL="http"

url="$PROTOCOL://$SERVER_DOMAIN/api/tournament";

key=$1 

####################################
# schedule related variables: future_elite_days, week_num_since_nov8
. ./schedule.elite.init.sh 10

output_dirname="./json_responses/"
mkdir -p $output_dirname

for x in $( seq 0 $((${#future_elite_days[@]}-1)) )
do
    

    ts=${future_elite_days[x]}

	odd_even=$(((week_num_since_nov8+x)%2))

	if [[ odd_even -eq 0 ]]; then
	    clockTime=3
	    clockIncr=0
	else 
	    clockTime=1
	    clockIncr=2
	fi

    durminute=120
    description="Good luck! Have fun! Join [Crazyhouse Curator](https://lichess.org/team/crazyhouse-curator) to keep posted on Elite ZH Arenas.%0A%0AUpcoming Elite Arenas:%0ATBA0A0AOther links:[Forum thread](https://lichess.org/forum/team-crazyhouse-world-championship/elite-crazyhouse-arena-3)%0A[Crazyhouse calendar](https://teamup.com/ks3ozaeaopfk1v98bf?view=agenda)"

	actualCmd="curl -s -X POST -H \"Authorization: Bearer $key\" -d 'name=Elite+Crazyhouse+Arena&clockTime=$clockTime&clockIncrement=$clockIncr&minutes=$durminute&startDate=$ts&variant=crazyhouse&description=$description' $url"

	echo "$actualCmd"

	#########################################################
	#create tournaments - get json response

	responseJson=$(eval $actualCmd)

	echo $'\e[1;33m'$responseJson$'\e[0m'

	echo $responseJson > "$output_dirname/iter_$((week_num_since_nov8+x))_$ts.json"

done
