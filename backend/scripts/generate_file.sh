#!/bin/bash

# Script to generate a sample large file for testing
# This creates a text file that simulates system logs
# Usage: ./generate_file.sh [SIZE_MB]
# Example: ./generate_file.sh 5  (generates 5MB file)
# Maximum recommended size: 10MB

# Get file size parameter (default: 2MB, max: 10MB)
SIZE_MB=${1:-2}
if [ "$SIZE_MB" -gt 10 ]; then
    echo "Warning: File size exceeds 10MB maximum. Clamping to 10MB."
    SIZE_MB=10
fi

# Generate current timestamp for filename
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CURRENT_TIME=$(date -u +"%Y%m%d_%H%M%S")
    CURRENT_TIME_RFC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
else
    # Linux
    CURRENT_TIME=$(date -u +"%Y%m%d_%H%M%S")
    CURRENT_TIME_RFC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
fi

FILES_DIR="./files"
FILENAME="system_log_${CURRENT_TIME}.txt"

# Create files directory if it doesn't exist
mkdir -p "$FILES_DIR"

FILE_PATH="$FILES_DIR/$FILENAME"

echo "Generating $SIZE_MB MB log file: $FILE_PATH"

# Header
cat > "$FILE_PATH" << EOF
=== Device System Log File ===
Generated: ${CURRENT_TIME_RFC}
System: Facial Recognition Access Control
Version: 2.4.1
Location: Main Hub, Control Room

=== Log Entries ===

EOF

# Calculate how many lines we need (approximately)
BYTES_PER_LINE=200
TARGET_SIZE=$((SIZE_MB * 1024 * 1024))
LINES_NEEDED=$((TARGET_SIZE / BYTES_PER_LINE))

echo "Writing approximately $LINES_NEEDED lines..."

# Event types and messages for realistic logs
declare -a EVENT_TYPES=("facial_authentication" "tailgating_detection" "access_denied" "system" "facial_authentication" "facial_authentication")
declare -a SEVERITIES=("INFO" "CRITICAL" "WARNING" "ERROR" "INFO" "INFO")
declare -a DEVICES=("DEVICE-001" "DEVICE-002" "DEVICE-003" "DEVICE-004" "DEVICE-005" "DEVICE-006")
declare -a LOCATIONS=("Main Entrance, Building A" "Server Room, Floor 3" "Executive Floor, Building B" "Parking Garage, Level 2" "Research Lab, Building C" "Data Center, Basement")

# Generate log entries
for i in $(seq 1 $LINES_NEEDED); do
    # Calculate timestamp (milliseconds since epoch)
    hours_ago=$((i / 60))
    minutes_offset=$((i % 60))
    
    # Generate timestamp in milliseconds
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        timestamp_ms=$(($(date -u -v-${hours_ago}H -v-${minutes_offset}M +%s 2>/dev/null || date +%s) * 1000))
        timestamp_rfc=$(date -u -v-${hours_ago}H -v-${minutes_offset}M +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S")
    else
        # Linux
        timestamp_ms=$(($(date -u -d "${hours_ago} hours ${minutes_offset} minutes ago" +%s 2>/dev/null || date +%s) * 1000))
        timestamp_rfc=$(date -u -d "${hours_ago} hours ${minutes_offset} minutes ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S")
    fi
    
    # Select random values
    event_idx=$((i % ${#EVENT_TYPES[@]}))
    device_idx=$((i % ${#DEVICES[@]}))
    location_idx=$((i % ${#LOCATIONS[@]}))
    
    event_type=${EVENT_TYPES[$event_idx]}
    severity=${SEVERITIES[$event_idx]}
    device=${DEVICES[$device_idx]}
    location=${LOCATIONS[$location_idx]}
    
    # Generate appropriate log message based on event type
    case $event_type in
        "facial_authentication")
            if [ $((i % 10)) -lt 8 ]; then
                message="Facial authentication successful, Confidence: $((85 + (i % 15)))%, Device: $device"
            else
                message="Facial authentication failed, Reason: Low confidence match ($((60 + (i % 20)))%), Device: $device"
                severity="WARNING"
            fi
            ;;
        "tailgating_detection")
            message="Tailgating detected - Unauthorized person followed authorized, Device: $device, Location: $location"
            ;;
        "access_denied")
            message="Access denied - Authentication failure after $((1 + (i % 3))) attempts, Device: $device"
            ;;
        "system")
            if [ $((i % 20)) -eq 0 ]; then
                message="System error - Camera calibration required, Device: $device, Error Code: ERR-$((1000 + (i % 100)))"
            else
                message="System status - Device: $device, Status: online, Uptime: $((100 + (i % 900))) hours"
                severity="INFO"
            fi
            ;;
        *)
            message="Event logged - Device: $device, Location: $location"
            ;;
    esac
    
    # Write log entry in structured format
    printf "%s.%03d [%s] [%s] Device=%s Location=\"%s\" Message=\"%s\"\n" \
        "$timestamp_rfc" \
        $((timestamp_ms % 1000)) \
        "$severity" \
        "$event_type" \
        "$device" \
        "$location" \
        "$message" >> "$FILE_PATH"
    
    # Progress indicator every 10000 lines
    if [ $((i % 10000)) -eq 0 ]; then
        echo "Progress: $i lines written ($(du -h "$FILE_PATH" | cut -f1))..."
    fi
done

echo ""
echo "File generation complete!"
echo "File: $FILE_PATH"
ls -lh "$FILE_PATH"
echo ""
echo "Sample log entries:"
head -n 20 "$FILE_PATH" | tail -n 10

