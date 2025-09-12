package com.faceshare.controller;

import com.faceshare.dto.PhotoDto;
import com.faceshare.model.Photo;
import com.faceshare.service.PhotoService;
import com.faceshare.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
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
@CrossOrigin(origins = "*")
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

    @GetMapping("/shared")
    public ResponseEntity<List<PhotoDto>> getSharedPhotos(Authentication authentication) {
        List<PhotoDto> photos = photoService.getSharedPhotos(authentication.getName());
        return ResponseEntity.ok(photos);
    }

    @GetMapping("/view/{photoId}")
    public ResponseEntity<Resource> viewPhoto(@PathVariable Long photoId) {
        try {
            Photo photo = photoService.getPhotoById(photoId);
            Path filePath = fileStorageService.loadFileAsResource(photo.getFileName());
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