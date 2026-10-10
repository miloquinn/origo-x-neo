import 'package:flutter/foundation.dart';

void registerLicenseFixture() {
  LicenseRegistry.addLicense(() async* {
    yield const _FixtureLicense(
      ['zz_fixture_a', 'zz_fixture_b'],
      [
        LicenseParagraph(
          'Shared notice heading',
          LicenseParagraph.centeredIndent,
        ),
        LicenseParagraph('Shared copyright and permission clause', 0),
        LicenseParagraph('Indented license clause', 1),
        LicenseParagraph('Final shared warranty clause', 0),
      ],
    );
    yield const _FixtureLicense(
      ['zz_fixture_a'],
      [LicenseParagraph('Second independent notice retained', 0)],
    );
  });
}

class _FixtureLicense extends LicenseEntry {
  const _FixtureLicense(this.packages, this.paragraphs);
  @override
  final List<String> packages;
  @override
  final List<LicenseParagraph> paragraphs;
}
