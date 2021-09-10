#!/bin/bash
if [[ -z "${SLACK_HOOK}" ]]; then
  echo "Please set the SLACK_HOOK envvar before calling this."
  exit 1
fi
function __command_exists {
    local exists=$(command -v "$1")
    # command does not exist
    if [[ -z $exists ]]; then
        echo 0
    else # command exists
        echo 1
    fi
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ $(__command_exists "${SCRIPT_DIR}/speedtest") -eq 0 ]]; then
    echo "speedtest local installation necessary: see https://www.speedtest.net/apps/cli"
    exit 1
fi
touch ${SCRIPT_DIR}/speedtest.out
${SCRIPT_DIR}/speedtest > speedtest.out
download=$(cat ${SCRIPT_DIR}/speedtest.out | grep Download | awk '{print $3" "$4}')
upload=$(cat ${SCRIPT_DIR}/speedtest.out | grep Upload | awk '{print $3" "$4}')
pingtime=$(cat ${SCRIPT_DIR}/speedtest.out | grep Latency | awk '{print $2" "$3}')
packetloss=$(cat ${SCRIPT_DIR}/speedtest.out | grep "Packet Loss" | awk '{print $3}')
servername=$(cat ${SCRIPT_DIR}/speedtest.out | grep "Server" | awk '{$1=""; print $0}')

runtime=$(date -r ${SCRIPT_DIR}/speedtest.out "+%m-%d-%Y %H:%M:%S")
slackMessage="Download: ${download}"$'\n'"Upload: ${upload}"$'\n'"Ping time: ${pingtime}"$'\n'"Packet Loss: ${packetloss}"$'\n'"Server Name: ${servername}"$'\n'
slackMessageWhole=$(echo "Executed at: ${runtime}"$'\n'"${slackMessage}")
echo "${slackMessageWhole}"
curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$slackMessageWhole"'"}' $SLACK_HOOK
echo $'\n'

FILE=${SCRIPT_DIR}/speedtest.csv
if test -f "$FILE"; then
    echo "$FILE exists."
else
    echo "Will create $FILE".
    echo "Time,Download,Upload,Server,Ping,PacketLoss" > $FILE
fi
echo "\"${runtime}\",\"${download}\",\"${upload}\",\"${servername}\",\"${pingtime}\",\"${packetloss}\"" >> $FILE
