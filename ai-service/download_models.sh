#!/bin/bash
# Download ONNX models on Railway deployment
# This runs before the Docker container starts

set -e

echo "Checking for ONNX models..."

MODELS_DIR="models"
mkdir -p "$MODELS_DIR"

# Model URLs (replace with your actual URLs)
DET_MODEL_URL="${DET_MODEL_URL:-https://github.com/deepinsight/insightface/releases/download/v0.7/det_10g.onnx}"
REC_MODEL_URL="${REC_MODEL_URL:-https://github.com/deepinsight/insightface/releases/download/v0.7/w600k_r50.onnx}"

# Download detection model if not exists
if [ ! -f "$MODELS_DIR/det_10g.onnx" ]; then
    echo "Downloading detection model (det_10g.onnx)..."
    curl -L -o "$MODELS_DIR/det_10g.onnx" "$DET_MODEL_URL"
    echo "Detection model downloaded"
else
    echo "Detection model already exists"
fi

# Download recognition model if not exists
if [ ! -f "$MODELS_DIR/w600k_r50.onnx" ]; then
    echo "Downloading recognition model (w600k_r50.onnx)..."
    curl -L -o "$MODELS_DIR/w600k_r50.onnx" "$REC_MODEL_URL"
    echo "Recognition model downloaded"
else
    echo "Recognition model already exists"
fi

echo "All models ready!"
