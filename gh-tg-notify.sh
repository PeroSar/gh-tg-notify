#!/usr/bin/env bash

# Get chatID
CID=${QUERY_STRING#*chat=}
CID=${CID%%&*}
CID=${CID//+/}

if [ -z "$CID" ]; then
	echo "ChatID not found in URL"
	exit 1
fi

# TG functions
tg_msg() {
	curl -o /dev/null -sX POST "$TG_API_BASE"/sendMessage \
		-d "parse_mode=markdown" \
		-d "chat_id=$CID" \
		-d "text=$1" \
		-d "reply_markup=$2"
}

tg_create_inlinekb_url() {
	printf '{"inline_keyboard": [[{"text":"%s", "url": "%s"}]]}' "$1" "$2"
}

# JSON data we recieved from github
GITHUB_JSON=$(</dev/stdin)

# Read secrets from .env
SRCDIR=$(dirname "$(realpath "$0")")
[ -f "$SRCDIR"/.env ] && source "$SRCDIR"/.env

if [ -z "$TG_TOKEN" ]; then
	echo "\$TG_TOKEN not found in env"
	exit 1
fi

TG_API_BASE="https://api.telegram.org/bot$TG_TOKEN"

# Set {repository,branch} name
GH_REPO=$(jq -r '.repository.full_name' <<<"$GITHUB_JSON")
GH_BRANCH=$(jq -r '.ref' <<<"$GITHUB_JSON")
GH_BRANCH=${GH_BRANCH#refs/heads/}

# Set limit for number of messages at one time
GH_COMMIT_LIMIT=8

# Parse and notify
readarray -t COMMITS < <(jq -c '.commits[]' <<<"$GITHUB_JSON")

# Anything more than the limit will be removed out
COMMITS=("${COMMITS[@]:0:$GH_COMMIT_LIMIT}")

for COMMIT in "${COMMITS[@]}"; do
	COMMIT_AUTHOR=$(jq -r '.author.username' <<<"$COMMIT")
	COMMIT_ID=$(jq -r '.id' <<<"$COMMIT")
	COMMIT_URL=$(jq -r '.url' <<<"$COMMIT")
	COMMIT_MSG=$(jq -r '.message' <<<"$COMMIT")
	COMMIT_MSG=${COMMIT_MSG/&/AND}
	COMMIT_MSG=$(python3 "$SRCDIR"/md-escape.py "$COMMIT_MSG")

	tg_msg "*New commit by $COMMIT_AUTHOR in $GH_REPO!* \[$GH_BRANCH \`${COMMIT_ID:0:7}\`]

$COMMIT_MSG" "$(tg_create_inlinekb_url "View on GitHub" "$COMMIT_URL")"
done
