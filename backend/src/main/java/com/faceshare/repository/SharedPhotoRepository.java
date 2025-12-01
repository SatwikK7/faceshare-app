package com.faceshare.repository;

import com.faceshare.model.SharedPhoto;
import com.faceshare.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SharedPhotoRepository extends JpaRepository<SharedPhoto, Long> {
    // Non-paginated for backward compatibility
    List<SharedPhoto> findByRecipientOrderByCreatedAtDesc(User recipient);

    // Paginated
    Page<SharedPhoto> findByRecipientOrderByCreatedAtDesc(User recipient, Pageable pageable);
}
