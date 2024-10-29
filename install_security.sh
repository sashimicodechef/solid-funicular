#!/bin/bash

# Log directory
LOG_DIR="/home/ubuntu/logs"
OSSEC_LOG="$LOG_DIR/OSSEC/manual_scan.log"
CLAMAV_LOG="$LOG_DIR/CLAMAV/manual_scan.log"
SNORT_LOG="$LOG_DIR/SNORT/manual_scan.log"

# Create log directories if they don't exist
mkdir -p $LOG_DIR/OSSEC
mkdir -p $LOG_DIR/CLAMAV
mkdir -p $LOG_DIR/SNORT

# Function to run OSSEC scan
run_ossec_scan() {
    sudo /var/ossec/bin/ossec-control restart > $OSSEC_LOG 2>&1
}

# Function to run ClamAV scan
run_clamav_scan() {
    sudo clamscan -r / > $CLAMAV_LOG 2>&1
}

# Function to run SNORT scan
run_snort_scan() {
    sudo snort -T -c /etc/snort/snort.conf -l $SNORT_LOG > /dev/null 2>&1
}

# Function to run manual scans
manual_scan() {
    run_ossec_scan
    run_clamav_scan
    run_snort_scan
    clear
    echo "Manual scan complete. All systems are secure."
    echo "Logs are available in /home/ubuntu/logs."
}

# Function to uninstall services
uninstall_services() {
    sudo apt-get remove -y snort clamav clamav-daemon ossec-hids ossec-hids-agent
    sudo apt-get autoremove -y
}

# Function to install and configure services
install_services() {
    # Update and upgrade the system
    sudo apt-get update -y
    sudo apt-get upgrade -y

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
    clear
    clear
    echo "Installation and configuration complete. SNORT, ClamAV, and OSSEC are now in active detection and prevention mode, and logs are being stored in /home/ubuntu/logs."
}

# Text UI for user selection
clear
echo "Please select an option:"
echo "1. Reinstall and configure SNORT, ClamAV, and OSSEC"
echo "2. Run manual scan with SNORT, ClamAV, and OSSEC"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        uninstall_services
        install_services
        ;;
    2)
        manual_scan
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
