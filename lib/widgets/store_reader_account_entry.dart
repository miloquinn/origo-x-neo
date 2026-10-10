import 'package:flutter/material.dart';

import '../pages/account/store_reader_unlock_page.dart';
import '../services/account/account.dart';
import '../utils/localization_extension.dart';
import 'glass_surface.dart';

/// Shows the store offer; purchasing and restoring require an Origo login.
class StoreReaderAccountEntry extends StatelessWidget {
  const StoreReaderAccountEntry({super.key, required this.account});

  final MemberAccountController account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      role: GlassSurfaceRole.control,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          minTileHeight: 56,
          leading: Icon(
            account.permanentReaderFeaturesForDisplay
                ? Icons.verified_rounded
                : Icons.menu_book_rounded,
            color: scheme.primary,
          ),
          title: Text(context.l10n.storeReaderLicenseTitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => StoreReaderUnlockPage(account: account),
            ),
          ),
        ),
      ),
    );
  }
}
