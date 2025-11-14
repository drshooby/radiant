import os
import json
import shutil
from PIL import Image
import albumentations as A
import cv2
import numpy as np

SOURCE_ROOT = "data"
TARGET_ROOT = "data_rekognition_format"
AUGS_PER_IMAGE = 3

# Augmentation pipeline with bbox-safe transforms
augmentor = A.Compose([
    A.HueSaturationValue(hue_shift_limit=25, sat_shift_limit=40, val_shift_limit=30, p=0.9),
    A.RandomBrightnessContrast(brightness_limit=0.25, contrast_limit=0.25, p=0.9),
    A.GaussianBlur(blur_limit=(3, 7), p=0.4),
    A.GaussNoise(var_limit=(10.0, 50.0), p=0.4),
    A.Rotate(limit=15, border_mode=cv2.BORDER_REFLECT_101, p=0.6),
    A.HorizontalFlip(p=0.5),
    A.RandomScale(scale_limit=0.15, p=0.5),
], bbox_params=A.BboxParams(format='yolo', label_fields=['class_labels']))


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def yolo_to_rekognition(class_id, cx, cy, w, h):
    left = cx - w / 2
    top = cy - h / 2
    return {
        "BoundingBox": {
            "Width": float(w),
            "Height": float(h),
            "Left": float(left),
            "Top": float(top)
        },
        "ClassId": int(class_id)
    }


def rekognition_to_yolo(bbox, class_id):
    left = bbox["Left"]
    top = bbox["Top"]
    width = bbox["Width"]
    height = bbox["Height"]

    cx = left + width / 2
    cy = top + height / 2

    return int(class_id), cx, cy, width, height


def process_split(split_name):
    src_img_dir = os.path.join(SOURCE_ROOT, split_name, "images")
    src_lbl_dir = os.path.join(SOURCE_ROOT, split_name, "labels")

    tgt_img_dir = os.path.join(TARGET_ROOT, split_name, "images")
    tgt_lbl_dir = os.path.join(TARGET_ROOT, split_name, "labels")

    ensure_dir(tgt_img_dir)
    ensure_dir(tgt_lbl_dir)

    if not os.path.exists(src_img_dir):
        print(f"Warning: {src_img_dir} does not exist, skipping...")
        return

    image_files = [f for f in os.listdir(src_img_dir)
                   if f.lower().endswith((".jpg", ".png", ".jpeg"))]

    print(f"\nProcessing {split_name}: {len(image_files)} images")
    processed = 0
    augmented = 0

    for img_name in image_files:
        base = os.path.splitext(img_name)[0]
        img_path = os.path.join(src_img_dir, img_name)
        lbl_path = os.path.join(src_lbl_dir, f"{base}.txt")

        if not os.path.exists(lbl_path):
            print(f"Warning: No label file for {img_name}, skipping...")
            continue

        # Read YOLO labels
        with open(lbl_path, "r") as f:
            lines = [line.strip() for line in f if line.strip()]

        if not lines:
            print(f"Warning: Empty label file for {img_name}, skipping...")
            continue

        # Parse YOLO format
        yolo_boxes = []
        class_labels = []
        for line in lines:
            parts = line.split()
            if len(parts) >= 5:
                class_id = int(parts[0])
                cx, cy, w, h = map(float, parts[1:5])
                yolo_boxes.append([cx, cy, w, h])
                class_labels.append(class_id)

        # Copy original image
        shutil.copy(img_path, os.path.join(tgt_img_dir, img_name))

        # Convert to Rekognition format
        rekognition_annotations = []
        for i, (cx, cy, w, h) in enumerate(yolo_boxes):
            rekognition_annotations.append(
                yolo_to_rekognition(class_labels[i], cx, cy, w, h)
            )

        json_path = os.path.join(tgt_lbl_dir, f"{base}.json")
        with open(json_path, "w") as jf:
            json.dump({"Annotations": rekognition_annotations}, jf, indent=4)

        processed += 1

        # Augment only for train split
        if split_name == "train":
            img = cv2.imread(img_path)
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

            for aug_idx in range(AUGS_PER_IMAGE):
                try:
                    # Apply augmentation with bounding boxes
                    transformed = augmentor(
                        image=img_rgb,
                        bboxes=yolo_boxes,
                        class_labels=class_labels
                    )

                    aug_img = transformed["image"]
                    aug_bboxes = transformed["bboxes"]
                    aug_labels = transformed["class_labels"]

                    # Skip if all bboxes were removed by augmentation
                    if not aug_bboxes:
                        continue

                    # Save augmented image
                    aug_filename = f"{base}_aug{aug_idx + 1}.jpg"
                    aug_img_path = os.path.join(tgt_img_dir, aug_filename)
                    cv2.imwrite(aug_img_path, cv2.cvtColor(aug_img, cv2.COLOR_RGB2BGR))

                    # Convert augmented boxes to Rekognition format
                    aug_rekognition_annotations = []
                    for bbox, label in zip(aug_bboxes, aug_labels):
                        cx, cy, w, h = bbox
                        aug_rekognition_annotations.append(
                            yolo_to_rekognition(label, cx, cy, w, h)
                        )

                    # Save augmented labels
                    aug_json_path = os.path.join(tgt_lbl_dir, f"{base}_aug{aug_idx + 1}.json")
                    with open(aug_json_path, "w") as jf:
                        json.dump({"Annotations": aug_rekognition_annotations}, jf, indent=4)

                    augmented += 1

                except Exception as e:
                    print(f"Warning: Augmentation failed for {img_name} (aug {aug_idx + 1}): {e}")

    print(f"  Processed: {processed} original images")
    if split_name == "train":
        print(f"  Created: {augmented} augmented images")


def main():
    print("Starting YOLO to Rekognition conversion with augmentation...")

    # Check source directory
    if not os.path.exists(SOURCE_ROOT):
        print(f"Error: Source directory '{SOURCE_ROOT}' not found!")
        return

    # Process each split
    for split in ["train", "valid", "test"]:
        process_split(split)

    print("\nConversion complete!")
    print(f"Output directory: {TARGET_ROOT}")
    print("\nNext steps:")
    print("1. Review the generated JSON files")
    print("2. Upload to S3: aws s3 sync data_rekognition_format s3://your-bucket/dataset/")


if __name__ == "__main__":
    main()