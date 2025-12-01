package com.faceshare.service;

import com.faceshare.model.FaceEncoding;
import com.faceshare.model.User;
import com.faceshare.repository.FaceEncodingRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.*;
import org.springframework.web.client.RestTemplate;

import java.io.File;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class FaceRecognitionService {

    private static final Logger logger = LoggerFactory.getLogger(FaceRecognitionService.class);
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private FaceEncodingRepository faceEncodingRepository;

    @Value("${ai.service.url:http://localhost:5000}")
    private String aiServiceUrl;

    @Value("${face.recognition.tolerance:0.6}")
    private double matchTolerance;

    /**
     * Detect faces in an image and extract encodings
     * Returns: { success: true, faces_detected: N, face_encodings: [[...],[...]] }
     */
    public Map<String, Object> detectFaces(File imageFile) {
        try {
            String url = aiServiceUrl + "/detect-faces";
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new FileSystemResource(imageFile));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            HttpEntity<MultiValueMap<String, Object>> req = new HttpEntity<>(body, headers);
            ResponseEntity<Map<String, Object>> resp =
                    restTemplate.postForEntity(url, req, (Class<Map<String, Object>>)(Class<?>)Map.class);

            Map<String, Object> result = resp.getBody();
            logger.info("Face detection result: {} faces detected", result.get("faces_detected"));
            return result;
        } catch (Exception e) {
            logger.error("Error detecting faces: {}", e.getMessage(), e);
            return Map.of("success", false, "faces_detected", 0, "error", e.getMessage());
        }
    }

    /**
     * Match detected face encodings against all registered users
     * Returns list of matched User IDs
     */
    public List<Long> matchFaces(List<List<Double>> detectedEncodings) {
        if (detectedEncodings == null || detectedEncodings.isEmpty()) {
            return Collections.emptyList();
        }

        Set<Long> matchedUserIds = new HashSet<>();

        // Get all registered face encodings with minimum quality
        List<FaceEncoding> registeredEncodings = faceEncodingRepository.findAllWithMinQuality(0.5);

        logger.info("Matching {} detected faces against {} registered encodings",
                detectedEncodings.size(), registeredEncodings.size());

        // Compare each detected encoding against all registered encodings
        for (List<Double> detectedEncoding : detectedEncodings) {
            for (FaceEncoding registeredEncoding : registeredEncodings) {
                try {
                    List<Double> storedEncoding = parseEncoding(registeredEncoding.getEncodingJson());
                    double distance = calculateEuclideanDistance(detectedEncoding, storedEncoding);

                    if (distance < matchTolerance) {
                        matchedUserIds.add(registeredEncoding.getUser().getId());
                        logger.info("Face match found! User ID: {}, Distance: {}",
                                registeredEncoding.getUser().getId(), distance);
                    }
                } catch (Exception e) {
                    logger.error("Error comparing encodings: {}", e.getMessage());
                }
            }
        }

        return new ArrayList<>(matchedUserIds);
    }

    /**
     * Save face encoding for a user
     */
    public FaceEncoding saveFaceEncoding(User user, List<Double> encoding, boolean isPrimary) {
        try {
            String encodingJson = objectMapper.writeValueAsString(encoding);
            FaceEncoding faceEncoding = new FaceEncoding(user, encodingJson);
            faceEncoding.setPrimary(isPrimary);
            faceEncoding.setQualityScore(1.0); // Default quality, can be improved

            return faceEncodingRepository.save(faceEncoding);
        } catch (Exception e) {
            logger.error("Error saving face encoding: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to save face encoding", e);
        }
    }

    /**
     * Parse JSON encoding string to List of Doubles
     */
    private List<Double> parseEncoding(String encodingJson) {
        try {
            return objectMapper.readValue(encodingJson, new TypeReference<List<Double>>() {});
        } catch (Exception e) {
            logger.error("Error parsing encoding JSON: {}", e.getMessage());
            throw new RuntimeException("Failed to parse encoding", e);
        }
    }

    /**
     * Calculate Euclidean distance between two face encodings
     * Lower distance = more similar faces
     */
    private double calculateEuclideanDistance(List<Double> encoding1, List<Double> encoding2) {
        if (encoding1.size() != encoding2.size()) {
            throw new IllegalArgumentException("Encodings must have the same length");
        }

        double sum = 0.0;
        for (int i = 0; i < encoding1.size(); i++) {
            double diff = encoding1.get(i) - encoding2.get(i);
            sum += diff * diff;
        }

        return Math.sqrt(sum);
    }

    /**
     * Get all face encodings for a user
     */
    public List<FaceEncoding> getUserEncodings(User user) {
        return faceEncodingRepository.findByUser(user);
    }

    /**
     * Check if user has registered face encodings
     */
    public boolean hasRegisteredFace(User user) {
        return faceEncodingRepository.existsByUser(user);
    }
}
