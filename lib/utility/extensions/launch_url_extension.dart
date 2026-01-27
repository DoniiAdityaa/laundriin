import 'package:url_launcher/url_launcher.dart';

extension LaunchUrlExtension on String {
  static Future<void> launchXenditLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        webViewConfiguration: WebViewConfiguration(
          enableJavaScript: true,
        ),
        Uri.parse(url),
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchMap({required double latitude, required double longitude}) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl));
    } else {
      throw 'Could not open the map.';
    }
  }
}
