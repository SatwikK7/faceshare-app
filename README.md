# FaceShare - AI-Powered Photo Sharing App

FaceShare is a modern photo-sharing application that uses AI-powered face recognition to automatically detect and tag people in photos, making photo sharing with friends seamless and intelligent.

## 🚀 Features

- **AI Face Recognition** - Automatically detect and recognize faces in uploaded photos
- **Smart Photo Sharing** - Share photos with friends based on face recognition
- **Secure Authentication** - JWT-based authentication with BCrypt password encoding
- **Cross-Platform** - Flutter mobile app with Spring Boot backend
- **Real-time Processing** - Python-based AI service for face detection and encoding
- **Modern UI** - Clean, intuitive mobile interface

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Spring Boot    │    │  Python AI      │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Service)     │
│                 │    │                 │    │                 │
│ • Photo Upload  │    │ • REST APIs     │    │ • Face Detection│
│ • User Auth     │    │ • Authentication│    │ • Face Encoding │
│ • Photo Gallery │    │ • File Storage  │    │ • Face Matching │
│ • Face Tagging  │    │ • Database      │    │ • ML Processing │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                       ┌─────────────┐
                       │ H2 Database │
                       │             │
                       │ • Users     │
                       │ • Photos    │
                       │ • Encodings │
                       └─────────────┘
```

## 🛠️ Tech Stack

### Backend (Spring Boot)
- **Java 17** with Spring Boot 3.2.0
- **Spring Security** with JWT authentication
- **Spring Data JPA** with H2 database
- **Maven** for dependency management
- **Swagger/OpenAPI** for API documentation

### AI Service (Python)
- **Python 3.8+** with Flask
- **face_recognition** library for face detection
- **OpenCV** for image processing
- **NumPy** for numerical computations

### Frontend (Flutter)
- **Flutter 3.0+** with Dart
- **HTTP** for API communication
- **Provider** for state management
- **Image Picker** for photo capture/selection

## 🚀 Quick Start

### Prerequisites
- Java 17+
- Python 3.8+
- Flutter 3.0+
- Maven 3.6+

### 1. Backend Setup
```bash
cd backend
mvn spring-boot:run
```
Backend will start on `http://localhost:8080`

**API Documentation:** http://localhost:8080/swagger-ui/index.html
**Database Console:** http://localhost:8080/h2-console

### 2. AI Service Setup
```bash
cd ai-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```
AI Service will start on `http://localhost:5000`

### 3. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

## 🧪 Testing

### Backend API Testing
```bash
cd backend
powershell -ExecutionPolicy Bypass -File .\basic-test.ps1
```

### Test Credentials
- **Email:** alice@example.com
- **Password:** password

## 📱 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token
- `GET /api/auth/me` - Get current user

### Photos
- `POST /api/photos/upload` - Upload photo
- `GET /api/photos/my-photos` - Get user's photos
- `GET /api/photos/shared` - Get shared photos
- `GET /api/photos/view/{id}` - View photo

### Users
- `GET /api/users/me` - Get user profile
- `GET /api/users/{id}` - Get user by ID

## 🗄️ Database Schema

### Users
- `id`, `email`, `password`, `full_name`, `profile_image_url`, `is_enabled`, `created_at`, `updated_at`

### Photos
- `id`, `file_name`, `file_path`, `file_size`, `mime_type`, `user_id`, `processing_status`, `faces_detected`, `created_at`, `updated_at`

### Face Encodings
- `id`, `user_id`, `encoding_json`

### Shared Photos
- `id`, `photo_id`, `recipient_user_id`, `created_at`, `delivered`

## 🔧 Configuration

### Backend Configuration (`application.yml`)
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:h2:file:./data/faceshare
    username: sa
    password: password

jwt:
  secret: mySecretKey123456789012345678901234567890
  expiration: 86400000 # 24 hours

file:
  upload-dir: ./uploads
  max-size: 10485760 # 10MB
```

### AI Service Configuration
- Face recognition models automatically downloaded
- Configurable confidence thresholds
- Support for multiple face encodings per user

## 🚀 Deployment

### Backend
- Package: `mvn clean package`
- Run: `java -jar target/faceshare-backend-0.0.1-SNAPSHOT.jar`

### AI Service
- Use Docker or virtual environment
- Configure production face recognition models
- Set up proper logging and monitoring

### Frontend
- Build: `flutter build apk` (Android) or `flutter build ios` (iOS)
- Deploy to app stores or distribute APK

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **face_recognition** library by Adam Geitgey
- **Spring Boot** team for the excellent framework
- **Flutter** team for the cross-platform framework

## 📞 Support

For support, email support@faceshare.com or create an issue in this repository.

---

**Built with ❤️ by the FaceShare Team**