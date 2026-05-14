#!/bin/zsh --no-rcs

# Get age of standings_file in minutes
[[ -f "${standings_file}" ]] && minutes="$((($(date +%s)-$(date -r "${standings_file}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    [[ "${minutes}" -gt 0 || -z "${minutes}" ]] && reload=$(./scripts/reload.sh) && minutes=0
fi

# Format Last Updated Time
if [[ ! -f "${standings_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${standings_file}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
if [[ -f "${standings_file}" ]]; then
    mdOutput=$(jq -crs --arg teamId "${teamId}" --arg country "${country}" --arg icons_dir "${icons_dir}" \
    '(.[0][0].items[] | select(.team.id == $teamId)) as $standings |
    ([.[1,2][] | select(.teamId == $teamId).statistics] | add | from_entries |
    40 as $spaces |
        "![Team Logo](\($icons_dir)/\($teamId)small.png)\n",
        "# "+$standings.team.translations.displayOfficialName.EN,
        $country,
        "\n**Matches Played:** \($standings.played)      ·      **Won:** \($standings.won)   ·   **Drawn:** \($standings.drawn)   ·   **Lost:** \($standings.lost)",
        "\n***\n\n### Goals\n\n```",
        ("Goals:"|.+" "*($spaces-length))+(.goals),
        ("Right foot:"|.+" "*($spaces-length))+(.goals_scored_with_right),
        ("Left foot:"|.+" "*($spaces-length))+(.goals_scored_with_left),
        ("Head:"|.+" "*($spaces-length))+(.goals_scored_head),
        ("Other:"|.+" "*($spaces-length))+(.goals_scored_other),
        ("Goals inside area:"|.+" "*($spaces-length))+(.goals_scored_inside_penalty_area),
        ("Goals outside area:"|.+" "*($spaces-length))+(.goals_scored_outside_penalty_area),
        ("Penalties scored:"|.+" "*($spaces-length))+(.penalty_scored),
        "```\n\n### Attempts\n\n```",
        ("Total attempts:"|.+" "*($spaces-length))+(.attempts),
        ("Attempts on target:"|.+" "*($spaces-length))+(.attempts_on_target),
        ("Attempts off target:"|.+" "*($spaces-length))+(.attempts_off_target),
        ("Attempts blocked:"|.+" "*($spaces-length))+(.attempts_blocked),
        "```\n\n### Distribution\n\n```",
        ("Passing accuracy (%):"|.+" "*($spaces-length))+(.passes_accuracy),
        ("Passes attempted:"|.+" "*($spaces-length))+(.passes_attempted),
        ("Passes completed:"|.+" "*($spaces-length))+(.passes_completed),
        ("Possession (%):"|.+" "*($spaces-length))+(.ball_possession),
        ("Crossing accuracy (%):"|.+" "*($spaces-length))+(.cross_accuracy),
        ("Crosses attempted:"|.+" "*($spaces-length))+(.cross_attempted),
        ("Crosses completed:"|.+" "*($spaces-length))+(.cross_completed),
        ("Free-kicks taken:"|.+" "*($spaces-length))+(.free_kick),
        "```\n\n### Attacking\n\n```",
        ("Attacks:"|.+" "*($spaces-length))+(.attacks),
        ("Assists:"|.+" "*($spaces-length))+(.assists),
        ("Corners taken:"|.+" "*($spaces-length))+(.corners),
        ("Offsides:"|.+" "*($spaces-length))+(.offsides),
        ("Dribbles:"|.+" "*($spaces-length))+(.dribbling),
        "```\n\n### Defending\n\n```",
        ("Balls recovered:"|.+" "*($spaces-length))+(.recovered_ball),
        ("Tackles:"|.+" "*($spaces-length))+(.tackles),
        ("Tackles won:"|.+" "*($spaces-length))+(.tackles_won),
        ("Tackles lost:"|.+" "*($spaces-length))+(.tackles_lost),
        ("Clearances attempted:"|.+" "*($spaces-length))+(.clearance_attempted),
        "```\n\n### Goalkeeping\n\n```",
        ("Saves:"|.+" "*($spaces-length))+(.saves),
        ("Goals conceded:"|.+" "*($spaces-length))+(.goals_conceded),
        ("Own goals conceded:"|.+" "*($spaces-length))+(.own_goal_conceded),
        ("Saves from penalties:"|.+" "*($spaces-length))+(.saves_on_penalty),
        ("Clean sheets:"|.+" "*($spaces-length))+(.clean_sheet),
        ("Punches made:"|.+" "*($spaces-length))+(.punches),
        "```\n\n### Disciplinary\n\n```",
        ("Fouls committed:"|.+" "*($spaces-length))+(.fouls_committed),
        ("Fouls suffered:"|.+" "*($spaces-length))+(.fouls_suffered),
        ("Yellow cards:"|.+" "*($spaces-length))+(.yellow_cards),
        ("Red cards:"|.+" "*($spaces-length))+(.red_cards),
        "```"
    )' "${standings_file}" "${seasonDir}"/stats*.json | sed 's/\"/\\"/g')
else
    mdOutput='![Team Logo]('${icons_dir}'/'${teamId}'small.png)\n# '${teamName}'\n\n**Games Played:** N/A      ·      **Goals:** N/A      ·      **Goals Conceded:** N/A\n***\n*No Team Stats available*'
fi

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now   ·   ⌘↩ Open in Browser"
}
EOB