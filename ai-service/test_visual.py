"""
FaceShare - Visual Face Detection Test
Run from command line: python test_visual.py
"""
import cv2
import numpy as np
import matplotlib.pyplot as plt
from services.insightface_onnx import InsightFaceONNX
import os

def draw_faces(img, faces):
    """
    Draw bounding boxes and landmarks on detected faces

    Args:
        img: Original image
        faces: List of detected faces with bbox, kps, score

    Returns:
        Image with drawn boxes and landmarks
    """
    img_copy = img.copy()

    for i, face in enumerate(faces):
        bbox = face['bbox'].astype(int)
        kps = face['kps'].astype(int)
        score = face['score']

        # Draw bounding box (green, thick)
        cv2.rectangle(img_copy,
                     (bbox[0], bbox[1]),
                     (bbox[2], bbox[3]),
                     (0, 255, 0), 4)

        # Draw confidence score
        text = f"Face #{i+1}: {score:.2f}"
        cv2.putText(img_copy, text,
                   (bbox[0], bbox[1]-10),
                   cv2.FONT_HERSHEY_SIMPLEX,
                   1.0, (0, 255, 0), 3)

        # Draw 5 facial landmarks (red circles)
        for point in kps:
            cv2.circle(img_copy, tuple(point), 8, (0, 0, 255), -1)

    return img_copy


def test_single_image(face_service, image_name):
    """Test detection on a single image"""
    test_dir = "test_images"
    img_path = os.path.join(test_dir, image_name)

    if not os.path.exists(img_path):
        print(f"Error: {img_path} not found")
        return

    print(f"\n{'='*60}")
    print(f"Testing: {image_name}")
    print('='*60)

    # Load and process
    img = face_service.preprocess_image(img_path)
    print(f"Image size: {img.shape[1]}x{img.shape[0]} pixels")

    # Detect faces
    faces = face_service.detect_faces(img)
    print(f"\nDetected {len(faces)} face(s)")

    # Show detection details
    for i, face in enumerate(faces):
        print(f"\nFace #{i+1}:")
        print(f"  Confidence: {face['score']:.3f}")
        print(f"  Bounding box: {face['bbox'].astype(int)}")
        print(f"  Landmarks: {face['kps'].astype(int)}")

    # Draw and display
    img_with_boxes = draw_faces(img, faces)
    img_rgb = cv2.cvtColor(img_with_boxes, cv2.COLOR_BGR2RGB)

    plt.figure(figsize=(15, 10))
    plt.imshow(img_rgb)
    plt.title(f"{image_name} - Detected {len(faces)} face(s)", fontsize=16)
    plt.axis('off')
    plt.tight_layout()
    plt.show()  # Shows in popup window


def test_all_images(face_service):
    """Test detection on all images in test_images folder"""
    test_dir = "test_images"
    image_files = [f for f in os.listdir(test_dir)
                   if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

    if not image_files:
        print("No images found in test_images folder")
        return

    print(f"\n{'='*60}")
    print(f"PROCESSING ALL IMAGES")
    print('='*60)
    print(f"Found {len(image_files)} images:")
    for img_file in image_files:
        print(f"  - {img_file}")

    # Process all images
    results = {}
    for img_file in image_files:
        img_path = os.path.join(test_dir, img_file)
        img = face_service.preprocess_image(img_path)
        faces = face_service.detect_faces(img)

        results[img_file] = {
            'image': img,
            'faces': faces,
            'count': len(faces)
        }
        print(f"{img_file}: {len(faces)} face(s)")

    # Display all in grid
    num_images = len(image_files)
    cols = 2
    rows = (num_images + 1) // 2

    fig, axes = plt.subplots(rows, cols, figsize=(20, 10*rows))
    if num_images == 1:
        axes = [axes]
    else:
        axes = axes.flatten()

    for idx, img_file in enumerate(image_files):
        result = results[img_file]
        img_with_boxes = draw_faces(result['image'], result['faces'])
        img_rgb = cv2.cvtColor(img_with_boxes, cv2.COLOR_BGR2RGB)

        axes[idx].imshow(img_rgb)
        axes[idx].set_title(f"{img_file}\n{result['count']} face(s) detected",
                           fontsize=14, fontweight='bold')
        axes[idx].axis('off')

    # Hide extra subplots
    for idx in range(num_images, len(axes)):
        axes[idx].axis('off')

    plt.tight_layout()
    plt.show()

    # Print summary
    print(f"\n{'='*60}")
    print("DETECTION SUMMARY")
    print('='*60)
    total_faces = 0
    for img_file, result in results.items():
        print(f"{img_file}: {result['count']} face(s)")
        total_faces += result['count']
    print(f"\nTotal faces across all images: {total_faces}")


def test_face_matching(face_service, image1, image2):
    """Compare faces between two images"""
    test_dir = "test_images"

    print(f"\n{'='*60}")
    print(f"FACE MATCHING TEST")
    print('='*60)
    print(f"Comparing: {image1} vs {image2}")

    # Process both images
    result1 = face_service.process_image(os.path.join(test_dir, image1))
    result2 = face_service.process_image(os.path.join(test_dir, image2))

    print(f"\n{image1}: {result1['faces_detected']} face(s)")
    print(f"{image2}: {result2['faces_detected']} face(s)")

    if result1['faces_detected'] == 0 or result2['faces_detected'] == 0:
        print("\nError: Need at least one face in each image to compare")
        return

    # Compare first face from each image
    emb1 = np.array(result1['face_encodings'][0])
    emb2 = np.array(result2['face_encodings'][0])

    similarity, is_match = face_service.compare_faces(emb1, emb2, threshold=0.4)

    print(f"\n{'='*60}")
    print("RESULT")
    print('='*60)
    print(f"Similarity: {similarity:.4f} ({similarity*100:.1f}%)")
    print(f"Distance: {1-similarity:.4f}")
    print(f"Threshold: 0.4 (40%)")
    print(f"Match: {'YES - SAME PERSON ✓' if is_match else 'NO - DIFFERENT PEOPLE ✗'}")

    # Interpretation
    print("\nInterpretation:")
    if similarity >= 0.7:
        print("  🟢 HIGH confidence - Definitely same person")
    elif similarity >= 0.5:
        print("  🟡 MEDIUM confidence - Likely same person")
    elif similarity >= 0.4:
        print("  🟠 LOW confidence - Possibly same person")
    else:
        print("  🔴 Different people")

    # Compare all faces if multiple detected
    if result1['faces_detected'] > 1 or result2['faces_detected'] > 1:
        print(f"\nAll combinations:")
        for i in range(result1['faces_detected']):
            for j in range(result2['faces_detected']):
                emb1 = np.array(result1['face_encodings'][i])
                emb2 = np.array(result2['face_encodings'][j])
                sim, match = face_service.compare_faces(emb1, emb2, threshold=0.4)
                print(f"  {image1} face#{i+1} vs {image2} face#{j+1}: {sim:.4f} ({sim*100:.1f}%)")


def analyze_embedding(face_service, image_name):
    """Analyze embedding quality"""
    test_dir = "test_images"
    img_path = os.path.join(test_dir, image_name)

    print(f"\n{'='*60}")
    print(f"EMBEDDING ANALYSIS: {image_name}")
    print('='*60)

    result = face_service.process_image(img_path)

    if result['faces_detected'] == 0:
        print("No faces detected")
        return

    embedding = np.array(result['face_encodings'][0])

    print(f"Dimension: {len(embedding)}")
    print(f"L2 Norm: {np.linalg.norm(embedding):.6f} (should be ~1.0)")
    print(f"Min value: {embedding.min():.4f}")
    print(f"Max value: {embedding.max():.4f}")
    print(f"Mean: {embedding.mean():.4f}")
    print(f"Std dev: {embedding.std():.4f}")

    # Plot histogram
    plt.figure(figsize=(12, 5))
    plt.hist(embedding, bins=50, color='blue', alpha=0.7, edgecolor='black')
    plt.title(f"Embedding Distribution - {image_name}", fontsize=14, fontweight='bold')
    plt.xlabel("Value", fontsize=12)
    plt.ylabel("Frequency", fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


def main():
    """Main test function"""
    print("="*60)
    print("FACESHARE - VISUAL FACE DETECTION TEST")
    print("="*60)

    # Initialize face recognition
    print("\nInitializing InsightFace ONNX...")
    face_service = InsightFaceONNX(
        det_model_path="models/det_10g.onnx",
        rec_model_path="models/w600k_r50.onnx"
    )
    print("Ready!\n")

    # Menu
    while True:
        print("\n" + "="*60)
        print("MENU")
        print("="*60)
        print("1. Test single image (with bounding boxes)")
        print("2. Test all images (grid view)")
        print("3. Compare two images (face matching)")
        print("4. Analyze embedding quality")
        print("5. Exit")

        choice = input("\nEnter choice (1-5): ").strip()

        if choice == '1':
            image_name = input("Enter image filename (e.g., me1.JPG): ").strip()
            test_single_image(face_service, image_name)

        elif choice == '2':
            test_all_images(face_service)

        elif choice == '3':
            image1 = input("Enter first image (e.g., me1.JPG): ").strip()
            image2 = input("Enter second image (e.g., me2.jpg): ").strip()
            test_face_matching(face_service, image1, image2)

        elif choice == '4':
            image_name = input("Enter image filename: ").strip()
            analyze_embedding(face_service, image_name)

        elif choice == '5':
            print("\nExiting...")
            break

        else:
            print("\nInvalid choice. Please enter 1-5.")


if __name__ == "__main__":
    main()
