#!/bin/bash

echo "Starting the ClamAV installation and configuration process..."

# Update package lists
echo "Updating package lists..."
(sudo apt-get update -y && clear) || echo "Error updating package lists."

# Stop ClamAV services if they are running
echo "Stopping ClamAV services..."
(sudo systemctl stop clamav-freshclam && sudo systemctl stop clamav-daemon && clear) || echo "Error stopping ClamAV services."

# Remove existing ClamAV cron jobs for clamav and ubuntu users
echo "Removing existing ClamAV cron jobs for clamav and ubuntu users..."
(sudo crontab -u clamav -l 2>/dev/null | grep -v 'clamscan' | sudo crontab -u clamav - && clear) || echo "No cron jobs found for user clamav."
(sudo crontab -u ubuntu -l 2>/dev/null | grep -v 'clamscan' | sudo crontab -u ubuntu - && clear) || echo "No cron jobs found for user ubuntu."

# Install ClamAV
echo "Installing ClamAV..."
(sudo apt-get install -y clamav clamav-daemon 2>/dev/null && clear) || echo "ClamAV installation error."

# Update ClamAV definitions
echo "Updating ClamAV definitions..."
(sudo freshclam 2>/dev/null && clear) || echo "ClamAV definitions update error."

# Configure ClamAV to delete infected files automatically
echo "Configuring ClamAV to delete infected files automatically..."
sudo sed -i 's/^#Remove/Infected/Remove/Infected/' /etc/clamav/clamd.conf
sudo sed -i 's/^#Remove/Infected/Remove/Infected/' /etc/clamav/freshclam.conf
sudo sed -i 's/^#Remove/Infected/Remove/Infected/' /etc/clamav/scan.conf

# Start ClamAV services
echo "Starting ClamAV services..."
(sudo systemctl start clamav-freshclam && sudo systemctl start clamav-daemon && clear) || echo "ClamAV service start error."

# Add a ClamAV daily scan job to the crontab for ubuntu user
echo "Setting up a daily ClamAV scan job for ubuntu user..."
(sudo crontab -u ubuntu -l 2>/dev/null; echo '0 2 * * * /usr/bin/clamscan -r / --remove') | sudo crontab -u ubuntu -

clear
echo "Installation and configuration completed."
