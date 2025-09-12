"""
Face Recognition Service
Handles face encoding extraction and matching operations
"""

import json
import logging
import numpy as np
import face_recognition
from PIL import Image
import cv2

from config.settings import Config
from utils.encoding_utils import encode_face_encoding, decode_face_encoding

logger = logging.getLogger(__name__)

class FaceRecognitionService:
    """Service for face recognition operations"""
    
    def __init__(self):
        self.tolerance = Config.FACE_RECOGNITION_TOLERANCE
        self.model = Config.FACE_RECOGNITION_MODEL
    
    def extract_face_encoding(self, image_path, user_id):
        """
        Extract face encoding from an image for a specific user
        
        Args:
            image_path (str): Path to the image file
            user_id (str): ID of the user
            
        Returns:
            dict: Result containing success status and encoding data
        """
        try:
            logger.info(f"Extracting face encoding for user {user_id} from {image_path}")
            
            # Load and process image
            image = face_recognition.load_image_file(image_path)
            
            # Find face locations
            face_locations = face_recognition.face_locations(image, model=self.model)
            
            if not face_locations:
                return {
                    'success': False,
                    'error': 'No face detected in the image',
                    'user_id': user_id
                }
            
            if len(face_locations) > 1:
                logger.warning(f"Multiple faces detected for user {user_id}, using the first one")
            
            # Extract face encodings
            face_encodings = face_recognition.face_encodings(image, face_locations)
            
            if not face_encodings:
                return {
                    'success': False,
                    'error': 'Could not extract face encoding',
                    'user_id': user_id
                }
            
            # Use the first face encoding
            face_encoding = face_encodings[0]
            
            # Convert to JSON-serializable format
            encoding_data = encode_face_encoding(face_encoding)
            
            logger.info(f"Successfully extracted face encoding for user {user_id}")
            
            return {
                'success': True,
                'user_id': user_id,
                'face_encoding': encoding_data,
                'face_location': face_locations[0]
            }
            
        except Exception as e:
            logger.error(f"Error extracting face encoding for user {user_id}: {str(e)}")
            return {
                'success': False,
                'error': f'Face encoding extraction failed: {str(e)}',
                'user_id': user_id
            }
    
    def recognize_faces(self, image_path, known_encodings_json, user_ids_json):
        """
        Recognize faces in an image against known face encodings
        
        Args:
            image_path (str): Path to the image file
            known_encodings_json (str): JSON string of known face encodings
            user_ids_json (str): JSON string of corresponding user IDs
            
        Returns:
            dict: Recognition results
        """
        try:
            # Parse JSON data
            known_encodings_data = json.loads(known_encodings_json) if known_encodings_json else []
            user_ids = json.loads(user_ids_json) if user_ids_json else []
            
            return self.recognize_faces_with_data(image_path, known_encodings_data, user_ids)
            
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing JSON data: {str(e)}")
            return {
                'success': False,
                'error': 'Invalid JSON data provided'
            }
    
    def recognize_faces_with_data(self, image_path, known_encodings_data, user_ids):
        """
        Recognize faces with already parsed data
        
        Args:
            image_path (str): Path to the image file
            known_encodings_data (list): List of known face encodings
            user_ids (list): List of corresponding user IDs
            
        Returns:
            dict: Recognition results
        """
        try:
            logger.info(f"Recognizing faces in {image_path} against {len(known_encodings_data)} known faces")
            
            # Load and process image
            image = face_recognition.load_image_file(image_path)
            
            # Find face locations and encodings in the uploaded image
            face_locations = face_recognition.face_locations(image, model=self.model)
            face_encodings = face_recognition.face_encodings(image, face_locations)
            
            if not face_encodings:
                return {
                    'success': True,
                    'recognized_users': [],
                    'face_locations': [],
                    'message': 'No faces detected in the image'
                }
            
            # Convert known encodings from JSON format
            known_encodings = []
            for encoding_data in known_encodings_data:
                try:
                    encoding = decode_face_encoding(encoding_data)
                    known_encodings.append(encoding)
                except Exception as e:
                    logger.warning(f"Failed to decode face encoding: {str(e)}")
                    continue
            
            if not known_encodings:
                return {
                    'success': True,
                    'recognized_users': [],
                    'face_locations': face_locations,
                    'message': 'No valid known face encodings available'
                }
            
            recognized_users = []
            
            # Compare each face in the image with known faces
            for i, face_encoding in enumerate(face_encodings):
                matches = face_recognition.compare_faces(
                    known_encodings, 
                    face_encoding, 
                    tolerance=self.tolerance
                )
                
                # Calculate face distances
                face_distances = face_recognition.face_distance(known_encodings, face_encoding)
                
                # Find the best match
                if True in matches:
                    best_match_index = np.argmin(face_distances)
                    if matches[best_match_index]:
                        user_id = user_ids[best_match_index]
                        confidence = 1 - face_distances[best_match_index]
                        
                        recognized_users.append({
                            'user_id': user_id,
                            'face_location': face_locations[i],
                            'confidence': float(confidence),
                            'face_index': i
                        })
                        
                        logger.info(f"Recognized user {user_id} with confidence {confidence:.2f}")
            
            logger.info(f"Recognition complete: {len(recognized_users)} users recognized out of {len(face_encodings)} faces")
            
            return {
                'success': True,
                'recognized_users': recognized_users,
                'face_locations': face_locations,
                'total_faces': len(face_encodings),
                'recognized_count': len(recognized_users)
            }
            
        except Exception as e:
            logger.error(f"Error in face recognition: {str(e)}")
            return {
                'success': False,
                'error': f'Face recognition failed: {str(e)}'
            }
    
    def compare_faces(self, encoding1_data, encoding2_data):
        """
        Compare two face encodings
        
        Args:
            encoding1_data: First face encoding data
            encoding2_data: Second face encoding data
            
        Returns:
            dict: Comparison result with match status and distance
        """
        try:
            # Decode face encodings
            encoding1 = decode_face_encoding(encoding1_data)
            encoding2 = decode_face_encoding(encoding2_data)
            
            # Compare faces
            matches = face_recognition.compare_faces([encoding1], encoding2, tolerance=self.tolerance)
            distance = face_recognition.face_distance([encoding1], encoding2)[0]
            
            return {
                'success': True,
                'match': matches[0],
                'distance': float(distance),
                'confidence': float(1 - distance) if distance < 1 else 0.0
            }
            
        except Exception as e:
            logger.error(f"Error comparing faces: {str(e)}")
            return {
                'success': False,
                'error': f'Face comparison failed: {str(e)}'
            }