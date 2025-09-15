package com.faceshare.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Component
public class StartupConfig implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(StartupConfig.class);

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Override
    public void run(String... args) throws Exception {
        // Create upload directory if it doesn't exist
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
            logger.info("Created upload directory: {}", uploadPath.toAbsolutePath());
        } else {
            logger.info("Upload directory already exists: {}", uploadPath.toAbsolutePath());
        }
    }
}