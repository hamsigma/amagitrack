// Download helper untuk Web (menggunakan package:web)
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> downloadCSV(String csv, String fileName) async {
  final bytes = utf8.encode(csv);
  final jsArray = bytes.toJS;
  final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return fileName;
}
