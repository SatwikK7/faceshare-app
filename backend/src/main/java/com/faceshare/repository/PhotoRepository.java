package com.faceshare.repository;

import com.faceshare.model.Photo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PhotoRepository extends JpaRepository<Photo, Long> {
    List<Photo> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<Photo> findByProcessingStatusOrderByCreatedAtDesc(Photo.ProcessingStatus status);
}