class LocationChoice {
  final String name;
  final double latitude;
  final double longitude;

  const LocationChoice(this.name, this.latitude, this.longitude);
}



enum HoraryQuestionType {
  general,

  // 1. hus
  selfIdentity,
  bodyAppearance,
  personalDecision,

  // 2. hus
  money,
  salaryIncome,
  possessions,
  lostThing,

  // 3. hus
  messageContact,
  siblingsNeighbors,
  shortTrip,
  documentsLetters,

  // 4. hus
  homeProperty,
  movingHome,
  familyParent,
  endingsOutcome,

  // 5. hus
  childrenPregnancy,
  romanceDating,
  creativeProject,
  funHobby,

  // 6. hus
  illnessHealth,
  treatmentRecovery,
  acuteIllness,
  diagnosisSymptoms,
  medicineTreatment,
  dailyWork,
  petsSmallAnimals,

  // 7. hus
  love,
  marriagePartner,
  contractDeal,
  opponentLawsuit,
  courtCase,
  judgeDecision,
  lawyerAdvice,
  clientConsultation,

  // 8. hus
  loanDebtTax,
  inheritanceInsurance,
  partnerMoney,
  fearCrisis,

  // 9. hus
  abroadTravel,
  higherEducation,
  examStudy,
  lawReligion,
  publishingMedia,

  // 10. hus
  job,
  promotionCareer,
  bossAuthority,
  reputationStatus,
  businessCompany,
  championshipTitle,

  // 11. hus
  friendsGroups,
  hopesPlans,
  patronSupport,
  communityNetwork,

  // 12. hus
  hiddenEnemy,
  secretsUnknown,
  isolationHospital,
  selfUndoing,
  largeAnimals,
}

class _QuestionTypeData {
  final String label;
  final String shortLabel;
  final int defaultHouse;
  final String ruleHint;

  const _QuestionTypeData({
    required this.label,
    required this.shortLabel,
    required this.defaultHouse,
    required this.ruleHint,
  });
}

const Map<HoraryQuestionType, _QuestionTypeData> _questionTypeData = {
  HoraryQuestionType.general: _QuestionTypeData(
    label: 'Generelt / vælg hus selv',
    shortLabel: 'Generelt',
    defaultHouse: 7,
    ruleHint: 'Vælg selv det hus, der bedst beskriver sagen.',
  ),

  // 1. hus
  HoraryQuestionType.selfIdentity: _QuestionTypeData(
    label: '1. hus – mig selv / min situation',
    shortLabel: 'Mig selv',
    defaultHouse: 1,
    ruleHint: '1. hus beskriver spørgeren, kroppen, identiteten og den direkte handlekraft.',
  ),
  HoraryQuestionType.bodyAppearance: _QuestionTypeData(
    label: '1. hus – krop, udseende, personlig fremtoning',
    shortLabel: 'Krop/udseende',
    defaultHouse: 1,
    ruleHint: 'Brug 1. hus for krop, udseende, vitalitet og hvordan spørgeren fremstår.',
  ),
  HoraryQuestionType.personalDecision: _QuestionTypeData(
    label: '1. hus – personlig beslutning / skal jeg gøre det?',
    shortLabel: 'Beslutning',
    defaultHouse: 1,
    ruleHint: 'Spørgerens hersker og Månen viser om spørgeren selv kan eller bør handle.',
  ),

  // 2. hus
  HoraryQuestionType.money: _QuestionTypeData(
    label: '2. hus – egne penge / betaling',
    shortLabel: 'Penge',
    defaultHouse: 2,
    ruleHint: '2. hus er egne penge, betaling, indkomst og ting med praktisk værdi.',
  ),
  HoraryQuestionType.salaryIncome: _QuestionTypeData(
    label: '2. hus – løn / indtægt / honorar',
    shortLabel: 'Løn/indtægt',
    defaultHouse: 2,
    ruleHint: 'Løn og honorar ses fra 2. hus; job/arbejdsgiver kan samtidig ses fra 10. hus.',
  ),
  HoraryQuestionType.possessions: _QuestionTypeData(
    label: '2. hus – ejendele / værdier',
    shortLabel: 'Ejendele',
    defaultHouse: 2,
    ruleHint: '2. hus beskriver ting man ejer, værdier, udstyr og beholdninger.',
  ),
  HoraryQuestionType.lostThing: _QuestionTypeData(
    label: '2. hus – tabt ting / forsvunden genstand',
    shortLabel: 'Tabte ting',
    defaultHouse: 2,
    ruleHint: 'Tabte ting læses oftest fra 2. hus og får sted-hints fra genstandens planet, hus og tegn.',
  ),

  // 3. hus
  HoraryQuestionType.messageContact: _QuestionTypeData(
    label: '3. hus – besked, opkald, kontakt',
    shortLabel: 'Besked/kontakt',
    defaultHouse: 3,
    ruleHint: '3. hus bruges til beskeder, opkald, mail, kommunikation og korte kontakter.',
  ),
  HoraryQuestionType.siblingsNeighbors: _QuestionTypeData(
    label: '3. hus – søskende, naboer, nærmiljø',
    shortLabel: 'Søskende/naboer',
    defaultHouse: 3,
    ruleHint: '3. hus beskriver søskende, naboer, nærmiljø og daglig kommunikation.',
  ),
  HoraryQuestionType.shortTrip: _QuestionTypeData(
    label: '3. hus – kort rejse / transport',
    shortLabel: 'Kort rejse',
    defaultHouse: 3,
    ruleHint: 'Korte ture, lokal transport, bil/cykel/tog i nærområdet hører typisk til 3. hus.',
  ),
  HoraryQuestionType.documentsLetters: _QuestionTypeData(
    label: '3. hus – dokument, brev, papir, aftaletekst',
    shortLabel: 'Dokumenter',
    defaultHouse: 3,
    ruleHint: '3. hus kan bruges til breve, dokumenter, papirarbejde, beskeder og aftaletekst.',
  ),

  // 4. hus
  HoraryQuestionType.homeProperty: _QuestionTypeData(
    label: '4. hus – bolig, hus, grund, ejendom',
    shortLabel: 'Bolig/ejendom',
    defaultHouse: 4,
    ruleHint: '4. hus er hjemmet, fast ejendom, jord, rødder og det fysiske sted.',
  ),
  HoraryQuestionType.movingHome: _QuestionTypeData(
    label: '4. hus – flytning / nyt hjem',
    shortLabel: 'Flytning',
    defaultHouse: 4,
    ruleHint: 'Flytning vurderes fra 4. hus for hjemmet; 7. kan inddrages ved køb/lejeaftale.',
  ),
  HoraryQuestionType.familyParent: _QuestionTypeData(
    label: '4. hus – familie / forælder / privatliv',
    shortLabel: 'Familie/forælder',
    defaultHouse: 4,
    ruleHint: '4. hus bruges til hjem, familie, rødder og ofte én af forældrene afhængigt af tradition/metode.',
  ),
  HoraryQuestionType.endingsOutcome: _QuestionTypeData(
    label: '4. hus – sagens afslutning / endelig udgang',
    shortLabel: 'Afslutning',
    defaultHouse: 4,
    ruleHint: '4. hus kan vise sagens bund, slutning og hvor det hele lander.',
  ),

  // 5. hus
  HoraryQuestionType.childrenPregnancy: _QuestionTypeData(
    label: '5. hus – børn / graviditet',
    shortLabel: 'Børn/graviditet',
    defaultHouse: 5,
    ruleHint: '5. hus beskriver børn, graviditet, glæde, leg og skabende frugtbarhed.',
  ),
  HoraryQuestionType.romanceDating: _QuestionTypeData(
    label: '5. hus – flirt / dating / fornøjelse',
    shortLabel: 'Flirt/dating',
    defaultHouse: 5,
    ruleHint: '5. hus beskriver forelskelse, flirt, fornøjelse og romantik uden nødvendigvis fast relation.',
  ),
  HoraryQuestionType.creativeProject: _QuestionTypeData(
    label: '5. hus – kreativt projekt',
    shortLabel: 'Kreativt projekt',
    defaultHouse: 5,
    ruleHint: '5. hus bruges til kreative projekter, skaberglæde, optræden og personlige frembringelser.',
  ),
  HoraryQuestionType.funHobby: _QuestionTypeData(
    label: '5. hus – hobby, spil, fornøjelse',
    shortLabel: 'Hobby/spil',
    defaultHouse: 5,
    ruleHint: '5. hus er hobby, spil, fornøjelse, fritid og det man gør for glædens skyld.',
  ),

  // 6. hus
  HoraryQuestionType.illnessHealth: _QuestionTypeData(
    label: '6. hus – sygdom / helbred',
    shortLabel: 'Sygdom/helbred',
    defaultHouse: 6,
    ruleHint: '6. hus beskriver sygdom, svækkelse, pligter og daglige belastninger. Appens svar er ikke medicinsk rådgivning.',
  ),
  HoraryQuestionType.treatmentRecovery: _QuestionTypeData(
    label: '6. hus – behandling / bedring',
    shortLabel: 'Behandling/bedring',
    defaultHouse: 6,
    ruleHint: '6. hus viser sygdommen/tilstanden; 10. hus kan inddrages for lægen/behandleren i nogle metoder.',
  ),
  HoraryQuestionType.acuteIllness: _QuestionTypeData(
    label: '6. hus – akut sygdom / pludselig forværring',
    shortLabel: 'Akut sygdom',
    defaultHouse: 6,
    ruleHint: 'Akut sygdom vurderes fra patienten, sygdommens styrke og om Månen/signifikatorer bevæger sig ud af eller ind i affliktion. Ikke medicinsk rådgivning.',
  ),
  HoraryQuestionType.diagnosisSymptoms: _QuestionTypeData(
    label: '6. hus – symptomer / hvad fejler jeg?',
    shortLabel: 'Symptomer',
    defaultHouse: 6,
    ruleHint: 'Symptomer læses varsomt fra 1., 6. og planetens tegn/kropsområde. Appen kan kun give astrologiske hints, ikke diagnose.',
  ),
  HoraryQuestionType.medicineTreatment: _QuestionTypeData(
    label: '6./10. hus – medicin, behandling, lægevalg',
    shortLabel: 'Medicin/behandling',
    defaultHouse: 6,
    ruleHint: 'Sygdommen ses fra 6. hus; læge/behandler og behandling vurderes supplerende fra 7./10. hus afhængigt af spørgsmålets formulering.',
  ),
  HoraryQuestionType.dailyWork: _QuestionTypeData(
    label: '6. hus – dagligt arbejde / opgaver',
    shortLabel: 'Dagligt arbejde',
    defaultHouse: 6,
    ruleHint: '6. hus er daglige opgaver, rutinearbejde, tjeneste, ansatte og praktiske pligter.',
  ),
  HoraryQuestionType.petsSmallAnimals: _QuestionTypeData(
    label: '6. hus – kæledyr / små dyr',
    shortLabel: 'Kæledyr',
    defaultHouse: 6,
    ruleHint: '6. hus bruges traditionelt til små dyr og kæledyr.',
  ),

  // 7. hus
  HoraryQuestionType.love: _QuestionTypeData(
    label: '7. hus – kærlighed / fast relation',
    shortLabel: 'Kærlighed',
    defaultHouse: 7,
    ruleHint: 'Bruger især 1./7. hus, Månen og Venus som naturlig ekstraindikator.',
  ),
  HoraryQuestionType.marriagePartner: _QuestionTypeData(
    label: '7. hus – ægtefælle / partner',
    shortLabel: 'Partner',
    defaultHouse: 7,
    ruleHint: '7. hus beskriver den anden part i en fast relation, ægteskab eller partnerskab.',
  ),
  HoraryQuestionType.contractDeal: _QuestionTypeData(
    label: '7. hus – kontrakt, handel, aftale',
    shortLabel: 'Kontrakt/aftale',
    defaultHouse: 7,
    ruleHint: '7. hus bruges til aftaler, kontrakter, køb/salg og den anden part i en handel.',
  ),
  HoraryQuestionType.opponentLawsuit: _QuestionTypeData(
    label: '7. hus – modpart / åben fjende / retssag',
    shortLabel: 'Modpart',
    defaultHouse: 7,
    ruleHint: '7. hus viser åben modpart, konkurrent, modstander og den anden side i en konflikt.',
  ),
  HoraryQuestionType.courtCase: _QuestionTypeData(
    label: '7./10. hus – retssag / konflikt i retten',
    shortLabel: 'Retssag',
    defaultHouse: 7,
    ruleHint: 'Retssager vurderes med 1. hus for spørger, 7. hus for modpart, 10. hus for dommer/autoritet og 4. hus for endeligt udfald.',
  ),
  HoraryQuestionType.judgeDecision: _QuestionTypeData(
    label: '10. hus – dommer / myndighedens afgørelse',
    shortLabel: 'Dommer/afgørelse',
    defaultHouse: 10,
    ruleHint: '10. hus viser dommer, myndighed og den afgørende autoritet; reception til parterne viser ofte hvem afgørelsen favoriserer.',
  ),
  HoraryQuestionType.lawyerAdvice: _QuestionTypeData(
    label: '9. hus – advokat / juridisk rådgivning',
    shortLabel: 'Advokat/råd',
    defaultHouse: 9,
    ruleHint: '9. hus bruges til lov, jura, rådgivning, advokater og den juridiske forståelse af sagen.',
  ),
  HoraryQuestionType.clientConsultation: _QuestionTypeData(
    label: '7. hus – klient / kunde / konsultation',
    shortLabel: 'Klient/kunde',
    defaultHouse: 7,
    ruleHint: '7. hus kan vise klient, kunde og den person man står direkte overfor.',
  ),

  // 8. hus
  HoraryQuestionType.loanDebtTax: _QuestionTypeData(
    label: '8. hus – lån, gæld, skat, erstatning',
    shortLabel: 'Lån/gæld/skat',
    defaultHouse: 8,
    ruleHint: '8. hus beskriver andres penge, lån, gæld, skat, erstatning, risiko og tab.',
  ),
  HoraryQuestionType.inheritanceInsurance: _QuestionTypeData(
    label: '8. hus – arv, forsikring, fælles midler',
    shortLabel: 'Arv/forsikring',
    defaultHouse: 8,
    ruleHint: '8. hus bruges til arv, forsikring, fælles midler, dødsbo og penge der kommer via andre.',
  ),
  HoraryQuestionType.partnerMoney: _QuestionTypeData(
    label: '8. hus – partnerens / andres penge',
    shortLabel: 'Andres penge',
    defaultHouse: 8,
    ruleHint: '8. hus er 2. fra 7. hus: den anden parts penge og ressourcer.',
  ),
  HoraryQuestionType.fearCrisis: _QuestionTypeData(
    label: '8. hus – frygt, krise, tab',
    shortLabel: 'Frygt/krise',
    defaultHouse: 8,
    ruleHint: '8. hus kan vise angst, krise, tab, dødssymbolik og det der føles truende.',
  ),

  // 9. hus
  HoraryQuestionType.abroadTravel: _QuestionTypeData(
    label: '9. hus – udland / lang rejse',
    shortLabel: 'Udland/rejse',
    defaultHouse: 9,
    ruleHint: '9. hus bruges til lange rejser, udland, fjerne steder og fremmede kulturer.',
  ),
  HoraryQuestionType.higherEducation: _QuestionTypeData(
    label: '9. hus – uddannelse / studie',
    shortLabel: 'Uddannelse',
    defaultHouse: 9,
    ruleHint: '9. hus beskriver højere uddannelse, læring, studieforløb og akademiske spørgsmål.',
  ),
  HoraryQuestionType.examStudy: _QuestionTypeData(
    label: '9. hus – eksamen / prøve',
    shortLabel: 'Eksamen',
    defaultHouse: 9,
    ruleHint: 'Eksamen kan ses fra 9. hus; 10. hus kan vise dommen/resultatet fra autoriteten.',
  ),
  HoraryQuestionType.lawReligion: _QuestionTypeData(
    label: '9. hus – lov, religion, livssyn',
    shortLabel: 'Lov/religion',
    defaultHouse: 9,
    ruleHint: '9. hus dækker lov, højere principper, religion, filosofi og livssyn.',
  ),
  HoraryQuestionType.publishingMedia: _QuestionTypeData(
    label: '9. hus – udgivelse / medie / kursus',
    shortLabel: 'Udgivelse/medie',
    defaultHouse: 9,
    ruleHint: '9. hus bruges til udgivelse, undervisning, kurser, formidling og større medieprojekter.',
  ),

  // 10. hus
  HoraryQuestionType.job: _QuestionTypeData(
    label: '10. hus – job / karriere',
    shortLabel: 'Job',
    defaultHouse: 10,
    ruleHint: 'Bruger især 10. hus for job/karriere; 6. hus kan beskrive dagligt arbejde.',
  ),
  HoraryQuestionType.promotionCareer: _QuestionTypeData(
    label: '10. hus – forfremmelse / karrierespring',
    shortLabel: 'Forfremmelse',
    defaultHouse: 10,
    ruleHint: '10. hus viser status, karriere, stilling, forfremmelse og offentlig position.',
  ),
  HoraryQuestionType.bossAuthority: _QuestionTypeData(
    label: '10. hus – chef / myndighed / dommer',
    shortLabel: 'Chef/myndighed',
    defaultHouse: 10,
    ruleHint: '10. hus beskriver chef, myndighed, dommer, autoritet og det der afgør sagen oppefra.',
  ),
  HoraryQuestionType.reputationStatus: _QuestionTypeData(
    label: '10. hus – ry, status, offentligt omdømme',
    shortLabel: 'Ry/status',
    defaultHouse: 10,
    ruleHint: '10. hus viser ry, status, offentlig synlighed og hvordan sagen står i verden.',
  ),
  HoraryQuestionType.businessCompany: _QuestionTypeData(
    label: '10. hus – firma / projektets succes',
    shortLabel: 'Firma/succes',
    defaultHouse: 10,
    ruleHint: '10. hus kan bruges til firmaets retning, succes, ledelse og den synlige position.',
  ),
  HoraryQuestionType.championshipTitle: _QuestionTypeData(
    label: '10. hus – mesterskab / titel / offentlig sejr',
    shortLabel: 'Mesterskab/sejr',
    defaultHouse: 10,
    ruleHint: '10. hus bruges til titlen, sejren, mesterskabet, pokalen og offentlig hæder. Ved konkret duel kan 1./7. hus vise parterne.',
  ),

  // 11. hus
  HoraryQuestionType.friendsGroups: _QuestionTypeData(
    label: '11. hus – venner / gruppe / forening',
    shortLabel: 'Venner/grupper',
    defaultHouse: 11,
    ruleHint: '11. hus beskriver venner, grupper, foreninger, netværk og fællesskaber.',
  ),
  HoraryQuestionType.hopesPlans: _QuestionTypeData(
    label: '11. hus – håb, plan, ønske',
    shortLabel: 'Håb/planer',
    defaultHouse: 11,
    ruleHint: '11. hus er håb, planer, ønsker, støtte og det man sigter mod.',
  ),
  HoraryQuestionType.patronSupport: _QuestionTypeData(
    label: '11. hus – støtte, sponsor, hjælper',
    shortLabel: 'Støtte/hjælper',
    defaultHouse: 11,
    ruleHint: '11. hus viser støtte, hjælpere, sponsorer, velyndere og dem der kan åbne døre.',
  ),
  HoraryQuestionType.communityNetwork: _QuestionTypeData(
    label: '11. hus – netværk / online fællesskab',
    shortLabel: 'Netværk',
    defaultHouse: 11,
    ruleHint: '11. hus kan bruges til netværk, fællesskaber, klubber og grupper online/offline.',
  ),

  // 12. hus
  HoraryQuestionType.hiddenEnemy: _QuestionTypeData(
    label: '12. hus – skjult fjende / skjult modstand',
    shortLabel: 'Skjult fjende',
    defaultHouse: 12,
    ruleHint: '12. hus viser skjulte fjender, skjult modstand, isolation og det der arbejder bag kulissen.',
  ),
  HoraryQuestionType.secretsUnknown: _QuestionTypeData(
    label: '12. hus – hemmelighed / det ukendte',
    shortLabel: 'Hemmelighed',
    defaultHouse: 12,
    ruleHint: '12. hus bruges til hemmeligheder, skjulte forhold, det ubevidste og det der ikke ses klart.',
  ),
  HoraryQuestionType.isolationHospital: _QuestionTypeData(
    label: '12. hus – isolation, hospital, lukket sted',
    shortLabel: 'Isolation/hospital',
    defaultHouse: 12,
    ruleHint: '12. hus beskriver isolation, hospital, institution, fangenskab og steder adskilt fra hverdagen.',
  ),
  HoraryQuestionType.selfUndoing: _QuestionTypeData(
    label: '12. hus – selvsabotage / skjult mønster',
    shortLabel: 'Selvsabotage',
    defaultHouse: 12,
    ruleHint: '12. hus viser det der undergraver spørgeren indefra eller sker skjult for bevidstheden.',
  ),
  HoraryQuestionType.largeAnimals: _QuestionTypeData(
    label: '12. hus – store dyr',
    shortLabel: 'Store dyr',
    defaultHouse: 12,
    ruleHint: '12. hus bruges traditionelt til store dyr.',
  ),
};

extension HoraryQuestionTypeInfo on HoraryQuestionType {
  _QuestionTypeData get _data => _questionTypeData[this]!;

  String get label => _data.label;
  String get shortLabel => _data.shortLabel;
  int get defaultHouse => _data.defaultHouse;
  String get ruleHint => _data.ruleHint;
}



enum HoraryAnswerMode {
  yesNo,
  where,
  when,
  howMuch,
  who,
  what,
  how,
  why,
}

extension HoraryAnswerModeInfo on HoraryAnswerMode {
  String get label {
    switch (this) {
      case HoraryAnswerMode.yesNo:
        return 'Ja/nej';
      case HoraryAnswerMode.where:
        return 'Hvor';
      case HoraryAnswerMode.when:
        return 'Hvornår';
      case HoraryAnswerMode.howMuch:
        return 'Hvor meget/hvor mange';
      case HoraryAnswerMode.who:
        return 'Hvem';
      case HoraryAnswerMode.what:
        return 'Hvad';
      case HoraryAnswerMode.how:
        return 'Hvordan';
      case HoraryAnswerMode.why:
        return 'Hvorfor';
    }
  }

  bool get isYesNo => this == HoraryAnswerMode.yesNo;

  String get resultHeading {
    switch (this) {
      case HoraryAnswerMode.yesNo:
        return 'Ja/nej-vurdering';
      case HoraryAnswerMode.where:
        return 'Hvor-svar';
      case HoraryAnswerMode.when:
        return 'Tids-svar';
      case HoraryAnswerMode.howMuch:
        return 'Mængde-/beløbs-svar';
      case HoraryAnswerMode.who:
        return 'Hvem-svar';
      case HoraryAnswerMode.what:
        return 'Hvad-svar';
      case HoraryAnswerMode.how:
        return 'Hvordan-svar';
      case HoraryAnswerMode.why:
        return 'Hvorfor-svar';
    }
  }
}

HoraryAnswerMode detectHoraryAnswerMode(String rawQuestion) {
  final q = rawQuestion
      .toLowerCase()
      .replaceAll(RegExp(r'[\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool startsOrContains(List<String> terms) {
    for (final t in terms) {
      if (q.startsWith(t) || q.contains(' $t')) return true;
    }
    return false;
  }

  if (startsOrContains([
    'hvor meget',
    'hvor mange',
    'hvilket beløb',
    'hvilket belob',
    'hvor stor',
    'hvor stort',
    'hvad koster',
    'hvad bliver prisen',
  ])) {
    return HoraryAnswerMode.howMuch;
  }

  if (startsOrContains([
    'hvornår',
    'hvornar',
    'hvilken dag',
    'hvilken måned',
    'hvilken maned',
    'hvilket tidspunkt',
    'hvor længe',
    'hvor laenge',
    'når sker',
    'naar sker',
    'hvad tid',
    'hvor hurtigt',
    'hvor lang tid',
    'om hvor længe',
    'om hvor laenge',
  ])) {
    return HoraryAnswerMode.when;
  }

  if (startsOrContains([
    'hvor er',
    'hvor ligger',
    'hvor finder',
    'hvor kan',
    'hvor skal jeg lede',
    'hvor befinder',
    'hvilket sted',
    'hvorhen',
    'hvor henne',
    'i hvilket rum',
    'på hvilket sted',
    'pa hvilket sted',
  ])) {
    return HoraryAnswerMode.where;
  }

  if (startsOrContains(['hvem ', 'hvem er', 'hvem har', 'hvem kan', 'hvem vil', 'hvem skal', 'hvem gjorde', 'hvem gør', 'hvem gor'])) {
    return HoraryAnswerMode.who;
  }

  if (startsOrContains(['hvorfor', 'hvorfor sker', 'hvorfor vil', 'hvorfor gør', 'hvorfor gor'])) {
    return HoraryAnswerMode.why;
  }

  if (startsOrContains(['hvordan', 'hvordan kan', 'hvordan sker', 'hvordan får', 'hvordan far'])) {
    return HoraryAnswerMode.how;
  }

  if (startsOrContains(['hvad ', 'hvad er', 'hvad betyder', 'hvad sker', 'hvad skal'])) {
    return HoraryAnswerMode.what;
  }

  return HoraryAnswerMode.yesNo;
}

class PlanetPosition {
  final String name;
  final String symbol;
  final int sweId;
  final double longitude;
  final double speed;
  final String sign;
  final int degree;
  final int minute;
  final int house;
  final bool retrograde;
  final EssentialDignity dignity;

  const PlanetPosition({
    required this.name,
    required this.symbol,
    required this.sweId,
    required this.longitude,
    required this.speed,
    required this.sign,
    required this.degree,
    required this.minute,
    required this.house,
    required this.retrograde,
    required this.dignity,
  });

  // Vigtigt: ingen Unicode-planetsymboler her.
  // Android/iOS kan vise især Venus og Mars som farvede emoji-symboler,
  // mens Linux ofte viser dem sort. Planet-symboler tegnes derfor ens
  // med PlanetGlyph-widgetten i UI'et.
  String get positionText =>
      '${shortSign(sign)} ${degree.toString().padLeft(2, '0')}°${minute.toString().padLeft(2, '0')}\'${retrograde ? ' R' : ''}';
}

class HousePosition {
  final int number;
  final double longitude;
  final String sign;
  final int degree;
  final int minute;

  const HousePosition({
    required this.number,
    required this.longitude,
    required this.sign,
    required this.degree,
    required this.minute,
  });

  String get positionText =>
      '${shortSign(sign)} ${degree.toString().padLeft(2, '0')}°${minute.toString().padLeft(2, '0')}\'';
}

class EssentialDignity {
  final String ruler;
  final String exaltation;
  final String detriment;
  final String fall;

  const EssentialDignity({
    required this.ruler,
    required this.exaltation,
    required this.detriment,
    required this.fall,
  });
}

class PlanetCondition {
  final int essentialScore;
  final int accidentalScore;
  final bool cazimi;
  final bool combust;
  final bool underSunBeams;
  final bool angular;
  final bool succedent;
  final bool cadent;
  final List<String> labels;

  const PlanetCondition({
    required this.essentialScore,
    required this.accidentalScore,
    required this.cazimi,
    required this.combust,
    required this.underSunBeams,
    required this.angular,
    required this.succedent,
    required this.cadent,
    required this.labels,
  });

  int get totalScore => essentialScore + accidentalScore;

  String get summary {
    if (labels.isEmpty) return 'neutral';
    return labels.join(', ');
  }
}

class HoraryAspect {
  final String from;
  final String to;
  final String aspect;
  final double angle;
  final double orb;
  final bool applying;

  /// Approximate days until exact perfection. Null means only a current/separating
  /// aspect was detected, not a calculated future perfection.
  final double? exactInDays;

  /// True when the aspect perfects before one of the two planets leaves its sign.
  final bool beforeSignChange;

  /// Short technical explanation used by the rule engine.
  final String? ruleNote;

  const HoraryAspect({
    required this.from,
    required this.to,
    required this.aspect,
    required this.angle,
    required this.orb,
    required this.applying,
    this.exactInDays,
    this.beforeSignChange = true,
    this.ruleNote,
  });

  bool involves(String planetName) => from == planetName || to == planetName;

  bool involvesBoth(String a, String b) {
    return (from == a && to == b) || (from == b && to == a);
  }

  String otherThan(String planetName) {
    if (from == planetName) return to;
    if (to == planetName) return from;
    return '';
  }

  String get daysText {
    if (exactInDays == null) return '';
    final d = exactInDays!;
    if (d < 0.1) return ', næsten eksakt';
    if (d < 1) return ', eksakt om ${(d * 24).toStringAsFixed(1)} timer';
    return ', eksakt om ${d.toStringAsFixed(1)} dage';
  }

  String get text {
    final direction = applying ? 'applikativ' : 'separativ';
    final signText = beforeSignChange ? '' : ', efter tegnskifte';
    final noteText = ruleNote == null || ruleNote!.isEmpty ? '' : ' — $ruleNote';
    return '$from $aspect $to, orb ${orb.toStringAsFixed(1)}°, $direction$daysText$signText$noteText';
  }
}


class AntiscionContact {
  final String pointType; // Antiscion eller contra-antiscion
  final String sourcePlanet;
  final String target;
  final double shadowLongitude;
  final double orb;

  const AntiscionContact({
    required this.pointType,
    required this.sourcePlanet,
    required this.target,
    required this.shadowLongitude,
    required this.orb,
  });

  String get text {
    final split = _splitAnyLongitude(shadowLongitude);
    return "$pointType for $sourcePlanet ligger ved ${shortSign(split.sign)} ${split.degree.toString().padLeft(2, '0')}°${split.minute.toString().padLeft(2, '0')}' og rammer $target med orb ${orb.toStringAsFixed(1)}°";
  }
}

class FixedStarContact {
  final String starName;
  final double starLongitude;
  final String target;
  final double orb;
  final String nature;
  final String meaning;

  const FixedStarContact({
    required this.starName,
    required this.starLongitude,
    required this.target,
    required this.orb,
    required this.nature,
    required this.meaning,
  });

  String get text {
    final split = _splitAnyLongitude(starLongitude);
    return "$target på $starName (${shortSign(split.sign)} ${split.degree.toString().padLeft(2, '0')}°${split.minute.toString().padLeft(2, '0')}'), orb ${orb.toStringAsFixed(1)}° – $meaning";
  }
}

({String sign, int degree, int minute}) _splitAnyLongitude(double longitude) {
  const signs = [
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
  var norm = longitude % 360.0;
  if (norm < 0) norm += 360.0;
  final signIndex = (norm / 30).floor().clamp(0, 11);
  final signDegree = norm - signIndex * 30;
  final degree = signDegree.floor();
  final minute = ((signDegree - degree) * 60).floor();
  return (sign: signs[signIndex], degree: degree, minute: minute);
}

class SpecialQuestionReading {
  final String title;
  final String summary;
  final int scoreAdjustment;
  final List<String> rules;
  final List<String> hints;

  const SpecialQuestionReading({
    required this.title,
    required this.summary,
    required this.scoreAdjustment,
    required this.rules,
    required this.hints,
  });
}

class WeightedJudgementFactor {
  final String category;
  final String title;
  final int weight;
  final String explanation;

  const WeightedJudgementFactor({
    required this.category,
    required this.title,
    required this.weight,
    required this.explanation,
  });

  String get signText => weight > 0 ? '+$weight' : weight.toString();

  String get direction {
    if (weight > 0) return 'Støttende faktor';
    if (weight < 0) return 'Hindrende/svækkende faktor';
    return 'Neutral';
  }
}

class HoraryChart {
  final String question;
  final DateTime localTime;
  final LocationChoice location;
  final HoraryQuestionType questionType;
  final HoraryAnswerMode answerMode;
  final int quesitedHouse;
  final String? derivedHouseExplanation;
  final List<PlanetPosition> planets;
  final List<HousePosition> houses;
  final String querentRuler;
  final String quesitedRuler;
  final HoraryAspect? moonPreviousAspect;
  final HoraryAspect? moonNextAspect;
  final HoraryAspect? significatorAspect;
  final List<HoraryAspect> futureAspects;
  final Map<String, PlanetCondition> conditions;
  final bool moonVoidOfCourse;
  final bool moonViaCombusta;
  final HoraryAspect? prohibition;
  final HoraryAspect? frustration;
  final HoraryAspect? translationOfLight;
  final HoraryAspect? collectionOfLight;
  final List<AntiscionContact> antiscionContacts;
  final List<FixedStarContact> fixedStarContacts;
  final SpecialQuestionReading? specialReading;
  final String judgement;
  final String judgementExplanation;
  final int finalScore;
  final int scoreMin;
  final int scoreMax;
  final List<WeightedJudgementFactor> weightedFactors;
  final List<String> notes;

  const HoraryChart({
    required this.question,
    required this.localTime,
    required this.location,
    required this.questionType,
    required this.answerMode,
    required this.quesitedHouse,
    this.derivedHouseExplanation,
    required this.planets,
    required this.houses,
    required this.querentRuler,
    required this.quesitedRuler,
    required this.moonPreviousAspect,
    required this.moonNextAspect,
    required this.significatorAspect,
    required this.futureAspects,
    required this.conditions,
    required this.moonVoidOfCourse,
    required this.moonViaCombusta,
    required this.prohibition,
    required this.frustration,
    required this.translationOfLight,
    required this.collectionOfLight,
    required this.antiscionContacts,
    required this.fixedStarContacts,
    required this.specialReading,
    required this.judgement,
    required this.judgementExplanation,
    required this.finalScore,
    required this.scoreMin,
    required this.scoreMax,
    required this.weightedFactors,
    required this.notes,
  });

  PlanetPosition? planetByName(String name) {
    for (final p in planets) {
      if (p.name == name) return p;
    }
    return null;
  }

  HousePosition? house(int number) {
    for (final h in houses) {
      if (h.number == number) return h;
    }
    return null;
  }

  PlanetCondition? conditionFor(String planetName) => conditions[planetName];
}

String shortSign(String sign) {
  switch (sign) {
    case 'Aries':
      return 'Ari';
    case 'Taurus':
      return 'Tau';
    case 'Gemini':
      return 'Gem';
    case 'Cancer':
      return 'Can';
    case 'Leo':
      return 'Leo';
    case 'Virgo':
      return 'Vir';
    case 'Libra':
      return 'Lib';
    case 'Scorpio':
      return 'Sco';
    case 'Sagittarius':
      return 'Sag';
    case 'Capricorn':
      return 'Cap';
    case 'Aquarius':
      return 'Aqu';
    case 'Pisces':
      return 'Pis';
    default:
      return sign;
  }
}
