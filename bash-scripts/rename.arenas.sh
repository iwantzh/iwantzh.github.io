####################################
# arguments:
key=$1
dir_with_jsons=$2

####################################
# schedule related variables:
. ./schedule.init.sh


####################################
# renaming:
prevTournamentId="z"
idx=$((numoftour-1))
prevTC="z"

for filename in `ls ./$dir_with_jsons/*.json | sort -gr`; do 
    echo "-- $filename -----------------------------------------------------------------"; 
    tournamentId=$(eval cat ${filename} | jq -r .id); 
    echo $tournamentId
    description="Full list of existing tournaments: [https://iwantzh.github.io/list.html](https://iwantzh.github.io/list.html)%0A%0AAlways one 24/7"
    if [ "$prevTournamentId" == 'z' ]
    then
        description="Full list of existing tournaments: [https://iwantzh.github.io/list.html](https://iwantzh.github.io/list.html)%0A-------------------------------------------%0AThere is always one. Anytime. 24/7%0A-------------------------------------------"
    else
        description="Full list of existing tournaments: [https://iwantzh.github.io/list.html](https://iwantzh.github.io/list.html)%0A-------------------------------------------%0A[Next+UZH+Arena:+$prevTC](https://lichess.org/tournament/$prevTournamentId)%0A-------------------------------------------"
    fi
    #echo $description

	actualCmd="curl -s -X POST -H \"Authorization: Bearer $key\" -d 'variant=crazyhouse&clockTime=${clockTime[idx]}&clockIncrement=${clockIncr[idx]}&minutes=${durminute[idx]}&description=$description' https://lichess.org/api/tournament/$tournamentId"

	echo "$actualCmd"

	#########################################################
	#update tournament description - get json response

	responseJson=$(eval $actualCmd)

	echo $'\e[1;33m'$responseJson$'\e[0m'


    prevTournamentId=$tournamentId
    prevTC="${clockTime[idx]}%2b${clockIncr[idx]}"
    idx=$((idx-1))
done

