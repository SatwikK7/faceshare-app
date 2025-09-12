package com.faceshare.dto;

import java.time.LocalDateTime;

public class PhotoDto {
    private Long id;
    private String fileName;
    private String filePath;
    private Long fileSize;
    private String mimeType;
    private Long userId;
    private String userFullName;
    private String processingStatus;
    private Integer facesDetected;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public PhotoDto() {}

    public PhotoDto(Long id, String fileName, String filePath, Long fileSize, String mimeType,
                    Long userId, String userFullName, String processingStatus, Integer facesDetected,
                    LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.fileName = fileName;
        this.filePath = filePath;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
        this.userId = userId;
        this.userFullName = userFullName;
        this.processingStatus = processingStatus;
        this.facesDetected = facesDetected;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }

    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUserFullName() { return userFullName; }
    public void setUserFullName(String userFullName) { this.userFullName = userFullName; }

    public String getProcessingStatus() { return processingStatus; }
    public void setProcessingStatus(String processingStatus) { this.processingStatus = processingStatus; }

    public Integer getFacesDetected() { return facesDetected; }
    public void setFacesDetected(Integer facesDetected) { this.facesDetected = facesDetected; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}