import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;

class CloudinaryService {
  // Cloudinary credentials
  // ✅ Untuk saat ini TIDAK perlu API Key karena pakai UNSIGNED Upload Preset
  // 📝 Unsigned = Anyone bisa upload tapi LIMITED ke preset yang ditentukan (safe enough)
  //
  // ⚠️ Untuk PRODUCTION (security lebih tinggi), perlu:
  // 1. Add API_KEY + API_SECRET
  // 2. Buat backend (Node.js/Python) untuk generate SIGNED tokens
  // 3. Frontend hanya kirim signed token ke Cloudinary (lebih aman)
  //
  // Untuk MVP/Testing, unsigned preset ini OK-OK aja!

  static const String CLOUD_NAME = 'dnbdwebur';
  static const String UPLOAD_PRESET = 'laundriin_orders'; // UNSIGNED preset

  // Optional: Kalau perlu signed uploads di future
  // static const String API_KEY = 'your-api-key';
  // static const String API_SECRET = 'your-api-secret';

  static const String UPLOAD_URL =
      'https://api.cloudinary.com/v1_1/$CLOUD_NAME/image/upload';

  final ImagePicker _imagePicker = ImagePicker();

  /// ===== 1. PICK IMAGE DARI CAMERA =====
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress quality
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// ===== 2. PICK IMAGE DARI GALLERY =====
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// ===== 3. COMPRESS IMAGE =====
  Future<File> _compressImage(File imageFile) async {
    try {
      // Read image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize jika terlalu besar (max width: 1024px)
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      // Encode dengan quality 85%
      final compressedBytes = img.encodeJpg(image, quality: 85);

      // Buat file baru dengan nama timestamp
      final compressedFile = File(
        '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      // Kalau gagal compress, return original file
      return imageFile;
    }
  }

  /// ===== 4. UPLOAD KE CLOUDINARY =====
  Future<String> uploadImage({
    required File imageFile,
    required String orderId,
    String photoType = 'photo', // 'before', 'after', dll
    Function(double)? onProgress, // Upload progress callback
  }) async {
    try {
      // Step 1: Compress image
      print('[CLOUDINARY] Compressing image...');
      final compressedFile = await _compressImage(imageFile);

      // Step 2: Prepare request
      print('[CLOUDINARY] Preparing upload request...');
      final request = http.MultipartRequest('POST', Uri.parse(UPLOAD_URL));

      // Add fields
      request.fields['upload_preset'] = UPLOAD_PRESET;
      request.fields['folder'] =
          'orders/$orderId'; // Auto-organize di Cloudinary
      request.fields['public_id'] =
          'photo-$photoType-${DateTime.now().millisecondsSinceEpoch}';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await compressedFile.readAsBytes(),
          filename: 'order_photo.jpg',
        ),
      );

      // Step 3: Send request
      print('[CLOUDINARY] Uploading to Cloudinary...');
      final response = await request.send();

      // Step 4: Collect response with progress tracking (FIX: stream listen hanya sekali)
      final List<int> responseBytes = [];
      final totalBytes = response.contentLength ?? 0;

      await response.stream.forEach((chunk) {
        responseBytes.addAll(chunk);
        if (totalBytes > 0 && onProgress != null) {
          onProgress(responseBytes.length / totalBytes);
        }
      });

      // Step 5: Parse response
      final responseString = String.fromCharCodes(responseBytes);
      final jsonResponse = jsonDecode(responseString);

      // Print detailed response info
      print('[CLOUDINARY] 📋 Response Status: ${response.statusCode}');
      print('[CLOUDINARY] 📋 Full Response: $jsonResponse');

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        final publicId = jsonResponse['public_id'] as String;
        final httpUrl = jsonResponse['url'] as String;
        final cloudinaryConsoleUrl =
            'https://console.cloudinary.com/console/c--${CLOUD_NAME.replaceAll('-', '_')}/media_library/search?q=$publicId';

        print('[CLOUDINARY] ✅ Upload successful!');
        print('[CLOUDINARY] 🔗 Secure URL: $secureUrl');
        print('[CLOUDINARY] 🔗 HTTP URL: $httpUrl');
        print('[CLOUDINARY] 📝 Public ID: $publicId');
        print('[CLOUDINARY] 🌐 Console Link: $cloudinaryConsoleUrl');

        // Clean up compressed file
        try {
          await compressedFile.delete();
        } catch (e) {
          print(
              '[CLOUDINARY] ⚠️ Warning: Could not delete compressed file: $e');
        }

        return secureUrl;
      } else {
        final error = jsonResponse['error']?['message'] ?? 'Unknown error';
        final code = jsonResponse['error']?['http_code'] ?? 'N/A';
        print('[CLOUDINARY] ❌ Upload failed (Code: $code): $error');
        throw Exception('Upload failed: $error');
      }
    } catch (e) {
      print('[CLOUDINARY] ❌ Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// ===== 5. UPLOAD DENGAN PILIHAN CAMERA/GALLERY =====
  /// Convenience method: langsung pilih sumber + upload
  Future<String> pickAndUploadImage({
    required String orderId,
    required ImageSource source, // ImageSource.camera atau ImageSource.gallery
    String photoType = 'photo',
    Function(double)? onProgress,
  }) async {
    try {
      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        throw Exception('No image selected');
      }

      // Upload
      return await uploadImage(
        imageFile: File(pickedFile.path),
        orderId: orderId,
        photoType: photoType,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to pick and upload image: $e');
    }
  }

  /// ===== 6. BUILD CLOUDINARY URL DENGAN TRANSFORMASI =====
  /// Contoh: resize, format conversion, dll
  static String buildTransformationUrl({
    required String publicId,
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    String url = 'https://res.cloudinary.com/$CLOUD_NAME/image/upload/';

    // Add transformations
    if (width != null) url += 'w_$width,';
    if (height != null) url += 'h_$height,';
    url += 'q_$quality/';

    url += publicId;
    return url;
  }
}
