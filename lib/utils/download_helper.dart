// Download helper untuk mobile (menggunakan share_plus)
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> downloadCSV(String csv, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv);

  // Buka share sheet agar user bisa simpan/kirim file
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      title: 'Laporan Penjualan AmagiTrack',
    ),
  );
  return file.path;
}
