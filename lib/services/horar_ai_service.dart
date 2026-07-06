import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/horary_models.dart';

/// Lokal AI-endpoint.
///
/// Brug fx ved kørsel på fysisk Android-telefon:
/// flutter run --dart-define=HORAR_AI_ENDPOINT=https://api.toft-terman.dk/horar-answer
///
/// Brug 10.0.2.2 ved Android-emulator, hvis serveren kører på samme computer.
const String kHorarAiEndpoint = String.fromEnvironment(
  'HORAR_AI_ENDPOINT',
  defaultValue: 'https://api.toft-terman.dk/horar-answer',
);

/// Valgfri separat endpoint til AI-husforslag.
/// Hvis den ikke sættes, afleder appen den automatisk fra HORAR_AI_ENDPOINT
/// ved at skifte /horar-answer ud med /horar-house-suggestion.
const String kHorarAiHouseEndpoint = String.fromEnvironment(
  'HORAR_AI_HOUSE_ENDPOINT',
  defaultValue: '',
);

class HorarAiResult {
  final bool ok;
  final String answer;
  final String? error;

  const HorarAiResult._({
    required this.ok,
    required this.answer,
    this.error,
  });

  const HorarAiResult.success(String answer)
      : this._(ok: true, answer: answer);

  const HorarAiResult.failure(String error)
      : this._(ok: false, answer: '', error: error);
}


class HorarAiHouseSuggestionResult {
  final bool ok;
  final int? house;
  final HoraryQuestionType? questionType;
  final String reason;
  final String? confidence;
  final String? derivedHouseExplanation;
  final String? error;

  const HorarAiHouseSuggestionResult._({
    required this.ok,
    this.house,
    this.questionType,
    this.reason = '',
    this.confidence,
    this.derivedHouseExplanation,
    this.error,
  });

  const HorarAiHouseSuggestionResult.success({
    required int house,
    required HoraryQuestionType questionType,
    required String reason,
    String? confidence,
    String? derivedHouseExplanation,
  }) : this._(
          ok: true,
          house: house,
          questionType: questionType,
          reason: reason,
          confidence: confidence,
          derivedHouseExplanation: derivedHouseExplanation,
        );

  const HorarAiHouseSuggestionResult.failure(String error)
      : this._(ok: false, error: error);
}

class HorarAiService {
  final String endpoint;
  final String houseEndpoint;
  final Duration timeout;

  const HorarAiService({
    this.endpoint = kHorarAiEndpoint,
    this.houseEndpoint = kHorarAiHouseEndpoint,
    this.timeout = const Duration(seconds: 35),
  });

  Future<HorarAiResult> interpret(HoraryChart chart) async {
    final trimmedEndpoint = endpoint.trim();
    if (trimmedEndpoint.isEmpty) {
      return const HorarAiResult.failure('AI-endpoint er ikke sat.');
    }

    final uri = Uri.tryParse(trimmedEndpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return HorarAiResult.failure('Ugyldig AI-endpoint: $trimmedEndpoint');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain;q=0.9');
      request.write(jsonEncode(_payload(chart)));

      final response = await request.close().timeout(timeout);
      final body = await utf8.decodeStream(response).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final shortBody = body.length > 600 ? '${body.substring(0, 600)}…' : body;
        return HorarAiResult.failure('AI-server svarede HTTP ${response.statusCode}: $shortBody');
      }

      final parsedAnswer = _extractAnswer(body);
      if (parsedAnswer.trim().isEmpty) {
        return HorarAiResult.failure('AI-serveren svarede, men uden tekst.');
      }

      return HorarAiResult.success(parsedAnswer.trim());
    } on TimeoutException {
      return const HorarAiResult.failure('Timeout: AI-serveren svarede ikke i tide.');
    } on SocketException catch (e) {
      return HorarAiResult.failure('Kan ikke kontakte AI-serveren: ${e.message}');
    } catch (e) {
      return HorarAiResult.failure('AI-fortolkning fejlede: $e');
    } finally {
      client.close(force: true);
    }
  }

  Future<HorarAiHouseSuggestionResult> suggestHouse({
    required String question,
    required List<dynamic> localSuggestions,
  }) async {
    final rawEndpoint = _resolvedHouseEndpoint().trim();
    if (rawEndpoint.isEmpty) {
      return const HorarAiHouseSuggestionResult.failure('AI-husendpoint er ikke sat.');
    }

    final uri = Uri.tryParse(rawEndpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return HorarAiHouseSuggestionResult.failure('Ugyldigt AI-husendpoint: $rawEndpoint');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain;q=0.9');
      request.write(jsonEncode({
        'app': 'Horar',
        'language': 'da',
        'task': 'Foreslå bedst egnede horar-astrologiske hus før beregning.',
        'question': question,
        'local_suggestions': localSuggestions,
        'allowed_houses': List.generate(12, (i) => i + 1),
        'allowed_question_types': HoraryQuestionType.values.map(_questionTypeName).toList(),
      }));

      final response = await request.close().timeout(timeout);
      final body = await utf8.decodeStream(response).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final shortBody = body.length > 600 ? '${body.substring(0, 600)}…' : body;
        return HorarAiHouseSuggestionResult.failure('AI-server svarede HTTP ${response.statusCode}: $shortBody');
      }

      return _extractHouseSuggestion(body);
    } on TimeoutException {
      return const HorarAiHouseSuggestionResult.failure('Timeout: AI-serveren svarede ikke i tide.');
    } on SocketException catch (e) {
      return HorarAiHouseSuggestionResult.failure('Kan ikke kontakte AI-serveren: ${e.message}');
    } catch (e) {
      return HorarAiHouseSuggestionResult.failure('AI-husforslag fejlede: $e');
    } finally {
      client.close(force: true);
    }
  }

  String _resolvedHouseEndpoint() {
    final explicit = houseEndpoint.trim();
    if (explicit.isNotEmpty) return explicit;

    final base = endpoint.trim();
    if (base.isEmpty) return '';
    final uri = Uri.tryParse(base);
    if (uri == null) return base;

    var path = uri.path;
    if (path.endsWith('/horar-answer')) {
      path = path.substring(0, path.length - '/horar-answer'.length) + '/horar-house-suggestion';
    } else if (path.endsWith('/horar-answer/')) {
      path = path.substring(0, path.length - '/horar-answer/'.length) + '/horar-house-suggestion';
    } else if (path.isEmpty || path == '/') {
      path = '/horar-house-suggestion';
    } else {
      path = '${path.replaceFirst(RegExp(r'/+$'), '')}/horar-house-suggestion';
    }
    return uri.replace(path: path, query: '').toString();
  }

  HorarAiHouseSuggestionResult _extractHouseSuggestion(String body) {
    try {
      var text = body.trim();
      if (text.startsWith('```')) {
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return const HorarAiHouseSuggestionResult.failure('AI-serverens husforslag var ikke JSON.');
      }

      final rawHouse = decoded['house'] ?? decoded['hus'];
      final house = rawHouse is int ? rawHouse : int.tryParse(rawHouse?.toString() ?? '');
      if (house == null || house < 1 || house > 12) {
        return const HorarAiHouseSuggestionResult.failure('AI-serveren returnerede ikke et gyldigt hus.');
      }

      final typeText = (decoded['question_type'] ?? decoded['type'] ?? '').toString();
      final questionType = _parseQuestionType(typeText) ?? _fallbackQuestionTypeForHouse(house);
      final reason = (decoded['reason'] ?? decoded['forklaring'] ?? '').toString().trim();
      final confidence = (decoded['confidence'] ?? decoded['sikkerhed'])?.toString();
      final derived = (decoded['derived_house_explanation'] ?? decoded['afledt_hus'])?.toString();

      return HorarAiHouseSuggestionResult.success(
        house: house,
        questionType: questionType,
        reason: reason.isEmpty ? 'AI foreslår dette hus ud fra spørgsmålets formulering.' : reason,
        confidence: confidence,
        derivedHouseExplanation: derived,
      );
    } catch (e) {
      return HorarAiHouseSuggestionResult.failure('Kunne ikke læse AI-husforslag: $e');
    }
  }

  HoraryQuestionType? _parseQuestionType(String raw) {
    final wanted = raw.trim();
    if (wanted.isEmpty) return null;
    for (final value in HoraryQuestionType.values) {
      if (_questionTypeName(value) == wanted) return value;
      if (value.shortLabel.toLowerCase() == wanted.toLowerCase()) return value;
      if (value.label.toLowerCase() == wanted.toLowerCase()) return value;
    }
    return null;
  }

  HoraryQuestionType _fallbackQuestionTypeForHouse(int house) {
    switch (house) {
      case 1:
        return HoraryQuestionType.selfIdentity;
      case 2:
        return HoraryQuestionType.possessions;
      case 3:
        return HoraryQuestionType.messageContact;
      case 4:
        return HoraryQuestionType.homeProperty;
      case 5:
        return HoraryQuestionType.funHobby;
      case 6:
        return HoraryQuestionType.illnessHealth;
      case 7:
        return HoraryQuestionType.marriagePartner;
      case 8:
        return HoraryQuestionType.partnerMoney;
      case 9:
        return HoraryQuestionType.abroadTravel;
      case 10:
        return HoraryQuestionType.job;
      case 11:
        return HoraryQuestionType.friendsGroups;
      case 12:
        return HoraryQuestionType.secretsUnknown;
      default:
        return HoraryQuestionType.general;
    }
  }

  String _questionTypeName(HoraryQuestionType type) {
    return type.toString().split('.').last;
  }

  Map<String, dynamic> _payload(HoraryChart chart) {
    final topFactors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

    final probability = _probabilityFromScore(chart);
    final querent = chart.planetByName(chart.querentRuler);
    final quesited = chart.planetByName(chart.quesitedRuler);
    final moon = chart.planetByName('Måne');

    return {
      'app': 'Horar',
      'language': 'da',
      'task': 'Formuler et kort, brugbart horar-astrologisk svar til brugeren ud fra beregningen.',
      'style_instructions': [
        'Svar på dansk.',
        'Svar i samme form som spørgsmålet: ja/nej, hvor, hvornår, hvem, hvor meget, hvordan, hvorfor eller hvad.',
        'Brug ikke ja/nej-formulering ved hvor/hvornår/hvem/hvor meget-spørgsmål.',
        'Gør svaret forståeligt for en bruger, men bevar forbehold og usikkerhed.',
        'Skriv ikke at astrologi er videnskabeligt sikkert.',
        'Nævn kun de vigtigste astrologiske grunde, ikke hele tekniktabellen.',
        'Ved helbred, jura eller økonomi: skriv at svaret ikke erstatter professionel rådgivning.',
      ],
      'question': chart.question,
      'answer_mode': chart.answerMode.label,
      'answer_heading': chart.answerMode.resultHeading,
      'question_type': chart.questionType.label,
      'quesited_house': chart.quesitedHouse,
      'derived_house_explanation': chart.derivedHouseExplanation,
      'time_local': chart.localTime.toIso8601String(),
      'location': {
        'name': chart.location.name,
        'latitude': chart.location.latitude,
        'longitude': chart.location.longitude,
      },
      'calculated_result': {
        'judgement': chart.judgement,
        'explanation': chart.judgementExplanation,
        'score': chart.finalScore,
        'score_min': chart.scoreMin,
        'score_max': chart.scoreMax,
        'probability_percent': probability,
        'probability_note': chart.answerMode == HoraryAnswerMode.yesNo
            ? 'Beregnet sandsynlighedsindikation ud fra horar-score, ikke objektiv statistik.'
            : 'Beregnet styrke/usikkerhed ud fra horar-score, ikke ja/nej-sandsynlighed.',
      },
      'significators': {
        'querent_ruler': chart.querentRuler,
        'querent_position': _planetSummary(querent),
        'quesited_ruler': chart.quesitedRuler,
        'quesited_position': _planetSummary(quesited),
        'moon_position': _planetSummary(moon),
        'moon_void_of_course': chart.moonVoidOfCourse,
        'moon_via_combusta': chart.moonViaCombusta,
      },
      'main_aspects': {
        'significator_aspect': chart.significatorAspect?.text,
        'moon_previous_aspect': chart.moonPreviousAspect?.text,
        'moon_next_aspect': chart.moonNextAspect?.text,
        'prohibition': chart.prohibition?.text,
        'frustration': chart.frustration?.text,
        'translation_of_light': chart.translationOfLight?.text,
        'collection_of_light': chart.collectionOfLight?.text,
      },
      'top_weighted_factors': topFactors.take(6).map((f) => {
            'category': f.category,
            'title': f.title,
            'weight': f.weight,
            'explanation': f.explanation,
          }).toList(),
      'special_reading': chart.specialReading == null
          ? null
          : {
              'title': chart.specialReading!.title,
              'summary': chart.specialReading!.summary,
              'score_adjustment': chart.specialReading!.scoreAdjustment,
              'hints': chart.specialReading!.hints,
            },
      'notes': chart.notes.take(12).toList(),
    };
  }

  int _probabilityFromScore(HoraryChart chart) {
    // Denne procent er ikke statistik. Den omsætter appens horar-astrologiske score til
    // en let forståelig styrkeindikator, som serveren kan bruge i formuleringen.
    final score = chart.finalScore;
    if (score == 0) return 50;

    double p;
    if (score > 0) {
      final max = chart.scoreMax <= 0 ? score.abs() : chart.scoreMax;
      p = 50 + 45 * (score / max);
    } else {
      final minAbs = chart.scoreMin >= 0 ? score.abs() : chart.scoreMin.abs();
      p = 50 - 45 * (score.abs() / minAbs);
    }

    return p.clamp(5, 95).round();
  }

  String? _planetSummary(PlanetPosition? planet) {
    if (planet == null) return null;
    return '${planet.name}: ${planet.positionText}, ${planet.house}. hus, ${planet.retrograde ? 'retrograd' : 'direkte'}, hersker: ${planet.dignity.ruler}, eksaltation: ${planet.dignity.exaltation}';
  }

  String _extractAnswer(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['answer', 'svar', 'text', 'tekst', 'content', 'message']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value;
        }
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final answer = data['answer'] ?? data['text'] ?? data['content'];
          if (answer is String && answer.trim().isNotEmpty) return answer;
        }
      }
    } catch (_) {
      // Plain text response er også OK.
    }
    return body;
  }
}
