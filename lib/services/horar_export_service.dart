import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/horary_models.dart';

class HorarExportService {
  const HorarExportService();

  Future<File> writeChartImage({
    required Uint8List pngBytes,
    required HoraryChart chart,
  }) async {
    final file = await _newExportFile(chart: chart, extension: 'png');
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  Future<File> writeChartPdf({
    required Uint8List chartPngBytes,
    required HoraryChart chart,
  }) async {
    final document = pw.Document(
      creator: 'Horar',
      producer: 'Horar',
      title: _pdfTitle(chart),
      subject: chart.question,
      keywords: 'horar, astrology, study journal',
    );

    final chartImage = pw.MemoryImage(chartPngBytes);
    final topFactors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Horar - side ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Horar-kort',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(_formatDateTime(chart.localTime)),
          pw.Text('Lokation: ${chart.location.name} (${chart.location.latitude.toStringAsFixed(4)}, ${chart.location.longitude.toStringAsFixed(4)})'),
          if (chart.question.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Spørgsmål'),
            pw.Text(chart.question),
          ],
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Container(
              width: 430,
              height: 430,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Image(chartImage, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Teknisk grundlag'),
          _line('Svarform', chart.answerMode.label),
          _line('Spørgsmålstype', chart.questionType.label),
          _line('Adspurgt hus', '${chart.quesitedHouse}. hus'),
          _line('Spørger', chart.querentRuler),
          _line('Det adspurgte', chart.quesitedRuler),
          if (chart.derivedHouseExplanation != null && chart.derivedHouseExplanation!.trim().isNotEmpty)
            _paragraph(chart.derivedHouseExplanation!),
          pw.SizedBox(height: 12),
          _sectionTitle('Kilder og metode'),
          _line('Primær reference', 'John Frawley: The Horary Textbook'),
          _line('Tradition', 'Klassisk horar-astrologi'),
          _line('Hussystem', 'Regiomontanus'),
          _paragraph('Kortet beregnes lokalt ud fra spørgsmålstidspunkt og placering. Konklusionen er en AI-formulering af appens lokale horar-astrologiske beregning; den erstatter ikke metodeafsnittet, tabellerne eller astrologens egen vurdering.'),
          pw.SizedBox(height: 12),
          _sectionTitle('Klassisk vurdering'),
          pw.Text(chart.judgement, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(chart.judgementExplanation),
          pw.SizedBox(height: 4),
          pw.Text('Score: ${_signed(chart.finalScore)} i intervallet ${_signed(chart.scoreMin)} til ${_signed(chart.scoreMax)}'),
          if (topFactors.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Vigtigste faktorer'),
            ...topFactors.take(8).map(
                  (factor) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text('- ${factor.signText} ${factor.title}: ${factor.explanation}'),
                  ),
                ),
          ],
          if (chart.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Noter'),
            ...chart.notes.take(12).map(
                  (note) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('- $note'),
                  ),
                ),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'Eksporteret fra Horar. Bruges som studie- og analysegrundlag, ikke som definitiv afgørelse.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final file = await _newExportFile(chart: chart, extension: 'pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<void> shareFile(File file, {required String title}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: title,
        text: title,
      ),
    );
  }

  Future<File> _newExportFile({
    required HoraryChart chart,
    required String extension,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/horar_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final base = _safeBaseName(chart);
    return File('${exportDir.path}/$base.$extension');
  }

  String _pdfTitle(HoraryChart chart) {
    final q = chart.question.trim();
    if (q.isEmpty) return 'Horar-kort';
    return 'Horar-kort - $q';
  }

  String _safeBaseName(HoraryChart chart) {
    final d = chart.localTime;
    final datePart = '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
    final questionPart = _slug(chart.question);
    if (questionPart.isEmpty) return 'horar_$datePart';
    return 'horar_${datePart}_$questionPart';
  }

  String _slug(String input) {
    var s = input.toLowerCase().trim();
    s = s
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'oe')
        .replaceAll('å', 'aa')
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'u')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (s.length > 42) s = s.substring(0, 42).replaceAll(RegExp(r'_$'), '');
    return s;
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _line(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: value),
            ],
          ),
        ),
      );

  static pw.Widget _paragraph(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
        child: pw.Text(text, style: const pw.TextStyle(color: PdfColors.grey700)),
      );

  static String _formatDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _signed(int value) => value > 0 ? '+$value' : value.toString();
}
