package com.faceshare.config;

import com.faceshare.model.FaceEncoding;
import com.faceshare.model.User;
import com.faceshare.repository.FaceEncodingRepository;
import com.faceshare.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FaceEncodingRepository faceEncodingRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Check if users already exist
        if (userRepository.count() == 0) {
            logger.info("Initializing default users...");
            
            // Create Alice
            User alice = new User();
            alice.setEmail("alice@example.com");
            alice.setPassword(passwordEncoder.encode("password"));
            alice.setFullName("Alice Johnson");
            alice.setEnabled(true);
            alice = userRepository.save(alice);
            
            // Create Bob
            User bob = new User();
            bob.setEmail("bob@example.com");
            bob.setPassword(passwordEncoder.encode("password"));
            bob.setFullName("Bob Smith");
            bob.setEnabled(true);
            bob = userRepository.save(bob);
            
            // Create face encodings
            FaceEncoding aliceEncoding = new FaceEncoding();
            aliceEncoding.setUser(alice);
            aliceEncoding.setEncodingJson("[0.1, 0.2, 0.3]");
            faceEncodingRepository.save(aliceEncoding);
            
            FaceEncoding bobEncoding = new FaceEncoding();
            bobEncoding.setUser(bob);
            bobEncoding.setEncodingJson("[0.11, 0.21, 0.31]");
            faceEncodingRepository.save(bobEncoding);
            
            logger.info("Default users and face encodings created successfully");
            logger.info("Alice: alice@example.com / password");
            logger.info("Bob: bob@example.com / password");
        } else {
            logger.info("Users already exist, skipping initialization");
        }
    }
}