#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 7m +%s)" ]] && seasonYear="$(($(date +%Y) + 1))" || seasonYear="$(date +%Y)"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./scripts/reload.sh)

# Get season files
standings_file="${seasonDir}/standings.json"
icons_dir="${seasonDir}/icons"

# Load Standings
jq -cs \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
   --slurpfile nocDict "nocDict.json" \
'{
    "variables": {
        "seasonYear": "'${seasonYear}'",
        "standings_file": "'${standings_file}'",
        "seasonDir": "'${seasonDir}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[][].items | map({
			"title": "\(.rank)  \(if (.rankTrend == "UP") then "↑" elif (.rankTrend == "DOWN") then "↓" else "↔" end)  \(.team.translations.displayName.EN)  \($nocDict[].emoji."\(.team.countryCode)")",
			"subtitle": "Pl: \(.played)    [ W: \(.won)  D: \(.drawn)  L: \(.lost) ]    [ GF: \(.goalsFor)  GA: \(.goalsAgainst)  GD: \(.goalDifference | (if . > 0 then "+\(.)" else . end)) ]    Pts: \(.points)",
			"match": [
                .rank, .team.translations.displayName.EN, .team.translations.countryName.EN,
                (if (.qualified) then "qualified" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.team.id).png" },
			"text": { "copy": .team.translations.displayName.EN },
			"variables": { "teamId": .team.id, "teamName": .team.translations.displayName.EN, "country": "\($nocDict[].emoji."\(.team.countryCode)") \(.team.countryCode)", "seq": .rank }
		}) | [(.[] | select((.variables.seq != 1) and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"