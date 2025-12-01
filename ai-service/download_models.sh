#!/bin/bash
# Download ONNX models on Railway deployment
# This runs before the Docker container starts

set -e

echo "====== ONNX Model Download Script ======"

MODELS_DIR="models"
mkdir -p "$MODELS_DIR"

# Correct URLs from InsightFace model zoo
# These are hosted on Hugging Face and are reliable
DET_MODEL_URL="${DET_MODEL_URL:-https://huggingface.co/deepinsight/inswapper/resolve/main/det_10g.onnx}"
REC_MODEL_URL="${REC_MODEL_URL:-https://huggingface.co/deepinsight/inswapper/resolve/main/w600k_r50.onnx}"

download_model() {
    local url=$1
    local output=$2
    local name=$3

    echo "Downloading $name..."
    echo "URL: $url"

    # Download with progress and fail on error
    if curl -L --fail --progress-bar -o "$output" "$url"; then
        local size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null || echo "unknown")
        echo "✓ $name downloaded successfully (size: $size bytes)"

        # Verify it's not an HTML error page
        if file "$output" | grep -q "HTML"; then
            echo "ERROR: Downloaded file is HTML (probably 404 error)"
            rm "$output"
            return 1
        fi

        return 0
    else
        echo "ERROR: Failed to download $name"
        return 1
    fi
}

# Download detection model
if [ -f "$MODELS_DIR/det_10g.onnx" ]; then
    echo "Detection model already exists, skipping download"
else
    if ! download_model "$DET_MODEL_URL" "$MODELS_DIR/det_10g.onnx" "Detection model (det_10g.onnx)"; then
        echo "FATAL: Could not download detection model"
        exit 1
    fi
fi

# Download recognition model
if [ -f "$MODELS_DIR/w600k_r50.onnx" ]; then
    echo "Recognition model already exists, skipping download"
else
    if ! download_model "$REC_MODEL_URL" "$MODELS_DIR/w600k_r50.onnx" "Recognition model (w600k_r50.onnx)"; then
        echo "FATAL: Could not download recognition model"
        exit 1
    fi
fi

echo "====== All models ready! ======"
ls -lh "$MODELS_DIR"
