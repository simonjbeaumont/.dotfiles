#!/bin/sh

output_device_type=$(mediaremotetool local-endpoint | paste -s | grep -o "outputDevices = (.*)" | grep -o "type=.*" | awk '{print $1}' | cut -d= -f2 | tr A-Z a-z)

echo "audio: ${output_device_type:-local}"
