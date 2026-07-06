import '../models/horary_models.dart';
import 'special_question_rules.dart';

class HoraryJudgement {
  final String judgement;
  final String explanation;
  final int finalScore;
  final int scoreMin;
  final int scoreMax;
  final List<WeightedJudgementFactor> weightedFactors;
  final List<String> notes;
  final SpecialQuestionReading? specialReading;

  const HoraryJudgement({
    required this.judgement,
    required this.explanation,
    required this.finalScore,
    required this.scoreMin,
    required this.scoreMax,
    required this.weightedFactors,
    required this.notes,
    this.specialReading,
  });
}

class HoraryRules {
  HoraryJudgement judge(HoraryChart chart) {
    final notes = <String>[];
    final factors = <WeightedJudgementFactor>[];

    void addFactor(
      String category,
      String title,
      int weight,
      String explanation,
    ) {
      if (weight == 0) return;
      factors.add(WeightedJudgementFactor(
        category: category,
        title: title,
        weight: weight,
        explanation: explanation,
      ));
    }

    final querent = chart.planetByName(chart.querentRuler);
    final quesited = chart.planetByName(chart.quesitedRuler);
    final moon = chart.planetByName('Måne');
    final querentCondition = chart.conditionFor(chart.querentRuler);
    final quesitedCondition = chart.conditionFor(chart.quesitedRuler);
    final specialReading = const SpecialQuestionRules().read(chart);

    notes.add('Spørgeren vurderes fra 1. hus: ${chart.querentRuler}.');
    notes.add('Det adspurgte vurderes fra ${chart.quesitedHouse}. hus: ${chart.quesitedRuler}.');
    if (chart.derivedHouseExplanation != null) {
      notes.add(chart.derivedHouseExplanation!);
    }
    notes.add('Månen bruges som medsignifikator og viser sagens flow.');
    if (chart.questionType != HoraryQuestionType.general) {
      notes.add('Spørgsmålstype: ${chart.questionType.shortLabel}. ${chart.questionType.ruleHint}');
    }

    if (querent != null && querentCondition != null) {
      notes.add(
        '${chart.querentRuler} står i ${querent.house}. hus i ${querent.sign}; styrke ${querentCondition.totalScore} (${querentCondition.summary}).',
      );
    }
    if (quesited != null && quesitedCondition != null) {
      notes.add(
        '${chart.quesitedRuler} står i ${quesited.house}. hus i ${quesited.sign}; styrke ${quesitedCondition.totalScore} (${quesitedCondition.summary}).',
      );
    }

    _addSolarConditionNotes(chart, notes);

    final sigAspect = chart.significatorAspect;
    if (sigAspect != null) {
      notes.add('Hovedsignifikatorerne har forbindelse: ${sigAspect.text}.');
      if (sigAspect.applying && sigAspect.beforeSignChange) {
        notes.add('Aspektet perfekterer før tegnskifte. Det er den vigtigste støttende indikator i denne regelpakke.');
        addFactor(
          'Kerne',
          'Hovedsignifikatorerne perfekterer',
          5,
          '${chart.querentRuler} og ${chart.quesitedRuler} danner et applikativt aspekt før tegnskifte. Det er den stærkeste simple indikator for, at sagen kan fuldbyrdes.',
        );
      } else if (sigAspect.applying && !sigAspect.beforeSignChange) {
        notes.add('Aspektet perfekterer først efter tegnskifte. Det svækker sagen og kan vise, at forholdene ændrer sig før udfaldet.');
        addFactor(
          'Kerne',
          'Perfektion først efter tegnskifte',
          1,
          'Der er forbindelse, men en planet skifter tegn før perfektionen. Det giver kun svag realisering, fordi sagens betingelser ændrer sig.',
        );
      } else {
        notes.add('Aspektet er separativt og beskriver mere noget, der allerede er sket, end noget der vil ske.');
        addFactor(
          'Kerne',
          'Aspektet er separativt',
          -2,
          'Forbindelsen ligger bagud i tiden. Den beskriver baggrund eller tidligere kontakt mere end et kommende udfald.',
        );
      }
    } else {
      notes.add('Der er ikke fundet applikativ perfektion mellem hovedsignifikatorerne. Det taler imod en enkel og direkte realisering, medmindre translation eller collection hjælper.');
      addFactor(
        'Kerne',
        'Ingen direkte perfektion',
        -2,
        'Hovedsignifikatorerne når ikke hinanden direkte. Et gunstigt eller tydeligt udfald kræver derfor hjælp fra Månen, translation, collection eller tydelig reception.',
      );
    }

    if (chart.prohibition != null) {
      notes.add('Prohibition: ${chart.prohibition!.text}. En tredje faktor kommer før hovedperfektionen og kan forhindre sagen.');
      addFactor(
        'Hindring',
        'Prohibition',
        -5,
        'En anden planet når ind og bryder eller optager forbindelsen før hovedsignifikatorerne kan perfektere. Det er en stærk hindrings- eller blokeringindikator.',
      );
    }

    if (chart.frustration != null) {
      notes.add('Frustration: ${chart.frustration!.text}. Den adspurgte signifikator optages af noget andet før sagen kan fuldbyrdes.');
      addFactor(
        'Hindring',
        'Frustration',
        -4,
        'Den ene part bliver ført over i en anden kontakt før sagen fuldbyrdes. Det viser ofte at fokus, vilje eller mulighed flytter sig.',
      );
    }

    if (chart.translationOfLight != null) {
      notes.add('Translation of light: ${chart.translationOfLight!.text}. En mellemplanet kan forbinde signifikatorerne, selv hvis de ikke selv når hinanden direkte.');
      addFactor(
        'Hjælp',
        'Translation of light',
        4,
        'En mellemplanet bærer lyset fra den ene signifikator til den anden. Det kan føre sagen videre via mellemmand, besked, omvej eller praktisk hjælp.',
      );
    }

    if (chart.collectionOfLight != null) {
      notes.add('Collection of light: ${chart.collectionOfLight!.text}. En tredje planet kan samle sagen, ofte gennem en person, institution eller omstændighed.');
      addFactor(
        'Hjælp',
        'Collection of light',
        3,
        'Begge signifikatorer føres til en tredje planet. Det kan føre sagen gennem en samlende person, autoritet, ramme eller fælles mulighed.',
      );
    }

    if (chart.antiscionContacts.isNotEmpty) {
      notes.add('Antiscia: skjulte/spejlede forbindelser fundet. De kan vise en indirekte eller usynlig kontakt mellem emnets aktører.');
      for (final c in chart.antiscionContacts.take(3)) {
        notes.add('Antiscion-kontakt: ${c.text}.');
      }
    }

    if (chart.fixedStarContacts.isNotEmpty) {
      notes.add('Fixstjerner: tætte kontakter er fundet med lille orb. De beskriver ofte farvning/tema, ikke alene hovedsvaret.');
      for (final c in chart.fixedStarContacts.take(3)) {
        notes.add('Fixstjerne-kontakt: ${c.text}.');
      }
    }

    if (chart.moonPreviousAspect != null) {
      notes.add('Månens seneste aspekt: ${chart.moonPreviousAspect!.text}. Det beskriver baggrunden for spørgsmålet.');
    }
    if (chart.moonNextAspect != null) {
      notes.add('Månens næste aspekt: ${chart.moonNextAspect!.text}. Det beskriver næste udvikling.');
    }

    if (chart.moonVoidOfCourse) {
      notes.add('Void Moon: Månen danner intet ptolemæisk hovedaspekt før den forlader sit tegn. Det svækker udfaldet og peger ofte på, at intet væsentligt sker.');
      addFactor(
        'Månen',
        'Void-of-course Måne',
        -3,
        'Månen fører ikke sagen videre før tegnskifte. Det taler for stilstand, manglende udvikling eller at intet væsentligt sker.',
      );
    } else {
      notes.add('Månen er ikke void-of-course efter denne test, fordi den har et kommende hovedaspekt før tegnskifte.');
    }
    if (chart.moonViaCombusta) {
      notes.add('Månen står i via combusta. Det markerer uro, pres eller et mindre stabilt dømmekort.');
      addFactor(
        'Månen',
        'Månen i via combusta',
        -1,
        'Månens placering peger på uro, følelsesmæssigt pres eller mindre klarhed i sagen.',
      );
    }

    if (querent != null && quesited != null) {
      final qReceivesX = _isInDignityOf(querent, chart.quesitedRuler);
      final xReceivesQ = _isInDignityOf(quesited, chart.querentRuler);
      if (qReceivesX) {
        notes.add('${chart.querentRuler} står i ${chart.quesitedRuler}s værdighed: spørgeren er orienteret mod sagen/personen.');
        addFactor(
          'Reception',
          'Spørgeren modtager sagen',
          1,
          '${chart.querentRuler} står i en værdighed, der tilhører ${chart.quesitedRuler}. Det viser interesse, ønske eller rettethed mod sagen.',
        );
      }
      if (xReceivesQ) {
        notes.add('${chart.quesitedRuler} står i ${chart.querentRuler}s værdighed: sagen/personen modtager spørgeren.');
        addFactor(
          'Reception',
          'Sagen modtager spørgeren',
          2,
          '${chart.quesitedRuler} står i en værdighed, der tilhører ${chart.querentRuler}. Det er vigtigere end spørgerens ønske, fordi det viser svar fra den anden side.',
        );
      }
      if (!qReceivesX && !xReceivesQ) {
        notes.add('Der ses ikke stærk reception mellem hovedsignifikatorerne i herskerskab/eksaltation.');
      }
      if (qReceivesX && xReceivesQ) {
        notes.add('Der er gensidig reception i de simple værdigheder. Det hjælper sagen betydeligt.');
        addFactor(
          'Reception',
          'Gensidig reception',
          2,
          'Begge parter har værdighed hos hinanden. Det kan mildne svære aspekter og viser gensidig forbindelse.',
        );
      }
    }

    if (querentCondition != null) {
      final contribution = _scoreContribution(querentCondition.totalScore);
      addFactor(
        'Styrke',
        'Spørgerens signifikator: ${chart.querentRuler}',
        contribution,
        '${chart.querentRuler} har samlet styrke ${querentCondition.totalScore}: ${querentCondition.summary}. Det viser spørgerens handlekraft og situation.',
      );
    }
    if (quesitedCondition != null) {
      final contribution = _scoreContribution(quesitedCondition.totalScore);
      addFactor(
        'Styrke',
        'Sagens signifikator: ${chart.quesitedRuler}',
        contribution,
        '${chart.quesitedRuler} har samlet styrke ${quesitedCondition.totalScore}: ${quesitedCondition.summary}. Det viser om sagen/personen har kraft til at levere et resultat.',
      );
    }
    if (moon != null) {
      final moonCondition = chart.conditionFor('Måne');
      if (moonCondition != null) {
        final contribution = _scoreContribution(moonCondition.totalScore);
        addFactor(
          'Månen',
          'Månens styrke',
          contribution,
          'Månen har samlet styrke ${moonCondition.totalScore}: ${moonCondition.summary}. Den beskriver sagens flow og tempo.',
        );
      }
    }

    for (final planetName in <String>{chart.querentRuler, chart.quesitedRuler, 'Måne'}) {
      final solar = _solarScore(chart, planetName);
      if (solar != 0) {
        addFactor(
          'Sol-tilstand',
          _solarFactorTitle(chart, planetName),
          solar,
          _solarFactorExplanation(chart, planetName),
        );
      }
    }

    final advancedScore = _advancedSymbolScore(chart);
    if (advancedScore != 0) {
      addFactor(
        'Symbolsk ekstra',
        'Antiscia/fixstjerner',
        advancedScore,
        'Antiscia og udvalgte fixstjerner farver vigtige punkter i kortet. Her bruges de kun som en lille justering, ikke som hoveddom.',
      );
    }

    if (specialReading != null) {
      addFactor(
        'Spørgsmålstype',
        specialReading.title,
        specialReading.scoreAdjustment,
        specialReading.summary,
      );
      notes.add(specialReading.summary);
      for (final rule in specialReading.rules) {
        notes.add(rule);
      }
      for (final hint in specialReading.hints) {
        notes.add('Hint: $hint');
      }
    }

    final score = factors.fold<int>(0, (sum, f) => sum + f.weight);
    final scoreMin = factors.where((f) => f.weight < 0).fold<int>(0, (sum, f) => sum + f.weight);
    final scoreMax = factors.where((f) => f.weight > 0).fold<int>(0, (sum, f) => sum + f.weight);
    final scoreLabel = _answerLabel(score, scoreMin, scoreMax);
    final scope = chart.questionType == HoraryQuestionType.general
        ? ''
        : ' for ${chart.questionType.shortLabel.toLowerCase()}';

    final judgement = _judgementTitle(chart.answerMode, scoreLabel, scope, chart, score, scoreMin, scoreMax);

    final explanation = _judgementExplanation(score, scoreMin, scoreMax, factors, chart);

    notes.add('Svarform: ${chart.answerMode.label}. Spørgsmålets indledning styrer om appen formulerer svaret som ja/nej, sted, timing, mængde, person, sagstype, forløb eller årsag.');
    notes.add('Samlet vægtet score: $score i det beregnede referenceinterval ${_signed(scoreMin)} til ${_signed(scoreMax)}. Intervallet udregnes hver gang ud fra de positive og negative faktorer, der faktisk er aktive i dette kort.');
    notes.add('Forklaringen er en prioriteret læsning af reglerne. Den erstatter ikke astrologisk dømmekraft, men viser tydeligt hvorfor appen ender på svarretningen og den valgte svarform.');
    notes.add('Stadig forenklet: fuld triplicitet, terms, faces og præcist fixstjernekatalog er ikke implementeret.');

    return HoraryJudgement(
      judgement: judgement,
      explanation: explanation,
      finalScore: score,
      scoreMin: scoreMin,
      scoreMax: scoreMax,
      weightedFactors: factors,
      notes: notes,
      specialReading: specialReading,
    );
  }


  String _signed(int value) => value > 0 ? '+$value' : value.toString();

  String _answerLabel(int score, int scoreMin, int scoreMax) {
    if (score == 0) return 'uklart eller balanceret';

    if (score > 0) {
      if (scoreMax <= 0) return 'uklart eller svagt ja';
      final ratio = score / scoreMax;
      if (ratio >= 0.70) return 'klart ja';
      if (ratio >= 0.45) return 'sandsynligvis ja';
      if (ratio >= 0.20) return 'svagt eller betinget ja';
      return 'uklart eller svagt ja';
    }

    if (scoreMin >= 0) return 'uklart eller svagt nej';
    final ratio = score.abs() / scoreMin.abs();
    if (ratio >= 0.60) return 'nej eller meget svagt udfald';
    if (ratio >= 0.30) return 'snarere nej / tydelige hindringer';
    return 'uklart eller svagt nej';
  }

  String _judgementExplanation(
    int score,
    int scoreMin,
    int scoreMax,
    List<WeightedJudgementFactor> factors,
    HoraryChart chart,
  ) {
    final positive = factors.where((f) => f.weight > 0).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    final negative = factors.where((f) => f.weight < 0).toList()
      ..sort((a, b) => a.weight.compareTo(b.weight));

    final strongestSupport = positive.isEmpty ? null : positive.first;
    final strongestObstacle = negative.isEmpty ? null : negative.first;

    final buffer = StringBuffer();

    if (chart.answerMode.isYesNo) {
      final answer = _answerLabel(score, scoreMin, scoreMax);
      buffer.write(
        'Appen lander på $answer, fordi den samlede vægt er $score i det beregnede referenceinterval ${_signed(scoreMin)} til ${_signed(scoreMax)}. ',
      );

      if (strongestSupport != null) {
        buffer.write('Stærkeste ja-faktor er "${strongestSupport.title}" (${strongestSupport.signText}). ');
      }
      if (strongestObstacle != null) {
        buffer.write('Stærkeste nej-/hindringsfaktor er "${strongestObstacle.title}" (${strongestObstacle.signText}). ');
      }

      if (strongestSupport != null && strongestObstacle != null) {
        buffer.write('Læs derfor svaret som en afvejning mellem forbindelse og hindring, ikke som et rent mekanisk facit.');
      } else if (strongestSupport != null) {
        buffer.write('Der er få tunge modargumenter i denne forenklede regelpakke.');
      } else if (strongestObstacle != null) {
        buffer.write('Der mangler stærke ja-faktorer til at opveje hindringerne.');
      } else {
        buffer.write('Der er kun svage eller neutrale faktorer, så kortet bør læses forsigtigt.');
      }
    } else {
      buffer.write('${chart.answerMode.resultHeading}: svaret formuleres ikke som ja/nej. ');
      buffer.write(
        'Den samlede vægt er $score i det beregnede referenceinterval ${_signed(scoreMin)} til ${_signed(scoreMax)} og bruges her som ${_nonYesNoScoreLabel(chart.answerMode, score, scoreMin, scoreMax)}. ',
      );

      if (strongestSupport != null) {
        buffer.write('Stærkeste støttende faktor er "${strongestSupport.title}" (${strongestSupport.signText}). ');
      }
      if (strongestObstacle != null) {
        buffer.write('Stærkeste begrænsende faktor er "${strongestObstacle.title}" (${strongestObstacle.signText}). ');
      }

      if (strongestSupport != null && strongestObstacle != null) {
        buffer.write('Læs derfor svaret som en prioriteret beskrivelse med både støtte og forbehold.');
      } else if (strongestSupport != null) {
        buffer.write('Der er få tunge modsignaler, så beskrivelsen kan læses mere direkte.');
      } else if (strongestObstacle != null) {
        buffer.write('Der er tydelige forbehold, så beskrivelsen bør læses forsigtigt eller som svækket/forsinket.');
      } else {
        buffer.write('Der er kun svage eller neutrale faktorer, så svaret bør formuleres åbent og forsigtigt.');
      }
    }

    buffer.write(' ');
    buffer.write(_modeSpecificGuidance(chart, score, scoreMin, scoreMax));

    return buffer.toString();
  }

  String _nonYesNoScoreLabel(
    HoraryAnswerMode mode,
    int score,
    int scoreMin,
    int scoreMax,
  ) {
    double ratio;
    if (score == 0) {
      ratio = 0.0;
    } else if (score > 0) {
      ratio = scoreMax <= 0 ? 0.0 : score / scoreMax;
    } else {
      ratio = scoreMin >= 0 ? 0.0 : score.abs() / scoreMin.abs();
    }

    final strong = ratio >= 0.60;
    final medium = ratio >= 0.25;

    switch (mode) {
      case HoraryAnswerMode.yesNo:
        return 'ja/nej-tendens';
      case HoraryAnswerMode.where:
        if (score > 0 && strong) return 'et stærkt og forholdsvis tydeligt stedsspor';
        if (score > 0 && medium) return 'et brugbart, men ikke endeligt stedsspor';
        if (score < 0 && strong) return 'et svækket eller forstyrret stedsspor';
        if (score < 0) return 'et usikkert stedsspor med forbehold';
        return 'et blandet eller neutralt stedsspor';
      case HoraryAnswerMode.when:
        if (score > 0 && strong) return 'et tydeligt timinggrundlag';
        if (score > 0 && medium) return 'et moderat timinggrundlag';
        if (score < 0 && strong) return 'svag, forsinket eller blokeret timing';
        if (score < 0) return 'timing med væsentlige forbehold';
        return 'uklar timing';
      case HoraryAnswerMode.howMuch:
        return _amountHeadline(score, scoreMin, scoreMax);
      case HoraryAnswerMode.who:
        if (score > 0 && strong) return 'en stærkere og mere genkendelig personbeskrivelse';
        if (score > 0 && medium) return 'en moderat personbeskrivelse';
        if (score < 0 && strong) return 'en skjult, svækket eller vanskelig aktørbeskrivelse';
        if (score < 0) return 'en personbeskrivelse med forbehold';
        return 'en blandet personbeskrivelse';
      case HoraryAnswerMode.what:
        if (score > 0 && strong) return 'en tydeligere beskrivelse af sagens natur';
        if (score > 0 && medium) return 'en brugbar beskrivelse af sagens natur';
        if (score < 0 && strong) return 'en svækket, skjult eller problematisk sagstype';
        if (score < 0) return 'en sagstype med forbehold';
        return 'en blandet eller åben sagstype';
      case HoraryAnswerMode.how:
        if (score > 0 && strong) return 'en tydelig handlingsvej eller mekanisme';
        if (score > 0 && medium) return 'en mulig handlingsvej';
        if (score < 0 && strong) return 'en blokeret, indirekte eller vanskelig handlingsvej';
        if (score < 0) return 'en handlingsvej med forbehold';
        return 'en uklar handlingsvej';
      case HoraryAnswerMode.why:
        if (score > 0 && strong) return 'en tydelig årsagslinje';
        if (score > 0 && medium) return 'en sandsynlig årsagslinje';
        if (score < 0 && strong) return 'en tung eller blokerende årsagslinje';
        if (score < 0) return 'en årsagslinje med forbehold';
        return 'en blandet eller uklar årsagslinje';
    }
  }

  String _judgementTitle(
    HoraryAnswerMode mode,
    String scoreLabel,
    String scope,
    HoraryChart chart,
    int score,
    int scoreMin,
    int scoreMax,
  ) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    switch (mode) {
      case HoraryAnswerMode.yesNo:
        return 'Vurdering: $scoreLabel$scope.';
      case HoraryAnswerMode.where:
        if (quesited == null) return 'Hvor-svar: se sagens hus og Månen.';
        return 'Hvor-svar: se især ${chart.quesitedRuler} i ${quesited.house}. hus i ${quesited.sign}.';
      case HoraryAnswerMode.when:
        return 'Tids-svar: ${_timingHeadline(chart)}';
      case HoraryAnswerMode.howMuch:
        return 'Mængde-/beløbs-svar: ${_amountHeadline(score, scoreMin, scoreMax)}';
      case HoraryAnswerMode.who:
        if (quesited == null) return 'Hvem-svar: se sagens signifikator og 7. hus.';
        return 'Hvem-svar: personen/aktøren beskrives især af ${chart.quesitedRuler} i ${quesited.sign} og ${quesited.house}. hus.';
      case HoraryAnswerMode.what:
        if (quesited == null) return 'Hvad-svar: se sagens signifikator, hus og Månen.';
        return 'Hvad-svar: sagens natur beskrives især af ${chart.quesitedRuler} i ${quesited.sign} og ${quesited.house}. hus.';
      case HoraryAnswerMode.how:
        return 'Hvordan-svar: se Månen, forbindelsen mellem signifikatorerne og eventuelle mellemplaneter.';
      case HoraryAnswerMode.why:
        return 'Hvorfor-svar: se Månens seneste aspekt, svækkelser og hindringer i kortet.';
    }
  }

  String _modeSpecificGuidance(
    HoraryChart chart,
    int score,
    int scoreMin,
    int scoreMax,
  ) {
    switch (chart.answerMode) {
      case HoraryAnswerMode.yesNo:
        return 'Da spørgsmålet er et ja/nej-spørgsmål, læses scoren direkte som ja/nej-tendens.';
      case HoraryAnswerMode.where:
        return _whereGuidance(chart);
      case HoraryAnswerMode.when:
        return _whenGuidance(chart);
      case HoraryAnswerMode.howMuch:
        return _amountGuidance(chart, score, scoreMin, scoreMax);
      case HoraryAnswerMode.who:
        return _whoGuidance(chart);
      case HoraryAnswerMode.what:
        return _whatGuidance(chart);
      case HoraryAnswerMode.how:
        return _howGuidance(chart);
      case HoraryAnswerMode.why:
        return _whyGuidance(chart);
    }
  }

  String _whereGuidance(HoraryChart chart) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    final hints = chart.specialReading?.hints ?? const <String>[];
    final buffer = StringBuffer();
    if (quesited != null) {
      buffer.write('Hvor-spørgsmålet besvares ikke som ja/nej, men ved at læse sagens signifikator: ${chart.quesitedRuler} i ${quesited.house}. hus i ${quesited.sign}. ');
      buffer.write(_placementHint(quesited.house, quesited.sign));
    } else {
      buffer.write('Hvor-spørgsmålet besvares ved at læse det valgte hus, dets hersker og Månen. ');
    }
    if (hints.isNotEmpty) {
      buffer.write(' Supplerende hints: ${hints.take(3).join(' · ')}');
    }
    if (chart.moonVoidOfCourse) {
      buffer.write(' Void Moon kan betyde, at stedet ikke ændrer sig, eller at der ikke skal ledes langt væk.');
    }
    return buffer.toString();
  }

  String _whenGuidance(HoraryChart chart) {
    final timing = _bestTimingAspect(chart);
    final buffer = StringBuffer();
    if (timing != null && timing.exactInDays != null) {
      buffer.write('Hvornår-spørgsmålet bruger nærmeste relevante kommende perfektion: ${timing.text}. Det giver et råt tidsmål på ${_formatDuration(timing.exactInDays!)}. ');
    } else if (chart.moonVoidOfCourse) {
      buffer.write('Der er ingen tydelig kommende måneperfektion før tegnskifte. Det giver svagt timing-grundlag og kan betyde, at intet væsentligt sker foreløbig. ');
    } else if (chart.moonNextAspect != null) {
      buffer.write('Der mangler direkte perfektion mellem hovedsignifikatorerne, så Månens næste aspekt bruges som næste tidsmarkør: ${chart.moonNextAspect!.text}. ');
    } else {
      buffer.write('Der er ikke fundet en klar timing-markør i denne forenklede regelpakke. ');
    }
    buffer.write(_timingContext(chart));
    return buffer.toString();
  }

  String _amountGuidance(HoraryChart chart, int score, int scoreMin, int scoreMax) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    final condition = chart.conditionFor(chart.quesitedRuler);
    final buffer = StringBuffer();
    buffer.write('Hvor meget/hvor mange læses som skala, ikke som et præcist tal. ${_amountHeadline(score, scoreMin, scoreMax)} ');
    if (quesited != null) {
      buffer.write('Sagens planet ${chart.quesitedRuler} står i ${quesited.house}. hus i ${quesited.sign}; det farver omfanget. ');
    }
    if (condition != null) {
      buffer.write('Styrke ${condition.totalScore} (${condition.summary}) bruges som tegn på om ressourcen/mængden er stærk, svag, skjult eller presset. ');
    }
    if (chart.questionType == HoraryQuestionType.money || chart.questionType == HoraryQuestionType.salaryIncome) {
      buffer.write('Ved penge ses dette sammen med 2. hus: egne penge, betaling og beholdning.');
    } else if (chart.questionType == HoraryQuestionType.loanDebtTax || chart.questionType == HoraryQuestionType.inheritanceInsurance || chart.questionType == HoraryQuestionType.partnerMoney) {
      buffer.write('Ved andres penge, gæld, skat, arv eller forsikring ses dette sammen med 8. hus.');
    }
    return buffer.toString();
  }

  String _whoGuidance(HoraryChart chart) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    final buffer = StringBuffer();
    if (quesited != null) {
      buffer.write('Hvem-spørgsmålet besvares ved at beskrive aktøren bag det valgte hus: ${chart.quesitedHouse}. hus har ${chart.quesitedRuler} som hersker, placeret i ${quesited.house}. hus i ${quesited.sign}. ');
      buffer.write(_personHint(chart.quesitedRuler, quesited.sign, quesited.house));
    } else {
      buffer.write('Hvem-spørgsmålet besvares ved at læse 7. hus/modparten, det relevante hus og Månen.');
    }
    if (chart.significatorAspect != null) {
      buffer.write(' Direkte aspekt til spørgerens signifikator viser kontakt mellem spørger og aktør.');
    }
    return buffer.toString();
  }

  String _whatGuidance(HoraryChart chart) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    final buffer = StringBuffer();
    if (quesited != null) {
      buffer.write('Hvad-spørgsmålet læses som sagens karakter: ${chart.quesitedRuler} i ${quesited.sign}, ${quesited.house}. hus. ${_thingHint(chart.quesitedRuler, quesited.sign)} ');
    }
    if (chart.moonPreviousAspect != null) {
      buffer.write('Månens seneste aspekt viser baggrunden: ${chart.moonPreviousAspect!.text}. ');
    }
    if (chart.moonNextAspect != null) {
      buffer.write('Månens næste aspekt viser hvad sagen bevæger sig mod: ${chart.moonNextAspect!.text}.');
    }
    return buffer.toString();
  }

  String _howGuidance(HoraryChart chart) {
    final buffer = StringBuffer();
    if (chart.translationOfLight != null) {
      buffer.write('Hvordan-svaret peger på mellemvej eller mellemmand: ${chart.translationOfLight!.text}. ');
    } else if (chart.collectionOfLight != null) {
      buffer.write('Hvordan-svaret peger på en samlende tredjepart/ramme: ${chart.collectionOfLight!.text}. ');
    } else if (chart.significatorAspect != null) {
      buffer.write('Hvordan-svaret følger hovedaspektet: ${chart.significatorAspect!.text}. ');
    } else {
      buffer.write('Hvordan-svaret er svagt, fordi der ikke ses en klar forbindelsesmekanisme mellem hovedsignifikatorerne. ');
    }
    if (chart.prohibition != null) buffer.write('Prohibition viser hvad der afbryder processen: ${chart.prohibition!.text}. ');
    if (chart.frustration != null) buffer.write('Frustration viser hvor fokus flyttes: ${chart.frustration!.text}.');
    return buffer.toString();
  }

  String _whyGuidance(HoraryChart chart) {
    final buffer = StringBuffer();
    if (chart.moonPreviousAspect != null) {
      buffer.write('Hvorfor-spørgsmålet starter med Månens seneste aspekt som baggrund/årsag: ${chart.moonPreviousAspect!.text}. ');
    }
    if (chart.prohibition != null) buffer.write('Prohibition peger på en årsag til blokering: ${chart.prohibition!.text}. ');
    if (chart.frustration != null) buffer.write('Frustration peger på, at en part eller sag optages af noget andet: ${chart.frustration!.text}. ');
    if (chart.moonViaCombusta) buffer.write('Månen i via combusta viser uro, pres eller uklarhed som årsagsfelt. ');
    if (buffer.isEmpty) {
      buffer.write('Hvorfor-spørgsmålet læses gennem Månens baggrund, sagens signifikators tilstand og de tungeste negative/positive faktorer i listen.');
    }
    return buffer.toString();
  }

  HoraryAspect? _bestTimingAspect(HoraryChart chart) {
    final candidates = <HoraryAspect?>[
      chart.significatorAspect,
      chart.translationOfLight,
      chart.collectionOfLight,
      chart.moonNextAspect,
    ].whereType<HoraryAspect>()
        .where((a) => a.applying && a.exactInDays != null)
        .toList()
      ..sort((a, b) => a.exactInDays!.compareTo(b.exactInDays!));
    return candidates.isEmpty ? null : candidates.first;
  }

  String _timingHeadline(HoraryChart chart) {
    final timing = _bestTimingAspect(chart);
    if (timing != null && timing.exactInDays != null) {
      return 'nærmeste relevante perfektion peger på cirka ${_formatDuration(timing.exactInDays!)}.';
    }
    if (chart.moonVoidOfCourse) {
      return 'ingen klar timing; Månen er void-of-course.';
    }
    if (chart.moonNextAspect != null) {
      return 'brug Månens næste aspekt som næste udvikling.';
    }
    return 'ingen sikker timing-markør fundet.';
  }

  String _formatDuration(double days) {
    if (days < 0.08) return 'få timer';
    if (days < 1) return '${(days * 24).round()} timer';
    if (days < 2) return '1 dag';
    if (days < 14) return '${days.round()} dage';
    if (days < 70) return '${(days / 7).round()} uger';
    return '${(days / 30).round()} måneder';
  }

  String _timingContext(HoraryChart chart) {
    final quesited = chart.planetByName(chart.quesitedRuler);
    if (quesited == null) {
      return 'Tidsenheden skal altid afstemmes med spørgsmålets realistiske kontekst.';
    }
    final houseSpeed = const {1, 4, 7, 10}.contains(quesited.house)
        ? 'vinkelhus gør ofte sagen mere umiddelbar'
        : const {2, 5, 8, 11}.contains(quesited.house)
            ? 'succedent hus giver ofte middel tempo'
            : 'kadent hus kan trække tiden ud eller gøre sagen fjernere';
    final signSpeed = _signMode(quesited.sign) == 'kardinal'
        ? 'kardinalt tegn peger på hurtigere bevægelse'
        : _signMode(quesited.sign) == 'fast'
            ? 'fast tegn peger på langsommere/stadigere udvikling'
            : 'bevægeligt tegn peger på skiftende eller middel tempo';
    return 'Tidsenheden skal afstemmes med spørgsmålets kontekst; her siger placeringen: $houseSpeed, og $signSpeed.';
  }

  String _amountHeadline(int score, int scoreMin, int scoreMax) {
    if (score == 0) return 'omfanget ser blandet eller usikkert ud.';
    if (score > 0) {
      final ratio = scoreMax <= 0 ? 0.0 : score / scoreMax;
      if (ratio >= 0.60) return 'omfanget ser højt/gunstigt ud i forhold til kortets muligheder.';
      if (ratio >= 0.25) return 'omfanget ser moderat til rimeligt ud.';
      return 'omfanget ser kun svagt gunstigt ud.';
    }
    final ratio = scoreMin >= 0 ? 0.0 : score.abs() / scoreMin.abs();
    if (ratio >= 0.60) return 'omfanget ser lavt, reduceret eller utilstrækkeligt ud.';
    if (ratio >= 0.25) return 'omfanget ser mindre end ønsket eller forsinket ud.';
    return 'omfanget er uklart, men hælder lavt.';
  }

  String _placementHint(int house, String sign) {
    return 'Huset peger på: ${_housePlaceHint(house)} Tegnet peger på: ${_signPlaceHint(sign)}';
  }

  String _housePlaceHint(int house) {
    switch (house) {
      case 1:
        return 'tæt på spørgeren, ved kroppen, i eget rum eller lige foran én.';
      case 2:
        return 'ved ejendele, penge, taske, pung, skabe, beholdere eller ting man ejer.';
      case 3:
        return 'ved papirer, telefon, bil, cykel, naboer, entré, post eller korte ruter.';
      case 4:
        return 'hjemme, lavt nede, ved gulv/kælder, have, jord eller familiens rum.';
      case 5:
        return 'ved børn, hobby, spil, sofa, underholdning, fritidsrum eller kreative ting.';
      case 6:
        return 'ved arbejdsplads, rutiner, redskaber, medicin, dyr, serviceområder eller praktiske rum.';
      case 7:
        return 'hos/ved en anden person, partner, modpart, klient eller et sted overfor dig.';
      case 8:
        return 'skjult, bag lukket låge, ved andres ting, affald, skat/forsikring eller urolige steder.';
      case 9:
        return 'ved bøger, studie, rejseting, udland, religiøse/juridiske papirer eller høje hylder.';
      case 10:
        return 'synligt, højt oppe, på arbejde, ved chef/myndighed, kontor eller offentligt sted.';
      case 11:
        return 'ved venner, grupper, netværk, mødesteder, planer eller fællesrum.';
      case 12:
        return 'skjult, isoleret, bag noget, i roderi, ved seng, hospital/institution eller steder man overser.';
      default:
        return 'det relevante husområde.';
    }
  }

  String _signPlaceHint(String sign) {
    switch (sign) {
      case 'Aries':
        return 'varmt, tørt, hurtigt, nær metal, ild, værktøj eller indgang.';
      case 'Taurus':
        return 'lavt, tungt, stabilt, ved mad, tekstiler, penge, planter eller jord.';
      case 'Gemini':
        return 'ved papir, bøger, telefon, computer, nøgler, transport eller to ens steder.';
      case 'Cancer':
        return 'ved køkken, vand, vask, bad, familiegenstande, bløde eller beskyttede steder.';
      case 'Leo':
        return 'synligt, varmt, ved lys, pynt, børn, underholdning eller noget centralt.';
      case 'Virgo':
        return 'ved orden/rod, skuffer, medicin, arbejde, små beholdere eller sortering.';
      case 'Libra':
        return 'ved pynt, tøj, spejl, kunst, par-genstande, aftaler eller balancerede steder.';
      case 'Scorpio':
        return 'skjult, fugtigt, ved toilet, afløb, affald, mørke hjørner eller lukkede rum.';
      case 'Sagittarius':
        return 'ved rejseting, bøger, sport, udland, høje steder eller store rum.';
      case 'Capricorn':
        return 'lavt, koldt, gammelt, ved sten, gulv, kælder, arbejde eller strukturer.';
      case 'Aquarius':
        return 'ved elektronik, grupper, netværk, vinduer, luftige steder eller noget usædvanligt.';
      case 'Pisces':
        return 'ved vand, sko, seng, stof, medicin, skjulte/bløde steder eller steder med uklarhed.';
      default:
        return 'tegnets element og kvalitet.';
    }
  }

  String _personHint(String planet, String sign, int house) {
    String planetHint;
    switch (planet) {
      case 'Sol':
        planetHint = 'en synlig, central eller autoritativ person';
        break;
      case 'Måne':
        planetHint = 'en omsorgsfuld, skiftende eller følelsesstyret person';
        break;
      case 'Merkur':
        planetHint = 'en kommunikerende, ung, praktisk eller mellemleds-person';
        break;
      case 'Venus':
        planetHint = 'en venlig, social, æstetisk eller relationsorienteret person';
        break;
      case 'Mars':
        planetHint = 'en aktiv, skarp, teknisk, vred eller handlekraftig person';
        break;
      case 'Jupiter':
        planetHint = 'en hjælpsom, juridisk, lærende, rådgivende eller velstillet person';
        break;
      case 'Saturn':
        planetHint = 'en ældre, formel, forsigtig, begrænsende eller ansvarsbærende person';
        break;
      default:
        planetHint = 'en person vist af sagens planet';
        break;
    }
    return '$planetHint; ${_signPersonTone(sign)} Husplaceringen ($house. hus) viser den scene eller rolle personen optræder gennem.';
  }

  String _signPersonTone(String sign) {
    final mode = _signMode(sign);
    final element = _signElement(sign);
    return 'Tegnet er $element og $mode, hvilket farver temperamentet.';
  }

  String _thingHint(String planet, String sign) {
    final element = _signElement(sign);
    final mode = _signMode(sign);
    return 'Planeten viser hovedtemaet, mens $sign ($element, $mode) beskriver stil, materiale, tempo eller miljø.';
  }

  String _signElement(String sign) {
    if (const {'Aries', 'Leo', 'Sagittarius'}.contains(sign)) return 'ild';
    if (const {'Taurus', 'Virgo', 'Capricorn'}.contains(sign)) return 'jord';
    if (const {'Gemini', 'Libra', 'Aquarius'}.contains(sign)) return 'luft';
    if (const {'Cancer', 'Scorpio', 'Pisces'}.contains(sign)) return 'vand';
    return 'ukendt element';
  }

  String _signMode(String sign) {
    if (const {'Aries', 'Cancer', 'Libra', 'Capricorn'}.contains(sign)) return 'kardinal';
    if (const {'Taurus', 'Leo', 'Scorpio', 'Aquarius'}.contains(sign)) return 'fast';
    if (const {'Gemini', 'Virgo', 'Sagittarius', 'Pisces'}.contains(sign)) return 'bevægelig';
    return 'ukendt kvalitet';
  }

  void _addSolarConditionNotes(HoraryChart chart, List<String> notes) {
    final important = <String>{chart.querentRuler, chart.quesitedRuler, 'Måne'};
    for (final name in important) {
      final condition = chart.conditionFor(name);
      if (condition == null) continue;
      if (condition.cazimi) {
        notes.add('$name er cazimi: meget tæt i Solens hjerte. Det kan give usædvanlig styrke eller særlig beskyttelse.');
      } else if (condition.combust) {
        notes.add('$name er forbrændt af Solen: alvorlig accidentel svækkelse, skjulthed eller pres.');
      } else if (condition.underSunBeams) {
        notes.add('$name er under solstråler: svækket eller mindre synlig, men ikke så hårdt ramt som ved forbrænding.');
      }
    }
  }

  int _solarScore(HoraryChart chart, String planetName) {
    final condition = chart.conditionFor(planetName);
    if (condition == null) return 0;
    if (condition.cazimi) return 2;
    if (condition.combust) return -3;
    if (condition.underSunBeams) return -1;
    return 0;
  }

  String _solarFactorTitle(HoraryChart chart, String planetName) {
    final condition = chart.conditionFor(planetName);
    if (condition == null) return planetName;
    if (condition.cazimi) return '$planetName cazimi';
    if (condition.combust) return '$planetName forbrændt';
    if (condition.underSunBeams) return '$planetName under solstråler';
    return planetName;
  }

  String _solarFactorExplanation(HoraryChart chart, String planetName) {
    final condition = chart.conditionFor(planetName);
    if (condition == null) return '';
    if (condition.cazimi) {
      return '$planetName er i Solens hjerte. Det tæller positivt som særlig beskyttelse eller koncentreret kraft.';
    }
    if (condition.combust) {
      return '$planetName er for tæt på Solen og mister synlighed/kraft. Det er en betydelig svækkelse i horar-astrologisk dømmekraft.';
    }
    if (condition.underSunBeams) {
      return '$planetName er under solstråler. Det svækker eller skjuler planeten, men ikke så alvorligt som egentlig forbrænding.';
    }
    return '';
  }

  int _advancedSymbolScore(HoraryChart chart) {
    var score = 0;

    for (final c in chart.antiscionContacts) {
      final importantTarget = <String>{chart.querentRuler, chart.quesitedRuler, 'Måne', 'ASC', 'MC'}.contains(c.target);
      if (importantTarget) score += c.pointType == 'Antiscion' ? 1 : -1;
    }

    for (final c in chart.fixedStarContacts) {
      final importantTarget = <String>{chart.querentRuler, chart.quesitedRuler, 'Måne', 'ASC', 'MC'}.contains(c.target);
      if (!importantTarget) continue;
      if (c.starName == 'Spica' || c.starName == 'Regulus' || c.starName == 'Sirius' || c.starName == 'Fomalhaut') {
        score += 1;
      }
      if (c.starName == 'Algol' || c.starName == 'Antares') {
        score -= 1;
      }
    }

    return score.clamp(-3, 3).toInt();
  }

  int _scoreContribution(int total) {
    if (total >= 8) return 2;
    if (total >= 4) return 1;
    if (total <= -8) return -2;
    if (total <= -4) return -1;
    return 0;
  }

  bool _isInDignityOf(PlanetPosition holder, String otherPlanet) {
    return holder.dignity.ruler == otherPlanet || holder.dignity.exaltation == otherPlanet;
  }
}
