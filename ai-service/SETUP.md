# FaceShare AI Service Setup Guide

## Overview
You're using **InsightFace ONNX** - production-grade face recognition with 99.8%+ accuracy.

**Status:** FULLY WORKING ✓
- Detection: SCRFD (det_10g) - 95%+ accuracy
- Recognition: ArcFace (w600k_r50) - 99.8%+ accuracy
- 512-dimensional embeddings with cosine similarity matching

---

## Quick Start

### 1. Models are Downloaded ✓
Models are already in place:
- `models/det_10g.onnx` (16.14 MB)
- `models/w600k_r50.onnx` (166.31 MB)

### 2. Start AI Service

**Activate virtual environment:**

**PowerShell:**
```powershell
cd D:\faceshare-app\ai-service
.\venv\Scripts\Activate.ps1
python main.py
```

**CMD:**
```cmd
cd D:\faceshare-app\ai-service
venv\Scripts\activate.bat
python main.py
```

**Git Bash:**
```bash
cd /d/faceshare-app/ai-service
source venv/Scripts/activate
python main.py
```

You should see:
```
Initializing InsightFace ONNX models...
InsightFace ONNX initialized successfully!
  Detection model: det_10g.onnx
  Recognition model: w600k_r50.onnx
 * Running on http://127.0.0.1:5000
```

---

## Test Results (Your Images)

Tested successfully with 4 images:
- **me1.JPG**: Detected 2 faces ✓
- **me2.jpg**: Detected 1 face ✓
- **friend1.JPG**: Detected 1 face ✓
- **group.JPG**: Detected 7 faces ✓

**Face Matching Test:**
- me1.JPG vs me2.jpg: 59.2% similarity (MATCH) ✓
- Threshold: 40% (industry standard for ArcFace)

---

## API Endpoints

**Health Check:**
```bash
GET http://127.0.0.1:5000/
```

**Detect Faces:**
```bash
POST http://127.0.0.1:5000/detect-faces
Content-Type: multipart/form-data
Body: image=<file>

Response:
{
  "faces_detected": 1,
  "face_locations": [[x1, y1, x2, y2]],
  "face_encodings": [[512-dim array]],
  "landmarks": [[[x,y], [x,y], ...]]
}
```

**Compare Faces:**
```bash
POST http://127.0.0.1:5000/compare-faces
Content-Type: application/json
Body: {
  "embedding1": [512-dim array],
  "embedding2": [512-dim array],
  "threshold": 0.4
}

Response:
{
  "similarity": 0.5917,
  "distance": 0.4083,
  "is_match": true,
  "threshold": 0.4
}
```

**Match Faces (for backend integration):**
```bash
POST http://127.0.0.1:5000/match-faces
Content-Type: application/json
Body: {
  "detected_encodings": [[512-dim arrays]],
  "known_encodings": [[512-dim arrays]],
  "user_ids": [1, 2, 3],
  "threshold": 0.4
}

Response:
{
  "matches": [{"user_id": 1, "similarity": 0.65}],
  "total_detected": 2,
  "total_matched": 1
}
```

---

## Troubleshooting

**Issue: PowerShell script execution disabled**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue: Port 5000 already in use**
```bash
# Kill existing process on port 5000
netstat -ano | findstr :5000
taskkill /PID <process_id> /F
```

---

## Performance

- **Detection Speed:** ~100-200ms per image (CPU)
- **Recognition Speed:** ~50ms per face (CPU)
- **Accuracy:** 99.8%+ (LFW benchmark)
- **Max Image Size:** 1280px (auto-resized)
- **Embedding Size:** 512 dimensions
- **Recommended Threshold:** 0.4 for ArcFace

---

## Next Steps

1. ✓ Models downloaded and verified
2. ✓ AI service tested with your images
3. ⏳ Integrate with Spring Boot backend
4. ⏳ Deploy to Railway.app
5. ⏳ Test with beta users
