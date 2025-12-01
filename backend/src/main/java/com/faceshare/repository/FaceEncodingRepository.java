package com.faceshare.repository;

import com.faceshare.model.FaceEncoding;
import com.faceshare.model.Photo;
import com.faceshare.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface FaceEncodingRepository extends JpaRepository<FaceEncoding, Long> {
    // Find all encodings for a user (supports multiple faces)
    List<FaceEncoding> findByUser(User user);

    // Find primary encoding for a user
    Optional<FaceEncoding> findByUserAndIsPrimaryTrue(User user);

    // Check if user has any encodings
    boolean existsByUser(User user);

    // Find encodings by photo
    List<FaceEncoding> findByPhoto(Photo photo);

    // Get all encodings for face matching
    @Query("SELECT fe FROM FaceEncoding fe WHERE fe.qualityScore IS NULL OR fe.qualityScore >= :minQuality")
    List<FaceEncoding> findAllWithMinQuality(Double minQuality);
}
