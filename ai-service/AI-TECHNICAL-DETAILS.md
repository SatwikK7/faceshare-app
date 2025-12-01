# FaceShare AI - Technical Details

## Architecture Overview

```
Image → SCRFD Detection → Face Alignment → ArcFace Recognition → 512-D Embedding
```

---

## Models Used

### 1. Detection: SCRFD (Sample and Computation Redistribution for Efficient Face Detection)

**Model File:** `models/det_10g.onnx` (16.14 MB)

**What it does:**
- Detects faces in images and returns bounding boxes
- Extracts 5 facial landmarks (2 eyes, nose, 2 mouth corners)
- Works at multiple scales for faces of different sizes

**Technical Details:**
- Architecture: Feature Pyramid Network (FPN) with 3 scales
  - Stride 8: Detects small faces (80×80 grid = 12,800 anchors)
  - Stride 16: Detects medium faces (40×40 grid = 3,200 anchors)
  - Stride 32: Detects large faces (20×20 grid = 800 anchors)
- 2 anchors per grid location = 16,800 total anchor boxes
- Input size: 640×640 pixels (images resized before detection)
- Output: Scores, bounding boxes, 5 landmarks per detected face

**Parameters:**
- Detection threshold: 0.3 (confidence score to accept a detection)
- NMS threshold: 0.4 (removes duplicate detections)

**Accuracy:** ~95% on WIDER FACE benchmark

---

### 2. Recognition: ArcFace (Additive Angular Margin Loss)

**Model File:** `models/w600k_r50.onnx` (166.31 MB)

**What it does:**
- Takes an aligned 112×112 face image
- Produces a 512-dimensional embedding (unique "fingerprint" for that face)
- Embeddings from same person have high cosine similarity (>0.7)
- Embeddings from different people have low similarity (<0.4)

**Technical Details:**
- Backbone: ResNet-50 (50-layer deep neural network)
- Training data: WebFace600K dataset (~600,000 identities)
- Input: 112×112×3 RGB image (normalized to [-1, 1])
- Output: 512-dimensional vector (L2-normalized to unit length)

**Preprocessing:**
```python
# Convert BGR → RGB
# Normalize: (pixel - 127.5) / 127.5  →  range [-1, 1]
# Create NCHW format: (1, 3, 112, 112)
```

**Accuracy:** 99.8%+ on LFW (Labeled Faces in the Wild) benchmark

---

## Pipeline Steps

### Step 1: Image Preprocessing
```python
# Load image
img = cv2.imread(image_path)  # BGR format

# Resize if too large (>1280px) to prevent memory issues
if max(height, width) > 1280:
    scale = 1280 / max(height, width)
    img = cv2.resize(img, new_size)
```

### Step 2: Face Detection (SCRFD)
```python
# Resize to 640×640 for detection
img_resized = cv2.resize(img, (640, 640))

# Normalize: (pixel - 127.5) / 128.0  →  range ~[-1, 1]
blob = cv2.dnn.blobFromImage(img_resized, 1.0/128.0, (640, 640), (127.5, 127.5, 127.5))

# Run SCRFD
outputs = detection_model.run(blob)
# Returns: 9 output tensors (3 scales × 3 types)
#   - Scores: [12800, 1], [3200, 1], [800, 1]
#   - Bboxes: [12800, 4], [3200, 4], [800, 4]
#   - Landmarks: [12800, 10], [3200, 10], [800, 10]

# Parse outputs
for each scale (stride 8, 16, 32):
    # Generate anchor centers
    anchor_centers = generate_grid(height, width, stride)

    # Filter by threshold (0.3)
    valid_detections = scores >= 0.3

    # Convert distance predictions to bounding boxes
    x1 = anchor_x - distance_left * stride
    y1 = anchor_y - distance_top * stride
    x2 = anchor_x + distance_right * stride
    y2 = anchor_y + distance_bottom * stride

    # Convert distance predictions to landmarks (5 points × 2 coords = 10 values)
    for each landmark:
        lm_x = anchor_x + offset_x * stride
        lm_y = anchor_y + offset_y * stride

# Apply NMS (Non-Maximum Suppression) to remove duplicates
final_faces = nms(all_detections, threshold=0.4)

# Scale back to original image size
bbox = bbox * [scale_x, scale_y, scale_x, scale_y]
landmarks = landmarks * [scale_x, scale_y]
```

### Step 3: Face Alignment
```python
# Standard ArcFace template (5 landmark positions for 112×112 face)
template = [
    [38.2946, 51.6963],  # Left eye
    [73.5318, 51.5014],  # Right eye
    [56.0252, 71.7366],  # Nose
    [41.5493, 92.3655],  # Left mouth corner
    [70.7299, 92.2041]   # Right mouth corner
]

# Estimate similarity transform (rotation + scale + translation)
# using scikit-image SimilarityTransform
tform = SimilarityTransform()
tform.estimate(detected_landmarks, template)

# Apply transform to get 112×112 aligned face
aligned_face = cv2.warpAffine(img, tform.params[0:2,:], (112, 112))
```

### Step 4: Embedding Extraction (ArcFace)
```python
# Normalize aligned face
blob = cv2.dnn.blobFromImage(aligned_face, 1.0/127.5, (112, 112), (127.5, 127.5, 127.5))
# Result: range [-1, 1], shape (1, 3, 112, 112)

# Run ArcFace model
embedding = recognition_model.run(blob)  # Shape: (1, 512)

# L2 normalize to unit vector
embedding = embedding / ||embedding||
# Now: ||embedding|| = 1.0
```

### Step 5: Face Matching
```python
# Cosine similarity (since both embeddings are unit vectors, this is just dot product)
similarity = embedding1 · embedding2

# Threshold-based matching
if similarity >= 0.4:
    # SAME PERSON
else:
    # DIFFERENT PEOPLE

# Similarity ranges:
# 0.7 - 1.0: Very high confidence (same person)
# 0.5 - 0.7: Medium confidence (likely same person)
# 0.4 - 0.5: Low confidence (possibly same person)
# 0.0 - 0.4: Different people
```

---

## Current Performance

**Detection:**
- ✓ Group photo: 8 faces detected (threshold 0.3)
- ✓ Individual photos: 1-2 faces detected
- Speed: ~100-200ms per image (CPU)

**Recognition:**
- Embedding size: 512 dimensions
- L2 norm: 1.0 (unit vector)
- Speed: ~50ms per face (CPU)

**Matching Accuracy:**
- Same person: 57.3% similarity (WORKS, but lower than ideal 70-80%)
- Different people: 36.5% similarity (correctly below threshold)
- Threshold: 40% (works correctly for match/no-match decision)

---

## Known Issues & Potential Improvements

### Issue 1: Low Same-Person Similarity (57% instead of 70-80%)

**Possible Causes:**
1. **Wrong model version** - May have downloaded wrong ArcFace variant
2. **Preprocessing mismatch** - Model may expect different normalization
3. **Alignment issues** - Face alignment not perfectly matching training
4. **Model quality** - w600k_r50 may be lower quality than glint360k

**Potential Solutions:**

**A. Try Different ArcFace Model:**
```
Current: w600k_r50.onnx (WebFace600K, ResNet-50)
Better options:
  - glint360k_r100.onnx (Glint360K, ResNet-100) - Higher accuracy
  - buffalo_l.onnx (Latest InsightFace model pack)
```

**B. Use Official InsightFace Library:**
```python
# Instead of manual ONNX loading
from insightface.app import FaceAnalysis
app = FaceAnalysis(providers=['CPUExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640, 640))
```
Pros: Battle-tested, proven accuracy
Cons: Requires Visual Studio Build Tools (~7GB)

**C. Check Preprocessing:**
Current normalization might be wrong. Try:
```python
# Option 1 (current): pixel range [-1, 1]
blob = (pixel - 127.5) / 127.5

# Option 2: pixel range [0, 1]
blob = pixel / 255.0

# Option 3: ImageNet normalization
mean = [0.485, 0.456, 0.406]
std = [0.229, 0.224, 0.225]
blob = (pixel/255 - mean) / std
```

**D. Improve Alignment:**
- Try different landmark detection models (RetinaFace instead of SCRFD)
- Use more landmarks (68 points instead of 5)
- Try affine transform instead of similarity transform

---

### Issue 2: Detection Threshold Trade-off

**Current:** threshold = 0.3
- Detects 8 faces in group photo ✓
- But may include false positives

**Options:**
- Lower (0.2): More faces detected, more false positives
- Higher (0.5): Fewer false positives, may miss some faces

---

## Recommended Next Steps

1. **Test with different threshold** (0.25) to see if more real faces detected
2. **Try glint360k_r100 model** if available as free ONNX download
3. **Compare with official InsightFace library** (need Visual Studio Build Tools)
4. **Test preprocessing variations** (different normalizations)
5. **Benchmark against known face recognition datasets** (LFW, YTF)

---

## References

- SCRFD Paper: https://arxiv.org/abs/2105.04714
- ArcFace Paper: https://arxiv.org/abs/1801.07698
- InsightFace GitHub: https://github.com/deepinsight/insightface
- Model Downloads: https://github.com/deepinsight/insightface/tree/master/model_zoo
