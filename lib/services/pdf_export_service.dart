import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  Future<void> exportNote({
    required String folderName,
    required String title,
    required String content,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'Wyvern Notes',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Pasta: $folderName',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text(
              title.trim().isEmpty ? 'Sem título' : title.trim(),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              content.trim().isEmpty ? 'Nota vazia.' : content.trim(),
              style: const pw.TextStyle(fontSize: 13, lineSpacing: 5),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
