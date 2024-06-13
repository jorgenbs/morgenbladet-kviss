#!/bin/bash

ARCHIVE_FILE="./archive.json"
FEEDSIZE=1

# {"_id":"","content_alias":"pafyll","feature":"top-table-list","from":0,"size":1}
QUERY="%7B%22_id%22%3A%22%22%2C%22content_alias%22%3A%22pafyll%22%2C%22feature%22%3A%22top-table-list%22%2C%22from%22%3A0%2C%22size%22%3A1%7D"
# {content_elements{_id,content_restrictions{content_code},display_date,embed_html,headlines{basic,original,print,web},subtype,type,websites{morgenbladet{website_section{_id,name},website_url}}}}
FILTER="%7Bcontent_elements%7B_id%2Ccontent_restrictions%7Bcontent_code%7D%2Cdisplay_date%2Cembed_html%2Cheadlines%7Bbasic%2Coriginal%2Cprint%2Cweb%7D%2Csubtype%2Ctype%2Cwebsites%7Bmorgenbladet%7Bwebsite_section%7B_id%2Cname%7D%2Cwebsite_url%7D%7D%7D%7D"
API_CALL="https://www.morgenbladet.no/pf/api/v3/content/fetch/mentor-api-collections?query=${QUERY}&filter=${FILTER}&_website=morgenbladet"

DATA=$(curl $API_CALL | jq ".content_elements[0]")

ID=$(echo $DATA | jq -r "._id")
NAME=$(echo $DATA | jq -r ".headlines.basic")

# if id not in archive its a new quiz
if ! jq --arg id "$ID" -e '.[] | select(._id == $id)' $ARCHIVE_FILE > /dev/null; then
    # Dumb and simple: Use curl quiz slug from response (its not behind paywall)
    ARTICLE_URL=https://www.morgenbladet.no$(echo $DATA | jq -r ".websites.morgenbladet.website_url")
    echo $ARTICLE_URL
    SLUG=$(curl $ARTICLE_URL | sed -n 's/.*kviss\.morgenbladet\.no\/\([^"]*\)".*/\1/p' | sed 's/\\//g')

    # # Update archive
    TEMP_FILE=$(mktemp)
    jq --argjson slug "{\"quiz_slug\": \"$SLUG\"}" --argjson new "$DATA" '[$new + $slug] + .' $ARCHIVE_FILE > $TEMP_FILE && mv $TEMP_FILE $ARCHIVE_FILE

    # Use slug to forward to the quiz webapp (which is also open)
    echo "window.location = 'https://kviss.morgenbladet.no/${SLUG}'" > docs/kviss.js

    # Push message
    message="Ny kviss: $NAME"
    curl \
        -H "Click: https://jorgenbs.github.io/morgenbladet-kviss/" \
        -d "$message" https://ntfy.sh/mbkviss

    echo $SLUG
else
    exit 1
fi
