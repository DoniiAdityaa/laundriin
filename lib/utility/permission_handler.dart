import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionType {
  location,
  notification,
  camera,
  media,
  image,
  video,
  file,
}

class PermissionHandler {
  /// Ask for permission, if granted returns true
  Future<Map<PermissionType, bool>> askPermission({required List<PermissionType> permissions}) async {
    Map<PermissionType, bool> permissionResult = {};
    for (var permissionType in permissions) {
      switch (permissionType) {
        case PermissionType.location:
          {
            var status = await Permission.location.request();
            permissionResult.addAll({PermissionType.location: status.isGranted});
          }
        case PermissionType.notification:
          {
            var status = await Permission.notification.request();
            permissionResult.addAll({PermissionType.notification: status.isGranted});
          }

        case PermissionType.camera:
          {
            var status = await Permission.camera.request();
            permissionResult.addAll({PermissionType.camera: status.isGranted});
          }
        case PermissionType.media:
          {}
        case PermissionType.image:
          {
            if (Platform.isAndroid) {
              var androidInfo = await DeviceInfoPlugin().androidInfo;
              var sdkInt = androidInfo.version.sdkInt;
              if (sdkInt >= 33) {
                var status = await Permission.photos.request();
                permissionResult.addAll({PermissionType.image: status.isGranted});
              } else {
                var status = await Permission.storage.request();
                permissionResult.addAll({PermissionType.image: status.isGranted});
              }
            } else if (Platform.isIOS) {
              var status = await Permission.mediaLibrary.request();
              permissionResult.addAll({PermissionType.image: status.isGranted});
            }
          }
        case PermissionType.video:
          {
            if (Platform.isAndroid) {
              var androidInfo = await DeviceInfoPlugin().androidInfo;
              var sdkInt = androidInfo.version.sdkInt;
              if (sdkInt >= 33) {
                var status = await Permission.videos.request();
                permissionResult.addAll({PermissionType.video: status.isGranted});
              } else {
                var status = await Permission.storage.request();
                permissionResult.addAll({PermissionType.video: status.isGranted});
              }
            } else if (Platform.isIOS) {
              var status = await Permission.mediaLibrary.request();
              permissionResult.addAll({PermissionType.video: status.isGranted});
            }
          }
        case PermissionType.file:
          {
            if (Platform.isAndroid) {
              var androidInfo = await DeviceInfoPlugin().androidInfo;
              var sdkInt = androidInfo.version.sdkInt;
              if (sdkInt >= 33) {
                var statusPhoto = await Permission.photos.request();
                var statusVideo = await Permission.videos.request();
                var statusAudio = await Permission.audio.request();
                permissionResult.addAll(
                    {PermissionType.file: statusPhoto.isGranted && statusVideo.isGranted && statusAudio.isGranted});
              } else {
                var status = await Permission.storage.request();
                permissionResult.addAll({PermissionType.file: status.isGranted});
              }
            } else if (Platform.isIOS) {
              var status = await Permission.storage.request();
              permissionResult.addAll({PermissionType.file: status.isGranted});
            }
          }
      }
    }

    return permissionResult;
  }
}
