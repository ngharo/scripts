#!/bin/bash
# used to prefix tarsnaps and email reports
tag="ngha.ro"

tarsnap=/usr/local/bin/tarsnap
sites=(ngha.ro example.com example.org)
dirs=(
    /etc/
    /root
    /var/www
)
log=$(mktemp)
mail_to="foo@example.com"
mail_subject="[${tag}] Backup results"

sql_dump() {
    local site="$1"
    local db="${site%.*}"
    local dump="/var/www/${site}/${db}.sql"

    printf "Dumping MySQL database '%s' to %s ... " "$db" "$dump"
    mysqldump -R -u USER -pPASSWORD "$db" > "$dump"
    ret_code=$?
    chown root:root "$dump"
    chmod 0600 "$dump"

    result="OK"
        [[ $req_code -eq 0 ]] || result="FAIL"
    printf "%s\n" "$result"

    return $ret_code
}

for site in "${sites[@]}"; do
    sql_dump $site >> "$log" 2>&1 || mail_subject="${mail_subject} [SQL FAILURES]"
done

$tarsnap -c -f "${tag}-$(date +%d%m%y_%H:%M)" "${dirs[@]}" 2>&1 \
    | tee -a "$log" | logger -t backup

[[ ${PIPESTATUS[0]} -eq 0 ]] || mail_subject="${mail_subject} [TARSNAP FAILURES]"
mail -s "$mail_subject" "$mail_to" < "$log"

rm "$log"
