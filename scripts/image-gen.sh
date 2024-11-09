if [ $# -eq 0 ]; then
  echo "Available slugs:"
  sqlite3 ./kviss-db/db.sqlite "SELECT DISTINCT slug FROM quiz_entry ORDER BY id DESC LIMIT 20" | while read -r slug; do
    echo "- $slug"
  done
  read -p "Please enter a slug from the above list: " SLUG
else
  SLUG=$1
fi

DB=$(sqlite3 ./kviss-db/db.sqlite "SELECT 'question: ' || question || ' answer: ' || answer FROM quiz_entry WHERE slug='$SLUG'")
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @- <<EOF
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are an image generation expert that makes generation prompts for Dall-E. Given a question and answer group you generate a short prompt for the image generation model for a thematic image."
    },
    {
      "role": "user",
      "content": "focus on the question, but sprinkle some of the answers in the prompt (not literally): $DB"
    }
  ]
}
EOF
)
PROMPT=$(echo $RESPONSE | jq -r '.choices[0].message.content' | jq -sRr @json)
IMAGE_RESPONSE=$(jq -n --arg model "dall-e-3" --arg prompt "$PROMPT" --argjson n 1 --arg size "1024x1024" \
'{
  model: $model,
  prompt: $prompt,
  n: $n,
  size: $size
}' | curl -s https://api.openai.com/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @-)

IMAGE_URL=$(echo $IMAGE_RESPONSE | jq -r '.data[0].url')
if [ "$IMAGE_URL" = "null" ]; then
  echo "Failed to generate image. Please check the prompt and try again."
  echo $IMAGE_RESPONSE
  exit 1
else
  DATE=$(date +%Y-%m-%d)
  NEW_IMAGE=docs/generated_$DATE.png
  curl $IMAGE_URL -o $NEW_IMAGE
  cp $NEW_IMAGE docs/generated.png
fi
