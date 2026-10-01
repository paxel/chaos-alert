import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

const _repoUrl = 'https://github.com/paxel/chaos-alert';
const _issuesUrl = '$_repoUrl/issues';
const _feedbackMail = 'taum@tuta.io';
const _donateUrl = 'https://ko-fi.com/paxel7';

/// Who made the app, where its source lives, how to reach the developer,
/// and the licences.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, this.version});

  /// The version to show; read from the platform when null.
  final Future<PackageInfo>? version;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _version =
      widget.version ?? PackageInfo.fromPlatform();

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Exception {
      // No app for the link; the entry simply does nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.about)),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const Center(child: Icon(Icons.alarm, size: 64)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              t.appTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: _version,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(
                  info == null
                      ? ''
                      : t.versionLabel(info.version, info.buildNumber),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(t.aboutTagline, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(t.sourceCode),
            subtitle: const Text('$_repoUrl — Apache-2.0 / MIT'),
            onTap: () => _open(_repoUrl),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(t.reportProblemOrIdea),
            subtitle: Text(t.githubIssues),
            onTap: () => _open(_issuesUrl),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t.writeTheDeveloper),
            subtitle: const Text(_feedbackMail),
            onTap: () =>
                _open('mailto:$_feedbackMail?subject=chaos-alert%20feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.coffee_outlined),
            title: Text(t.buyCoffee),
            subtitle: Text(t.coffeeSubtitle),
            onTap: () => _open(_donateUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(t.openSourceLicenses),
            onTap: () =>
                showLicensePage(context: context, applicationName: t.appTitle),
          ),
          const SizedBox(height: 24),
          const Center(child: _DangerButton()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Unlabelled anywhere else, explained nowhere: a big red button that
/// says not to press it. Pressing it thanks the user. That is the
/// whole feature.
class _DangerButton extends StatelessWidget {
  const _DangerButton();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      width: 160,
      height: 160,
      child: Material(
        color: const Color(0xFFC62828),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF7F0000), width: 6),
        ),
        elevation: 8,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u{1F917}', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(
                    t.dangerThanks,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.doneLabel),
                ),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t.dangerButton,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
