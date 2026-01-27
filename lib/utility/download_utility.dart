import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:laundriin/utility/permission_handler.dart';

import 'package:path_provider/path_provider.dart';

class DownloadUtility {
  downloadFile(
      {required String fileName,
      required String url,
      required Function(File) onDownloadCompleted,
      required Function(String) onDownloadFailed,
      required Function() onDownloadStarted}) async {
    /// get base storeage
    final baseStorage = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download') //FOR ANDROID
        : await getApplicationDocumentsDirectory(); //FOR iOS

    /// check file permission
    final permission = await PermissionHandler()
        .askPermission(permissions: [PermissionType.file]);
    if (permission[PermissionType.file] == true) {
      final filePath = "${baseStorage.path}/$fileName";
      File fileExist = File(filePath);

      /// File exists, open it
      if (fileExist.existsSync()) {
        onDownloadCompleted(File(filePath));
      } else {
        /// File does not exist, download it
        try {
          onDownloadStarted();
          final taskId = await FlutterDownloader.enqueue(
            fileName: fileName,
            url: url,
            headers: {},
            // optional: header send with url (auth token etc)
            savedDir: baseStorage.path,
            saveInPublicStorage: true,
            showNotification: true,
            // show download progress in status bar (for Android)
            openFileFromNotification:
                true, // click on notification to open downloaded file (for Android)
          );
          if (taskId != null) {
            onDownloadCompleted(File(filePath));
          }
        } catch (e) {
          onDownloadFailed(e.toString());
        }
      }
    } else {
      onDownloadFailed("Silahkan beri izin storage untuk mendownload file");
    }
  }
}
