import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note_model.dart';

class PdfExportService {
  Future<void> exportNote({
    required String folderName,
    required String title,
    required String content,
    List<ChecklistItemModel> checklist = const [],
  }) async {
    final pdf = pw.Document();
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final logoBytes = await _loadLogoBytes();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    width: 28,
                    height: 28,
                    margin: const pw.EdgeInsets.only(right: 10),
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                pw.Text(
                  'Wyvern Notes',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 22,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              title.trim().isEmpty ? 'Sem titulo' : title.trim(),
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 20,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Pasta: $folderName',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            ..._buildContentWidgets(
              content: content,
              regularFont: regularFont,
            ),
            if (checklist.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Checklist',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 10),
              ...checklist.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Bullet(
                    text: item.text.trim().isEmpty ? 'Item vazio' : item.text,
                    bulletMargin: const pw.EdgeInsets.only(right: 8, top: 2),
                    bulletSize: 5,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                      lineSpacing: 4,
                    ),
                    bulletColor: item.isDone
                        ? PdfColors.green700
                        : PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  List<pw.Widget> _buildContentWidgets({
    required String content,
    required pw.Font regularFont,
  }) {
    final cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      return [
        pw.Text(
          'Nota vazia.',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 13,
            lineSpacing: 5,
          ),
        ),
      ];
    }

    final paragraphs = cleanContent
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return paragraphs
        .map(
          (paragraph) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Paragraph(
              text: paragraph,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 13,
                lineSpacing: 5,
              ),
            ),
          ),
        )
        .toList();
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load('assets/icons/wyvern_launcher_icon.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
