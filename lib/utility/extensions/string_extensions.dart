import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

extension StringExtension on String {
  bool isValidEmail() {
    final regex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\\.,;:\s@\"]+\.)+[^<>()[\]\\.,;:\s@\"]{2,})$');
    return regex.hasMatch(this);
  }

  bool isImage() {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    final url = toLowerCase();
    return imageExtensions.any((ext) => url.endsWith(ext));
  }

  bool isVideo() {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'wmv'];
    final url = toLowerCase();
    return videoExtensions.any((ext) => url.endsWith(ext));
  }

  String convertTimeString({String format = 'yyyy-MM-dd HH:mm:ss'}) {
    // Parse the input string into a DateTime object
    DateTime dateTime = DateTime.parse(this);

    // Format the DateTime object using the provided format
    String formattedDate = DateFormat(format).format(dateTime);

    return formattedDate;
  }

  String timeStampToString({String format = 'dd MMMM yyyy, HH:mm'}) {
    DateTime dt = DateTime.parse(this);
    DateFormat dateFormat = DateFormat(format);
    return dateFormat.format(dt);
  }

  String timeStampToStringLocal({String format = 'dd MMMM yyyy, HH:mm', BuildContext? context}) {
    // Parse the UTC time string
    DateTime dateTimeUtc = DateTime.parse(this);

    // Get the current user's local time zone
    // var local = Localizations.localeOf(context); // Replace 'context' with your actual context

    // Convert UTC time to local time
    DateTime dateTimeLocal = dateTimeUtc.toLocal();

    // Format the date and time in the desired format
    var formatter = DateFormat(format);
    String formattedDateTime = formatter.format(dateTimeLocal);

    return formattedDateTime;
  }

  DateTime timeStampToLocalDateTime() {
    // Parse the UTC time string
    DateTime dateTimeUtc = DateTime.parse(this);

    // Get the current user's local time zone
    // var local = Localizations.localeOf(context); // Replace 'context' with your actual context

    // Convert UTC time to local time
    DateTime dateTimeLocal = dateTimeUtc.toLocal();
    return dateTimeLocal;
  }

  String cleanText() {
    final text = convertStringToUnicode(replaceAll(r"\<br>", "<br>")
        .replaceAll("<br>", "\n")
        .replaceAll("\\\\", "\\")
        .replaceAll(r"\n", "\n")
        .replaceAll(r"\\", ""));
    return text.removeAllHtmlTags();
  }

  String removeAllHtmlTags() {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    return replaceAll(exp, '');
  }

  DateTime toDateTime({String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).parse(this);
    } catch (e) {
      return DateTime.now();
    }
  }

  String convertDate({String from = "yyyy-MM-dd HH:mm", required String to}) {
    try {
      DateTime tempDate = DateFormat(from).parse(this);
      return DateFormat(to, "id").format(tempDate);
    } catch (e) {
      return this;
    }
  }

  String convertStringToUnicode(String content) {
    String regex = "\\u";
    int offset = content.indexOf(regex) + regex.length;
    while (offset > 1) {
      int limit = offset + 4;
      String str = content.substring(offset, limit);
//     print(str);
      if (str.isNotEmpty) {
        String uni = String.fromCharCode(int.parse(str, radix: 16));

        content = content.replaceFirst(regex + str, uni);
//       print(content);
      }
      offset = content.indexOf(regex) + regex.length;
//     print(offset);
    }
    return content;
  }

  String getFileExtension() {
    // Split the URL by '.' to get the parts of the file name and extension
    List<String> parts = split('.');

    // If the URL has at least one dot and the last part is not empty
    if (parts.length > 1 && parts.last.isNotEmpty) {
      // Return the last part, which should be the file extension
      return parts.last;
    } else {
      // If no valid extension found, return an empty string
      return '';
    }
  }

  Future<XFile> getImageXFileByUrl() async {
    final http.Response responseData = await http.get(Uri.parse(this));
    final uint8list = responseData.bodyBytes;
    var buffer = uint8list.buffer;
    final ByteData byteData = ByteData.view(buffer);
    var tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/file${DateTime.now().millisecondsSinceEpoch}.${getFileExtension()}')
        .writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return XFile(file.path);
    // Directory tempDir = await getTemporaryDirectory();
    // String tempPath = tempDir.path;
    // String fileName = "image${DateTime.now().millisecondsSinceEpoch}";
    // File fileWrite = new File("$tempPath/$fileName");
    // Uri uri = Uri.parse(this);
    // final response = await get(uri);
    // fileWrite.writeAsBytesSync(response.bodyBytes);
    // final mimeType = lookupMimeType("$tempPath/$fileName", headerBytes: [0xFF, 0xD8]);
    // final type = mimeType?.split("/");
    // final file = XFile("$tempPath/$fileName", mimeType: mimeType);
    // return file;
  }

  // List<PointLatLng> decodePolyline() {
  //   PolylinePoints polylinePoints = PolylinePoints();
  //   final List<PointLatLng> result = polylinePoints.decodePolyline(this);
  //   print(result);
  //   return result;
  // }

  String convertTo12HourFormat() {
    // Split the time string into hours, minutes, and seconds
    List<String> parts = split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    // Convert hours to 12-hour format
    int hourIn12HourFormat = hour % 12;
    if (hourIn12HourFormat == 0) {
      hourIn12HourFormat = 12;
    }

    // Determine AM or PM
    String period = hour < 12 ? 'AM' : 'PM';

    // Format the time string
    String formattedTime =
        '${hourIn12HourFormat.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

    return formattedTime;
  }

  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
