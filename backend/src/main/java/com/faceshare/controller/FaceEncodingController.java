package com.faceshare.controller;

import com.faceshare.model.FaceEncoding;
import com.faceshare.model.User;
import com.faceshare.service.FaceRecognitionService;
import com.faceshare.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/face-encoding")
public class FaceEncodingController {

    private static final Logger logger = LoggerFactory.getLogger(FaceEncodingController.class);

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @Autowired
    private UserService userService;

    /**
     * Register user's face for recognition
     * User uploads a photo of their face, and the system extracts and stores the encoding
     */
    @PostMapping("/register")
    public ResponseEntity<?> registerFace(
            @RequestParam("face_image") MultipartFile faceImage,
            @RequestParam(value = "is_primary", defaultValue = "false") boolean isPrimary,
            Authentication authentication) {

        try {
            // Get current user
            User user = userService.findByEmail(authentication.getName());
            if (user == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "User not found"
                ));
            }

            // Validate file
            if (faceImage.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Face image is required"
                ));
            }

            // Save temporary file for processing
            Path tempFile = Files.createTempFile("face-", faceImage.getOriginalFilename());
            faceImage.transferTo(tempFile.toFile());

            // Detect faces in the image
            Map<String, Object> detectionResult = faceRecognitionService.detectFaces(tempFile.toFile());

            // Clean up temp file
            Files.deleteIfExists(tempFile);

            // Check if detection was successful
            Boolean success = (Boolean) detectionResult.get("success");
            if (success == null || !success) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Failed to detect face in the image"
                ));
            }

            // Get face encodings
            @SuppressWarnings("unchecked")
            List<List<Double>> faceEncodings = (List<List<Double>>) detectionResult.get("face_encodings");

            if (faceEncodings == null || faceEncodings.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "No face detected in the image. Please upload a clear photo of your face."
                ));
            }

            if (faceEncodings.size() > 1) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Multiple faces detected. Please upload a photo with only your face."
                ));
            }

            // Save the face encoding
            List<Double> encoding = faceEncodings.get(0);
            FaceEncoding savedEncoding = faceRecognitionService.saveFaceEncoding(user, encoding, isPrimary);

            logger.info("Face encoding registered for user: {} (ID: {})", user.getEmail(), user.getId());

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Face registered successfully",
                "encoding_id", savedEncoding.getId(),
                "is_primary", savedEncoding.isPrimary()
            ));

        } catch (IOException e) {
            logger.error("Error processing face image: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error processing image: " + e.getMessage()
            ));
        } catch (Exception e) {
            logger.error("Error registering face: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error registering face: " + e.getMessage()
            ));
        }
    }

    /**
     * Check if user has registered face encodings
     */
    @GetMapping("/status")
    public ResponseEntity<?> getFaceRegistrationStatus(Authentication authentication) {
        try {
            User user = userService.findByEmail(authentication.getName());
            if (user == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "User not found"
                ));
            }

            boolean hasRegisteredFace = faceRecognitionService.hasRegisteredFace(user);
            List<FaceEncoding> encodings = faceRecognitionService.getUserEncodings(user);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "has_registered_face", hasRegisteredFace,
                "encodings_count", encodings.size()
            ));

        } catch (Exception e) {
            logger.error("Error checking face registration status: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error checking status: " + e.getMessage()
            ));
        }
    }

    /**
     * Get user's face encodings
     */
    @GetMapping("/my-encodings")
    public ResponseEntity<?> getMyEncodings(Authentication authentication) {
        try {
            User user = userService.findByEmail(authentication.getName());
            if (user == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "User not found"
                ));
            }

            List<FaceEncoding> encodings = faceRecognitionService.getUserEncodings(user);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "encodings_count", encodings.size(),
                "encodings", encodings.stream().map(e -> Map.of(
                    "id", e.getId(),
                    "is_primary", e.isPrimary(),
                    "quality_score", e.getQualityScore() != null ? e.getQualityScore() : "N/A",
                    "created_at", e.getCreatedAt()
                )).toList()
            ));

        } catch (Exception e) {
            logger.error("Error getting face encodings: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error getting encodings: " + e.getMessage()
            ));
        }
    }
}
