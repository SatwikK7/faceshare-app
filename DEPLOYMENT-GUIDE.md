# FaceShare - Deployment Preparation Guide

**Goal:** Prepare codebase for production deployment to Railway.app with cloud services

---

## PHASE 1: Create Cloud Service Accounts

### Step 1.1: Railway.app Account (Free Tier)

**What:** Hosting platform for backend, AI service, and PostgreSQL database

**Sign Up:**
1. Go to: https://railway.app
2. Click "Login" → "Login with GitHub"
3. Authorize Railway to access your GitHub
4. You get: $5 free credit/month (enough for hobby project)

**What you'll deploy:**
- Spring Boot Backend
- Python AI Service
- PostgreSQL Database

**DO NOT CREATE SERVICES YET** - We'll do this after code is ready

---

### Step 1.2: Cloudinary Account (Free Tier)

**What:** Cloud image storage and CDN (replaces local ./uploads/ folder)

**Sign Up:**
1. Go to: https://cloudinary.com/users/register_free
2. Register with email
3. Verify email
4. Free tier includes:
   - 25 GB storage
   - 25 GB bandwidth/month
   - Perfect for beta testing

**After Sign Up:**
1. Go to Dashboard: https://console.cloudinary.com/
2. Find your credentials (top of page):
   ```
   Cloud Name: dxxxxxxxxxxxxx
   API Key: 123456789012345
   API Secret: abcdefghijklmnopqrstuvwxyz123
   ```
3. **SAVE THESE** - You'll need them for backend configuration

**Copy This Format:**
```
CLOUDINARY_URL=cloudinary://123456789012345:abcdefghijklmnopqrstuvwxyz123@dxxxxxxxxxxxxx
```

---

## PHASE 2: Backend Modifications

### Changes Overview:
1. ✅ Replace H2 database with PostgreSQL
2. ✅ Replace local file storage with Cloudinary
3. ✅ All configs use environment variables
4. ✅ Production-ready CORS settings
5. ✅ Remove hardcoded paths

---

### Files to Modify:

#### File 1: `backend/pom.xml`
**Changes:**
- Remove H2 dependency
- Add PostgreSQL driver
- Add Cloudinary SDK

#### File 2: `backend/src/main/resources/application.yml`
**Changes:**
- Database: PostgreSQL with env vars
- File storage: Remove local paths
- AI service: Use env var for URL
- JWT secret: Use env var

#### File 3: `backend/src/main/java/com/faceshare/service/FileStorageService.java`
**Changes:**
- Replace local file operations with Cloudinary upload/delete
- Return Cloudinary URLs instead of local paths

#### File 4: `backend/src/main/java/com/faceshare/controller/PhotoController.java`
**Changes:**
- viewPhoto() should redirect to Cloudinary URL instead of serving local file

#### File 5: `backend/src/main/java/com/faceshare/config/SecurityConfig.java`
**Changes:**
- Update CORS to allow production domain
- Add environment-based allowed origins

#### File 6: `backend/src/main/java/com/faceshare/model/Photo.java`
**Changes:**
- filePath should store Cloudinary URL (not ./uploads/...)

---

## PHASE 3: AI Service Modifications

### Changes Overview:
1. ✅ Create Dockerfile for Railway deployment
2. ✅ Use environment variables for PORT
3. ✅ Add gunicorn for production server
4. ✅ Ensure ONNX models are included in deployment

---

### Files to Create/Modify:

#### File 1: `ai-service/Dockerfile` (NEW)
**Purpose:** Package AI service with models for Railway

#### File 2: `ai-service/requirements.txt`
**Changes:**
- Add gunicorn (production WSGI server)

#### File 3: `ai-service/main.py`
**Changes:**
- Read PORT from environment variable
- Production-ready Flask configuration

#### File 4: `ai-service/.dockerignore` (NEW)
**Purpose:** Exclude test files from Docker build

---

## PHASE 4: Frontend Modifications

### Changes Overview:
1. ✅ Use environment variable for API URL
2. ✅ Remove hardcoded IP addresses
3. ✅ Prepare build scripts for production APK

---

### Files to Modify:

#### File 1: `frontend/lib/utils/constants.dart`
**Changes:**
- Use environment variable for baseUrl
- Remove hardcoded 192.168.x.x IP

#### File 2: Create build script for easy production builds

---

## PHASE 5: Environment Variables Setup

### Backend Environment Variables (Railway)

```bash
# Database (Railway PostgreSQL - auto-provided)
SPRING_DATASOURCE_URL=jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}
SPRING_DATASOURCE_USERNAME=${PGUSER}
SPRING_DATASOURCE_PASSWORD=${PGPASSWORD}

# Cloudinary (from your Cloudinary dashboard)
CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME

# JWT Security (generate random 64-char string)
JWT_SECRET=<generate-with-command-below>

# AI Service URL (Railway internal networking)
AI_SERVICE_URL=http://ai-service.railway.internal:5000

# Server Port (Railway sets this automatically)
PORT=8080
```

**Generate JWT Secret:**
```bash
# On Windows (PowerShell):
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# On Mac/Linux:
openssl rand -base64 64 | tr -d '\n'
```

---

### AI Service Environment Variables (Railway)

```bash
# Port (Railway sets this automatically)
PORT=5000

# Flask Config
HOST=0.0.0.0
DEBUG=False
FLASK_ENV=production
```

---

## PHASE 6: Deployment Checklist

### Pre-Deployment Testing:

- [ ] Backend connects to PostgreSQL locally (using Docker)
- [ ] Cloudinary upload works (test with Postman)
- [ ] AI service responds to /detect-faces
- [ ] Flutter app can login/register
- [ ] Flutter app can upload photo
- [ ] Photo appears in Cloudinary dashboard
- [ ] Face detection triggers and creates shared_photos
- [ ] Shared photos appear in Flutter app

### Railway Deployment Order:

1. **Deploy PostgreSQL Database**
   - Use Railway PostgreSQL template
   - Copy connection details

2. **Deploy Backend**
   - Push to GitHub
   - Connect Railway to GitHub repo
   - Set all environment variables
   - Railway auto-detects Spring Boot

3. **Deploy AI Service**
   - Push to GitHub (including models in Git LFS or build step)
   - Connect Railway to GitHub repo
   - Set environment variables
   - Use Dockerfile for deployment

4. **Update Backend AI_SERVICE_URL**
   - Set to Railway internal URL
   - Redeploy backend

5. **Build Flutter APK**
   - Build with production API URL
   - Test on physical device
   - Share with beta testers

---

## PHASE 7: Post-Deployment Verification

### Test Flow:
1. Install APK on Android phone
2. Register new account → Check PostgreSQL (users table)
3. Login → Receive JWT token
4. Upload photo with face → Check Cloudinary dashboard
5. Wait 5-10 seconds → Check backend logs (AI service called)
6. Check PostgreSQL → face_encodings table should have entry
7. Upload another photo of same person → Auto-sharing should trigger
8. Check "Shared Photos" tab → Photo should appear
9. Click photo → Opens from Cloudinary URL

---

## Important Notes

### Security Considerations:
1. **NEVER commit credentials** to Git
2. **Use .env files locally** (add to .gitignore)
3. **Use Railway environment variables** for production
4. **Rotate JWT secret** if ever exposed

### Cost Management:
- Railway: $5 free credit/month
- Cloudinary: Free tier (25GB)
- PostgreSQL: Included in Railway
- **Total cost: $0/month** for hobby usage

### Limitations (Free Tier):
- Railway: 500 hours/month (single service can run 24/7)
- Cloudinary: 25GB bandwidth (enough for ~5000 image views/month)
- PostgreSQL: 1GB storage (enough for thousands of photos metadata)

---

## Next Steps

After this guide, I will:
1. Modify all backend files with environment variables
2. Create Cloudinary integration
3. Create AI service Dockerfile
4. Update Flutter configuration
5. Create deployment scripts

**Ready to proceed with code modifications?**
