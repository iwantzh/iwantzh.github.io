#SERVER_DOMAIN="lichess.org"
SERVER_DOMAIN="localhost:9663"
PROTOCOL="http"

export TZ='UTC'

url="$PROTOCOL://$SERVER_DOMAIN/api/tournament";

key=$1 

####################################
# schedule related variables: future_elite_days, week_num_since_nov8
. ./schedule.elite.init.sh 10

output_dirname="./json_responses/"
mkdir -p $output_dirname

newlyCreatedTournaments=()

for x in $( seq 0 $((${#future_elite_days[@]}-1)) )
do
    

    ts=${future_elite_days[x]}

    filename="$output_dirname/iter_$((week_num_since_nov8+x))_$ts.json"

    tournamentId=$(eval cat ${filename} | jq -r .id); 
    echo $tournamentId

    newlyCreatedTournaments[x]=$tournamentId

done


for x in $( seq 0 $((${#future_elite_days[@]}-1)) )
do
	odd_even=$(((week_num_since_nov8+x)%2))
    ts=${future_elite_days[x]}
    tournamentId=${newlyCreatedTournaments[x]}

	if [[ odd_even -eq 0 ]]; then
	    clockTime=3
	    clockIncr=0
	else 
	    clockTime=1
	    clockIncr=2
	fi

    durminute=120

    description="Good luck! Have fun! Join [Crazyhouse Curator](https://lichess.org/team/crazyhouse-curator) to keep posted on Elite ZH Arenas.%0A%0AUpcoming Elite Arenas:"

	if [[ x -eq $((${#future_elite_days[@]}-1)) ]]; then
    	description="$description%0ATBA"
    else 
	    for y in $( seq $((x+1)) $((${#future_elite_days[@]}-1)) )
	    do
		    tsSec=$((future_elite_days[y]/1000))
	    	tournamentTimeLabel=$(eval date -d @${tsSec} +\'%A, %b %d, %H:%M UTC\')
	    	description="$description %0A[$tournamentTimeLabel](https://lichess.org/tournament/${newlyCreatedTournaments[y]})"
	    done
	fi

    description="$description%0A%0AOther links:%0A[Forum thread](https://lichess.org/forum/team-crazyhouse-world-championship/elite-crazyhouse-arena-3)%0A[Crazyhouse calendar](https://teamup.com/ks3ozaeaopfk1v98bf?view%3Dagenda)"

	actualCmd="curl -s -X POST -H \"Authorization: Bearer $key\" -d 'variant=crazyhouse&clockTime=$clockTime&clockIncrement=$clockIncr&minutes=$durminute&description=$description' $url/$tournamentId"

	echo "$actualCmd"

	#########################################################
	#create tournaments - get json response

	responseJson=$(eval $actualCmd)

	echo $'\e[1;33m'$responseJson$'\e[0m'
done
