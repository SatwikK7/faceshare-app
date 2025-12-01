package com.faceshare.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "face_encodings")
public class FaceEncoding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Multiple encodings per user for better accuracy
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Store face encoding as JSON string (array of 128 floats)
    @Lob
    @Column(nullable = false, columnDefinition = "TEXT")
    private String encodingJson;

    // Optional: Reference to the photo this encoding was extracted from
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "photo_id")
    private Photo photo;

    // Track when this encoding was created
    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    // Quality score (0.0 to 1.0) - higher is better
    @Column
    private Double qualityScore;

    // Whether this is the primary encoding for the user
    @Column(nullable = false)
    private boolean isPrimary = false;

    // Constructors
    public FaceEncoding() {}

    public FaceEncoding(User user, String encodingJson) {
        this.user = user;
        this.encodingJson = encodingJson;
    }

    public FaceEncoding(User user, String encodingJson, Photo photo) {
        this.user = user;
        this.encodingJson = encodingJson;
        this.photo = photo;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getEncodingJson() { return encodingJson; }
    public void setEncodingJson(String encodingJson) { this.encodingJson = encodingJson; }
    public Photo getPhoto() { return photo; }
    public void setPhoto(Photo photo) { this.photo = photo; }
    public Instant getCreatedAt() { return createdAt; }
    public Double getQualityScore() { return qualityScore; }
    public void setQualityScore(Double qualityScore) { this.qualityScore = qualityScore; }
    public boolean isPrimary() { return isPrimary; }
    public void setPrimary(boolean primary) { isPrimary = primary; }
}
