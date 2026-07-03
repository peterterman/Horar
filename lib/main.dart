import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'sweph_loader/web_helper.dart' if (dart.library.ffi) 'sweph_loader/io_helper.dart';

import 'models/horary_models.dart';
import 'services/astro_calculator.dart';
import 'services/question_validator.dart';
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

  void _showHouseSystemDialog(BuildContext context) {
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hussystem'),
        content: const Text(
          'Horar bruger Regiomontanus i denne version.\n\n'
          'Valg af hussystem er reserveret til en senere version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
          'Horar beregner et horarisk kort ud fra spørgsmålets tidspunkt og spørgerens placering.',
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
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Hussystem'),
              subtitle: const Text('Regiomontanus nu – valg senere'),
              onTap: () => _showHouseSystemDialog(context),
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
            'Stil spørgsmålet, vælg det relevante hus. Tidspunktet sættes automatisk, når du trykker “Beregn horar”, medmindre du vælger manuelt tidspunkt.',
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
              onApplySuggestion: _applyHouseSuggestion,
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
          DropdownButtonFormField<HoraryQuestionType>(
            value: _questionType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Spørgsmålstype',
              border: OutlineInputBorder(),
            ),
            items: HoraryQuestionType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _autoUseQuestionSuggestion = false;
              _questionType = value ?? _questionType;
              if (_questionType != HoraryQuestionType.general) {
                _house = _questionType.defaultHouse;
              }
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _questionType.ruleHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _house,
            decoration: InputDecoration(
              labelText: _questionType == HoraryQuestionType.general
                  ? 'Spørgsmålet angår'
                  : 'Relevant hus (foreslået af spørgsmålstype)',
              border: const OutlineInputBorder(),
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
          const SizedBox(height: 16),
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
  final ValueChanged<HouseSuggestion> onApplySuggestion;

  const _QuestionValidationCard({
    required this.result,
    required this.autoUseSuggestion,
    required this.onApplySuggestion,
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
                        OutlinedButton(
                          onPressed: () => onApplySuggestion(s),
                          child: const Text('Brug'),
                        ),
                      ],
                    ),
                  )),
              Text(
                autoUseSuggestion
                    ? 'Auto-forslag er aktivt: dropdowns følger bedste forslag fra teksten.'
                    : 'Du har valgt manuelt. Tryk “Brug” for at følge forslaget igen.',
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

class HoraryResultScreen extends StatelessWidget {
  final HoraryChart chart;

  const HoraryResultScreen({super.key, required this.chart});

  String get _timeText {
    final date = chart.localTime;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const HorarMainDrawer(),
        appBar: AppBar(
          title: const Text('Horar-svar'),
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
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'Horoskop'),
              Tab(icon: Icon(Icons.notes), text: 'Detaljer'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConclusionTab(chart: chart, timeText: _timeText),
            _HoroscopeTab(chart: chart, timeText: _timeText),
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
  final String timeText;

  const _ConclusionTab({required this.chart, required this.timeText});

  List<WeightedJudgementFactor> get _topFactors {
    final factors = [...chart.weightedFactors]
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));
    return factors.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topFactors = _topFactors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$timeText – ${chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
        if (chart.question.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Spørgsmål: ${chart.question}'),
        ],
        const SizedBox(height: 16),
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
                if (topFactors.isEmpty)
                  const Text('Ingen vægtede faktorer er beregnet endnu.')
                else
                  ...topFactors.map((factor) => Padding(
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
                const SizedBox(height: 6),
                Text("Måne: ${chart.moonVoidOfCourse ? 'void-of-course' : 'har videre aspekt'}${chart.moonViaCombusta ? ' · via combusta' : ''}"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HoroscopeTab extends StatelessWidget {
  final HoraryChart chart;
  final String timeText;

  const _HoroscopeTab({required this.chart, required this.timeText});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Horarhjulet må gerne være større end telefonens skærmbredde.
    // Derfor lægges det i vandret scroll, så symboler og grader bliver lettere at læse.
    final wheelSize = (screenWidth * 1.45).clamp(560.0, 820.0).toDouble();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$timeText – ${chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
              if (chart.question.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Spørgsmål: ${chart.question}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Horoskoptegning – træk sidelæns for at se hele hjulet',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 8),
                Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: wheelSize,
                      height: wheelSize,
                      child: ZodiacWheel(chart: chart),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$timeText – ${chart.location.name}', style: Theme.of(context).textTheme.titleMedium),
        if (chart.question.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Spørgsmål: ${chart.question}'),
        ],
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
