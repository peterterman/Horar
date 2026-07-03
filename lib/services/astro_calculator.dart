import 'dart:math';

import 'package:sweph/sweph.dart' hide HousePosition;

import '../models/horary_models.dart';
import 'horary_rules.dart';

class _FixedStarData {
  final String name;
  final double longitude;
  final String nature;
  final String meaning;

  const _FixedStarData(this.name, this.longitude, this.nature, this.meaning);
}

class AstroCalculator {
  const AstroCalculator();

  static const List<String> signs = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  static const Map<String, String> planetSymbols = {
    'Sol': '☉',
    'Måne': '☽',
    'Merkur': '☿',
    'Venus': '♀',
    'Mars': '♂',
    'Jupiter': '♃',
    'Saturn': '♄',
  };

  // Udvalgte fixstjerner med omtrentlige tropiske længder for moderne epoke.
  // De bruges som praktiske horariske markører med lille orb, ikke som
  // astronomisk præcisionskatalog.
  static const List<_FixedStarData> fixedStars = [
    _FixedStarData('Algol', 56.2, 'Saturn/Jupiter', 'krise, tab af hovedet, stærk uro eller noget dramatisk'),
    _FixedStarData('Plejaderne', 60.0, 'Måne/Mars', 'tårer, tåge, svag sigtbarhed eller mange små ting samlet'),
    _FixedStarData('Aldebaran', 69.9, 'Mars', 'styrke, mod, frontlinje, men krav om integritet'),
    _FixedStarData('Betelgeuse', 89.0, 'Mars/Merkur', 'markant styrke, synlighed og handlekraft'),
    _FixedStarData('Sirius', 104.3, 'Jupiter/Mars', 'stor kraft, varme, ry, succes eller overophedning'),
    _FixedStarData('Regulus', 150.1, 'Mars/Jupiter', 'status, sejr, rang og faldgrube ved hævn/stolthed'),
    _FixedStarData('Spica', 204.2, 'Venus/Merkur', 'beskyttelse, talent, hjælp og heldig udgang'),
    _FixedStarData('Arcturus', 204.5, 'Mars/Jupiter', 'beskyttelse, ledelse, vejviser og stærk bevægelse'),
    _FixedStarData('Antares', 249.9, 'Mars/Jupiter', 'kamp, intensitet, afslutning eller alt-eller-intet-tema'),
    _FixedStarData('Fomalhaut', 334.2, 'Venus/Merkur', 'vision, ideal, løfte og behov for ren hensigt'),
  ];

  // Traditionelle herskere, som er udgangspunktet i klassisk/Frawley-horar.
  static const Map<String, String> rulers = {
    'Aries': 'Mars',
    'Taurus': 'Venus',
    'Gemini': 'Merkur',
    'Cancer': 'Måne',
    'Leo': 'Sol',
    'Virgo': 'Merkur',
    'Libra': 'Venus',
    'Scorpio': 'Mars',
    'Sagittarius': 'Jupiter',
    'Capricorn': 'Saturn',
    'Aquarius': 'Saturn',
    'Pisces': 'Jupiter',
  };

  static const Map<String, String> exaltations = {
    'Aries': 'Sol',
    'Taurus': 'Måne',
    'Cancer': 'Jupiter',
    'Virgo': 'Merkur',
    'Libra': 'Saturn',
    'Capricorn': 'Mars',
    'Pisces': 'Venus',
  };

  static const Map<String, String> detriments = {
    'Aries': 'Venus',
    'Taurus': 'Mars',
    'Gemini': 'Jupiter',
    'Cancer': 'Saturn',
    'Leo': 'Saturn',
    'Virgo': 'Jupiter',
    'Libra': 'Mars',
    'Scorpio': 'Venus',
    'Sagittarius': 'Merkur',
    'Capricorn': 'Måne',
    'Aquarius': 'Sol',
    'Pisces': 'Merkur',
  };

  static const Map<String, String> falls = {
    'Aries': 'Saturn',
    'Taurus': '',
    'Gemini': '',
    'Cancer': 'Mars',
    'Leo': '',
    'Virgo': 'Venus',
    'Libra': 'Sol',
    'Scorpio': 'Måne',
    'Sagittarius': '',
    'Capricorn': 'Jupiter',
    'Aquarius': '',
    'Pisces': 'Merkur',
  };

  Future<HoraryChart> calculate({
    required String question,
    required DateTime localTime,
    required LocationChoice location,
    required HoraryQuestionType questionType,
    required int quesitedHouse,
  }) async {
    final utc = localTime.toUtc();
    final utHour = utc.hour + utc.minute / 60.0 + utc.second / 3600.0;
    final jd = Sweph.swe_julday(
      utc.year,
      utc.month,
      utc.day,
      utHour,
      CalendarType.SE_GREG_CAL,
    );

    final housesResult = Sweph.swe_houses(
      jd,
      location.latitude,
      location.longitude,
      Hsys.R, // Regiomontanus
    );

    final houses = <HousePosition>[];
    for (var i = 1; i <= 12; i++) {
      final lon = _norm(housesResult.cusps[i]);
      final split = splitLongitude(lon);
      houses.add(HousePosition(
        number: i,
        longitude: lon,
        sign: split.sign,
        degree: split.degree,
        minute: split.minute,
      ));
    }

    final bodyMap = <String, HeavenlyBody>{
      'Sol': HeavenlyBody.SE_SUN,
      'Måne': HeavenlyBody.SE_MOON,
      'Merkur': HeavenlyBody.SE_MERCURY,
      'Venus': HeavenlyBody.SE_VENUS,
      'Mars': HeavenlyBody.SE_MARS,
      'Jupiter': HeavenlyBody.SE_JUPITER,
      'Saturn': HeavenlyBody.SE_SATURN,
    };

    final planets = <PlanetPosition>[];
    for (final entry in bodyMap.entries) {
      final pos = Sweph.swe_calc_ut(
        jd,
        entry.value,
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED,
      );
      final lon = _norm(pos.longitude);
      final split = splitLongitude(lon);
      planets.add(PlanetPosition(
        name: entry.key,
        symbol: planetSymbols[entry.key] ?? entry.key,
        sweId: entry.value.value,
        longitude: lon,
        speed: pos.speedInLongitude,
        sign: split.sign,
        degree: split.degree,
        minute: split.minute,
        house: _houseFor(lon, houses.map((h) => h.longitude).toList()),
        retrograde: pos.speedInLongitude < 0,
        dignity: dignityForSign(split.sign),
      ));
    }

    final ascSign = houses.first.sign;
    final quesitedSign = houses[quesitedHouse - 1].sign;
    final querentRuler = rulers[ascSign] ?? '-';
    final quesitedRuler = rulers[quesitedSign] ?? '-';
    final answerMode = detectHoraryAnswerMode(question);

    final futureAspects = _futureAspectEvents(planets);
    final moonPrevious = _nearestAspectByMotion(
      planets,
      fromName: 'Måne',
      forward: false,
    );
    final moonNext = _firstFutureAspectFor(futureAspects, 'Måne');
    final sigAspect = _aspectBetweenSignificators(
      planets,
      futureAspects,
      querentRuler,
      quesitedRuler,
    );

    final conditions = _planetConditions(planets);
    final moon = planets.where((p) => p.name == 'Måne').firstOrNull;
    final moonVoid = moon == null ? false : _moonVoidOfCourse(moon, futureAspects);
    final moonViaCombusta = moon == null ? false : _isViaCombusta(moon.longitude);

    final translation = _translationOfLight(
      planets,
      futureAspects,
      moonPrevious,
      moonNext,
      querentRuler,
      quesitedRuler,
    );
    final collection = _collectionOfLight(
      planets,
      futureAspects,
      querentRuler,
      quesitedRuler,
    );
    final prohibition = _firstProhibition(
      futureAspects,
      querentRuler,
      quesitedRuler,
      sigAspect,
      translation,
    );
    final frustration = _firstFrustration(
      futureAspects,
      querentRuler,
      quesitedRuler,
      sigAspect,
      prohibition,
      translation,
    );

    final antiscionContacts = _antiscionContacts(
      planets,
      houses,
      querentRuler,
      quesitedRuler,
    );
    final fixedStarContacts = _fixedStarContacts(
      planets,
      houses,
      querentRuler,
      quesitedRuler,
    );

    final preliminary = HoraryChart(
      question: question,
      localTime: localTime,
      location: location,
      questionType: questionType,
      answerMode: answerMode,
      quesitedHouse: quesitedHouse,
      planets: planets,
      houses: houses,
      querentRuler: querentRuler,
      quesitedRuler: quesitedRuler,
      moonPreviousAspect: moonPrevious,
      moonNextAspect: moonNext,
      significatorAspect: sigAspect,
      futureAspects: futureAspects,
      conditions: conditions,
      moonVoidOfCourse: moonVoid,
      moonViaCombusta: moonViaCombusta,
      prohibition: prohibition,
      frustration: frustration,
      translationOfLight: translation,
      collectionOfLight: collection,
      antiscionContacts: antiscionContacts,
      fixedStarContacts: fixedStarContacts,
      specialReading: null,
      judgement: '',
      judgementExplanation: '',
      finalScore: 0,
      scoreMin: 0,
      scoreMax: 0,
      weightedFactors: const [],
      notes: const [],
    );

    final rules = HoraryRules().judge(preliminary);
    return HoraryChart(
      question: preliminary.question,
      localTime: preliminary.localTime,
      location: preliminary.location,
      questionType: preliminary.questionType,
      answerMode: preliminary.answerMode,
      quesitedHouse: preliminary.quesitedHouse,
      planets: preliminary.planets,
      houses: preliminary.houses,
      querentRuler: preliminary.querentRuler,
      quesitedRuler: preliminary.quesitedRuler,
      moonPreviousAspect: preliminary.moonPreviousAspect,
      moonNextAspect: preliminary.moonNextAspect,
      significatorAspect: preliminary.significatorAspect,
      futureAspects: preliminary.futureAspects,
      conditions: preliminary.conditions,
      moonVoidOfCourse: preliminary.moonVoidOfCourse,
      moonViaCombusta: preliminary.moonViaCombusta,
      prohibition: preliminary.prohibition,
      frustration: preliminary.frustration,
      translationOfLight: preliminary.translationOfLight,
      collectionOfLight: preliminary.collectionOfLight,
      antiscionContacts: preliminary.antiscionContacts,
      fixedStarContacts: preliminary.fixedStarContacts,
      specialReading: rules.specialReading,
      judgement: rules.judgement,
      judgementExplanation: rules.explanation,
      finalScore: rules.finalScore,
      scoreMin: rules.scoreMin,
      scoreMax: rules.scoreMax,
      weightedFactors: rules.weightedFactors,
      notes: rules.notes,
    );
  }

  EssentialDignity dignityForSign(String sign) {
    return EssentialDignity(
      ruler: rulers[sign] ?? '-',
      exaltation: exaltations[sign] ?? '-',
      detriment: detriments[sign] ?? '-',
      fall: (falls[sign] == null || falls[sign]!.isEmpty) ? '-' : falls[sign]!,
    );
  }

  static ({String sign, int degree, int minute}) splitLongitude(double longitude) {
    final norm = _norm(longitude);
    final signIndex = (norm / 30).floor().clamp(0, 11);
    final signDegree = norm - signIndex * 30;
    final degree = signDegree.floor();
    final minute = ((signDegree - degree) * 60).floor();
    return (sign: signs[signIndex], degree: degree, minute: minute);
  }

  static double _norm(double value) {
    var v = value % 360.0;
    if (v < 0) v += 360.0;
    return v;
  }

  int _houseFor(double planetLongitude, List<double> cusps) {
    for (var i = 0; i < 12; i++) {
      var start = _norm(cusps[i]);
      var end = _norm(cusps[(i + 1) % 12]);
      var p = _norm(planetLongitude);
      if (end < start) end += 360;
      if (p < start) p += 360;
      if (p >= start && p < end) return i + 1;
    }
    return 0;
  }

  Map<String, PlanetCondition> _planetConditions(List<PlanetPosition> planets) {
    final sun = planets.where((p) => p.name == 'Sol').firstOrNull;
    final out = <String, PlanetCondition>{};

    for (final p in planets) {
      var essential = 0;
      final labels = <String>[];

      if (p.dignity.ruler == p.name) {
        essential += 5;
        labels.add('hersker');
      }
      if (p.dignity.exaltation == p.name) {
        essential += 4;
        labels.add('eksaltation');
      }
      if (p.dignity.detriment == p.name) {
        essential -= 5;
        labels.add('exil');
      }
      if (p.dignity.fall == p.name) {
        essential -= 4;
        labels.add('fald');
      }
      if (essential == 0) labels.add('peregrin/simpel');

      var accidental = 0;
      final angular = const {1, 4, 7, 10}.contains(p.house);
      final succedent = const {2, 5, 8, 11}.contains(p.house);
      final cadent = const {3, 6, 9, 12}.contains(p.house);

      if (angular) {
        accidental += 5;
        labels.add('vinkelhus');
      } else if (succedent) {
        accidental += 2;
        labels.add('succedent');
      } else if (cadent) {
        accidental -= 2;
        labels.add('kadent');
      }

      if (p.retrograde) {
        accidental -= 3;
        labels.add('retrograd');
      }

      var cazimi = false;
      var combust = false;
      var underBeams = false;
      if (sun != null && p.name != 'Sol') {
        final d = _angularDistance(p.longitude, sun.longitude);
        if (d <= 0.2833) {
          cazimi = true;
          accidental += 6;
          labels.add('cazimi');
        } else if (d <= 8.5) {
          combust = true;
          accidental -= 5;
          labels.add('forbrændt');
        } else if (d <= 17) {
          underBeams = true;
          accidental -= 2;
          labels.add('under solstråler');
        }
      }

      out[p.name] = PlanetCondition(
        essentialScore: essential,
        accidentalScore: accidental,
        cazimi: cazimi,
        combust: combust,
        underSunBeams: underBeams,
        angular: angular,
        succedent: succedent,
        cadent: cadent,
        labels: labels,
      );
    }
    return out;
  }

  HoraryAspect? _aspectBetweenSignificators(
    List<PlanetPosition> planets,
    List<HoraryAspect> futureAspects,
    String a,
    String b,
  ) {
    if (a == b) return null;
    final p1 = planets.where((p) => p.name == a).firstOrNull;
    final p2 = planets.where((p) => p.name == b).firstOrNull;
    if (p1 == null || p2 == null) return null;

    final future = futureAspects.where((x) => x.involvesBoth(a, b)).firstOrNull;
    if (future != null) return future;

    final current = _aspectAt(p1.longitude, p2.longitude, orbLimit: 8.0);
    if (current == null) return null;

    final nowOrb = current.orb;
    final later = _aspectOrb(
      p1.longitude + p1.speed * 0.25,
      p2.longitude + p2.speed * 0.25,
      current.angle,
    );

    return HoraryAspect(
      from: p1.name,
      to: p2.name,
      aspect: current.name,
      angle: current.angle,
      orb: nowOrb,
      applying: later < nowOrb,
      exactInDays: null,
      beforeSignChange: true,
    );
  }

  HoraryAspect? _nearestAspectByMotion(
    List<PlanetPosition> planets, {
    required String fromName,
    required bool forward,
  }) {
    final from = planets.where((p) => p.name == fromName).firstOrNull;
    if (from == null) return null;

    HoraryAspect? best;
    double bestDays = double.infinity;

    for (final to in planets) {
      if (to.name == from.name) continue;
      for (var step = 1; step <= 280; step++) {
        final days = step * 0.05 * (forward ? 1 : -1);
        final aspect = _aspectAt(
          from.longitude + from.speed * days,
          to.longitude + to.speed * days,
          orbLimit: 0.35,
        );
        if (aspect != null) {
          final absDays = days.abs();
          if (absDays < bestDays) {
            bestDays = absDays;
            best = HoraryAspect(
              from: from.name,
              to: to.name,
              aspect: aspect.name,
              angle: aspect.angle,
              orb: aspect.orb,
              applying: forward,
              exactInDays: forward ? absDays : null,
              beforeSignChange: true,
            );
          }
          break;
        }
      }
    }
    return best;
  }

  List<HoraryAspect> _futureAspectEvents(List<PlanetPosition> planets) {
    final events = <HoraryAspect>[];
    for (var i = 0; i < planets.length; i++) {
      for (var j = i + 1; j < planets.length; j++) {
        final a = planets[i];
        final b = planets[j];
        final ev = _nextFutureAspect(a, b);
        if (ev != null) events.add(ev);
      }
    }
    events.sort((a, b) => (a.exactInDays ?? 9999).compareTo(b.exactInDays ?? 9999));
    return events;
  }

  HoraryAspect? _nextFutureAspect(PlanetPosition a, PlanetPosition b) {
    const aspects = <String, double>{
      'konjunktion': 0,
      'sekstil': 60,
      'kvadrat': 90,
      'trigon': 120,
      'opposition': 180,
    };

    HoraryAspect? best;
    const stepDays = 0.05;
    const maxDays = 90.0;
    final minSignDays = min(_daysUntilSignChange(a), _daysUntilSignChange(b));

    for (final entry in aspects.entries) {
      var bestOrb = double.infinity;
      var bestDay = 0.0;
      var wasImproving = false;
      var previousOrb = _aspectOrb(a.longitude, b.longitude, entry.value);

      for (var step = 1; step <= (maxDays / stepDays).round(); step++) {
        final days = step * stepDays;
        final orb = _aspectOrb(
          a.longitude + a.speed * days,
          b.longitude + b.speed * days,
          entry.value,
        );

        if (orb < bestOrb) {
          bestOrb = orb;
          bestDay = days;
        }

        if (orb < previousOrb) {
          wasImproving = true;
        } else if (wasImproving && orb > previousOrb) {
          break;
        }
        previousOrb = orb;
      }

      if (bestOrb <= 0.20 && bestDay > 0) {
        final candidate = HoraryAspect(
          from: a.name,
          to: b.name,
          aspect: entry.key,
          angle: entry.value,
          orb: bestOrb,
          applying: true,
          exactInDays: bestDay,
          beforeSignChange: bestDay <= minSignDays,
        );
        if (best == null || bestDay < (best.exactInDays ?? double.infinity)) {
          best = candidate;
        }
      }
    }
    return best;
  }

  HoraryAspect? _firstFutureAspectFor(List<HoraryAspect> futureAspects, String planetName) {
    return futureAspects.where((a) => a.involves(planetName)).firstOrNull;
  }

  bool _moonVoidOfCourse(PlanetPosition moon, List<HoraryAspect> futureAspects) {
    final daysToMoonSignChange = _daysUntilSignChange(moon);
    final nextMoon = _firstFutureAspectFor(futureAspects, 'Måne');
    if (nextMoon == null) return true;
    return (nextMoon.exactInDays ?? double.infinity) > daysToMoonSignChange;
  }

  bool _isViaCombusta(double longitude) {
    final lon = _norm(longitude);
    return lon >= 195 && lon <= 225; // 15 Libra til 15 Scorpio.
  }

  HoraryAspect? _firstProhibition(
    List<HoraryAspect> futureAspects,
    String querentRuler,
    String quesitedRuler,
    HoraryAspect? significatorAspect,
    HoraryAspect? translationOfLight,
  ) {
    if (significatorAspect == null || significatorAspect.exactInDays == null) return null;
    final limit = significatorAspect.exactInDays!;

    for (final a in futureAspects) {
      final d = a.exactInDays ?? double.infinity;
      if (d >= limit) continue;
      if (a.involvesBoth(querentRuler, quesitedRuler)) continue;

      // Når samme aspekt er markeret som translation, skal det ikke samtidig
      // læses som prohibition.
      if (translationOfLight != null && a.involves(translationOfLight.from)) {
        continue;
      }

      if (a.involves(querentRuler) || a.involves(quesitedRuler)) {
        final touched = a.involves(querentRuler) ? querentRuler : quesitedRuler;
        final third = a.otherThan(touched);
        return HoraryAspect(
          from: a.from,
          to: a.to,
          aspect: a.aspect,
          angle: a.angle,
          orb: a.orb,
          applying: a.applying,
          exactInDays: a.exactInDays,
          beforeSignChange: a.beforeSignChange,
          ruleNote: '$touched møder $third før hovedsignifikatorerne når hinanden',
        );
      }
    }
    return null;
  }

  HoraryAspect? _firstFrustration(
    List<HoraryAspect> futureAspects,
    String querentRuler,
    String quesitedRuler,
    HoraryAspect? significatorAspect,
    HoraryAspect? prohibition,
    HoraryAspect? translationOfLight,
  ) {
    if (significatorAspect == null || significatorAspect.exactInDays == null) return null;
    final limit = significatorAspect.exactInDays!;

    for (final a in futureAspects) {
      final d = a.exactInDays ?? double.infinity;
      if (d >= limit) continue;
      if (a.involvesBoth(querentRuler, quesitedRuler)) continue;

      if (prohibition != null &&
          a.from == prohibition.from &&
          a.to == prohibition.to &&
          (a.exactInDays ?? -1) == (prohibition.exactInDays ?? -2)) {
        continue;
      }
      if (translationOfLight != null && a.involves(translationOfLight.from)) {
        continue;
      }

      // Simpel definition: et andet aspekt til især den adspurgtes
      // signifikator før hovedperfektion kan frustrere sagen. Det er ikke en
      // absolut dom, men markeres tydeligt i noterne.
      if (a.involves(quesitedRuler)) {
        final third = a.otherThan(quesitedRuler);
        return HoraryAspect(
          from: a.from,
          to: a.to,
          aspect: a.aspect,
          angle: a.angle,
          orb: a.orb,
          applying: a.applying,
          exactInDays: a.exactInDays,
          beforeSignChange: a.beforeSignChange,
          ruleNote: '$quesitedRuler optages af $third før hovedperfektion',
        );
      }
    }
    return null;
  }

  HoraryAspect? _translationOfLight(
    List<PlanetPosition> planets,
    List<HoraryAspect> futureAspects,
    HoraryAspect? moonPrevious,
    HoraryAspect? moonNext,
    String querentRuler,
    String quesitedRuler,
  ) {
    // Først den klassiske og hyppigste: Månen har netop forladt den ene
    // signifikator og går nu til den anden.
    final moonTranslation = _translationByPlanet(
      translator: 'Måne',
      previous: moonPrevious,
      futureAspects: futureAspects,
      querentRuler: querentRuler,
      quesitedRuler: quesitedRuler,
    );
    if (moonTranslation != null) return moonTranslation;

    // Derefter en forsigtig udvidelse: en hurtig planet kan overføre lys.
    // Vi holder os til de traditionelle planeter og kræver seneste aspekt bagud
    // samt næste aspekt fremad til den anden signifikator.
    const candidates = ['Merkur', 'Venus', 'Mars'];
    for (final candidate in candidates) {
      if (candidate == querentRuler || candidate == quesitedRuler) continue;
      final previous = _nearestAspectByMotion(
        planets,
        fromName: candidate,
        forward: false,
      );
      final translated = _translationByPlanet(
        translator: candidate,
        previous: previous,
        futureAspects: futureAspects,
        querentRuler: querentRuler,
        quesitedRuler: quesitedRuler,
      );
      if (translated != null) return translated;
    }
    return null;
  }

  HoraryAspect? _translationByPlanet({
    required String translator,
    required HoraryAspect? previous,
    required List<HoraryAspect> futureAspects,
    required String querentRuler,
    required String quesitedRuler,
  }) {
    if (previous == null || !previous.involves(translator)) return null;

    final previousTouchedQuerent = previous.involves(querentRuler);
    final previousTouchedQuesited = previous.involves(quesitedRuler);
    if (!previousTouchedQuerent && !previousTouchedQuesited) return null;

    final target = previousTouchedQuerent ? quesitedRuler : querentRuler;
    final next = futureAspects
        .where((a) => a.involvesBoth(translator, target))
        .where((a) => a.beforeSignChange)
        .firstOrNull;

    if (next == null) return null;
    if ((next.exactInDays ?? double.infinity) > 30) return null;

    final fromSide = previousTouchedQuerent ? querentRuler : quesitedRuler;
    final toSide = target;
    return HoraryAspect(
      from: translator,
      to: '$fromSide → $toSide',
      aspect: 'overfører lys',
      angle: next.angle,
      orb: next.orb,
      applying: true,
      exactInDays: next.exactInDays,
      beforeSignChange: next.beforeSignChange,
      ruleNote: 'seneste aspekt til $fromSide, næste aspekt til $toSide',
    );
  }

  HoraryAspect? _collectionOfLight(
    List<PlanetPosition> planets,
    List<HoraryAspect> futureAspects,
    String querentRuler,
    String quesitedRuler,
  ) {
    final querent = planets.where((p) => p.name == querentRuler).firstOrNull;
    final quesited = planets.where((p) => p.name == quesitedRuler).firstOrNull;
    if (querent == null || quesited == null) return null;

    const traditionalPlanets = ['Sol', 'Måne', 'Merkur', 'Venus', 'Mars', 'Jupiter', 'Saturn'];
    for (final collector in traditionalPlanets) {
      if (collector == querentRuler || collector == quesitedRuler) continue;
      final collectorPlanet = planets.where((p) => p.name == collector).firstOrNull;
      if (collectorPlanet == null) continue;

      // Collection virker bedst med en langsommere/stærkere planet, der kan
      // modtage begge. Dette er en app-regel, ikke en endelig dom.
      final isSlowerThanBoth = collectorPlanet.speed.abs() <= querent.speed.abs() &&
          collectorPlanet.speed.abs() <= quesited.speed.abs();

      final toQuerent = futureAspects
          .where((a) => a.involvesBoth(collector, querentRuler))
          .where((a) => a.beforeSignChange)
          .firstOrNull;
      final toQuesited = futureAspects
          .where((a) => a.involvesBoth(collector, quesitedRuler))
          .where((a) => a.beforeSignChange)
          .firstOrNull;
      if (toQuerent != null && toQuesited != null) {
        final latest = (toQuerent.exactInDays ?? 9999) > (toQuesited.exactInDays ?? 9999)
            ? toQuerent
            : toQuesited;
        if ((latest.exactInDays ?? 9999) <= 30) {
          return HoraryAspect(
            from: collector,
            to: '$querentRuler og $quesitedRuler',
            aspect: 'samler lys fra',
            angle: 0,
            orb: 0,
            applying: true,
            exactInDays: latest.exactInDays,
            beforeSignChange: latest.beforeSignChange,
            ruleNote: isSlowerThanBoth
                ? 'langsommere tredje planet modtager begge signifikatorer'
                : 'tredje planet får aspekt til begge signifikatorer; hastighed bør vurderes manuelt',
          );
        }
      }
    }
    return null;
  }

  List<AntiscionContact> _antiscionContacts(
    List<PlanetPosition> planets,
    List<HousePosition> houses,
    String querentRuler,
    String quesitedRuler,
  ) {
    final sourceNames = <String>{querentRuler, quesitedRuler, 'Måne'};
    final targetPlanets = planets
        .where((p) => <String>{querentRuler, quesitedRuler, 'Måne', 'Sol', 'Venus', 'Mars', 'Jupiter', 'Saturn'}.contains(p.name))
        .toList();
    final angleTargets = <({String name, double longitude})>[
      if (houses.isNotEmpty) (name: 'ASC', longitude: houses[0].longitude),
      if (houses.length >= 10) (name: 'MC', longitude: houses[9].longitude),
    ];

    final contacts = <AntiscionContact>[];
    for (final source in planets.where((p) => sourceNames.contains(p.name))) {
      final antiscion = _norm(180.0 - source.longitude);
      final contra = _norm(antiscion + 180.0);
      for (final shadow in [
        (type: 'Antiscion', lon: antiscion),
        (type: 'Contra-antiscion', lon: contra),
      ]) {
        for (final target in targetPlanets) {
          if (target.name == source.name) continue;
          final orb = _angularDistance(shadow.lon, target.longitude);
          if (orb <= 1.0) {
            contacts.add(AntiscionContact(
              pointType: shadow.type,
              sourcePlanet: source.name,
              target: target.name,
              shadowLongitude: shadow.lon,
              orb: orb,
            ));
          }
        }
        for (final target in angleTargets) {
          final orb = _angularDistance(shadow.lon, target.longitude);
          if (orb <= 1.0) {
            contacts.add(AntiscionContact(
              pointType: shadow.type,
              sourcePlanet: source.name,
              target: target.name,
              shadowLongitude: shadow.lon,
              orb: orb,
            ));
          }
        }
      }
    }

    contacts.sort((a, b) => a.orb.compareTo(b.orb));
    return contacts.take(10).toList();
  }

  List<FixedStarContact> _fixedStarContacts(
    List<PlanetPosition> planets,
    List<HousePosition> houses,
    String querentRuler,
    String quesitedRuler,
  ) {
    final targetPlanets = planets
        .where((p) => <String>{querentRuler, quesitedRuler, 'Måne', 'Sol', 'Venus', 'Mars', 'Jupiter', 'Saturn'}.contains(p.name))
        .map((p) => (name: p.name, longitude: p.longitude))
        .toList();
    final targets = <({String name, double longitude})>[
      ...targetPlanets,
      if (houses.isNotEmpty) (name: 'ASC', longitude: houses[0].longitude),
      if (houses.length >= 10) (name: 'MC', longitude: houses[9].longitude),
    ];

    final contacts = <FixedStarContact>[];
    for (final target in targets) {
      for (final star in fixedStars) {
        final orb = _angularDistance(target.longitude, star.longitude);
        if (orb <= 1.0) {
          contacts.add(FixedStarContact(
            starName: star.name,
            starLongitude: star.longitude,
            target: target.name,
            orb: orb,
            nature: star.nature,
            meaning: star.meaning,
          ));
        }
      }
    }
    contacts.sort((a, b) => a.orb.compareTo(b.orb));
    return contacts.take(10).toList();
  }

  double _daysUntilSignChange(PlanetPosition p) {
    if (p.speed.abs() < 0.00001) return double.infinity;
    final posInSign = _norm(p.longitude) % 30;
    final degrees = p.speed > 0 ? 30 - posInSign : posInSign;
    if (degrees <= 0.00001) return 0;
    return degrees / p.speed.abs();
  }

  ({String name, double angle, double orb})? _aspectAt(
    double lon1,
    double lon2, {
    required double orbLimit,
  }) {
    const aspects = <String, double>{
      'konjunktion': 0,
      'sekstil': 60,
      'kvadrat': 90,
      'trigon': 120,
      'opposition': 180,
    };

    for (final entry in aspects.entries) {
      final orb = _aspectOrb(lon1, lon2, entry.value);
      if (orb <= orbLimit) {
        return (name: entry.key, angle: entry.value, orb: orb);
      }
    }
    return null;
  }

  double _aspectOrb(double lon1, double lon2, double aspectAngle) {
    final diff = _angularDistance(lon1, lon2);
    return (diff - aspectAngle).abs();
  }

  double _angularDistance(double lon1, double lon2) {
    final diff = (_norm(lon1) - _norm(lon2)).abs();
    return min(diff, 360 - diff);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
