# Pipeline - Intelligent Image Optimization Tester

Pipeline is a Flutter application designed to test and validate an advanced, AI-driven image optimization pipeline. The app challenges users to guess which version of an image has been compressed, serving as a gamified A/B testing ground to determine the perceptual success of the compression system. 

*Note: This application was built with the assistance of AI, based directly on my custom architectural design.*

## The Compression System Architecture

The core of this project is a highly sophisticated, content-aware image compression pipeline designed to minimize file size while strictly preserving the visual integrity of important image elements (like faces, text, and primary subjects).

### How It Works

1. **Smart Concurrency & Baseline Scaling**: The pipeline dynamically detects the device's hardware capabilities (core count) to adjust processing concurrency, preventing memory crashes. Images are decoded, EXIF orientation is baked in, and they are scaled to a 1080p baseline using a separate isolate for performance.
2. **Multi-Model Machine Learning Analysis**: Using Google ML Kit, the system runs four models concurrently:
   - **Subject Segmentation**: Generates a foreground confidence mask to separate the primary subject from the background.
   - **Text Recognition**: Detects and extracts bounding boxes for any text within the image.
   - **Image Labeling**: Identifies the context of the image (e.g., classifying it as "art", "poster", or "illustration").
   - **Face Detection**: Counts the number of faces in the photo to identify group shots.
3. **Dynamic Quality & Smart Bypass**: The WebP compression quality dynamically scales based on the percentage of the image occupied by the primary subject. Crucially, the system includes a "Smart Bypass": if an image is detected as a poster/art, a group photo (3+ faces), or lacks a clear subject, it bypasses background blurring to protect UI icons, artistic details, and background context.
4. **GPU Compositing (Selective Blurring)**: For standard images, the pipeline uses hardware-accelerated `dart:ui` drawing to slightly blur the background while keeping the segmented foreground subject and any detected text boxes perfectly sharp. This reduces the high-frequency detail in the background, allowing the final WebP encoder to compress the image much more efficiently without degrading the perceived quality of the subject.
5. **WebP Compression**: The final composited image is encoded into the WebP format, yielding massive file size savings.

### Application for Social Media (Instagram, X, etc.)

This pipeline is exceptionally well-suited for social media applications that handle millions of image uploads daily:
- **Bandwidth & Storage Savings**: By selectively blurring backgrounds (which users naturally pay less attention to) and preserving subjects/text, platforms can achieve aggressive WebP compression rates, saving petabytes of server storage and drastically cutting CDN bandwidth costs.
- **Improved User Experience**: Smaller file sizes mean faster upload times for creators and near-instant loading times for consumers scrolling through their feeds, especially on slower cellular networks.
- **Content-Aware Preservation**: Unlike naive compression that aggressively crushes the entire image (often ruining memes, screenshots, or text-heavy posts), this system understands *what* it's compressing. Memes stay readable, and group photos keep everyone's face sharp.

## How to Test It

You can test the application by installing the APK directly onto your Android device.

1. Navigate to the `build/app/outputs/flutter-apk/` directory within this repository (if it has been built).
2. Locate the `app-release.apk` file.
3. Transfer the APK to your Android device and install it (ensure you have "Install from Unknown Sources" enabled in your device settings).

*Note: If the APK is not present in the repository, you can build it yourself by running `flutter build apk --release` from the root of the project.*
