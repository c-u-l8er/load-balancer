# PowerShell script to configure Windows hosts file for load balancer testing
# Run this script as Administrator

Write-Host "Configuring Windows hosts file for load balancer testing..." -ForegroundColor Green

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath

# Define the entries to add
$newEntries = @(
    "127.0.0.1 portainer.local",
    "127.0.0.1 web.local", 
    "127.0.0.1 web1.local",
    "127.0.0.1 web2.local",
    "127.0.0.1 lb.local",
    "127.0.0.1 api.local"
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
        Add-Content -Path $hostsPath -Value "`n# Load Balancer Test Domains" -ErrorAction Stop
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
Write-Host "  - Portainer: http://portainer.local:9000" -ForegroundColor White
Write-Host "  - Load Balancer: http://lb.local:4000" -ForegroundColor White
Write-Host "  - Web Apps: http://web.local:8080" -ForegroundColor White
Write-Host "  - Individual Apps: http://web1.local:8080, http://web2.local:8080" -ForegroundColor White
Write-Host "  - API: http://api.local:8080" -ForegroundColor White

# Flush DNS cache
Write-Host "`nFlushing DNS cache..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Write-Host "DNS cache flushed successfully" -ForegroundColor Green
