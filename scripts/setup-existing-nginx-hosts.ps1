# PowerShell script to configure Windows hosts file for existing nginx + load balancer
# Run this script as Administrator

Write-Host "Configuring Windows hosts file for existing nginx + load balancer..." -ForegroundColor Green

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath

# Define the entries to add
$newEntries = @(
    "127.0.0.1 myapp.local",      # Your existing nginx container
    "127.0.0.1 nginx.local",      # Alternative name for existing nginx
    "127.0.0.1 lb.local",         # Load balancer management
    "127.0.0.1 web.local",        # Test web apps (optional)
    "127.0.0.1 web1.local",       # Individual test app 1
    "127.0.0.1 web2.local"        # Individual test app 2
)

# Check if entries already exist
$entriesToAdd = @()
foreach ($entry in $newEntries) {
    if ($hostsContent -notcontains $entry) {
        $entriesToAdd += $entry
    } else {
        Write-Host "Entry already exists: $entry" -ForegroundColor Yellow
    }
}

# Add new entries if any
if ($entriesToAdd.Count -gt 0) {
    try {
        Add-Content -Path $hostsPath -Value "`n# Load Balancer + Existing Nginx Test Domains" -ErrorAction Stop
        Add-Content -Path $hostsPath -Value ($entriesToAdd -join "`n") -ErrorAction Stop
        Write-Host "Successfully added $($entriesToAdd.Count) entries to hosts file" -ForegroundColor Green
    } catch {
        Write-Host "Error adding entries to hosts file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please run this script as Administrator" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "All entries already exist in hosts file" -ForegroundColor Green
}

Write-Host "`nHosts file configuration complete!" -ForegroundColor Green
Write-Host "You can now access:" -ForegroundColor Cyan
Write-Host "  - Your Existing Nginx: http://myapp.local:8080 (or http://nginx.local:8080)" -ForegroundColor White
Write-Host "  - Load Balancer:       http://lb.local:4000" -ForegroundColor White
Write-Host "  - Test Web Apps:       http://web.local:8080 (optional)" -ForegroundColor White
Write-Host "  - Individual Apps:     http://web1.local:8080, http://web2.local:8080 (optional)" -ForegroundColor White
Write-Host ""
Write-Host "Note: Your existing nginx is accessible via:" -ForegroundColor Yellow
Write-Host "  - Direct access:        http://localhost:57755" -ForegroundColor White
Write-Host "  - Load balanced:        http://myapp.local:8080" -ForegroundColor White

# Flush DNS cache
Write-Host "`nFlushing DNS cache..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Write-Host "DNS cache flushed successfully" -ForegroundColor Green
