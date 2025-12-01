package com.faceshare.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.Map;

/**
 * Service for managing image uploads to Cloudinary
 * Replaces local file storage for production deployment
 */
@Service
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public CloudinaryService(@Value("${cloudinary.url:}") String cloudinaryUrl) {
        if (cloudinaryUrl != null && !cloudinaryUrl.isEmpty()) {
            // Production: Use Cloudinary URL from environment
            this.cloudinary = new Cloudinary(cloudinaryUrl);
        } else {
            // Development: Use local storage (Cloudinary disabled)
            this.cloudinary = null;
        }
    }

    /**
     * Check if Cloudinary is configured
     */
    public boolean isEnabled() {
        return cloudinary != null;
    }

    /**
     * Upload image to Cloudinary
     *
     * @param file MultipartFile to upload
     * @param folder Cloudinary folder (e.g., "faceshare/photos")
     * @return Cloudinary URL of uploaded image
     */
    @SuppressWarnings("unchecked")
    public String uploadImage(MultipartFile file, String folder) throws IOException {
        if (!isEnabled()) {
            throw new IllegalStateException("Cloudinary is not configured. Set CLOUDINARY_URL environment variable.");
        }

        Map<String, Object> uploadResult = cloudinary.uploader().upload(file.getBytes(),
                ObjectUtils.asMap(
                        "folder", folder,
                        "resource_type", "image",
                        "quality", "auto:good",
                        "format", "jpg" // Convert all to JPG for consistency
                ));

        return (String) uploadResult.get("secure_url");
    }

    /**
     * Upload image from File (for AI service processing)
     */
    @SuppressWarnings("unchecked")
    public String uploadImage(File file, String folder) throws IOException {
        if (!isEnabled()) {
            throw new IllegalStateException("Cloudinary is not configured. Set CLOUDINARY_URL environment variable.");
        }

        Map<String, Object> uploadResult = cloudinary.uploader().upload(file,
                ObjectUtils.asMap(
                        "folder", folder,
                        "resource_type", "image",
                        "quality", "auto:good",
                        "format", "jpg"
                ));

        return (String) uploadResult.get("secure_url");
    }

    /**
     * Delete image from Cloudinary by public ID
     *
     * @param publicId Cloudinary public ID (extracted from URL)
     */
    public void deleteImage(String publicId) throws IOException {
        if (!isEnabled()) {
            return; // Silently skip if Cloudinary not configured
        }

        cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
    }

    /**
     * Extract Cloudinary public ID from URL
     * URL format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{public_id}.jpg
     *
     * @param url Cloudinary URL
     * @return Public ID or null if not a Cloudinary URL
     */
    public String extractPublicId(String url) {
        if (url == null || !url.contains("cloudinary.com")) {
            return null;
        }

        try {
            // Extract public_id from URL
            String[] parts = url.split("/upload/");
            if (parts.length < 2) return null;

            String afterUpload = parts[1];
            // Remove version (v123456789/)
            String withoutVersion = afterUpload.replaceFirst("v\\d+/", "");
            // Remove extension
            return withoutVersion.replaceFirst("\\.[^.]+$", "");
        } catch (Exception e) {
            return null;
        }
    }
}
