-- Users (passwords should be encoded by your UserService at create-time; for dev, you can store already-encoded)
-- If you rely on Spring Security’s PasswordEncoder, consider creating via a CommandLineRunner instead.
INSERT INTO users (id, email, password_hash, display_name, created_at)
VALUES
  (1, 'alice@example.com', '{noop}password', 'Alice', CURRENT_TIMESTAMP),
  (2, 'bob@example.com',   '{noop}password', 'Bob',   CURRENT_TIMESTAMP);

-- Photos (assuming you have a Photo entity with user_id, file_path, created_at, processing_status)
-- Keep empty initially, you will upload via API.

-- Face encodings (store dummy encodings as JSON strings for now)
INSERT INTO face_encodings (id, user_id, encoding_json) VALUES
  (1, 1, '[0.1, 0.2, 0.3]'),
  (2, 2, '[0.11, 0.21, 0.31]');
