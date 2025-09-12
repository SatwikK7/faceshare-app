package com.faceshare.exception;

import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

import static com.faceshare.exception.CustomExceptions.*;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFound.class)
    public ResponseEntity<Map<String,Object>> handleNotFound(NotFound ex) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(BadRequest.class)
    public ResponseEntity<Map<String,Object>> handleBadRequest(BadRequest ex) {
        return build(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    @ExceptionHandler(Unauthorized.class)
    public ResponseEntity<Map<String,Object>> handleUnauthorized(Unauthorized ex) {
        return build(HttpStatus.UNAUTHORIZED, ex.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String,Object>> handleGeneric(Exception ex) {
        return build(HttpStatus.INTERNAL_SERVER_ERROR, ex.getMessage());
    }

    private ResponseEntity<Map<String,Object>> build(HttpStatus status, String message) {
        Map<String,Object> body = new HashMap<>();
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("message", message);
        body.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.status(status).body(body);
    }
}
