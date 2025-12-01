#!/usr/bin/env python3
"""
FaceShare AI Service
Handles face detection, recognition, and matching for the FaceShare application.
"""

import os
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import requests

from config.settings import Config
# from services.insightface_onnx import InsightFaceONNX  # Real AI service (requires models)
from services.dummy_face_service import DummyFaceService  # Mock service for testing
from utils.image_utils import allowed_file, save_uploaded_file
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)
CORS(app)

# Initialize Face Recognition Service
# Using DUMMY service for testing (no models required)
# TODO: Replace with InsightFaceONNX once models are available
USE_DUMMY = os.getenv('USE_DUMMY_AI', 'true').lower() == 'true'

if USE_DUMMY:
    logger.warning("=" * 60)
    logger.warning("⚠️  USING DUMMY AI SERVICE - NOT REAL FACE DETECTION!")
    logger.warning("⚠️  This is for testing the full app flow only")
    logger.warning("⚠️  Set USE_DUMMY_AI=false to use real InsightFace")
    logger.warning("=" * 60)
    insightface = DummyFaceService()
else:
    from services.insightface_onnx import InsightFaceONNX
    MODEL_DIR = "models"
    DET_MODEL = os.path.join(MODEL_DIR, "det_10g.onnx")
    REC_MODEL = os.path.join(MODEL_DIR, "w600k_r50.onnx")
    insightface = InsightFaceONNX(
        det_model_path=DET_MODEL,
        rec_model_path=REC_MODEL
    )

@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint"""
    if USE_DUMMY:
        return jsonify({
            'status': 'healthy',
            'service': 'FaceShare AI Service (TESTING MODE)',
            'version': '2.0.0-dummy',
            'engine': 'Dummy/Mock Service',
            'detection_model': 'FAKE - Random detection',
            'recognition_model': 'FAKE - Random embeddings',
            'accuracy': 'N/A - Not real AI',
            'warning': 'This is a mock service for testing. Set USE_DUMMY_AI=false for real face detection.'
        })
    else:
        return jsonify({
            'status': 'healthy',
            'service': 'FaceShare AI Service',
            'version': '2.0.0',
            'engine': 'InsightFace ONNX',
            'detection_model': 'SCRFD (det_10g)',
            'recognition_model': 'ArcFace (w600k_r50)',
            'accuracy': '99.8%+ (LFW benchmark)'
        })

@app.route('/detect-faces', methods=['POST'])
def detect_faces():
    """
    Detect faces in an uploaded image
    Returns: List of face locations, landmarks, and embeddings
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type'}), 400

        # Save uploaded file temporarily
        temp_path = save_uploaded_file(file)

        try:
            # Process the image with InsightFace ONNX
            logger.info(f"Processing image: {file.filename}")
            result = insightface.process_image(temp_path)

            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)

            logger.info(f"Detected {result['faces_detected']} face(s)")
            return jsonify(result)

        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e

    except Exception as e:
        logger.error(f"Error in face detection: {str(e)}")
        return jsonify({'error': f'Face detection failed: {str(e)}'}), 500

@app.route('/compare-faces', methods=['POST'])
def compare_faces():
    """
    Compare two face embeddings to check if they match
    """
    try:
        data = request.get_json()

        embedding1 = np.array(data.get('embedding1'))
        embedding2 = np.array(data.get('embedding2'))
        threshold = data.get('threshold', 0.4)

        similarity, is_match = insightface.compare_faces(
            embedding1, embedding2, threshold
        )

        return jsonify({
            'similarity': float(similarity),
            'distance': float(1.0 - similarity),
            'is_match': bool(is_match),
            'threshold': threshold
        })

    except Exception as e:
        logger.error(f"Error comparing faces: {str(e)}")
        return jsonify({'error': f'Face comparison failed: {str(e)}'}), 500

@app.route('/match-faces', methods=['POST'])
def match_faces():
    """
    Match detected faces against known face encodings (for backend integration)
    """
    try:
        data = request.get_json()

        detected_encodings = [np.array(enc) for enc in data.get('detected_encodings', [])]
        known_encodings = [np.array(enc) for enc in data.get('known_encodings', [])]
        user_ids = data.get('user_ids', [])
        threshold = data.get('threshold', 0.4)

        matches = []
        for detected_enc in detected_encodings:
            best_match = None
            best_similarity = -1

            for idx, known_enc in enumerate(known_encodings):
                similarity, is_match = insightface.compare_faces(
                    detected_enc, known_enc, threshold
                )

                if is_match and similarity > best_similarity:
                    best_similarity = similarity
                    best_match = user_ids[idx] if idx < len(user_ids) else None

            if best_match is not None:
                matches.append({
                    'user_id': best_match,
                    'similarity': float(best_similarity)
                })

        return jsonify({
            'matches': matches,
            'total_detected': len(detected_encodings),
            'total_matched': len(matches)
        })

    except Exception as e:
        logger.error(f"Error matching faces: {str(e)}")
        return jsonify({'error': f'Face matching failed: {str(e)}'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Create necessary directories
    os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
    os.makedirs(Config.TEMP_FOLDER, exist_ok=True)
    
    logger.info("Starting FaceShare AI Service...")
    logger.info(f"Upload folder: {Config.UPLOAD_FOLDER}")
    logger.info(f"Temp folder: {Config.TEMP_FOLDER}")
    
    # Run the application
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )