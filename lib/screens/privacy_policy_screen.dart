import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// In-app privacy policy (content adapted from ForgeTech policy structure for CarTrack).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'CarTrack Privacy Policy',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Operated by ForgeTech\nEffective date: September 8, 2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _p(context,
              'This Privacy Policy describes how ForgeTech (“we,” “us,” or “our”) handles information when you use the CarTrack mobile application (the “Application”).'),
          _p(context,
              'CarTrack is designed as a local-first app. Your vehicle logs, expenses, reminders, and preferences are stored on your device. Optional backup lets you export a file you can save to Google Drive or another location you choose.'),
          _h('1. Information we store'),
          _p(context,
              'Information you enter in the Application may include vehicle details, mileage, fuel and service logs, expenses, income entries, reminders, notes, and app preferences (currency, units, reminder settings).'),
          _p(context,
              'This information is stored locally on your device. We do not require an account to use core features.'),
          _h('2. Backup to Google Drive'),
          _p(context,
              'If you use Backup & export, the Application creates a full JSON backup of your vehicles, logs, reminders, and preferences on your device, then opens the system share sheet. Choose Google Drive to upload that file. Restore lets you pick the same backup file from Google Drive or Files and replace local data after confirmation. We do not receive your Google password or access your full Drive.'),
          _h('3. Information we do not collect'),
          _p(context,
              'We do not intentionally collect precise GPS location, contacts, microphone/camera recordings for core logging, SMS content, or advertising identifiers for third-party ads in the Application’s local-first mode.'),
          _h('4. How we use information'),
          _p(context,
              'Local data is used only to provide CarTrack features on your device (tracking, reminders, reports, and backup export).'),
          _h('5. Sharing'),
          _p(context,
              'We do not sell your personal information. Data leaves your device only when you explicitly share or back up a file using your device’s share sheet or a service you select.'),
          _h('6. Data retention & deletion'),
          _p(context,
              'Local data remains until you delete it in the app, clear app storage, or uninstall the Application. Backup copies stored in Google Drive remain under your control in that account.'),
          _h('7. Children’s privacy'),
          _p(context,
              'The Application is not directed to children under 13. We do not knowingly collect personal information from children.'),
          _h('8. Changes'),
          _p(context,
              'We may update this Policy from time to time. The effective date above will be revised when changes are posted.'),
          _h('9. Contact'),
          _p(context,
              'Questions about this Policy: privacy@forgetech.dev (or your ForgeTech support email).'),
        ],
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          t,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      );

  Widget _p(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: Theme.of(context).textTheme.bodyMedium),
      );
}
