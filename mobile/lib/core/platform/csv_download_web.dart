// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadCsv(String content, String filename) {
  final blob = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  (html.document.createElement('a') as html.AnchorElement)
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
