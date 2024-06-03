#!/bin/bash

DUMP_FILE="dump.json"
QUERY='https://www.morgenbladet.no/pf/api/v3/content/fetch/story-feed-sections?query=%7B%22feature%22%3A%22results-list%22%2C%22feedOffset%22%3A0%2C%22feedSize%22%3A1%2C%22includeSections%22%3A%22%2Fpafyll%2Fkviss%22%7D&filter=%7Bcontent_elements%7B_id%2Ccredits%7Bby%7B_id%2Cadditional_properties%7Boriginal%7Bbyline%7D%7D%2Cname%2Ctype%2Curl%7D%7D%2Cdescription%7Bbasic%7D%2Cdisplay_date%2Cheadlines%7Bbasic%7D%2Clabel%7Bbasic%7Bdisplay%2Ctext%2Curl%7D%7D%2Cowner%7Bsponsored%7D%2Cpromo_items%7Bbasic%7Bresized_params%7B158x89%2C274x154%7D%2Ctype%2Curl%7D%2Clead_art%7Bpromo_items%7Bbasic%7Bresized_params%7B158x89%2C274x154%7D%2Ctype%2Curl%7D%7D%2Ctype%7D%7D%2Ctype%2Cwebsites%7Bmorgenbladet%7Bwebsite_section%7B_id%2Cname%7D%2Cwebsite_url%7D%7D%7D%2Ccount%2Cnext%7D&d=331&_website=morgenbladet'
DATA=$(curl $QUERY | jq ".content_elements[0]")
ID=$(echo $DATA | jq -r "._id")


if ! jq --arg id "$ID" -e '.content_elements[] | select(._id == $id)' $DUMP_FILE > /dev/null; then
    echo "New element found: $ID"
    echo $DATA
    # Prepend the new element
    TEMP_FILE=$(mktemp)
    jq --argjson new "$DATA" '[$new] + .content_elements' $DUMP_FILE > $TEMP_FILE && mv $TEMP_FILE $DUMP_FILE
    # jq --argjson newElement "$DATA" '[$newElement] + .' "$DUMP_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DUMP_FILE"

else
    echo "No new elements found"
fi
