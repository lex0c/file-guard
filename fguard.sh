#!/bin/sh

if ! command -v inotifywait &> /dev/null
then
    echo "inotifywait could not be found."
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [file_to_watch] [event1,event2,...]"
    exit 1
fi

# Path to the file you want to monitor
FILE_TO_MONITOR="$1"
EVENTS="$2"
#RECIPIENT=""

if [ ! -f "$FILE_TO_MONITOR" ]; then
    echo "File does not exist."
    exit 1
fi

if [ ! -n "$EVENTS" ]; then
    echo "EVENTS is empty."
    exit 1
fi

# Function to get process info based on PID
get_process_info() {
    PID=$1
    if [ "$PID" != "-" ]; then
        # Getting process info using ps command
        PROCESS_INFO=$(/bin/ps -p $PID -f)
        echo -e "Process Info for PID $PID:\n$PROCESS_INFO"
    else
        echo "No PID found for process."
    fi
}

get_network_state() {
    # Running ss command to get established connections and their processes
    SS_OUTPUT=$(/bin/ss -ntulp state established)

    # Logging the ss command output
    echo -e "Output of 'ss -ntulp state established':\n$SS_OUTPUT"

    # Extracting PIDs from the ss command output and getting process info
    echo "$SS_OUTPUT" | grep -o 'pid=[0-9]*' | cut -d= -f2 | while read -r PID; do
        get_process_info $PID
    done
}

# Function to perform a notification (customize as needed)
notify() {
    MESSAGE=$1
    NET_STATE=$(get_network_state)

    # Here you might want to add code to send an email or another type of notification
    echo -e "$MESSAGE\n$NET_STATE"
    #echo -e "$MESSAGE\n$NET_STATE" | sendmail $RECIPIENT
    #echo -e "$MESSAGE\n$NET_STATE" | jq -R -s -c '{data: .}' | curl -X POST -H "Content-Type: application/json" -d @- http://localhost:5000/log
}

# Loop that starts the monitoring
while true; do
    EVENT=$(/bin/inotifywait -e "$EVENTS" --format '%e' $FILE_TO_MONITOR)
    TIMESTAMP=$(date)

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
done

