#!/bin/bash

# Update and upgrade the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Create log directories
sudo mkdir -p /home/ubuntu/logs/SNORT
sudo mkdir -p /home/ubuntu/logs/OSSEC
sudo mkdir -p /home/ubuntu/logs/CLAMAV

# Install SNORT
sudo apt-get install -y snort

# Configure SNORT for active detection and prevention
sudo cp /etc/snort/snort.conf /etc/snort/snort.conf.bak
sudo sed -i 's/# output unified2: filename snort.log, limit 128/output unified2: filename snort.log, limit 128/' /etc/snort/snort.conf
sudo sed -i 's/# config policy_mode:inline/config policy_mode:inline/' /etc/snort/snort.conf
sudo snort -T -i eth0 -c /etc/snort/snort.conf
sudo systemctl enable snort
sudo systemctl start snort

# Redirect SNORT logs
sudo ln -sf /var/log/snort /home/ubuntu/logs/SNORT

# Install ClamAV
sudo apt-get install -y clamav clamav-daemon

# Update ClamAV database
sudo freshclam

# Configure ClamAV for active detection and prevention
sudo cp /etc/clamav/clamd.conf /etc/clamav/clamd.conf.bak
sudo sed -i 's/#LogFile \/var\/log\/clamav\/clamd.log/LogFile \/home\/ubuntu\/logs\/CLAMAV\/clamd.log/' /etc/clamav/clamd.conf
sudo sed -i 's/#Remove /Remove /' /etc/clamav/clamd.conf
sudo sed -i 's/#MoveTo /MoveTo \/home\/ubuntu\/logs\/CLAMAV\/quarantine\//' /etc/clamav/clamd.conf
sudo systemctl stop clamav-freshclam
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon

# Install OSSEC
sudo apt-get install -y ossec-hids ossec-hids-agent

# Configure OSSEC
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak
sudo sed -i 's/<logall>/&\n  <output>\n    <logall_output>\n      <file>/home/ubuntu/logs/OSSEC/ossec.log</file>\n    </logall_output>\n  <\/output>/' /var/ossec/etc/ossec.conf
sudo systemctl enable ossec-hids
sudo systemctl start ossec-hids

# Restart services to ensure all configurations are applied
sudo systemctl restart snort
sudo systemctl restart clamav-daemon
sudo systemctl restart ossec-hids

echo "Installation and configuration complete. SNORT, ClamAV, and OSSEC are now in active detection and prevention mode, and logs are being stored in /home/ubuntu/logs."
