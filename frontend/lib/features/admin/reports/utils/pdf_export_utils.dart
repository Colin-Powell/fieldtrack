import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportUtils {
  static Future<void> generateAndDownloadReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    final stats = reportData['stats'] ?? {};
    final totalActivities = stats['totalActivities'] ?? 0;
    
    final countyDist = reportData['countyDistribution'] as Map<String, dynamic>? ?? {};
    final logSummary = (reportData['logSummary'] as List<dynamic>?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('System Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total Activities: $totalActivities', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Text('County Distribution', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['County', 'Activities'],
              data: countyDist.entries.map((e) => [e.key, e.value.toString()]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Recent Activities (Sample)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Day', 'Student', 'Title', 'Location', 'County', 'Dept', 'Supervisor', 'Status'],
              data: logSummary.take(20).map((log) {
                final dateStr = log['timestamp'] != null 
                    ? DateTime.tryParse(log['timestamp'].toString())?.toLocal().toString().split(' ')[0] ?? '' 
                    : '';
                return [
                  dateStr,
                  log['student']?.toString() ?? '',
                  log['title']?.toString() ?? '',
                  log['location']?.toString() ?? 'Unknown',
                  log['county']?.toString() ?? 'Unknown',
                  log['department']?.toString() ?? '',
                  log['supervisor']?.toString() ?? '',
                  log['status']?.toString() ?? '',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'system_report.pdf',
    );
  }
}
