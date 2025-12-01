# FaceShare - Complete System Startup Script
Write-Host "=== FaceShare Complete System Startup ===" -ForegroundColor Green

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

# Check Java
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    Write-Host "✓ Java installed: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Java not found. Install Java 17+" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version
    Write-Host "✓ Python installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Install Python 3.8+" -ForegroundColor Red
    exit 1
}

# Check Flutter
try {
    $flutterVersion = flutter --version | Select-String "Flutter"
    Write-Host "✓ Flutter installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Install Flutter" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Starting Services ===" -ForegroundColor Cyan

# Start AI Service
Write-Host "`n1. Starting AI Service (Port 5000)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd ai-service; if (Test-Path venv) { venv\Scripts\activate } else { python -m venv venv; venv\Scripts\activate; pip install -r requirements.txt }; python main.py"
Start-Sleep -Seconds 3

# Start Backend
Write-Host "2. Starting Backend (Port 8080)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; mvn spring-boot:run"
Start-Sleep -Seconds 5

# Start Frontend
Write-Host "3. Starting Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; flutter run"

Write-Host "`n=== All Services Starting ===" -ForegroundColor Green
Write-Host "AI Service: http://localhost:5000" -ForegroundColor White
Write-Host "Backend: http://localhost:8080" -ForegroundColor White
Write-Host "Frontend: Running on connected device" -ForegroundColor White

Write-Host "`nTest URLs:" -ForegroundColor Cyan
Write-Host "- AI Health: http://localhost:5000/health" -ForegroundColor Gray
Write-Host "- Backend Health: http://localhost:8080/api/health" -ForegroundColor Gray
Write-Host "- Swagger: http://localhost:8080/swagger-ui/index.html" -ForegroundColor Gray

Write-Host "`nPress any key to stop all services..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
