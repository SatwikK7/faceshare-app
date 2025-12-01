"""
InsightFace ONNX-based Face Recognition Service
Uses SCRFD for detection and ArcFace for recognition
Includes proper face alignment for maximum accuracy
"""
import cv2
import numpy as np
import onnxruntime as ort
from typing import List, Tuple, Dict, Optional
import os
from skimage import transform as trans

class InsightFaceONNX:
    """
    Production-grade face recognition using ONNX models
    - SCRFD for fast, accurate face detection
    - ArcFace for state-of-the-art face recognition (99.8%+ accuracy)
    - Built-in face alignment using 5-point landmarks
    """

    def __init__(self, det_model_path: str, rec_model_path: str):
        """
        Initialize face detection and recognition models

        Args:
            det_model_path: Path to SCRFD detection model (.onnx)
            rec_model_path: Path to ArcFace recognition model (.onnx)
        """
        print("Initializing InsightFace ONNX models...")

        # Initialize detection model (SCRFD)
        self.det_session = ort.InferenceSession(
            det_model_path,
            providers=['CPUExecutionProvider']
        )
        self.det_input_name = self.det_session.get_inputs()[0].name

        # Initialize recognition model (ArcFace)
        self.rec_session = ort.InferenceSession(
            rec_model_path,
            providers=['CPUExecutionProvider']
        )
        self.rec_input_name = self.rec_session.get_inputs()[0].name

        # Detection parameters
        self.det_thresh = 0.3  # Lower threshold for better recall
        self.nms_thresh = 0.4
        self.input_size = (640, 640)

        # SCRFD uses 3 feature scales with 2 anchors per location
        self.fmc = 3  # number of feature pyramid levels
        self._feat_stride_fpn = [8, 16, 32]
        self._num_anchors = 2

        # Standard face alignment template (5 landmarks)
        self.arcface_dst = np.array([
            [38.2946, 51.6963],
            [73.5318, 51.5014],
            [56.0252, 71.7366],
            [41.5493, 92.3655],
            [70.7299, 92.2041]
        ], dtype=np.float32)

        print("InsightFace ONNX initialized successfully!")
        print(f"  Detection model: {os.path.basename(det_model_path)}")
        print(f"  Recognition model: {os.path.basename(rec_model_path)}")

    def preprocess_image(self, image_path: str, max_size: int = 1280) -> np.ndarray:
        """
        Preprocess image - resize if too large

        Args:
            image_path: Path to image file
            max_size: Maximum dimension size

        Returns:
            Preprocessed image as numpy array (BGR)
        """
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Failed to load image: {image_path}")

        # Resize if too large (improves accuracy)
        h, w = img.shape[:2]
        if max(h, w) > max_size:
            scale = max_size / max(h, w)
            new_w = int(w * scale)
            new_h = int(h * scale)
            img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LINEAR)

        return img

    def detect_faces(self, img: np.ndarray) -> List[Dict]:
        """
        Detect faces in image using SCRFD

        Args:
            img: Input image (BGR format)

        Returns:
            List of detected faces with bounding boxes and landmarks
        """
        # Prepare input blob
        img_h, img_w = img.shape[:2]
        input_h, input_w = self.input_size

        # Resize image to fixed input size
        img_resized = cv2.resize(img, (input_w, input_h))

        # Create input blob: normalize and transpose
        blob = cv2.dnn.blobFromImage(
            img_resized, 1.0/128.0, (input_w, input_h),
            (127.5, 127.5, 127.5), swapRB=True
        )

        # Run inference
        outputs = self.det_session.run(None, {self.det_input_name: blob})

        # Parse detection outputs
        # SCRFD outputs: scores[0,1,2], bboxes[3,4,5], keypoints[6,7,8]
        # For 3 scales: stride 8, 16, 32
        all_scores = []
        all_bboxes = []
        all_kpss = []

        for idx, stride in enumerate(self._feat_stride_fpn):
            # Get outputs for this scale
            scores = outputs[idx].squeeze()  # Shape: (num_anchors,)
            bbox_preds = outputs[idx + 3]    # Shape: (num_anchors, 4)
            kps_preds = outputs[idx + 6]     # Shape: (num_anchors, 10)

            # Generate anchor centers for this scale
            height = input_h // stride
            width = input_w // stride

            # Create anchor grid
            anchor_centers = np.stack(
                np.mgrid[:height, :width][::-1], axis=-1
            ).astype(np.float32)
            anchor_centers = (anchor_centers * stride).reshape(-1, 2)

            # SCRFD uses 2 anchors per location, so duplicate anchor centers
            if self._num_anchors > 1:
                anchor_centers = np.tile(anchor_centers, (self._num_anchors, 1))

            # Filter by detection threshold
            pos_inds = np.where(scores >= self.det_thresh)[0]
            if len(pos_inds) == 0:
                continue

            pos_scores = scores[pos_inds]
            pos_bbox_preds = bbox_preds[pos_inds]
            pos_kps_preds = kps_preds[pos_inds]
            pos_anchor_centers = anchor_centers[pos_inds]

            # Decode bounding boxes (distance2bbox)
            x1 = (pos_anchor_centers[:, 0] - pos_bbox_preds[:, 0] * stride)
            y1 = (pos_anchor_centers[:, 1] - pos_bbox_preds[:, 1] * stride)
            x2 = (pos_anchor_centers[:, 0] + pos_bbox_preds[:, 2] * stride)
            y2 = (pos_anchor_centers[:, 1] + pos_bbox_preds[:, 3] * stride)
            bboxes = np.stack([x1, y1, x2, y2], axis=-1)

            # Decode keypoints (5 points x 2 coordinates = 10 values)
            kpss = pos_kps_preds.copy()
            for i in range(5):  # 5 facial landmarks
                kpss[:, i*2] = pos_anchor_centers[:, 0] + kpss[:, i*2] * stride
                kpss[:, i*2+1] = pos_anchor_centers[:, 1] + kpss[:, i*2+1] * stride

            all_scores.append(pos_scores)
            all_bboxes.append(bboxes)
            all_kpss.append(kpss)

        if len(all_scores) == 0:
            return []

        # Concatenate results from all scales
        all_scores = np.concatenate(all_scores)
        all_bboxes = np.concatenate(all_bboxes)
        all_kpss = np.concatenate(all_kpss)

        # Apply NMS (Non-Maximum Suppression)
        keep_indices = self._nms(all_bboxes, all_scores, self.nms_thresh)

        # Scale coordinates back to original image size
        scale_x = img_w / input_w
        scale_y = img_h / input_h

        detected_faces = []
        for idx in keep_indices:
            bbox = all_bboxes[idx]
            kps = all_kpss[idx].reshape(5, 2)
            score = all_scores[idx]

            # Scale to original image coordinates
            bbox = bbox * [scale_x, scale_y, scale_x, scale_y]
            kps = kps * [scale_x, scale_y]

            detected_faces.append({
                'bbox': bbox,  # [x1, y1, x2, y2]
                'kps': kps,    # 5x2 array of landmarks
                'score': float(score)
            })

        return detected_faces

    def _nms(self, bboxes: np.ndarray, scores: np.ndarray, threshold: float) -> List[int]:
        """Non-Maximum Suppression"""
        x1 = bboxes[:, 0]
        y1 = bboxes[:, 1]
        x2 = bboxes[:, 2]
        y2 = bboxes[:, 3]

        areas = (x2 - x1 + 1) * (y2 - y1 + 1)
        order = scores.argsort()[::-1]

        keep = []
        while order.size > 0:
            i = order[0]
            keep.append(i)

            xx1 = np.maximum(x1[i], x1[order[1:]])
            yy1 = np.maximum(y1[i], y1[order[1:]])
            xx2 = np.minimum(x2[i], x2[order[1:]])
            yy2 = np.minimum(y2[i], y2[order[1:]])

            w = np.maximum(0.0, xx2 - xx1 + 1)
            h = np.maximum(0.0, yy2 - yy1 + 1)
            inter = w * h

            ovr = inter / (areas[i] + areas[order[1:]] - inter)

            inds = np.where(ovr <= threshold)[0]
            order = order[inds + 1]

        return keep

    def align_face(self, img: np.ndarray, landmarks: np.ndarray) -> np.ndarray:
        """
        Align face using similarity transform (scikit-image implementation)

        Args:
            img: Original image
            landmarks: 5 facial landmarks (5x2 array)

        Returns:
            Aligned face image (112x112)
        """
        # Use scikit-image's SimilarityTransform (proven, reliable)
        tform = trans.SimilarityTransform()
        tform.estimate(landmarks, self.arcface_dst)

        # Apply transform
        M = tform.params[0:2, :]
        aligned = cv2.warpAffine(
            img, M, (112, 112),
            borderValue=0.0
        )

        return aligned

    def extract_embedding(self, aligned_face: np.ndarray) -> np.ndarray:
        """
        Extract face embedding using ArcFace

        Args:
            aligned_face: Aligned face image (112x112)

        Returns:
            512-dimensional normalized embedding
        """
        # Prepare input blob
        blob = cv2.dnn.blobFromImage(
            aligned_face, 1.0/127.5, (112, 112),
            (127.5, 127.5, 127.5), swapRB=True
        )

        # Run inference
        embedding = self.rec_session.run(None, {self.rec_input_name: blob})[0]

        # Flatten and normalize
        embedding = embedding.flatten()
        embedding = embedding / np.linalg.norm(embedding)

        return embedding

    def process_image(self, image_path: str) -> Dict:
        """
        Complete pipeline: detect faces, align, and extract embeddings

        Args:
            image_path: Path to image file

        Returns:
            Dictionary with detection results and embeddings
        """
        # Load and preprocess image
        img = self.preprocess_image(image_path)

        # Detect faces
        faces = self.detect_faces(img)

        # Extract embeddings for each face
        face_encodings = []
        face_locations = []
        landmarks_list = []

        for face in faces:
            bbox = face['bbox']
            kps = face['kps']

            # Align face
            aligned_face = self.align_face(img, kps)

            # Extract embedding
            embedding = self.extract_embedding(aligned_face)

            face_encodings.append(embedding.tolist())
            face_locations.append(bbox.tolist())
            landmarks_list.append(kps.tolist())

        return {
            'faces_detected': len(faces),
            'face_locations': face_locations,
            'face_encodings': face_encodings,
            'landmarks': landmarks_list
        }

    def compare_faces(
        self,
        embedding1: np.ndarray,
        embedding2: np.ndarray,
        threshold: float = 0.4
    ) -> Tuple[float, bool]:
        """
        Compare two face embeddings

        Args:
            embedding1: First face embedding
            embedding2: Second face embedding
            threshold: Similarity threshold (0.4 recommended for ArcFace)

        Returns:
            Tuple of (similarity_score, is_match)
        """
        # Ensure embeddings are normalized
        embedding1 = embedding1 / np.linalg.norm(embedding1)
        embedding2 = embedding2 / np.linalg.norm(embedding2)

        # Compute cosine similarity
        similarity = np.dot(embedding1, embedding2)

        # Check if similarity exceeds threshold
        is_match = similarity >= threshold

        return similarity, is_match
