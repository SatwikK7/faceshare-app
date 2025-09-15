Write-Host "=== FaceShare Backend Basic Tests ===" -ForegroundColor Green

$baseUrl = "http://localhost:8080"

Write-Host "Testing backend at: $baseUrl" -ForegroundColor Cyan

Write-Host "`n1. Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/api/health" -Method GET
    Write-Host "SUCCESS: Health check passed" -ForegroundColor Green
    Write-Host "Status: $($health.status)" -ForegroundColor Cyan
}
catch {
    Write-Host "FAILED: Health check failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Testing Swagger UI..." -ForegroundColor Yellow
try {
    $swagger = Invoke-WebRequest -Uri "$baseUrl/swagger-ui/index.html" -Method GET -UseBasicParsing
    Write-Host "SUCCESS: Swagger UI accessible" -ForegroundColor Green
}
catch {
    Write-Host "FAILED: Swagger UI not accessible" -ForegroundColor Red
}

Write-Host "`n3. Testing H2 Console..." -ForegroundColor Yellow
try {
    $h2 = Invoke-WebRequest -Uri "$baseUrl/h2-console" -Method GET -UseBasicParsing
    Write-Host "SUCCESS: H2 Console accessible" -ForegroundColor Green
}
catch {
    Write-Host "FAILED: H2 Console not accessible" -ForegroundColor Red
}

Write-Host "`n4. Testing User Login..." -ForegroundColor Yellow
$loginData = '{"email":"alice@example.com","password":"password"}'
try {
    $login = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    Write-Host "SUCCESS: Login worked" -ForegroundColor Green
    Write-Host "User: $($login.fullName)" -ForegroundColor Cyan
    $token = $login.token
}
catch {
    Write-Host "FAILED: Login failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    $token = $null
}

if ($token) {
    Write-Host "`n5. Testing Protected Endpoints..." -ForegroundColor Yellow
    $headers = @{"Authorization" = "Bearer $token"}
    
    # Test current user endpoint
    try {
        $user = Invoke-RestMethod -Uri "$baseUrl/api/auth/me" -Method GET -Headers $headers
        Write-Host "SUCCESS: Get current user works" -ForegroundColor Green
        Write-Host "Current user: $($user.fullName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "FAILED: Get current user failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test photos endpoint
    try {
        $photos = Invoke-RestMethod -Uri "$baseUrl/api/photos/my-photos" -Method GET -Headers $headers
        Write-Host "SUCCESS: Get photos works" -ForegroundColor Green
        Write-Host "Photos count: $($photos.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "FAILED: Get photos failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test users endpoint
    try {
        $userProfile = Invoke-RestMethod -Uri "$baseUrl/api/users/me" -Method GET -Headers $headers
        Write-Host "SUCCESS: Users endpoint works" -ForegroundColor Green
        Write-Host "Profile: $($userProfile.fullName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "FAILED: Users endpoint failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test token refresh
    try {
        $refreshed = Invoke-RestMethod -Uri "$baseUrl/api/auth/refresh" -Method POST -Headers $headers
        Write-Host "SUCCESS: Token refresh works" -ForegroundColor Green
        Write-Host "New token received" -ForegroundColor Cyan
    }
    catch {
        Write-Host "FAILED: Token refresh failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Test 6: User Registration
Write-Host "`n6. Testing User Registration..." -ForegroundColor Yellow
$newUserEmail = "newuser$(Get-Random)@example.com"
$registerJson = "{`"email`":`"$newUserEmail`",`"password`":`"newpassword123`",`"fullName`":`"New Test User`"}"

try {
    $newUser = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -Body $registerJson -ContentType "application/json"
    Write-Host "SUCCESS: User registration works" -ForegroundColor Green
    Write-Host "New user: $($newUser.fullName) ($($newUser.email))" -ForegroundColor Cyan
}
catch {
    Write-Host "FAILED: User registration failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 7: Error Handling
Write-Host "`n7. Testing Error Handling..." -ForegroundColor Yellow

# Test invalid login
$invalidLoginJson = "{`"email`":`"invalid@example.com`",`"password`":`"wrongpassword`"}"
try {
    $invalidLogin = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $invalidLoginJson -ContentType "application/json"
    Write-Host "FAILED: Invalid login should have failed" -ForegroundColor Red
}
catch {
    Write-Host "SUCCESS: Invalid login properly rejected" -ForegroundColor Green
}

# Test unauthorized access
try {
    $unauthorized = Invoke-RestMethod -Uri "$baseUrl/api/photos/my-photos" -Method GET
    Write-Host "FAILED: Unauthorized access should have failed" -ForegroundColor Red
}
catch {
    Write-Host "SUCCESS: Unauthorized access properly blocked" -ForegroundColor Green
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Green
Write-Host "Backend URL: $baseUrl" -ForegroundColor White
Write-Host "Swagger UI: $baseUrl/swagger-ui/index.html" -ForegroundColor White
Write-Host "H2 Console: $baseUrl/h2-console" -ForegroundColor White
Write-Host "  JDBC URL: jdbc:h2:file:./data/faceshare" -ForegroundColor Gray
Write-Host "  Username: sa" -ForegroundColor Gray
Write-Host "  Password: password" -ForegroundColor Gray

if ($token) {
    Write-Host "`nTest Credentials:" -ForegroundColor Cyan
    Write-Host "Email: alice@example.com" -ForegroundColor Gray
    Write-Host "Password: password" -ForegroundColor Gray
    Write-Host "`nJWT Token (for manual testing):" -ForegroundColor Cyan
    Write-Host "$token" -ForegroundColor Gray
}

Write-Host "`n🎉 Backend testing completed!" -ForegroundColor Green