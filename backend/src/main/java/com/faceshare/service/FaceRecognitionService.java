package com.faceshare.service;

import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.*;
import org.springframework.web.client.RestTemplate;

import java.io.File;
import java.util.Map;

@Service
public class FaceRecognitionService {

    private final RestTemplate restTemplate = new RestTemplate();

    // Example endpoint the AI service should expose: POST /detect
    // Returns JSON: { success: true, faces_detected: N, face_locations: [...], face_encodings: [[...],[...]] }
    public Map<String, Object> detectFaces(File imageFile) {
        String url = "http://localhost:5000/detect";
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new FileSystemResource(imageFile));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        HttpEntity<MultiValueMap<String, Object>> req = new HttpEntity<>(body, headers);
        // ResponseEntity<Map> resp = restTemplate.postForEntity(url, req, Map.class);
        // return resp.getBody();
        ResponseEntity<Map<String, Object>> resp =
        restTemplate.postForEntity(url, req, (Class<Map<String, Object>>)(Class<?>)Map.class);
        return resp.getBody();
    }
}
