package com.faceshare.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * File Storage Service - supports both local and Cloudinary storage
 * - Development: Uses local filesystem (./uploads/)
 * - Production: Uses Cloudinary (if CLOUDINARY_URL env var is set)
 */
@Service
public class FileStorageService {

    private static final Logger logger = LoggerFactory.getLogger(FileStorageService.class);

    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    private final CloudinaryService cloudinaryService;

    @Autowired
    public FileStorageService(CloudinaryService cloudinaryService) {
        this.cloudinaryService = cloudinaryService;
    }

    /**
     * Store file - uses Cloudinary if configured, otherwise local storage
     *
     * @param file MultipartFile to store
     * @return Cloudinary URL or local filename
     */
    public String storeFile(MultipartFile file) throws IOException {
        // Use Cloudinary if configured
        if (cloudinaryService.isEnabled()) {
            logger.info("Uploading file to Cloudinary: {}", file.getOriginalFilename());
            String cloudinaryUrl = cloudinaryService.uploadImage(file, "faceshare/photos");
            logger.info("File uploaded to Cloudinary: {}", cloudinaryUrl);
            return cloudinaryUrl;
        }

        // Fallback to local storage for development
        logger.info("Cloudinary not configured, using local storage");
        return storeFileLocally(file);
    }

    /**
     * Store file locally (development mode)
     */
    private String storeFileLocally(MultipartFile file) throws IOException {
        // Create upload directory if it doesn't exist
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        // Generate unique filename
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = "";
        if (originalFileName.contains(".")) {
            fileExtension = originalFileName.substring(originalFileName.lastIndexOf("."));
        }

        String fileName = UUID.randomUUID().toString() + fileExtension;

        // Store file
        Path targetLocation = uploadPath.resolve(fileName);
        Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

        logger.info("File stored locally: {}", fileName);

        // Return local path for database storage
        return uploadDir + "/" + fileName;
    }

    /**
     * Load file as resource (only for local storage)
     * For Cloudinary URLs, this method is not used - frontend accesses URLs directly
     */
    public Path loadFileAsResource(String filePathOrUrl) {
        // If it's a Cloudinary URL, we don't serve it from backend
        if (filePathOrUrl != null && filePathOrUrl.startsWith("http")) {
            throw new UnsupportedOperationException(
                "Cloudinary URLs should be accessed directly by frontend, not through backend"
            );
        }

        // Local file path
        Path filePath = Paths.get(filePathOrUrl).normalize();
        if (Files.exists(filePath) && Files.isReadable(filePath)) {
            return filePath;
        } else {
            throw new RuntimeException("File not found: " + filePathOrUrl);
        }
    }

    /**
     * Delete file - handles both Cloudinary and local storage
     */
    public boolean deleteFile(String filePathOrUrl) {
        try {
            // Check if it's a Cloudinary URL
            if (cloudinaryService.isEnabled() && filePathOrUrl != null && filePathOrUrl.contains("cloudinary.com")) {
                String publicId = cloudinaryService.extractPublicId(filePathOrUrl);
                if (publicId != null) {
                    cloudinaryService.deleteImage(publicId);
                    logger.info("Deleted file from Cloudinary: {}", publicId);
                    return true;
                }
            }

            // Local file deletion
            Path filePath = Paths.get(filePathOrUrl).normalize();
            boolean deleted = Files.deleteIfExists(filePath);
            if (deleted) {
                logger.info("Deleted local file: {}", filePathOrUrl);
            }
            return deleted;

        } catch (IOException e) {
            logger.error("Error deleting file: {}", filePathOrUrl, e);
            return false;
        }
    }

    /**
     * Check if using cloud storage
     */
    public boolean isUsingCloudStorage() {
        return cloudinaryService.isEnabled();
    }
}
