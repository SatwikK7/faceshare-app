# utils/encoding_utils.py
import json
import numpy as np

def encode_face_encoding(face_encoding):
    """Convert numpy array to JSON-serializable format"""
    return face_encoding.tolist()

def decode_face_encoding(encoding_data):
    """Convert JSON data back to numpy array"""
    return np.array(encoding_data)