package com.faceshare.service;

import com.faceshare.dto.PhotoDto;
import com.faceshare.model.Photo;
import com.faceshare.model.User;
import com.faceshare.repository.PhotoRepository;
import com.faceshare.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PhotoService {

    @Autowired
    private PhotoRepository photoRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    public PhotoDto uploadPhoto(MultipartFile file, String userEmail) throws Exception {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String fileName = fileStorageService.storeFile(file);
        String filePath = "./uploads/" + fileName; // Full path for storage

        Photo photo = new Photo(
                file.getOriginalFilename(),
                filePath,
                file.getSize(),
                file.getContentType(),
                user
        );

        Photo savedPhoto = photoRepository.save(photo);

        // Trigger face recognition processing asynchronously
        try {
            faceRecognitionService.detectFaces(new File(savedPhoto.getFilePath()));
            savedPhoto.setProcessingStatus(Photo.ProcessingStatus.COMPLETED);
        } catch (Exception e) {
            savedPhoto.setProcessingStatus(Photo.ProcessingStatus.FAILED);
        }
        photoRepository.save(savedPhoto);


        return convertToDto(savedPhoto);
    }

    public List<PhotoDto> getUserPhotos(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return photoRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<PhotoDto> getSharedPhotos(String userEmail) {
        // Implementation for getting photos shared with user
        return List.of(); // Placeholder
    }

    public Photo getPhotoById(Long photoId) {
        return photoRepository.findById(photoId)
                .orElseThrow(() -> new RuntimeException("Photo not found"));
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