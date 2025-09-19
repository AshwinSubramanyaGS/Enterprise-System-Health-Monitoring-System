#!/bin/bash

# collect_metrics.sh - Collects system metrics and stores in JSON format

REPORT_TYPE="$1"
TIMESTAMP="$2"
METRICS_FILE="/var/log/health_monitor/metrics_${TIMESTAMP}.json"

# Collect various system metrics
collect_cpu_metrics() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d'.' -f1)
    load_avg=$(awk '{print $1,$2,$3}' /proc/loadavg)
    echo "\"cpu\": {\"usage_percent\": $cpu_usage, \"load_average\": \"$load_avg\"}"
}

collect_memory_metrics() {
    memory_info=$(free -m | awk 'NR==2{printf "{\"total_mb\": %d, \"used_mb\": %d, \"free_mb\": %d, \"usage_percent\": %.1f}", $2, $3, $4, $3*100/$2}')
    swap_info=$(free -m | awk 'NR==3{printf "{\"total_mb\": %d, \"used_mb\": %d, \"free_mb\": %d}", $2, $3, $4}')
    echo "\"memory\": $memory_info, \"swap\": $swap_info"
}

collect_disk_metrics() {
    disk_info=$(df -h / | awk 'NR==2{printf "{\"total\": \"%s\", \"used\": \"%s\", \"available\": \"%s\", \"usage_percent\": \"%s\"}", $2, $3, $4, $5}')
    inode_info=$(df -i / | awk 'NR==2{printf "{\"total_inodes\": %d, \"used_inodes\": %d, \"free_inodes\": %d}", $2, $3, $4}')
    echo "\"disk\": $disk_info, \"inodes\": $inode_info"
}

collect_network_metrics() {
    network_stats=$(netstat -i | awk 'NR>2{print $1,$4,$8}' | head -5 | jq -R -n '[inputs | split(" ") | {interface:.[0], packets_in:.[1], packets_out:.[2]}]')
    echo "\"network_interfaces\": $network_stats"
}

collect_process_metrics() {
    total_processes=$(ps -e | wc -l)
    zombie_processes=$(ps -e | grep -c Z)
    echo "\"processes\": {\"total\": $total_processes, \"zombies\": $zombie_processes}"
}

# Create JSON output
{
    echo "{"
    echo "\"timestamp\": \"$TIMESTAMP\","
    echo "\"report_type\": \"$REPORT_TYPE\","
    echo "\"hostname\": \"$(hostname)\","
    echo "\"uptime\": \"$(uptime -p)\","
    echo $(collect_cpu_metrics) ","
    echo $(collect_memory_metrics) ","
    echo $(collect_disk_metrics) ","
    echo $(collect_network_metrics) ","
    echo $(collect_process_metrics)
    echo "}"
} > "$METRICS_FILE"

echo "Metrics collected and saved to $METRICS_FILE"
