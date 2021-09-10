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
if [[ $(__command_exists "jq") -eq 0 ]]; then
    echo "jq package is required"
    exit 1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ $(__command_exists "${SCRIPT_DIR}/speedtest") -eq 0 ]]; then
    echo "speedtest local installation necessary: see https://www.speedtest.net/apps/cli"
    exit 1
fi
${SCRIPT_DIR}/speedtest -f json-pretty > speedtest.json
download=$(cat speedtest.json | jq -r '.download.bandwidth')
downloadcommas=$(printf "%'d" $(echo ${download}))
upload=$(cat speedtest.json | jq -r '.upload.bandwidth')
uploadcommas=$(printf "%'d" $(echo ${upload}))
pingtime=$(cat speedtest.json | jq -r '.ping.latency')
packetloss=$(cat speedtest.json | jq -r '.packetLoss')
servername=$(cat speedtest.json | jq -r '.server.name')
usingVPN=$(cat speedtest.json | jq -r '.interface.isVpn')

downloadStr=$(echo "Download speed (Mb/s): ${downloadcommas}")
#echo $downloadStr
uploadStr=$(echo "Upload speed (Mb/s): ${uploadcommas}")
#echo $uploadStr
servernameStr=$(echo "Server Name used: ${servername}")
#echo $servernameStr
pingtimeStr=$(echo "Ping time (ms): ${pingtime}")
#echo $pingtime
packetlossStr=$(echo "Packet loss: ${packetloss}")
#echo $packetlossStr
usingVPNStr=$(echo "Using VPN: ${usingVPN}")
#echo $usingVPNStr
runtimeStr=$(date -r speedtest.json "+%m-%d-%Y %H:%M:%S")
#echo $runtimeStr
slackMessage="${downloadStr}"$'\n'"${uploadStr}"$'\n'"${pingtimeStr}"$'\n'"${packetlossStr}"$'\n'"${usingVPNStr}"$'\n'"${servernameStr}"$'\n'
slackMessageWhole=$(echo "Executed at ${runtimeStr}"$'\n'"${slackMessage}")
echo "${slackMessageWhole}"
curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$slackMessageWhole"'"}' $SLACK_HOOK
echo $'\n'

FILE=${SCRIPT_DIR}/speedtest.csv
if test -f "$FILE"; then
    echo "$FILE exists."
else
    echo "Will create $FILE".
    echo "Time,Download,Upload,Server,Ping,PacketLoss,UsingVPN" > $FILE
fi
echo "${runtimeStr},${download},${upload},${servername},${pingtime},${packetloss},${usingVPN}" >> $FILE
