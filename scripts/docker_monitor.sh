#!/bin/bash

# If $1 is unset or empty, use the default path
OUTPUT_FILE=${1:-"log/docker_stats_$(date +%Y%m%d_%H%M%S)"}

# Create the directory if it doesn't exist to avoid "No such file or directory" errors
mkdir -p "$(dirname "$OUTPUT_FILE")"

# The trap must come BEFORE the loop starts
trap 'echo ""; echo "Stopped monitoring."; exit 0' INT

echo "Monitoring docker stats to: $OUTPUT_FILE"
echo "Press [Ctrl+C] to stop."

while true; do
  # Append stats to the file
  docker stats --no-stream --format '{"timestamp": '$(date +%s)', "container":"{{.Name}}", "cpu":"{{.CPUPerc}}", "mem":"{{.MemPerc}}"}' >>"$OUTPUT_FILE"
  sleep 2
done
