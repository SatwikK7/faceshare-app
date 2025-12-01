package com.faceshare.repository;

import com.faceshare.model.Photo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PhotoRepository extends JpaRepository<Photo, Long> {
    // Non-paginated methods for backward compatibility
    List<Photo> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<Photo> findByProcessingStatusOrderByCreatedAtDesc(Photo.ProcessingStatus status);

    // Paginated methods
    Page<Photo> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
    Page<Photo> findByProcessingStatusOrderByCreatedAtDesc(Photo.ProcessingStatus status, Pageable pageable);
}