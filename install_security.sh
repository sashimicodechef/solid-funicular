#!/bin/bash

echo "Starting the ClamAV installation and configuration process..."

# Update package lists
echo "Updating package lists..."
sudo apt-get update -y || echo "Error updating package lists."

# Stop ClamAV services if they are running
echo "Stopping ClamAV services..."
sudo systemctl stop clamav-freshclam
sudo systemctl stop clamav-daemon || echo "Error stopping ClamAV services."

# Remove existing ClamAV cron jobs for clamav and ubuntu users
echo "Removing existing ClamAV cron jobs for clamav and ubuntu users..."
sudo crontab -u clamav -l | grep -v 'clamscan' | sudo crontab -u clamav -
sudo crontab -u ubuntu -l | grep -v 'clamscan' | sudo crontab -u ubuntu -

# Install ClamAV
echo "Installing ClamAV..."
sudo apt-get install -y clamav clamav-daemon || echo "ClamAV installation error."

# Update ClamAV definitions
echo "Updating ClamAV definitions..."
sudo freshclam || echo "ClamAV definitions update error."

# Configure ClamAV to delete infected files automatically
echo "Configuring ClamAV to delete infected files automatically..."
sudo sed -i 's/^#Remove\/Infected/Remove\/Infected/' /etc/clamav/clamd.conf

# Start ClamAV services
echo "Starting ClamAV services..."
sudo systemctl start clamav-freshclam
sudo systemctl start clamav-daemon || echo "ClamAV service start error."

# Add a ClamAV daily scan job to the crontab for ubuntu user
echo "Setting up a daily ClamAV scan job for ubuntu user..."
(sudo crontab -u ubuntu -l; echo '0 2 * * * /usr/bin/clamscan -r / --remove') | sudo crontab -u ubuntu -
clear
echo "Installation and configuration completed."
