import '../models/horary_models.dart';
import 'derived_house_resolver.dart';

class HouseSuggestion {
  final int house;
  final HoraryQuestionType questionType;
  final int score;
  final String reason;
  final bool isDerived;

  const HouseSuggestion({
    required this.house,
    required this.questionType,
    required this.score,
    required this.reason,
    this.isDerived = false,
  });

  String get title => isDerived
      ? 'Afledt: $house. hus – ${questionType.shortLabel}'
      : '$house. hus – ${questionType.shortLabel}';
}

class QuestionValidationResult {
  final String question;
  final bool hasEnoughText;
  final bool isQuestionLike;
  final bool hasSingleFocus;
  final bool isConcreteEnough;
  final bool isValid;
  final HoraryAnswerMode answerMode;
  final String verdict;
  final List<String> warnings;
  final List<HouseSuggestion> suggestions;

  const QuestionValidationResult({
    required this.question,
    required this.hasEnoughText,
    required this.isQuestionLike,
    required this.hasSingleFocus,
    required this.isConcreteEnough,
    required this.isValid,
    required this.answerMode,
    required this.verdict,
    required this.warnings,
    required this.suggestions,
  });

  HouseSuggestion? get bestSuggestion => suggestions.isEmpty ? null : suggestions.first;
}

class QuestionValidator {
  const QuestionValidator();

  QuestionValidationResult validate(String rawQuestion) {
    final question = rawQuestion.trim();
    final q = _normalize(question);
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (q == 'test') {
      return const QuestionValidationResult(
        question: 'test',
        hasEnoughText: true,
        isQuestionLike: true,
        hasSingleFocus: true,
        isConcreteEnough: true,
        isValid: true,
        answerMode: HoraryAnswerMode.yesNo,
        verdict: 'Testspørgsmål accepteret.',
        warnings: <String>[],
        suggestions: <HouseSuggestion>[
          HouseSuggestion(
            house: 7,
            questionType: HoraryQuestionType.general,
            score: 1,
            reason: 'Testtilstand: generelt spørgsmål med manuelt/standard husvalg.',
          ),
        ],
      );
    }

    final warnings = <String>[];
    final hasEnoughText = question.length >= 8 && words.length >= 3;
    if (!hasEnoughText && question.isNotEmpty) {
      warnings.add('Spørgsmålet er for kort. Skriv helst en hel sætning.');
    }

    final isQuestionLike = question.contains('?') || _looksLikeQuestion(q);
    if (question.isNotEmpty && !isQuestionLike) {
      warnings.add('Skriv det som et egentligt spørgsmål, fx “Får jeg jobbet?” eller “Kommer han tilbage?”.');
    }

    final hasSingleFocus = _hasSingleFocus(q);
    if (!hasSingleFocus) {
      warnings.add('Spørgsmålet ser ud til at rumme flere spørgsmål. Horar virker bedst med ét klart fokus.');
    }

    final isConcreteEnough = !_isTooBroad(q);
    if (!isConcreteEnough) {
      warnings.add('Spørgsmålet er for bredt. Gør det konkret: én sag, én person, én beslutning eller ét udfald.');
    }

    final answerMode = detectHoraryAnswerMode(question);
    final suggestions = _suggestHouses(q);
    if (hasEnoughText && suggestions.isEmpty) {
      warnings.add('Jeg kan ikke tydeligt se hvilket hus spørgsmålet tilhører. Vælg hus manuelt.');
    }

    final isValid = hasEnoughText && isQuestionLike && hasSingleFocus && isConcreteEnough;
    final verdict = _verdict(isValid: isValid, warnings: warnings, suggestions: suggestions);

    return QuestionValidationResult(
      question: question,
      hasEnoughText: hasEnoughText,
      isQuestionLike: isQuestionLike,
      hasSingleFocus: hasSingleFocus,
      isConcreteEnough: isConcreteEnough,
      isValid: isValid,
      answerMode: answerMode,
      verdict: verdict,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeQuestion(String q) {
    if (q.isEmpty) return false;
    final starts = <String>[
      'skal ',
      'vil ',
      'får ',
      'far ',
      'kommer ',
      'bliver ',
      'er ',
      'kan ',
      'bør ',
      'bor ',
      'har ',
      'må ',
      'ma ',
      'hvor ',
      'hvornår ',
      'hvornar ',
      'hvad ',
      'hvem ',
      'hvilken ',
      'hvilket ',
      'hvilke ',
      'hvordan ',
      'hvorfor ',
      'finder ',
      'mister ',
    ];
    if (starts.any(q.startsWith)) return true;

    final questionPhrases = <String>[
      'skal jeg',
      'vil jeg',
      'får jeg',
      'far jeg',
      'kommer jeg',
      'kan jeg',
      'bør jeg',
      'bor jeg',
      'vil han',
      'vil hun',
      'kommer han',
      'kommer hun',
      'får vi',
      'far vi',
      'er det',
      'kan det',
      'bliver det',
    ];
    return questionPhrases.any(q.contains);
  }

  bool _hasSingleFocus(String q) {
    final questionMarks = '?'.allMatches(q).length;
    if (questionMarks > 1) return false;

    final multiQuestionSignals = <String>[
      ' og skal ',
      ' og vil ',
      ' og får ',
      ' og far ',
      ' eller skal ',
      ' eller vil ',
      ' eller får ',
      ' eller far ',
      ' både ',
      ' bade ',
      ' samt om ',
    ];
    return !multiQuestionSignals.any(q.contains);
  }

  bool _isTooBroad(String q) {
    final broadPatterns = <String>[
      'hvad siger stjernerne',
      'hvad bringer fremtiden',
      'mit liv',
      'resten af mit liv',
      'alt om',
      'generelt',
      'generel horoskop',
      'hvordan bliver fremtiden',
      'fortæl mig om',
      'fortael mig om',
    ];
    return broadPatterns.any(q.contains);
  }

  String _verdict({
    required bool isValid,
    required List<String> warnings,
    required List<HouseSuggestion> suggestions,
  }) {
    if (isValid && suggestions.isNotEmpty) {
      return 'Spørgsmålet kan bruges. Jeg har også et husforslag.';
    }
    if (isValid) {
      return 'Spørgsmålet kan bruges, men hus bør vælges manuelt.';
    }
    if (warnings.isEmpty) return 'Skriv et spørgsmål.';
    return 'Spørgsmålet bør justeres før beregning.';
  }

  List<HouseSuggestion> _suggestHouses(String q) {
    final derived = DerivedHouseResolver.resolve(q);
    final scored = <_ScoredType>[];

    void add(HoraryQuestionType type, int score, List<String> terms, String reason) {
      var points = 0;
      for (final term in terms) {
        if (_containsTerm(q, term)) points += score;
      }
      if (points > 0) {
        scored.add(_ScoredType(type: type, score: points, reason: reason));
      }
    }

    add(HoraryQuestionType.selfIdentity, 4, [
      'mig selv', 'min situation', 'hvem er jeg', 'min rolle', 'min vej',
    ], 'Spørgsmålet handler primært om spørgeren selv.');
    add(HoraryQuestionType.bodyAppearance, 5, [
      'krop', 'udseende', 'fremtoning', 'vitalitet', 'helbredstilstand',
    ], 'Krop og personlig fremtoning hører til 1. hus.');
    add(HoraryQuestionType.personalDecision, 4, [
      'skal jeg', 'bør jeg', 'bor jeg', 'kan jeg gøre', 'beslutning', 'vælge', 'valget',
    ], 'Personlig beslutning peger ofte på 1. hus og spørgerens handlekraft.');

    add(HoraryQuestionType.money, 5, [
      'penge', 'betaling', 'betalt', 'økonomi', 'okonomi', 'råd til', 'rad til', 'pris', 'købe', 'kobe',
    ], 'Egne penge og betaling hører til 2. hus.');
    add(HoraryQuestionType.salaryIncome, 6, [
      'løn', 'lon', 'indtægt', 'indtaegt', 'honorar', 'faktura', 'udbetaling', 'pension',
    ], 'Løn, honorar og indtægt peger på 2. hus.');
    add(HoraryQuestionType.possessions, 5, [
      'ejendel', 'ting', 'værdi', 'vaerdi', 'udstyr', 'computer', 'telefon', 'bil', 'cykel',
    ], 'Ejendele og værdigenstande hører til 2. hus.');
    add(HoraryQuestionType.lostThing, 9, [
      'tabt', 'mistet', 'forsvundet', 'væk', 'vaek', 'finde min', 'finder jeg', 'hvor er min', 'hvor ligger',
    ], 'Tabte og forsvundne ting læses normalt fra 2. hus.');

    add(HoraryQuestionType.messageContact, 6, [
      'besked', 'sms', 'mail', 'email', 'opkald', 'ringer', 'kontakte', 'kontakt', 'svarer', 'svar',
    ], 'Beskeder, opkald og kontakt hører til 3. hus.');
    add(HoraryQuestionType.siblingsNeighbors, 6, [
      'søster', 'soster', 'bror', 'søskende', 'soskende', 'nabo', 'nærmiljø', 'naermiljo',
    ], 'Søskende, naboer og nærmiljø hører til 3. hus.');
    add(HoraryQuestionType.shortTrip, 6, [
      'kort rejse', 'tur', 'transport', 'tog', 'bus', 'billet', 'pendle', 'køre', 'kore',
    ], 'Korte rejser og lokal transport peger på 3. hus.');
    add(HoraryQuestionType.documentsLetters, 6, [
      'dokument', 'brev', 'papir', 'kontrakttekst', 'formular', 'ansøgning', 'ansogning',
    ], 'Dokumenter, breve og papirarbejde kan pege på 3. hus.');

    add(HoraryQuestionType.homeProperty, 7, [
      'hus', 'bolig', 'lejlighed', 'ejendom', 'grund', 'sommerhus', 'hjem',
    ], 'Bolig, ejendom og hjem hører til 4. hus.');
    add(HoraryQuestionType.movingHome, 8, [
      'flytte', 'flytning', 'nyt hjem', 'ny bolig', 'sælge huset', 'saelge huset', 'købe hus', 'kobe hus',
    ], 'Flytning og nyt hjem peger på 4. hus.');
    add(HoraryQuestionType.familyParent, 6, [
      'familie', 'mor', 'far', 'forælder', 'foraelder', 'privatliv', 'hjemme',
    ], 'Familie, hjem og forældre peger ofte på 4. hus.');
    add(HoraryQuestionType.endingsOutcome, 5, [
      'ender det', 'slutter det', 'afslutning', 'udfaldet', 'endeligt resultat',
    ], 'Sagens slutning og bund kan ses fra 4. hus.');

    add(HoraryQuestionType.childrenPregnancy, 8, [
      'barn', 'børn', 'born', 'gravid', 'graviditet', 'fødsel', 'fodsel',
    ], 'Børn og graviditet hører til 5. hus.');
    add(HoraryQuestionType.romanceDating, 7, [
      'flirt', 'dating', 'date', 'forelsket', 'romance', 'romantisk',
    ], 'Flirt og dating uden fast relation peger på 5. hus.');
    add(HoraryQuestionType.creativeProject, 6, [
      'kreativ', 'bog', 'roman', 'kunst', 'musik', 'projekt', 'skrive', 'udstilling',
    ], 'Kreative projekter kan læses fra 5. hus.');
    add(HoraryQuestionType.funHobby, 5, [
      'hobby', 'spil', 'fornøjelse', 'fornojelse', 'fest', 'ferieaktivitet',
    ], 'Hobby, spil og fornøjelse hører til 5. hus.');

    add(HoraryQuestionType.illnessHealth, 8, [
      'syg', 'sygdom', 'helbred', 'smerte', 'feber', 'træt', 'traet', 'blodtryk', 'læge', 'laege',
    ], 'Sygdom og helbred peger på 6. hus.');
    add(HoraryQuestionType.treatmentRecovery, 8, [
      'bedring', 'rask', 'restitution', 'behandling', 'komme mig', 'bliver jeg rask',
    ], 'Behandling og bedring peger på sygdomsreglerne omkring 6. hus.');
    add(HoraryQuestionType.acuteIllness, 9, [
      'akut', 'pludselig', 'forværring', 'forvaerring', 'skadestue', 'anfald',
    ], 'Akut sygdom læses varsomt fra 6. hus og affliktioner.');
    add(HoraryQuestionType.diagnosisSymptoms, 9, [
      'symptom', 'hvad fejler', 'diagnose', 'årsag til smerte', 'aarsag til smerte',
    ], 'Symptomer peger på 6. hus, men appen kan ikke stille diagnose.');
    add(HoraryQuestionType.medicineTreatment, 8, [
      'medicin', 'piller', 'operation', 'behandler', 'terapi', 'kur',
    ], 'Medicin og behandling peger på 6. hus med supplerende behandler-vurdering.');
    add(HoraryQuestionType.dailyWork, 6, [
      'dagligt arbejde', 'arbejdsopgave', 'rutine', 'kollega', 'ansat', 'pligt',
    ], 'Dagligt arbejde og pligter hører til 6. hus.');
    add(HoraryQuestionType.petsSmallAnimals, 8, [
      'hund', 'kat', 'kæledyr', 'kaeledyr', 'kanin', 'fugl', 'små dyr', 'sma dyr',
    ], 'Kæledyr og små dyr hører til 6. hus.');

    add(HoraryQuestionType.love, 8, [
      'kærlighed', 'kaerlighed', 'elsker', 'elsker mig', 'forhold', 'relation', 'tilbage til mig',
    ], 'Fast kærlighed/relation læses fra 7. hus.');
    add(HoraryQuestionType.marriagePartner, 8, [
      'ægtefælle', 'aegtefaelle', 'mand', 'kone', 'partner', 'parforhold', 'ægteskab', 'aegteskab',
    ], 'Partner og ægteskab hører til 7. hus.');
    add(HoraryQuestionType.contractDeal, 7, [
      'kontrakt', 'aftale', 'handel', 'købsaftale', 'kobsaftale', 'salgsaftale', 'underskrive',
    ], 'Kontrakter, aftaler og handel peger på 7. hus.');
    add(HoraryQuestionType.opponentLawsuit, 7, [
      'modpart', 'modstander', 'fjende', 'konkurrent', 'uenighed', 'konflikt',
    ], 'Åben modpart og konflikt peger på 7. hus.');
    add(HoraryQuestionType.courtCase, 10, [
      'retssag', 'retten', 'domstol', 'sag i retten', 'vinder jeg sagen', 'taber jeg sagen',
    ], 'Retssag vurderes med 1., 7., 10. og 4. hus; start normalt med modparten i 7. hus.');
    add(HoraryQuestionType.judgeDecision, 8, [
      'dommer', 'afgørelse', 'afgorelse', 'myndighed', 'kommune', 'skat afgørelse', 'afgør', 'afgor',
    ], 'Dommer og myndighedens afgørelse peger på 10. hus.');
    add(HoraryQuestionType.lawyerAdvice, 8, [
      'advokat', 'juridisk', 'lov', 'rådgivning', 'radgivning', 'paragraf',
    ], 'Advokat og juridisk rådgivning peger på 9. hus.');
    add(HoraryQuestionType.clientConsultation, 6, [
      'klient', 'kunde', 'konsultation', 'patient hos mig',
    ], 'Klient eller kunde står ofte i 7. hus.');

    add(HoraryQuestionType.loanDebtTax, 8, [
      'lån', 'laan', 'gæld', 'gaeld', 'skat', 'erstatning', 'krav', 'renter',
    ], 'Lån, gæld, skat og erstatning hører til 8. hus.');
    add(HoraryQuestionType.inheritanceInsurance, 8, [
      'arv', 'forsikring', 'dødsbo', 'dodsbo', 'boet', 'fælles midler', 'faelles midler',
    ], 'Arv, forsikring og fælles midler peger på 8. hus.');
    add(HoraryQuestionType.partnerMoney, 7, [
      'hans penge', 'hendes penge', 'partnerens penge', 'andres penge',
    ], 'Den anden parts penge er 8. hus, dvs. 2. fra 7. hus.');
    add(HoraryQuestionType.fearCrisis, 5, [
      'frygt', 'bange', 'krise', 'tab', 'risiko', 'bekymret for',
    ], 'Frygt, krise og tab kan pege på 8. hus.');

    add(HoraryQuestionType.abroadTravel, 8, [
      'udland', 'lang rejse', 'rejse til', 'flyrejse', 'ferie i', 'emigrere',
    ], 'Udland og lange rejser hører til 9. hus.');
    add(HoraryQuestionType.higherEducation, 7, [
      'uddannelse', 'studie', 'universitet', 'kursus', 'skole', 'lære', 'laere',
    ], 'Højere uddannelse og studier peger på 9. hus.');
    add(HoraryQuestionType.examStudy, 8, [
      'eksamen', 'prøve', 'prove', 'består', 'bestaar', 'karakter',
    ], 'Eksamen og prøve vurderes fra 9. hus, med 10. hus som dom/resultat.');
    add(HoraryQuestionType.lawReligion, 6, [
      'religion', 'filosofi', 'livssyn', 'tro', 'lovgivning',
    ], 'Lov, religion og højere principper peger på 9. hus.');
    add(HoraryQuestionType.publishingMedia, 7, [
      'udgivelse', 'publicere', 'forlag', 'medie', 'artikel', 'bogudgivelse',
    ], 'Udgivelse, kurser og større formidling peger på 9. hus.');

    add(HoraryQuestionType.job, 9, [
      'job', 'arbejde', 'stilling', 'ansættelse', 'ansaettelse', 'ansat', 'karriere',
    ], 'Job, stilling og karriere hører til 10. hus.');
    add(HoraryQuestionType.promotionCareer, 8, [
      'forfremmelse', 'karrierespring', 'ny rolle', 'chefstilling', 'avancement',
    ], 'Forfremmelse og karrierespring peger på 10. hus.');
    add(HoraryQuestionType.bossAuthority, 8, [
      'chef', 'leder', 'autoritet', 'myndighed', 'direktør', 'direktor',
    ], 'Chef, autoritet og myndighed hører til 10. hus.');
    add(HoraryQuestionType.reputationStatus, 7, [
      'ry', 'omdømme', 'omdomme', 'status', 'anerkendelse', 'offentlig',
    ], 'Ry, status og offentlig position peger på 10. hus.');
    add(HoraryQuestionType.businessCompany, 7, [
      'firma', 'virksomhed', 'forretning', 'app store', 'appstore', 'projektets succes',
    ], 'Firmaets synlige succes og position peger ofte på 10. hus.');

    if (_isChampionshipTitleQuestion(q)) {
      scored.add(const _ScoredType(
        type: HoraryQuestionType.championshipTitle,
        score: 80,
        reason: 'Spørgsmålet handler om titel, mesterskab, pokal eller offentlig sejr. Det peger på 10. hus; sport/spil kan være 5. hus som baggrund.',
      ));
    }

    add(HoraryQuestionType.friendsGroups, 7, [
      'ven', 'venner', 'gruppe', 'forening', 'klub', 'fællesskab', 'faellesskab',
    ], 'Venner, grupper og foreninger hører til 11. hus.');
    add(HoraryQuestionType.hopesPlans, 6, [
      'håb', 'haab', 'ønske', 'onske', 'plan', 'drøm', 'drom',
    ], 'Håb, ønsker og planer peger på 11. hus.');
    add(HoraryQuestionType.patronSupport, 7, [
      'støtte', 'stotte', 'hjælp', 'hjaelp', 'sponsor', 'velynder', 'anbefaling',
    ], 'Støtte, hjælpere og sponsorer peger på 11. hus.');
    add(HoraryQuestionType.communityNetwork, 6, [
      'netværk', 'netvaerk', 'online gruppe', 'community', 'sociale medier',
    ], 'Netværk og fællesskab peger på 11. hus.');

    add(HoraryQuestionType.hiddenEnemy, 7, [
      'skjult fjende', 'modarbejder mig', 'bag min ryg', 'hemmelig modstand',
    ], 'Skjult modstand og skjulte fjender hører til 12. hus.');
    add(HoraryQuestionType.secretsUnknown, 7, [
      'hemmelighed', 'skjult', 'ukendt', 'ved ikke hvad', 'løgn', 'logn',
    ], 'Hemmeligheder og det ukendte peger på 12. hus.');
    add(HoraryQuestionType.isolationHospital, 7, [
      'hospital', 'institution', 'isolation', 'indlagt', 'fængsel', 'faengsel',
    ], 'Isolation, hospital og lukkede steder hører til 12. hus.');
    add(HoraryQuestionType.selfUndoing, 7, [
      'selvsabotage', 'undergraver', 'mønster', 'monster', 'ubevidst',
    ], 'Selvsabotage og skjulte indre mønstre peger på 12. hus.');
    add(HoraryQuestionType.largeAnimals, 8, [
      'hest', 'ko', 'kvæg', 'kvaeg', 'store dyr', 'stor hund',
    ], 'Store dyr hører traditionelt til 12. hus.');

    final merged = <HoraryQuestionType, _ScoredType>{};
    for (final item in scored) {
      final old = merged[item.type];
      if (old == null || item.score > old.score) {
        merged[item.type] = item;
      }
    }

    final sorted = merged.values.toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.type.defaultHouse.compareTo(b.type.defaultHouse);
      });

    final normalSuggestions = sorted.take(3).map((item) {
      return HouseSuggestion(
        house: item.type.defaultHouse,
        questionType: item.type,
        score: item.score,
        reason: item.reason,
      );
    }).toList();

    if (derived == null) return normalSuggestions;

    final derivedSuggestion = HouseSuggestion(
      house: derived.finalHouse,
      questionType: derived.questionType,
      score: 999,
      reason: derived.explanation,
      isDerived: true,
    );

    return [
      derivedSuggestion,
      ...normalSuggestions.where((s) => s.house != derived.finalHouse).take(2),
    ];
  }

  bool _isChampionshipTitleQuestion(String q) {
    final hasChampionshipSignal = _containsAny(q, const [
      'vinder vm', 'vinde vm', 'vundet vm', 'bliver verdensmester', 'verdensmester',
      'verdensmesterskab', 'verdensmesterskabet', 'vinder mesterskabet',
      'vinde mesterskabet', 'mesterskab', 'mesterskabet', 'champion',
      'titel', 'titlen', 'pokal', 'pokalen', 'trofæ', 'trofae',
      'guldmedalje', 'guldmedaljen', 'turneringsvinder', 'vinder turneringen',
      'vinde turneringen', 'vinder ligaen', 'vinde ligaen',
    ]);

    if (!hasChampionshipSignal) return false;

    // Ved en konkret duel/finale mellem to navngivne parter skal appen ikke
    // kun gøre det til 10. hus. Der er parterne normalt 1./7. hus, mens
    // 10. hus stadig kan bruges som bekræftende faktor for titlen/sejren.
    final hasConcreteOpponent = _containsAny(q, const [
      ' mellem ', ' mod ', ' versus ', ' vs ', 'finalen mellem', 'kampen mellem',
      'danmark mod', 'mod danmark',
    ]);

    return !hasConcreteOpponent;
  }

  bool _containsAny(String q, List<String> terms) {
    return terms.any((term) => q.contains(term));
  }

  bool _containsTerm(String q, String term) {
    final t = term.toLowerCase();
    if (t.length <= 3) return q.contains(t);
    return q.contains(t);
  }
}

class _ScoredType {
  final HoraryQuestionType type;
  final int score;
  final String reason;

  const _ScoredType({
    required this.type,
    required this.score,
    required this.reason,
  });
}
