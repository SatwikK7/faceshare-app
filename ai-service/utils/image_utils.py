import os
import uuid
from werkzeug.utils import secure_filename
from config.settings import Config

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS

def save_uploaded_file(file):
    filename = secure_filename(file.filename)
    unique_filename = f"{uuid.uuid4()}_{filename}"
    temp_path = os.path.join(Config.TEMP_FOLDER, unique_filename)
    file.save(temp_path)
    return temp_path