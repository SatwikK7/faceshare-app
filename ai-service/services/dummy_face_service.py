"""
Dummy Face Recognition Service for Testing
Returns mock face detection and recognition results without requiring ONNX models.
This allows the app to be deployed and tested end-to-end.
Replace with real InsightFace service once models are available.
"""
import numpy as np
import cv2
import logging

logger = logging.getLogger(__name__)

class DummyFaceService:
    """Mock face recognition service for testing without models"""

    def __init__(self):
        logger.info("Initializing DUMMY Face Service (no real AI - for testing only)")
        logger.warning("⚠️  Using MOCK face detection - results are fake!")

    def process_image(self, image_path):
        """
        Mock face detection - always detects 1 face with random embedding

        Args:
            image_path: Path to image file

        Returns:
            dict with mock face detection results
        """
        try:
            # Read image to get dimensions
            img = cv2.imread(image_path)
            if img is None:
                raise ValueError(f"Could not read image: {image_path}")

            height, width = img.shape[:2]

            # Generate fake face detection
            # Assume face is in center 50% of image
            center_x = width // 2
            center_y = height // 2
            face_w = width // 3
            face_h = height // 3

            # Mock bounding box [x1, y1, x2, y2]
            bbox = [
                center_x - face_w // 2,
                center_y - face_h // 2,
                center_x + face_w // 2,
                center_y + face_h // 2
            ]

            # Mock 5 facial landmarks (eyes, nose, mouth corners)
            landmarks = [
                [center_x - 30, center_y - 20],  # Left eye
                [center_x + 30, center_y - 20],  # Right eye
                [center_x, center_y],             # Nose
                [center_x - 25, center_y + 30],  # Left mouth
                [center_x + 25, center_y + 30]   # Right mouth
            ]

            # Generate random but consistent embedding (512-dim like ArcFace)
            # Use image hash as seed for consistency
            seed = hash(image_path) % (2**32)
            np.random.seed(seed)
            embedding = np.random.randn(512).astype(np.float32)
            # Normalize to unit length (like real ArcFace embeddings)
            embedding = embedding / np.linalg.norm(embedding)

            logger.info(f"✓ MOCK: Detected 1 face in {image_path}")

            return {
                'faces_detected': 1,
                'faces': [{
                    'bbox': bbox,
                    'landmarks': landmarks,
                    'confidence': 0.95,  # Fake high confidence
                    'embedding': embedding.tolist()
                }]
            }

        except Exception as e:
            logger.error(f"Error in mock face detection: {str(e)}")
            raise

    def compare_faces(self, embedding1, embedding2, threshold=0.4):
        """
        Mock face comparison - returns random similarity

        Args:
            embedding1: First face embedding
            embedding2: Second face embedding
            threshold: Similarity threshold (default 0.4)

        Returns:
            (similarity, is_match)
        """
        # Convert to numpy arrays
        emb1 = np.array(embedding1)
        emb2 = np.array(embedding2)

        # Calculate cosine similarity (like real ArcFace)
        similarity = np.dot(emb1, emb2) / (np.linalg.norm(emb1) * np.linalg.norm(emb2))

        # Add some randomness to make it look real
        similarity = float(similarity)

        is_match = similarity > threshold

        logger.info(f"✓ MOCK: Face comparison - similarity: {similarity:.3f}, match: {is_match}")

        return similarity, is_match
