#!/bin/bash

# Bash script to configure Linux/WSL2 hosts file for existing nginx + load balancer
# Run this script with sudo

echo "Configuring Linux hosts file for existing nginx + load balancer..."

HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.backup.$(date +%Y%m%d_%H%M%S)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (use sudo)"
    exit 1
fi

# Backup current hosts file
echo "Creating backup of current hosts file..."
cp "$HOSTS_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Define the entries to add
NEW_ENTRIES=(
    "127.0.0.1 myapp.local"      # Your existing nginx container
    "127.0.0.1 nginx.local"      # Alternative name for existing nginx
    "127.0.0.1 lb.local"         # Load balancer management
    "127.0.0.1 web.local"        # Test web apps (optional)
    "127.0.0.1 web1.local"       # Individual test app 1
    "127.0.0.1 web2.local"       # Individual test app 2
)

# Check if entries already exist and add new ones
ENTRIES_ADDED=0
for entry in "${NEW_ENTRIES[@]}"; do
    if ! grep -q "^$entry" "$HOSTS_FILE"; then
        echo "$entry" >> "$HOSTS_FILE"
        echo "Added: $entry"
        ((ENTRIES_ADDED++))
    else
        echo "Entry already exists: $entry"
    fi
done

if [ $ENTRIES_ADDED -gt 0 ]; then
    echo "Successfully added $ENTRIES_ADDED entries to hosts file"
else
    echo "All entries already exist in hosts file"
fi

echo ""
echo "Hosts file configuration complete!"
echo "You can now access:"
echo "  - Your Existing Nginx: http://myapp.local:8080 (or http://nginx.local:8080)"
echo "  - Load Balancer:       http://lb.local:4000"
echo "  - Test Web Apps:       http://web.local:8080 (optional)"
echo "  - Individual Apps:     http://web1.local:8080, http://web2.local:8080 (optional)"
echo ""
echo "Note: Your existing nginx is accessible via:"
echo "  - Direct access:        http://localhost:57755"
echo "  - Load balanced:        http://myapp.local:8080"

# Flush DNS cache if systemd-resolved is available
if command -v systemd-resolve &> /dev/null; then
    echo "Flushing DNS cache..."
    systemd-resolve --flush-caches
    echo "DNS cache flushed successfully"
fi

echo "Configuration complete!"
