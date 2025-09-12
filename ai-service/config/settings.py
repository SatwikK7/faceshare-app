"""
Configuration settings for the AI Service
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    """Base configuration class"""
    
    # Server settings
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5000))
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
    
    # File handling
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', './uploads')
    TEMP_FOLDER = os.getenv('TEMP_FOLDER', './temp')
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))  # 16MB
    
    # Allowed file extensions
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff'}
    
    # Face recognition settings
    FACE_RECOGNITION_TOLERANCE = float(os.getenv('FACE_RECOGNITION_TOLERANCE', 0.6))
    FACE_RECOGNITION_MODEL = os.getenv('FACE_RECOGNITION_MODEL', 'hog')  # 'hog' or 'cnn'
    
    # Image processing settings
    MAX_IMAGE_SIZE = (1920, 1080)  # Resize large images for faster processing
    JPEG_QUALITY = 85
    
    # Backend service settings
    BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:8080')
    BACKEND_TIMEOUT = int(os.getenv('BACKEND_TIMEOUT', 30))
    
    # Security
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-change-in-production')
    
    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', './logs/ai_service.log')

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    FACE_RECOGNITION_MODEL = 'hog'  # Faster for development

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    FACE_RECOGNITION_MODEL = 'cnn'  # More accurate for production
    
class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    UPLOAD_FOLDER = './test_uploads'
    TEMP_FOLDER = './test_temp'

# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}