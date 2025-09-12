package com.faceshare.dto;

public class AuthResponse {
    private String token;
    private Long userId;
    private String email;
    private String fullName;
    private String profileImageUrl;

    public AuthResponse() {}

    public AuthResponse(String token, Long userId, String email, String fullName, String profileImageUrl) {
        this.token = token;
        this.userId = userId;
        this.email = email;
        this.fullName = fullName;
        this.profileImageUrl = profileImageUrl;
    }

    // Getters and Setters
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getProfileImageUrl() { return profileImageUrl; }
    public void setProfileImageUrl(String profileImageUrl) { this.profileImageUrl = profileImageUrl; }
}