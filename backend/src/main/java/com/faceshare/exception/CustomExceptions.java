package com.faceshare.exception;

public class CustomExceptions {

    public static class NotFound extends RuntimeException {
        public NotFound(String msg) { super(msg); }
    }

    public static class BadRequest extends RuntimeException {
        public BadRequest(String msg) { super(msg); }
    }

    public static class Unauthorized extends RuntimeException {
        public Unauthorized(String msg) { super(msg); }
    }
}
