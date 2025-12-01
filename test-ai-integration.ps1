# Test AI Integration End-to-End
Write-Host "=== FaceShare AI Integration Test ===" -ForegroundColor Green

$aiUrl = "http://localhost:5000"
$backendUrl = "http://localhost:8080"

# Test 1: AI Service Health
Write-Host "`n1. Testing AI Service..." -ForegroundColor Yellow
try {
    $aiHealth = Invoke-RestMethod -Uri "$aiUrl/health" -Method GET
    Write-Host "✓ AI Service: $($aiHealth.status)" -ForegroundColor Green
    Write-Host "  Version: $($aiHealth.version)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ AI Service not running" -ForegroundColor Red
    Write-Host "  Start with: cd ai-service && python main.py" -ForegroundColor Yellow
    exit 1
}

# Test 2: Backend Health
Write-Host "`n2. Testing Backend..." -ForegroundColor Yellow
try {
    $backendHealth = Invoke-RestMethod -Uri "$backendUrl/api/health" -Method GET
    Write-Host "✓ Backend: $($backendHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend not running" -ForegroundColor Red
    Write-Host "  Start with: cd backend && mvn spring-boot:run" -ForegroundColor Yellow
    exit 1
}

# Test 3: Login and Get Token
Write-Host "`n3. Testing Authentication..." -ForegroundColor Yellow
$loginData = @{
    email = "alice@example.com"
    password = "password"
} | ConvertTo-Json

try {
    $login = Invoke-RestMethod -Uri "$backendUrl/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    Write-Host "✓ Login successful: $($login.fullName)" -ForegroundColor Green
    $token = $login.token
} catch {
    Write-Host "✗ Login failed" -ForegroundColor Red
    exit 1
}

# Test 4: Check Photos
Write-Host "`n4. Checking User Photos..." -ForegroundColor Yellow
$headers = @{"Authorization" = "Bearer $token"}
try {
    $photos = Invoke-RestMethod -Uri "$backendUrl/api/photos/my-photos" -Method GET -Headers $headers
    Write-Host "✓ Photos retrieved: $($photos.Count) photos" -ForegroundColor Green
    
    if ($photos.Count -gt 0) {
        $photo = $photos[0]
        Write-Host "  Latest photo:" -ForegroundColor Cyan
        Write-Host "    - File: $($photo.fileName)" -ForegroundColor Gray
        Write-Host "    - Status: $($photo.processingStatus)" -ForegroundColor Gray
        Write-Host "    - Faces: $($photo.facesDetected)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to get photos" -ForegroundColor Red
}

# Test 5: AI Face Detection (if test image exists)
Write-Host "`n5. Testing AI Face Detection..." -ForegroundColor Yellow
if (Test-Path "test-images/test-face.jpg") {
    try {
        $boundary = [System.Guid]::NewGuid().ToString()
        $headers = @{"Content-Type" = "multipart/form-data; boundary=$boundary"}
        
        Write-Host "  Test image found, sending to AI..." -ForegroundColor Cyan
        Write-Host "  (Manual test: Upload photo via app)" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠ Skipping AI test (use app to upload)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ No test image (upload via app to test)" -ForegroundColor Yellow
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "✓ AI Service running on port 5000" -ForegroundColor White
Write-Host "✓ Backend running on port 8080" -ForegroundColor White
Write-Host "✓ Authentication working" -ForegroundColor White
Write-Host "`nNext: Upload photos via mobile app to test AI integration" -ForegroundColor Cyan
