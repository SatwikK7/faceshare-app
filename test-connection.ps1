# Test network connectivity for FaceShare app
Write-Host "=== FaceShare Network Connectivity Test ===" -ForegroundColor Green

# Get computer's IP address
Write-Host "`n1. Computer's IP Address:" -ForegroundColor Yellow
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
Write-Host "IP: $ipAddress" -ForegroundColor Cyan

# Check if backend is running
Write-Host "`n2. Checking if backend is running locally..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 5
    Write-Host "✓ Backend is running on localhost" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is NOT running on localhost" -ForegroundColor Red
    Write-Host "Please start the backend first!" -ForegroundColor Yellow
    exit 1
}

# Check if backend is accessible via network IP
Write-Host "`n3. Checking if backend is accessible via network IP..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://${ipAddress}:8080/api/health" -Method GET -TimeoutSec 5
    Write-Host "✓ Backend is accessible at http://${ipAddress}:8080" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is NOT accessible at http://${ipAddress}:8080" -ForegroundColor Red
    Write-Host "This is likely a firewall issue!" -ForegroundColor Yellow
}

# Check Windows Firewall status
Write-Host "`n4. Windows Firewall Status:" -ForegroundColor Yellow
$firewallProfiles = Get-NetFirewallProfile
foreach ($profile in $firewallProfiles) {
    Write-Host "$($profile.Name): $($profile.Enabled)" -ForegroundColor Cyan
}

Write-Host "`n=== Instructions ===" -ForegroundColor Green
Write-Host "Your Flutter app should use: http://${ipAddress}:8080" -ForegroundColor White
Write-Host "`nIf the backend is not accessible via network IP:" -ForegroundColor Yellow
Write-Host "1. Allow Java through Windows Firewall" -ForegroundColor White
Write-Host "2. Or temporarily disable Windows Firewall for testing" -ForegroundColor White
Write-Host "3. Make sure your phone and computer are on the same WiFi network" -ForegroundColor White
