

import 'dart:io';

extension FileExtensions on File{
  Future<double> get sizeInMB async {
    // Get file length in bytes and convert to MB
    final bytes = await length();
    return bytes / (1024 * 1024);
  }

  // Returns the file name
  String get fileName {
    return path.split('/').last;
  }
}