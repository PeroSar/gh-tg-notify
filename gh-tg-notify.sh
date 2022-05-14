#!/usr/bin/env bash

# TG functions
tg_msg() {
	curl -o /dev/null -sX POST "$TG_API_BASE"/sendMessage \
		-d "parse_mode=markdown" \
		-d "chat_id=$TG_CHATID" \
		-d "text=$1" \
		-d "reply_markup=$2"
}

tg_create_inlinekb_url() {
	printf '{"inline_keyboard": [[{"text":"%s", "url": "%s"}]]}' "$1" "$2"
}

# JSON data we recieved from github
GITHUB_JSON=$(</dev/stdin)

# Read secrets from .env
DOTENV=$(dirname "$(realpath "$0")")/.env
[ -f "$DOTENV" ] && source "$DOTENV"

if [ -z "$TG_TOKEN" ] || [ -z "$TG_CHATID" ]; then
	echo "\$TG_TOKEN or \$TG_CHATID not found in env"
	exit 1
fi

TG_API_BASE="https://api.telegram.org/bot$TG_TOKEN"

# Set repository name
GH_REPO=$(jq -r .repository.full_name <<<"$GITHUB_JSON")

# Parse and notify
readarray -t COMMITS < <(jq -c '.commits[]' <<<"$GITHUB_JSON")

for COMMIT in "${COMMITS[@]}"; do
	COMMIT_AUTHOR=$(jq -r '.author.username' <<<"$COMMIT")
	COMMIT_ID=$(jq -r '.id' <<<"$COMMIT")
	COMMIT_URL=$(jq -r '.url' <<<"$COMMIT")
	COMMIT_MSG=$(jq -r '.message' <<<"$COMMIT")
	tg_msg "*New commit by $COMMIT_AUTHOR in $GH_REPO!* \[\`${COMMIT_ID:0:7}\`]

$COMMIT_MSG" "$(tg_create_inlinekb_url "View on GitHub" "$COMMIT_URL")"
done
