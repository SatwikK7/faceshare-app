package com.faceshare.controller;

import com.faceshare.dto.PhotoDto;
import com.faceshare.model.Photo;
import com.faceshare.service.PhotoService;
import com.faceshare.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;
import java.util.List;

@RestController
@RequestMapping("/api/photos")
public class PhotoController {

    @Autowired
    private PhotoService photoService;

    @Autowired
    private FileStorageService fileStorageService;

    @PostMapping("/upload")
    public ResponseEntity<?> uploadPhoto(
            @RequestParam("image") MultipartFile file,
            Authentication authentication) {
        try {
            PhotoDto photo = photoService.uploadPhoto(file, authentication.getName());
            return ResponseEntity.ok(photo);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Upload failed: " + e.getMessage());
        }
    }

    @GetMapping("/my-photos")
    public ResponseEntity<List<PhotoDto>> getMyPhotos(Authentication authentication) {
        List<PhotoDto> photos = photoService.getUserPhotos(authentication.getName());
        return ResponseEntity.ok(photos);
    }

    /**
     * Get user photos with pagination
     * @param page Page number (0-indexed)
     * @param size Number of items per page
     */
    @GetMapping("/my-photos/paginated")
    public ResponseEntity<Page<PhotoDto>> getMyPhotosPaginated(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<PhotoDto> photos = photoService.getUserPhotos(authentication.getName(), page, size);
        return ResponseEntity.ok(photos);
    }

    @GetMapping("/shared")
    public ResponseEntity<List<PhotoDto>> getSharedPhotos(Authentication authentication) {
        List<PhotoDto> photos = photoService.getSharedPhotos(authentication.getName());
        return ResponseEntity.ok(photos);
    }

    /**
     * Get shared photos with pagination
     * @param page Page number (0-indexed)
     * @param size Number of items per page
     */
    @GetMapping("/shared/paginated")
    public ResponseEntity<Page<PhotoDto>> getSharedPhotosPaginated(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<PhotoDto> photos = photoService.getSharedPhotos(authentication.getName(), page, size);
        return ResponseEntity.ok(photos);
    }

    @GetMapping("/view/{photoId}")
    public ResponseEntity<?> viewPhoto(@PathVariable Long photoId, Authentication authentication) {
        try {
            // Authorization check: user must own or have access to the photo
            if (!photoService.canUserAccessPhoto(photoId, authentication.getName())) {
                return ResponseEntity.status(403).build();  // Forbidden
            }

            Photo photo = photoService.getPhotoById(photoId);
            String filePathOrUrl = photo.getFilePath();

            // If using Cloudinary, redirect to the direct URL
            if (fileStorageService.isUsingCloudStorage() && filePathOrUrl.startsWith("http")) {
                return ResponseEntity.status(302)
                        .header(HttpHeaders.LOCATION, filePathOrUrl)
                        .build();
            }

            // Local storage: serve file from backend
            String fileName = filePathOrUrl.substring(filePathOrUrl.lastIndexOf("/") + 1);
            Path filePath = fileStorageService.loadFileAsResource(fileName);
            Resource resource = new UrlResource(filePath.toUri());

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(photo.getMimeType()))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + photo.getFileName() + "\"")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
}