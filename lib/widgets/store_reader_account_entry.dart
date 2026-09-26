import 'package:flutter/material.dart';

import '../pages/account/store_reader_unlock_page.dart';
import '../services/account/account.dart';
import '../utils/localization_extension.dart';

/// A store purchase remains available independently of the Origo login form.
class StoreReaderAccountEntry extends StatelessWidget {
  const StoreReaderAccountEntry({super.key, required this.account});

  final MemberAccountController account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          account.hasPermanentReaderAccess
              ? Icons.verified_rounded
              : Icons.menu_book_rounded,
        ),
        title: Text(context.l10n.storeReaderLicenseTitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => StoreReaderUnlockPage(account: account),
          ),
        ),
      ),
    );
  }
}
