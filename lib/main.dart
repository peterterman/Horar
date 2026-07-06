import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'sweph_loader/web_helper.dart' if (dart.library.ffi) 'sweph_loader/io_helper.dart';

import 'models/horary_models.dart';
import 'services/astro_calculator.dart';
import 'services/question_validator.dart';
import 'services/horar_ai_service.dart';
import 'services/study_journal_service.dart';
import 'services/horar_export_service.dart';
import 'widgets/zodiac_wheel.dart';
import 'widgets/planet_glyph.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HorarBootstrapApp());
}

class HorarBootstrapApp extends StatefulWidget {
  const HorarBootstrapApp({super.key});

  @override
  State<HorarBootstrapApp> createState() => _HorarBootstrapAppState();
}

class _HorarBootstrapAppState extends State<HorarBootstrapApp> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSwissEph();
  }

  Future<void> _loadSwissEph() {
    // Vigtigt: runApp er allerede kaldt. Derfor får vi en synlig startskærm
    // i stedet for en blank Android Activity, hvis Swiss Ephemeris fejler/hænger.
    return initSweph(const [
      'packages/sweph/assets/ephe/sepl_18.se1',
      'packages/sweph/assets/ephe/semo_18.se1',
      'packages/sweph/assets/ephe/seas_18.se1',
      'packages/sweph/assets/ephe/seleapsec.txt',
    ]).timeout(const Duration(seconds: 30));
  }

  void _retry() {
    setState(() {
      _future = _loadSwissEph();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Horar',
            theme: AppTheme.theme,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Indlæser Swiss Ephemeris...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Horar',
            theme: AppTheme.theme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Horar')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Swiss Ephemeris kunne ikke indlæses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Det er derfor appen tidligere kunne vise blank skærm før Flutter UI nåede at starte.',
                    ),
                    const SizedBox(height: 12),
                    SelectableText('${snapshot.error}'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Prøv igen'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const HorarApp();
      },
    );
  }
}

class HorarApp extends StatelessWidget {
  const HorarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Horar',
      theme: AppTheme.theme,
      home: HoraryQuestionScreen(calculator: AstroCalculator()),
    );
  }
}


const String kHorarAppVersion = '1.0';
const String kHorarDeveloperName = 'Peter Terman Hansen';

class HorarMainDrawer extends StatelessWidget {
  const HorarMainDrawer({super.key});

  void _openHouseSystemScreen(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HouseSystemScreen()),
    );
  }

  void _openStudyJournal(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudyJournalScreen()),
    );
  }

  void _openLearnHorary(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LearnHoraryScreen()),
    );
  }

  void _openSourcesAndMethod(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SourcesAndMethodScreen()),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).pop();
    showAboutDialog(
      context: context,
      applicationName: 'Horar',
      applicationVersion: 'Version $kHorarAppVersion',
      applicationIcon: const Icon(Icons.auto_awesome, size: 42),
      children: const [
        SizedBox(height: 12),
        Text('Udvikler: $kHorarDeveloperName.'),
        SizedBox(height: 12),
        Text(
          'Horar beregner et horar-astrologisk kort ud fra spørgsmålets tidspunkt og spørgerens placering.',
        ),
        SizedBox(height: 12),
        Text(
          'Reference: John Frawley: The Horary Textbook.',
        ),
        SizedBox(height: 12),
        Text(
          'Hussystem: Regiomontanus.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.brown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.auto_awesome, color: AppColors.white, size: 42),
                  SizedBox(height: 10),
                  Text(
                    'Horar',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Menu',
                    style: TextStyle(color: Color(0xddffffff)),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Studie-journal'),
              subtitle: const Text('Gemte spørgsmål og AI-svar'),
              onTap: () => _openStudyJournal(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Lær horar-astrologi'),
              subtitle: const Text('Forklaring af regler og eksempler'),
              onTap: () => _openLearnHorary(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Kilder og metode'),
              subtitle: const Text('Datagrundlag, regler og AI-afgrænsning'),
              onTap: () => _openSourcesAndMethod(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Hussystem'),
              subtitle: const Text('Regiomontanus valgt som standard'),
              onTap: () => _openHouseSystemScreen(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Om'),
              subtitle: const Text('Version og reference'),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

class HoraryQuestionScreen extends StatefulWidget {
  final AstroCalculator calculator;

  const HoraryQuestionScreen({super.key, required this.calculator});

  @override
  State<HoraryQuestionScreen> createState() => _HoraryQuestionScreenState();
}

class _HoraryQuestionScreenState extends State<HoraryQuestionScreen> {
  final _questionController = TextEditingController();
  final _questionValidator = const QuestionValidator();
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  static const _baseLocations = <LocationChoice>[
    LocationChoice('Rørvig', 55.9300, 11.7500),
    LocationChoice('København', 55.6761, 12.5683),
    LocationChoice('Aarhus', 56.1629, 10.2039),
    LocationChoice('Odense', 55.4038, 10.4024),
    LocationChoice('Aalborg', 57.0488, 9.9217),
    LocationChoice('Esbjerg', 55.4765, 8.4594),
  ];

  late List<LocationChoice> _locations;
  HoraryQuestionType _questionType = HoraryQuestionType.general;
  int _house = HoraryQuestionType.general.defaultHouse;
  late LocationChoice _location;
  bool _busy = false;
  bool _hasQuestionText = false;
  bool _autoUseQuestionSuggestion = true;
  QuestionValidationResult? _validationResult;
  bool _locationBusy = false;
  String? _locationStatus;
  bool _manualTime = false;
  bool _aiHouseBusy = false;
  String? _aiHouseStatus;
  HorarAiHouseSuggestionResult? _aiHouseSuggestionResult;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hourController = TextEditingController(text: now.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: now.minute.toString().padLeft(2, '0'));
    _locations = List<LocationChoice>.from(_baseLocations);
    _location = _locations.first;
    _validationResult = _questionValidator.validate(_questionController.text);
    _questionController.addListener(_questionChanged);
    _setCurrentLocationAsDefault();
  }

  @override
  void dispose() {
    _questionController.removeListener(_questionChanged);
    _questionController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _questionChanged() {
    final result = _questionValidator.validate(_questionController.text);
    final suggestion = result.bestSuggestion;

    setState(() {
      _validationResult = result;
      _hasQuestionText = result.question.isNotEmpty;
      _aiHouseStatus = null;
      _aiHouseSuggestionResult = null;

      // Indtil brugeren selv ændrer dropdowns, følger appen bedste husforslag
      // ud fra spørgsmålets tekst.
      if (_autoUseQuestionSuggestion && result.isValid && suggestion != null) {
        _questionType = suggestion.questionType;
        _house = suggestion.house;
      }
    });
  }

  void _applyHouseSuggestion(HouseSuggestion suggestion) {
    setState(() {
      _autoUseQuestionSuggestion = true;
      _questionType = suggestion.questionType;
      _house = suggestion.house;
    });
  }

  HouseSuggestion? _activeAiHouseSuggestion() {
    final ai = _aiHouseSuggestionResult;
    if (ai == null || !ai.ok || ai.house == null || ai.questionType == null) {
      return null;
    }

    final reasonParts = <String>[];
    if (ai.reason.trim().isNotEmpty) reasonParts.add(ai.reason.trim());
    if ((ai.derivedHouseExplanation ?? '').trim().isNotEmpty) {
      reasonParts.add(ai.derivedHouseExplanation!.trim());
    }
    final confidence = (ai.confidence ?? '').trim();
    if (confidence.isNotEmpty) reasonParts.add('AI-sikkerhed: $confidence.');

    return HouseSuggestion(
      house: ai.house!,
      questionType: ai.questionType!,
      score: 999,
      reason: reasonParts.isEmpty
          ? 'AI foreslog dette hus ud fra spørgsmålets formulering.'
          : reasonParts.join(' '),
      isDerived: (ai.derivedHouseExplanation ?? '').trim().isNotEmpty,
    );
  }

  HouseSuggestion? _activeHouseSuggestion([HouseSuggestion? explicitSuggestion]) {
    if (explicitSuggestion != null) return explicitSuggestion;

    // Når AI er spurgt og har returneret et brugbart hus, er det AI-forslaget
    // der forklares af knapperne “Hvorfor dette hus?” og
    // “Hvorfor valgte appen dette hus?”. Ellers bruges de lokale husforslag.
    final aiSuggestion = _activeAiHouseSuggestion();
    if (aiSuggestion != null) return aiSuggestion;

    final suggestions = _validationResult?.suggestions ?? const <HouseSuggestion>[];
    for (final suggestion in suggestions) {
      if (suggestion.house == _house && suggestion.questionType == _questionType) {
        return suggestion;
      }
    }
    for (final suggestion in suggestions) {
      if (suggestion.house == _house) return suggestion;
    }
    return suggestions.isNotEmpty ? suggestions.first : null;
  }

  void _showHouseChoiceExplanation([HouseSuggestion? explicitSuggestion]) {
    final suggestion = _activeHouseSuggestion(explicitSuggestion);
    final question = _questionController.text.trim();
    final selectedHouse = suggestion?.house ?? _house;
    final selectedType = suggestion?.questionType ?? _questionType;
    final isDerived = suggestion?.isDerived ?? false;

    final paragraphs = <Widget>[
      Text(
        question.isEmpty
            ? 'Appen forklarer husvalget, når der er skrevet et konkret spørgsmål.'
            : 'Spørgsmål: “$question”',
      ),
      const SizedBox(height: 12),
      Text(
        '$selectedHouse. hus – ${selectedType.shortLabel}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      if (suggestion?.score == 999) ...const [
        SizedBox(height: 4),
        Text('Kilde: AI-husforslag', style: TextStyle(color: AppColors.mutedText)),
      ],
      const SizedBox(height: 8),
    ];

    if (suggestion != null) {
      paragraphs.addAll([
        Text('Tekstregel: ${suggestion.reason}'),
        const SizedBox(height: 8),
        Text('Husregel: ${suggestion.questionType.ruleHint}'),
      ]);
      if (isDerived) {
        paragraphs.addAll(const [
          SizedBox(height: 8),
          Text(
            'Afledt hus: appen fandt først den person eller relation, spørgsmålet handler om, og talte derefter videre derfra. Det bruges fx ved partnerens penge, barnets job eller konens ejendel.',
          ),
        ]);
      }
    } else {
      paragraphs.addAll([
        Text(
          'Dette hus er valgt manuelt. Appen har derfor ikke en sikker tekstregel bag valget endnu.',
        ),
        const SizedBox(height: 8),
        Text('Husregel: ${selectedType.ruleHint}'),
      ]);
    }

    if (_aiHouseStatus != null && _aiHouseStatus!.trim().isNotEmpty) {
      paragraphs.addAll([
        const SizedBox(height: 8),
        Text('AI-husforslag: $_aiHouseStatus'),
      ]);
    }

    paragraphs.addAll(const [
      SizedBox(height: 12),
      Text(
        'Undervisningsmodus: denne forklaring er ikke selve tydningen. Den viser kun hvorfor dette hus blev valgt som sagens hovedhus, før signifikatorer, aspekter og reception vurderes.',
        style: TextStyle(color: AppColors.mutedText),
      ),
    ]);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hvorfor valgte appen dette hus?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraphs,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Luk'),
          ),
        ],
      ),
    );
  }

  Future<void> _askAiForHouseSuggestion() async {
    final question = _questionController.text.trim();
    final validation = _questionValidator.validate(question);

    if (question.isEmpty || !validation.hasEnoughText) {
      setState(() {
        _validationResult = validation;
        _aiHouseStatus = 'Skriv først et helt spørgsmål, før AI foreslår hus.';
      });
      return;
    }

    setState(() {
      _validationResult = validation;
      _aiHouseBusy = true;
      _aiHouseStatus = 'AI vurderer bedste hus...';
      _aiHouseSuggestionResult = null;
    });

    try {
      final result = await const HorarAiService().suggestHouse(
        question: question,
        localSuggestions: validation.suggestions.map((s) => {
              'house': s.house,
              'question_type': s.questionType.toString().split('.').last,
              'label': s.questionType.label,
              'short_label': s.questionType.shortLabel,
              'reason': s.reason,
              'is_derived': s.isDerived,
            }).toList(),
      );

      if (!mounted) return;

      if (result.ok && result.house != null && result.questionType != null) {
        setState(() {
          _autoUseQuestionSuggestion = true;
          _questionType = result.questionType!;
          _house = result.house!;
          _aiHouseSuggestionResult = result;
          _aiHouseStatus = 'AI foreslår ${result.house}. hus – ${result.questionType!.shortLabel}. ${result.reason}';
        });
      } else {
        setState(() {
          _aiHouseSuggestionResult = null;
          _aiHouseStatus = result.error ?? 'AI kunne ikke foreslå hus.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _aiHouseBusy = false);
      }
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Lokationstjenester er slået fra');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Lokationstilladelse blev afvist');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Lokationstilladelse er permanent afvist');
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  Future<void> _setCurrentLocationAsDefault() async {
    if (_locationBusy) return;
    setState(() {
      _locationBusy = true;
      _locationStatus = 'Finder aktuel lokation...';
    });

    try {
      final pos = await _determinePosition();
      if (!mounted) return;

      final currentLocation = LocationChoice(
        'Aktuel lokation',
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _locations = [currentLocation, ..._baseLocations];
        _location = currentLocation;
        _locationBusy = false;
        _locationStatus =
            'Aktuel lokation valgt: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationBusy = false;
        _locationStatus = 'Aktuel lokation kunne ikke hentes. Bruger ${_location.name}.';
      });
    }
  }

  Future<void> _calculate() async {
    final question = _questionController.text.trim();
    final validation = _questionValidator.validate(question);
    if (!validation.isValid) {
      setState(() => _validationResult = validation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.verdict)),
      );
      return;
    }

    final now = DateTime.now();
    final DateTime localTime;

    if (_manualTime) {
      final hour = int.tryParse(_hourController.text) ?? now.hour;
      final minute = int.tryParse(_minuteController.text) ?? now.minute;
      localTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour.clamp(0, 23),
        minute.clamp(0, 59),
      );
    } else {
      localTime = now;
      _hourController.text = now.hour.toString().padLeft(2, '0');
      _minuteController.text = now.minute.toString().padLeft(2, '0');
    }

    setState(() => _busy = true);
    try {
      final chart = await widget.calculator.calculate(
        question: question,
        localTime: localTime,
        location: _location,
        questionType: _questionType,
        quesitedHouse: _house,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HoraryResultScreen(chart: chart),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beregning fejlede: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HorarMainDrawer(),
      appBar: AppBar(title: const Text('Horar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Stil spørgsmålet. Appen foreslår et relevant hus ud fra teksten, og du kan rette huset manuelt. Tidspunktet sættes automatisk, når du trykker “Beregn horar”, medmindre du vælger manuelt tidspunkt.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Spørgsmål',
              helperText: (_validationResult?.isValid ?? false)
                  ? 'Spørgsmålet kan bruges'
                  : 'Påkrævet – skriv ét konkret spørgsmål',
              border: const OutlineInputBorder(),
            ),
          ),
          if (_hasQuestionText) ...[
            const SizedBox(height: 10),
            _QuestionValidationCard(
              result: _validationResult,
              autoUseSuggestion: _autoUseQuestionSuggestion,
              aiHouseBusy: _aiHouseBusy,
              aiHouseStatus: _aiHouseStatus,
              onApplySuggestion: _applyHouseSuggestion,
              onExplainHouseChoice: _showHouseChoiceExplanation,
              onRequestAiSuggestion: _askAiForHouseSuggestion,
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _manualTime,
                    title: const Text('Manuelt tidspunkt'),
                    subtitle: const Text(
                      'Uden flueben bruges det aktuelle klokkeslæt, når du trykker “Beregn horar”.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      final now = DateTime.now();
                      setState(() {
                        _manualTime = value ?? false;
                        if (!_manualTime) {
                          _hourController.text = now.hour.toString().padLeft(2, '0');
                          _minuteController.text = now.minute.toString().padLeft(2, '0');
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: _manualTime,
                          controller: _hourController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Time',
                            helperText: _manualTime ? 'Manuel' : 'Sættes ved beregning',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          enabled: _manualTime,
                          controller: _minuteController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Minut',
                            helperText: _manualTime ? 'Manuel' : 'Sættes ved beregning',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_manualTime) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tidspunktet låses først i det øjeblik du trykker “Beregn horar”.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _house,
            decoration: const InputDecoration(
              labelText: 'Relevant hus',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (i) => i + 1)
                .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text('$h. hus'),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _autoUseQuestionSuggestion = false;
              _house = value ?? _house;
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _hasQuestionText ? () => _showHouseChoiceExplanation() : null,
              icon: const Icon(Icons.school_outlined),
              label: const Text('Hvorfor dette hus?'),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LocationChoice>(
            value: _location,
            decoration: const InputDecoration(
              labelText: 'Lokation',
              border: OutlineInputBorder(),
            ),
            items: _locations
                .map((loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.name),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _location = value ?? _location;
              if (_location.name != 'Aktuel lokation') {
                _locationStatus = null;
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _locationStatus ?? 'Vælg lokation manuelt eller brug aktuel lokation.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: _locationBusy ? null : _setCurrentLocationAsDefault,
                icon: _locationBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Aktuel'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (_busy || !(_validationResult?.isValid ?? false)) ? null : _calculate,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Beregner...' : 'Beregn horar'),
          ),
        ],
      ),
    );
  }
}


class _QuestionValidationCard extends StatelessWidget {
  final QuestionValidationResult? result;
  final bool autoUseSuggestion;
  final bool aiHouseBusy;
  final String? aiHouseStatus;
  final ValueChanged<HouseSuggestion> onApplySuggestion;
  final void Function(HouseSuggestion? suggestion) onExplainHouseChoice;
  final VoidCallback onRequestAiSuggestion;

  const _QuestionValidationCard({
    required this.result,
    required this.autoUseSuggestion,
    required this.aiHouseBusy,
    required this.aiHouseStatus,
    required this.onApplySuggestion,
    required this.onExplainHouseChoice,
    required this.onRequestAiSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const SizedBox.shrink();

    final color = r.isValid ? AppColors.brown : Colors.red.shade700;
    final icon = r.isValid ? Icons.check_circle_outline : Icons.error_outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.verdict,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Svarform: ${r.answerMode.label}', style: const TextStyle(color: AppColors.mutedText)),
            if (r.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...r.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $w'),
                  )),
            ],
            if (r.suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Foreslået hus', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...r.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(s.reason),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => onApplySuggestion(s),
                              child: const Text('Brug'),
                            ),
                            TextButton(
                              onPressed: () => onExplainHouseChoice(s),
                              child: const Text('Hvorfor?'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              Text(
                autoUseSuggestion
                    ? 'Auto-forslag er aktivt: huset følger bedste forslag fra teksten.'
                    : 'Du har valgt hus manuelt. Tryk “Brug” for at følge forslaget igen.',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => onExplainHouseChoice(null),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Hvorfor valgte appen dette hus?'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: aiHouseBusy ? null : onRequestAiSuggestion,
              icon: aiHouseBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology_alt_outlined),
              label: Text(aiHouseBusy ? 'AI vurderer hus...' : 'Få AI-husforslag'),
            ),
            if (aiHouseStatus != null && aiHouseStatus!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                aiHouseStatus!,
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _ScoreReference {
  static String signed(int value) => value > 0 ? '+$value' : value.toString();

  static double progressFor(int score, int min, int max) {
    if (min == max) return 0.5;
    final low = min < max ? min : max;
    final high = max > min ? max : min;
    final clamped = score.clamp(low, high).toDouble();
    return (clamped - low) / (high - low);
  }

  static String labelFor(int score, int min, int max, HoraryAnswerMode mode) {
    if (mode == HoraryAnswerMode.yesNo) {
      if (score == 0) return 'uklart/balanceret';

      if (score > 0) {
        if (max <= 0) return 'uklart/svagt ja';
        final ratio = score / max;
        if (ratio >= 0.70) return 'klart ja';
        if (ratio >= 0.45) return 'sandsynligvis ja';
        if (ratio >= 0.20) return 'svagt/betinget ja';
        return 'uklart/svagt ja';
      }

      if (min >= 0) return 'uklart/svagt nej';
      final ratio = score.abs() / min.abs();
      if (ratio >= 0.60) return 'nej/meget svagt';
      if (ratio >= 0.30) return 'snarere nej';
      return 'uklart/svagt nej';
    }

    final ratio = _relativeStrength(score, min, max);
    final strong = ratio >= 0.60;
    final medium = ratio >= 0.25;

    switch (mode) {
      case HoraryAnswerMode.yesNo:
        return 'uklart/balanceret';
      case HoraryAnswerMode.where:
        if (score > 0 && strong) return 'stærkt stedsspor';
        if (score > 0 && medium) return 'brugbart stedsspor';
        if (score < 0 && strong) return 'svækket stedsspor';
        if (score < 0) return 'usikkert stedsspor';
        return 'blandet stedsspor';
      case HoraryAnswerMode.when:
        if (score > 0 && strong) return 'tydelig timing';
        if (score > 0 && medium) return 'moderat timing';
        if (score < 0 && strong) return 'forsinket/blokeret timing';
        if (score < 0) return 'timing med forbehold';
        return 'uklar timing';
      case HoraryAnswerMode.howMuch:
        if (score > 0 && strong) return 'højt/gunstigt omfang';
        if (score > 0 && medium) return 'moderat omfang';
        if (score < 0 && strong) return 'lavt/reduceret omfang';
        if (score < 0) return 'mindre end ønsket';
        return 'blandet omfang';
      case HoraryAnswerMode.who:
        if (score > 0 && strong) return 'tydelig aktør';
        if (score > 0 && medium) return 'moderat aktørspor';
        if (score < 0 && strong) return 'skjult/svækket aktør';
        if (score < 0) return 'aktør med forbehold';
        return 'blandet aktørspor';
      case HoraryAnswerMode.what:
        if (score > 0 && strong) return 'tydelig sagstype';
        if (score > 0 && medium) return 'brugbar sagstype';
        if (score < 0 && strong) return 'svækket/skjult sag';
        if (score < 0) return 'sag med forbehold';
        return 'blandet sagstype';
      case HoraryAnswerMode.how:
        if (score > 0 && strong) return 'tydelig handlingsvej';
        if (score > 0 && medium) return 'mulig handlingsvej';
        if (score < 0 && strong) return 'blokeret handlingsvej';
        if (score < 0) return 'handlingsvej med forbehold';
        return 'uklar handlingsvej';
      case HoraryAnswerMode.why:
        if (score > 0 && strong) return 'tydelig årsagslinje';
        if (score > 0 && medium) return 'mulig årsagslinje';
        if (score < 0 && strong) return 'tung/blokeret årsag';
        if (score < 0) return 'årsag med forbehold';
        return 'blandet årsagslinje';
    }
  }

  static double _relativeStrength(int score, int min, int max) {
    if (score == 0) return 0.0;
    if (score > 0) return max <= 0 ? 0.0 : score / max;
    return min >= 0 ? 0.0 : score.abs() / min.abs();
  }

  static String intervalText(int score, int min, int max) =>
      '${signed(score)} i intervallet ${signed(min)} til ${signed(max)}';
}

class _ScoreReferenceLine extends StatelessWidget {
  final int score;
  final int min;
  final int max;
  final HoraryAnswerMode answerMode;
  final String label;

  const _ScoreReferenceLine({
    required this.score,
    required this.min,
    required this.max,
    required this.answerMode,
    this.label = 'Samlet vægtet score',
  });

  @override
  Widget build(BuildContext context) {
    return Text('$label: ${_ScoreReference.intervalText(score, min, max)} · ${_ScoreReference.labelFor(score, min, max, answerMode)}');
  }
}

class _ScoreReferenceBar extends StatelessWidget {
  final int score;
  final int min;
  final int max;
  final HoraryAnswerMode answerMode;

  const _ScoreReferenceBar({
    required this.score,
    required this.min,
    required this.max,
    required this.answerMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreReferenceLine(score: score, min: min, max: max, answerMode: answerMode),
        if (answerMode != HoraryAnswerMode.yesNo) ...[
          const SizedBox(height: 4),
          Text(
            'Ved ${answerMode.label.toLowerCase()}-spørgsmål bruges scoren som styrke/usikkerhed, ikke som ja/nej-svar.',
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: _ScoreReference.progressFor(score, min, max),
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brown),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_ScoreReference.signed(min), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
            const Text('0', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
            Text(_ScoreReference.signed(max), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
          ],
        ),
      ],
    );
  }
}

class HoraryResultScreen extends StatefulWidget {
  final HoraryChart chart;

  const HoraryResultScreen({super.key, required this.chart});

  @override
  State<HoraryResultScreen> createState() => _HoraryResultScreenState();
}

class _HoraryResultScreenState extends State<HoraryResultScreen> {
  late Future<HorarAiResult> _aiFuture;
  final HorarAiService _aiService = const HorarAiService();

  @override
  void initState() {
    super.initState();
    _aiFuture = _aiService.interpret(widget.chart);
  }

  String get _timeText {
    final date = widget.chart.localTime;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _retryAi() {
    setState(() {
      _aiFuture = _aiService.interpret(widget.chart);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chart = widget.chart;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        drawer: const HorarMainDrawer(),
        appBar: AppBar(
          title: const Text('Horar-svar'),
          actions: [
            IconButton(
              tooltip: 'Studie-journal',
              icon: const Icon(Icons.book_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StudyJournalScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.white,
            unselectedLabelColor: Color(0xccffffff),
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Konklusion'),
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'Tegning'),
              Tab(icon: Icon(Icons.table_chart_outlined), text: 'Tabeller'),
              Tab(icon: Icon(Icons.notes), text: 'Detaljer'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConclusionTab(chart: chart, aiFuture: _aiFuture, onRetryAi: _retryAi),
            _ChartTab(chart: chart, timeText: _timeText),
            _TablesTab(chart: chart, timeText: _timeText),
            _DetailsTab(chart: chart, timeText: _timeText),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Tilbage – stil nyt spørgsmål'),
          ),
        ),
      ),
    );
  }
}

class _ConclusionTab extends StatelessWidget {
  final HoraryChart chart;
  final Future<HorarAiResult> aiFuture;
  final VoidCallback onRetryAi;

  const _ConclusionTab({
    required this.chart,
    required this.aiFuture,
    required this.onRetryAi,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AiAnswerCard(chart: chart, aiFuture: aiFuture, onRetry: onRetryAi),
      ],
    );
  }
}


class _AiAnswerCard extends StatelessWidget {
  final HoraryChart chart;
  final Future<HorarAiResult> aiFuture;
  final VoidCallback onRetry;

  const _AiAnswerCard({
    required this.chart,
    required this.aiFuture,
    required this.onRetry,
  });

  Future<void> _saveToJournal(BuildContext context, String aiAnswer) async {
    try {
      await const StudyJournalService().save(
        StudyJournalEntry.fromChart(chart: chart, aiAnswer: aiAnswer),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemt i studie-journalen')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke gemme journalnotat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<HorarAiResult>(
          future: aiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontekst-svar', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text('Sender beregningen til AI-serveren og formulerer svaret...')),
                    ],
                  ),
                ],
              );
            }

            final result = snapshot.data;
            if (snapshot.hasError || result == null || !result.ok) {
              final errorText = snapshot.hasError
                  ? snapshot.error.toString()
                  : (result?.error ?? 'Ukendt AI-fejl');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontekst-svar', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    'AI-serveren kunne ikke give et svar. Den horar-astrologiske beregning ovenfor kan stadig bruges.',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 6),
                  Text(errorText, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Prøv AI-svar igen'),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kontekst-svar', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(result.answer),
                const SizedBox(height: 8),
                const Text(
                  'Svaret er formuleret ud fra appens horar-astrologiske beregning og skal læses med samme forbehold som resten af vurderingen.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _saveToJournal(context, result.answer),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Gem i studie-journal'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChartTab extends StatefulWidget {
  final HoraryChart chart;
  final String timeText;

  const _ChartTab({required this.chart, required this.timeText});

  @override
  State<_ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<_ChartTab> {
  late final TransformationController _wheelController;
  final GlobalKey _wheelExportKey = GlobalKey();
  final HorarExportService _exportService = const HorarExportService();
  bool _zoomed = false;
  bool _exportBusy = false;

  @override
  void initState() {
    super.initState();
    _wheelController = TransformationController();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _zoomed = false;
      _wheelController.value = Matrix4.identity();
    });
  }

  void _toggleZoom(double viewportSize) {
    setState(() {
      if (_zoomed) {
        _zoomed = false;
        _wheelController.value = Matrix4.identity();
      } else {
        _zoomed = true;
        const scale = 2.4;
        final offset = -(viewportSize * (scale - 1)) / 2;
        _wheelController.value = Matrix4.identity()
          ..translate(offset, offset)
          ..scale(scale);
      }
    });
  }


  Future<Uint8List> _captureWheelPng() async {
    // Vent en frame, så RepaintBoundary er færdigtegnet før eksport.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _wheelExportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Horar-tegningen er ikke klar endnu. Prøv igen om et øjeblik.');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw Exception('Kunne ikke danne PNG-billede.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _exportImage() async {
    if (_exportBusy) return;
    setState(() => _exportBusy = true);

    try {
      final pngBytes = await _captureWheelPng();
      final file = await _exportService.writeChartImage(
        pngBytes: pngBytes,
        chart: widget.chart,
      );
      await _exportService.shareFile(file, title: 'Horar-kort som billede');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Billede gemt: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke eksportere billede: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_exportBusy) return;
    setState(() => _exportBusy = true);

    try {
      final pngBytes = await _captureWheelPng();
      final file = await _exportService.writeChartPdf(
        chartPngBytes: pngBytes,
        chart: widget.chart,
      );
      await _exportService.shareFile(file, title: 'Horar-kort som PDF');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF gemt: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke eksportere PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.timeText} – ${widget.chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
              if (widget.chart.question.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Spørgsmål: ${widget.chart.question}'),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportBusy ? null : _exportImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Eksportér billede'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportBusy ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Eksportér PDF'),
                  ),
                  if (_exportBusy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Knib med to fingre for at zoome. Dobbelttryk zoomer også.',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        ),
                        TextButton(
                          onPressed: _resetZoom,
                          child: const Text('Nulstil'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortest = constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth
                            : constraints.maxHeight;
                        final wheelSize = (shortest - 12).clamp(280.0, 900.0).toDouble();

                        return ClipRect(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: () => _toggleZoom(wheelSize),
                            child: InteractiveViewer(
                              transformationController: _wheelController,
                              panEnabled: true,
                              scaleEnabled: true,
                              minScale: 1.0,
                              maxScale: 6.0,
                              boundaryMargin: const EdgeInsets.all(900),
                              clipBehavior: Clip.hardEdge,
                              child: Center(
                                child: RepaintBoundary(
                                  key: _wheelExportKey,
                                  child: Container(
                                    width: wheelSize,
                                    height: wheelSize,
                                    color: AppColors.white,
                                    child: ZodiacWheel(chart: widget.chart),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TablesTab extends StatelessWidget {
  final HoraryChart chart;
  final String timeText;

  const _TablesTab({required this.chart, required this.timeText});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$timeText – ${chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
        if (chart.question.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Spørgsmål: ${chart.question}'),
        ],
        const SizedBox(height: 16),
        Text('Planeter og værdigheder', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DignitiesTable(chart: chart),
        const SizedBox(height: 16),
        Text('Husspidser', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _HouseCuspsTable(chart: chart),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final HoraryChart chart;
  final String timeText;

  const _DetailsTab({required this.chart, required this.timeText});

  @override
  Widget build(BuildContext context) {
    final topFactors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));
    final mainFactors = topFactors.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$timeText – ${chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
        if (chart.question.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Spørgsmål: ${chart.question}'),
        ],
        const SizedBox(height: 16),
        _SourceMethodCard(chart: chart),
        const SizedBox(height: 16),
        Text('Klassisk horar-astrologisk vurdering', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. ${chart.answerMode.resultHeading}', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(chart.judgement, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(chart.judgementExplanation),
                const SizedBox(height: 8),
                Text('Svarform: ${chart.answerMode.label}', style: const TextStyle(color: AppColors.mutedText)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Vægtning / styrke', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _ScoreReferenceBar(score: chart.finalScore, min: chart.scoreMin, max: chart.scoreMax, answerMode: chart.answerMode),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. Vigtigste faktorer', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (mainFactors.isEmpty)
                  const Text('Ingen vægtede faktorer er beregnet endnu.')
                else
                  ...mainFactors.map((factor) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• ${factor.signText} ${factor.title}: ${factor.explanation}'),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4. Signifikatorer', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('Spørger: ${chart.querentRuler}'),
                Text('Det adspurgte: ${chart.quesitedRuler} (${chart.quesitedHouse}. hus)'),
                if (chart.derivedHouseExplanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    chart.derivedHouseExplanation!,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ],
                const SizedBox(height: 6),
                Text("Måne: ${chart.moonVoidOfCourse ? 'void-of-course' : 'har videre aspekt'}${chart.moonViaCombusta ? ' · via combusta' : ''}"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Fuld vægtet forklaring', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _WeightedExplanationCard(chart: chart),
        if (chart.specialReading != null) ...[
          const SizedBox(height: 16),
          Text('Specialregler og hus-/tegn-hints', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _SpecialQuestionCard(reading: chart.specialReading!),
        ],
        if (chart.antiscionContacts.isNotEmpty || chart.fixedStarContacts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Antiscia og fixstjerner', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AdvancedSymbolCard(chart: chart),
        ],
        const SizedBox(height: 16),
        Text('Regler', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _RulesTable(chart: chart),
        const SizedBox(height: 16),
        Text('Tolkning', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...chart.notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $n'),
            )),
      ],
    );
  }
}


class _SourceMethodCard extends StatelessWidget {
  final HoraryChart chart;

  const _SourceMethodCard({required this.chart});

  @override
  Widget build(BuildContext context) {
    final derived = chart.derivedHouseExplanation;
    final methodRows = <String>[
      'Kort: beregnet lokalt på enheden ud fra spørgsmålstidspunkt, valgt/aktuel placering og Regiomontanus-huse.',
      'Husvalg: ${chart.quesitedHouse}. hus (${chart.questionType.label}). Spørgeren læses fra 1. hus; det adspurgte fra det valgte hus.',
      if (derived != null && derived.trim().isNotEmpty) 'Afledt hus: $derived',
      'Signifikatorer: ${chart.querentRuler} for spørgeren og ${chart.quesitedRuler} for det adspurgte. Månen indgår som medsignifikator og som fortæller om sagens forløb.',
      'Vurdering: appen vægter perfektion/aspekter, reception, essentiel og accidental styrke, Månen, prohibition, frustration, translation/collection, antiscia, fixstjerner og relevante specialregler.',
      'AI: Konklusionen er en sproglig formulering af appens lokale beregning. AI’en skal forklare resultatet, ikke erstatte den horar-astrologiske metode.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fact_check_outlined, color: AppColors.brown),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kilder og metode', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      const Text(
                        'Denne sektion viser, hvilket datagrundlag og hvilke regler den konkrete vurdering bygger på.',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _MethodLine(label: 'Primær reference', value: 'John Frawley: The Horary Textbook.'),
            const _MethodLine(label: 'Tradition', value: 'Klassisk horar-astrologi med fokus på husvalg, signifikatorer, reception og perfektion.'),
            const _MethodLine(label: 'Hussystem', value: 'Regiomontanus.'),
            const _MethodLine(label: 'Planetgrundlag', value: 'Sol, Måne, Merkur, Venus, Mars, Jupiter og Saturn anvendes som traditionelle horar-astrologiske signifikatorer.'),
            const SizedBox(height: 10),
            ...methodRows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text('• $row'),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SourcesAndMethodScreen()),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Åbn fuld kilde-/metodebeskrivelse'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodLine extends StatelessWidget {
  final String label;
  final String value;

  const _MethodLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}


class _WeightedExplanationCard extends StatelessWidget {
  final HoraryChart chart;

  const _WeightedExplanationCard({required this.chart});

  @override
  Widget build(BuildContext context) {
    final factors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chart.judgementExplanation,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ScoreReferenceBar(score: chart.finalScore, min: chart.scoreMin, max: chart.scoreMax, answerMode: chart.answerMode),
            const SizedBox(height: 12),
            if (factors.isEmpty)
              const Text('Ingen vægtede faktorer er beregnet endnu.')
            else
              ...factors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                factor.signText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'interval\n${_ScoreReference.signed(chart.scoreMin)}…${_ScoreReference.signed(chart.scoreMax)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9, color: AppColors.mutedText, height: 1.05),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${factor.title} · ${factor.direction}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                factor.category,
                                style: const TextStyle(color: AppColors.mutedText),
                              ),
                              const SizedBox(height: 4),
                              Text(factor.explanation),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 6),
            const Text(
              'Ved ja/nej-spørgsmål læses positiv/negativ vægt som ja/nej-tendens. Ved hvem, hvor, hvornår, hvor meget, hvad, hvordan og hvorfor læses vægten som styrke, tydelighed, hindring, forsinkelse, omfang eller forbehold.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}


class _SpecialQuestionCard extends StatelessWidget {
  final SpecialQuestionReading reading;

  const _SpecialQuestionCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reading.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(reading.summary),
            const SizedBox(height: 8),
            Text('Scorejustering: ${reading.scoreAdjustment}'),
            const SizedBox(height: 12),
            ...reading.rules.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $r'),
                )),
            if (reading.hints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Hus-/tegn-hints', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...reading.hints.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $h'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}


class _AdvancedSymbolCard extends StatelessWidget {
  final HoraryChart chart;

  const _AdvancedSymbolCard({required this.chart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chart.antiscionContacts.isNotEmpty) ...[
              Text('Antiscia', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...chart.antiscionContacts.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${c.text}'),
                  )),
            ],
            if (chart.fixedStarContacts.isNotEmpty) ...[
              if (chart.antiscionContacts.isNotEmpty) const SizedBox(height: 10),
              Text('Fixstjerner', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...chart.fixedStarContacts.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${c.text}\n  Natur: ${c.nature}'),
                  )),
            ],
            const SizedBox(height: 8),
            const Text(
              'Disse faktorer farver tolkningen. De bør ikke alene afgøre hovedsvaret uden hovedsignifikatorer, Månen og reception.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesTable extends StatelessWidget {
  final HoraryChart chart;

  const _RulesTable({required this.chart});

  @override
  Widget build(BuildContext context) {
    final rows = <({String rule, String status})>[
      (
        rule: 'Prohibition',
        status: chart.prohibition?.text ?? 'Ikke fundet',
      ),
      (
        rule: 'Frustration',
        status: chart.frustration?.text ?? 'Ikke fundet',
      ),
      (
        rule: 'Translation',
        status: chart.translationOfLight?.text ?? 'Ikke fundet',
      ),
      (
        rule: 'Collection',
        status: chart.collectionOfLight?.text ?? 'Ikke fundet',
      ),
      (
        rule: 'Void Moon',
        status: chart.moonVoidOfCourse ? 'Ja' : 'Nej',
      ),
      (
        rule: 'Via combusta',
        status: chart.moonViaCombusta ? 'Ja' : 'Nej',
      ),
      (
        rule: 'Antiscia',
        status: chart.antiscionContacts.isEmpty
            ? 'Ikke fundet'
            : chart.antiscionContacts.map((c) => c.text).join(' · '),
      ),
      (
        rule: 'Fixstjerner',
        status: chart.fixedStarContacts.isEmpty
            ? 'Ikke fundet'
            : chart.fixedStarContacts.map((c) => c.text).join(' · '),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: rows
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            r.rule,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(child: Text(r.status)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}


class _HouseCuspsTable extends StatelessWidget {
  final HoraryChart chart;

  const _HouseCuspsTable({required this.chart});

  String _labelForHouse(int number) {
    switch (number) {
      case 1:
        return '1. hus / AC';
      case 4:
        return '4. hus / IC';
      case 7:
        return '7. hus / DC';
      case 10:
        return '10. hus / MC';
      default:
        return '$number. hus';
    }
  }

  @override
  Widget build(BuildContext context) {
    final houses = [...chart.houses]..sort((a, b) => a.number.compareTo(b.number));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Husspids')),
          DataColumn(label: Text('Position')),
          DataColumn(label: Text('Longitude')),
        ],
        rows: houses.map((h) {
          return DataRow(cells: [
            DataCell(Text(_labelForHouse(h.number))),
            DataCell(Text(h.positionText)),
            DataCell(Text('${h.longitude.toStringAsFixed(2)}°')),
          ]);
        }).toList(),
      ),
    );
  }
}

class _DignitiesTable extends StatelessWidget {
  final HoraryChart chart;

  const _DignitiesTable({required this.chart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Planet')),
          DataColumn(label: Text('Pos')),
          DataColumn(label: Text('Hus')),
          DataColumn(label: Text('Dign')),
          DataColumn(label: Text('Exalt')),
          DataColumn(label: Text('Detr')),
          DataColumn(label: Text('Fall')),
          DataColumn(label: Text('Score')),
          DataColumn(label: Text('Tilstand')),
        ],
        rows: chart.planets.map((p) {
          final condition = chart.conditionFor(p.name);
          return DataRow(cells: [
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlanetGlyph(planet: p.name, size: 20, color: AppColors.text),
                const SizedBox(width: 6),
                Text(p.name),
              ],
            )),
            DataCell(Text(p.positionText)),
            DataCell(Text(p.house.toString())),
            DataCell(Text(p.dignity.ruler)),
            DataCell(Text(p.dignity.exaltation)),
            DataCell(Text(p.dignity.detriment)),
            DataCell(Text(p.dignity.fall)),
            DataCell(Text(condition?.totalScore.toString() ?? '-')),
            DataCell(Text(condition?.summary ?? '-')),
          ]);
        }).toList(),
      ),
    );
  }
}

class StudyJournalScreen extends StatefulWidget {
  const StudyJournalScreen({super.key});

  @override
  State<StudyJournalScreen> createState() => _StudyJournalScreenState();
}

class _StudyJournalScreenState extends State<StudyJournalScreen> {
  final StudyJournalService _service = const StudyJournalService();
  late Future<List<StudyJournalEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load();
  }

  void _reload() {
    setState(() {
      _future = _service.load();
    });
  }

  Future<void> _deleteEntry(StudyJournalEntry entry) async {
    await _service.delete(entry.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journalnotat slettet')),
      );
      _reload();
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet hele journalen?'),
        content: const Text('Alle gemte horarspørgsmål og svar slettes fra denne enhed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Slet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studie-journalen er slettet')),
        );
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studie-journal'),
        actions: [
          IconButton(
            tooltip: 'Opdater',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: 'Slet alle',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: FutureBuilder<List<StudyJournalEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <StudyJournalEntry>[];
          if (entries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingen gemte spørgsmål endnu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Når AI-svaret vises under Konklusion, kan du gemme spørgsmålet og svaret her som studie-journal.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final title = entry.question.trim().isEmpty ? 'Uden spørgsmål' : entry.question.trim();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_formatJournalDateTime(entry.savedAt)} · ${entry.answerModeLabel} · ${entry.quesitedHouse}. hus\n'
                      '${_shortJournalText(entry.aiAnswer)}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Slet',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEntry(entry),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudyJournalDetailScreen(entry: entry),
                      ),
                    );
                    if (mounted) _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudyJournalDetailScreen extends StatelessWidget {
  final StudyJournalEntry entry;

  const StudyJournalDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journalnotat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_formatJournalDateTime(entry.savedAt), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Spørgsmålets tid: ${_formatJournalDateTime(entry.questionTime)} · ${entry.locationName}',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 16),
          _JournalCard(
            title: 'Spørgsmål',
            child: Text(entry.question.trim().isEmpty ? 'Uden spørgsmål' : entry.question),
          ),
          const SizedBox(height: 12),
          _JournalCard(
            title: 'AI-svar',
            child: Text(entry.aiAnswer),
          ),
          const SizedBox(height: 12),
          _JournalCard(
            title: 'Teknisk horar-astrologisk grundlag',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Svarform: ${entry.answerModeLabel}'),
                Text('Spørgsmålstype: ${entry.questionTypeLabel}'),
                Text('Det adspurgte: ${entry.quesitedRuler} (${entry.quesitedHouse}. hus)'),
                Text('Spørger: ${entry.querentRuler}'),
                const SizedBox(height: 8),
                Text('Klassisk vurdering: ${entry.judgement}'),
                Text(entry.judgementExplanation),
                const SizedBox(height: 8),
                Text('Score: ${entry.finalScore} / interval ${entry.scoreMin} til ${entry.scoreMax}'),
                if (entry.derivedHouseExplanation != null && entry.derivedHouseExplanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.derivedHouseExplanation!),
                ],
              ],
            ),
          ),
          if (entry.topFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            _JournalCard(
              title: 'Vigtigste faktorer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.topFactors
                    .map(
                      (factor) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• ${factor.signText} ${factor.title}: ${factor.explanation}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _JournalCard(
              title: 'Noter',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.notes.map((note) => Text('• $note')).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _JournalCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

String _formatJournalDateTime(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _shortJournalText(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 110) return compact;
  return '${compact.substring(0, 110)}…';
}



class HouseSystemScreen extends StatelessWidget {
  const HouseSystemScreen({super.key});

  static const String _activeHouseSystem = 'Regiomontanus';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hussystem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivt hussystem',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Regiomontanus er valgt som standard, fordi det er det klassiske hussystem, der oftest bruges i traditionel horar-astrologi og hos John Frawley.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HouseSystemChoice(
            title: 'Regiomontanus',
            subtitle: 'Aktivt hussystem. Bruges til alle beregninger i denne version.',
            value: 'Regiomontanus',
            groupValue: _activeHouseSystem,
            enabled: true,
          ),
          _HouseSystemChoice(
            title: 'Placidus',
            subtitle: 'Ikke aktivt endnu. Vises kun for metodegennemsigtighed.',
            value: 'Placidus',
            groupValue: _activeHouseSystem,
            enabled: false,
          ),
          _HouseSystemChoice(
            title: 'Whole Sign',
            subtitle: 'Ikke aktivt endnu. Kan evt. tilføjes i en senere version.',
            value: 'Whole Sign',
            groupValue: _activeHouseSystem,
            enabled: false,
          ),
          _HouseSystemChoice(
            title: 'Equal House',
            subtitle: 'Ikke aktivt endnu. Kan evt. tilføjes i en senere version.',
            value: 'Equal House',
            groupValue: _activeHouseSystem,
            enabled: false,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Metode-note',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Alle husspidser, afledte huse, signifikatorvalg og vurderinger beregnes derfor ud fra Regiomontanus. Menuen er medtaget for at gøre metodevalget tydeligt for brugeren og for App Review.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseSystemChoice extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final bool enabled;

  const _HouseSystemChoice({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? (_) {} : null,
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: enabled
            ? const Icon(Icons.check_circle_outline)
            : const Icon(Icons.lock_outline),
      ),
    );
  }
}

class SourcesAndMethodScreen extends StatelessWidget {
  const SourcesAndMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kilder og metode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MethodInfoCard(
            icon: Icons.menu_book_outlined,
            title: 'Primær kilde',
            children: [
              'John Frawley: The Horary Textbook anvendes som hovedreference for appens klassiske horar-astrologiske metode.',
              'Appen er et studie- og analyseværktøj. Den erstatter ikke astrologens egen vurdering, men viser de regler og vægtninger den bruger.',
            ],
          ),
          _MethodInfoCard(
            icon: Icons.account_tree_outlined,
            title: 'Husvalg og afledte huse',
            children: [
              'Appen foreslår hus ud fra spørgsmålets tekst, klassiske hustemaer og eventuelt AI-husforslag før beregning.',
              'Ved relationer anvendes afledte huse: partner = 7. hus; partnerens ejendel = 2. fra 7. = 8. hus; barns partner = 7. fra 5. = 11. hus.',
              'Konkurrence og titelspørgsmål adskilles: en konkret modstander peger mod 7. hus, mens titel, pokal og mesterskab peger mod 10. hus.',
            ],
          ),
          _MethodInfoCard(
            icon: Icons.public_outlined,
            title: 'Kortberegning',
            children: [
              'Kortet beregnes lokalt på enheden ud fra tidspunktet for spørgsmålet og den valgte eller aktuelle geografiske placering.',
              'Hussystemet er Regiomontanus i denne version. Det fremgår også af menupunktet Hussystem, hvor øvrige hussystemer vises som ikke-aktive metodevalg.',
              'Tegningen viser både husgrænser og tegn-grænser. Tabellerne viser planetpositioner, huse, digniteter, aspekter og regler.',
            ],
          ),
          _MethodInfoCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Signifikatorer og vurdering',
            children: [
              'Spørgeren læses fra 1. hus. Det adspurgte læses fra det valgte eller afledte hus.',
              'Appen vurderer traditionelle signifikatorer, Månen, aspekter/perfektion, reception, essentiel og accidental styrke, prohibition, frustration, translation og collection.',
              'Særlige regler bruges ved blandt andet tabte ting, sygdom, retssager, konkurrence og mesterskaber.',
            ],
          ),
          _MethodInfoCard(
            icon: Icons.psychology_alt_outlined,
            title: 'AI’s rolle',
            children: [
              'AI bruges til to adskilte formål: husforslag før beregning og sproglig konklusion efter beregning.',
              'Horar-beregningen og de klassiske vægtninger sker lokalt i appen. AI-svaret skal formulere og forklare appens beregnede resultat.',
              'Konklusion-fanen viser AI-svaret. Detaljer-fanen viser metoden, vægtningen og de konkrete regler bag svaret.',
            ],
          ),
          _MethodInfoCard(
            icon: Icons.warning_amber_outlined,
            title: 'Afgrænsning',
            children: [
              'Resultatet er en horar-astrologisk vurdering og et læringsgrundlag, ikke en garanti.',
              'Ved helbred, jura, økonomi og sikkerhed bør appens svar ikke bruges som erstatning for faglig rådgivning.',
              'Studie-journalen kan bruges til at gemme spørgsmål, svar og udfald, så metoden kan kontrolleres over tid.',
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> children;

  const _MethodInfoCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.brown),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 10),
            ...children.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $text'),
                )),
          ],
        ),
      ),
    );
  }
}


class LearnHoraryScreen extends StatelessWidget {
  const LearnHoraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _learnHorarySections;
    return Scaffold(
      appBar: AppBar(title: const Text('Lær horar-astrologi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Horar som studie- og analyseværktøj',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Horar-astrologi tolker et konkret spørgsmål ud fra tidspunktet, hvor spørgsmålet bliver klart formuleret. Denne side forklarer de regler appen bruger, så resultatet kan studeres, kontrolleres og sammenlignes med klassisk horar-astrologisk metode.',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Brug siden sammen med fanerne Tabeller og Detaljer: først spørgsmålet, derefter husvalg, signifikatorer, aspekter, receptioner og særlige regler.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map((section) => _LearnSectionTile(section: section)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reference og forbehold',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appens metode er inspireret af klassisk horar-astrologi, blandt andet John Frawley: The Horary Textbook. Resultatet er et studiegrundlag, ikke en garanti. Journalen kan bruges til at sammenligne tydning og faktisk udfald over tid.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnSectionTile extends StatelessWidget {
  final _LearnSection section;

  const _LearnSectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(section.icon),
        title: Text(section.title),
        subtitle: Text(section.subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final paragraph in section.paragraphs) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(paragraph),
            ),
            const SizedBox(height: 10),
          ],
          if (section.examples.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eksempler',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            for (final example in section.examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• $example'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LearnSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> paragraphs;
  final List<String> examples;

  const _LearnSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.paragraphs,
    this.examples = const [],
  });
}

const List<_LearnSection> _learnHorarySections = [
  _LearnSection(
    icon: Icons.help_outline,
    title: '1. Spørgsmålet',
    subtitle: 'Et horar-astrologisk kort begynder med et klart spørgsmål',
    paragraphs: [
      'Et horar-astrologisk spørgsmål skal være konkret og oprigtigt. Kortet beregnes for tidspunktet, hvor spørgsmålet stilles og forstås klart.',
      'Appen afviser eller advarer ved meget tomme eller uklare spørgsmål, fordi horar kræver et bestemt anliggende.',
    ],
    examples: [
      'Godt: "Hvor er min kones tørklæde?"',
      'Godt: "Får jeg jobbet?"',
      'Uklart: "Hvad sker der?"',
    ],
  ),
  _LearnSection(
    icon: Icons.home_work_outlined,
    title: '2. Husvalg',
    subtitle: 'Det rette hus beskriver sagen der spørges om',
    paragraphs: [
      'Huset er nøglen til tydningen. 1. hus er spørgeren. Det hus der beskriver sagen, bliver den adspurgte part eller det adspurgte emne.',
      'Appen foreslår hus ud fra spørgsmålets ordlyd og viser begrundelsen i Detaljer. AI-husforslag kan bruges før beregningen som ekstra hjælp.',
      'Undervisningsknappen “Hvorfor dette hus?” viser den konkrete regel bag husvalget, så brugeren kan se forskel på hovedhus, afledt hus og manuelt valgt hus, før selve tydningen beregnes.',
    ],
    examples: [
      'Job og karriere: 10. hus.',
      'Penge og ejendele: 2. hus.',
      'Partner/ægtefælle/modstander: 7. hus.',
      'Børn: 5. hus.',
      'Sygdom og behandling: 6. hus.',
    ],
  ),
  _LearnSection(
    icon: Icons.account_tree_outlined,
    title: '3. Afledte huse',
    subtitle: 'Man tæller fra en anden persons hus',
    paragraphs: [
      'Afledte huse bruges, når spørgsmålet handler om en anden persons ting, forhold, arbejde eller familie. Den relevante person bliver et nyt 1. hus, og man tæller derfra.',
      'Man tæller inklusivt: 7. hus er partneren som 1. fra partneren. 8. hus er 2. fra partneren og kan derfor vise partnerens penge eller ejendel.',
    ],
    examples: [
      'Min kones tørklæde: kone = 7. hus, hendes ejendel = 2. fra 7. = 8. hus.',
      'Min datters mand: datter = 5. hus, hendes mand = 7. fra 5. = 11. hus.',
      'Min datters mands job: 10. fra 11. = 8. hus.',
    ],
  ),
  _LearnSection(
    icon: Icons.person_search_outlined,
    title: '4. Signifikatorer',
    subtitle: 'Planeterne der repræsenterer spørger og sag',
    paragraphs: [
      'Signifikatoren for spørgeren er herskeren over 1. hus. Signifikatoren for sagen er herskeren over det valgte hus. Månen er næsten altid medsignifikator for spørgeren og sagens udvikling.',
      'Tydningen undersøger især om signifikatorerne mødes, adskilles, modtager hinanden eller er blokerede.',
    ],
    examples: [
      'Ascendant i Vædderen: Mars viser spørgeren.',
      '7. hus i Vægten: Venus viser partneren.',
      '10. hus i Løven: Solen viser job, titel eller chef.',
    ],
  ),
  _LearnSection(
    icon: Icons.public_outlined,
    title: '5. Essentiel og accidental styrke',
    subtitle: 'Hvor stærk og handlekraftig en planet er',
    paragraphs: [
      'Essentiel værdighed viser om planeten står i et tegn, hvor den har naturmæssig styrke eller svaghed: domicil, exaltation, detriment og fald.',
      'Accidental styrke handler mere om handlekraft i situationen, for eksempel husplacering, hastighed, retrograditet, forbrænding og om planeten er vinklet.',
    ],
    examples: [
      'En stærk signifikator kan handle bedre.',
      'En retrograd eller forbrændt signifikator kan vise forsinkelse, svækkelse eller tilbagegang.',
    ],
  ),
  _LearnSection(
    icon: Icons.compare_arrows_outlined,
    title: '6. Aspekt og perfektion',
    subtitle: 'Om sagen faktisk kan ske',
    paragraphs: [
      'Et ja/nej-spørgsmål afgøres ofte ved, om spørgerens og sagens signifikatorer danner et applikativt aspekt. Applikativt betyder, at aspektet er på vej til at blive eksakt.',
      'Konjunktion, sekstil, trigon, kvadrat og opposition kan alle være relevante. Gode aspekter er lettere, mens kvadrat/opposition ofte viser besvær eller modstand.',
    ],
    examples: [
      'Applikativ trigon mellem signifikatorerne: stærkt ja.',
      'Ingen forbindelse: svagt eller nej, medmindre Månen eller en anden planet forbinder dem.',
      'Separativt aspekt: noget har allerede været eller er ved at glide væk.',
    ],
  ),
  _LearnSection(
    icon: Icons.sync_alt_outlined,
    title: '7. Reception',
    subtitle: 'Hvem vil hvem, og på hvilke vilkår?',
    paragraphs: [
      'Reception viser hvordan parterne modtager hinanden. En planet i et tegn styret af den anden part viser interesse, afhængighed eller velvilje over for den anden.',
      'God reception kan hjælpe et vanskeligt aspekt. Dårlig reception kan svække et ellers pænt aspekt.',
    ],
    examples: [
      'Spørgerens planet i partnerens tegn: spørgeren er stærkt optaget af partneren.',
      'Gensidig reception: parterne kan hjælpe hinanden.',
    ],
  ),
  _LearnSection(
    icon: Icons.block_outlined,
    title: '8. Forhindringer',
    subtitle: 'Prohibition, frustration og andre stopklodser',
    paragraphs: [
      'Selv når signifikatorerne er på vej mod et aspekt, kan en anden planet komme først og forhindre udfaldet. Det kaldes ofte prohibition.',
      'Frustration kan opstå, når en signifikator skifter situation eller aspektet ikke fuldendes. Translation og collection of light kan derimod forbinde parter indirekte.',
    ],
    examples: [
      'En tredje planet aspekterer først og afbryder forbindelsen.',
      'Månen overfører lys fra den ene signifikator til den anden.',
      'En stærk tredje planet samler lyset fra begge parter.',
    ],
  ),
  _LearnSection(
    icon: Icons.nights_stay_outlined,
    title: '9. Månen',
    subtitle: 'Månen viser forløbet og næste udvikling',
    paragraphs: [
      'Månen bruges som medsignifikator og viser ofte sagens bevægelse. Dens næste aspekt er vigtigt for hvad der sker nu.',
      'En void of course Måne kan vise, at intet væsentligt ændrer sig, men det skal altid vurderes i sammenhæng med resten af kortet.',
    ],
    examples: [
      'Månens næste aspekt til sagens planet kan bringe udfaldet.',
      'Void Måne kan være et tegn på stilstand.',
    ],
  ),
  _LearnSection(
    icon: Icons.search_outlined,
    title: '10. Tabte ting',
    subtitle: 'Hus, retning, sted og tegnsymbolik',
    paragraphs: [
      'Ved tabte ting bruges normalt 2. hus for spørgerens ejendel. Hvis tingen tilhører en anden person, bruges afledt 2. hus fra personens hus.',
      'Tegnet, huset og planetens placering kan give symbolik om rum, retning, højde, farve eller type sted. Appens AI-svar kan formulere disse spor i almindeligt sprog.',
    ],
    examples: [
      'Hvor er mine nøgler? 2. hus.',
      'Hvor er min kones tørklæde? 8. hus, fordi det er 2. fra 7.',
      'Hvor er mit barns jakke? Barn = 5. hus, barnets ejendel = 2. fra 5. = 6. hus.',
    ],
  ),
  _LearnSection(
    icon: Icons.emoji_events_outlined,
    title: '11. Sport, konkurrence og titler',
    subtitle: 'Skel mellem duel, hold og mesterskab',
    paragraphs: [
      'Ved en konkret duel kan 1. hus vise spørgerens/først nævnte side og 7. hus modstanderen. Ved et åbent spørgsmål om titel, pokal eller verdensmester er 10. hus centralt, fordi det viser sejr, ære og offentlig titel.',
      'Derfor bør "Hvem vinder VM?" pege på 10. hus, mens "Vinder Danmark over Tyskland?" typisk bruger 1./7. hus.',
    ],
    examples: [
      'Hvem vinder VM? 10. hus.',
      'Hvem bliver verdensmester? 10. hus.',
      'Vinder Danmark over Tyskland? Danmark = 1. hus, Tyskland = 7. hus.',
    ],
  ),
  _LearnSection(
    icon: Icons.fact_check_outlined,
    title: '12. Sådan læses appens resultat',
    subtitle: 'Fra AI-svar til tekniske detaljer',
    paragraphs: [
      'Konklusion viser det korte AI-formulerede svar. Detaljer viser de klassiske regler bag svaret: husvalg, signifikatorer, score, faktorer, særlige regler og noter.',
      'Studie-journalen gør det muligt at gemme spørgsmålet, AI-svaret og den tekniske tydning, så du senere kan kontrollere om reglen og udfaldet passede.',
    ],
    examples: [
      'Læs først Konklusion for almindeligt svar.',
      'Læs derefter Detaljer for hvorfor appen nåede frem til svaret.',
      'Gem i Studie-journal, når spørgsmålet er vigtigt eller godt som eksempel.',
    ],
  ),
];
