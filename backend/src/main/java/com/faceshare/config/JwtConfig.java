package com.faceshare.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JwtConfig {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration:3600000}")
    private long expirationMs;

    @Value("${security.jwt.header:Authorization}")
    private String header;

    public String getSecret() { return secret; }
    public long getExpirationMs() { return expirationMs; }
    public String getHeader() { return header; }
}
