package com.faceshare.controller;

import com.faceshare.dto.AuthResponse;
import com.faceshare.dto.AuthRequest;
import com.faceshare.dto.UserDto;
import com.faceshare.model.User;
import com.faceshare.service.JwtService;
import com.faceshare.service.UserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UserService userService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private AuthenticationManager authenticationManager;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody AuthRequest request) {
        try {
            logger.info("Registration request received for email: {}", request.getEmail());

            // Check if user already exists
            if (userService.existsByEmail(request.getEmail())) {
                logger.warn("Registration failed: User already exists with email: {}", request.getEmail());
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("User already exists with this email"));
            }

            // Create new user
            User user = userService.createUser(request.getEmail(), request.getPassword(), request.getFullName());
            logger.info("User registered successfully with ID: {}", user.getId());

            // Generate JWT token
            String token = jwtService.generateToken(user.getEmail());

            // Create response
            AuthResponse response = new AuthResponse(
                    token,
                    user.getId(),
                    user.getEmail(),
                    user.getFullName(),
                    user.getProfileImageUrl()
            );

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Registration failed for email: {}", request.getEmail(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("Registration failed: " + e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody AuthRequest request) {
        try {
            logger.info("Login request received for email: {}", request.getEmail());

            // Authenticate user
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
            );

            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            User user = userService.findByEmail(userDetails.getUsername());

            logger.info("User authenticated successfully: {}", user.getEmail());

            // Generate JWT token
            String token = jwtService.generateToken(user.getEmail());

            // Create response
            AuthResponse response = new AuthResponse(
                    token,
                    user.getId(),
                    user.getEmail(),
                    user.getFullName(),
                    user.getProfileImageUrl()
            );

            return ResponseEntity.ok(response);

        } catch (BadCredentialsException e) {
            logger.warn("Login failed: Invalid credentials for email: {}", request.getEmail());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse("Invalid email or password"));
        } catch (Exception e) {
            logger.error("Login failed for email: {}", request.getEmail(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("Login failed: " + e.getMessage()));
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestHeader("Authorization") String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(createErrorResponse("Invalid authorization header"));
            }

            String token = authHeader.substring(7);
            String email = jwtService.extractUsername(token);

            if (email != null && jwtService.isTokenValid(token, email)) {
                User user = userService.findByEmail(email);
                String newToken = jwtService.generateToken(email);

                AuthResponse response = new AuthResponse(
                        newToken,
                        user.getId(),
                        user.getEmail(),
                        user.getFullName(),
                        user.getProfileImageUrl()
                );

                return ResponseEntity.ok(response);
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse("Invalid or expired token"));

        } catch (Exception e) {
            logger.error("Token refresh failed", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("Token refresh failed"));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        try {
            if (authentication == null || !authentication.isAuthenticated()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(createErrorResponse("User not authenticated"));
            }

            User user = userService.findByEmail(authentication.getName());
            UserDto userDto = new UserDto(
                    user.getId(),
                    user.getEmail(),
                    user.getFullName(),
                    user.getProfileImageUrl(),
                    user.getCreatedAt()
            );

            return ResponseEntity.ok(userDto);

        } catch (Exception e) {
            logger.error("Failed to get current user", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("Failed to get user information"));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        // Since we're using stateless JWT, logout is handled on client side
        // In a production app, you might want to implement a token blacklist
        Map<String, String> response = new HashMap<>();
        response.put("message", "Logged out successfully");
        return ResponseEntity.ok(response);
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}