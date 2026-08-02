import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuizExportService {
  
  static Future<void> exportQuestionScript(String topic, List<Map<String, dynamic>> quizData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Question Script: $topic', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          ...quizData.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final options = q['options'] as List<dynamic>;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Q${idx + 1}. ${q['question']}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...options.asMap().entries.map((opt) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                    child: pw.Text('${String.fromCharCode(65 + opt.key)}. ${opt.value}', style: const pw.TextStyle(fontSize: 12)),
                  );
                }),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    final fileName = '${topic.replaceAll(' ', '_')}_Questions.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<void> exportAnswerScript(String topic, List<Map<String, dynamic>> quizData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Answer Script: $topic', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          ...quizData.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final options = q['options'] as List<dynamic>;
            final correctIdx = q['correctAnswerIndex'] as int;
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Q${idx + 1}. ${q['question']}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...options.asMap().entries.map((opt) {
                  final isCorrect = opt.key == correctIdx;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                    child: pw.Text(
                      '${String.fromCharCode(65 + opt.key)}. ${opt.value}${isCorrect ? '  (✓ CORRECT)' : ''}', 
                      style: pw.TextStyle(fontSize: 12, color: isCorrect ? PdfColors.green700 : PdfColors.black, fontWeight: isCorrect ? pw.FontWeight.bold : pw.FontWeight.normal)
                    ),
                  );
                }),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey100,
                  child: pw.Text('Explanation: ${q['explanation']}', style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    final fileName = '${topic.replaceAll(' ', '_')}_Answers.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
