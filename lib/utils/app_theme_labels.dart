import '../l10n/app_localizations.dart';

String appColorPresetName(AppLocalizations l10n, String? id) => switch (id) {
  'blue' => l10n.settingsThemeColorBlue,
  'forest' => l10n.settingsThemeColorForest,
  'amber' => l10n.settingsThemeColorAmber,
  'rose' => l10n.settingsThemeColorRose,
  'violet' => l10n.settingsThemeColorViolet,
  'graphite' => l10n.settingsThemeColorGraphite,
  _ => l10n.settingsThemeOriginalColor,
};

String appSkinName(AppLocalizations l10n, String id) => switch (id) {
  'tidal' => l10n.settingsThemeSkinTidal,
  'botanical' => l10n.settingsThemeSkinBotanical,
  'celestial' => l10n.settingsThemeSkinCelestial,
  _ => l10n.settingsThemeSkinOriginal,
};

String appSkinDescription(AppLocalizations l10n, String id) => switch (id) {
  'tidal' => l10n.settingsThemeSkinTidalHint,
  'botanical' => l10n.settingsThemeSkinBotanicalHint,
  'celestial' => l10n.settingsThemeSkinCelestialHint,
  _ => l10n.settingsThemeSkinOriginalHint,
};
