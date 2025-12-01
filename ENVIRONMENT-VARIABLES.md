# FaceShare - Environment Variables Reference

Complete guide for all environment variables needed for deployment.

---

## Backend (Spring Boot)

### Required for Production

| Variable | Description | Example | How to Get |
|----------|-------------|---------|------------|
| `JWT_SECRET` | Secret key for JWT token signing | `abcd1234...` (64+ chars) | Generate with `openssl rand -base64 64` |
| `CLOUDINARY_URL` | Cloudinary connection string | `cloudinary://key:secret@cloud` | From https://console.cloudinary.com/ |
| `AI_SERVICE_URL` | URL of AI service | `http://ai-service.railway.internal:5000` | Railway internal URL after AI deployment |

### Auto-Provided by Railway (PostgreSQL)

| Variable | Description | Auto-Set |
|----------|-------------|----------|
| `PGHOST` | PostgreSQL hostname | ✅ Yes |
| `PGPORT` | PostgreSQL port | ✅ Yes |
| `PGDATABASE` | Database name | ✅ Yes |
| `PGUSER` | Database username | ✅ Yes |
| `PGPASSWORD` | Database password | ✅ Yes |

Railway maps these to Spring Boot format automatically:
- `SPRING_DATASOURCE_URL` = `jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}`
- `SPRING_DATASOURCE_USERNAME` = `${PGUSER}`
- `SPRING_DATASOURCE_PASSWORD` = `${PGPASSWORD}`

### Optional

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `PORT` | Server port | `8080` | Railway overrides automatically |
| `CORS_ALLOWED_ORIGINS` | Additional CORS origins | None | Comma-separated: `https://app.com,https://*.app.com` |
| `LOG_LEVEL` | Logging level | `INFO` | Options: DEBUG, INFO, WARN, ERROR |
| `SPRING_PROFILES_ACTIVE` | Spring profile | None | Options: dev, prod |
| `H2_CONSOLE_ENABLED` | Enable H2 console (dev only) | `false` | Set to `true` for local dev |

---

## AI Service (Python/Flask)

### Required for Production

| Variable | Description | Example | Default |
|----------|-------------|---------|---------|
| `PORT` | Server port | `5000` | Railway auto-sets |

### Optional

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `HOST` | Bind address | `0.0.0.0` | Don't change for Railway |
| `DEBUG` | Debug mode | `False` | Set to `True` only for local dev |
| `FLASK_ENV` | Flask environment | `production` | Options: development, production |
| `UPLOAD_FOLDER` | Temp upload directory | `/tmp/faceshare/uploads` | Railway has ephemeral filesystem |
| `TEMP_FOLDER` | Temp processing directory | `/tmp/faceshare/temp` | Cleaned on restart |
| `MAX_CONTENT_LENGTH` | Max upload size (bytes) | `16777216` (16MB) | Adjust if needed |
| `BACKEND_URL` | Backend service URL | `http://localhost:8080` | Usually not needed |

---

## Flutter App

### Build-Time Variable

The Flutter app uses `--dart-define` for environment configuration.

**Development Build:**
```bash
flutter build apk --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:8080
```

**Production Build:**
```bash
flutter build apk --dart-define=API_BASE_URL=https://faceshare-backend.up.railway.app
```

---

## Quick Setup Guide

### Step 1: Generate JWT Secret
```bash
# On Windows (PowerShell):
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# On Mac/Linux:
openssl rand -base64 64
```

### Step 2: Get Cloudinary URL
1. Sign up at https://cloudinary.com/users/register_free
2. Go to Dashboard
3. Copy the "API Environment variable" that looks like:
   ```
   CLOUDINARY_URL=cloudinary://123456789012345:abcdefghijklmnopqrstuvwxyz123@dxxxxxxxxxxxxx
   ```

### Step 3: Railway Deployment Order

**Deploy in this order:**

1. **PostgreSQL Database**
   - Use Railway's PostgreSQL template
   - No environment variables needed
   - Copy the connection details (automatically set as env vars)

2. **Backend Service**
   - Connect GitHub repo: `faceshare-app/backend`
   - Set environment variables:
     ```
     JWT_SECRET=<your-generated-secret>
     CLOUDINARY_URL=<your-cloudinary-url>
     ```
   - Railway auto-detects Spring Boot
   - Note the backend URL: `https://faceshare-backend.up.railway.app`

3. **AI Service**
   - Connect GitHub repo: `faceshare-app/ai-service`
   - No environment variables needed initially
   - Railway will build using Dockerfile
   - Note the internal URL: `ai-service.railway.internal`

4. **Update Backend with AI Service URL**
   - In Backend service settings, add:
     ```
     AI_SERVICE_URL=http://ai-service.railway.internal:5000
     ```
   - Trigger redeploy

---

## Local Development Setup

Create a `.env` file in the backend directory (copy from `.env.example`):

```bash
# Backend .env
CLOUDINARY_URL=cloudinary://...
JWT_SECRET=dev_secret_not_for_production
AI_SERVICE_URL=http://localhost:5000
H2_CONSOLE_ENABLED=true
```

Create a `.env` file in the ai-service directory:

```bash
# AI Service .env
HOST=0.0.0.0
PORT=5000
DEBUG=True
```

---

## Security Best Practices

### ✅ DO:
- ✅ Use strong, random JWT_SECRET (64+ characters)
- ✅ Rotate JWT_SECRET if ever exposed
- ✅ Use environment variables for ALL secrets
- ✅ Add `.env` to `.gitignore`
- ✅ Use different secrets for dev/staging/prod
- ✅ Enable HTTPS in production (Railway provides this automatically)

### ❌ DON'T:
- ❌ Commit secrets to Git
- ❌ Use the same secrets across environments
- ❌ Share secrets in chat/email
- ❌ Use default JWT_SECRET in production
- ❌ Enable DEBUG=True in production

---

## Troubleshooting

### Backend can't connect to database
**Problem:** `Connection refused` or `Unknown database`
**Solution:** Check that PostgreSQL service is deployed and `SPRING_DATASOURCE_*` variables are set

### Backend can't reach AI service
**Problem:** `Connection timeout` on `/detect-faces`
**Solution:** Use Railway internal URL: `http://ai-service.railway.internal:5000`, not the public URL

### Flutter app can't connect to backend
**Problem:** Network error or timeout
**Solution:**
- Development: Use your computer's local IP (192.168.x.x), not localhost
- Production: Use the Railway public URL with HTTPS
- Check CORS settings in SecurityConfig.java

### Cloudinary upload fails
**Problem:** `Cloudinary is not configured`
**Solution:** Set `CLOUDINARY_URL` environment variable with correct format

### Images return 404
**Problem:** `/api/photos/view/{id}` returns 404
**Solution:** With Cloudinary, frontend should use the direct URL from `photo.filePath`, not backend endpoint

---

## Environment Variable Checklist

Before deploying, ensure you have:

**Backend:**
- [ ] `JWT_SECRET` set (strong random value)
- [ ] `CLOUDINARY_URL` set (from Cloudinary dashboard)
- [ ] `AI_SERVICE_URL` set (Railway internal URL)
- [ ] PostgreSQL connected (auto-configured by Railway)

**AI Service:**
- [ ] No required variables (uses defaults)
- [ ] Models included in Docker image (det_10g.onnx, w600k_r50.onnx)

**Flutter:**
- [ ] Build command includes `--dart-define=API_BASE_URL=<production-url>`

**All Done?**
✅ Test login/register
✅ Test photo upload
✅ Test face detection (check Railway logs)
✅ Test photo sharing
