import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const PdfViewerScreen({super.key, required this.title, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.print, color: AppTheme.primary),
            onPressed: () {
              Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
            tooltip: 'Print',
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppTheme.primary),
            onPressed: () {
              Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => Uint8List.fromList(pdfBytes),
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
