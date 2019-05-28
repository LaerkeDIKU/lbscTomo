#!/bin/bash

# Usage: slackpost "<webhook_url>" "<message>"

# ------------
webhook_url=$1
if [[ $webhook_url == "" ]]
then
        echo "No webhook_url specified"
        exit 1
fi

# ------------
shift

text=$*

if [[ $text == "" ]]
then
        echo "No text specified"
        exit 1
fi

#escapedText=$(echo $text | sed 's/"/\"/g' | sed "s/'/\'/g" )

json="{\"channel\": \"$channel\", \"icon_emoji\":\"ghost\", \"attachments\":[{\"color\":\"danger\" , \"text\": \"$*\"}]}"

curl -s -d "payload=$json" "$webhook_url"
