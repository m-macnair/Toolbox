#!/bin/bash

# Define the array of log prefixes
extra_logs=(
	"in_port_logged_bl"
	"in_host_logged_bl"
	"out_port_logged_bl"
)
mkdir -p "/var/log/iptables/"
for key in "${extra_logs[@]}"
do
	# Set up a custom log file for iptables logs
	LOG_FILE="/var/log/iptables/$key.log"

	# Check if the log file exists, create it if it doesn't
	if [ ! -f "$LOG_FILE" ]; then
		touch "$LOG_FILE"
		chmod 644 "$LOG_FILE"
	fi

	# Configure rsyslog to write logs with the specified prefix to the custom log file
	echo ":msg, contains, \"$key:\" /var/log/iptables/$key.log" | sudo tee /etc/rsyslog.d/iptables.conf
done

# Restart the rsyslog service to apply the new configuration
sudo systemctl restart rsyslog
