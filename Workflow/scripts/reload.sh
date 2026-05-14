#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 7m +%s)" ]] && seasonYear="$(($(date +%Y) + 1))" || seasonYear="$(date +%Y)"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Get season standings
mkdir -p "${seasonDir}"
curl -sf --compressed --parallel --connect-timeout 10 \
    -L "https://standings.uefa.com/v1/standings?competitionId=1&seasonYear=${seasonYear}" -o "${seasonDir}/standings.json" \
    -L "https://compstats.uefa.com/v1/team-ranking?competitionId=1&limit=50&offset=0&seasonYear=${seasonYear}&stats=goals%2Cgoals_scored_with_right%2Cgoals_scored_with_left%2Cgoals_scored_head%2Cgoals_scored_other%2Cgoals_scored_inside_penalty_area%2Cgoals_scored_outside_penalty_area%2Cpenalty_scored%2Cattempts%2Cattempts_on_target%2Cattempts_off_target%2Cattempts_blocked%2Cpasses_accuracy%2Cpasses_attempted%2Cpasses_completed%2Cball_possession%2Ccross_accuracy%2Ccross_attempted%2Ccross_completed%2Cfree_kick%2Cattacks%2Cassists%2Ccorners%2Coffsides%2Cdribbling%2Crecovered_ball%2Ctackles%2Ctackles_won%2Ctackles_lost%2Cclearance_attempted" -o "${seasonDir}/stats1.json" \
    -L "https://compstats.uefa.com/v1/team-ranking?competitionId=1&limit=50&offset=0&seasonYear=${seasonYear}&stats=saves%2Cgoals_conceded%2Cown_goal_conceded%2Csaves_on_penalty%2Cclean_sheet%2Cpunches%2Cfouls_committed%2Cfouls_suffered%2Cyellow_cards%2Cred_cards" -o "${seasonDir}/stats2.json" \
&& downloadStatus=1

if [[ -n "${downloadStatus}" ]]; then
    set -o extendedglob
    if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamLogos=($(jq -r '.[].items[].team.mediumLogoUrl' "${seasonDir}/standings.json"))
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" --remote-name-all -L "${teamLogos[@]}"
    fi
    touch "${alfred_workflow_data}"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi