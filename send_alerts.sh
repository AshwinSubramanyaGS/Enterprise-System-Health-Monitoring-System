#!/bin/bash

# send_alerts.sh - Sends alerts based on system analysis

REPORT_TYPE="$1"
TIMESTAMP="$2"
ANALYSIS_FILE="/var/log/health_monitor/analysis_${TIMESTAMP}.txt"
REPORT_FILE="/var/reports/system_health/${REPORT_TYPE}_report_${TIMESTAMP}.txt"

# Configuration
ALERT_EMAIL="ashwin.subramanya@gmail.com"
CRITICAL_THRESHOLD=1  # Number of issues to trigger critical alert

# Count number of issues
issue_count=$(grep -c "●" "$ANALYSIS_FILE" 2>/dev/null || echo 0)

# Function to send email alert
send_email_alert() {
    local subject="$1"
    local body="$2"
    
    # Using mail command (requires mailutils or similar)
    echo "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null
    
    # Alternative using sendmail (uncomment if preferred)
    # {
    #     echo "Subject: $subject"
    #     echo "To: $ALERT_EMAIL"
    #     echo ""
    #     echo "$body"
    # } | sendmail "$ALERT_EMAIL"
}


# Determine alert level and send appropriate notifications
if [ $issue_count -ge $CRITICAL_THRESHOLD ]; then
    # Critical alert - multiple issues
    subject="🚨 CRITICAL: Multiple system issues detected on $(hostname)"
    message="Multiple critical issues ($issue_count) detected on $(hostname). Immediate attention required."
    
    send_email_alert "$subject" "$(cat "$REPORT_FILE")"
    
    
elif [ $issue_count -gt 0 ]; then
    # Warning alert - some issues
    subject="⚠️ WARNING: System issues detected on $(hostname)"
    message="$issue_count issue(s) detected on $(hostname). Review recommended."
    
    send_email_alert "$subject" "$(head -20 "$REPORT_FILE")"
    
    
else
    # Informational message - no issues
    if [ "$REPORT_TYPE" = "daily" ]; then
        subject="✅ System Health OK: $(hostname) - $(date)"
        message="Daily health check completed. No issues detected on $(hostname)."
        
        send_email_alert "$subject" "System is operating within normal parameters."
    fi
fi

# Log the alert action
echo "Alerts processed: $issue_count issue(s) detected, notifications sent accordingly"
