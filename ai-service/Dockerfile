# AI Service Dockerfile for Railway Deployment
# Based on Python 3.10 slim image for minimal size

FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies for OpenCV and ONNX
RUN apt-get update && apt-get install -y \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    libglvnd0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better layer caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY config/ ./config/
COPY services/ ./services/
COPY utils/ ./utils/
COPY main.py .
COPY download_models.sh .

# Download ONNX models (not in git due to size)
# Alternative: Set DET_MODEL_URL and REC_MODEL_URL env vars to custom URLs
RUN chmod +x download_models.sh && bash download_models.sh

# Create directories for temporary files
RUN mkdir -p /tmp/faceshare/uploads /tmp/faceshare/temp

# Expose port (Railway will override with $PORT)
EXPOSE 5000

# Use gunicorn for production
# --bind 0.0.0.0:$PORT - Listen on all interfaces on Railway's assigned port
# --workers 2 - Use 2 worker processes (adjust based on Railway plan)
# --timeout 120 - Allow 2 minutes for face processing
# --worker-class sync - Use synchronous workers (ONNX doesn't work well with async)
CMD gunicorn --bind 0.0.0.0:${PORT:-5000} \
    --workers 2 \
    --timeout 120 \
    --worker-class sync \
    --access-logfile - \
    --error-logfile - \
    main:app
