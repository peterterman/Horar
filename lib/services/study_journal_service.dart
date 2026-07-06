import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/horary_models.dart';

class StudyJournalFactor {
  final int weight;
  final String title;
  final String explanation;

  const StudyJournalFactor({
    required this.weight,
    required this.title,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'title': title,
        'explanation': explanation,
      };

  factory StudyJournalFactor.fromJson(Map<String, dynamic> json) {
    return StudyJournalFactor(
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
    );
  }

  String get signText => weight > 0 ? '+$weight' : weight.toString();
}

class StudyJournalEntry {
  final String id;
  final DateTime savedAt;
  final DateTime questionTime;
  final String question;
  final String locationName;
  final String questionTypeLabel;
  final String answerModeLabel;
  final int quesitedHouse;
  final String querentRuler;
  final String quesitedRuler;
  final String judgement;
  final String judgementExplanation;
  final int finalScore;
  final int scoreMin;
  final int scoreMax;
  final String? derivedHouseExplanation;
  final String aiAnswer;
  final List<StudyJournalFactor> topFactors;
  final List<String> notes;

  const StudyJournalEntry({
    required this.id,
    required this.savedAt,
    required this.questionTime,
    required this.question,
    required this.locationName,
    required this.questionTypeLabel,
    required this.answerModeLabel,
    required this.quesitedHouse,
    required this.querentRuler,
    required this.quesitedRuler,
    required this.judgement,
    required this.judgementExplanation,
    required this.finalScore,
    required this.scoreMin,
    required this.scoreMax,
    required this.derivedHouseExplanation,
    required this.aiAnswer,
    required this.topFactors,
    required this.notes,
  });

  factory StudyJournalEntry.fromChart({
    required HoraryChart chart,
    required String aiAnswer,
  }) {
    final sortedFactors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

    return StudyJournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      questionTime: chart.localTime,
      question: chart.question,
      locationName: chart.location.name,
      questionTypeLabel: chart.questionType.label,
      answerModeLabel: chart.answerMode.label,
      quesitedHouse: chart.quesitedHouse,
      querentRuler: chart.querentRuler,
      quesitedRuler: chart.quesitedRuler,
      judgement: chart.judgement,
      judgementExplanation: chart.judgementExplanation,
      finalScore: chart.finalScore,
      scoreMin: chart.scoreMin,
      scoreMax: chart.scoreMax,
      derivedHouseExplanation: chart.derivedHouseExplanation,
      aiAnswer: aiAnswer,
      topFactors: sortedFactors
          .take(8)
          .map((factor) => StudyJournalFactor(
                weight: factor.weight,
                title: factor.title,
                explanation: factor.explanation,
              ))
          .toList(),
      notes: chart.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'questionTime': questionTime.toIso8601String(),
        'question': question,
        'locationName': locationName,
        'questionTypeLabel': questionTypeLabel,
        'answerModeLabel': answerModeLabel,
        'quesitedHouse': quesitedHouse,
        'querentRuler': querentRuler,
        'quesitedRuler': quesitedRuler,
        'judgement': judgement,
        'judgementExplanation': judgementExplanation,
        'finalScore': finalScore,
        'scoreMin': scoreMin,
        'scoreMax': scoreMax,
        'derivedHouseExplanation': derivedHouseExplanation,
        'aiAnswer': aiAnswer,
        'topFactors': topFactors.map((f) => f.toJson()).toList(),
        'notes': notes,
      };

  factory StudyJournalEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      return DateTime.tryParse((json[key] ?? '').toString()) ?? DateTime.now();
    }

    final rawFactors = json['topFactors'];
    final factors = rawFactors is List
        ? rawFactors
            .whereType<Map>()
            .map((m) => StudyJournalFactor.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <StudyJournalFactor>[];

    final rawNotes = json['notes'];
    final notes = rawNotes is List ? rawNotes.map((n) => n.toString()).toList() : <String>[];

    return StudyJournalEntry(
      id: (json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      savedAt: parseDate('savedAt'),
      questionTime: parseDate('questionTime'),
      question: (json['question'] ?? '').toString(),
      locationName: (json['locationName'] ?? '').toString(),
      questionTypeLabel: (json['questionTypeLabel'] ?? '').toString(),
      answerModeLabel: (json['answerModeLabel'] ?? '').toString(),
      quesitedHouse: (json['quesitedHouse'] as num?)?.toInt() ?? 0,
      querentRuler: (json['querentRuler'] ?? '').toString(),
      quesitedRuler: (json['quesitedRuler'] ?? '').toString(),
      judgement: (json['judgement'] ?? '').toString(),
      judgementExplanation: (json['judgementExplanation'] ?? '').toString(),
      finalScore: (json['finalScore'] as num?)?.toInt() ?? 0,
      scoreMin: (json['scoreMin'] as num?)?.toInt() ?? 0,
      scoreMax: (json['scoreMax'] as num?)?.toInt() ?? 0,
      derivedHouseExplanation: json['derivedHouseExplanation']?.toString(),
      aiAnswer: (json['aiAnswer'] ?? '').toString(),
      topFactors: factors,
      notes: notes,
    );
  }
}

class StudyJournalService {
  const StudyJournalService();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/horar_study_journal.json');
  }

  Future<List<StudyJournalEntry>> load() async {
    final file = await _file();
    if (!await file.exists()) return <StudyJournalEntry>[];

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <StudyJournalEntry>[];
      final entries = decoded
          .whereType<Map>()
          .map((m) => StudyJournalEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return entries;
    } catch (_) {
      return <StudyJournalEntry>[];
    }
  }

  Future<void> save(StudyJournalEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    await _write(entries);
  }

  Future<void> delete(String id) async {
    final entries = await load();
    entries.removeWhere((entry) => entry.id == id);
    await _write(entries);
  }

  Future<void> clear() async {
    await _write(<StudyJournalEntry>[]);
  }

  Future<void> _write(List<StudyJournalEntry> entries) async {
    final file = await _file();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entries.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }
}
