#!/bin/sh

IPAD_MAC=C0:B6:58:CA:F2:40
TV_MAC=80:9F:9B:6F:B4:40
log_current_time() {
    # Get the current date and time
    current_time=$(date)
    
    # Output the current date and time to run.log
    echo "Current time: $current_time" >> /tmp/run.log
}


logFile=/tmp/run.log
echo "start" >> $logFile

pwd >> $logFile

log_current_time

while true; do

    inused=0
    used_time=0
    unused_time=0
    last_clear_time=0

    while [ $used_time -lt $((20 * 60)) ]; do
        start_time=$(date +%s)
        result=$(timeout -t 30 tcpdump -i br-lan ether src host $IPAD_MAC or ether src host $TV_MAC -nn -q | awk '/length/ {sum += $NF} END {if (sum == "") sum = 0; print sum}')
        end_time=$(date +%s)
        excution_time_tcpdump=$((end_time-start_time))
        time=$excution_time_tcpdump

        if [ $result -gt 100 ]; then
            connected=true
            if [ $unused_time -gt 1 ]; then
                used_time=$((used_time + unused_time))
            fi
            unused_time=0
            used_time=$((used_time + time))
            echo data length: $result unused_time: $unused_time used_time:$used_time >> $logFile

        else
            connected=false
            unused_time=$((unused_time + time))
        fi

        if [ $unused_time -gt $((5 * 60)) ]; then
            used_time=0
            last_clear_time=0
            unused_time=0
            echo data length: $result unused_time: $unused_time used_time:$used_time >> $logFile
        fi
        
    done

    inused=1
    echo "inused:$inused" >> $logFile

    inused=1
    iptables -I INPUT -m mac --mac-source $IPAD_MAC -j DROP
    iptables -I FORWARD -m mac --mac-source $IPAD_MAC -j DROP

    iptables -I INPUT -m mac --mac-source $TV_MAC -j DROP
    iptables -I FORWARD -m mac --mac-source $TV_MAC -j DROP

    log_current_time
    echo "Disable networking" >> $logFile

    sleep 2h
    log_current_time
    echo "Enable networking" >> $logFile
    iptables -D INPUT -m mac --mac-source $IPAD_MAC -j DROP
    iptables -D FORWARD -m mac --mac-source $IPAD_MAC -j DROP

    iptables -D INPUT -m mac --mac-source $TV_MAC -j DROP
    iptables -D FORWARD -m mac --mac-source $TV_MAC -j DROP

    # for i in $(seq 1 2); do
    #     echo $i
    #     output=$(iptables -L FORWARD --line-numbers | sed -n '3p')

    #     echo $output
    #     if echo "$output" | grep -q "MAC"; then

    #         iptables -D FORWARD 1
    #         echo "delete rule" >> $logFile
    #     fi 
    # done
done

sh /etc/NetAccessControl.sh &


# @reboot /tmp/NetAccessControl.sh
