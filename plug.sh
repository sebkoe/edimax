#!/bin/bash

# Script to control a Edimax SP1101w smart plug
# Requires curl

################################################################
# Path to the file that contains the neccessary credentials
CONFIG="~/.config/edimax/credentials"
################################################################


if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 IP ON|OFF|TOOGLE|GET" 1>&2
    exit 1
fi

if [ -f "$CONFIG" ]; then
    . "$CONFIG"
else
    echo "Please provide a credentials file" 1>$2
    exit 1
fi

send_xml() {
    local CMD="$1"
    local ID="$2"
    local HOST="$3"

    OUTPUT=$(curl -s \
        -d "<?xml version='1.0' encoding='utf-8'?><SMARTPLUG id='edimax'><CMD id='${ID}'><Device.System.Power.State>$CMD</Device.System.Power.State></CMD></SMARTPLUG>" \
        --digest ${USER}:${PASSWORD}@${HOST}:10000/smartplug.cgi)

    echo $OUTPUT | grep -q 'OK'
    if [ $? -eq 0 ]; then
        return 0
    fi

    TMP=$(echo $OUTPUT | egrep -o '<Device.System.Power.State>.*</Device.System.Power.State>')
    if [ $? -ne 0 ]; then
        echo "Error while sending xml"
        echo $OUTPUT
        return 1
    fi

    echo $TMP | sed 's|<Device.System.Power.State>\(.*\)</Device.System.Power.State>|\1|g'

}

toggle() {
    local HOST="$1"

    local STATE=$(send_xml get get "$HOST")

    case $STATE in
        ON)
            send_xml OFF setup "$HOST"
            ;;
        OFF)
            send_xml ON setup "$HOST"
            ;;
        *)
            echo "Invalid state: $STATE"
            ;;
    esac
}

HOST="$1"; CMD="$2"

shopt -s nocasematch
case "$CMD" in
    ON)
        send_xml ON setup "$HOST"
        ;;
    OFF)
        send_xml OFF setup "$HOST"
        ;;
    GET)
        send_xml get get "$HOST"
        ;;
    TOGGLE)
        toggle "$HOST"
        ;;
    *)
        echo "Usage $0 ON|OFF"
        ;;
esac
