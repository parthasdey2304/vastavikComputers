import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const PdfViewerScreen({super.key, required this.title, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppTheme.primary),
            onPressed: () {
              Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primary),
            onPressed: () {
              Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => pdfBytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: '$title.pdf',
      ),
    );
  }
}
