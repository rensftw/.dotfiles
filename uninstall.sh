#!/bin/zsh

RED='\033[1;31m'
NC='\033[0m' # No color

echo "${RED}This action is irreversible. Are you sure you want to proceed? (y/n)${NC}"


read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    echo "YAY, answer was: $ANSWER"
elif [[ "$ANSWER" == "n" || "$ANSWER" == "no" ]]; then
    echo "Oh noes! answer  was negative?! $ANSWER"
else
    echo "Please type y(es) or n(o)"
    read SECOND_ANSWER
    echo "Second answer was: $SECOND_ANSWER"
fi
