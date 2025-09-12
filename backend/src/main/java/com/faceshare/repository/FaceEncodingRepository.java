package com.faceshare.repository;

import com.faceshare.model.FaceEncoding;
import com.faceshare.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FaceEncodingRepository extends JpaRepository<FaceEncoding, Long> {
    Optional<FaceEncoding> findByUser(User user);
    boolean existsByUser(User user);
}
