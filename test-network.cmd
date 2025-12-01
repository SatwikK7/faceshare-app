@echo off
echo === FaceShare Network Diagnostic ===
echo.

echo Step 1: Getting your IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP:~1!
    echo Your IP: !IP!
)

echo.
echo Step 2: Testing localhost backend...
curl -s http://localhost:8080/api/health
if %errorlevel% neq 0 (
    echo [ERROR] Backend not running on localhost!
    echo Please start backend: cd backend ^& mvn spring-boot:run
    exit /b 1
)
echo [OK] Backend running on localhost

echo.
echo Step 3: Testing network access...
curl -s http://192.168.29.74:8080/api/health
if %errorlevel% neq 0 (
    echo [ERROR] Backend not accessible from network!
    echo This is a FIREWALL issue.
    echo Run as Administrator: netsh advfirewall firewall add rule name="FaceShare Backend" dir=in action=allow protocol=TCP localport=8080
    exit /b 1
)
echo [OK] Backend accessible from network

echo.
echo Step 4: Checking firewall rules...
netsh advfirewall firewall show rule name="FaceShare Backend" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Firewall rule not found
    echo Run as Administrator: netsh advfirewall firewall add rule name="FaceShare Backend" dir=in action=allow protocol=TCP localport=8080
) else (
    echo [OK] Firewall rule exists
)

echo.
echo === Diagnostic Complete ===
echo.
echo Next steps:
echo 1. Make sure phone and computer are on SAME WiFi
echo 2. Test from phone browser: http://192.168.29.74:8080/api/health
echo 3. Restart Flutter app: cd frontend ^& flutter run
