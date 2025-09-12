package com.faceshare.model;

import jakarta.persistence.*;

@Entity
@Table(name = "face_encodings", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id"})
})
public class FaceEncoding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // one encoding per user for now (can be expanded to multiple later)
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    // store as JSON string (array of floats). Alternative: separate table.
    @Lob
    @Column(nullable = false)
    private String encodingJson;

    public Long getId() { return id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getEncodingJson() { return encodingJson; }
    public void setEncodingJson(String encodingJson) { this.encodingJson = encodingJson; }
}
