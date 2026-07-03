import '../models/horary_models.dart';

class SpecialQuestionRules {
  const SpecialQuestionRules();

  SpecialQuestionReading? read(HoraryChart chart) {
    final type = chart.questionType;

    if (type == HoraryQuestionType.general) return null;

    if (_isLoveType(type)) return _love(chart);
    if (_isJobType(type)) return _job(chart);
    if (_isMoneyType(type)) return _money(chart);
    if (type == HoraryQuestionType.lostThing) return _lostThing(chart);
    if (_isIllnessType(type)) return _illness(chart);
    if (_isLegalType(type)) return _lawsuit(chart);

    return _houseMatter(chart);
  }

  bool _isLoveType(HoraryQuestionType type) {
    return const {
      HoraryQuestionType.love,
      HoraryQuestionType.marriagePartner,
      HoraryQuestionType.romanceDating,
    }.contains(type);
  }

  bool _isJobType(HoraryQuestionType type) {
    return const {
      HoraryQuestionType.job,
      HoraryQuestionType.promotionCareer,
      HoraryQuestionType.bossAuthority,
      HoraryQuestionType.reputationStatus,
      HoraryQuestionType.businessCompany,
    }.contains(type);
  }

  bool _isMoneyType(HoraryQuestionType type) {
    return const {
      HoraryQuestionType.money,
      HoraryQuestionType.salaryIncome,
      HoraryQuestionType.loanDebtTax,
      HoraryQuestionType.inheritanceInsurance,
      HoraryQuestionType.partnerMoney,
    }.contains(type);
  }

  bool _isIllnessType(HoraryQuestionType type) {
    return const {
      HoraryQuestionType.illnessHealth,
      HoraryQuestionType.treatmentRecovery,
      HoraryQuestionType.acuteIllness,
      HoraryQuestionType.diagnosisSymptoms,
      HoraryQuestionType.medicineTreatment,
    }.contains(type);
  }

  bool _isLegalType(HoraryQuestionType type) {
    return const {
      HoraryQuestionType.opponentLawsuit,
      HoraryQuestionType.courtCase,
      HoraryQuestionType.judgeDecision,
      HoraryQuestionType.lawyerAdvice,
      HoraryQuestionType.lawReligion,
    }.contains(type);
  }

  SpecialQuestionReading _houseMatter(HoraryChart chart) {
    final rules = <String>[
      '${chart.questionType.shortLabel} læses primært fra ${chart.quesitedHouse}. hus: ${_houseTheme(chart.quesitedHouse)}',
    ];
    final hints = <String>[];
    var score = 0;

    _addMainConnection(chart, rules, onScore: (v) => score += v);
    _addObstacles(chart, rules, onScore: (v) => score += v);
    _addReception(chart, rules, onScore: (v) => score += v);

    final querent = chart.planetByName(chart.querentRuler);
    final quesited = chart.planetByName(chart.quesitedRuler);
    final quesitedCondition = chart.conditionFor(chart.quesitedRuler);

    if (quesited != null) {
      rules.add('Sagens signifikator er ${chart.quesitedRuler} i ${quesited.house}. hus i ${quesited.sign}.');
      _addPlacementHints(chart, hints, subject: 'Sagens synlige scene');

      if (quesited.house == 1) {
        rules.add('${chart.quesitedRuler} står i 1. hus: sagen kommer symbolsk mod spørgeren.');
        score += 2;
      }
      if (querent != null && querent.house == chart.quesitedHouse) {
        rules.add('${chart.querentRuler} står i det relevante hus: spørgeren er stærkt orienteret mod sagen.');
        score += 1;
      }
      if (quesited.retrograde) {
        rules.add('${chart.quesitedRuler} er retrograd: sagen kan vende tilbage, gentage sig eller kræve tilbageskridt/revision.');
        score -= 1;
      }
      if (const {1, 4, 7, 10}.contains(quesited.house)) {
        rules.add('Sagens signifikator er i vinkelhus: sagen er synlig, aktiv eller tæt på manifestation.');
        score += 2;
      } else if (const {3, 6, 9, 12}.contains(quesited.house)) {
        rules.add('Sagens signifikator er i kadent hus: sagen er svagere, fjernere, skjult eller mindre handlekraftig.');
        score -= 1;
      }
    }

    if (quesitedCondition != null) {
      if (quesitedCondition.totalScore >= 5) {
        rules.add('${chart.quesitedRuler} er stærk (${quesitedCondition.summary}); det styrker selve sagen.');
        score += 2;
      } else if (quesitedCondition.totalScore <= -5) {
        rules.add('${chart.quesitedRuler} er svækket (${quesitedCondition.summary}); det svækker selve sagen.');
        score -= 2;
      }
      if (quesitedCondition.cazimi) {
        hints.add('Cazimi for sagens signifikator: sagen er tæt på magt/centrum og kan være stærkt beskyttet.');
        score += 2;
      } else if (quesitedCondition.combust) {
        hints.add('Forbrændt sags-signifikator: noget er skjult, presset, overstrålet eller vanskeligt at se klart.');
        score -= 2;
      } else if (quesitedCondition.underSunBeams) {
        hints.add('Under solstråler: sagen er ikke helt synlig endnu, men ikke så hårdt ramt som ved forbrænding.');
        score -= 1;
      }
    }

    final moonNext = chart.moonNextAspect;
    if (moonNext != null && moonNext.involves(chart.quesitedRuler)) {
      rules.add('Månens næste aspekt rammer sagens signifikator: næste udvikling handler direkte om sagen.');
      score += 1;
    }
    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon: der sker ofte mindre end ventet, eller sagen forbliver i sin nuværende tilstand.');
      score -= 2;
    }
    if (chart.moonViaCombusta) {
      hints.add('Månen i via combusta: uro, pres, usikkerhed eller manglende ro omkring spørgsmålet.');
      score -= 1;
    }

    return SpecialQuestionReading(
      title: '${chart.questionType.shortLabel}',
      summary: _summary(
        score,
        positive: 'sagen har gode tegn',
        mixed: 'sagen er mulig, men blandet og afhænger af hindringer/reception',
        negative: 'sagen ser svag, fjern eller blokeret ud',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _love(HoraryChart chart) {
    final rules = <String>[
      'Kærlighed/relation læses primært fra 1. hus og 7. hus.',
      'Månen viser sagens flow; Venus bruges kun som naturlig ekstraindikator for tiltrækning, ikke som erstatning for husenes herskere.',
    ];
    final hints = <String>[];
    var score = 0;

    _addMainConnection(chart, rules, onScore: (v) => score += v);
    _addObstacles(chart, rules, onScore: (v) => score += v);
    _addReception(chart, rules, onScore: (v) => score += v);
    _addPlacementHints(chart, hints, subject: 'Den anden part/relationen');

    final querent = chart.planetByName(chart.querentRuler);
    final quesited = chart.planetByName(chart.quesitedRuler);
    final venus = chart.planetByName('Venus');
    final venusCondition = chart.conditionFor('Venus');

    if (querent != null && querent.house == 7) {
      rules.add('${chart.querentRuler} står i 7. hus: spørgeren er stærkt orienteret mod den anden part.');
      score += 1;
    }
    if (quesited != null && quesited.house == 1) {
      rules.add('${chart.quesitedRuler} står i 1. hus: den anden part kommer symbolsk mod spørgeren.');
      score += 3;
    }

    if (venus != null && venusCondition != null) {
      if (venusCondition.totalScore >= 4) {
        rules.add('Venus er rimeligt stærk (${venusCondition.summary}); det støtter den naturlige relation/tiltrækning.');
        score += 1;
      } else if (venusCondition.totalScore <= -4) {
        rules.add('Venus er svækket (${venusCondition.summary}); det svækker den naturlige relationsindikator.');
        score -= 1;
      }
    }

    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon gør kærlighedsspørgsmålet passivt: ofte sker der mindre, end spørgeren håber.');
      score -= 2;
    }
    if (chart.moonViaCombusta) {
      hints.add('Månen i via combusta kan vise uro, usikkerhed eller følelsesmæssigt pres.');
      score -= 1;
    }

    return SpecialQuestionReading(
      title: 'kærlighed/relation',
      summary: _summary(
        score,
        positive: 'relationen har reelle tegn på forbindelse',
        mixed: 'relationen er blandet og afhænger af reception/hindringer',
        negative: 'relationen ser svag eller blokeret ud',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _job(HoraryChart chart) {
    final rules = <String>[
      'Job/karriere læses primært fra 10. hus. 6. hus kan beskrive dagligt arbejde, vilkår og underordnede opgaver.',
    ];
    final hints = <String>[];
    var score = 0;

    _addMainConnection(chart, rules, onScore: (v) => score += v);
    _addObstacles(chart, rules, onScore: (v) => score += v);
    _addReception(chart, rules, onScore: (v) => score += v);
    _addPlacementHints(chart, hints, subject: 'Jobbet/autoriteten');

    final querent = chart.planetByName(chart.querentRuler);
    final job = chart.planetByName(chart.quesitedRuler);
    final jobCondition = chart.conditionFor(chart.quesitedRuler);

    if (querent != null && querent.house == 10) {
      rules.add('${chart.querentRuler} i 10. hus: spørgeren er tydeligt rettet mod jobbet/karrieren.');
      score += 1;
    }
    if (job != null && job.house == 1) {
      rules.add('${chart.quesitedRuler} i 1. hus: jobbet/arbejdsgiveren kommer mod spørgeren.');
      score += 3;
    }
    if (jobCondition != null) {
      if (jobCondition.totalScore >= 5) {
        rules.add('10.-husets hersker er stærk (${jobCondition.summary}); selve jobbet/positionen står stærkt.');
        score += 2;
      } else if (jobCondition.totalScore <= -5) {
        rules.add('10.-husets hersker er svækket (${jobCondition.summary}); jobbet/positionen kan være svag, uklar eller mindre fordelagtig.');
        score -= 2;
      }
    }

    final moonNext = chart.moonNextAspect;
    if (moonNext != null && moonNext.involves(chart.quesitedRuler)) {
      hints.add('Månens næste aspekt rammer 10.-husets hersker: næste udvikling handler direkte om jobspørgsmålet.');
      score += 1;
    }
    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon svækker jobsagen og kan vise, at der ikke sker et klart skift endnu.');
      score -= 2;
    }

    return SpecialQuestionReading(
      title: 'job/karriere',
      summary: _summary(
        score,
        positive: 'jobsagen har gode tegn',
        mixed: 'jobsagen er mulig, men ikke ren',
        negative: 'jobsagen ser svag eller blokeret ud',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _money(HoraryChart chart) {
    final rules = <String>[
      'Penge læses fra det valgte pengehus: 2. hus for egne penge og 8. hus for andres penge, lån, gæld, arv og forsikring.',
    ];
    final hints = <String>[];
    var score = 0;

    _addMainConnection(chart, rules, onScore: (v) => score += v);
    _addObstacles(chart, rules, onScore: (v) => score += v);
    _addReception(chart, rules, onScore: (v) => score += v);
    _addPlacementHints(chart, hints, subject: 'Pengene/ressourcen');

    final money = chart.planetByName(chart.quesitedRuler);
    final moneyCondition = chart.conditionFor(chart.quesitedRuler);
    final querent = chart.planetByName(chart.querentRuler);

    if (money != null && money.house == 1) {
      rules.add('${chart.quesitedRuler} i 1. hus: pengene/betalingen kommer mod spørgeren.');
      score += 3;
    }
    if (querent != null && querent.house == chart.quesitedHouse) {
      rules.add('${chart.querentRuler} i ${chart.quesitedHouse}. hus: spørgeren er stærkt fokuseret på pengesagen.');
      score += 1;
    }
    if (money != null && money.retrograde) {
      rules.add('${chart.quesitedRuler} er retrograd: penge kan vende tilbage, men ofte efter forsinkelse eller omvej.');
      score += 1;
    }
    if (moneyCondition != null) {
      if (moneyCondition.totalScore >= 5) {
        rules.add('Penge-signifikatoren er stærk (${moneyCondition.summary}); pengesagen har substans.');
        score += 2;
      } else if (moneyCondition.totalScore <= -5) {
        rules.add('Penge-signifikatoren er svækket (${moneyCondition.summary}); pengene kan være svære at få eller mindre end ventet.');
        score -= 2;
      }
      if (moneyCondition.combust) {
        hints.add('Forbrændt penge-signifikator kan vise skjulte tal, uklar betaling eller penge der ikke er synlige endnu.');
        score -= 1;
      }
    }

    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon kan pege på, at betalingen ikke flytter sig i øjeblikket.');
      score -= 2;
    }

    return SpecialQuestionReading(
      title: 'penge/ressourcer',
      summary: _summary(
        score,
        positive: 'pengesagen har gode tegn',
        mixed: 'pengesagen er blandet og kan kræve indsats',
        negative: 'pengesagen ser svag eller forsinket ud',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _lostThing(HoraryChart chart) {
    final rules = <String>[
      'Tabte ting læses normalt fra 2. hus: genstanden er 2.-husets hersker. Månen viser udviklingen i eftersøgningen.',
    ];
    final hints = <String>[];
    var score = 0;

    final item = chart.planetByName(chart.quesitedRuler);
    final itemCondition = chart.conditionFor(chart.quesitedRuler);
    final moonNext = chart.moonNextAspect;

    _addMainConnection(chart, rules, onScore: (v) => score += v);
    _addObstacles(chart, rules, onScore: (v) => score += v);

    if (item != null) {
      rules.add('Genstanden vises af ${chart.quesitedRuler} i ${item.house}. hus i ${item.sign}.');
      _addUnique(hints, _houseHint(item.house));
      _addUnique(hints, _signHint(item.sign));
      _addUnique(hints, _angularityHint(item.house));

      if (item.retrograde) {
        rules.add('${chart.quesitedRuler} er retrograd: genstanden kan vende tilbage eller findes ved at gå tilbage ad egne spor.');
        score += 2;
      }
      if (const {1, 4, 7, 10}.contains(item.house)) {
        rules.add('Genstandens signifikator er i vinkelhus: den er ofte tættere på eller lettere at finde.');
        score += 2;
      } else if (const {3, 6, 9, 12}.contains(item.house)) {
        rules.add('Genstandens signifikator er i kadent hus: den kan være længere væk, skjult eller sværere at få øje på.');
        score -= 1;
      }
      if (itemCondition != null && itemCondition.combust) {
        hints.add('Forbrændt genstands-signifikator: genstanden er skjult, dækket til eller tæt ved noget varmt/lysende/centralt.');
        score -= 2;
      }
    }

    if (moonNext != null && (moonNext.involves(chart.quesitedRuler) || moonNext.involves(chart.querentRuler))) {
      rules.add('Månens næste aspekt forbinder søgningen med spørger/genstand: der er bevægelse i eftersøgningen.');
      score += 2;
    }
    if (chart.translationOfLight != null || chart.collectionOfLight != null) {
      rules.add('Translation/collection kan i tabte ting betyde, at en anden person eller omstændighed hjælper med at finde genstanden.');
      score += 1;
    }
    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon kan betyde, at intet nyt spor kommer lige nu — eller at genstanden ligger, hvor den hele tiden har ligget.');
      score -= 1;
    }

    return SpecialQuestionReading(
      title: 'tabte ting',
      summary: _summary(
        score,
        positive: 'genstanden ser mulig at finde',
        mixed: 'der er spor, men søgningen er ikke helt klar',
        negative: 'genstanden ser skjult eller svær at finde ud',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _illness(HoraryChart chart) {
    final rules = <String>[
      'Sygdomsreglen er astrologisk og ikke medicinsk rådgivning. Ved symptomer, forværring eller tvivl skal læge/behandler kontaktes.',
      'Patienten læses fra 1. hus og ${chart.querentRuler}; sygdommen fra 6. hus; læge/behandler ofte fra 7. hus; behandling/medicin kan ses fra 10. hus.',
    ];
    final hints = <String>[];
    var score = 0;

    final patientRuler = chart.querentRuler;
    final diseaseRuler = _rulerOfHouse(chart, 6);
    final doctorRuler = _rulerOfHouse(chart, 7);
    final treatmentRuler = _rulerOfHouse(chart, 10);

    final patient = chart.planetByName(patientRuler);
    final disease = chart.planetByName(diseaseRuler);
    final doctor = chart.planetByName(doctorRuler);
    final treatment = chart.planetByName(treatmentRuler);
    final moon = chart.planetByName('Måne');

    final patientCondition = chart.conditionFor(patientRuler);
    final diseaseCondition = chart.conditionFor(diseaseRuler);
    final treatmentCondition = chart.conditionFor(treatmentRuler);

    if (patientCondition != null && diseaseCondition != null) {
      final diff = patientCondition.totalScore - diseaseCondition.totalScore;
      rules.add('Styrkeforhold patient/sygdom: $patientRuler ${patientCondition.totalScore} mod $diseaseRuler ${diseaseCondition.totalScore}.');
      if (diff >= 4) {
        rules.add('Patientens signifikator er tydeligt stærkere end sygdommens signifikator; det støtter bedring/modstandskraft astrologisk.');
        score += 3;
      } else if (diff <= -4) {
        rules.add('Sygdommens signifikator er stærkere end patientens; det viser større belastning eller sværere forløb.');
        score -= 3;
      } else {
        rules.add('Patient og sygdom står nogenlunde lige stærkt; udfaldet afhænger mere af Månen, behandling og reception.');
      }
    }

    if (patient != null) {
      rules.add('Patienten: $patientRuler i ${patient.house}. hus i ${patient.sign}.');
      hints.add(_bodyAreaHint(patient.sign));
      if (patient.house == 6) {
        rules.add('$patientRuler i 6. hus: patienten er tydeligt indlejret i sygdoms-/belastningstemaet.');
        score -= 2;
      }
      if (patient.retrograde) {
        rules.add('$patientRuler er retrograd: forløbet kan gå tilbage, gentage sig eller kræve revision af tidligere skridt.');
        score -= 1;
      }
    }

    if (disease != null) {
      rules.add('Sygdommen/tilstanden: $diseaseRuler i ${disease.house}. hus i ${disease.sign}.');
      hints.add(_bodyAreaHint(disease.sign));
      _addPlacementHints(chart, hints, subject: 'Sygdommens/tilstandens scene');
      if (disease.house == 1) {
        rules.add('$diseaseRuler i 1. hus: sygdommen påvirker patienten direkte og er svær at ignorere.');
        score -= 2;
      }
      if (disease.retrograde) {
        rules.add('$diseaseRuler retrograd: tilstanden kan være tilbagevendende, aftagende/tilbagegående eller svær at læse lineært.');
      }
    }

    final patientToDisease = _firstAspect(chart, patientRuler, diseaseRuler);
    if (patientToDisease != null) {
      if (patientToDisease.applying) {
        rules.add('Patientens og sygdommens signifikatorer går mod aspekt: ${patientToDisease.text}. Det kan vise, at sygdomstemaet stadig udvikler sig.');
        score += patientToDisease.aspect == 'trigon' || patientToDisease.aspect == 'sekstil' ? 1 : -2;
      } else {
        rules.add('Patient/sygdom-aspektet er separativt: ${patientToDisease.text}. Det kan vise, at den værste kontakt er bagudrettet.');
        score += 1;
      }
    }

    final patientToTreatment = _firstAspect(chart, patientRuler, treatmentRuler);
    if (patientToTreatment != null && patientToTreatment.applying && patientToTreatment.beforeSignChange) {
      rules.add('Patienten går mod behandling/autoritet: ${patientToTreatment.text}. Det støtter, at hjælp eller behandling kan få betydning.');
      score += 2;
    }
    final moonToTreatment = _firstAspect(chart, 'Måne', treatmentRuler);
    if (moonToTreatment != null && moonToTreatment.applying && moonToTreatment.beforeSignChange) {
      rules.add('Månen går mod behandling/autoritet: ${moonToTreatment.text}. Næste udvikling kan handle om hjælp/behandling.');
      score += 1;
    }

    if (treatmentCondition != null) {
      if (treatmentCondition.totalScore >= 4) {
        rules.add('Behandlingens/autoritetens signifikator er stærk (${treatmentCondition.summary}); det støtter hjælp udefra.');
        score += 1;
      } else if (treatmentCondition.totalScore <= -4) {
        rules.add('Behandlingens/autoritetens signifikator er svag (${treatmentCondition.summary}); behandling/plan kan være uklar eller mindre effektiv.');
        score -= 1;
      }
    }

    if (doctor != null && patient != null) {
      final doctorReceivesPatient = _isInDignityOf(doctor, patientRuler);
      if (doctorReceivesPatient) {
        rules.add('Læge/behandler-signifikatoren modtager patienten: hjælp udefra er astrologisk mere velvillig/relevant.');
        score += 1;
      }
    }

    if (chart.moonVoidOfCourse) {
      rules.add('Void Moon i sygdomsspørgsmål: ofte ingen hurtig ændring; forløbet kan være passivt eller afventende.');
      score -= 1;
    }
    if (chart.moonViaCombusta) {
      rules.add('Månen i via combusta: uro, bekymring og mindre stabil vurdering omkring helbredsspørgsmålet.');
      score -= 1;
    }
    if (moon != null) {
      hints.add('Månen i ${moon.sign}: ${_bodyAreaHint(moon.sign)}');
    }

    for (final star in chart.fixedStarContacts.where((c) => <String>{patientRuler, 'Måne', 'ASC'}.contains(c.target))) {
      if (star.starName == 'Algol' || star.starName == 'Antares') {
        rules.add('Varsom fixstjerne ved patient/Måne/ASC: ${star.text}. Det bør kun læses som astrologisk advarselstema, ikke som diagnose.');
        score -= 1;
      } else if (star.starName == 'Spica' || star.starName == 'Sirius') {
        rules.add('Støttende fixstjerne ved patient/Måne/ASC: ${star.text}.');
        score += 1;
      }
    }

    hints.add('Sygdoms-hint: sammenhold planet, tegn og hus med kroppens område, men brug aldrig dette som erstatning for lægelig vurdering.');

    return SpecialQuestionReading(
      title: 'sygdom/helbred',
      summary: _summary(
        score,
        positive: 'helbredsspørgsmålet har relativt støttende tegn, især hvis behandling/reception bekræfter det',
        mixed: 'helbredsspørgsmålet er blandet og bør læses varsomt sammen med behandling og Måne',
        negative: 'helbredsspørgsmålet ser belastet ud astrologisk; søg praktisk/lægelig afklaring ved tvivl',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  SpecialQuestionReading _lawsuit(HoraryChart chart) {
    final rules = <String>[
      'Retssagsreglen er astrologisk analyse, ikke juridisk rådgivning.',
      'Spørgeren læses fra 1. hus; modparten fra 7. hus; dommer/myndighed fra 10. hus; sagens endelige udgang fra 4. hus.',
    ];
    final hints = <String>[];
    var score = 0;

    final querentRuler = chart.querentRuler;
    final opponentRuler = _rulerOfHouse(chart, 7);
    final judgeRuler = _rulerOfHouse(chart, 10);
    final outcomeRuler = _rulerOfHouse(chart, 4);

    final querent = chart.planetByName(querentRuler);
    final opponent = chart.planetByName(opponentRuler);
    final judge = chart.planetByName(judgeRuler);
    final outcome = chart.planetByName(outcomeRuler);

    final querentCondition = chart.conditionFor(querentRuler);
    final opponentCondition = chart.conditionFor(opponentRuler);
    final judgeCondition = chart.conditionFor(judgeRuler);
    final outcomeCondition = chart.conditionFor(outcomeRuler);

    if (querentCondition != null && opponentCondition != null) {
      final diff = querentCondition.totalScore - opponentCondition.totalScore;
      rules.add('Styrkeforhold parter: $querentRuler ${querentCondition.totalScore} mod $opponentRuler ${opponentCondition.totalScore}.');
      if (diff >= 4) {
        rules.add('Spørgerens signifikator er stærkere end modpartens; det støtter spørgerens position.');
        score += 3;
      } else if (diff <= -4) {
        rules.add('Modpartens signifikator er stærkere end spørgerens; modparten står astrologisk bedre.');
        score -= 3;
      } else {
        rules.add('Parterne står nogenlunde lige stærkt; dommer/reception og udfaldshuset bliver vigtigere.');
      }
    }

    if (judge != null) {
      rules.add('Dommer/myndighed: $judgeRuler i ${judge.house}. hus i ${judge.sign}.');
      if (_isInDignityOf(judge, querentRuler)) {
        rules.add('Dommeren/myndigheden modtager spørgerens signifikator: afgørelsen hælder astrologisk mod spørgeren.');
        score += 3;
      }
      if (_isInDignityOf(judge, opponentRuler)) {
        rules.add('Dommeren/myndigheden modtager modpartens signifikator: afgørelsen hælder astrologisk mod modparten.');
        score -= 3;
      }
    }

    if (judgeCondition != null) {
      if (judgeCondition.totalScore >= 4) {
        rules.add('Dommerens/myndighedens signifikator er stærk (${judgeCondition.summary}); afgørelsen har tydelig kraft.');
      } else if (judgeCondition.totalScore <= -4) {
        rules.add('Dommerens/myndighedens signifikator er svag (${judgeCondition.summary}); processen/afgørelsen kan være uklar, forsinket eller mindre stabil.');
        score -= 1;
      }
    }

    final querentToJudge = _firstAspect(chart, querentRuler, judgeRuler);
    final opponentToJudge = _firstAspect(chart, opponentRuler, judgeRuler);
    if (querentToJudge != null && querentToJudge.applying && querentToJudge.beforeSignChange) {
      rules.add('Spørgeren får forbindelse til dommer/myndighed: ${querentToJudge.text}.');
      score += _aspectScore(querentToJudge) + 1;
    }
    if (opponentToJudge != null && opponentToJudge.applying && opponentToJudge.beforeSignChange) {
      rules.add('Modparten får forbindelse til dommer/myndighed: ${opponentToJudge.text}.');
      final opponentJudgeScore = _aspectScore(opponentToJudge);
      score -= opponentJudgeScore > 0 ? opponentJudgeScore + 1 : 1;
    }

    if (outcome != null) {
      rules.add('Udfald/endelig bund: $outcomeRuler i ${outcome.house}. hus i ${outcome.sign}.');
      _addPlacementHints(chart, hints, subject: 'Retssagens scene/udfald');
      if (_isInDignityOf(outcome, querentRuler)) {
        rules.add('Udfaldets signifikator modtager spørgeren: 4. hus hælder mod spørgerens slutposition.');
        score += 2;
      }
      if (_isInDignityOf(outcome, opponentRuler)) {
        rules.add('Udfaldets signifikator modtager modparten: 4. hus hælder mod modpartens slutposition.');
        score -= 2;
      }
    }

    if (outcomeCondition != null) {
      if (outcomeCondition.totalScore >= 4) {
        hints.add('Udfaldets signifikator er stærk: sagen får en tydelig slutning/fast bund.');
      } else if (outcomeCondition.totalScore <= -4) {
        hints.add('Udfaldets signifikator er svag: slutningen kan blive mindre tilfredsstillende, forsinket eller uklar.');
        score -= 1;
      }
    }

    if (chart.prohibition != null) {
      rules.add('Prohibition i retssag: ${chart.prohibition!.text}. En tredje faktor kan blokere eller ændre forløbet.');
      score -= 2;
    }
    if (chart.frustration != null) {
      rules.add('Frustration i retssag: ${chart.frustration!.text}. Den relevante part/autoritet kan blive optaget af noget andet.');
      score -= 2;
    }
    if (chart.translationOfLight != null || chart.collectionOfLight != null) {
      hints.add('Translation/collection kan i retssager ofte være advokat, mægler, myndighed, dokument eller tredjepart der samler sagen.');
      score += 1;
    }

    if (querent != null && opponent != null) {
      hints.add('Spørger: $querentRuler i ${querent.house}. hus; modpart: $opponentRuler i ${opponent.house}. hus. Sammenlign synlighed, styrke og reception.');
    }
    if (chart.moonVoidOfCourse) {
      hints.add('Void Moon i retssag: ofte intet hurtigt gennembrud; sagen kan stå stille eller ende med mindre ændring end ventet.');
      score -= 1;
    }

    return SpecialQuestionReading(
      title: 'retssag/jura',
      summary: _summary(
        score,
        positive: 'retssagen hælder astrologisk mod spørgeren eller en brugbar afgørelse',
        mixed: 'retssagen er blandet; dommer/reception og tredjeparter bør læses nøje',
        negative: 'retssagen ser svagere ud for spørgeren eller mere belastet af modpart/hindringer',
      ),
      scoreAdjustment: score,
      rules: rules,
      hints: hints,
    );
  }

  void _addMainConnection(
    HoraryChart chart,
    List<String> rules, {
    required void Function(int) onScore,
  }) {
    final aspect = chart.significatorAspect;
    if (aspect != null && aspect.applying && aspect.beforeSignChange) {
      rules.add('Hovedsignifikatorerne perfekterer: ${aspect.text}.');
      onScore(_aspectScore(aspect) + 3);
    } else if (aspect != null && aspect.applying) {
      rules.add('Hovedsignifikatorerne mødes først efter tegnskifte: ${aspect.text}. Det viser mulighed, men først efter ændrede forhold.');
      onScore(1);
    } else if (aspect != null) {
      rules.add('Hovedsignifikatorernes aspekt er separativt: ${aspect.text}. Det beskriver mere fortid end fremtid.');
      onScore(-1);
    } else {
      rules.add('Der er ingen direkte perfektion mellem hovedsignifikatorerne i denne beregning.');
      onScore(-2);
    }

    if (chart.translationOfLight != null) {
      rules.add('Translation hjælper specialspørgsmålet: ${chart.translationOfLight!.text}.');
      onScore(2);
    }
    if (chart.collectionOfLight != null) {
      rules.add('Collection hjælper specialspørgsmålet: ${chart.collectionOfLight!.text}.');
      onScore(1);
    }
  }

  void _addObstacles(
    HoraryChart chart,
    List<String> rules, {
    required void Function(int) onScore,
  }) {
    if (chart.prohibition != null) {
      rules.add('Prohibition rammer specialspørgsmålet: ${chart.prohibition!.text}.');
      onScore(-4);
    }
    if (chart.frustration != null) {
      rules.add('Frustration rammer specialspørgsmålet: ${chart.frustration!.text}.');
      onScore(-3);
    }
  }

  void _addReception(
    HoraryChart chart,
    List<String> rules, {
    required void Function(int) onScore,
  }) {
    final querent = chart.planetByName(chart.querentRuler);
    final quesited = chart.planetByName(chart.quesitedRuler);
    if (querent == null || quesited == null) return;

    final querentReceives = _isInDignityOf(querent, chart.quesitedRuler);
    final quesitedReceives = _isInDignityOf(quesited, chart.querentRuler);

    if (querentReceives) {
      rules.add('${chart.querentRuler} modtager ${chart.quesitedRuler}: spørgeren vil sagen/personen.');
      onScore(1);
    }
    if (quesitedReceives) {
      rules.add('${chart.quesitedRuler} modtager ${chart.querentRuler}: sagen/personen er positivt orienteret mod spørgeren.');
      onScore(2);
    }
    if (querentReceives && quesitedReceives) {
      rules.add('Gensidig reception: begge parter/signifikatorer hjælper hinanden.');
      onScore(2);
    }
    if (!querentReceives && !quesitedReceives) {
      rules.add('Ingen tydelig reception i herskerskab/eksaltation mellem hovedsignifikatorerne.');
      onScore(-1);
    }
  }

  void _addPlacementHints(
    HoraryChart chart,
    List<String> hints, {
    required String subject,
  }) {
    final p = chart.planetByName(chart.quesitedRuler);
    if (p == null) return;

    _addUnique(hints, '$subject vises ved ${chart.quesitedRuler} i ${p.house}. hus og ${p.sign}.');
    _addUnique(hints, _houseHint(p.house));
    _addUnique(hints, _signHint(p.sign));
    _addUnique(hints, _angularityHint(p.house));
  }

  void _addUnique(List<String> values, String value) {
    if (value.trim().isEmpty) return;
    if (!values.contains(value)) values.add(value);
  }

  int _aspectScore(HoraryAspect aspect) {
    switch (aspect.aspect) {
      case 'trigon':
      case 'sekstil':
        return 2;
      case 'konjunktion':
        return 1;
      case 'kvadrat':
        return -1;
      case 'opposition':
        return -2;
      default:
        return 0;
    }
  }

  bool _isInDignityOf(PlanetPosition holder, String otherPlanet) {
    return holder.dignity.ruler == otherPlanet || holder.dignity.exaltation == otherPlanet;
  }

  static const Map<String, String> _traditionalRulers = {
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

  String _rulerOfHouse(HoraryChart chart, int house) {
    final h = chart.house(house);
    if (h == null) return '-';
    return _traditionalRulers[h.sign] ?? '-';
  }

  HoraryAspect? _firstAspect(HoraryChart chart, String a, String b) {
    if (a == '-' || b == '-' || a == b) return null;
    final direct = chart.significatorAspect;
    if (direct != null && direct.involvesBoth(a, b)) return direct;
    return chart.futureAspects.where((x) => x.involvesBoth(a, b)).firstOrNull;
  }

  String _bodyAreaHint(String sign) {
    switch (sign) {
      case 'Aries':
        return 'Kropshint Vædder: hoved, ansigt, øjne, feber/akut varme.';
      case 'Taurus':
        return 'Kropshint Tyr: hals, nakke, stemme, mandler, stofskifteområde.';
      case 'Gemini':
        return 'Kropshint Tvilling: arme, hænder, skuldre, lunger, nerver/kommunikation.';
      case 'Cancer':
        return 'Kropshint Krebs: mave, bryst, væsker, fordøjelse og næring.';
      case 'Leo':
        return 'Kropshint Løve: hjerte, ryg, rygsøjle, vitalitet og varme.';
      case 'Virgo':
        return 'Kropshint Jomfru: tarme, fordøjelse, rutiner, kost og små ubalancer.';
      case 'Libra':
        return 'Kropshint Vægt: nyrer, lænd, sukker-/væskebalance og parvise organer.';
      case 'Scorpio':
        return 'Kropshint Skorpion: urinveje, kønsorganer, udskillelse, infektion/skjult proces.';
      case 'Sagittarius':
        return 'Kropshint Skytte: hofter, lår, lever, blod og overdrivelse/udvidelse.';
      case 'Capricorn':
        return 'Kropshint Stenbuk: knæ, knogler, hud, tænder, kronisk/koldt/tørt tema.';
      case 'Aquarius':
        return 'Kropshint Vandbærer: ankler, kredsløb, nerver, kramper/uregelmæssighed.';
      case 'Pisces':
        return 'Kropshint Fisk: fødder, lymfe, medicin, forgiftning/overfølsomhed og diffuse symptomer.';
      default:
        return 'Kropshint kunne ikke bestemmes sikkert.';
    }
  }

  String _summary(
    int score, {
    required String positive,
    required String mixed,
    required String negative,
  }) {
    if (score >= 5) return 'Specialregel: $positive.';
    if (score >= 1) return 'Specialregel: $mixed.';
    return 'Specialregel: $negative.';
  }

  String _houseTheme(int house) {
    switch (house) {
      case 1:
        return 'spørgeren selv, krop, identitet, fremtoning og egen handlekraft.';
      case 2:
        return 'egne penge, ejendele, værdier og tabte genstande.';
      case 3:
        return 'beskeder, søskende, naboer, korte ture, dokumenter og daglig kommunikation.';
      case 4:
        return 'hjem, bolig, jord, familie, rødder og sagens afslutning.';
      case 5:
        return 'børn, forelskelse, dating, kreativitet, fornøjelse og hobby.';
      case 6:
        return 'sygdom, daglige pligter, rutinearbejde, ansatte og små dyr.';
      case 7:
        return 'partner, modpart, kontrakt, køb/salg, klient og den anden person.';
      case 8:
        return 'andres penge, lån, gæld, skat, arv, forsikring, krise og tab.';
      case 9:
        return 'udland, lange rejser, højere uddannelse, lov, religion og udgivelse.';
      case 10:
        return 'job, karriere, chef, myndighed, status, omdømme og offentlig position.';
      case 11:
        return 'venner, grupper, netværk, støtte, planer, håb og ønsker.';
      case 12:
        return 'skjulte fjender, hemmeligheder, isolation, hospitaler, selvsabotage og store dyr.';
      default:
        return 'det valgte emne.';
    }
  }

  String _houseHint(int house) {
    switch (house) {
      case 1:
        return '1. hus-hint: tæt på spørgeren, ved kroppen, tasken, entréen eller noget der bruges personligt.';
      case 2:
        return '2. hus-hint: blandt ejendele, penge, skabe, skuffer, madvarer eller ting med praktisk værdi.';
      case 3:
        return '3. hus-hint: ved papir, bøger, telefon, bil, cykel, post, søskende/naboer eller korte ture.';
      case 4:
        return '4. hus-hint: hjemme, lavt nede, ved gulv, kælder, have, jord eller familiens rum.';
      case 5:
        return '5. hus-hint: ved hobby, børn, spil, sofa, fritidsrum eller noget behageligt/fornøjeligt.';
      case 6:
        return '6. hus-hint: ved arbejde, værktøj, rengøring, medicin, husdyr eller daglige rutiner.';
      case 7:
        return '7. hus-hint: hos/ved en anden person, partner, gæst, kunde eller et sted overfor indgangen.';
      case 8:
        return '8. hus-hint: skjult, i lukkede rum, nær affald, forsikring/papirer, andres ting eller svært tilgængelige steder.';
      case 9:
        return '9. hus-hint: ved rejseting, bøger, undervisning, udland, religiøse/juridiske papirer eller højt placerede hylder.';
      case 10:
        return '10. hus-hint: synligt, højt oppe, ved arbejdsbord, autoritet, offentligt rum eller noget professionelt.';
      case 11:
        return '11. hus-hint: hos venner, grupper, foreninger, netværk, teknologi eller steder man håber/planlægger noget.';
      case 12:
        return '12. hus-hint: meget skjult, bagved, under noget, i soveværelse, isoleret rum, hospital/lukket sted eller blandt rod.';
      default:
        return 'Husplaceringen kunne ikke tolkes sikkert.';
    }
  }

  String _signHint(String sign) {
    switch (sign) {
      case 'Aries':
        return 'Vædder/ild-hint: varmt, tørt, aktivt, ved redskaber, metal, maskiner, sport eller noget hurtigt.';
      case 'Taurus':
        return 'Tyr/jord-hint: lavt, stabilt, ved mad, penge, tekstiler, komfort, have eller tunge/praktiske ting.';
      case 'Gemini':
        return 'Tvilling/luft-hint: ved telefon, computer, papirer, bøger, beskeder, transport eller to ens steder/ting.';
      case 'Cancer':
        return 'Krebs/vand-hint: hjemme, i køkken, bad, nær væske, beholdere, familie-ting eller bløde steder.';
      case 'Leo':
        return 'Løve/ild-hint: synligt, varmt, lyst, ved pynt, børn, fornøjelse, scene, stue eller noget værdigt/centralt.';
      case 'Virgo':
        return 'Jomfru/jord-hint: ved papirer, orden/rod, hylder, beholdere, sundhedsting, værktøj eller praktisk arbejde.';
      case 'Libra':
        return 'Vægt/luft-hint: ved partner/andre, smukke ting, spejl, tøj, skrivebord, aftaler eller steder med balance/par.';
      case 'Scorpio':
        return 'Skorpion/vand-hint: skjult, mørkt, fugtigt, ved affald, toilet, kælder, låste steder eller noget intenst/privat.';
      case 'Sagittarius':
        return 'Skytte/ild-hint: højt, langt væk, ved rejseting, bøger, undervisning, sport, udland eller åbne rum.';
      case 'Capricorn':
        return 'Stenbuk/jord-hint: lavt, koldt, gammelt, ved sten, vægge, arbejde, struktur, kælder eller autoritets-/kontorting.';
      case 'Aquarius':
        return 'Vandbærer/luft-hint: ved elektronik, netværk, grupper, usædvanlige steder, vinduer, hylder eller noget teknisk.';
      case 'Pisces':
        return 'Fisk/vand-hint: nær vand, sko/fødder, seng, medicin, musik, skjulte rum, bløde tekstiler eller uoverskueligt rod.';
      default:
        return 'Tegnet giver ikke et sikkert sted- eller scene-hint.';
    }
  }

  String _angularityHint(int house) {
    if (const {1, 4, 7, 10}.contains(house)) {
      return 'Vinkelhus: emnet er mere synligt, tættere på, aktivt eller lettere at få fat i.';
    }
    if (const {2, 5, 8, 11}.contains(house)) {
      return 'Succedent hus: emnet er stabilt eller fastholdt; det kan kræve vedholdenhed, men er ikke helt væk.';
    }
    if (const {3, 6, 9, 12}.contains(house)) {
      return 'Kadent hus: emnet kan være fjernere, svagere, skjult, spredt eller afhængigt af omveje.';
    }
    return '';
  }
}
