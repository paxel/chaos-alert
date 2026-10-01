import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

void main() {
  runApp(const ChaosAlertApp());
}

class ChaosAlertApp extends StatelessWidget {
  const ChaosAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
        ),
      ),
    );
  }
}
