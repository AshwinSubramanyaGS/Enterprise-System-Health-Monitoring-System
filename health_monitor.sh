#!/bin/bash

# health_monitor.sh - Main controller script
# Usage: ./health_monitor.sh [daily|weekly|monthly]

REPORT_TYPE="${1:-daily}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/var/log/health_monitor"
REPORT_DIR="/var/reports/system_health"
ARCHIVE_DIR="/var/archives/system_reports"

# Create directories if they don't exist
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$ARCHIVE_DIR"

# Define log file
LOG_FILE="$LOG_DIR/health_monitor_${TIMESTAMP}.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

# Validate report type
if [[ ! "$REPORT_TYPE" =~ ^(daily|weekly|monthly)$ ]]; then
    handle_error "Invalid report type. Use: daily, weekly, or monthly"
fi

log_message "Starting $REPORT_TYPE system health monitoring"

# Execute the four component scripts
log_message "Collecting system metrics..."
./collect_metrics.sh "$REPORT_TYPE" "$TIMESTAMP" || handle_error "Metrics collection failed"

log_message "Analyzing system data..."
./analyze_system.sh "$REPORT_TYPE" "$TIMESTAMP" || handle_error "System analysis failed"

log_message "Generating health report..."
./generate_report.sh "$REPORT_TYPE" "$TIMESTAMP" || handle_error "Report generation failed"

log_message "Sending alerts and notifications..."
./send_alerts.sh "$REPORT_TYPE" "$TIMESTAMP" || handle_error "Alert sending failed"

# Archive the report
log_message "Archiving report..."
tar -czf "$ARCHIVE_DIR/system_health_${REPORT_TYPE}_${TIMESTAMP}.tar.gz" \
    "$REPORT_DIR/${REPORT_TYPE}_report_${TIMESTAMP}.txt" \
    "$LOG_DIR/metrics_${TIMESTAMP}.json" 2>/dev/null

log_message "$REPORT_TYPE health monitoring completed successfully"
