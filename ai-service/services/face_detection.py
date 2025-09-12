# services/face_detection.py
import cv2
import face_recognition
import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

class FaceDetectionService:
    def __init__(self):
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    
    def detect_faces(self, image_path: str) -> Dict[str, Any]:
        try:
            # Load image
            image = face_recognition.load_image_file(image_path)
            
            # Find face locations
            face_locations = face_recognition.face_locations(image)
            
            # Extract face encodings
            face_encodings = face_recognition.face_encodings(image, face_locations)
            
            return {
                'success': True,
                'faces_detected': len(face_locations),
                'face_locations': face_locations,
                'face_encodings': [encoding.tolist() for encoding in face_encodings]
            }
            
        except Exception as e:
            logger.error(f"Face detection failed: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'faces_detected': 0
            }