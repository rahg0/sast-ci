#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 SLACK_WEBHOOK_URL FINDINGS_FILE WORKFLOW_URL"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    if ! command_exists jq; then
        echo "jq could not be found. Please install jq to run this script."
        exit 1
    fi

    if [ ! -f "$FINDINGS_FILE" ]; then
        echo "Findings summary JSON file '$FINDINGS_FILE' does not exist."
        exit 1
    fi
}

# Function to extract counts from findings file
extract_counts() {
    CRITICAL_COUNT=$(jq '.results.findings_summary.CRITICAL // 0' "$FINDINGS_FILE")
    HIGH_COUNT=$(jq '.results.findings_summary.HIGH // 0' "$FINDINGS_FILE")
    MEDIUM_COUNT=$(jq '.results.findings_summary.MEDIUM // 0' "$FINDINGS_FILE")
    LOW_COUNT=$(jq '.results.findings_summary.LOW // 0' "$FINDINGS_FILE")
    INFO_COUNT=$(jq '.results.findings_summary.INFO // 0' "$FINDINGS_FILE")
}

# Function to format Slack message
format_slack_message() {
    SLACK_MESSAGE="*Warning!!*\nPlease note that some issues were found on your latest sast scan.\n\n*Findings Summary:*\n\`\`\`CRITICAL: $CRITICAL_COUNT\nHIGH: $HIGH_COUNT\nMEDIUM: $MEDIUM_COUNT\nLOW: $LOW_COUNT\nINFO: $INFO_COUNT\`\`\`\n\nFor more details, see the GitHub Actions workflow: <$WORKFLOW_URL|Workflow Run>"
}

# Function to send message to Slack
send_to_slack() {
    curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"${SLACK_MESSAGE}\"}" "$SLACK_WEBHOOK_URL"
}

# Main function
main() {
    # Check arguments
    if [ "$#" -ne 3 ]; then
        usage
        exit 1
    fi

    SLACK_WEBHOOK_URL="$1"
    FINDINGS_FILE="$2"
    WORKFLOW_URL="$3"

    # Ensure SLACK_WEBHOOK_URL is provided
    if [ -z "$SLACK_WEBHOOK_URL" ]; then
        echo "Error: SLACK_WEBHOOK_URL not provided."
        usage
        exit 1
    fi

    # Ensure FINDINGS_FILE is provided
    if [ -z "$FINDINGS_FILE" ]; then
        echo "Error: FINDINGS_FILE not provided."
        usage
        exit 1
    fi

    check_prerequisites
    extract_counts
    format_slack_message
    send_to_slack
}

# Execute main function
main "$@"
