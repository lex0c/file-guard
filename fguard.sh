#!/bin/sh

if ! command -v /bin/inotifywait &> /dev/null
then
    /bin/echo "/bin/inotifywait could not be found."
fi

if ! command -v /bin/lsof &> /dev/null
then
    /bin/echo "/bin/lsof could not be found."
fi

if [ "$#" -lt 2 ]; then
    /bin/echo "Usage: $0 [file_to_watch] [event1,event2,...]"
    exit 1
fi

# Path to the file you want to monitor
FILE_TO_MONITOR="$1"
EVENTS="$2"
#RECIPIENT=""
#TELEGRAM_BOT_TOKEN="" # https://core.telegram.org/bots/features#botfather
#TELEGRAM_CHAT_ID=""   # https://api.telegram.org/bot<YourBOTToken>/getUpdates

if [ ! -f "$FILE_TO_MONITOR" ]; then
    /bin/echo "File does not exist."
    exit 1
fi

if [ ! -n "$EVENTS" ]; then
    /bin/echo "EVENTS is empty."
    exit 1
fi

# Function to get process info based on PID
get_process_info() {
    PID=$1
    if [ "$PID" != "-" ]; then
        # Getting process info using ps command
        PROCESS_INFO=$(/bin/ps -p $PID -f)
        /bin/echo -e "Process Info for PID $PID:\n$PROCESS_INFO"
    else
        /bin/echo "No PID $PID found for process."
    fi
}

get_network_state() {
    # Getting processes accessing the file
    LSOF_OUTPUT=$(/bin/lsof $FILE_TO_MONITOR)
    # Running ss command to get established connections and their processes
    SS_OUTPUT=$(/bin/ss -ntulp state established)

    if [ -n "$LSOF_OUTPUT" ]; then
        # Logging the command output
        /bin/echo -e "Processes interacting with the file:\n$LSOF_OUTPUT"
        get_process_info $(/bin/echo "$LSOF_OUTPUT" | /bin/awk '{print $2}' | /bin/grep -v PID)
    fi

    if [ -n "$SS_OUTPUT" ]; then
        # Logging the command output
        /bin/echo -e "Connections established on the server:\n$SS_OUTPUT"

        # Extracting PIDs from the ss command output and getting process info
        /bin/echo "$SS_OUTPUT" | /bin/grep -o 'pid=[0-9]*' | /bin/cut -d= -f2 | while read -r PID; do
            get_process_info $PID
        done
    fi
}

# Function to perform a notification (customize as needed)
notify() {
    MESSAGE=$1
    NET_STATE=$(get_network_state)

    # Here you might want to add code to send an email or another type of notification
    /bin/echo -e "$MESSAGE\n$NET_STATE"
    #/bin/echo -e "$MESSAGE\n$NET_STATE" | sendmail $RECIPIENT
    #/bin/echo -e "$MESSAGE\n$NET_STATE" | /bin/jq -R -s -c '{data: .}' | /bin/curl -X POST -H "Content-Type: application/json" -d @- http://localhost:5000/log

    #/bin/curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    #    -d chat_id="$TELEGRAM_CHAT_ID" \
    #    -d text="$MESSAGE\n$NET_STATE" &> /dev/null
}

# Loop that starts the monitoring
while true; do
    EVENT=$(/bin/inotifywait -e "$EVENTS" --format '%e' $FILE_TO_MONITOR)
    TIMESTAMP=$(/bin/date)

        case "$EVENT" in
        "ACCESS")
            notify "File $FILE_TO_MONITOR was accessed at $TIMESTAMP" 
            ;;
        "MODIFY")
            notify "File $FILE_TO_MONITOR was modified at $TIMESTAMP"
            ;;
        "OPEN")
            notify "File $FILE_TO_MONITOR was opened at $TIMESTAMP"
            ;;
        "CLOSE_WRITE,CLOSE")
            notify "File $FILE_TO_MONITOR was closed after writing at $TIMESTAMP"
            ;;
        "MOVE_SELF")
            notify "File $FILE_TO_MONITOR was moved at $TIMESTAMP"
            exit 1
            ;;
        "DELETE_SELF")
            notify "File $FILE_TO_MONITOR was deleted at $TIMESTAMP"
            exit 1
            ;;
    esac

    if [ ! -f "$FILE_TO_MONITOR" ]; then
        /bin/echo "File does not exist."
        exit 1
    fi
done

