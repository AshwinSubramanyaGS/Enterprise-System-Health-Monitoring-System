#!/bin/bash

# analyze_system.sh - Analyzes collected metrics and identifies issues

REPORT_TYPE="$1"
TIMESTAMP="$2"
METRICS_FILE="/var/log/health_monitor/metrics_${TIMESTAMP}.json"
ANALYSIS_FILE="/var/log/health_monitor/analysis_${TIMESTAMP}.txt"

# Load metrics from JSON file
cpu_usage=$(jq '.cpu.usage_percent' "$METRICS_FILE")
mem_usage=$(jq '.memory.usage_percent' "$METRICS_FILE")
disk_usage=$(jq '.disk.usage_percent' "$METRICS_FILE" | tr -d '%')
zombie_procs=$(jq '.processes.zombies' "$METRICS_FILE")

# Thresholds (adjust based on your environment)
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90
ZOMBIE_THRESHOLD=5

# Initialize issues array
declare -A issues=()

# Check for issues
check_cpu() {
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        issues[CPU]="High CPU usage: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%)"
    fi
}

check_memory() {
    if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
        issues[MEMORY]="High Memory usage: ${mem_usage}% (Threshold: ${MEM_THRESHOLD}%)"
    fi
}

check_disk() {
    if (( $(echo "$disk_usage > $DISK_THRESHOLD" | bc -l) )); then
        issues[DISK]="High Disk usage: ${disk_usage}% (Threshold: ${DISK_THRESHOLD}%)"
    fi
}

check_zombies() {
    if (( zombie_procs > ZOMBIE_THRESHOLD )); then
        issues[ZOMBIES]="Zombie processes detected: ${zombie_procs} (Threshold: ${ZOMBIE_THRESHOLD})"
    fi
}

# Run all checks
check_cpu
check_memory
check_disk
check_zombies

# Save analysis results
{
    echo "SYSTEM ANALYSIS REPORT - $(date)"
    echo "=========================================="
    echo "Report Type: $REPORT_TYPE"
    echo "Timestamp: $TIMESTAMP"
    echo "Hostname: $(hostname)"
    echo ""
    echo "ISSUES DETECTED:"
    echo "----------------"
    
    if [ ${#issues[@]} -eq 0 ]; then
        echo "No critical issues detected. System is healthy."
    else
        for key in "${!issues[@]}"; do
            echo "● ${issues[$key]}"
        done
    fi
    
    echo ""
    echo "METRIC SUMMARY:"
    echo "---------------"
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory Usage: ${mem_usage}%"
    echo "Disk Usage: ${disk_usage}%"
    echo "Zombie Processes: ${zombie_procs}"
    
} > "$ANALYSIS_FILE"

echo "Analysis completed. Results saved to $ANALYSIS_FILE"
