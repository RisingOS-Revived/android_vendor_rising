#!/bin/bash

function fetch_list() {
  curl --silent "$2" | sed -E "$3; /^#/d; /^$/d; /([[:space:]])?localhost/d; /([[:space:]])?local$/d" > "$1"
}

SRC="$(pwd)"

fetch_list "$SRC"/adaway.list "https://adaway.org/hosts.txt" "s/127\.0\.0\.1/0\.0\.0\.0/g"
fetch_list "$SRC"/adguard.list "https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt"
fetch_list "$SRC"/black.list "https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts"
fetch_list "$SRC"/easylist.list "https://v.firebog.net/hosts/Easylist.txt" "/^$/d; s/^([^#]*)$/0\.0\.0\.0 \1/g"
fetch_list "$SRC"/easyprivacy.list "https://v.firebog.net/hosts/Easyprivacy.txt" "/^$/d; s/^([^#]*)$/0\.0\.0\.0 \1/g"
fetch_list "$SRC"/kad.list "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
fetch_list "$SRC"/someone.list "https://someonewhocares.org/hosts/zero/hosts" "/^255\.255\.255\.255/d; /^f/d; /^::1/d; /^[[:space:]]*#/d"
fetch_list "$SRC"/urlhaus.list "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts.txt"
fetch_list "$SRC"/yoyo.list "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts;showintro=0&mimetype=plaintext" "s/127\.0\.0\.1/0\.0\.0\.0/g"

cat "$SRC"/*.list | sort | uniq > "$SRC"/hosts.adblock.in
rm "$SRC"/*.list
