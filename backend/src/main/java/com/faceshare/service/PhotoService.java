package com.faceshare.service;

import com.faceshare.dto.PhotoDto;
import com.faceshare.model.Photo;
import com.faceshare.model.SharedPhoto;
import com.faceshare.model.User;
import com.faceshare.repository.PhotoRepository;
import com.faceshare.repository.SharedPhotoRepository;
import com.faceshare.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class PhotoService {

    private static final Logger logger = LoggerFactory.getLogger(PhotoService.class);

    @Autowired
    private PhotoRepository photoRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @Autowired
    private SharedPhotoRepository sharedPhotoRepository;

    public PhotoDto uploadPhoto(MultipartFile file, String userEmail) throws Exception {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String fileName = fileStorageService.storeFile(file);
        String filePath = "./uploads/" + fileName;

        Photo photo = new Photo(
                file.getOriginalFilename(),
                filePath,
                file.getSize(),
                file.getContentType(),
                user
        );

        Photo savedPhoto = photoRepository.save(photo);

        // Process face detection and automatic sharing asynchronously
        // Returns immediately while processing happens in background
        processPhotoAndShare(savedPhoto);

        return convertToDto(savedPhoto);
    }

    /**
     * Process photo for face detection and automatically share with detected users
     * This method runs asynchronously to avoid blocking the upload request
     */
    @Async
    public void processPhotoAndShare(Photo photo) {
        try {
            photo.setProcessingStatus(Photo.ProcessingStatus.PROCESSING);
            photoRepository.save(photo);

            logger.info("Starting face detection for photo ID: {}", photo.getId());

            // Detect faces and extract encodings
            Map<String, Object> detectionResult = faceRecognitionService.detectFaces(
                    new File(photo.getFilePath())
            );

            Boolean success = (Boolean) detectionResult.get("success");
            if (success == null || !success) {
                logger.error("Face detection failed for photo ID: {}", photo.getId());
                photo.setProcessingStatus(Photo.ProcessingStatus.FAILED);
                photoRepository.save(photo);
                return;
            }

            // Get number of faces detected
            Object facesDetectedObj = detectionResult.get("faces_detected");
            Integer facesDetected = facesDetectedObj instanceof Integer
                ? (Integer) facesDetectedObj
                : 0;

            photo.setFacesDetected(facesDetected);
            logger.info("Detected {} faces in photo ID: {}", facesDetected, photo.getId());

            // Get face encodings
            @SuppressWarnings("unchecked")
            List<List<Double>> faceEncodings = (List<List<Double>>) detectionResult.get("face_encodings");

            if (faceEncodings != null && !faceEncodings.isEmpty()) {
                // Match faces against registered users
                List<Long> matchedUserIds = faceRecognitionService.matchFaces(faceEncodings);
                logger.info("Matched {} users in photo ID: {}", matchedUserIds.size(), photo.getId());

                // Automatically share photo with matched users
                sharePhotoWithUsers(photo, matchedUserIds);
            }

            photo.setProcessingStatus(Photo.ProcessingStatus.COMPLETED);
            photoRepository.save(photo);
            logger.info("Photo processing completed for photo ID: {}", photo.getId());

        } catch (Exception e) {
            logger.error("Error processing photo ID {}: {}", photo.getId(), e.getMessage(), e);
            photo.setProcessingStatus(Photo.ProcessingStatus.FAILED);
            photoRepository.save(photo);
        }
    }

    /**
     * Share photo with a list of users
     */
    private void sharePhotoWithUsers(Photo photo, List<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            logger.info("No users to share photo ID: {}", photo.getId());
            return;
        }

        // Don't share with the photo owner
        Long ownerId = photo.getUser().getId();
        userIds = userIds.stream()
                .filter(userId -> !userId.equals(ownerId))
                .collect(Collectors.toList());

        List<SharedPhoto> sharedPhotos = new ArrayList<>();
        for (Long userId : userIds) {
            try {
                User recipient = userRepository.findById(userId).orElse(null);
                if (recipient != null) {
                    SharedPhoto sharedPhoto = new SharedPhoto();
                    sharedPhoto.setPhoto(photo);
                    sharedPhoto.setRecipient(recipient);
                    sharedPhoto.setDelivered(true);
                    sharedPhotos.add(sharedPhoto);
                    logger.info("Sharing photo ID {} with user ID {}", photo.getId(), userId);
                }
            } catch (Exception e) {
                logger.error("Error sharing photo with user {}: {}", userId, e.getMessage());
            }
        }

        if (!sharedPhotos.isEmpty()) {
            sharedPhotoRepository.saveAll(sharedPhotos);
            logger.info("Successfully shared photo ID {} with {} users",
                    photo.getId(), sharedPhotos.size());
        }
    }

    public List<PhotoDto> getUserPhotos(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return photoRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Get user photos with pagination
     */
    public Page<PhotoDto> getUserPhotos(String userEmail, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Pageable pageable = PageRequest.of(page, size);
        return photoRepository.findByUserIdOrderByCreatedAtDesc(user.getId(), pageable)
                .map(this::convertToDto);
    }

    public List<PhotoDto> getSharedPhotos(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return sharedPhotoRepository.findByRecipientOrderByCreatedAtDesc(user)
                .stream()
                .map(SharedPhoto::getPhoto)
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Get shared photos with pagination
     */
    public Page<PhotoDto> getSharedPhotos(String userEmail, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Pageable pageable = PageRequest.of(page, size);
        return sharedPhotoRepository.findByRecipientOrderByCreatedAtDesc(user, pageable)
                .map(SharedPhoto::getPhoto)
                .map(this::convertToDto);
    }

    public Photo getPhotoById(Long photoId) {
        return photoRepository.findById(photoId)
                .orElseThrow(() -> new RuntimeException("Photo not found"));
    }

    /**
     * Check if user can access a photo (owner or recipient of shared photo)
     */
    public boolean canUserAccessPhoto(Long photoId, String userEmail) {
        try {
            User user = userRepository.findByEmail(userEmail)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Photo photo = photoRepository.findById(photoId)
                    .orElse(null);

            if (photo == null) {
                return false;
            }

            // User is the owner
            if (photo.getUser().getId().equals(user.getId())) {
                return true;
            }

            // Check if photo is shared with user
            return sharedPhotoRepository.findByRecipientOrderByCreatedAtDesc(user)
                    .stream()
                    .anyMatch(sp -> sp.getPhoto().getId().equals(photoId));

        } catch (Exception e) {
            logger.error("Error checking photo access: {}", e.getMessage());
            return false;
        }
    }

    private PhotoDto convertToDto(Photo photo) {
        return new PhotoDto(
                photo.getId(),
                photo.getFileName(),
                photo.getFilePath(),
                photo.getFileSize(),
                photo.getMimeType(),
                photo.getUser().getId(),
                photo.getUser().getFullName(),
                photo.getProcessingStatus().toString(),
                photo.getFacesDetected(),
                photo.getCreatedAt(),
                photo.getUpdatedAt()
        );
    }
}