# Horar Flutter Starter v16

Denne version bygger videre på v15 og tilføjer validering af brugerens spørgsmål.

## Nyt i v16

- Spørgsmålet vurderes mens brugeren skriver.
- Knappen **Beregn horar** er kun aktiv, når spørgsmålet ligner et brugbart horarisk spørgsmål.
- Appen advarer hvis spørgsmålet er for kort, for bredt eller ser ud til at rumme flere spørgsmål.
- Appen foreslår automatisk relevant hus og spørgsmålstype ud fra nøgleord i teksten.
- Brugeren kan trykke **Brug** ved et forslag, eller vælge hus/type manuelt.
- Hvis brugeren vælger manuelt, stopper auto-forslag, indtil et forslag bruges igen.

Eksempler:

- “Får jeg jobbet?” → 10. hus – Job
- “Kommer han tilbage til mig?” → 7. hus – Kærlighed/relation
- “Hvor er min telefon?” → 2. hus – Tabte ting
- “Består jeg eksamen?” → 9. hus – Eksamen
- “Vinder jeg retssagen?” → 7./10. hus – Retssag

## Kopiering

```bash
cd ~/horar_flutter
cp -r /sti/til/horar_flutter_starter_v16/lib .
cp /sti/til/horar_flutter_starter_v16/pubspec.yaml .

flutter clean
flutter pub get
flutter run
```

