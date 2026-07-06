import '../models/horary_models.dart';

class DerivedHouseResult {
  final int finalHouse;
  final HoraryQuestionType questionType;
  final String explanation;
  final List<String> steps;

  const DerivedHouseResult({
    required this.finalHouse,
    required this.questionType,
    required this.explanation,
    required this.steps,
  });
}

class DerivedHouseResolver {
  const DerivedHouseResolver._();

  static DerivedHouseResult? resolve(String rawQuestion) {
    final q = _normalize(rawQuestion);
    if (q.isEmpty || q == 'test') return null;

    final relationMatches = _findRelationMatches(q);
    final topic = _findBestTopic(q, afterIndex: relationMatches.isEmpty ? 0 : relationMatches.last.end);

    // Ved "hans/hendes/deres ..." uden navngiven relation læser vi den anden part fra 7. hus.
    final hasOtherPersonPossessive = _containsAny(q, const [
      'hans ', 'hendes ', 'deres ', 'partnerens ', 'ægtefællens ', 'aegtefaellens ',
      'kærestens ', 'kaerestens ', 'mandens ', 'konens ',
    ]);

    if (relationMatches.isEmpty && !(hasOtherPersonPossessive && topic != null)) {
      return null;
    }

    var currentHouse = 1;
    var currentLabel = 'spørgeren';
    final steps = <String>[];

    if (relationMatches.isEmpty && hasOtherPersonPossessive) {
      currentHouse = _turnedHouse(1, 7);
      currentLabel = 'den anden part';
      steps.add('den anden part = 7. hus');
    }

    for (final match in relationMatches) {
      final nextHouse = _turnedHouse(currentHouse, match.step.houseFromCurrent);
      if (currentHouse == 1) {
        steps.add('${match.step.label} = ${match.step.houseFromCurrent}. hus');
      } else {
        steps.add('${match.step.label} fra $currentLabel = ${match.step.houseFromCurrent}. fra ${currentHouse}. = ${nextHouse}. hus');
      }
      currentHouse = nextHouse;
      currentLabel = match.step.label;
    }

    var questionType = relationMatches.isNotEmpty ? relationMatches.last.step.questionType : HoraryQuestionType.general;
    if (topic != null) {
      final nextHouse = _turnedHouse(currentHouse, topic.houseFromCurrent);
      steps.add('${topic.label} fra $currentLabel = ${topic.houseFromCurrent}. fra ${currentHouse}. = ${nextHouse}. hus');
      currentHouse = nextHouse;
      questionType = topic.questionType;
    }

    // Undgå at kalde helt almindelige 1.-hus-spørgsmål "afledte".
    if (steps.isEmpty || currentHouse == 1 && relationMatches.isEmpty) return null;

    return DerivedHouseResult(
      finalHouse: currentHouse,
      questionType: questionType,
      steps: steps,
      explanation: 'Afledt hus: ${steps.join('; ')}.',
    );
  }

  static int _turnedHouse(int baseHouse, int houseFromBase) {
    return ((baseHouse + houseFromBase - 2) % 12) + 1;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\n\t]+'), ' ')
        .replaceAll(RegExp(r'[^a-zæøå0-9\s-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsAny(String q, List<String> terms) => terms.any(q.contains);

  static List<_RelationMatch> _findRelationMatches(String q) {
    final matches = <_RelationMatch>[];
    for (final step in _relationSteps) {
      for (final term in step.terms) {
        final index = q.indexOf(term);
        if (index >= 0) {
          matches.add(_RelationMatch(step, index, index + term.length));
          break;
        }
      }
    }

    matches.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      // Ved samme start bruges længste/tydeligste udtryk først.
      return (b.end - b.start).compareTo(a.end - a.start);
    });

    final result = <_RelationMatch>[];
    var lastEnd = -1;
    for (final m in matches) {
      if (m.start < lastEnd) continue;
      result.add(m);
      lastEnd = m.end;
    }
    return result.take(4).toList();
  }

  static _TopicStep? _findBestTopic(String q, {required int afterIndex}) {
    final tail = afterIndex <= 0 || afterIndex >= q.length ? q : q.substring(afterIndex);
    _TopicStep? best;
    var bestScore = -1;
    for (final topic in _topicSteps) {
      var score = 0;
      for (final term in topic.terms) {
        if (tail.contains(term)) score += topic.weight + term.length;
      }
      if (score > bestScore && score > 0) {
        best = topic;
        bestScore = score;
      }
    }
    return best;
  }

  static const List<_HouseStep> _relationSteps = [
    _HouseStep(
      label: 'datter/søn/barn',
      houseFromCurrent: 5,
      questionType: HoraryQuestionType.childrenPregnancy,
      terms: ['min datter', 'min søn', 'min son', 'mit barn', 'mine børn', 'mine born', 'datter', 'søn', 'son', 'barn', 'børn', 'born'],
    ),
    _HouseStep(
      label: 'partner/ægtefælle',
      houseFromCurrent: 7,
      questionType: HoraryQuestionType.marriagePartner,
      terms: ['ægtefælle', 'aegtefaelle', 'ægtefællens', 'aegtefaellens', 'kæreste', 'kaereste', 'kærestens', 'kaerestens', 'partner', 'partnerens', 'min mand', 'min mands', 'min kone', 'min kones', 'mand', 'mands', 'mandens', 'kone', 'kones', 'konens'],
    ),
    _HouseStep(
      label: 'søskende/nabo',
      houseFromCurrent: 3,
      questionType: HoraryQuestionType.siblingsNeighbors,
      terms: ['søster', 'soster', 'bror', 'søskende', 'soskende', 'nabo'],
    ),
    _HouseStep(
      label: 'forælder/familie',
      houseFromCurrent: 4,
      questionType: HoraryQuestionType.familyParent,
      terms: ['mor', 'far', 'forælder', 'foraelder', 'familie'],
    ),
    _HouseStep(
      label: 'chef/arbejdsgiver',
      houseFromCurrent: 10,
      questionType: HoraryQuestionType.bossAuthority,
      terms: ['chef', 'leder', 'arbejdsgiver', 'direktør', 'direktor', 'myndighed', 'dommer'],
    ),
    _HouseStep(
      label: 'ven/gruppe',
      houseFromCurrent: 11,
      questionType: HoraryQuestionType.friendsGroups,
      terms: ['veninde', 'venner', 'ven ', 'gruppe', 'forening', 'klub'],
    ),
    _HouseStep(
      label: 'klient/kunde/modpart',
      houseFromCurrent: 7,
      questionType: HoraryQuestionType.clientConsultation,
      terms: ['klient', 'kunde', 'modpart', 'modstander', 'konkurrent'],
    ),
    _HouseStep(
      label: 'kæledyr/lille dyr',
      houseFromCurrent: 6,
      questionType: HoraryQuestionType.petsSmallAnimals,
      terms: ['hund', 'kat', 'kæledyr', 'kaeledyr', 'kanin', 'fugl'],
    ),
    _HouseStep(
      label: 'stort dyr',
      houseFromCurrent: 12,
      questionType: HoraryQuestionType.largeAnimals,
      terms: ['hest', 'ko', 'kvæg', 'kvaeg', 'stort dyr', 'store dyr'],
    ),
  ];

  static const List<_TopicStep> _topicSteps = [
    _TopicStep(
      label: 'penge/økonomi',
      houseFromCurrent: 2,
      questionType: HoraryQuestionType.money,
      weight: 10,
      terms: ['penge', 'økonomi', 'okonomi', 'betaling', 'betalt', 'løn', 'lon', 'indtægt', 'indtaegt', 'honorar', 'pension'],
    ),
    _TopicStep(
      label: 'mistet/fundet ejendel',
      houseFromCurrent: 2,
      questionType: HoraryQuestionType.lostThing,
      weight: 12,
      terms: [
        'tørklæde', 'toerklaede', 'halstørklæde', 'halstoerklaede',
        'nøgle', 'nøgler', 'noegle', 'noegler', 'pung', 'taske', 'ur', 'ring',
        'briller', 'hat', 'handsker', 'jakke', 'frakke', 'sko', 'bog', 'bøger', 'boeger',
        'mobil', 'telefon', 'computer', 'ipad', 'tablet', 'bil', 'cykel',
        'mistet', 'forsvundet', 'tabt', 'glemt', 'forlagt', 'finde', 'fundet',
      ],
    ),
    _TopicStep(
      label: 'ejendel/ting',
      houseFromCurrent: 2,
      questionType: HoraryQuestionType.possessions,
      weight: 8,
      terms: ['ejendel', 'ejendele', 'ting', 'værdi', 'vaerdi', 'tøj', 'toj', 'klæder', 'klaeder', 'computer', 'telefon', 'bil', 'cykel'],
    ),
    _TopicStep(
      label: 'besked/kontakt',
      houseFromCurrent: 3,
      questionType: HoraryQuestionType.messageContact,
      weight: 8,
      terms: ['besked', 'sms', 'mail', 'email', 'opkald', 'kontakt', 'svarer', 'ringer'],
    ),
    _TopicStep(
      label: 'bolig/hjem',
      houseFromCurrent: 4,
      questionType: HoraryQuestionType.homeProperty,
      weight: 8,
      terms: ['bolig', 'hus', 'lejlighed', 'ejendom', 'grund', 'sommerhus', 'hjem', 'flytte'],
    ),
    _TopicStep(
      label: 'barn/børn',
      houseFromCurrent: 5,
      questionType: HoraryQuestionType.childrenPregnancy,
      weight: 8,
      terms: ['barn', 'børn', 'born', 'gravid', 'graviditet', 'fødsel', 'fodsel'],
    ),
    _TopicStep(
      label: 'sygdom/helbred',
      houseFromCurrent: 6,
      questionType: HoraryQuestionType.illnessHealth,
      weight: 9,
      terms: ['syg', 'sygdom', 'helbred', 'smerte', 'feber', 'læge', 'laege', 'behandling', 'medicin'],
    ),
    _TopicStep(
      label: 'dagligt arbejde/pligt',
      houseFromCurrent: 6,
      questionType: HoraryQuestionType.dailyWork,
      weight: 7,
      terms: ['dagligt arbejde', 'arbejdsopgave', 'rutine', 'kollega', 'ansat hos', 'pligt'],
    ),
    _TopicStep(
      label: 'partner/kontrakt/modpart',
      houseFromCurrent: 7,
      questionType: HoraryQuestionType.marriagePartner,
      weight: 7,
      terms: ['partner', 'mand', 'kone', 'ægtefælle', 'aegtefaelle', 'kæreste', 'kaereste', 'kontrakt', 'aftale', 'modpart'],
    ),
    _TopicStep(
      label: 'gæld/arv/forsikring',
      houseFromCurrent: 8,
      questionType: HoraryQuestionType.loanDebtTax,
      weight: 8,
      terms: ['gæld', 'gaeld', 'lån', 'laan', 'skat', 'arv', 'forsikring', 'erstatning', 'dødsbo', 'dodsbo'],
    ),
    _TopicStep(
      label: 'lang rejse/uddannelse',
      houseFromCurrent: 9,
      questionType: HoraryQuestionType.abroadTravel,
      weight: 8,
      terms: ['udland', 'lang rejse', 'flyrejse', 'uddannelse', 'studie', 'universitet', 'eksamen', 'kursus'],
    ),
    _TopicStep(
      label: 'job/karriere/status',
      houseFromCurrent: 10,
      questionType: HoraryQuestionType.job,
      weight: 10,
      terms: ['job', 'arbejde', 'stilling', 'ansættelse', 'ansaettelse', 'karriere', 'forfremmelse', 'ry', 'status', 'omdømme', 'omdomme'],
    ),
    _TopicStep(
      label: 'titel/mesterskab/sejr',
      houseFromCurrent: 10,
      questionType: HoraryQuestionType.championshipTitle,
      weight: 11,
      terms: ['vinder vm', 'vinde vm', 'verdensmester', 'verdensmesterskab', 'mesterskab', 'mesterskabet', 'titel', 'titlen', 'pokal', 'pokalen', 'trofæ', 'trofae', 'champion', 'guldmedalje'],
    ),
    _TopicStep(
      label: 'venner/håb/planer',
      houseFromCurrent: 11,
      questionType: HoraryQuestionType.friendsGroups,
      weight: 7,
      terms: ['venner', 'gruppe', 'forening', 'netværk', 'netvaerk', 'håb', 'haab', 'ønske', 'onske', 'plan'],
    ),
    _TopicStep(
      label: 'hemmelighed/isolation/skjult modstand',
      houseFromCurrent: 12,
      questionType: HoraryQuestionType.secretsUnknown,
      weight: 7,
      terms: ['hemmelighed', 'skjult', 'ukendt', 'hospital', 'institution', 'isolation', 'bag min ryg'],
    ),
  ];
}

class _HouseStep {
  final String label;
  final int houseFromCurrent;
  final HoraryQuestionType questionType;
  final List<String> terms;

  const _HouseStep({
    required this.label,
    required this.houseFromCurrent,
    required this.questionType,
    required this.terms,
  });
}

class _TopicStep extends _HouseStep {
  final int weight;

  const _TopicStep({
    required super.label,
    required super.houseFromCurrent,
    required super.questionType,
    required super.terms,
    required this.weight,
  });
}

class _RelationMatch {
  final _HouseStep step;
  final int start;
  final int end;

  const _RelationMatch(this.step, this.start, this.end);
}
