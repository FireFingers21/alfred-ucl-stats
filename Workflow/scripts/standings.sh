#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 7m +%s)" ]] && seasonYear="$(($(date +%Y) + 1))" || seasonYear="$(date +%Y)"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${seasonDir}" ]] && reload=$(./scripts/reload.sh)

# Load Standings
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg icons_dir "${seasonDir}/icons" \
   --arg seasonYear "${seasonYear}" \
   --slurpfile nocDict "nocDict.json" \
'{
    "variables": {
        "keyword": $alfred_workflow_keyword,
        "icons_dir": $icons_dir,
        "seasonYear": $seasonYear
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		if (isempty(.[][]) | not) then .[][].items | map(((.team.translations.displayName.EN|ascii_downcase) == $favTeam) as $isFavourite | {
			"title": "\(.rank)  \(if (.rankTrend == "UP") then "↑" elif (.rankTrend == "DOWN") then "↓" else "↔" end)  \(.team.translations.displayName.EN)  \($nocDict[].emoji."\(.team.countryCode)")  \(if ((.team.translations.displayName.EN|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "Pl: \(.played)    [ W: \(.won)  D: \(.drawn)  L: \(.lost) ]    [ GF: \(.goalsFor)  GA: \(.goalsAgainst)  GD: \(.goalDifference | (if . > 0 then "+\(.)" else . end)) ]    Pts: \(.points)",
			"match": [
                .rank, (.team.translations | .displayName, .displayOfficialName, .countryName | .EN),
                (if (.qualified) then "qualified" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.team.id).png" },
			"text": { "copy": .team.translations.displayName.EN },
			"variables": { "favTeamNew": .team.translations.displayName.EN, "teamId": .team.id, "teamName": .team.translations.displayName.EN, "teamNameOfficial": .team.translations.displayOfficialName.EN, "country": "\($nocDict[].emoji."\(.team.countryCode)") \(.team.countryCode)", "seq": .rank },
			"mods": {
			    "cmd+shift": {"subtitle": "⇧⌘↩ \(if ($isFavourite) then "Unset" else "Set" end) Favourite Team"}
			}
		}) | [(.[] | select((.variables.seq != 1) and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		else
			[{
				"title": "No Data Available",
				"valid": false,
				"mods": {"cmd":{ "subtitle":"", "valid":false }}
			}]
		end
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"