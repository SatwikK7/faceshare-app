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
from services.face_recognition_service import FaceRecognitionService
from services.face_detection import FaceDetectionService
from services.image_processor import ImageProcessor
from utils.image_utils import allowed_file, save_uploaded_file

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

# Initialize services
face_recognition_service = FaceRecognitionService()
face_detection_service = FaceDetectionService()
image_processor = ImageProcessor()

@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'FaceShare AI Service',
        'version': '1.0.0'
    })

@app.route('/detect-faces', methods=['POST'])
def detect_faces():
    """
    Detect faces in an uploaded image
    Returns: List of face locations and encodings
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
            # Process the image
            result = face_detection_service.detect_faces(temp_path)
            
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
            return jsonify(result)
        
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e
    
    except Exception as e:
        logger.error(f"Error in face detection: {str(e)}")
        return jsonify({'error': f'Face detection failed: {str(e)}'}), 500

@app.route('/recognize-faces', methods=['POST'])
def recognize_faces():
    """
    Recognize faces in an uploaded image against known face encodings
    """
    try:
        # Get the image file
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type'}), 400
        
        # Get known face encodings from request (sent by backend)
        known_encodings = request.form.get('known_encodings', '[]')
        user_ids = request.form.get('user_ids', '[]')
        
        # Save uploaded file temporarily
        temp_path = save_uploaded_file(file)
        
        try:
            # Recognize faces
            result = face_recognition_service.recognize_faces(
                temp_path, known_encodings, user_ids
            )
            
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
            return jsonify(result)
        
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e
    
    except Exception as e:
        logger.error(f"Error in face recognition: {str(e)}")
        return jsonify({'error': f'Face recognition failed: {str(e)}'}), 500

@app.route('/process-photo', methods=['POST'])
def process_photo():
    """
    Complete photo processing: detect faces and match against known users
    This is the main endpoint called by the backend service
    """
    try:
        # Get the image file and metadata
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        photo_id = request.form.get('photo_id')
        backend_url = request.form.get('backend_url', 'http://localhost:8080')
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type'}), 400
        
        # Save uploaded file temporarily
        temp_path = save_uploaded_file(file)
        
        try:
            logger.info(f"Processing photo {photo_id}")
            
            # Step 1: Detect faces in the image
            detection_result = face_detection_service.detect_faces(temp_path)
            
            if not detection_result['success']:
                return jsonify({
                    'success': False,
                    'error': 'Face detection failed',
                    'details': detection_result
                })
            
            faces_detected = len(detection_result['faces'])
            logger.info(f"Detected {faces_detected} faces in photo {photo_id}")
            
            # Step 2: Get known face encodings from backend
            known_faces_response = requests.get(
                f"{backend_url}/api/faces/encodings",
                timeout=30
            )
            
            if known_faces_response.status_code == 200:
                known_faces_data = known_faces_response.json()
            else:
                logger.warning("Could not fetch known face encodings")
                known_faces_data = {'encodings': [], 'user_ids': []}
            
            # Step 3: Recognize faces against known encodings
            recognition_result = face_recognition_service.recognize_faces_with_data(
                temp_path, 
                known_faces_data.get('encodings', []),
                known_faces_data.get('user_ids', [])
            )
            
            # Step 4: Send results back to backend
            result_payload = {
                'photo_id': photo_id,
                'faces_detected': faces_detected,
                'recognized_users': recognition_result.get('recognized_users', []),
                'face_locations': detection_result.get('face_locations', []),
                'processing_status': 'completed'
            }
            
            # Notify backend of processing completion
            try:
                backend_response = requests.post(
                    f"{backend_url}/api/photos/{photo_id}/processing-complete",
                    json=result_payload,
                    timeout=30
                )
                
                if backend_response.status_code == 200:
                    logger.info(f"Successfully notified backend about photo {photo_id}")
                else:
                    logger.warning(f"Failed to notify backend: {backend_response.status_code}")
            
            except requests.RequestException as e:
                logger.error(f"Error notifying backend: {str(e)}")
            
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
            return jsonify({
                'success': True,
                'photo_id': photo_id,
                'faces_detected': faces_detected,
                'recognized_users': recognition_result.get('recognized_users', []),
                'message': 'Photo processed successfully'
            })
        
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e
    
    except Exception as e:
        logger.error(f"Error in photo processing: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Photo processing failed: {str(e)}'
        }), 500

@app.route('/add-face-encoding', methods=['POST'])
def add_face_encoding():
    """
    Add a new face encoding for a user (called when user uploads profile photo)
    """
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        user_id = request.form.get('user_id')
        
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type'}), 400
        
        # Save uploaded file temporarily
        temp_path = save_uploaded_file(file)
        
        try:
            # Extract face encoding
            result = face_recognition_service.extract_face_encoding(temp_path, user_id)
            
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
            return jsonify(result)
        
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e
    
    except Exception as e:
        logger.error(f"Error adding face encoding: {str(e)}")
        return jsonify({'error': f'Failed to add face encoding: {str(e)}'}), 500

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