#!/bin/bash

# generate_report.sh - Generates a comprehensive health report

REPORT_TYPE="$1"
TIMESTAMP="$2"
METRICS_FILE="/var/log/health_monitor/metrics_${TIMESTAMP}.json"
ANALYSIS_FILE="/var/log/health_monitor/analysis_${TIMESTAMP}.txt"
REPORT_FILE="/var/reports/system_health/${REPORT_TYPE}_report_${TIMESTAMP}.txt"

# Function to format metrics for report
format_metrics() {
    echo "DETAILED METRICS:"
    echo "================="
    jq -r '"CPU: \(.cpu.usage_percent)% (Load: \(.cpu.load_average))",
           "Memory: \(.memory.usage_percent)% (Total: \(.memory.total_mb)MB, Used: \(.memory.used_mb)MB)",
           "Disk: \(.disk.usage_percent) used (\(.disk.used)/\(.disk.total))",
           "Processes: Total: \(.processes.total), Zombies: \(.processes.zombies)",
           "Uptime: \(.uptime)",
           "Network: Top 5 interfaces -",
           (.network_interfaces[] | "  \(.interface): IN=\(.packets_in), OUT=\(.packets_out)")' "$METRICS_FILE"
}

# Generate the comprehensive report
{
    echo "SYSTEM HEALTH REPORT"
    echo "===================="
    echo "Generated: $(date)"
    echo "Report Type: $REPORT_TYPE"
    echo "Hostname: $(hostname)"
    echo "Report ID: $TIMESTAMP"
    echo ""
    echo "EXECUTIVE SUMMARY"
    echo "-----------------"
    
    # Include analysis results
    cat "$ANALYSIS_FILE" | sed -n '/ISSUES DETECTED:/,/METRIC SUMMARY:/p' | head -n -2
    
    echo ""
    format_metrics
    
    echo ""
    echo "RECOMMENDATIONS"
    echo "---------------"
    
    # Generate recommendations based on issues
    if grep -q "High CPU usage" "$ANALYSIS_FILE"; then
        echo "● Investigate CPU-intensive processes using 'top' or 'htop'"
        echo "● Consider optimizing applications or adding more CPU resources"
    fi
    
    if grep -q "High Memory usage" "$ANALYSIS_FILE"; then
        echo "● Check memory usage by process: 'ps aux --sort=-%mem | head'"
        echo "● Consider adding swap space or increasing physical memory"
    fi
    
    if grep -q "High Disk usage" "$ANALYSIS_FILE"; then
        echo "● Identify large files: 'du -sh /* | sort -rh | head -10'"
        echo "● Clean up temporary files and old logs"
        echo "● Consider expanding storage capacity"
    fi
    
    if grep -q "Zombie processes" "$ANALYSIS_FILE"; then
        echo "● Identify parent processes of zombies: 'ps -eo stat,pid,ppid,comm | grep -w Z'"
        echo "● Consider restarting affected services or the system"
    fi
    
    if [ ! -s "$ANALYSIS_FILE" ] || ! grep -q "No critical issues" "$ANALYSIS_FILE"; then
        echo "● No immediate action required. Continue regular monitoring."
    fi
    
    echo ""
    echo "NEXT SCHEDULED REPORT:"
    case "$REPORT_TYPE" in
        "daily") echo "Next report in 24 hours" ;;
        "weekly") echo "Next report in 7 days" ;;
        "monthly") echo "Next report in 30 days" ;;
    esac
    
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
