package com.faceshare;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@SpringBootApplication
@EnableAsync
@EnableTransactionManagement
@ConfigurationPropertiesScan
public class FaceShareApplication {

    public static void main(String[] args) {
        SpringApplication.run(FaceShareApplication.class, args);
        System.out.println("===========================================");
        System.out.println("🚀 FaceShare Backend Started Successfully!");
        System.out.println("📱 API Documentation: http://localhost:8080/");
        System.out.println("🗄️  H2 Console: http://localhost:8080/h2-console");
        System.out.println("===========================================");
    }
}