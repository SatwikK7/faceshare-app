package com.faceshare.controller;

import com.faceshare.model.SharedPhoto;
import com.faceshare.model.User;
import com.faceshare.repository.SharedPhotoRepository;
import com.faceshare.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/shared")
public class SharedPhotoController {

    private final SharedPhotoRepository sharedRepo;
    private final UserRepository userRepo;

    public SharedPhotoController(SharedPhotoRepository sharedRepo, UserRepository userRepo) {
        this.sharedRepo = sharedRepo;
        this.userRepo = userRepo;
    }

    // list photos shared *to me*
    @GetMapping("/inbox")
    public ResponseEntity<List<SharedPhoto>> inbox(Principal principal) {
        User me = userRepo.findByEmail(principal.getName()).orElse(null);
        if (me == null) return ResponseEntity.status(401).build();
        return ResponseEntity.ok(sharedRepo.findByRecipientOrderByCreatedAtDesc(me));
    }
}
