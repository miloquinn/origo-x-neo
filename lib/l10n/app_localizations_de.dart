// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Start';

  @override
  String get library => 'Bücherregal';

  @override
  String get bookSources => 'Quellen';

  @override
  String get discover => 'Entdecken';

  @override
  String get discoverRecommended => 'Für dich';

  @override
  String get discoverCategories => 'Kategorien';

  @override
  String get discoverLatest => 'Neuheiten';

  @override
  String get discoverLoadFailed =>
      'Entdecken-Inhalte konnten nicht geladen werden';

  @override
  String get discoverRetry => 'Erneut versuchen';

  @override
  String get discoverEmptyTitle => 'Noch nichts zu sehen';

  @override
  String get discoverEmptyMessage => 'Dieser Bereich hat noch keinen Inhalt.';

  @override
  String get discoverUnsupportedTitle =>
      'Die aktuellen Quellen unterstützen diesen Bereich nicht';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'Eine Quelle mit der Funktion $capability ist erforderlich. Vorhandene Quellen können weiterhin durchsucht werden.';
  }

  @override
  String get discoverCategoryEmpty =>
      'In dieser Kategorie gibt es noch keine Bücher.';

  @override
  String get bookSourceChannelLoadFailed => 'Kanal konnte nicht geladen werden';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'Die Quelle lieferte keine verwertbaren Bücher: $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'Nach dem Durchprobieren der verfügbaren Netzwerkadressen konnte keine Verbindung zum Quellserver hergestellt werden. Versuche es später erneut.';

  @override
  String get bookSourceRedirectFailed =>
      'Die Quellseite hat immer wieder umgeleitet. Die Cookies der Seite wurden behalten, aber die Adresse lieferte weiterhin keinen Inhalt.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'Die Quellseite hat HTTP $status zurückgegeben. Die Kanaladresse ist möglicherweise veraltet oder wird von der Seite blockiert.';
  }

  @override
  String get bookSourceStandardLayout => 'Standardlayout';

  @override
  String get bookSourceListLayout => 'Listenlayout';

  @override
  String get bookSourceChangeChannel => 'Wechseln';

  @override
  String get bookSourceChangeSourceTitle => 'Quelle wechseln';

  @override
  String get bookSourceChangeCurrentSource => 'Aktuelle Quelle';

  @override
  String get bookSourceChangeTargetSource => 'Wechseln zu';

  @override
  String get bookSourceChangeNotSelected => 'Nicht ausgewählt';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'Aktuell bei Kapitel $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Dieses Buch in anderen Quellen finden';

  @override
  String get bookSourceChangeSearchAgain => 'Erneut suchen';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Alle übrigen Quellen durchsuchen';

  @override
  String get bookSourceChangeCheckAuthor => 'Autor abgleichen';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return '$completed von $total geprüft';
  }

  @override
  String get bookSourceChangeNoOtherSources =>
      'Keine weiteren Quellen verfügbar';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Füge zuerst eine weitere Quelle hinzu, die Suche unterstützt, und aktiviere sie.';

  @override
  String get bookSourceChangeSearching => 'Suche weitere Quellen';

  @override
  String get bookSourceChangeSearchingHint =>
      'Treffer erscheinen, sobald eine Quelle die Suche abgeschlossen hat.';

  @override
  String get bookSourceChangeNoMatches => 'Keine passenden Quellen gefunden';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Ändere den Titel oder deaktiviere den Autor-Abgleich und suche dann erneut.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return '$count Quellenanfrage(n) fehlgeschlagen. Du kannst erneut suchen.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Anderer Autor';

  @override
  String get bookSourceChangeValidating =>
      'Katalog und aktuelles Kapitel werden geprüft…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Prüfung fehlgeschlagen: $details';
  }

  @override
  String get bookSourceChangeReadable => 'Aktuelles Kapitel lesbar';

  @override
  String bookSourceChangeChapterCount(int count) {
    return '$count Kapitel';
  }

  @override
  String bookSourceChangeResponseTime(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get bookSourceChangeTapToValidate =>
      'Zum Prüfen von Katalog und aktuellem Kapitel auswählen.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Diese Quellversion ist bereits im Bücherregal.';

  @override
  String get bookSourceChangeSwitching => 'Quelle wird gewechselt…';

  @override
  String get bookSourceChangeSwitchAction => 'Zu dieser Quelle wechseln';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Quelle zu $source gewechselt';
  }

  @override
  String get bookSourceChangeConfirmTitle => 'Confirm source change';

  @override
  String bookSourceChangeQuickProgress(int completed, int batch, int total) {
    return 'Quick search: $completed/$batch · $total sources available';
  }

  @override
  String get bookSourceChangeStopSearch => 'Stop searching';

  @override
  String get bookSourceChangeLoadFailed => 'Could not load sources';

  @override
  String get bookSourceChangeLoadFailedHint =>
      'Check your connection and try again.';

  @override
  String get bookSourceChangeChecking => 'Checking this source';

  @override
  String get bookSourceChangeCheckingPosition =>
      'Reading your current position…';

  @override
  String get bookSourceChangeCheckingDetail => 'Loading book details…';

  @override
  String get bookSourceChangeCheckingCatalog => 'Loading the chapter list…';

  @override
  String get bookSourceChangeCheckingContent => 'Checking the current chapter…';

  @override
  String get bookSourceChangeSlow =>
      'This source is responding slowly. You can cancel and try another.';

  @override
  String get bookSourceChangeCheckTimedOut =>
      'The check timed out. Try again or choose another source.';

  @override
  String get bookSourceChangeCheckFailed =>
      'Could not verify this source. Try again or choose another.';

  @override
  String get bookSourceChangeCommitFailed =>
      'Could not finish changing the source. Check your bookshelf before retrying.';

  @override
  String get bookSourceChangeReaderOpenFailed =>
      'The source changed, but this chapter could not be opened. Try again or return to your bookshelf.';

  @override
  String get bookSourceChangeReadingPosition => 'Reading position';

  @override
  String bookSourceChangeOriginalChapter(int number, String title) {
    return 'Current: chapter $number · $title';
  }

  @override
  String bookSourceChangeNewChapter(int number, String title) {
    return 'New: chapter $number · $title';
  }

  @override
  String get bookSourceChangeMappingTitle => 'Matched by chapter title';

  @override
  String get bookSourceChangeMappingNumber =>
      'Matched by chapter number; please check the position';

  @override
  String get bookSourceChangeMappingManual => 'Chapter chosen by you';

  @override
  String get bookSourceChangeMappingEstimate =>
      'Estimated from chapter position';

  @override
  String get bookSourceChangeMappingNeedsChoice =>
      'Check the chapter before switching; the estimate may be wrong.';

  @override
  String get bookSourceChangePositionUnavailable =>
      'Your previous reading position is unavailable. Choose the chapter to open.';

  @override
  String get bookSourceChangeChooseChapter => 'Choose a chapter';

  @override
  String get bookSourceChangeLocalImpact =>
      'Your downloaded text and reading position stay unchanged. Only the source for future updates changes.';

  @override
  String get bookSourceChangeOnlineImpact =>
      'The bookshelf source and reading position will change. Your old source position remains saved.';

  @override
  String bookSourceChangeConfirmAction(String source) {
    return 'Change to $source';
  }

  @override
  String bookSourceChannelCount(int count) {
    return '$count Kanäle';
  }

  @override
  String get bookSourceManagementTitle => 'Quellen verwalten';

  @override
  String get bookSourceManagementSubtitle =>
      'Inhaltsanbieter hinzufügen, aktivieren, entfernen und prüfen. Entdecken bleibt aufs Bücherfinden konzentriert.';

  @override
  String get settingsContentSourcesTitle => 'Inhaltsquellen';

  @override
  String get settingsContentSourcesSubtitle =>
      'Offene Buchquellen hinzufügen, aktivieren oder entfernen';

  @override
  String get bookSourcesSubtitle =>
      'Offene Quellen verbinden und über Anbieter hinweg lesbare Inhalte durchsuchen';

  @override
  String get bookSourcesAdd => 'Quelle hinzufügen';

  @override
  String get bookSourcesSearchHint =>
      'Aktivierte Quellen nach Titel oder Autor durchsuchen';

  @override
  String get bookSourcesSearch => 'Suchen';

  @override
  String get bookSourcesLoadMore => 'Mehr laden';

  @override
  String bookSourcesFailedCount(int count) {
    return '$count Quellenanfrage(n) fehlgeschlagen';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Sucheinstellungen';

  @override
  String get bookSourcesSearchSettingsTitle => 'Sucheinstellungen';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Gleichzeitige Anfragen';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Zeitlimit pro Quelle (s)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Quellenlimit';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Wenn viele Quellen aktiviert sind, werden nur so viele gleichzeitig durchsucht (in Listenreihenfolge), um Netzwerk und Akku zu schonen.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return '$enabledCount Quellen sind aktiviert, über dem aktuellen Limit von $limit. Quellen über dem Limit werden nicht durchsucht.';
  }

  @override
  String get bookSourcesSearchResetDefaults => 'Auf Standardwerte zurücksetzen';

  @override
  String get bookSourcesSearchPrompt =>
      'Füge eine Quelle hinzu und aktiviere sie, um sie hier zu durchsuchen';

  @override
  String get bookSourcesNoResults => 'Keine passenden Bücher gefunden';

  @override
  String get bookSourcesNoSourcesTitle => 'Noch keine Quellen';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Füge die Adresse eines Dienstes ein, der mit dem Origo Source Protocol kompatibel ist.';

  @override
  String get bookSourcesManageTitle => 'Verbundene Quellen';

  @override
  String get bookSourcesEnabled => 'Aktiviert';

  @override
  String get bookSourcesDisabled => 'Deaktiviert';

  @override
  String get bookSourcesRunnable => 'Einsatzbereit';

  @override
  String get bookSourcesPendingCompatibility => 'Keine ausführbaren Regeln';

  @override
  String get bookSourcesRequiresLogin => 'Anmeldung erforderlich';

  @override
  String get bookSourcesManagementSearchHint =>
      'Name, URL, Notizen oder Gruppe durchsuchen';

  @override
  String get bookSourcesClearSearch => 'Suche löschen';

  @override
  String get bookSourcesAllGroups => 'Alle Gruppen';

  @override
  String get bookSourcesChooseGroup => 'Quellengruppe wählen';

  @override
  String get bookSourcesSearchGroups => 'Gruppen durchsuchen';

  @override
  String get bookSourcesNoMatchingSources =>
      'Keine Quellen entsprechen der aktuellen Suche und den Filtern';

  @override
  String get bookSourcesResetFilters => 'Zurücksetzen';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return '$visible von $total werden angezeigt';
  }

  @override
  String get bookSourcesRemove => 'Entfernen';

  @override
  String get bookSourcesRemoveTitle => 'Quelle entfernen';

  @override
  String get bookSourcesRemoveMessage =>
      'Dies entfernt nur die Quellkonfiguration. Lokale Bücher bleiben unberührt.';

  @override
  String get bookSourcesCancel => 'Abbrechen';

  @override
  String get bookSourcesConfirm => 'Bestätigen';

  @override
  String get bookSourcesAddTitle => 'Quelle hinzufügen';

  @override
  String get bookSourcesImportLink => 'Link importieren';

  @override
  String get bookSourcesAnalyze => 'Quellen lesen';

  @override
  String get bookSourcesDetectedOrsp => 'Erkannt: ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Erkannt: Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'ORSP-Quellen';

  @override
  String get bookSourcesProtocolGroupAdditional => 'Quellen anderer Protokolle';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Diese Quelle ist für das aktuelle Konto oder die aktuellen Einstellungen nicht verfügbar.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Keine Quelle hat die Live-Suchprüfung bestanden. Es wurde nichts importiert.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return '$completed/$total geprüft; $available funktionsfähig';
  }

  @override
  String get bookSourcesSelect => 'Quellen auswählen';

  @override
  String get bookSourcesSelectAll => 'Alle auswählen';

  @override
  String get bookSourcesClearSelection => 'Auswahl aufheben';

  @override
  String get bookSourcesEnableSelected => 'Ausgewählte aktivieren';

  @override
  String get bookSourcesDisableSelected => 'Ausgewählte deaktivieren';

  @override
  String get bookSourcesExportSelected => 'Ausgewählte exportieren';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return '$count Quelle(n) nach $location exportiert';
  }

  @override
  String get bookSourcesExportFailed =>
      'Ausgewählte Quellen konnten nicht exportiert werden';

  @override
  String get bookSourcesExportUnsupported =>
      'Quellenexport wird auf dieser Plattform noch nicht unterstützt';

  @override
  String get bookSourcesExportReplaceTitle => 'Vorhandene Datei ersetzen?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Unter $path existiert bereits eine Datei. Ersetzen?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Ersetzen';

  @override
  String get bookSourcesDeleteSelected => 'Ausgewählte löschen';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return '$count ausgewählte Quellen löschen? Lokale Bücher bleiben unberührt.';
  }

  @override
  String get bookSourcesCheckSelected => 'Ausgewählte prüfen';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return '$healthy von $total Quelle(n) sind fehlerfrei';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Quellen prüfen & aufräumen';

  @override
  String get bookSourcesCleanupNoCheckableSources => 'Keine Quellen zu prüfen';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Alle $count geprüften Quellen sind vollständig verfügbar';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Zustandsergebnisse';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return '$fullyAvailable vollständig verfügbar · $needsAttention zu prüfen';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Fehlende Funktionen oder ein Timeout bedeuten nicht, dass eine Quelle unbrauchbar ist. Wähle nur die Quellen aus, die du deaktivieren möchtest.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return '$count ausgewählte deaktivieren';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return '$count Quelle(n) deaktiviert';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Gestoppt — $count Quelle(n) geprüft. Führe die Prüfung später erneut aus, um fortzufahren.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Quellenwartung';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Duplikate finden und Quellenverfügbarkeit prüfen';

  @override
  String get bookSourcesMaintenanceHealthTitle => 'Quellenzustandsprüfung';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Suche und Lesen testen; kürzliche fehlerfreie Ergebnisse wiederverwenden';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Quellenzustandsprüfung läuft';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Duplikate bereinigen';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Quellen lokal vergleichen, kein Netzwerk nötig';

  @override
  String get bookSourcesMaintenanceReviewTitle => 'Letztes Prüfergebnis';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return '$count Quelle(n) brauchen Aufmerksamkeit';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Nur Quellen, die du bestätigst, werden deaktiviert. Ihre Konfigurationen bleiben erhalten.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Quellen werden geprüft';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Suche, Details, Kataloge und Inhalte werden geprüft';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Quellenzustandsprüfung abgeschlossen';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return '$checked Quelle(n) geprüft; $attention brauchen Aufmerksamkeit';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Prüfung stoppen';

  @override
  String get bookSourcesMaintenanceBackground => 'Im Hintergrund fortfahren';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Schließe diese Fortschrittsansicht; die Prüfung läuft still weiter, solange die App geöffnet ist.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'Die Quellenzustandsprüfung läuft still im Hintergrund weiter';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Ergebnisse ansehen';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Quellenwartung $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Doppelte Quellen finden';

  @override
  String get bookSourcesDedupeNone => 'Keine doppelten Quellen gefunden';

  @override
  String get bookSourcesDedupeReviewTitle => 'Doppelte Quellen prüfen';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return '$groups Gruppe(n), $duplicates doppelte Quelle(n)';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'Die empfohlene Quelle bleibt erhalten. Ausgewählte Duplikate werden deaktiviert, nicht gelöscht.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return '$count ausgewählte deaktivieren';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return '$count doppelte Quelle(n) deaktiviert';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Exakt';

  @override
  String get bookSourcesDedupeModeStandard => 'Standard';

  @override
  String get bookSourcesDedupeModeSite => 'Gleiche Seite';

  @override
  String get bookSourcesDedupeExactReason => 'Gleiche Quellenidentität';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Gleiche normalisierte Quellenadresse';

  @override
  String get bookSourcesDedupeSiteReason =>
      'Gleiche Seite; Prüfung erforderlich';

  @override
  String get bookSourcesDedupeRecommended => 'Empfohlen';

  @override
  String get bookSourcesDedupeReviewAction => 'Deduplizierung ansehen';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return '$ready bereit, $duplicates doppelt, $errors ungültig';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return '$books Buch · $comics Comic · $unsupported derzeit nicht ausführbar';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults =>
      'Empfehlungen wiederherstellen';

  @override
  String get bookSourcesUrlLabel => 'Quellenadresse';

  @override
  String get bookSourcesUrlHint =>
      'https://example.com oder eine Quellen-JSON-URL';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'Origo X enthält keine Quellen und betreibt, empfiehlt oder unterstützt keine Quellendienste Dritter. Jede Quellenadresse fügst du selbst hinzu.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Ich bestätige, dass ich berechtigt bin, auf diese Inhalte zuzugreifen, und die Quelle nicht dazu verwenden werde, Anmeldungen, Zahlungen, DRM oder andere Zugriffskontrollen zu umgehen.';

  @override
  String get bookSourcesConnect => 'Lesen und importieren';

  @override
  String get bookSourcesConnecting => 'Quellen werden verarbeitet…';

  @override
  String get bookSourcesAdded => 'Quelle hinzugefügt';

  @override
  String get bookSourcesRefresh => 'Quelle aktualisieren';

  @override
  String get bookSourcesRefreshed => 'Buchquelle aktualisiert';

  @override
  String get bookSourcesRefreshFailed =>
      'Diese Buchquelle konnte nicht aktualisiert werden';

  @override
  String get bookSourcesProtocolTitle => 'Origo Source Protocol';

  @override
  String get bookSourcesInformationTitle => 'Protokoll & Informationen';

  @override
  String get bookSourcesInformationSubtitle =>
      'Protokoll, Projektlinks und Rechteinformationen ansehen';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'Erfahre mehr über unterstützte Quellenfunktionen und das offene Protokoll';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Protokoll-Repository auf GitHub ansehen';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'Inhalte und Rechtegrenzen von Drittanbietern verstehen';

  @override
  String get bookSourcesProtocolDescription =>
      'Ein gemeinsamer Vertrag für Entdecken, Suche, Buchdetails, Kataloge und Kapitelinhalte. Entwickler können eigene Quellen hosten oder Adapter für Inhalte erstellen, zu deren Bereitstellung sie berechtigt sind.';

  @override
  String get bookSourcesProtocolDetails => 'Protokoll ansehen';

  @override
  String get bookSourcesProtocolRepository => 'Protokoll-Repository';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Auf GitHub ansehen';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'Protokoll-Repository konnte nicht geöffnet werden';

  @override
  String get bookSourcesProtocolDialogTitle => 'Offenes Quellenprotokoll v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Eine Quelle veröffentlicht /.well-known/open-reading-source.json und implementiert die Kern-Lesefähigkeiten: Suche, Buchdetails, paginierte Kapitelkataloge und Kapitelinhalte. Version 1.4 behält die vollständige Katalog-Paginierung bei, setzt diese Kernfähigkeiten voraus und bewahrt Betreiber-, Kontakt-, Lizenz- und Rechteangaben für öffentliche HTTP(S)-Quellen ohne Anmeldepflicht.';

  @override
  String get bookSourcesRightsDetails => 'Betreiber und Rechte';

  @override
  String get bookSourcesOperator => 'Quellenbetreiber';

  @override
  String get bookSourcesContentLicense => 'Inhaltslizenz';

  @override
  String get bookSourcesRightsStatement => 'Rechteerklärung';

  @override
  String get bookSourcesRightsNotProvided =>
      'Von dieser Quelle nicht angegeben';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Diese Angaben stammen vom unabhängigen Quellenbetreiber. Origo X zeigt sie zur Transparenz an, überprüft oder empfiehlt sie aber nicht.';

  @override
  String get bookSourcesContactOperator => 'Betreiber kontaktieren';

  @override
  String get bookSourcesRightsReport => 'Rechtebericht';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'Das Rechtebericht-Formular konnte nicht geöffnet werden';

  @override
  String get bookSourcesClose => 'Schließen';

  @override
  String get sourceLoginTitle => 'Quellenanmeldung';

  @override
  String get sourceLoginInfo => 'Anmeldedaten';

  @override
  String get sourceLoginActions => 'Quellenaktionen';

  @override
  String get sourceLoginExtraSettings => 'Zusätzliche Einstellungen';

  @override
  String get sourceLoginSecureStorageNotice =>
      'Anmeldedaten bleiben im sicheren Systemspeicher dieses Geräts.';

  @override
  String get sourceLoginNoForm =>
      'Diese Quelle bietet keine verfügbare Anmeldemethode.';

  @override
  String get sourceLoginBrowserTitle => 'Auf der Original-Website anmelden';

  @override
  String get sourceLoginBrowserNotice =>
      'Schließe die Anmeldung im Browser ab und tippe dann auf „Fertig“. Cookies und der lokale Speicher der Website werden auf diesem Gerät gespeichert.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'Die Website-Anmeldung ist auf Android, iPhone, iPad und Mac verfügbar.';

  @override
  String get sourceLoginBrowserOpen => 'Website zum Anmelden öffnen';

  @override
  String get sourceLoginSave => 'Anmelden und Sitzung speichern';

  @override
  String get sourceLoginClear => 'Anmeldesitzung löschen';

  @override
  String get sourceLoginSaved => 'Quellen-Anmeldesitzung aktualisiert';

  @override
  String get sourceLoginCleared => 'Quellen-Anmeldesitzung gelöscht';

  @override
  String sourceLoginFailed(String details) {
    return 'Quellen-Anmeldesitzung konnte nicht aktualisiert werden: $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '„$sourceName“ bietet eine Anmeldung für reine Kontoinhalte.';
  }

  @override
  String get sourceDebugMenuLabel => 'Debuggen';

  @override
  String get sourceDebugTitle => 'Quellen-Debugger';

  @override
  String get sourceDebugInputHint =>
      'Gib ein Suchwort ein oder füge eine Buch-, Katalog- oder Kapitel-URL ein';

  @override
  String get sourceDebugRun => 'Ausführen';

  @override
  String get sourceDebugStop => 'Stopp';

  @override
  String get sourceDebugClear => 'Protokoll löschen';

  @override
  String get sourceDebugEmpty =>
      'Gib ein Wort oder eine URL ein und tippe auf „Ausführen“, um Schritt für Schritt zu sehen, wie diese Quelle es auflöst.';

  @override
  String get sourceDebugCopy => 'Kopieren';

  @override
  String get sourceDebugCopied => 'In die Zwischenablage kopiert';

  @override
  String get sourceHealthMenuLabel => 'Zustand prüfen';

  @override
  String get sourceHealthHealthy => 'Fehlerfrei';

  @override
  String get sourceHealthPartial => 'Teilweise defekt';

  @override
  String get bookSourcesFullyAvailable => 'Vollständig verfügbar';

  @override
  String get sourceHealthTimedOut => 'Zeitüberschreitung bei der Prüfung';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Defekt: $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'Suche';

  @override
  String get sourceHealthCapabilityDiscover => 'Entdecken';

  @override
  String get sourceHealthCapabilityInfo => 'Buchdetails';

  @override
  String get sourceHealthCapabilityCatalog => 'Katalog';

  @override
  String get sourceHealthCapabilityContent => 'Inhalt';

  @override
  String get sourceVerificationTitle => 'Quellenüberprüfung';

  @override
  String get sourceVerificationBrowserHint =>
      'Schließe die Seitenprüfung im sicheren Browser ab und wähle dann „Überprüfung abgeschlossen“. Seitenadresse und Cookies fließen nur in diese Quellenaufgabe zurück.';

  @override
  String get sourceVerificationCodeHint =>
      'Lies das Bild ab und gib seinen Code ein, um diese Quellenaufgabe fortzusetzen.';

  @override
  String get sourceVerificationCodeLabel => 'Bildcode';

  @override
  String get sourceVerificationSubmit => 'Fortfahren';

  @override
  String get sourceVerificationRetry => 'Browser erneut öffnen';

  @override
  String get sourceVerificationCancel => 'Überprüfung abbrechen';

  @override
  String sourceVerificationFailed(String details) {
    return 'Quellenüberprüfung konnte nicht geöffnet werden: $details';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get statistics => 'Statistiken';

  @override
  String get reading => 'Lesen';

  @override
  String get importBooks => 'Bücher importieren';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get systemMode => 'System';

  @override
  String get theme => 'Design';

  @override
  String get accent => 'Akzentfarbe';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get notes => 'Notizen';

  @override
  String get highlights => 'Markierungen';

  @override
  String get ttsReading => 'Text-to-Speech';

  @override
  String get share => 'Teilen';

  @override
  String get shareContent => 'Inhalt teilen';

  @override
  String get shareCurrentPage => 'Aktuelle Seite teilen';

  @override
  String get shareSelectedText => 'Ausgewählten Text teilen';

  @override
  String get shareProgress => 'Lesefortschritt teilen';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stopp';

  @override
  String get speed => 'Geschwindigkeit';

  @override
  String get pitch => 'Tonhöhe';

  @override
  String get language => 'Sprache';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get readingProgress => 'Lesefortschritt';

  @override
  String get totalPages => 'Seiten gesamt';

  @override
  String get currentPage => 'Aktuelle Seite';

  @override
  String get readingTime => 'Lesezeit';

  @override
  String get booksRead => 'Gelesene Bücher';

  @override
  String get todayReading => 'Heutiges Lesen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Vorherige';

  @override
  String get search => 'Suchen';

  @override
  String get noResults => 'Keine Ergebnisse gefunden';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get error => 'Fehler';

  @override
  String get initializationFailed => 'Initialisierung fehlgeschlagen';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get appearanceSettings => 'Erscheinungsbild';

  @override
  String get readingTips => 'Lesetipps';

  @override
  String get readingFontSettingsMoved =>
      'Einstellungen der Leseschrift wurden verschoben';

  @override
  String get readingFontSettingsHint =>
      'Öffne ein beliebiges Buch, tippe auf die Bildschirmmitte und passe dann über die untere Symbolleiste Schriftgröße, Zeilenabstand, Zeichenabstand, Ränder und Leseschrift an.';

  @override
  String get readingSettings => 'Leseeinstellungen';

  @override
  String get enableTts => 'TTS aktivieren';

  @override
  String get enableTtsHint => 'Text-to-Speech-Vorlesen aktivieren';

  @override
  String get ttsSpeedLabel => 'Geschwindigkeit';

  @override
  String get ttsSpeedHint => 'Lesegeschwindigkeit anpassen';

  @override
  String get ttsVolumeLabel => 'Lautstärke';

  @override
  String get ttsVolumeHint => 'Vorleselautstärke anpassen';

  @override
  String get ttsPitchLabel => 'Tonhöhe';

  @override
  String get ttsPitchHint => 'Tonhöhe anpassen';

  @override
  String get appSettings => 'App-Einstellungen';

  @override
  String get appFont => 'App-Schriftart';

  @override
  String get appFontDescription =>
      'Wird von Navigation, Schaltflächen, Einstellungen und anderen Oberflächentexten verwendet. Buchinhalte werden nicht geändert.';

  @override
  String get readerFont => 'Leseschriftart';

  @override
  String get readerFontDescription =>
      'Für TXT und Online-Bücher. EPUB hat eine eigene Schrifteinstellung.';

  @override
  String get readerFontSelectionDescription =>
      'Leseschrift wählen. EPUB bietet die Buchschrift, die Systemschrift und installierte Schriften.';

  @override
  String get readerFontBookPriorityHint =>
      'Verwendet die eingebettete Schrift des Buchs, wenn verfügbar; andernfalls die plattformstandardmäßige Leseschrift.';

  @override
  String get readerFontOverrideHint =>
      'Überschreibt die vom Herausgeber eingebetteten Schriften.';

  @override
  String get fontBookEmbedded => 'Im Buch eingebettet';

  @override
  String get fontSystem => 'Plattform-Standard';

  @override
  String get fontSourceHanSerif => 'Source Han Serif';

  @override
  String get fontSourceHanSans => 'Source Han Sans';

  @override
  String get fontJetBrainsMono => 'JetBrains Mono';

  @override
  String get fontInstrumentSans => 'Instrument Sans';

  @override
  String get fontNewsreader => 'Newsreader';

  @override
  String get fontSystemDescription =>
      'Verwendet eine plattformoptimierte Leseschrift für stabile Zeichen und Seitenverteilung.';

  @override
  String get fontSerifDescription =>
      'Serifenschrift mit ruhigem, redaktionellem Charakter für längeres Lesen.';

  @override
  String get fontSansSerifDescription =>
      'Klare serifenlose Schrift für kompakte Oberflächen und alltägliches Lesen.';

  @override
  String get fontMonospaceDescription =>
      'Nichtproportionale Schrift für Code, technisches Material und fokussierte Layouts.';

  @override
  String get fontPreviewText => 'Origo X · Frei lesen 开卷有益';

  @override
  String get customFonts => 'Meine Schriften';

  @override
  String get customFontsEmpty => 'Noch keine eigenen Schriften';

  @override
  String get customFontsEmptyHint =>
      'Importiere einmal eine TTF- oder OTF-Datei und verwende sie dann für die App-Oberfläche oder zum Lesen.';

  @override
  String customFontsCount(int count) {
    return '$count importierte Schriften';
  }

  @override
  String get customFontsLocalOnly =>
      'Importierte Schriften werden nur auf diesem Gerät gespeichert und nicht automatisch synchronisiert.';

  @override
  String get builtInFonts => 'Integrierte Schriften';

  @override
  String get onlineFonts => 'Online-Schriften';

  @override
  String get fontDownload => 'Herunterladen';

  @override
  String get fontDownloading => 'Wird heruntergeladen…';

  @override
  String get fontDownloaded => 'Heruntergeladen';

  @override
  String get fontDownloadFailed =>
      'Download fehlgeschlagen, zum Wiederholen tippen';

  @override
  String get fontDownloadHint =>
      'Die erste Verwendung erfordert einen Online-Download';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Einstellbare Strichstärke $min–$max';
  }

  @override
  String get fontStaticWeight => 'Feste Strichstärke (Fett wird synthetisiert)';

  @override
  String get fontDeleteDownload => 'Download löschen';

  @override
  String fontDeleteDownloadTitle(String name) {
    return 'Heruntergeladene \"$name\" löschen?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Gibt $size Speicher frei. Wird bei der nächsten Verwendung erneut heruntergeladen.';
  }

  @override
  String get fontDownloadCancelled => 'Download abgebrochen';

  @override
  String get fontDownloadNetworkFailed =>
      'Netzwerkfehler, Download fehlgeschlagen';

  @override
  String get fontDownloadInvalid =>
      'Die heruntergeladene Schriftdatei ist ungültig';

  @override
  String get fontDownloadUnsupported =>
      'Der Online-Download von Schriften wird auf dieser Plattform nicht unterstützt';

  @override
  String get importFont => 'Schrift importieren';

  @override
  String get importingFont => 'Schrift wird importiert…';

  @override
  String get customFontImported => 'Schrift importiert';

  @override
  String get customFontAlreadyImported =>
      'Diese Schrift wurde bereits importiert und ist einsatzbereit';

  @override
  String get customFontApplied => 'Schriftauswahl aktualisiert';

  @override
  String get customFontAppliedToApp =>
      'Importiert und als App-Schriftart festgelegt';

  @override
  String get customFontAppliedToReader =>
      'Importiert und als Leseschriftart festgelegt';

  @override
  String get customFontImportUnsupported =>
      'Dauerhafter Schriftimport wird auf dieser Plattform noch nicht unterstützt.';

  @override
  String get customFontUnsupportedFormat =>
      'Wähle eine TTF- oder OTF-Schriftdatei.';

  @override
  String get customFontInvalid =>
      'Diese Datei ist keine gültige oder unterstützte Schrift.';

  @override
  String get customFontTooLarge => 'Die Schriftdatei ist größer als 50 MB.';

  @override
  String get customFontReadFailed =>
      'Die Schriftdatei konnte nicht gelesen werden.';

  @override
  String get customFontLoadFailed => 'Die Schrift konnte nicht geladen werden.';

  @override
  String get customFontStorageFailed =>
      'Die Schrift konnte nicht auf diesem Gerät gespeichert werden.';

  @override
  String get customFontUnavailable =>
      'Die Schriftdatei ist nicht verfügbar. Lösche sie und importiere sie erneut.';

  @override
  String get setAsAppFont => 'Als App-Schriftart verwenden';

  @override
  String get setAsReaderFont => 'Als Leseschriftart verwenden';

  @override
  String get setAsBothFonts => 'Für beide verwenden';

  @override
  String get renameFont => 'Schrift umbenennen';

  @override
  String deleteCustomFontTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteCustomFontMessage =>
      'Die Schriftdatei wird von diesem Gerät entfernt.';

  @override
  String get deleteCustomFontInUse =>
      'Diese Schrift ist gerade in Gebrauch. Wenn du sie löschst, werden die betroffenen Schrifteinstellungen auf die Standardwerte zurückgesetzt.';

  @override
  String get deleteAndReset => 'Löschen und zurücksetzen';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Offizieller Telegram-Kanal';

  @override
  String get settingsTelegramOpenFailed =>
      'Der Telegram-Link konnte nicht geöffnet werden';

  @override
  String get settingsQqChannel => 'QQ-Kanal';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'Der QQ-Kanal-Einladungslink konnte nicht geöffnet werden';

  @override
  String get languageSystem => 'Systemsprache folgen';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get typographySettings => 'Typografie';

  @override
  String get fontFamilyLabel => 'Schriftart';

  @override
  String get fontSizeLabel => 'Schriftgröße';

  @override
  String get readerFontWeightLabel => 'Schriftstärke';

  @override
  String get readerFontWeightLight => 'Leicht';

  @override
  String get readerFontWeightRegular => 'Normal';

  @override
  String get readerFontWeightMedium => 'Mittel';

  @override
  String get readerFontWeightSemiBold => 'Halbfett';

  @override
  String get readerFontWeightBold => 'Fett';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'Die Lesesteuerung nutzt fünf gut lesbare Stufen von 300–700. Der tatsächliche volle Bereich dieser Schrift ist $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'Die Lesesteuerung nutzt fünf Stufen von 300–700. Diese Schrift hat keine deklarierte variable Strichstärkenachse, daher nähert das System das Ergebnis an; es kann je nach Plattform abweichen.';

  @override
  String get readerFontWeightPreview => 'Eine stille Seite trägt weiter · 字里行间';

  @override
  String get lineSpacingLabel => 'Zeilenabstand';

  @override
  String get letterSpacingLabel => 'Zeichenabstand';

  @override
  String get textAlignmentLabel => 'Textausrichtung';

  @override
  String get textAlignmentNatural => 'Natürlich';

  @override
  String get textAlignmentJustified => 'Blocksatz';

  @override
  String get firstLineIndentLabel => 'Erstzeileneinzug';

  @override
  String get paragraphSpacingLabel => 'Absatzabstand';

  @override
  String get pageMarginLabel => 'Seitenrand';

  @override
  String get resetDefault => 'Zurücksetzen';

  @override
  String get ttsPanelTitle => 'Text-to-Speech';

  @override
  String get ttsPreviewEffect => 'Effektvorschau';

  @override
  String get ttsVolume => 'Lautstärke';

  @override
  String get ttsPitch => 'Tonhöhe';

  @override
  String get ttsSpeed => 'Geschwindigkeit';

  @override
  String get ttsPreviousSentence => 'Vorheriger Satz';

  @override
  String get ttsNextSentence => 'Nächster Satz';

  @override
  String get ttsTimerStop => 'Timer-Stopp';

  @override
  String get ttsTimerOff => 'Kein Limit';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes Minuten';
  }

  @override
  String get ttsPlaying => 'Wiedergabe läuft';

  @override
  String get ttsPaused => 'Pausiert';

  @override
  String get ttsStopped => 'Gestoppt';

  @override
  String get ttsPreviousSentenceFailed =>
      'Vorheriger Satz konnte nicht abgespielt werden';

  @override
  String get ttsNextSentenceFailed =>
      'Nächster Satz konnte nicht abgespielt werden';

  @override
  String get ttsEmptyContentError => 'Der Inhalt der aktuellen Seite ist leer';

  @override
  String get ttsPlaybackFailed => 'Wiedergabe fehlgeschlagen';

  @override
  String get ttsOperationFailed => 'Vorgang fehlgeschlagen';

  @override
  String get pageTurningMode => 'Seitenmodus';

  @override
  String get pageTurningSlide => 'Horizontales Gleiten';

  @override
  String get pageTurningScroll => 'Vertikales Blättern';

  @override
  String get tapZoneSettings => 'Tippzonen';

  @override
  String get tapZoneNextPage => 'Nächste Seite';

  @override
  String get tapZonePreviousPage => 'Vorherige Seite';

  @override
  String get tapZoneMenu => 'Menü';

  @override
  String get tapZoneLegend => 'Legende';

  @override
  String get tapZoneNextChapter => 'Nächstes Kapitel';

  @override
  String get tapZonePreviousChapter => 'Vorheriges Kapitel';

  @override
  String get tapZoneNone => 'Keine Aktion';

  @override
  String get tapZoneSettingsHint =>
      'Lege fest, was die neun Tippflächen jeweils tun';

  @override
  String get tapZoneChooseAction => 'Aktion wählen';

  @override
  String get tapZoneMenuRequiredHint =>
      'Tippe auf eine Fläche, um ihre Aktion zu ändern. Mindestens eine Fläche muss Menü bleiben; wird jedes Menü entfernt, wird die mittlere Fläche wieder zum Menü.';

  @override
  String get tapZoneReset => 'Standard wiederherstellen';

  @override
  String get highlightColor => 'Markierungsfarbe';

  @override
  String get highlightPreview => 'Vorschau';

  @override
  String get highlightSampleText => 'Dies ist ein Beispieltext,';

  @override
  String get highlightSampleText2 => 'dieser Teil wird markiert,';

  @override
  String get highlightSampleText3 => 'so zeigt sich der Markierungs-Effekt.';

  @override
  String get colorLightBlue => 'Hellblau';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorPurple => 'Lila';

  @override
  String get colorGold => 'Gold';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Gelb';

  @override
  String get colorDarkGreen => 'Dunkelgrün';

  @override
  String get colorCustom => 'Benutzerdefiniert';

  @override
  String get noteTypeHighlight => 'Markierung';

  @override
  String get noteTypeUnderline => 'Unterstreichung';

  @override
  String get noteTypeNote => 'Notiz';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Buch importieren';

  @override
  String get importFromFiles => 'Aus Dateien importieren';

  @override
  String get importNoBooks => 'Noch keine Bücher importiert';

  @override
  String get importSuccess => 'Buch erfolgreich importiert';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get importProcessing => 'Buch wird verarbeitet...';

  @override
  String get author => 'Autor';

  @override
  String get progress => 'Fortschritt';

  @override
  String get continueReading => 'Weiterlesen';

  @override
  String get recentBooks => 'Kürzliche Bücher';

  @override
  String get allBooks => 'Alle Bücher';

  @override
  String get emptyLibrary => 'Dein Bücherregal ist leer';

  @override
  String get deleteBook => 'Buch löschen';

  @override
  String get deleteBookConfirm => 'Möchtest du dieses Buch wirklich löschen?';

  @override
  String get bookDeleted => 'Buch gelöscht';

  @override
  String get userAgreement => 'Nutzungsvereinbarung';

  @override
  String get acceptAgreement => 'Ich habe gelesen und stimme zu';

  @override
  String get declineAgreement => 'Ablehnen';

  @override
  String get statsToday => 'Heute';

  @override
  String get statsThisWeek => 'Diese Woche';

  @override
  String get statsTotal => 'Gesamt';

  @override
  String statsMinutes(Object minutes) {
    return '$minutes Min.';
  }

  @override
  String statsHours(Object hours) {
    return '$hours h';
  }

  @override
  String statsBooks(Object count) {
    return '$count Bücher';
  }

  @override
  String get statsConsecutiveDays => 'Tage in Folge';

  @override
  String get statsFocusTime => 'Fokuszeit';

  @override
  String get statsThisWeekTotal => 'Diese Woche gesamt';

  @override
  String get statsKeepReading => 'Lies täglich weiter';

  @override
  String get statsMaxSession => 'Längste Sitzung';

  @override
  String get statsWeeklyTrend => 'Wochentrend';

  @override
  String get statsAchievements => 'Erfolge';

  @override
  String get readerToolbarMenu => 'Menü';

  @override
  String get readerToolbarTOC => 'Inhaltsverzeichnis';

  @override
  String get readerToolbarSettings => 'Einstellungen';

  @override
  String get readerAddBookmark => 'Lesezeichen hinzufügen';

  @override
  String get readerAddNote => 'Notiz hinzufügen';

  @override
  String get readerShare => 'Teilen';

  @override
  String get bookmarkAdded => 'Lesezeichen hinzugefügt';

  @override
  String get bookmarkRemoved => 'Lesezeichen entfernt';

  @override
  String get readerNavigationTitle => 'Navigation beim Lesen';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Kapitel $current von $total';
  }

  @override
  String get readerSearchChapters => 'Kapitel durchsuchen';

  @override
  String get readerBackToCurrentChapter => 'Zurück zum aktuellen Kapitel';

  @override
  String get readerCurrentChapter => 'Aktuell';

  @override
  String get readerCurrentPosition => 'Aktuelle Position';

  @override
  String get readerNoChapterResults => 'Keine passenden Kapitel';

  @override
  String get readerNoChapterResultsHint =>
      'Versuche ein anderes Wort aus dem Kapiteltitel.';

  @override
  String get readerNoBookmarks => 'Noch keine Lesezeichen';

  @override
  String get readerNoBookmarksHint =>
      'Tippe oben rechts auf die Lesezeichen-Taste, um deine Stelle zu speichern.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Füge dieses Buch zuerst dem Regal hinzu, bevor du Lesezeichen speicherst';

  @override
  String get themeBlue => 'Ozeanblau';

  @override
  String get themeGreen => 'Waldgrün';

  @override
  String get themeOrange => 'Kräftiges Orange';

  @override
  String get themeRed => 'Leidenschaftliches Rot';

  @override
  String get themeCustom => 'Benutzerdefiniert';

  @override
  String get tapZoneLeftRight => 'Links/Rechts';

  @override
  String get tapZoneLeftCenterRight => 'Links/Mitte/Rechts';

  @override
  String get homeTagline => 'Schön lesen';

  @override
  String get homeReadingStatsTitle => 'Lesestatistiken';

  @override
  String get homeTodayReadingMoment => 'Dein Lesemoment heute';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return '$minutes Minuten gelesen, mach weiter so';
  }

  @override
  String get homeTodayReadingJourneyStart => 'Starte heute deine Lesereise';

  @override
  String get homeTodayReadingKeepRhythm =>
      'Du bist heute im Rhythmus, mach weiter so';

  @override
  String get homeTodayReadingPrompt => 'Nimm dir heute Zeit zum Lesen';

  @override
  String homeTotalReadingHours(String hours) {
    return 'Insgesamt $hours Stunden gelesen';
  }

  @override
  String get homeWeeklyReading => 'Diese Woche';

  @override
  String get homeTotalReading => 'Gesamt gelesen';

  @override
  String get homeLibraryCount => 'Bücher im Regal';

  @override
  String get homeCollectionCount => 'Sammlung';

  @override
  String get homeKeyMetrics => 'Kennzahlen';

  @override
  String get homeReadingRhythm => 'Leserhythmus';

  @override
  String get homeAchievements => 'Leseerfolge';

  @override
  String get homeConsecutiveReading => 'Lesen in Folge';

  @override
  String get homeConsecutiveReadingDesc =>
      'Halte eine tägliche Lesegewohnheit aufrecht';

  @override
  String get homeFocusDuration => 'Fokusdauer';

  @override
  String get homeFocusDurationDesc => 'Längste einzelne Lesesitzung';

  @override
  String get homeWeeklyTotal => 'Wochensumme';

  @override
  String get homeWeeklyTotalDesc => 'Lesezeit diese Woche';

  @override
  String get homeRecentReading => 'Zuletzt gelesen';

  @override
  String get homeWeeklyTrend => 'Wöchentlicher Lesetrend';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get unitMinute => 'Min.';

  @override
  String get unitHour => 'Stunde';

  @override
  String get unitBook => 'Bücher';

  @override
  String get unitDay => 'Tage';

  @override
  String get weekdayMonShort => 'Mo';

  @override
  String get weekdayTueShort => 'Di';

  @override
  String get weekdayWedShort => 'Mi';

  @override
  String get weekdayThuShort => 'Do';

  @override
  String get weekdayFriShort => 'Fr';

  @override
  String get weekdaySatShort => 'Sa';

  @override
  String get weekdaySunShort => 'So';

  @override
  String get agreementTagline =>
      'Immersives Lesen · AI-Assistent · Lokal zuerst';

  @override
  String get agreementCardTitle => 'Nutzungs- und Servicevereinbarung';

  @override
  String get agreementCardSubtitle => 'Bitte lies das Folgende sorgfältig';

  @override
  String get agreementWelcomeTitle => 'Willkommen bei Origo X';

  @override
  String get agreementWelcomeBody =>
      'Um ein stabiles und vorhersehbares Leseerlebnis zu gewährleisten, lies und akzeptiere bitte zuerst die folgende Vereinbarung.';

  @override
  String get agreementFeatureFormatsTitle => 'Multi-Format-Unterstützung';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI und mehr';

  @override
  String get agreementFeatureCustomizationTitle => 'Personalisiertes Lesen';

  @override
  String get agreementFeatureCustomizationBody =>
      'Schriften, Farben, Typografie und mehr anpassen';

  @override
  String get agreementFeatureSyncTitle => 'Lokal zuerst';

  @override
  String get agreementFeatureSyncBody =>
      'Bücher, Fortschritt und Notizen bleiben auf dem Gerät, das du kontrollierst';

  @override
  String get agreementFeatureTtsTitle => 'Text-to-Speech';

  @override
  String get agreementFeatureTtsBody =>
      'Intelligente Sprachwiedergabe befreit deine Augen, damit du überall zuhören kannst';

  @override
  String get agreementTapToAgreeHint =>
      'Mit dem Tippen auf \"Zustimmen und fortfahren\" bestätigst du, dass du die Vereinbarung gelesen hast und der Nutzung der App zustimmst';

  @override
  String get agreementExitApp => 'App beenden';

  @override
  String get agreementAgreeAndContinue => 'Zustimmen und fortfahren';

  @override
  String get agreementExitDialogContent =>
      'Wenn du der Nutzungsvereinbarung nicht zustimmst, kannst du diese App nicht verwenden. Möchtest du sie wirklich beenden?';

  @override
  String get agreementConfirmExit => 'Beenden';

  @override
  String get readerFileMissing =>
      'Buchdatei nicht gefunden. Bitte importiere sie erneut.';

  @override
  String get readerUnsupportedFormat =>
      'Dieses Format kann noch nicht gelesen werden.';

  @override
  String get readerKindleDrmProtected =>
      'Dieses Kindle-Buch ist DRM-geschützt und kann hier nicht gelesen werden. Nur DRM-freie Bücher werden unterstützt.';

  @override
  String get readerComicNoPages =>
      'In diesem Comic-Archiv wurden keine Bildseiten gefunden.';

  @override
  String get readerComicCbrUnsupported =>
      'Dieser CBR-Comic verwendet echte RAR-Komprimierung und ist noch nicht lesbar. Bitte wandle ihn in CBZ um.';

  @override
  String get readerComicArchiveUnsupported =>
      'Das Archivformat dieses Comics ist noch nicht lesbar. Bitte wandle ihn in CBZ um.';

  @override
  String get readerComicChapterNoPages =>
      'Dieses Kapitel hat keine Bildseiten.';

  @override
  String get imageReaderSettings => 'Leseeinstellungen';

  @override
  String get imageReaderDirectionTitle => 'Leserichtung';

  @override
  String get imageReaderDirectionVertical => 'Fortlaufend vertikal';

  @override
  String get imageReaderDirectionLtr => 'Von links nach rechts';

  @override
  String get imageReaderDirectionRtl => 'Von rechts nach links (Manga)';

  @override
  String get imageReaderJumpToPage => 'Zu Seite springen';

  @override
  String get imageReaderBackgroundTitle => 'Seitenhintergrund';

  @override
  String get imageReaderBackgroundBlack => 'Schwarz';

  @override
  String get imageReaderBackgroundGray => 'Grau';

  @override
  String get imageReaderBackgroundWhite => 'Weiß';

  @override
  String get readerPdfLinuxUnsupported =>
      'PDF-Lesen ist unter Linux noch nicht verfügbar.';

  @override
  String get bootstrapImageManagerFailed =>
      'Der Bildmanager konnte nicht initialisiert werden';

  @override
  String homeFocusCompleted(int minutes) {
    return '$minutes-Minuten-Fokus-Sitzung abgeschlossen. Gut gemacht!';
  }

  @override
  String get homeDailyReadingGoal => 'Tägliches Leseziel';

  @override
  String get homeAiAdviceSection => 'AI-Lesetipps';

  @override
  String get homeTodayGlance => 'Heute im Überblick';

  @override
  String get homeViewAll => 'Alle ansehen';

  @override
  String get homeGoalDoneSuggestReview =>
      'Das heutige Ziel ist erreicht — denke über eine Lese-Rückschau nach';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Nur noch $minutes Minuten bis zum heutigen Ziel';
  }

  @override
  String get homePickBookHint =>
      'Wähle ein Buch aus deinem Regal zum Weiterlesen und schließe zuerst 1 Fokus-Sitzung ab.';

  @override
  String homeContinueBookHint(String title) {
    return 'Lies zuerst \"$title\" weiter und wechsle dann zu anderen Büchern.';
  }

  @override
  String get homeTodayActionAdvice => 'Heutiger Aktionsplan';

  @override
  String homeProgressPercent(int percent) {
    return '$percent% Fortschritt';
  }

  @override
  String homeStreakDays(int days) {
    return '$days Tage in Folge';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes Min. diese Woche';
  }

  @override
  String get homePlanLoading => 'Plan wird geladen';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Ziel: $minutes Min./Tag';
  }

  @override
  String get homeAiAdviceForYou => 'AI-Lesetipps für dich';

  @override
  String homeBasedOnBook(String title) {
    return 'Basierend auf \"$title\"';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Heute gelesen (Min.)';

  @override
  String get homeTotalReadingMinutesLabel => 'Gesamt gelesen (Min.)';

  @override
  String get homeGeneratingPlan => 'Heutiger Leseplan wird erstellt...';

  @override
  String get homeCompletedLabel => 'Fertig';

  @override
  String get homeTodayGoalAchieved => 'Heutiges Ziel erreicht';

  @override
  String homeMinutesRemaining(int minutes) {
    return 'Noch $minutes Minuten';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return '$read / $goal Min. gelesen';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'Etwa $sessions Fokus-Sitzungen bis zum heutigen Ziel';
  }

  @override
  String get homeStreakLabel => 'Serie';

  @override
  String get homeWeekAchievedLabel => 'Wochenziel';

  @override
  String get homeFocusLabel => 'Fokus';

  @override
  String homeDaysCount(int days) {
    return '$days Tage';
  }

  @override
  String homeTimesCount(int times) {
    return '$times Mal';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Fokus-Countdown $time';
  }

  @override
  String get homeGoLibraryRead => 'Aus dem Regal lesen';

  @override
  String get homeEndFocus => 'Fokus beenden';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Fokus $minutes Min.';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Ziel anpassen: $minutes Min.';
  }

  @override
  String get homeNoRecentReading =>
      'Noch nichts kürzlich gelesen. Öffne ein Buch aus deinem Regal, um loszulegen.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Fortschritt $percent%';
  }

  @override
  String get librarySearchHint => 'Titel oder Autoren durchsuchen';

  @override
  String libraryFilterAll(int count) {
    return 'Alle $count';
  }

  @override
  String libraryFilterReading(int count) {
    return 'Am Lesen $count';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Beendet $count';
  }

  @override
  String get libraryFilterTooltip => 'Nach Lesestatus filtern';

  @override
  String get libraryNoMatchingBooks => 'Keine passenden Bücher';

  @override
  String get libraryNoReadingBooks => 'Keine Bücher in Arbeit';

  @override
  String get libraryNoFinishedBooks => 'Keine beendeten Bücher';

  @override
  String get libraryNoBooks => 'Noch keine Bücher';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · Weiterlesen';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Seite $page';
  }

  @override
  String get libraryStartFromBeginning => 'Von vorn beginnen';

  @override
  String get libraryBookInfo => 'Buchinformationen';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · $pages Seiten';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · $chapters Kapitel';
  }

  @override
  String get libraryRenameBook => 'Umbenennen';

  @override
  String get libraryRenameBookHint =>
      'Ändere den Titel; die Datei auf der Festplatte wird ebenfalls umbenannt';

  @override
  String get libraryRenameBookSuccess => 'Umbenannt';

  @override
  String get libraryRenameBookFailed =>
      'Das Buch konnte nicht umbenannt werden';

  @override
  String get libraryCustomCover => 'Eigenes Cover';

  @override
  String get libraryCustomCoverHint =>
      'Wähle ein Bild als Cover für dieses Buch';

  @override
  String get libraryCustomCoverSuccess => 'Cover aktualisiert';

  @override
  String get libraryCoverUnsupportedFormat => 'Nicht unterstütztes Bildformat';

  @override
  String get libraryCoverFileTooLarge =>
      'Das Bild überschreitet die Größenbeschränkung von 20 MB';

  @override
  String get libraryCoverReadFailed =>
      'Das ausgewählte Bild konnte nicht gelesen werden';

  @override
  String get libraryCoverSaveFailed =>
      'Das Cover konnte nicht gespeichert werden';

  @override
  String get libraryResetCover => 'Standard-Cover wiederherstellen';

  @override
  String get libraryResetCoverHint =>
      'Entfernt das eigene Cover und stellt das Original wieder her';

  @override
  String get libraryResetCoverSuccess => 'Standard-Cover wiederhergestellt';

  @override
  String get libraryExportBook => 'Buchdatei exportieren';

  @override
  String get libraryExportOriginalHint =>
      'Die Originaldatei an einen anderen Ort kopieren';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Das heruntergeladene Buch als erzeugte TXT-Datei exportieren';

  @override
  String bookExportSuccess(String location) {
    return 'Exportiert nach $location';
  }

  @override
  String get bookExportSourceMissing =>
      'Die Buchdatei fehlt und kann nicht exportiert werden';

  @override
  String get bookExportUnsupported =>
      'Buchexport wird auf dieser Plattform noch nicht unterstützt';

  @override
  String get bookExportFailed => 'Das Buch konnte nicht exportiert werden';

  @override
  String get bookExportInProgress => 'Buch wird exportiert…';

  @override
  String get incomingBooksImporting =>
      'Ein Buch wird aus einer anderen App importiert…';

  @override
  String get incomingBooksNoBookFile =>
      'Die geteilten Inhalte enthalten keine importierbare Buchdatei';

  @override
  String get incomingBooksPermissionExpired =>
      'Der Dateizugriff ist abgelaufen. Teile oder öffne die Datei erneut';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Dieses Buchformat wird nicht unterstützt';

  @override
  String get incomingBooksFileTooLarge =>
      'Die Datei überschreitet die Importgrenze von 500 MB';

  @override
  String get incomingBooksTooManyFiles =>
      'Zu viele Buchdateien wurden auf einmal geteilt. Füge sie in kleineren Stapeln hinzu';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Einige Dateien konnten nicht erkannt werden; die übrigen Bücher werden weiter importiert';

  @override
  String get incomingBooksContentMismatch =>
      'Das Dateiformat passt nicht zum Inhalt';

  @override
  String get incomingBooksImportFailed =>
      'Das Buch konnte nicht aus einer anderen App importiert werden';

  @override
  String get libraryDeleteBookHint => 'Dieses Buch wird dauerhaft gelöscht';

  @override
  String get libraryBookTitle => 'Titel';

  @override
  String get libraryFormat => 'Format';

  @override
  String libraryPagesCount(int pages) {
    return '$pages Seiten';
  }

  @override
  String get totalChapters => 'Kapitel gesamt';

  @override
  String get currentChapter => 'Aktuelles Kapitel';

  @override
  String libraryChaptersCount(int chapters) {
    return '$chapters Kapitel';
  }

  @override
  String get libraryClose => 'Schließen';

  @override
  String get libraryConfirmDeleteTitle => 'Löschen bestätigen';

  @override
  String libraryDeleteBookMessage(String title) {
    return '\"$title\" löschen? Die Datei wird dauerhaft von deinem Gerät entfernt.';
  }

  @override
  String libraryDeletingBook(String title) {
    return '\"$title\" wird gelöscht...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '\"$title\" gelöscht';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get libraryReadingBadge => 'Am Lesen';

  @override
  String get libraryDeletingBookFile => 'Buchdatei wird gelöscht...';

  @override
  String get libraryDeletingCoverImage => 'Cover-Bild wird gelöscht...';

  @override
  String get libraryCleaningDatabase => 'Datenbankeinträge werden bereinigt...';

  @override
  String get libraryDeleteComplete => 'Löschen abgeschlossen';

  @override
  String get librarySelectMultiple => 'Mehrere auswählen';

  @override
  String get librarySelectAll => 'Alle auswählen';

  @override
  String librarySelectedBooks(int count) {
    return '$count ausgewählt';
  }

  @override
  String libraryDeleteSelected(int count) {
    return '$count löschen';
  }

  @override
  String get libraryBatchDeleteTitle => 'Ausgewählte Bücher löschen?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Dies löscht die $count ausgewählten Bücher, zugehörige Notizen und Lesezeichen sowie lokale Dateien dauerhaft. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return '$done/$total werden gelöscht';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return '$count Bücher gelöscht';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return '$success gelöscht; $failed fehlgeschlagen';
  }

  @override
  String get readerPrefaceTitle => 'Vorspann';

  @override
  String get readerModeHorizontalPage => 'Keine Animation';

  @override
  String get readerModeVerticalScrollHint =>
      'Blättere vorab erzeugte Seiten vertikal durch; wische seitlich, um Kapitel zu wechseln';

  @override
  String get readerModeWholeBookScrollHint =>
      'Vorab erzeugte Kapitel bilden eine positionierbare durchlaufende vertikale Liste';

  @override
  String get readerScrollByChapterTitle => 'Kapitelweise scrollen';

  @override
  String get readerScrollByChapterOnHint =>
      'Blättere ein Kapitel Seite für Seite durch; wische seitlich, um das Kapitel zu wechseln';

  @override
  String get readerScrollByChapterOffHint =>
      'Alle Kapitel gehen Seite für Seite in eine positionierbare durchlaufende vertikale Liste über';

  @override
  String get readerModeHorizontalPageHint =>
      'Tippe links für die vorherige Seite und rechts für die nächste Seite';

  @override
  String get readerModeHorizontalSlideHint =>
      'Seiten folgen deinem Finger horizontal und rasten ein';

  @override
  String get readerModeCoverSlide => 'Cover';

  @override
  String get readerModeCoverSlideHint =>
      'Die aktuelle Seite gleitet nach links weg und gibt die Seite darunter frei';

  @override
  String get readerModePageCurl => 'Seitenumschlag';

  @override
  String get readerModePageCurlHint =>
      'Ziehe seitlich, um die Seite umzuschlagen, und lass los, um zu blättern oder zurückzuschnellen';

  @override
  String get readerTextBrightnessLabel => 'Text-Helligkeit';

  @override
  String get readerDimTextInDarkModeTitle => 'Text im Dunkelmodus abdunkeln';

  @override
  String get readerDimTextInDarkModeHint =>
      'Im Dunkelmodus 70 % Helligkeit verwenden';

  @override
  String readerFontSizeValue(int size) {
    return 'Schriftgröße  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Horizontaler Rand  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Horizontaler Rand';

  @override
  String get readerTopMarginLabel => 'Oberer Rand';

  @override
  String get readerBottomMarginLabel => 'Unterer Rand';

  @override
  String get readerTxtChapterTitlePageTitle => 'Kapiteltitel auf eigener Seite';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Wenn ausgeschaltet, erscheint der Kapiteltitel über dem Fließtext';

  @override
  String get readerVerticalMarginLabel => 'Vertikaler Rand';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Vertikaler Rand  $margin';
  }

  @override
  String readerChapterCount(int count) {
    return '$count Kapitel';
  }

  @override
  String readerChapterFallback(int number) {
    return 'Kapitel $number';
  }

  @override
  String readerOpenFailed(String error) {
    return 'Öffnen fehlgeschlagen: $error';
  }

  @override
  String get readerNoContent => 'Dieses Buch hat keinen lesbaren Inhalt';

  @override
  String readerStatusPaged(
    int chapter,
    int chapterCount,
    int page,
    int pageCount,
  ) {
    return 'Kapitel $chapter/$chapterCount · Seite $page/$pageCount';
  }

  @override
  String readerStatusScroll(int chapter, int chapterCount) {
    return 'Kapitel $chapter/$chapterCount · Vertikales Scrollen';
  }

  @override
  String get importPreparing => 'Import wird vorbereitet...';

  @override
  String importFailedWithError(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get importLocalFile => 'Lokale Dateien';

  @override
  String get settingsAiTempHintMinimax =>
      'Temperature: MiniMax empfiehlt 0.01 ~ 1.00';

  @override
  String get settingsAiCustomConfigTitle => 'Eigene AI-Konfiguration';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Aktueller Anbieter: $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'Die MiniMax-Temperature muss zwischen 0.01 und 1.00 liegen';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'Die Temperature liegt außerhalb des Bereichs, bitte folge dem Hinweis';

  @override
  String get settingsApply => 'Anwenden';

  @override
  String get settingsAiCustomApplied =>
      'Eigene Parameter angewendet, denke daran, die Konfiguration zu speichern';

  @override
  String get settingsAiApiKeyRequired => 'Der API Key darf nicht leer sein';

  @override
  String get settingsAiModelRequired => 'Das Modell darf nicht leer sein';

  @override
  String get settingsAiBaseUrlInvalid =>
      'Die Base URL muss eine gültige http/https-Adresse sein';

  @override
  String get settingsAiSettingsSaved => 'AI-Einstellungen gespeichert';

  @override
  String settingsSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle => 'Mit Lautstärketasten blättern';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Lautstärketasten in Seitenmodi verwenden';

  @override
  String get settingsAutoResumeReadingTitle => 'Lesen beim Start fortsetzen';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Wenn du die App beim Lesen verlässt, kehrt der nächste Start zu deiner Stelle zurück';

  @override
  String get settingsShowStatusBarTitle =>
      'Systemstatusleiste beim Lesen anzeigen';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Akku-/Uhr-Anzeige des Lesers ausgeblendet';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Akku-/Uhr-Anzeige des Lesers wird verwendet';

  @override
  String get readerTopBarStyleTitle => 'Obere Informationen';

  @override
  String get readerTopBarStyleSystem => 'Systemstatusleiste';

  @override
  String get readerTopBarStyleSystemHint =>
      'Systemzeit, Signal und Akku anzeigen';

  @override
  String get readerTopBarStyleReader => 'Info-Leiste des Lesers';

  @override
  String get readerTopBarStyleReaderHint =>
      'Zeit, Kapiteltitel und Akku anzeigen';

  @override
  String get readerTopBarStyleFloating => 'Schwebende Info-Leiste';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Zeit und Akku im Statusleistenbereich anzeigen, ohne Lesefläche zu verbrauchen';

  @override
  String get readerTopBarStyleHidden => 'Vollständig immersiv';

  @override
  String get readerTopBarStyleHiddenHint => 'Oben keine Informationen anzeigen';

  @override
  String get settingsAiAssistantTitle => 'AI-Leseassistent';

  @override
  String get settingsSystemSettingsTitle => 'Systemeinstellungen';

  @override
  String get settingsSectionAppearanceFonts => 'Erscheinungsbild & Schriften';

  @override
  String get settingsSectionDataServices => 'Daten & Dienste';

  @override
  String get settingsSectionGeneral => 'Allgemein';

  @override
  String get settingsSectionAdvancedFeatures => 'Erweiterte Funktionen';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Weitere Quellenprotokolle';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Unterstützung für zusätzliche Quellenprotokolle aktivieren.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Quellen in privaten Netzen erlauben';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Erlaube Buchquellen den Zugriff auf dieses Gerät, das lokale Netzwerk und andere private Adressen. Mit Premium standardmäßig aktiv; verwende nur vertrauenswürdige Quellen.';

  @override
  String get additionalSourcesImport => 'Weitere Quellenprotokolle importieren';

  @override
  String get additionalSourcesImportTitle => 'Quellen-JSON importieren';

  @override
  String get additionalSourcesImportNotice =>
      'Der Import verarbeitet und dedupliziert nur lokal; er prüft nicht jede Quelle online. Quellen mit ausführbaren Regeln behalten ihren importierten Aktivierungsstatus, und jede Funktion wird bei Verwendung geprüft.';

  @override
  String get additionalSourcesChooseFile => 'Aus JSON-Datei hinzufügen';

  @override
  String get additionalSourcesUrlLabel => 'Quellen-JSON-URL';

  @override
  String get additionalSourcesLoadUrl => 'URL laden';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return '$supported verfügbar, $partial teilweise unterstützt, $unsupported nicht unterstützt';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return '$supported Standard-Regeln, $partial erweiterte Regeln, $unsupported fortgeschrittene Regeln, $skipped übersprungen';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return '$count Quellen importbereit, $skipped übersprungen';
  }

  @override
  String get additionalSourcesAvailable => 'Verfügbar';

  @override
  String get additionalSourcesPartial => 'Teilweise unterstützt';

  @override
  String get additionalSourcesUnsupported => 'Nicht unterstützt';

  @override
  String get additionalSourcesImportConfirm => 'Alle importieren';

  @override
  String additionalSourcesImported(int count) {
    return '$count Quellen importiert';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return '$count Quellen importiert; $conflicted übersprungen, deren ID bereits von einem anderen Ursprung registriert ist';
  }

  @override
  String get settingsSectionAboutSupport => 'Über & Unterstützung';

  @override
  String get settingsKeepScreenOnTitle => 'Bildschirm dauerhaft an';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Verhindert das Abschalten des Bildschirms beim Lesen';

  @override
  String get settingsPowerSavingModeTitle => 'Energiesparmodus';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Beschränkt die App auf 60 fps, statt eine hohe Bildwiederholrate zu nutzen';

  @override
  String get settingsAutoSaveTitle => 'Automatisch speichern';

  @override
  String get settingsAutoSaveSubtitle =>
      'Lesefortschritt automatisch speichern';

  @override
  String get settingsHelpPlaceholder =>
      'Hier könnten Hilfeinformationen stehen';

  @override
  String get settingsAiConfigured => 'AI konfiguriert';

  @override
  String get settingsAiNotConfigured => 'API Key noch nicht konfiguriert';

  @override
  String get settingsAiReadyToUse => 'Einsatzbereit';

  @override
  String get settingsAiPendingConfig => 'Einrichtung offen';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Aktuelle Voreinstellung: $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Aktuelle Konfiguration: eigene · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'Häufige Anbieter und Modelle sind integriert; meist musst du nur eine Voreinstellung wählen und einen API Key eingeben.';

  @override
  String get settingsAiProviderLabel => 'Anbieter';

  @override
  String get settingsAiCustomProvider => 'Eigener';

  @override
  String get settingsAiProtocolLabel => 'API-Protokoll';

  @override
  String get settingsAiProtocolOpenAi => 'OpenAI-kompatibel';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Voreingestelltes Modell wählen';

  @override
  String get settingsAiPresetLabel => 'Voreingestelltes Modell';

  @override
  String get settingsAiCustomButton => 'Eigene';

  @override
  String get settingsAiPresetSelectedHint =>
      'Nach der Auswahl einer Voreinstellung genügt ein API Key, um sie zu nutzen.';

  @override
  String get settingsAiCustomActiveHint =>
      'Eigene Parameter sind aktiv; du kannst jederzeit zur Voreinstellung zurückwechseln.';

  @override
  String get settingsAiApiKeyHint =>
      'Zum Aktivieren der aktuellen Voreinstellung eingeben';

  @override
  String get settingsShow => 'Anzeigen';

  @override
  String get settingsHide => 'Verbergen';

  @override
  String get settingsAiSaving => 'Speichern...';

  @override
  String get settingsAiSaveConfig => 'AI-Konfiguration speichern';

  @override
  String get settingsPageIntro =>
      'Nur die Optionen, die dein Leseerlebnis prägen.';

  @override
  String get settingsSupportDevelopmentTitle => 'Entwicklung unterstützen';

  @override
  String get firstHomeSupportNow => 'Jetzt unterstützen';

  @override
  String get firstHomeSupportLater => 'Vielleicht später';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Ein Brief des Origo-X-Entwicklers mit der Bitte um freiwillige Unterstützung';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Entwicklung unterstützen';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'Spenden sind freiwillig und unterstützen die laufende Entwicklung.';

  @override
  String get settingsAccountGuestTitle => 'Bei Origo X anmelden';

  @override
  String get settingsAccountGuestSubtitle =>
      'Profil und Sicherheitseinstellungen synchronisieren.';

  @override
  String get settingsAccountOpen => 'Kontozentrum';

  @override
  String get settingsAccountVerified => 'Verifiziertes Konto';

  @override
  String get accountPageTitle => 'Konto';

  @override
  String get accountIntroTitle => 'Konto';

  @override
  String get accountPageSubtitle =>
      'Melde dich an, um Profil und Kontoeinstellungen zu synchronisieren.';

  @override
  String get accountLoginTab => 'E-Mail-Anmeldung';

  @override
  String get accountRegisterTab => 'Registrieren';

  @override
  String get accountCodeTab => 'E-Mail-Code';

  @override
  String get accountResetTab => 'Zurücksetzen';

  @override
  String get accountEmail => 'E-Mail';

  @override
  String get accountEmailRequired => 'Gib deine E-Mail-Adresse ein';

  @override
  String get accountEmailFirstHint =>
      'Gib deine E-Mail ein, um fortzufahren. Die Passwort-Anmeldung ist der Standard.';

  @override
  String get accountContinue => 'Weiter';

  @override
  String get accountPasswordLoginTitle => 'Mit Passwort anmelden';

  @override
  String get accountPasswordLoginHint =>
      'Gib dein Passwort ein oder verwende stattdessen einen E-Mail-Code.';

  @override
  String get accountUseEmailCode => 'Mit E-Mail-Code anmelden';

  @override
  String get accountNoAccount => 'Kein Konto? Registrieren';

  @override
  String get accountForgotPassword => 'Passwort vergessen';

  @override
  String get accountHaveAccount => 'Schon registriert? Zurück zur Anmeldung';

  @override
  String get accountBackToPassword => 'Zurück zur Passwort-Anmeldung';

  @override
  String get accountChangeEmail => 'Ändern';

  @override
  String get accountRegisterHint =>
      'Bestätige deine E-Mail und erstelle dann Konto und Passwort.';

  @override
  String get accountCodeLoginHint =>
      'Wir senden einen Code an die ausgewählte E-Mail.';

  @override
  String get accountResetHint =>
      'Bestätige deine E-Mail und wähle dann ein neues Passwort.';

  @override
  String get accountPassword => 'Passwort';

  @override
  String get accountConfirmPassword => 'Passwort bestätigen';

  @override
  String get accountAvatarCropTitle => 'Profilbild zuschneiden';

  @override
  String get accountAvatarCropHint =>
      'Ziehe zum Neupositionieren und nutze den Zwei-Finger-Zoom, bis das Motiv in den Kreis passt.';

  @override
  String get accountUsername => 'Benutzername';

  @override
  String get accountDisplayName => 'Anzeigename';

  @override
  String get accountVerificationCode => 'Bestätigungscode';

  @override
  String get accountSendCode => 'Code senden';

  @override
  String get accountSignIn => 'Anmelden';

  @override
  String get accountCreate => 'Konto erstellen';

  @override
  String get accountResetPassword => 'Passwort zurücksetzen';

  @override
  String get accountUseApple => 'Mit Apple anmelden';

  @override
  String get accountUseGithub => 'Mit GitHub anmelden';

  @override
  String get accountUseGoogle => 'Mit Google fortfahren';

  @override
  String get accountUsePasskey => 'Mit Passkey fortfahren';

  @override
  String get accountMoreSignInMethods => 'Weitere Anmeldemethoden';

  @override
  String get accountExternalHint =>
      'Ein sicherer Browser wird geöffnet. Kehre nach der Freigabe hierher zurück.';

  @override
  String get accountProfileTitle => 'Profil';

  @override
  String get accountEditProfile => 'Profil bearbeiten';

  @override
  String get accountSignInMethodsTitle => 'Anmeldemethoden';

  @override
  String get accountSaveProfile => 'Profil speichern';

  @override
  String get accountChangeAvatar => 'Profilbild ändern';

  @override
  String get accountRemoveAvatar => 'Profilbild entfernen';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String get accountSupportTitle => 'Premium-Mitgliedschaft';

  @override
  String get accountSupportFreeSubtitle =>
      'Grundlegende Lesefunktionen sind kostenlos nutzbar.';

  @override
  String get accountSupportAction => 'Premium holen';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Mindestens 12 Zeichen';

  @override
  String get accountUsernameHint =>
      '3–30 Kleinbuchstaben, Zahlen oder Unterstriche';

  @override
  String get settingsDonationAction => 'Mit WeChat spenden';

  @override
  String get settingsAlipayDonationAction => 'Mit Alipay spenden';

  @override
  String get settingsDonationDialogTitle => 'WeChat-Spende';

  @override
  String get settingsDonationDialogHint =>
      'Scanne den QR-Code mit WeChat, um die Weiterentwicklung zu unterstützen. Danke.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Alipay-Spende';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Scanne den QR-Code mit Alipay, um die Weiterentwicklung zu unterstützen. Danke.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'Spenden sind völlig freiwillig. Sie schalten keine Funktionen frei und stellen keine Kauf- oder Dienstleistungsvereinbarung dar.';

  @override
  String get settingsDonationQrCodeLabel => 'WeChat-Spenden-QR-Code';

  @override
  String get settingsAlipayDonationQrCodeLabel => 'Alipay-Spenden-QR-Code';

  @override
  String get settingsAiSwipeHint =>
      'Wische durch die Modelle, tippe zum Wechseln, drücke lange zum Bearbeiten oder Löschen.';

  @override
  String get settingsAiLegacyIntro =>
      'Wähle Anbieter und Modell und gib dann deinen API Key ein.';

  @override
  String get settingsAiModelLabel => 'Modell';

  @override
  String get settingsAiUsingCustomParams =>
      'Eigene Modelleinstellungen in Gebrauch';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Nur auf diesem Gerät gespeichert';

  @override
  String get settingsAiSaveAndEnable => 'Speichern und aktivieren';

  @override
  String get settingsAboutTagline =>
      'Plattformübergreifend, fokussiert aufs Lesen';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get changelogHistoryTitle => 'Versionsverlauf';

  @override
  String get changelogHistorySubtitle => 'Änderungen jeder Version ansehen';

  @override
  String get openSourceLicensesTitle => 'Open-Source- & Schriftlizenzen';

  @override
  String get openSourceLicensesSubtitle =>
      'Lizenzen der App, mitgelieferten Schriften und Drittanbieter-Software ansehen';

  @override
  String get openSourceLicensesIntro =>
      'Diese Lizenztexte und Hinweise sind in der App offline verfügbar. Origo X, Schriften auf Abruf und Drittanbieter-Software unterliegen weiterhin ihren jeweiligen Lizenzen.';

  @override
  String get openSourceProjectSection => 'Projektlizenzen';

  @override
  String get openSourceLegacyLicenseTitle => 'Frühere Versionen';

  @override
  String get openSourceFontsSection => 'Schriftlizenzen';

  @override
  String get openSourceDependenciesSection => 'Drittanbieter-Software';

  @override
  String get openSourceDependenciesTitle => 'Flutter- und Dart-Abhängigkeiten';

  @override
  String get openSourceDependenciesSubtitle =>
      'Von Flutter automatisch gesammelte Drittanbieter-Lizenzen ansehen';

  @override
  String get openSourceLicenseLegalese =>
      'Origo X und Drittanbieter-Komponenten unterliegen weiterhin ihren jeweiligen Lizenzen.';

  @override
  String get openSourceLicenseLoadFailed =>
      'Der Lizenztext konnte nicht geladen werden.';

  @override
  String get changelogPageTitle => 'Release-Verlauf';

  @override
  String get changelogCurrentVersion => 'Aktuelle Version';

  @override
  String get changelogLoadFailed =>
      'Release-Verlauf konnte nicht geladen werden';

  @override
  String get settingsMaintainerLabel => 'Maintainer';

  @override
  String get settingsLicenseLabel => 'Lizenz';

  @override
  String get settingsViewSourceSubtitle => 'Open-Source-Projekt ansehen';

  @override
  String get settingsJoinQqGroup => 'QQ-Gruppe beitreten';

  @override
  String get settingsQqOpenFailed =>
      'QQ konnte nicht geöffnet werden. Bitte stelle sicher, dass QQ installiert ist.';

  @override
  String get settingsDarkModeTitle => 'Nachtmodus';

  @override
  String settingsCurrentValue(String value) {
    return 'Aktuell: $value';
  }

  @override
  String get settingsUiStyleTitle => 'Glaseffekt';

  @override
  String get settingsGlassEffectSubtitle =>
      'Transluzente Flächen, Hintergrund-Weichzeichnung und schwebende Tiefe verwenden';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Beschriftungen der unteren Navigation ausblenden';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'In der mobilen unteren Navigation nur Symbole zeigen';

  @override
  String get settingsFloatingNavigationTitle => 'Schwebende Navigationsleiste';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Größe, Anzeigestil und Reihenfolge der Ziele anpassen';

  @override
  String get floatingNavigationPreviewTitle => 'Vorschau';

  @override
  String get floatingNavigationSizeTitle => 'Größe';

  @override
  String get floatingNavigationSizeAutomatic => 'Automatisch';

  @override
  String get floatingNavigationSizeCustom => 'Benutzerdefiniert';

  @override
  String get floatingNavigationHeightLabel => 'Höhe';

  @override
  String get floatingNavigationSideMarginLabel => 'Seitlicher Abstand';

  @override
  String get floatingNavigationDisplayModeTitle => 'Anzeigestil';

  @override
  String get floatingNavigationIconsOnly => 'Nur Symbole';

  @override
  String get floatingNavigationIconsAndLabels => 'Symbole und Beschriftungen';

  @override
  String get floatingNavigationOrderTitle => 'Navigationsreihenfolge';

  @override
  String get floatingNavigationOrderHint =>
      'Halte den Griff rechts, um die Reihenfolge zu ändern';

  @override
  String get floatingNavigationSyncHint =>
      'Die Reihenfolge gilt auch für Wischnavigation und die Breitbild-Seitenleiste';

  @override
  String get floatingNavigationResetOrder =>
      'Standardreihenfolge wiederherstellen';

  @override
  String get floatingNavigationResetDone =>
      'Standardreihenfolge wiederhergestellt';

  @override
  String get settingsLibraryLayoutTitle => 'Regal-Einstellungen';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Regal-Layout und Buchöffnungs-Erlebnis anpassen';

  @override
  String get settingsLibraryLayoutCard => 'Karten';

  @override
  String get settingsLibraryLayoutGrid => 'Raster';

  @override
  String get settingsLibraryGridColumnsTitle =>
      'Cover pro Zeile auf Smartphones';

  @override
  String get settingsLibraryGridTwoColumns => '2 Spalten';

  @override
  String get settingsLibraryGridThreeColumns => '3 Spalten';

  @override
  String get settingsLibraryGridShowDetailsTitle =>
      'Titel und Fortschritt anzeigen';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Fügt unter jedem Cover eine Titelzeile und eine schlanke Fortschrittsleiste hinzu';

  @override
  String get settingsLibraryOpenAnimationTitle => 'Animation beim Buchöffnen';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Wird nur beim Öffnen eines Buchs aus dem Regal verwendet';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Klassische Cover-Vergrößerung';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Vergrößert das Original-Cover auf Vollbild, bevor der Reader erscheint';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Minimales Überblenden';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Blendet den Text ohne gerichtete Bewegung ein';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Papier-Anstieg';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'Das Leseblatt legt sich sanft von unten an seinen Platz';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Seiten-Gleiten';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'Die Leseseite erscheint mit einer kurzen seitlichen Bewegung';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Animationstempo';

  @override
  String get settingsLibraryOpenAnimationFast => 'Schnell';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Schnell einblenden, sobald der Text bereit ist';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Elegant';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Den Text langsamer enthüllen für einen ruhigeren Übergang';

  @override
  String get settingsAccentFollowTheme => 'Akzentfarbe: folgt dem Design';

  @override
  String settingsAccentValue(String name) {
    return 'Akzentfarbe: $name';
  }

  @override
  String get settingsAppThemeTitle => 'App-Design';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Aktuell: $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'App-Design folgen';

  @override
  String get settingsAccentColorTitle => 'Akzentfarbe';

  @override
  String get settingsThemeModeSystemHint =>
      'Automatisch mit dem System-Erscheinungsbild wechseln';

  @override
  String get settingsThemeModeLightHint =>
      'Immer das helle Erscheinungsbild verwenden';

  @override
  String get settingsThemeModeDarkHint =>
      'Immer das dunkle Erscheinungsbild verwenden';

  @override
  String get settingsSelectAppTheme => 'App-Design wählen';

  @override
  String get settingsDone => 'Fertig';

  @override
  String get settingsAccentColorAdvice =>
      'Die Akzentfarbe erzeugt die vollständigen Material-3-Farbschemata für Hell und Dunkel.';

  @override
  String get settingsAccentPresetColors => 'Schnellauswahl';

  @override
  String get settingsAccentCustomColor => 'Eigene Farbe';

  @override
  String get settingsAccentSaturationBrightness =>
      'Farbfeld für Sättigung und Helligkeit';

  @override
  String get settingsAccentHue => 'Farbton';

  @override
  String get settingsAccentPreview => 'Vorschau der Design-Palette';

  @override
  String get settingsAccentFollowThemeOption => 'Design folgen';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Die Standard-Akzentfarbe des aktuellen App-Designs verwenden';

  @override
  String get settingsAboutTitle => 'Über';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Maintainer: 小元Niki';

  @override
  String get settingsGithubRepo => 'GitHub-Repository';

  @override
  String get settingsNewYearGreeting =>
      'Ein fokussierter, zurückhaltender und frei modifizierbarer plattformübergreifender Reader.';

  @override
  String get settingsGithubOpenFailed =>
      'Der GitHub-Link konnte nicht geöffnet werden';

  @override
  String get settingsOfficialWebsite => 'Offizielle Website';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Von open.xxread.top herunterladen und installieren';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'Die offizielle Website konnte nicht geöffnet werden';

  @override
  String get updateCheckNow => 'Nach Updates suchen';

  @override
  String get updateCheckNowSubtitle =>
      'Die neueste Version von GitHub oder der offiziellen Website laden';

  @override
  String get updateAppStoreManaged =>
      'Dieser Mac-App-Store-Build aktualisiert über den App Store';

  @override
  String get updateAvailableTitle => 'Eine neue Version ist verfügbar';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Aktuelle Version: $currentVersion\nNeueste Version: $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Neuheiten';

  @override
  String get updateNotesEmpty =>
      'Für diese Version wurden keine Release-Notizen bereitgestellt.';

  @override
  String get updateLater => 'Später';

  @override
  String get updateSkipVersion => 'Diese Version überspringen';

  @override
  String get updateGoToDownload => 'Zum Update gehen';

  @override
  String get updateFromGithub => 'Von GitHub aktualisieren';

  @override
  String get updateFromWebsite => 'Offizielle Website öffnen';

  @override
  String get updateFromWebsiteInstall => 'Von der Website herunterladen';

  @override
  String get updateWebsiteUnavailable =>
      'Das Paket der offiziellen Website ist für dieses Gerät noch nicht verfügbar';

  @override
  String get updateDownloadingTitle => 'Update wird heruntergeladen';

  @override
  String updateDownloadProgress(int percent) {
    return '$percent% heruntergeladen';
  }

  @override
  String get updatePreparingInstaller =>
      'Paket wird verifiziert und System-Installer vorbereitet…';

  @override
  String get updateDownloadFailed =>
      'Das Update konnte nicht von der offiziellen Website heruntergeladen werden';

  @override
  String get updateIntegrityFailed =>
      'Das heruntergeladene Update hat die Integritätsprüfung nicht bestanden und wurde gelöscht';

  @override
  String get updateInstallFailed =>
      'Das Update-Paket konnte nicht installiert werden. Prüfe die Installationsrechte und versuche es erneut.';

  @override
  String get updateAlreadyLatest => 'Du nutzt bereits die neueste Version';

  @override
  String get updateCheckFailed =>
      'Es konnte nicht nach Updates gesucht werden. Bitte versuche es später erneut.';

  @override
  String get updateOpenFailed => 'Der Link konnte nicht geöffnet werden';

  @override
  String get settingsIosOnlyFeature =>
      'Diese Funktion ist nur unter iOS verfügbar';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Synchronisiert mit $storage\n$books Bücher, $files Dateien kopiert';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Diese Einstellungsänderung erfordert einen App-Neustart, um vollständig zu wirken.';

  @override
  String get settingsRestartRequiredTitle => 'Neustart erforderlich';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\nApp jetzt neu starten?';
  }

  @override
  String get settingsRestartLater => 'Später';

  @override
  String get settingsRestartNow => 'Neu starten';

  @override
  String get statsDetailedTitle => 'Detaillierte Statistiken';

  @override
  String get statsRange7Days => '7 Tage';

  @override
  String get statsRange30Days => '30 Tage';

  @override
  String get statsRange90Days => '90 Tage';

  @override
  String get statsRange1Year => '1 Jahr';

  @override
  String get statsRangeAll => 'Alle';

  @override
  String get statsTabOverview => 'Übersicht';

  @override
  String get statsTabCharts => 'Diagramme';

  @override
  String get statsTabBooks => 'Bücher';

  @override
  String get statsTabAchievements => 'Erfolge';

  @override
  String get statsReadingOverview => 'Leseübersicht';

  @override
  String statsCumulativeHours(Object hours) {
    return 'Insgesamt $hours Stunden';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Halte den Rhythmus — du hast $days Tage in Folge gelesen';
  }

  @override
  String get statsTotalDuration => 'Gesamtzeit';

  @override
  String get statsAvgSession => 'Ø Sitzung';

  @override
  String statsDaysCount(Object count) {
    return '$count Tage';
  }

  @override
  String get statsNoData => 'Keine Daten';

  @override
  String get statsPeriodEarlyMorning => 'Frühmorgens 05:00-08:59';

  @override
  String get statsPeriodMorning => 'Vormittags 09:00-11:59';

  @override
  String get statsPeriodAfternoon => 'Nachmittags 12:00-17:59';

  @override
  String get statsPeriodEvening => 'Abends 18:00-21:59';

  @override
  String get statsPeriodLateNight => 'Nachts 22:00-04:59';

  @override
  String get statsTotalReadingTime => 'Gesamte Lesezeit';

  @override
  String get statsTotalPagesRead => 'Gelesene Seiten gesamt';

  @override
  String get statsBooksReadCount => 'Gelesene Bücher';

  @override
  String get statsUnitPage => 'Seiten';

  @override
  String get statsTodayProgress => 'Heutiger Lesefortschritt';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target Min.';
  }

  @override
  String get statsPagesRead => 'Gelesene Seiten';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target Seiten';
  }

  @override
  String get statsReadingHabits => 'Lesegewohnheiten';

  @override
  String get statsBestReadingPeriod => 'Beste Lesezeit';

  @override
  String get statsAvgSessionReading => 'Ø Sitzungsdauer';

  @override
  String get statsMaxStreakDays => 'Längste Serie';

  @override
  String get statsFocusScore => 'Lesefokus';

  @override
  String get statsBookCount => 'Buchanzahl';

  @override
  String get statsTrendAnalysis => 'Lesetrend-Analyse';

  @override
  String statsAxisMinutes(Object value) {
    return '$value Min.';
  }

  @override
  String statsAxisPages(Object value) {
    return '$value S.';
  }

  @override
  String statsAxisBooks(Object value) {
    return '$value B.';
  }

  @override
  String statsAxisHour(Object hour) {
    return '${hour}h';
  }

  @override
  String get statsTimeDistribution => 'Verteilung der Lesezeit';

  @override
  String get statsFormatDistribution => 'Verteilung der Buchformate';

  @override
  String get statsCompleted => 'Abgeschlossen';

  @override
  String get statsInProgress => 'Am Lesen';

  @override
  String get statsDurationRanking => 'Rangliste nach Lesezeit';

  @override
  String get statsProgressRanking => 'Rangliste nach Lesefortschritt';

  @override
  String statsPagesCount(Object count) {
    return '$count Seiten';
  }

  @override
  String statsSessionCount(Object count) {
    return '$count Sitzungen';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return '$achieved Erfolge erreicht, $remaining weitere zu entsperren';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Erstes Lesen';

  @override
  String get statsAchievementFirstReadDesc =>
      'Schließe deine erste Lesesitzung ab';

  @override
  String get statsAchievementNoviceTitle => 'Lese-Anfänger';

  @override
  String get statsAchievementNoviceDesc => 'Lies insgesamt 10 Stunden';

  @override
  String get statsAchievementBookwormTitle => 'Bücherwurm';

  @override
  String get statsAchievementBookwormDesc => 'Lies insgesamt 100 Stunden';

  @override
  String get statsAchievementExpertTitle => 'Lese-Experte';

  @override
  String get statsAchievementExpertDesc => 'Lies 7 Tage in Folge';

  @override
  String get statsAchievementOceanTitle => 'Ozean des Wissens';

  @override
  String get statsAchievementOceanDesc => 'Lies 10.000 Seiten';

  @override
  String get statsAchievementScholarTitle => 'Universalgelehrter';

  @override
  String get statsAchievementScholarDesc => 'Lies 10 verschiedene Bücher';

  @override
  String get statsAchievementMarathonTitle => 'Lese-Marathon';

  @override
  String get statsAchievementMarathonDesc => 'Lies 30 Tage in Folge';

  @override
  String get statsAchievementFocusTitle => 'Fokus-Meister';

  @override
  String get statsAchievementFocusDesc => 'Lies insgesamt 500 Stunden';

  @override
  String statsProgressPercent(Object percent) {
    return 'Fortschritt: $percent%';
  }

  @override
  String get statsGoalProgress => 'Fortschritt beim Leseziel';

  @override
  String get statsMonthlyReadingTime => 'Lesezeit diesen Monat';

  @override
  String get statsWeeklyReadingTime => 'Lesezeit diese Woche';

  @override
  String get statsAvgDailyPages7d => 'Seiten pro Tag (letzte 7 Tage)';

  @override
  String statsHoursCount(Object count) {
    return '$count Stunden';
  }

  @override
  String get statsSpeedTrend => 'Lesegeschwindigkeits-Trend';

  @override
  String statsAvgSpeed(Object speed) {
    return 'Ø: $speed Seiten/Min.';
  }

  @override
  String get statsReadingContinuity => 'Lesekontinuität';

  @override
  String statsCurrentStreak(Object days) {
    return 'Aktuelle Serie: $days Tage';
  }

  @override
  String get statsHeatmapLess => 'Weniger';

  @override
  String get statsHeatmapMore => 'Mehr';

  @override
  String statsWeekNumber(Object week) {
    return 'Woche $week';
  }

  @override
  String get bookSourceAddToShelf => 'Ins Regal';

  @override
  String get bookSourceAddOnline => 'Online hinzufügen';

  @override
  String get bookSourceAddOnlineHint =>
      'Lies aus der Quelle und zwischenspeichere Kapitel beim Lesen';

  @override
  String get bookSourceDownloadLocal => 'Lokal herunterladen';

  @override
  String get bookSourceDownloadLocalHint =>
      'Lädt jedes Kapitel herunter und fügt eine lokale TXT-Kopie hinzu';

  @override
  String get bookSourceAddedOnline => 'Als Online-Buch ins Regal gestellt';

  @override
  String get bookSourceAlreadyOnShelf =>
      'Dieses Buch ist bereits in deinem Regal';

  @override
  String get bookSourceDownloading => 'Wird lokal heruntergeladen';

  @override
  String get bookSourceFetchingCatalog => 'Kapitelkatalog wird geladen…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return '$completed/$total Kapitel';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Download abgeschlossen und ins lokale Regal gestellt';

  @override
  String get bookSourceDownloadConverted =>
      'Download abgeschlossen. Dies ist jetzt ein lokales Buch';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get downloadTasksTitle => 'Downloads';

  @override
  String get downloadTasksEmpty => 'Keine Download-Aufgaben';

  @override
  String get downloadTaskQueued => 'Wartet auf Download';

  @override
  String get downloadTaskDownloading => 'Wird im Hintergrund heruntergeladen';

  @override
  String get downloadTaskCompleted => 'Download abgeschlossen';

  @override
  String get downloadTaskFailed => 'Download fehlgeschlagen';

  @override
  String get downloadTaskCancelled => 'Abgebrochen';

  @override
  String get downloadTaskCancel => 'Aufgabe abbrechen';

  @override
  String get downloadContinueInBackground => 'Im Hintergrund fortfahren';

  @override
  String get downloadRunningInBackground =>
      'Der Download läuft im Hintergrund weiter';

  @override
  String get bookSourceExitAddTitle => 'Ins Regal stellen?';

  @override
  String bookSourceExitAddMessage(String title) {
    return '„$title“ als Online-Buch in dein Regal stellen? Dein Lesefortschritt bleibt erhalten.';
  }

  @override
  String get bookSourceNotNow => 'Nicht jetzt';

  @override
  String get bookSourceOnlineBadge => 'Online';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'Die Daten des Online-Buchs sind ungültig: $error';
  }

  @override
  String get readerThemeTitle => 'Lese-Design';

  @override
  String get readerThemeDescription =>
      'Ändert nur die Leseseite und ihre Steuerung';

  @override
  String get readerSettingsTabTheme => 'Design';

  @override
  String get readerSettingsTabText => 'Text';

  @override
  String get readerSettingsTabLayout => 'Layout';

  @override
  String get readerSettingsTabPaging => 'Blättern';

  @override
  String get readerSettingsAdvancedTypography => 'Erweiterte Typografie';

  @override
  String get readerAutoPageTurnTitle => 'Automatisches Blättern';

  @override
  String get readerAutoPageTurnOff => 'Nicht gestartet';

  @override
  String get readerAutoPageTurnShortcutTitle =>
      'Kurzbefehl für automatisches Lesen';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Für schnelles Starten oder Pausieren in den Lesesteuerungen zeigen';

  @override
  String get readerAutoPageTurnHint =>
      'Rückt im gewählten Intervall um einen Bildschirm vor, auch im vertikalen Seitenmodus.';

  @override
  String get readerAutoPageTurnModeTimed => 'Zeitgesteuertes Blättern';

  @override
  String get readerAutoPageTurnModeSweep => 'Blättern mit Linie';

  @override
  String get readerAutoPageTurnModeContinuous => 'Fortlaufendes Scrollen';

  @override
  String get readerAutoPageTurnModeInterval => 'Intervall-Scrollen';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Wartet das gewählte Intervall ab und blättert dann zur nächsten Seite.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Eine Linie wandert nach unten und gibt die nächste Seite darüber nach und nach frei.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Scrollt gleichmäßig mit konstanter Lesegeschwindigkeit nach unten.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Wartet das gewählte Intervall ab und scrollt dann um etwa einen Bildschirm nach unten.';

  @override
  String get readerAutoPageTurnSweepDurationLabel => 'Durchlaufdauer';

  @override
  String get readerAutoPageTurnScrollSpeedLabel => 'Scrollgeschwindigkeit';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds Sekunden pro Bildschirm';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · ${seconds}s/Bildschirm';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'Pausiert · $mode · ${seconds}s/Bildschirm';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Seitenintervall';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds Sekunden pro Bildschirm';
  }

  @override
  String get readerAutoPageTurnStart => 'Automatisches Blättern starten';

  @override
  String get readerAutoPageTurnResume => 'Automatisches Blättern fortsetzen';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Auto · ${seconds}s/Bildschirm';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'Pausiert · ${seconds}s/Bildschirm';
  }

  @override
  String get readerThemeDay => 'Tag';

  @override
  String get readerThemeFollowSystem => 'System folgen';

  @override
  String get readerThemeMist => 'Nebel';

  @override
  String get readerThemeGreen => 'Augenschonend';

  @override
  String get readerThemeRose => 'Rose';

  @override
  String get readerThemeNavy => 'Tiefblau';

  @override
  String get readerThemeNight => 'Nacht';

  @override
  String get readerThemePureBlack => 'Reinschwarz';

  @override
  String get readerThemeParchment => 'Pergament';

  @override
  String get readerThemeCustom => 'Eigene';

  @override
  String get readerPullBookmarkTitle => 'Lesezeichen durch Herunterziehen';

  @override
  String get readerPullBookmarkHint =>
      'Ziehe vom oberen Rand nach unten und lass los, um ein Lesezeichen für diese Seite hinzuzufügen oder zu entfernen';

  @override
  String get readerPullBookmarkAddHint =>
      'Weiter ziehen, um das Lesezeichen hinzuzufügen';

  @override
  String get readerPullBookmarkRemoveHint =>
      'Weiter ziehen, um das Lesezeichen zu entfernen';

  @override
  String get readerPullBookmarkReleaseHint => 'Loslassen zum Abschließen';

  @override
  String get readerTapAnimationTitle => 'Tipp-Animation';

  @override
  String get readerTapAnimationHint =>
      'Nutzt die aktuelle Blätter-Animation für seitliche Tips; ausschalten für sofortige Aktualisierung';

  @override
  String get readerTabletTwoPageTitle => 'Zweiseiten-Layout für Tablets';

  @override
  String get readerTabletTwoPageHint =>
      'Zeigt im Querformat linke und rechte Seite nebeneinander; ausschalten, um immer nur eine Seite zu verwenden';

  @override
  String get readerCustomThemeTitle => 'Eigenes Lese-Design';

  @override
  String get readerCustomThemeReset => 'Zurücksetzen';

  @override
  String get readerCustomThemeColors => 'Design-Farben';

  @override
  String get readerCustomThemeTextColor => 'Textfarbe';

  @override
  String get readerCustomThemeTextColorHint =>
      'Fließtext, Überschriften und Hauptsymbole';

  @override
  String get readerCustomThemeBackground => 'Lese-Hintergrund';

  @override
  String get readerCustomThemeBackgroundHint =>
      'Die Papier- und Leseflächenfarbe';

  @override
  String get readerCustomThemeControlBar => 'Farbe der Steuerleiste';

  @override
  String get readerCustomThemeControlBarHint =>
      'Obere und untere Steuerungen sowie Einstellungsflächen';

  @override
  String get readerCustomThemeContrastGood =>
      'Der Text hat klaren Kontrast für entspanntes Langlesen';

  @override
  String get readerCustomThemeContrastLow =>
      'Der Textkontrast ist gering und kann Lesermüdigkeit verursachen';

  @override
  String get readerCustomThemeSave => 'Speichern und verwenden';

  @override
  String get readerCustomThemePreview => 'Live-Vorschau';

  @override
  String get readerCustomThemePreviewChapter =>
      'Kapitel eins · Wind zwischen den Seiten';

  @override
  String get readerCustomThemePreviewBody =>
      'Dies ist dein Leseraum. Stimme Text-, Papier- und Steuerfarben ab, bis sich jede Seite klar wie deine anfühlt.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Gib einen sechstelligen Hex-Farbcode ein, z. B. #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Hex-Farbe';

  @override
  String get readerCustomThemesTitle => 'Eigene Lese-Designs';

  @override
  String get readerCustomThemeAdd => 'Design hinzufügen';

  @override
  String get readerCustomThemeReorderHint =>
      'Halte den Griff rechts, um Designs zu sortieren. Dieselbe Reihenfolge erscheint in den Leseeinstellungen.';

  @override
  String get readerCustomThemeUse => 'Ausgewähltes Design verwenden';

  @override
  String get readerCustomThemeDeleteTitle => 'Lese-Design löschen?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return '„$name“ wird samt gespeichertem Hintergrundbild aus deinen Designs entfernt.';
  }

  @override
  String get readerCustomThemeEmptyTitle => 'Noch keine eigenen Designs';

  @override
  String get readerCustomThemeEmptyHint =>
      'Erstelle deine eigene Kombination aus Schrift, Papierfarbe und Hintergrundbild.';

  @override
  String get readerCustomThemeNewTitle => 'Neues Lese-Design';

  @override
  String get readerCustomThemeEditTitle => 'Lese-Design bearbeiten';

  @override
  String get readerCustomThemeName => 'Designname';

  @override
  String get readerCustomThemeNameHint =>
      'Zum Beispiel Regennacht oder Nachmittagspapier';

  @override
  String get readerCustomThemeBackgroundImage => 'Hintergrundbild';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Unterstützt JPG, PNG und WebP. Das Bild wird in den App-Speicher kopiert.';

  @override
  String get readerCustomThemeChooseImage => 'Bild hochladen';

  @override
  String get readerCustomThemeReplaceImage => 'Bild ersetzen';

  @override
  String get readerCustomThemeRemoveImage => 'Bild entfernen';

  @override
  String get readerCustomThemeImageStrength => 'Stärke des Hintergrundbilds';

  @override
  String get readerCustomThemeImageUnsupported =>
      'Der Import von Hintergrundbildern wird auf dieser Plattform nicht unterstützt';

  @override
  String get readerCustomThemeImageTooLarge =>
      'Das Bild darf nicht größer als 20 MB sein';

  @override
  String get readerCustomThemeImageFormat =>
      'Wähle ein JPG-, PNG- oder WebP-Bild';

  @override
  String get readerCustomThemeImageFailed =>
      'Das Hintergrundbild konnte nicht importiert werden. Versuche es erneut.';

  @override
  String get importSourceTitle => 'Bücher hinzufügen';

  @override
  String get importSourceDescription =>
      'Wähle zuerst mehrere Dateien. Prüfe die Warteschlange, bevor du den Import startest.';

  @override
  String get importSelectFiles => 'Dateien wählen';

  @override
  String get importIosSharedDocuments => 'Auf meinem iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'iCloud Drive ist nicht verfügbar';

  @override
  String get importAndroidFolder => 'Buchordner autorisieren';

  @override
  String get importAndroidRescan => 'Autorisierte Ordner durchsuchen';

  @override
  String get importFolderPermissionAvailable =>
      'Autorisiert · zum Durchsuchen tippen';

  @override
  String get importFolderPermissionLost =>
      'Berechtigung verloren · zum Wiederherstellen des Zugriffs erneut autorisieren';

  @override
  String get importRemoveFolder => 'Ordner entfernen';

  @override
  String importQueueTitle(int count) {
    return 'Import-Warteschlange ($count)';
  }

  @override
  String get importQueueHint =>
      'Entferne fälschlich ausgewählte Dateien und importiere sie dann nacheinander.';

  @override
  String get importQueueEmptyTitle => 'Keine Bücher ausgewählt';

  @override
  String get importQueueEmptyBody =>
      'Wähle EPUB, PDF, TXT, MOBI oder eine andere unterstützte Buchdatei.';

  @override
  String importAction(int count) {
    return '$count Bücher importieren';
  }

  @override
  String importRetryFailed(int count) {
    return '$count fehlgeschlagene erneut versuchen';
  }

  @override
  String get importStatusQueued => 'Wartend';

  @override
  String get importStatusPreparing => 'Datei wird vorbereitet';

  @override
  String get importStatusChecking => 'Prüfen';

  @override
  String get importStatusCopying => 'Kopieren';

  @override
  String get importStatusAnalyzing => 'Analysieren';

  @override
  String get importStatusSaving => 'Speichern';

  @override
  String get importStatusImported => 'Importiert';

  @override
  String get importStatusSkipped => 'Existiert bereits, übersprungen';

  @override
  String get importStatusFailed => 'Import fehlgeschlagen';

  @override
  String get importRemove => 'Entfernen';

  @override
  String get importRetry => 'Erneut versuchen';

  @override
  String get importClearCompleted => 'Fertige entfernen';

  @override
  String get importDone => 'Fertig';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return '$succeeded importiert · $skipped übersprungen · $failed fehlgeschlagen';
  }

  @override
  String get importNoSupportedFiles =>
      'Es wurden keine unterstützten Buchdateien gefunden';

  @override
  String get importScanning => 'Dateien werden durchsucht…';

  @override
  String get settingsAiApiKeyConfigured => 'API Key konfiguriert';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Tippe, um die Einrichtung abzuschließen';

  @override
  String get settingsAiAddModel => 'Modell hinzufügen';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Gewechselt zu $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Bitte fülle zuerst Base URL und API Key aus';

  @override
  String get settingsAiEditModelTitle => 'Modell konfigurieren';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Jede Schnellkarte ist einem Modell zugeordnet';

  @override
  String get settingsAiPresetModel => 'Voreingestelltes Modell';

  @override
  String get settingsAiBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'OpenAI-kompatibel: Die Base URL muss üblicherweise /v1 enthalten (z. B. https://example.com/v1). Die App hängt /chat/completions an.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic: Die Base URL darf /v1 enthalten oder weglassen. Die App vermeidet doppelte /v1 und hängt /messages an.';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiModelNameLabel => 'Modellname';

  @override
  String get settingsAiFetchModelsTooltip => 'Modelle automatisch abrufen';

  @override
  String get settingsAiFetchModelsList => 'Modellliste automatisch abrufen';

  @override
  String get settingsAiSelectModel => 'Modell auswählen';

  @override
  String get settingsAiTemperatureLabel => 'Temperature';

  @override
  String get settingsAiAddAndEnable => 'Hinzufügen und aktivieren';

  @override
  String get settingsAiModelMismatchClaude =>
      'Claude-Modellnamen beginnen üblicherweise mit \"claude\". Bitte prüfe, dass Anbieter und Modell zusammenpassen.';

  @override
  String get settingsAiModelMismatchGemini =>
      'Gemini-Modellnamen enthalten üblicherweise \"gemini\". Bitte prüfe, dass Anbieter und Modell zusammenpassen.';

  @override
  String get settingsAiModelMismatchGlm =>
      'GLM-Modellnamen beginnen üblicherweise mit \"glm\". Bitte prüfe, dass Anbieter und Modell zusammenpassen.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'MiniMax-Modellnamen enthalten üblicherweise \"MiniMax\". Bitte prüfe, dass Anbieter und Modell zusammenpassen.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Format der Modelllisten-Antwort nicht erkannt';

  @override
  String get settingsAiNoModelsReturned =>
      'Der Server hat keine verfügbare Modellliste zurückgegeben';

  @override
  String get settingsAiNoModelsAvailable => 'Keine Modelle verfügbar';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Modelle konnten nicht abgerufen werden: $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'AI-Buchvorverarbeitung';

  @override
  String get settingsAiPreprocessSubtitle =>
      'Lass AI nach dem Import eines Buchs dieses lesen und automatisch eine lokale Wissensbasis mit Zusammenfassungen aufbauen';

  @override
  String get settingsAiPreprocessWarning =>
      'Die Vorverarbeitung sendet das ganze Buch in Teilen an das AI-Modell. Sie verbraucht viele Tokens und dauert eine Weile. Trotzdem aktivieren?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Konfiguriere zuerst ein funktionsfähiges AI-Modell mit API Key';

  @override
  String get libraryAiPreprocess => 'AI-Vorverarbeitung';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return 'AI soll \"$title\" lesen und eine Wissensbasis mit Zusammenfassungen aufbauen? Dies verbraucht viele Tokens.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'AI liest dieses Buch… (Schritt $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'AI-Wissensbasis erstellt';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'AI-Vorverarbeitung fehlgeschlagen: $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Dieses Buchformat unterstützt die AI-Vorverarbeitung noch nicht';

  @override
  String get libraryAiPreprocessQueued =>
      'Zur AI-Vorverarbeitungswarteschlange hinzugefügt. Prüfe den Fortschritt unter Downloads.';

  @override
  String get downloadTasksTabDownloads => 'Downloads';

  @override
  String get aiPreprocessTaskRunning => 'AI liest…';

  @override
  String get aiPreprocessTasksEmpty => 'Keine AI-Vorverarbeitungsaufgaben';

  @override
  String get aiPreprocessClearFinished => 'Fertige entfernen';

  @override
  String get aiChatNewChat => 'Neuer Chat';

  @override
  String get aiChatSelectBook => 'Buch verknüpfen';

  @override
  String get aiChatNoBook => 'Kein verknüpftes Buch';

  @override
  String get navAi => 'AI';

  @override
  String get aiHistoryTitle => 'AI-Chats';

  @override
  String get aiHistoryEmpty =>
      'Noch keine AI-Chats.\nTippe beim Lesen auf „AI fragen“, um dein erstes Gespräch zu starten.';

  @override
  String aiHistoryMessageCount(int count) {
    return '$count Nachrichten';
  }

  @override
  String get aiHistoryClearAll => 'Alle löschen';

  @override
  String get aiHistoryClearAllConfirm =>
      'Den gesamten AI-Chatverlauf löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get aiHistoryDeleteConfirm => 'Diesen Chat löschen?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Schalte einen Schalter aus, um die Seite auszublenden; Einstellungen lassen sich nicht ausblenden.';

  @override
  String get readerAskAi => 'AI fragen';

  @override
  String get readerAiInputHint => 'Frag etwas zu diesem Buch…';

  @override
  String get readerAiSendButton => 'Senden';

  @override
  String get readerAiThinking => 'Denkt nach…';

  @override
  String get readerAiNotConfiguredHint =>
      'Es ist noch kein AI-Modell konfiguriert. Gehe zu Einstellungen → AI-Leseassistent, um Modell und API Key hinzuzufügen.';

  @override
  String get readerAiEmptyHint =>
      'Frag die AI zur aktuellen Seite oder zu allem in diesem Buch.';

  @override
  String get readerAiSelectionQuestionLabel => 'Diese Auswahl erklären';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Erkläre die untenstehende ausgewählte Passage und nenne 3 Kernpunkte.\n\nAusgewählter Text:\n$selection\n\nKontext davor:\n$before\n\nKontext danach:\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst =>
      'Bitte gib vor dem Senden eine Frage ein';

  @override
  String get readerAiEmptyResponse =>
      'Das Modell hat eine leere Antwort zurückgegeben, bitte erneut versuchen';

  @override
  String readerAiRequestFailed(String error) {
    return 'Anfrage fehlgeschlagen: $error';
  }

  @override
  String get readerAiUnknownError => 'Unbekannter Fehler';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'Die Server-Antwort ist leer. Ursache ist meist eine falsche Base URL, ein Gateway, das nicht an den Modell-Endpunkt weiterleitet, oder ein früher Verbindungsabbau durch den Server.\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'Die Server-Antwort ist kein gültiges JSON. Der aktuelle Endpunkt ist möglicherweise inkompatibel mit der $provider-Konfiguration.\nAnfrage-URL: $endpoint\nAntwort-Auszug: $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Anfrage fehlgeschlagen$status: Die Server-Antwort konnte nicht gelesen werden. Ursache ist meist eine falsche Base URL, ein Endpunkt ohne Inhalt oder eine vom Netzwerk abgeschnittene Antwort.\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Netzwerkanfrage fehlgeschlagen$status: $error\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Anfrage fehlgeschlagen($status): $text\nVorschläge: 1) Die MiniMax-Temperature muss in (0,1] liegen; 2) prüfe, dass der Modellname zum Endpunkt passt; 3) verwende nur eine einzige Systemanweisung.\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Anfrage fehlgeschlagen($status): $text\nTipp: Claude erfordert den Anfrage-Header anthropic-version.\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Anfrage fehlgeschlagen($status): $text\nTipp: Bitte bestätige, dass Anbieter und API Key zusammenpassen; sie lassen sich nicht mischen.\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Anfrage fehlgeschlagen($status): $text\nAnfrage-URL: $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'AI (Test): Der von dir ausgewählte Text ist \"$selectedText\".\n\nDavor: $before\nDanach: $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'AI (Test): Diese Seite hat $chars Zeichen. Achte auf die Argumente am Anfang und Ende der Absätze.';
  }

  @override
  String get readerAiMockGreeting => 'Hallo';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'AI (Test): Du hast gefragt: \"$question\".\n\nIch habe die aktuelle Seite gelesen ($chars Zeichen). Du kannst weiterfragen.';
  }

  @override
  String get ttsSystemDefault => 'Systemstandard';

  @override
  String get ttsUnavailable => 'System-TTS nicht verfügbar';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'Das System unterstützt die Sprache nicht: $language';
  }

  @override
  String get ttsCallFailed => 'System-TTS-Aufruf fehlgeschlagen';

  @override
  String get importErrorSourceMissing => 'Die Quelldatei existiert nicht';

  @override
  String get importErrorHashFailed =>
      'Der Dateiinhalt kann nicht verifiziert werden';

  @override
  String get importErrorTargetNameExhausted =>
      'Es kann kein freier Name für die Importdatei gefunden werden';

  @override
  String get importErrorSourceNotMaterialized =>
      'Die Quelldatei ist noch nicht im lokalen Speicher';

  @override
  String get importErrorCopyVerificationFailed =>
      'Die kopierte Datei stimmt nicht mit der Quelle überein';

  @override
  String get importErrorFileTooLarge =>
      'Die Datei überschreitet die Importgrenze von 500 MB';

  @override
  String get importErrorSourcePrepareFailed =>
      'Die Importdatei kann nicht vorbereitet werden';

  @override
  String get importErrorFailed => 'Buchimport fehlgeschlagen';

  @override
  String get importUnknownTitle => 'Unbekannter Titel';

  @override
  String get importUnknownAuthor => 'Unbekannter Autor';

  @override
  String get bookUntitled => 'Ohne Titel';

  @override
  String get accentPurple => 'Elegantes Lila';

  @override
  String get accentPink => 'Kirschrosa';

  @override
  String get accentCyan => 'Frisches Cyan';

  @override
  String get accentBrown => 'Klassisches Braun';

  @override
  String get accentGrey => 'Elegantes Grau';

  @override
  String get accentDeepPurple => 'Charmantes Violett';

  @override
  String get accentAmber => 'Bernsteingold';

  @override
  String get accentLightGreen => 'Lebhaftes Grün';

  @override
  String get accentYellow => 'Sonnengelb';

  @override
  String get accentNeutralGrey => 'Minimalistisches Grau';

  @override
  String get accentIndigo => 'Tiefes Indigo';

  @override
  String get accentDeepOrange => 'Flammenorange';

  @override
  String get agreementV2HeroTitle => 'Lies weiter auf deinem eigenen Gerät.';

  @override
  String get agreementV2HeroBody =>
      'Origo X ist ein quelloffener, plattformübergreifender, lokal orientierter E-Book-Reader. Er bietet Lesewerkzeuge; die von dir importierten Bücher stellt er weder bereit, hostet sie noch prüft er sie.';

  @override
  String get agreementV2LocalTitle => 'Lokal zuerst';

  @override
  String get agreementV2LocalBody =>
      'Bücher, Fortschritt und Notizen bleiben im Allgemeinen auf deinem Gerät, damit du sie verwalten und sichern kannst.';

  @override
  String get agreementV2OpenSourceTitle => 'Unter AGPL-3.0 lizenziert';

  @override
  String get agreementV2OpenSourceBody =>
      'Der Quellcode wird unter GNU AGPL v3.0 bereitgestellt, und die Software wird „wie besehen“ und ohne Garantien geliefert.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Bedingungsversion $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Einführung';

  @override
  String get agreementFlowStepTerms => 'Bedingungen';

  @override
  String get agreementFlowStepSource => 'Buchquellen';

  @override
  String get agreementFlowStepPrivacy => 'Datenschutz';

  @override
  String get agreementFlowNext => 'Weiter';

  @override
  String get agreementFlowBack => 'Zurück';

  @override
  String get agreementFlowTermsTitle => 'Origo X mit klaren Grenzen nutzen';

  @override
  String get agreementFlowTermsSubtitle =>
      'Prüfe die Bedingungen für die Nutzung der Software und der Inhalte, die du öffnen möchtest.';

  @override
  String get agreementFlowTermsConsent =>
      'Ich habe die Nutzungsbedingungen gelesen und stimme ihnen zu.';

  @override
  String get agreementFlowSourceTitle =>
      'Vereinbarung zu Buchquellen von Drittanbietern';

  @override
  String get agreementFlowSourceSubtitle =>
      'Bestätige, wie Quelladressen, Inhalte, Berechtigungen und Verantwortung vom offiziellen Projekt getrennt sind.';

  @override
  String get agreementFlowSourceConsent =>
      'Ich habe die Vereinbarung zu Buchquellen von Drittanbietern gelesen und stimme ihr zu.';

  @override
  String get agreementFlowPrivacyTitle =>
      'Deine Daten bleiben unter deiner Kontrolle';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Prüfe, was lokal bleibt, wann Netzwerkanfragen erfolgen und wie Download-Einträge aufbewahrt werden.';

  @override
  String get agreementFlowPrivacyConsent =>
      'Ich habe die Datenschutzerklärung gelesen und stimme ihr zu.';

  @override
  String get agreementFlowEnterApp => 'Origo X öffnen';

  @override
  String get agreementFlowPrivacyLocalTitle => 'Standardmäßig lokal';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Bücher, Fortschritt, Notizen und Einstellungen bleiben normalerweise auf diesem Gerät.';

  @override
  String get agreementFlowPrivacyNetworkTitle =>
      'Netzwerknutzung ist ausdrücklich';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'Lokales Lesen lädt keinen Buchtext hoch. Update-Prüfungen kontaktieren GitHub und die offizielle Website; Quellen, AI und Sync verbinden sich nur, wenn ihre Funktionen genutzt werden.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Begrenzte Download-Einträge';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'Download-Einträge der offiziellen Website mit vollständiger IP-Adresse werden höchstens 180 Tage aufbewahrt und dann gelöscht.';

  @override
  String get agreementV2Title => 'Nutzungsbedingungen & Datenschutzerklärung';

  @override
  String get agreementV2Subtitle =>
      'Bitte lies dies, bevor du Origo X verwendest';

  @override
  String get agreementV2ImportantNotice =>
      'Wichtig: Die offizielle Origo-X-App installiert keine Buchquellen von Drittanbietern vor, bündelt oder empfiehlt sie nicht, und ihre Entwickler betreiben, vertreten oder hosten keine Quellinhalte. Du wählst jede importierte Datei und jede hinzugefügte Quelle selbst; verwende nur Inhalte, für die du zugangsberechtigt bist.';

  @override
  String get agreementV2SourceBoundaryTitle =>
      'Grenze zu Quellen von Drittanbietern';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'Das offizielle Projekt stellt nur quelloffene Reader-Software und das Origo Source Protocol bereit. Es liefert keine Quelladressen und kein offizielles Quellenverzeichnis.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Jede Quelladresse musst du selbst eingeben und hinzufügen. Die App verbindet sich direkt mit diesem unabhängigen Dienst, ohne Inhalte über einen Server der Entwickler zu leiten.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'Protokollkompatibilität bedeutet nur, dass sich eine Schnittstelle verbinden kann; sie beweist weder Rechtmäßigkeit noch Lizenzen. Quellenbetreiber sind für ihre Inhalte verantwortlich, und du musst sie prüfen und gesetzeskonform verwenden.';

  @override
  String get agreementV2Section1Title => 'Geltungsbereich und Annahme';

  @override
  String get agreementV2Section1Body =>
      'Diese Bedingungen gelten für Herunterladen, Installation und Nutzung von Origo X und seinen enthaltenen Funktionen. Mit der Auswahl von „Zustimmen und fortfahren“ bestätigst du, dass du sie gelesen, verstanden und akzeptiert hast. Wenn du nicht zustimmst, beende die Nutzung und verlasse die App. Wo örtliches Recht es verlangt, muss ein Erziehungsberechtigter zustimmen.';

  @override
  String get agreementV2Section2Title => 'Open-Source-Lizenz';

  @override
  String get agreementV2Section2Body =>
      'Künftige Origo-X-Versionen werden unter der GNU Affero General Public License v3.0 veröffentlicht. Du darfst die Software unter dieser Lizenz verwenden, kopieren, ändern, verbreiten oder verkaufen. Eine vertriebene geänderte Version muss ihren vollständigen entsprechenden Quellcode unter AGPL-3.0 bereitstellen, und eine geänderte Version, die einen Netzwerkdienst anbietet, muss den damit interagierenden Nutzern ebenfalls den entsprechenden Quellcode anbieten. Für v1.0.0 und frühere Versionen bereits gewährte MIT-Rechte bleiben gültig und werden nicht widerrufen. Diese Bedingungen beschränken keine Rechte aus der Open-Source-Lizenz. Komponenten von Drittanbietern unterliegen weiterhin ihren eigenen Lizenzen.';

  @override
  String get agreementV2Section3Title => 'Nutzerinhalte und Rechte';

  @override
  String get agreementV2Section3Body =>
      '„Nutzerinhalte“ umfassen Bücher, Dokumente, Bilder, Metadaten, Links und anderes Material, das du importierst, herunterlädst, öffnest, konvertierst, zwischenspeicherst, kommentierst oder vorlesen lässt. Du musst über alle für die Nutzung erforderlichen Rechte und Erlaubnisse verfügen. Du bist allein verantwortlich für Urheberrecht, Marken, Privatsphäre, Verleumdung, rechtswidrige Inhalte, Schadsoftware und sonstige Ansprüche oder Verluste im Zusammenhang mit Nutzerinhalten. Die Software und ihre Entwickler laden diese Inhalte nicht hoch, verkaufen, lizenzieren, empfehlen oder prüfen sie nicht, und Formatunterstützung bedeutet keine rechtliche Erlaubnis zur Nutzung einer Datei.';

  @override
  String get agreementV2Section4Title => 'Verbotene Nutzung';

  @override
  String get agreementV2Section4Body =>
      'Du darfst die Software nicht verwenden, um geistiges Eigentum oder andere Rechte zu verletzen, rechtswidrige, schädliche oder bösartige Inhalte zu verbreiten, DRM, Zugriffskontrollen oder Bezahlschranken zu umgehen, Systeme Dritter anzugreifen oder zu stören oder gegen anwendbares Recht verstoßende Aktivitäten auszuüben. Du bist verantwortlich für Beschwerden, Ansprüche, Strafen und Verluste, die aus deinem Verhalten entstehen.';

  @override
  String get agreementV2Section5Title => 'Buchquellen und Drittanbieter';

  @override
  String get agreementV2Section5Body =>
      'Die offizielle App installiert keine Buchquellen vor, verbreitet oder empfiehlt sie nicht und betreibt kein offizielles Quellenverzeichnis. Quellen, Netzwerk-APIs, externe Links, Online-Inhalte, System-Text-to-Speech, AI-Dienste und weitere von dir hinzugefügte Integrationen werden unabhängig von Drittanbietern bereitgestellt und kontrolliert. Sie werden von den Entwicklern weder betrieben, vertreten, lizenziert, empfohlen noch geprüft. Quellenbetreiber tragen die rechtliche Verantwortung für die von ihnen bereitgestellten Inhalte. Prüfe vor dem Hinzufügen Herkunft, Inhaltsrechte, Datenschutzerklärung und Bedingungen; du bist verantwortlich für deinen eigenen Zugriff, deine Downloads, Zwischenspeicherung, Weitergabe und sonstige Nutzung. Im vom anwendbaren Recht zugelassenen Umfang haften die Entwickler nicht für Inhalte, Kosten, Datenpraktiken, Ausfälle oder Urheberrechtsstreitigkeiten Dritter.';

  @override
  String get agreementV2Section6Title => 'Daten und Datenschutz';

  @override
  String get agreementV2Section6Body =>
      'Origo X ist lokal orientiert. Bücher, Lesefortschritt, Notizen und Einstellungen werden normalerweise auf deinem Gerät gespeichert. Sofern du keine Netzwerkbuchquelle, AI, Sync oder eine andere Online-Funktion aktivierst, muss die App für das lokale Lesen keinen Buchtext an die Entwickler senden. Automatische und manuelle Update-Prüfungen kontaktieren GitHub und die offizielle Website open.xxread.top mit nötigen technischen Parametern wie Plattform, Prozessorarchitektur und Release-Kanal; deren Server verarbeiten deine IP-Adresse und deinen User-Agent als Teil des gewöhnlichen Netzwerkverkehrs. Wenn du ein Installationspaket von der offiziellen Website lädst, erfasst das Backend Version, Architektur, Download-Zeitpunkt, IP-Adresse und User-Agent für Download-Zähler, Sicherheitsmaßnahmen und Fehlersuche. Download-Ereigniseinträge mit vollständiger IP-Adresse werden höchstens 180 Tage aufbewahrt und dann gelöscht; länger aufbewahrt werden nur aggregierte Statistiken ohne vollständige IP-Adressen. Update-Anfragen enthalten keinen Buchtext, dein Regal, deine Notizen, ein Konto oder eine eindeutige Gerätekennung. GitHub-Anfragen unterliegen zusätzlich den Datenschutzbestimmungen von GitHub. Bei Nutzung einer anderen Online-Funktion können Anfragen, ausgewählter Text, Netzwerkinformationen oder nötige Parameter unter den Richtlinien des von dir gewählten Anbieters an diesen gesendet werden. Schütze dein Gerät, deine API Keys und deine Sicherungen; Deinstallation, Datenlöschung, Gerätedefekte oder Bedienfehler können Daten endgültig löschen.';

  @override
  String get agreementV2Section7Title => 'AI und automatisierte Ausgaben';

  @override
  String get agreementV2Section7Body =>
      'AI-Zusammenfassungen, Antworten, Übersetzungen, Empfehlungen und andere generierte Ausgaben können ungenau, unvollständig, veraltet oder irreführend sein. Sie sind nur Lesehilfen und keine rechtliche, medizinische, finanzielle, akademische oder sonstige professionelle Beratung. Prüfe Ausgaben unabhängig und verlasse dich bei riskanten Entscheidungen nicht auf sie. Material, das an einen AI-Anbieter übermittelt wird, unterliegt zusätzlich dessen Bedingungen.';

  @override
  String get agreementV2Section8Title => 'Ausschluss von Garantien';

  @override
  String get agreementV2Section8Body =>
      'Im vom Recht zugelassenen Umfang werden die Software und zugehörige Materialien „wie besehen“ und „wie verfügbar“ bereitgestellt, ohne ausdrückliche, stillschweigende oder gesetzliche Garantien, einschließlich Marktgängigkeit, Eignung für einen bestimmten Zweck, Eigentum, Nichtverletzung von Rechten, Genauigkeit, Kompatibilität, Sicherheit, fehlerfreiem Betrieb, ununterbrochener Verfügbarkeit oder Erhalt von Daten. Open-Source-Beitragende haben keine Pflicht, die Software zu pflegen, zu aktualisieren, zu unterstützen oder zu beheben.';

  @override
  String get agreementV2Section9Title => 'Haftungsbeschränkung';

  @override
  String get agreementV2Section9Body =>
      'Im vom Recht zugelassenen Umfang haften Entwickler, Urheberrechtsinhaber und Beitragende nicht für direkte, indirekte, zufällige, besondere, Straf- oder Folgeschäden aus Installation, Nutzung, Nichtnutzung, Nutzerinhalten, Diensten Dritter, Datenverlust, Geräteproblemen, Geschäftsunterbrechung oder Sicherheitsvorfällen, gleich aus Vertrag, Delikt oder anderer Grundlage. Haftung, die rechtlich nicht ausgeschlossen werden kann, bleibt auf das gesetzlich zulässige Mindestmaß beschränkt.';

  @override
  String get agreementV2Section10Title => 'Freistellung';

  @override
  String get agreementV2Section10Body =>
      'Soweit anwendbares Recht es erlaubt, bist du verantwortlich und stellst Entwickler, Urheberrechtsinhaber und Beitragende von Ansprüchen Dritter, Untersuchungen, Strafen, Verlusten und angemessenen Kosten frei, die aus deinen Nutzerinhalten, rechtswidrigem oder rechtsverletzendem Verhalten, einem Bruch dieser Bedingungen oder der Nutzung von Diensten Dritter entstehen.';

  @override
  String get agreementV2Section11Title => 'Änderungen, Beendigung und Recht';

  @override
  String get agreementV2Section11Body =>
      'Funktionen, Pflegezustand und diese Bedingungen können sich ändern, wenn das Open-Source-Projekt, das Recht oder die Risikokontrolle sich weiterentwickeln. Wesentliche Änderungen können eine erneute Zustimmung erfordern; wenn du nicht einverstanden bist, beende die Nutzung der App. Du kannst die App jederzeit deinstallieren. Streitigkeiten sollten zuerst einvernehmlich gelöst werden. Vorbehaltlich zwingender Verbraucherschutzvorschriften gelten das Recht am Ort des Entwicklers und Gerichte mit rechtmäßiger Zuständigkeit. Ist eine Bestimmung nicht durchsetzbar, bleibt der Rest wirksam.';

  @override
  String get agreementV2ConfirmLabel =>
      'Ich habe die Nutzungsbedingungen und die Datenschutzerklärung gelesen und stimme ihnen zu.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Ich verstehe, dass das offizielle Projekt keine Buchquellen bereitstellt; Quellen und Inhalte, die ich hinzufüge, stammen von unabhängigen Drittanbietern, und ich werde die Berechtigung prüfen und für meine eigene Nutzung verantwortlich bleiben.';

  @override
  String get agreementV2ExitLabel => 'Ablehnen';

  @override
  String get agreementV2ContinueLabel => 'Zustimmen und fortfahren';

  @override
  String get agreementV2ExitDialogTitle => 'Bedingungen ablehnen?';

  @override
  String get agreementV2ExitDialogBody =>
      'Du musst die Nutzungsbedingungen akzeptieren, um Origo X weiter zu verwenden. Wenn du nicht zustimmst, verlasse bitte die App.';

  @override
  String get agreementV2CancelLabel => 'Zurück';

  @override
  String get agreementV2ConfirmExitLabel => 'Beenden';

  @override
  String get agreementV2SaveFailed =>
      'Deine Zustimmung konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get settingsDataSyncTitle => 'Daten & Sync';

  @override
  String get settingsCacheManagementTitle => 'Cache-Verwaltung';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return 'Belegt $size · Details ansehen und Caches leeren';
  }

  @override
  String get settingsCacheUsageTitle => 'Cache-Nutzung';

  @override
  String get settingsCacheTotalUsage => 'Gesamt belegt';

  @override
  String get settingsCacheSafeHint =>
      'Nur sicher entfernbare Caches werden angezeigt. Bücher, Lesefortschritt und Einstellungen sind nicht enthalten.';

  @override
  String get settingsCacheSourceCovers => 'Quellen-Cover-Cache';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Heruntergeladene Quellen-Cover · $size';
  }

  @override
  String get settingsCacheSourceData => 'Quellen-Kapitel-Cache';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Sicher entfernbarer Online-Kapitel-Cache · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Lokaler Lese-Cache';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Wieder aufbaubarer EPUB/TXT/Kindle-Parsing-Cache · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'Temporäre Dateien';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'Wegwerfbare Update- und temporäre Dateien · $size';
  }

  @override
  String get settingsCacheClearAll => 'Alle sicheren Caches leeren';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Leert nur die obigen Kategorien · $size';
  }

  @override
  String get settingsCacheCalculating => 'Wird berechnet…';

  @override
  String get settingsCacheClearConfirm =>
      'Dies entfernt nur temporäre Cache-Daten. Bücher, gespeicherte Cover, Lesefortschritt, Datenbanken, Einstellungen und Zugangsdaten bleiben erhalten.';

  @override
  String get settingsCacheClearAction => 'Leeren';

  @override
  String get settingsCacheCleared => 'Cache geleert';

  @override
  String get settingsCacheClearFailed =>
      'Der Cache konnte nicht geleert werden';

  @override
  String get settingsWebDavSyncTitle => 'WebDAV-Sync';

  @override
  String get webDavNotConfigured => 'Nicht konfiguriert';

  @override
  String get webDavConfigureSubtitle =>
      'Lesedaten mit deinem eigenen WebDAV-Speicher synchronisieren';

  @override
  String get webDavBetaBadge => 'Beta · Kann instabil sein';

  @override
  String get webDavPageTitle => 'WebDAV-Sync';

  @override
  String get webDavConnected => 'Verbunden';

  @override
  String get webDavSyncing => 'Wird synchronisiert';

  @override
  String get webDavPartialFailure => 'Einige Einträge brauchen Aufmerksamkeit';

  @override
  String get webDavSyncFailed => 'Sync fehlgeschlagen';

  @override
  String webDavPendingChanges(int count) {
    return '$count Änderungen warten auf Sync';
  }

  @override
  String webDavLastSync(String time) {
    return 'Letzter Sync: $time';
  }

  @override
  String get webDavNeverSynced => 'Noch nicht synchronisiert';

  @override
  String get webDavSyncNow => 'Jetzt synchronisieren';

  @override
  String get webDavSetUp => 'WebDAV einrichten';

  @override
  String get webDavConnectionTitle => 'Verbindung';

  @override
  String get webDavServerUrl => 'WebDAV-Adresse';

  @override
  String get webDavUsername => 'Benutzername';

  @override
  String get webDavPassword => 'App-Passwort';

  @override
  String get webDavPasswordHint =>
      'Wird nur sicher auf diesem Gerät gespeichert';

  @override
  String get webDavRootPath => 'Remote-Ordner';

  @override
  String get webDavTestConnection => 'Verbindung testen';

  @override
  String get webDavTestingConnection => 'Verbindung wird getestet…';

  @override
  String get webDavConnectionSuccess =>
      'Verbindung und Schreibzugriff bestätigt';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Verbindungstest fehlgeschlagen: $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Konfiguration speichern';

  @override
  String get webDavAutomaticSync => 'Automatischer Sync';

  @override
  String get webDavAutomaticSyncHint =>
      'Sync nach dem Start oder wenn die App in den Vordergrund zurückkehrt';

  @override
  String get webDavSyncContent => 'Sync-Inhalt';

  @override
  String get webDavScopeBookSources => 'Buchquellen';

  @override
  String get webDavScopeBookSourcesHint =>
      'Synchronisiert öffentliche ORSP-Quellen und Favoriten sowie alle Gruppennamen, leeren Gruppen und deren Reihenfolge. Quellen-Zugangsdaten und private Konfigurationen bleiben auf diesem Gerät.';

  @override
  String get webDavScopeBooks => 'Regal und Online-Bücher';

  @override
  String get webDavScopeProgress => 'Lesefortschritt';

  @override
  String get webDavScopeBookmarks => 'Lesezeichen';

  @override
  String get webDavScopeNotes => 'Notizen und Markierungen';

  @override
  String get webDavScopeNotesHint =>
      'Enthält zitierten Text, Notizen und handschriftliche Anmerkungen. WebDAV-Daten sind nicht Ende-zu-Ende-verschlüsselt.';

  @override
  String get webDavScopeReadingSessions => 'Lesestatistiken';

  @override
  String get webDavScopeReaderSettings => 'Reader-Einstellungen';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Synchronisiert Typografie, Designs, Blättern, automatische Blattereinstellungen, Tippzonen und Bild-Reader-Einstellungen.';

  @override
  String get webDavScopeReplaceRules => 'Ersetzungsregeln';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Synchronisiert Regelmuster und Ersetzungstext. WebDAV-Daten sind nicht Ende-zu-Ende-verschlüsselt.';

  @override
  String get webDavScopeBookFiles => 'Buchdateien';

  @override
  String get webDavBookFilesHint =>
      'Wähle, welche Bücher hoch- oder heruntergeladen werden';

  @override
  String get webDavBookFilesUnavailable =>
      'Die Übertragung von Buchdateien wird aktiviert, sobald der Metadaten-Sync stabil ist';

  @override
  String get webDavSecurityNotice =>
      'Daten werden über HTTPS gesendet, aber dein WebDAV-Anbieter kann unverschlüsselte Remote-Inhalte lesen.';

  @override
  String get webDavConnectionDetails => 'Verbindungseinstellungen';

  @override
  String get webDavClearConfiguration => 'Konfiguration löschen';

  @override
  String get webDavClearConfigurationTitle => 'WebDAV-Konfiguration löschen?';

  @override
  String get webDavClearConfigurationMessage =>
      'Dies entfernt die WebDAV-Adresse und die Anmeldung von diesem Gerät. Lokale Lesedaten und Remote-Dateien werden nicht gelöscht.';

  @override
  String get webDavClearConfigurationConfirm => 'Von diesem Gerät löschen';

  @override
  String get webDavActivityTitle => 'Sync-Aktivität';

  @override
  String get webDavActivityEmpty => 'Noch keine Sync-Aktivität';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return '$uploaded hochgeladen, $downloaded heruntergeladen';
  }

  @override
  String get webDavErrorAuthentication =>
      'Benutzername, Passwort oder Ordnerberechtigung ist falsch.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'Die WebDAV-Konfiguration ist unvollständig oder ungültig.';

  @override
  String get webDavErrorInsecureConnection =>
      'Die Verbindung erfüllt die Sicherheitsanforderungen nicht.';

  @override
  String get webDavErrorCertificate =>
      'Das Serverzertifikat konnte nicht verifiziert werden.';

  @override
  String get webDavErrorPermission =>
      'Der Remote-Ordner ist nicht beschreibbar.';

  @override
  String get webDavErrorNotFound =>
      'Der Remote-Sync-Ordner oder eine benötigte Datei wurde nicht gefunden.';

  @override
  String get webDavErrorConflict =>
      'Remote-Daten sind im Konflikt. Versuche, erneut zu synchronisieren.';

  @override
  String get webDavErrorStorageFull => 'Der WebDAV-Speicher ist voll.';

  @override
  String get webDavErrorRateLimited =>
      'Zu viele WebDAV-Anfragen. Versuche es später erneut.';

  @override
  String get webDavErrorTimeout =>
      'Der Server hat nicht rechtzeitig geantwortet.';

  @override
  String get webDavErrorUnsupported =>
      'Die Server-Antwort ist mit dem Synchronisationsprotokoll inkompatibel.';

  @override
  String get webDavErrorServer =>
      'Der WebDAV-Server konnte die Anfrage nicht abschließen.';

  @override
  String get webDavErrorNetwork =>
      'Das Netzwerk ist nicht verfügbar. Änderungen bleiben auf diesem Gerät gespeichert.';

  @override
  String get webDavErrorCorruptData =>
      'Einige Remote-Sync-Daten sind beschädigt und wurden nicht angewendet.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'Lokale Lese-Einstellungen sind beschädigt. Der Sync wurde gestoppt, ohne das Remote-Backup zu löschen.';

  @override
  String get webDavErrorClockSkew =>
      'Die Uhr dieses Geräts weicht zu stark vom WebDAV-Server ab.';

  @override
  String get webDavErrorSecureStorage =>
      'Das WebDAV-Passwort konnte nicht aus dem sicheren Speicher gelesen werden.';

  @override
  String get webDavErrorUnknown =>
      'WebDAV konnte den Vorgang nicht abschließen.';

  @override
  String get webDavErrorDetails => 'Details der Server-Antwort';

  @override
  String get webDavErrorMissingEtagDetail =>
      'Der Server hat keinen starken Datei-Versionsbezeichner (ETag) zurückgegeben. Der ETag fehlt möglicherweise oder ist zu schwach, sodass die App nicht erkennen kann, ob ein anderes Gerät die Remote-Datei geändert hat.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'Der Server hat die Bedingung ignoriert, die Schreiben nur bei passender Dateiversion erlaubt (If-Match). Fortfahren könnte eine neuere Änderung eines anderen Geräts überschreiben.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'Der Server hat die Bedingung ignoriert, die Erstellen nur erlaubt, wenn die Datei nicht existiert (If-None-Match). Fortfahren könnte eine bestehende Datei überschreiben.';

  @override
  String webDavErrorReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'HTTP-Status: $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Anfragemethode: $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Ressourcenpfad: $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Fehlgeschlagen bei: $phase';
  }

  @override
  String get webDavPhaseConnecting => 'Verbindung mit dem Remote-Server';

  @override
  String get webDavPhaseScanningLocal => 'Dieses Gerät wird durchsucht';

  @override
  String get webDavPhaseReadingRemote => 'Remote-Daten werden gelesen';

  @override
  String get webDavPhaseApplyingRemote => 'Remote-Daten werden zusammengeführt';

  @override
  String get webDavPhaseUploadingLocal =>
      'Lokale Änderungen werden hochgeladen';

  @override
  String get webDavPhaseFinishing => 'Synchronisation wird abgeschlossen';

  @override
  String get webDavPhaseUnknown => 'ein unbekannter Schritt';

  @override
  String get webDavBookFilesTitle => 'Buchdateien';

  @override
  String get webDavFilesPendingUpload => 'Hochzuladen';

  @override
  String get webDavFilesAvailableDownload => 'Verfügbar';

  @override
  String get webDavFilesSynced => 'Synchronisiert';

  @override
  String get webDavFilesUploadSelected => 'Ausgewählte hochladen';

  @override
  String get webDavFilesDownloadSelected => 'Ausgewählte herunterladen';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return '$count ausgewählt · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Nur auf diesem Gerät';

  @override
  String get webDavFilesOnlyRemote =>
      'Datei nicht auf dieses Gerät heruntergeladen';

  @override
  String get webDavFilesUploadPermission => 'Uploads von Buchdateien erlauben';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Synchronisiere ausgewählte Bücher und Cover. TXT überträgt nach dem ersten Upload nur geänderte Blöcke; EPUB und PDF behalten ihre ursprünglichen Bytes. Vollständig lesbare Dateien werden separat exportiert.';

  @override
  String get webDavNewBookPolicyTitle => 'Neue Buchdateien';

  @override
  String get webDavNewBookPolicyAsk => 'Jedes Mal fragen (empfohlen)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Wähle nach einem abgeschlossenen Import, welche Bücher hochgeladen werden';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Neue Bücher automatisch hochladen';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Lädt direkt nach dem Import hoch und nutzt dabei möglicherweise mobile Daten';

  @override
  String get webDavNewBookPolicyManual => 'Immer manuell wählen';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Starte Uploads nur über die Seite „Buchdateien“';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return 'Die $count gerade importierten Bücher synchronisieren?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'Lesedaten werden automatisch synchronisiert. Wähle die Original-Buchdateien, die zu WebDAV hochgeladen werden sollen.';

  @override
  String get webDavNewBooksSkip => 'Nicht jetzt';

  @override
  String webDavNewBooksUploading(int count) {
    return '$count neue Bücher werden hochgeladen…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Upload neuer Bücher abgeschlossen: $success erfolgreich, $failed fehlgeschlagen';
  }

  @override
  String get webDavFilesTooLarge =>
      'Diese Datei überschreitet das Sync-Größenlimit ihres Formats';

  @override
  String get webDavFilesEmpty => 'Keine Bücher in dieser Kategorie';

  @override
  String get webDavFilesTransferComplete =>
      'Übertragung der Buchdateien abgeschlossen';

  @override
  String get readerAddAnnotation => 'Anmerkung hinzufügen';

  @override
  String get readerAnnotationHint =>
      'Schreibe deine Gedanken zu dieser Stelle…';

  @override
  String get readerAnnotationSaved => 'Anmerkung gespeichert';

  @override
  String get readerAnnotationDeleted => 'Anmerkung gelöscht';

  @override
  String get readerAnnotationShelfRequired =>
      'Füge dieses Buch zuerst dem Regal hinzu, bevor du Anmerkungen speicherst';

  @override
  String get readerNoAnnotations => 'Noch keine Anmerkungen';

  @override
  String get readerNoAnnotationsHint =>
      'Markiere Text oder füge einen Kommentar hinzu. Tippe eine unterstrichene Anmerkung an, um sie erneut zu lesen.';

  @override
  String get replaceRulesTitle => 'Ersetzen & Bereinigen';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Entferne Werbung, Werbeaktionen und andere unerwünschte Texte beim Lesen';

  @override
  String get replaceRulesImport => 'Regeln importieren';

  @override
  String get replaceRulesExport => 'Regeln exportieren';

  @override
  String get replaceRulesSearchHint => 'Namen, Gruppen oder Muster durchsuchen';

  @override
  String get replaceRulesUnnamed => 'Unbenannte Regel';

  @override
  String get replaceRulesDeleteValue => 'Entfernen';

  @override
  String get replaceRulesCreate => 'Neue Regel';

  @override
  String get replaceRulesEmptyTitle => 'Keine Ersetzungsregeln';

  @override
  String get replaceRulesEmptyBody =>
      'Importiere eine Lesequellen-JSON-Datei oder erstelle eine Regel mit regulärem Ausdruck.';

  @override
  String get replaceRulesNoSearchResults => 'Keine passenden Regeln';

  @override
  String get replaceRulesCreateTitle => 'Neue Ersetzungsregel';

  @override
  String get replaceRulesEditTitle => 'Ersetzungsregel bearbeiten';

  @override
  String get replaceRulesNameLabel => 'Regelname';

  @override
  String get replaceRulesPatternLabel =>
      'Zu findender Text oder regulärer Ausdruck';

  @override
  String get replaceRulesPatternHelper =>
      'Lass die Ersetzung leer, um gefundenen Text zu entfernen';

  @override
  String get replaceRulesReplacementLabel => 'Ersetzen durch';

  @override
  String get replaceRulesRegexLabel => 'Regulären Ausdruck verwenden';

  @override
  String get replaceRulesScopeTitleLabel => 'Auf Kapiteltitel anwenden';

  @override
  String get replaceRulesScopeContentLabel => 'Auf Kapitelinhalt anwenden';

  @override
  String get replaceRulesGroupLabel => 'Gruppe (optional)';

  @override
  String get replaceRulesScopeLabel => 'Bereich (optional)';

  @override
  String get replaceRulesScopeHelper =>
      'Trenne Buchtitel oder Quellnamen mit Semikolons';

  @override
  String get replaceRulesExcludeScopeLabel =>
      'Ausgeschlossener Bereich (optional)';

  @override
  String get replaceRulesDeleteConfirmTitle => 'Diese Regel löschen?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'Die Regel wird von diesem Gerät entfernt.';

  @override
  String replaceRulesImported(int count) {
    return '$count Regeln importiert';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'Regeln konnten nicht importiert werden: $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'Die Regeldatei überschreitet $max';
  }

  @override
  String get replaceRulesExported => 'Regeln exportiert';

  @override
  String get replaceRulesPatternRequired =>
      'Gib einen zu findenden Text oder regulären Ausdruck ein';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'Das Muster überschreitet $max Zeichen';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Ungültiger regulärer Ausdruck: $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Es werden höchstens $max Regeln unterstützt';
  }

  @override
  String get accountSecurityTitle => 'Sicherheit';

  @override
  String get accountSecurityLoading => 'Sicherheitsstatus wird geladen…';

  @override
  String get accountChangeEmailTitle => 'E-Mail ändern';

  @override
  String get accountChangeEmailEnterTitle => 'Neue E-Mail wählen';

  @override
  String get accountChangeEmailEnterHint =>
      'Wir senden einen Code an deine aktuelle E-Mail und einen an die neue Adresse.';

  @override
  String get accountChangeEmailVerifyTitle =>
      'Beide E-Mail-Adressen bestätigen';

  @override
  String get accountChangeEmailVerifyHint =>
      'Gib die beiden Codes ein, um das Ändern deiner Anmelde-E-Mail abzuschließen.';

  @override
  String get accountCurrentEmail => 'Aktuelle E-Mail';

  @override
  String get accountNewEmail => 'Neue E-Mail';

  @override
  String get accountCurrentEmailCode => 'Code an die aktuelle E-Mail';

  @override
  String get accountNewEmailCode => 'Code an die neue E-Mail';

  @override
  String get accountSendBothCodes => 'Beide Codes senden';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Deine aktuelle Adresse ist eine versteckte Apple-Relay-E-Mail, die keine Codes empfangen kann. Ein einzelner Code wird an die neue Adresse gesendet.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Deine aktuelle Adresse ist eine versteckte Apple-Relay-E-Mail, dafür ist kein Code nötig. Gib den an die neue Adresse gesendeten Code ein, um den Vorgang abzuschließen.';

  @override
  String get accountCurrentPasswordInstead =>
      'Aktuelles Passwort (statt des Codes)';

  @override
  String get accountRelayEmailTitle => 'Du nutzt eine versteckte Apple-E-Mail';

  @override
  String get accountRelayEmailBody =>
      'Deine Anmeldeadresse ist eine private Apple-Relay-Adresse; Bestätigungs-E-Mails kommen möglicherweise nicht an. Ziehe einen Wechsel zu einer E-Mail-Adresse in Betracht, die du täglich nutzt.';

  @override
  String get accountChangeEmailAction => 'E-Mail ändern';

  @override
  String get accountEmailChanged => 'E-Mail geändert';

  @override
  String get accountChangePasswordTitle => 'Passwort festlegen oder ändern';

  @override
  String get accountPasswordEmailTitle => 'Per E-Mail bestätigen';

  @override
  String get accountPasswordEmailHint =>
      'Sende einen Code an deine aktuelle E-Mail, bevor du ein neues Passwort wählst.';

  @override
  String get accountPasswordNewTitle => 'Neues Passwort wählen';

  @override
  String get accountPasswordNewHint =>
      'Gib den E-Mail-Code ein und lege das Passwort fest, das du künftig verwendest.';

  @override
  String get accountNewPassword => 'Neues Passwort';

  @override
  String get accountChangePasswordAction => 'Passwort ändern';

  @override
  String get accountPasswordChanged => 'Passwort geändert';

  @override
  String get accountPasswordsMismatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get accountMfaTitle => 'Zwei-Faktor-Authentifizierung';

  @override
  String get accountMfaEnabled =>
      'Aktiviert. Bei der Anmeldung ist ein Authenticator- oder ein unbenutzter Wiederherstellungscode erforderlich.';

  @override
  String get accountMfaDisabledByDefault =>
      'Standardmäßig aus. Aktiviere sie, um Passwort- und E-Mail-Code-Anmeldungen zu schützen.';

  @override
  String get accountMfaOnTitle => 'Zwei-Faktor-Authentifizierung ist aktiv';

  @override
  String get accountMfaEmailTitle => 'Bestätige zuerst deine E-Mail';

  @override
  String accountMfaEmailHint(String email) {
    return 'Wir senden einen Einrichtungscode an $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'E-Mail-Code eingeben';

  @override
  String get accountMfaEmailCodeHint =>
      'Nach der Bestätigung öffnen sich auf der nächsten Seite der Authenticator-QR-Code und das Secret.';

  @override
  String get accountMfaAuthenticatorTitle =>
      'Füge Origo X zu deinem Authenticator hinzu';

  @override
  String get accountMfaAuthenticatorHint =>
      'Scanne den QR-Code oder gib das Secret manuell ein und gib dann den sechsstelligen Code aus dem Authenticator ein.';

  @override
  String get accountMfaQrCodeLabel => 'Authenticator-Einrichtungs-QR-Code';

  @override
  String get accountMfaSecretLabel => 'Einrichtungs-Secret';

  @override
  String get accountMfaSecretCopied => 'Einrichtungs-Secret kopiert';

  @override
  String get accountMfaRecoveryTitle =>
      'Speichere deine Wiederherstellungscodes';

  @override
  String get accountMfaChallengeTitle => 'Zwei-Faktor-Bestätigung';

  @override
  String get accountMfaChallengeHint =>
      'Gib den Code aus deinem Authenticator oder einen unbenutzten Wiederherstellungscode ein, um auf dein Konto zuzugreifen.';

  @override
  String get accountMfaCode => 'Authenticator-Code';

  @override
  String get accountMfaOrRecoveryCode =>
      'Authenticator- oder Wiederherstellungscode';

  @override
  String get accountMfaVerify => 'Bestätigen und fortfahren';

  @override
  String get accountMfaSendSetupCode => 'Einrichtungs-E-Mail-Code senden';

  @override
  String get accountMfaContinueSetup => 'Einrichtung fortsetzen';

  @override
  String get accountMfaSecretWarning =>
      'Füge dieses Secret zu deinem Authenticator hinzu. Es wird nur während der Einrichtung angezeigt.';

  @override
  String get accountMfaOpenAuthenticator => 'Authenticator öffnen';

  @override
  String get accountMfaConfirm => 'Bestätigen und aktivieren';

  @override
  String get accountMfaDisable => 'Zwei-Faktor-Authentifizierung deaktivieren';

  @override
  String get accountMfaDisabled => 'Zwei-Faktor-Authentifizierung deaktiviert';

  @override
  String get accountRecoveryCodesWarning =>
      'Speichere diese Wiederherstellungscodes jetzt. Jeder Code funktioniert einmal, und diese Liste wird nicht erneut angezeigt.';

  @override
  String get accountCopyRecoveryCodes => 'Wiederherstellungscodes kopieren';

  @override
  String get accountRecoveryCodesCopied => 'Wiederherstellungscodes kopiert';

  @override
  String get accountRecoveryCodesSaved => 'Ich habe diese Codes gespeichert';

  @override
  String get accountPremiumLifetime => 'Lifetime Premium freigeschaltet';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'Premium ist mit diesem Konto verknüpft und wird über unterstützte Plattformen synchronisiert.';

  @override
  String get accountRedemptionCode => 'Lifetime-Premium-Code';

  @override
  String get accountRedeemPremium => 'Einlösen und für immer freischalten';

  @override
  String get accountApplePurchase => 'Mit App Store für immer freischalten';

  @override
  String get accountApplePurchaseHint =>
      'Ein einmaliger Kauf verknüpft Premium dauerhaft mit diesem Origo-X-Konto und synchronisiert es auf unterstützte Plattformen.';

  @override
  String get accountAppleProductLoading =>
      'Produktinformationen werden geladen…';

  @override
  String get accountAppleProductRetry =>
      'Produktinformationen konnten nicht geladen werden. Zum Wiederholen tippen.';

  @override
  String get accountAppleRestore => 'Käufe wiederherstellen';

  @override
  String get accountApplePurchasePending =>
      'Der Kauf wartet auf die Freigabe des App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Kauf eingereicht; Premium-Zugriff wird verifiziert';

  @override
  String get accountAppleRestoreSubmitted =>
      'Wiederherstellung der Käufe angefordert';

  @override
  String get accountPremiumUnlocked => 'Lifetime Premium freigeschaltet';

  @override
  String get accountPremiumUnlockedReferral =>
      'Eingelöst: Du und dein Einladender habt beide Lifetime Premium freigeschaltet';

  @override
  String get accountInviteTitle => 'Freunde einladen';

  @override
  String get accountInviteSubtitle =>
      'Wenn ein Freund deinen Code bindet und einen Lifetime-Premium-Code einlöst, schaltet ihr beide für immer Premium frei.';

  @override
  String get accountInviteMyCode => 'Mein Einladungscode';

  @override
  String get accountInviteCopyCode => 'Einladungscode kopieren';

  @override
  String get accountInviteCopyLink => 'Einladungslink kopieren';

  @override
  String get accountInviteShareAction => 'Einladungslink zum Teilen kopieren';

  @override
  String get accountInviteCopied => 'Einladungsdetails kopiert';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return '$invited eingeladen · $rewarded erfolgreich';
  }

  @override
  String get accountInviteStatsInvited => 'Gebundene Codes';

  @override
  String get accountInviteStatsRewarded => 'Freigeschaltete Belohnungen';

  @override
  String accountInviterBound(String name) {
    return 'Eingeladen von $name';
  }

  @override
  String get accountInviteRewarded => 'Einladung abgeschlossen';

  @override
  String get accountInviteWaiting => 'Wartet auf Einlösung des Codes';

  @override
  String get accountInviteBindLabel => 'Einladungscode des Freundes';

  @override
  String get accountInviteBindHint =>
      'Ein Konto kann nur einmal binden und dies später nicht ändern';

  @override
  String get accountInviteBindAction => 'Einladungscode binden';

  @override
  String get accountInviteBound => 'Einladungscode gebunden';

  @override
  String get accountInviteHowItWorks => 'So funktioniert es';

  @override
  String get accountInviteStepShareTitle => 'Link teilen';

  @override
  String get accountInviteStepShareBody =>
      'Sende den Link oder Code an einen Freund. Er öffnet ihn und erstellt ein Konto.';

  @override
  String get accountInviteStepBindTitle => 'Code binden';

  @override
  String get accountInviteStepBindBody =>
      'Dein Freund gibt deinen Code unter Konto ein. Jedes Konto kann nur einmal binden.';

  @override
  String get accountInviteStepRedeemTitle => 'Code einlösen';

  @override
  String get accountInviteStepRedeemBody =>
      'Wenn er einen Lifetime-Premium-Code einlöst, schalten beide Konten sofort Premium frei.';

  @override
  String get accountInviteMyBinding => 'Meine Einladungs-Beziehung';

  @override
  String get accountInviteBindIntro =>
      'Wenn dich jemand eingeladen hat, binde seinen Code hier, damit die Belohnung mit deinem Konto verbunden bleibt.';

  @override
  String get accountInviteBindingNotNeeded =>
      'Dieses Konto hat bereits Premium, daher ist kein Einladungscode nötig.';

  @override
  String get readingDataExportAction => 'Lesedaten exportieren';

  @override
  String get readingDataExportSubtitle =>
      'Markierungen, Unterstreichungen und Notizen';

  @override
  String get readingDataExportWholeBook => 'Ganzes Buch';

  @override
  String get readingDataExportWholeBookHint =>
      'Exportiert alle deine Anmerkungen in diesem Buch. Buchtext und Quelldatei sind nicht enthalten.';

  @override
  String get readingDataExportPrivacySummary =>
      'Enthält markierte oder unterstrichene Auszüge und deine privaten Notizen. Die Buchdatei, der Volltext, Kontodaten und Geräteinformationen sind nicht enthalten.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return '$highlights Markierungen · $underlines Unterstreichungen · $notes Notizen';
  }

  @override
  String readingDataExportButton(int count) {
    return '$count Anmerkungen exportieren';
  }

  @override
  String get readingDataExportPreparing => 'Markdown wird vorbereitet…';

  @override
  String get readingDataExportEmpty =>
      'Dieses Buch hat keine Markierungen, Unterstreichungen oder Notizen zu exportieren.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Lesedaten nach $location exportiert';
  }

  @override
  String get readingDataExportFailed =>
      'Lesedaten konnten nicht exportiert werden';

  @override
  String get readingDataExportUnsupported =>
      'Der Export von Lesedaten wird auf dieser Plattform noch nicht unterstützt';

  @override
  String get readingDataExportReplaceTitle => 'Vorhandene Datei ersetzen?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Unter $path existiert bereits eine Datei. Das Ersetzen kann nicht rückgängig gemacht werden.';
  }

  @override
  String get readingDataExportReplaceAction => 'Ersetzen';

  @override
  String get readingDataExportExportedAt => 'Exportiert';

  @override
  String get readingDataExportAuthor => 'Autor';

  @override
  String get readingDataExportContents => 'Inhalt';

  @override
  String get readingDataExportMyNote => 'Meine Notiz';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Seite $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Nicht zugeordnete Anmerkungen';

  @override
  String get cloudSyncTitle => 'Cloud-Sync';

  @override
  String get cloudSyncTagline =>
      'Mache auf einem anderen Gerät weiter, wo du aufgehört hast';

  @override
  String get cloudSyncResumeTitle => 'Geräteübergreifend fortfahren';

  @override
  String get cloudSyncAutoResume => 'Beim Öffnen eines Buchs fortfahren';

  @override
  String get cloudSyncAutoResumeHint =>
      'Prüft beim Öffnen die neueste Position; bietet beim Lesen Aktualisierungen an';

  @override
  String get cloudSyncAutoHint =>
      'Speichert den Fortschritt beim Lesen und prüft Aktualisierungen beim Öffnen eines Buchs';

  @override
  String get cloudSyncMoreContent => 'Weitere Sync-Optionen';

  @override
  String get cloudSyncBooks => 'Bücher und Text';

  @override
  String get cloudSyncBooksHint =>
      'Teilnehmende Bücher, Text-Updates und Downloads';

  @override
  String get cloudSyncActivity => 'Sync-Details und Probleme';

  @override
  String get cloudSyncStorage => 'Speicherverbindung';

  @override
  String get cloudSyncNoActivity => 'Noch keine Sync-Aktivität';

  @override
  String get cloudSyncProgress => 'Leseposition';

  @override
  String get cloudSyncText => 'Buchtextdateien';

  @override
  String get cloudSyncMetadataComplete =>
      'Ausgewählte Lesedaten werden mit WebDAV ausgetauscht';

  @override
  String get cloudSyncPaused => 'Automatischer Sync ist pausiert';

  @override
  String get cloudSyncLocalOnly => 'Auf diesem Gerät behalten';

  @override
  String get cloudSyncCheckHint =>
      'Eine Verbindung bestätigt nicht den Empfang auf anderen Geräten; prüfe die Einträge unten';

  @override
  String get cloudSyncPendingFiles => 'Text-Updates brauchen Aufmerksamkeit';

  @override
  String get cloudSyncFileIdle =>
      'Verknüpfte Textdateien werden beim nächsten Sync geprüft';

  @override
  String get cloudSyncManageBooks => 'Bücher und Downloads wählen';

  @override
  String get cloudSyncNoBooks => 'Noch keine TXT-Bücher verknüpft';

  @override
  String get cloudSyncCompare => 'Versionen vergleichen';

  @override
  String get cloudSyncKeepLocal => 'Version dieses Geräts verwenden';

  @override
  String get cloudSyncUseRemote => 'Cloud-Version verwenden';

  @override
  String get cloudSyncBothKept =>
      'Beide Versionen bleiben erhalten. Der Sync läuft nach deiner Auswahl weiter.';

  @override
  String get cloudSyncPreviewLimited =>
      'Die Vorschau zeigt den ersten Unterschied. Beide vollständigen Versionen bleiben erhalten.';

  @override
  String get cloudSyncPending => 'Wartet auf Sync';

  @override
  String get cloudSyncConflict => 'Versionen brauchen Prüfung';

  @override
  String get cloudSyncCurrent => 'Aktueller Text ist mit WebDAV synchronisiert';

  @override
  String get cloudSyncFailed => 'Sync unvollständig. Wiederholung möglich.';

  @override
  String get cloudSyncHistory => 'Versionsverlauf';

  @override
  String get cloudSyncApplyUpdate => 'Text-Update anwenden';

  @override
  String get cloudSyncParticipate => 'Text dieses Buchs synchronisieren';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Schließe Reader oder Editor dieses Buchs, bevor du das Text-Update anwendest';

  @override
  String get cloudSyncTextLocation => 'Aktuelle Cloud-Datei';

  @override
  String get cloudSyncTextLocationHint =>
      'Verwalte hier Updates, Pausen und Konflikte teilnehmender Bücher.';

  @override
  String get bookSourcesImportIntro =>
      'Erkennt Quellen automatisch. Prüfe vor dem Import.';

  @override
  String get bookSourcesImportInputStep => 'Quelle wählen';

  @override
  String get bookSourcesImportReviewStep => 'Prüfen & importieren';

  @override
  String get bookSourcesImportFileHint => 'Wähle eine JSON-Quellendatei.';

  @override
  String get bookSourcesImportDownloading => 'Quelle wird heruntergeladen…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Regeln werden gelesen und Duplikate geprüft…';

  @override
  String get bookSourcesImportSaving => 'Quellen werden gespeichert…';

  @override
  String get bookSourcesImportPicking => 'Dateiauswahl wird geöffnet…';

  @override
  String get bookSourcesImportWaitHint =>
      'Große Quelllisten können länger dauern. Du kannst abbrechen und es erneut versuchen.';

  @override
  String get bookSourcesImportSaveHint =>
      'Bitte halte dieses Fenster offen, bis das Speichern abgeschlossen ist.';

  @override
  String get bookSourcesImportReady => 'Bereit zum Importieren';

  @override
  String get bookSourcesImportEmpty =>
      'Keine Quellen ausgewählt. Prüfe die Datei oder die Duplikatauswahl.';

  @override
  String get bookSourcesImportRetry => 'Erneut versuchen';

  @override
  String get bookSourcesImportFailed =>
      'Quellen konnten nicht gelesen werden. Prüfe Adresse oder Datei und versuche es erneut.';

  @override
  String get bookSourcesImportWebPage =>
      'Diese URL hat eine Website oder Anmeldeseite zurückgegeben. Kopiere stattdessen den Quellen-Download- oder Abo-JSON-Link der Website und importiere diesen. Nach dem Import der Quelle kannst du dich anmelden.';

  @override
  String get bookSourcesImportSaveFailed =>
      'Quellen konnten nicht gespeichert werden. Deine Vorschau bleibt erhalten; bitte versuche es erneut.';

  @override
  String get bookSourcesImportErrorDetails => 'Fehlerdetails';

  @override
  String get bookSourcesImportFileUnreadable =>
      'Die ausgewählte Datei konnte nicht gelesen werden. Wähle sie erneut.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Quellen importieren',
      one: '1 Quelle importieren',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'JSON-Datei';

  @override
  String get bookSourcesImportTimedOut =>
      'Das Lesen hat zu lange gedauert. Prüfe deine Verbindung oder importiere eine heruntergeladene JSON-Datei.';

  @override
  String get bookSourcesImportUsageNotice => 'Informationen zur Quellennutzung';

  @override
  String get bookSourcesMaintenanceScope => 'Bereich';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Aktivierte';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Alle Quellen';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Ausgewählte';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return '$count Quellen in diesem Bereich';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope =>
      'Keine Quellen in diesem Bereich';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Prüfung gestoppt';

  @override
  String get bookSourcesMaintenanceCancellingTitle =>
      'Prüfungen werden gestoppt';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Aktive Prüfungen werden abgeschlossen und fertige Ergebnisse behalten';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Prüfung unterbrochen';

  @override
  String get bookSourcesMaintenanceResume => 'Übrige Prüfungen fortsetzen';

  @override
  String get bookSourcesMaintenanceRetry => 'Ungeklärte Prüfungen wiederholen';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return '$count Quellen noch nicht geprüft';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Zustandsergebnisse';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Alle Ergebnisse';

  @override
  String get bookSourcesMaintenanceAvailable => 'Verfügbar';

  @override
  String get bookSourcesMaintenanceLimited => 'Teilweise';

  @override
  String get bookSourcesMaintenanceFailed => 'Fehlgeschlagene Prüfungen';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Zeitüberschreitung';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Unbestätigt';

  @override
  String get bookSourcesMaintenanceReviewSearch =>
      'Name oder Adresse durchsuchen';

  @override
  String get bookSourcesMaintenanceReviewEmpty => 'Keine passenden Ergebnisse';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return '$count zum Deaktivieren ausgewählt';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Fehlgeschlagene Prüfungen auswählen';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Zeitüberschreitung der Verbindung; später erneut versuchen';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Kein eindeutiges Ergebnis aus dieser Prüfung';

  @override
  String get bookSourcesMaintenanceAvailableReason => 'Kernprüfungen bestanden';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Duplikate werden gesucht…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Von deinem Regal genutzt · standardmäßig behalten';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return '$count ausgewählte Quelle(n) werden von Büchern in deinem Regal genutzt. Wenn du sie löschst, können diese Bücher möglicherweise nicht mehr aktualisiert oder neue Kapitel geladen werden.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Probleme';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return '$count Quelle(n) ausgewählt';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed =>
      'Von deinem Bücherregal genutzt';

  @override
  String get bookSourcesMaintenancePause => 'Pause';

  @override
  String get bookSourcesMaintenancePausing => 'Wird pausiert…';

  @override
  String get bookSourcesMaintenancePaused => 'Prüfung pausiert';

  @override
  String get bookSourcesMaintenanceCompleted => 'Prüfung abgeschlossen';

  @override
  String get bookSourcesMaintenanceStart => 'Prüfung starten';

  @override
  String get bookSourcesMaintenanceRestart => 'Erneut starten';

  @override
  String get bookSourcesMaintenanceCheckedThisRun =>
      'In diesem Durchlauf geprüft';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Wähle und verwalte jetzt fertige Ergebnisse oder setze die Prüfung der übrigen Quellen fort.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'Änderungen konnten nicht gespeichert werden. Versuche es erneut.';

  @override
  String get settingsQqGroup => 'QQ-Gruppe';

  @override
  String get settingsOpenSourceTitle => 'Open-Source-Details';

  @override
  String get settingsOpenSourceDetails =>
      'Alle Funktionen außer den erweiterten Funktionen sind quelloffen. Der Open-Source-Code steht unter AGPL-3.0; den Umfang findest du im GitHub-Repository.';

  @override
  String get premiumLifetimeTitle => 'Lifetime Premium';

  @override
  String get premiumLifetimeCaption =>
      'Einmaliger Kauf · Keine automatische Verlängerung';

  @override
  String get premiumBenefitsTitle => 'In Premium enthalten';

  @override
  String get premiumProtocolsBenefit =>
      'Zusätzliche kompatible Quellenprotokolle importieren und verwenden.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Auf vertrauenswürdige Quellen auf deinem Gerät, im lokalen Netz oder privaten Netz zugreifen.';

  @override
  String get premiumSourceNotice =>
      'Premium enthält keine Bücher oder Quelladressen. Dienste von Drittanbietern können separat kostenpflichtig sein.';

  @override
  String get premiumSetupHint =>
      'Nach dem Freischalten standardmäßig aktiv. Du kannst sie unter Einstellungen → Erweiterte Funktionen ausschalten.';

  @override
  String get premiumBillingTitle => 'Kaufdetails';

  @override
  String get premiumBillingBody =>
      'Dies ist ein nicht verbrauchbarer einmaliger Kauf, kein Abo. Er verlängert sich nicht automatisch. Der App Store zeigt den tatsächlichen Preis, und Apple wickelt die Zahlung ab.';

  @override
  String get premiumRestoreHelp =>
      'Stelle nach Neuinstallation oder Gerätewechsel mit dem beim Kauf verwendeten Apple-Konto und dem verknüpften Origo-X-Konto wieder her. Die Wiederherstellung berechnet dir nichts erneut.';

  @override
  String get premiumMembershipTerms => 'Mitgliedschaftsbedingungen';

  @override
  String get premiumPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get premiumAppleEula => 'Apple-Standard-EULA';

  @override
  String get premiumPurchaseConsent =>
      'Lies vor dem Kauf die Mitgliedschaftsbedingungen, die Datenschutzerklärung und Apples Standard-EULA.';

  @override
  String get premiumAccountBindingTitle => 'Konto und Zugriff';

  @override
  String get premiumAccountBindingBody =>
      'Nach der Verifizierung wird Premium mit dem aktuellen Origo-X-Konto verknüpft und über unterstützte Plattformen synchronisiert. Erweiterte Einstellungen werden mit der Mitgliedschaft verfügbar. Abmelden oder Widerruf deaktiviert erweiterte Funktionen. Prüfe dein Konto vor dem Kauf.';

  @override
  String get premiumRefundTitle => 'Rückerstattung anfordern';

  @override
  String get premiumRefundTerms =>
      'Apple prüft und bearbeitet Rückerstattungsanfragen für den App Store nach seinen geltenden Regeln. Eine Anfrage bedeutet keine Genehmigung. Erstattete oder widerrufene Käufe gewähren den entsprechenden Premium-Zugriff nicht mehr.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Daten der Kauf-Verifizierung';

  @override
  String get premiumPrivacyPurchaseBody =>
      'Apple wickelt die Zahlungsinformationen ab. Die App sendet die Produkt-ID und die von Apple signierten Transaktions-Verifizierungsdaten an den Origo-X-Kontodienst, um Käufe zu prüfen und Premium zu verknüpfen oder wiederherzustellen. Dieser Kaufvorgang gibt dem Entwickler weder deine vollständige Kartennummer noch dein Apple-Konto-Passwort.';

  @override
  String get premiumPrivacyAccountTitle => 'Kontodienst';

  @override
  String get premiumPrivacyAccountBody =>
      'Der Origo-X-Kontodienst verarbeitet Kontodaten und Mitgliedschaftseinträge für Anmeldung, Sicherheitsprüfung und geräteübergreifenden Zugriff. Kontaktiere uns zu Support oder Datenschutz über die Kontaktoptionen auf der offiziellen Website.';

  @override
  String get premiumPurchaseSuccess => 'Premium freigeschaltet';

  @override
  String get premiumTestPurchaseVerified =>
      'Testkauf verifiziert. Das reguläre Premium wurde nicht aktiviert.';

  @override
  String get premiumPurchaseRevoked =>
      'Der Premium-Zugriff aus diesem Kauf wurde widerrufen.';

  @override
  String get premiumRestoreSuccess =>
      'Kauf wiederhergestellt. Premium ist synchronisiert.';

  @override
  String get premiumRestoreEmpty =>
      'Es wurde kein wiederherstellbarer Kauf gefunden. Prüfe dein Apple-Konto und das mit dem Kauf verknüpfte Origo-X-Konto.';

  @override
  String get premiumPurchaseCanceled => 'Kauf abgebrochen';

  @override
  String get premiumPendingApproval =>
      'Wartet auf Apples Freigabe. Der Zugriff wird nach Freigabe und Verifizierung entsperrt.';

  @override
  String get premiumVerifying => 'Dein Kauf wird verifiziert…';

  @override
  String get premiumRestoring => 'Käufe werden wiederhergestellt…';

  @override
  String get premiumRefundSubmitted =>
      'Rückerstattungsanfrage wurde zur Prüfung an Apple gesendet.';

  @override
  String get premiumRefundNotFound =>
      'Für dieses Apple-Konto wurde kein erstattungsfähiger Premium-Kauf gefunden. Du kannst deinen Verlauf auch beim Apple-Kaufsupport prüfen.';

  @override
  String get premiumApplePurchaseSupport => 'Apple-Kaufsupport';

  @override
  String get premiumLinkFailed =>
      'Dieser Link lässt sich nicht öffnen. Bitte versuche es später erneut.';

  @override
  String get premiumSignInRequired =>
      'Melde dich vor dem Kauf oder der Wiederherstellung von Premium bei Origo X an.';

  @override
  String get premiumRefundUnavailable =>
      'Das Apple-Rückerstattungsfenster ist nicht verfügbar. Fahre über den Apple-Kaufsupport fort.';

  @override
  String get premiumOperationFailed =>
      'Der Vorgang konnte nicht abgeschlossen werden. Bitte versuche es erneut.';

  @override
  String get premiumPurchaseConsentOther =>
      'Bitte lies vor dem Freischalten von Premium die Mitgliedschaftsbedingungen und die Datenschutzerklärung.';

  @override
  String get premiumBillingBodyOther =>
      'Schalte Premium über die verfügbaren Kauf- oder Einlöseoptionen frei. Der Kaufkanal zeigt Preis und Zahlungsmethode an. Eine verifizierte Mitgliedschaft wird mit deinem aktuellen Origo-X-Konto verknüpft.';

  @override
  String get accountDeleteTitle => 'Konto löschen';

  @override
  String get accountDeleteEntrySubtitle =>
      'Dieses Konto und alle seine Daten endgültig löschen';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get accountDeleteReviewTitle => 'Was die Löschung bewirkt';

  @override
  String get accountDeleteReviewBody =>
      'Bitte lies jeden Punkt. Sobald du bestätigst, wird alles unten Genannte sofort gelöscht, und wir können es nicht für dich zurückholen.';

  @override
  String get accountDeleteCurrentAccount => 'Aktuelles Konto';

  @override
  String get accountDeleteJoined => 'Beigetreten';

  @override
  String get accountDeletePremiumActive =>
      'Premium freigeschaltet (wird entfernt)';

  @override
  String get accountDeletePremiumNone => 'Premium nicht freigeschaltet';

  @override
  String get accountDeleteHasTitle => 'Dieses Konto hat derzeit';

  @override
  String accountDeleteHasSessions(int count) {
    return '$count angemeldete Geräte';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return '$count Passkeys';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return '$count verknüpfte Anmeldeanbieter';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return '$count Mitglieder, die mit deinem Einladungscode beigetreten sind';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return '$count eingelöste Codes';
  }

  @override
  String get accountDeleteTermsTitle => 'Löschungsbedingungen';

  @override
  String get accountDeleteTermsIrreversible =>
      'Die Kontolöschung ist endgültig und nicht umkehrbar. Sobald du bestätigst, kann niemand — auch nicht der Support — die gelöschten Daten wiederherstellen.';

  @override
  String get accountDeleteTermsIdentity =>
      'Das Konto selbst wird gelöscht: deine E-Mail-Adresse, dein Benutzername, dein Anzeigename und dein Profilbild.';

  @override
  String get accountDeleteTermsLogins =>
      'Jede Anmeldemethode wird gelöscht: dein Passwort, deine Passkeys sowie deine Google-, GitHub- und Apple-Verknüpfungen.';

  @override
  String get accountDeleteTermsSessions =>
      'Du wirst überall sofort abgemeldet — auf Smartphones, Tablets und Computern gleichermaßen.';

  @override
  String get accountDeleteTermsMfa =>
      'Deine Zwei-Faktor-Einrichtung und alle Wiederherstellungscodes werden gelöscht.';

  @override
  String get accountDeleteTermsPremium =>
      'Der Premium-Zugriff wird entfernt, wie auch immer du ihn freigeschaltet hast — Einlösecode, Einladungs-Belohnung oder Apple-Kauf.';

  @override
  String get accountDeleteTermsReferrals =>
      'Dein Einladungscode funktioniert nicht mehr, und die Empfehlungseinträge zwischen dir und den von dir Eingeladenen werden gelöscht. Bereits an andere vergebene Belohnungen werden nicht zurückgenommen.';

  @override
  String get accountDeleteTermsRedemptions =>
      'Bereits von dir verwendete Einlösecodes werden nicht erstattet und nicht wieder verfügbar.';

  @override
  String get accountDeleteTermsApple =>
      'Du hast Lifetime Premium im App Store gekauft. Die Löschung deines Kontos erstattet ihn nicht und storniert keine App-Store-Transaktion — Rückerstattungen kann nur Apple gewähren. Dein Kaufbeleg wird von diesem Konto entkoppelt und aufbewahrt, sodass du später auf einem neuen Konto mit derselben Apple-ID auf „Käufe wiederherstellen“ tippen und Premium zurückbekommen kannst.';

  @override
  String get accountDeleteTermsLocalData =>
      'Bücher, Regale und Lesefortschritt auf diesem Gerät werden nicht gelöscht — sie haben nur je auf deinem Gerät existiert. Entferne sie in der App, wenn auch sie weg sollen.';

  @override
  String get accountDeleteTermsTombstone =>
      'Wir behalten nur minimale anonymisierte Löschungsdaten, die zur Missbrauchsverhinderung nötig sind, zusammen mit App-Store-Kauf-Verifizierungseinträgen, die zum Wiederherstellen oder Prüfen von Käufen erforderlich sind. Diese Einträge werden nicht verwendet, um dein Konto neu zu erstellen.';

  @override
  String get accountDeleteTermsRejoin =>
      'Nach der Löschung kann sich dieselbe E-Mail-Adresse erneut registrieren, aber es wird ein brandneues, leeres Konto ohne deine alten Daten oder Zugriffe sein.';

  @override
  String get accountDeleteBlockedTitle =>
      'Dieses Konto kann noch nicht gelöscht werden';

  @override
  String get accountDeleteBlockedOwner =>
      'Du bist der Eigentümer der Admin-Konsole. Übergib die Eigentümerschaft zuerst an jemand anderen und komme dann zurück — sonst bliebe niemand übrig, der sie verwaltet.';

  @override
  String get accountDeleteConsent =>
      'Ich habe die Bedingungen vollständig gelesen, ich verstehe, dass die Löschung nicht rückgängig gemacht werden kann, und ich bin damit einverstanden, mein Konto und alle seine Daten dauerhaft zu löschen.';

  @override
  String get accountDeleteConsentRequired =>
      'Bitte akzeptiere zuerst die Löschungsbedingungen.';

  @override
  String get accountDeleteContinue => 'Ich verstehe, fortfahren';

  @override
  String get accountDeleteVerifyTitle => 'Bestätige deine E-Mail';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Wir senden einen 6-stelligen Code an $email, um zu bestätigen, dass diese Anfrage wirklich von dir stammt.';
  }

  @override
  String get accountDeleteSendCode => 'Löschungscode senden';

  @override
  String get accountDeleteResendCode => 'Erneut senden';

  @override
  String get accountDeleteCodeSent =>
      'Code gesendet. Schließe die Löschung innerhalb von 10 Minuten ab.';

  @override
  String get accountDeleteConfirmTitle => 'Letzter Schritt';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Gib deine Konto-E-Mail $email ein, damit es keinen Zweifel gibt, welches Konto gelöscht wird.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'In dem Moment, in dem du die Schaltfläche unten drückst, wird das Konto dauerhaft gelöscht.';

  @override
  String get accountDeleteConfirmField =>
      'Gib zur Bestätigung deine Konto-E-Mail ein';

  @override
  String get accountDeleteMfaHint =>
      'Dieses Konto hat die Zwei-Faktor-Authentifizierung aktiv, daher ist ein weiterer Code erforderlich.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Diese E-Mail stimmt nicht mit dem aktuellen Konto überein.';

  @override
  String get accountDeleteAction => 'Mein Konto dauerhaft löschen';

  @override
  String get accountDeleteDoneTitle => 'Dein Konto ist gelöscht';

  @override
  String get accountDeleteDoneBody =>
      'Dein Konto und seine Daten sind endgültig weg, und jedes Gerät wurde abgemeldet. Danke, dass du Origo X verwendet hast.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Öffne nach dem Schließen dieses Dialogs Apple-Konto-Einstellungen > Anmeldung & Sicherheit > Mit Apple anmelden > Origo X und wähle dann „Mit Apple anmelden“ beenden.';

  @override
  String get accountDeleteDoneClose => 'Schließen';

  @override
  String get bookSourceDetailsTitle => 'Buchdetails';

  @override
  String get bookSourceDetailsDescription => 'Über dieses Buch';

  @override
  String get bookSourceDetailsNoDescription =>
      'Diese Quelle stellt keine Beschreibung bereit.';

  @override
  String get bookSourceDetailsLatestChapter => 'Neuestes Kapitel';

  @override
  String get bookSourceDetailsLoadFailed =>
      'Vollständige Details konnten nicht geladen werden. Du kannst es erneut versuchen oder mit den verfügbaren Informationen lesen.';

  @override
  String get bookSourceDetailsOnShelf => 'Im Regal';

  @override
  String get bookSourceDetailsAddFailed =>
      'Dieses Buch konnte nicht deinem Regal hinzugefügt werden. Versuche es erneut.';

  @override
  String get bookSourceDetailsReadFailed =>
      'Dieses Buch konnte nicht geöffnet werden. Versuche es erneut.';

  @override
  String get appTextSize => 'Textgröße der Oberfläche';

  @override
  String get appTextSizeDescription =>
      'Ändert nur App-Menüs und -Steuerungen, nicht den Lesetext.';

  @override
  String get appTextSizePreview =>
      'Menüs und Einstellungen verwenden diese Textgröße.';

  @override
  String get appTextSizeDefault => '100 % (Standard)';

  @override
  String get bookSourceTrackUpdatesTitle =>
      'Updates und heruntergeladener Text';

  @override
  String get bookSourceTrackUpdatesBody =>
      'Heruntergeladene Bücher behalten ihre Quelle. Prüfe auf neue Kapitel, um neue Inhalte anzuhängen, oder aktualisiere heruntergeladene Kapitel, wobei deine Änderungen und dein Verlauf bewahrt werden.';

  @override
  String get bookSourceCheckNewChapters => 'Nach neuen Kapiteln suchen';

  @override
  String get bookSourceRefreshDownloaded =>
      'Heruntergeladene Kapitel aktualisieren';

  @override
  String get bookSourceNoNewChapters =>
      'Keine neuen Kapitel im Katalog. Aktualisiere heruntergeladene Kapitel, um früheren Text auf Änderungen zu prüfen.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return '$added Kapitel hinzugefügt, $refreshed aktualisiert';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Bestätige das zuletzt heruntergeladene Kapitel, bevor du mit Updates fortfährst. Dein vorhandener Text bleibt erhalten.';

  @override
  String get bookSourceSelectBoundary => 'Heruntergeladene Kapitel bestätigen';

  @override
  String get bookSourceBoundaryHelp =>
      'Wähle das letzte Quellenkapitel, das in deinem lokalen Text enthalten ist. Nur spätere Kapitel werden angehängt; vorhandener Text bleibt unangetastet.';

  @override
  String get bookSourceTrackingEstablished =>
      'Verfolgungsgrenze gespeichert. Du kannst jetzt nach neuen Kapiteln suchen.';

  @override
  String get bookSourceMappingChanged =>
      'Die Quelle hat ihre Kapitelreihenfolge oder -Kennungen geändert. Bestätige deine heruntergeladenen Kapitel erneut. Vorhandener Text wurde bewahrt.';

  @override
  String get bookSourceContentConflicts => 'Textänderungen brauchen Prüfung';

  @override
  String get bookSourceContentConflictBody =>
      'Du und die Quelle habt diese Kapitel geändert. Deine Version bleibt aktiv. Vergleiche und wähle, was du lesen möchtest; beide Versionen bleiben im Verlauf.';

  @override
  String get bookSourceCompareVersions => 'Text vergleichen';

  @override
  String get bookSourceLocalVersion => 'Mein Text';

  @override
  String get bookSourceRemoteVersion => 'Text der Quelle';

  @override
  String get bookSourceBaselineVersion => 'Heruntergeladene Basis';

  @override
  String get bookSourceKeepLocal => 'Meinen Text behalten';

  @override
  String get bookSourceUseRemote => 'Text der Quelle verwenden';

  @override
  String get bookSourceUpdateFailed =>
      'Update wurde nicht abgeschlossen. Dein Text wurde bewahrt. Bitte versuche es erneut.';

  @override
  String get cloudSyncReadableStorage =>
      'Bearbeitete Bücher werden als vollständige Dateien hochgeladen. Unveränderte Bücher werden nicht erneut übertragen. Lesefortschritt wird separat synchronisiert.';

  @override
  String get bookSourceBindSource => 'Buchquelle verknüpfen';

  @override
  String get bookSourceNotBound => 'Keine Quelle verknüpft';

  @override
  String get bookSourceDownloadedUnchanged =>
      'Heruntergeladene Kapitel sind auf dem neuesten Stand.';

  @override
  String get premiumSyncFailed =>
      'Der Mitgliedschaftsstatus konnte nicht synchronisiert werden. Es wird automatisch erneut versucht; ein Verbindungsfehler widerruft keinen verifizierten Zugriff.';

  @override
  String get premiumGrantedAccess =>
      'Du hast kostenlosen Premium-Zugriff. Ein zusätzlicher Kauf ist nicht nötig.';

  @override
  String get premiumOtherChannelAccess =>
      'Du hast Premium über einen anderen Kanal. Ein zusätzlicher Kauf ist nicht nötig.';

  @override
  String get premiumAppleAccess =>
      'Du hast Premium über den App Store. Ein zusätzlicher Kauf ist nicht nötig.';

  @override
  String get premiumExistingAccess =>
      'Du hast bereits Premium. Ein zusätzlicher Kauf ist nicht nötig.';

  @override
  String get premiumSyncPending => 'Mitgliedschaftsstatus wird synchronisiert';

  @override
  String get cloudSyncExportBook =>
      'Vollständige Datei in die Cloud exportieren';

  @override
  String get cloudSyncExportDone => 'Vollständige Datei exportiert';

  @override
  String get cloudSyncDiagnostics => 'Sync-Diagnose kopieren';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Dieser Ordner gehört zu einem älteren Sync-Format. Wähle einen neuen, leeren Ordner. Deine lokalen Bücher und bestehenden Cloud-Dateien bleiben erhalten.';

  @override
  String get cloudSyncSettings => 'Sync-Einstellungen';

  @override
  String get cloudSyncSettingsHint =>
      'Automatischer Sync, weitere Daten und Verbindung';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Lesepositionen synchronisieren, ohne Buchdateien hochzuladen';

  @override
  String get cloudSyncProgressExplanation =>
      'Wenn beide Geräte dasselbe Buch haben, kannst du allein den Lesefortschritt synchronisieren. Das neue Telefon braucht weiterhin eine lesbare Kopie; Fortschrittseinträge enthalten nicht den Buchtext.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Bücher hoch- oder herunterladen; Änderungen laden die ganze Datei hoch';

  @override
  String get cloudSyncOtherDataHint =>
      'Regal, Quellen, Lesezeichen, Notizen und Lese-Einstellungen';

  @override
  String get cloudSyncActivityHint =>
      'Fortschritt, Dateistatus und Fehlerdetails';

  @override
  String get cloudSyncNeedsAttention =>
      'Ein Sync-Problem braucht Aufmerksamkeit';

  @override
  String get cloudSyncFileStatus => 'Updates und Konflikte';

  @override
  String get cloudSyncTransferGuide => 'Auf ein neues Telefon umziehen';

  @override
  String get cloudSyncTransferGuideHint =>
      'Bücher und Lesefortschritt auf einem neuen Telefon wiederherstellen';

  @override
  String get cloudSyncTransferIntro =>
      'Das Hochladen eines Buchs ist für den Fortschrittssync optional. Eine Cloud-Kopie brauchst du nur, wenn das neue Telefon das Buch nicht bereits hat und du es von hier herunterladen möchtest.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Fortschritt auf dem alten Telefon synchronisieren';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Verlasse den Reader, um deine neueste Position zu speichern, aktiviere Lesefortschritt und tippe auf Jetzt synchronisieren. Verwende auf beiden Telefonen dieselbe WebDAV-Verbindung und denselben Sync-Ordner.';

  @override
  String get cloudSyncTransferHasBook =>
      '2. Das neue Telefon hat das Buch bereits';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Importiere dieselbe lokale Datei oder öffne dasselbe Online-Buch aus derselben Quelle. Synchronisiere den Fortschritt und öffne dann das Buch, um weiterzulesen. Gleiche Titel allein garantieren keine Übereinstimmung.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. Das neue Telefon braucht die Buchdatei';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'Öffne auf dem alten Telefon Buchdateien, erlaube Uploads und wähle das Buch. Nach erfolgreichem Upload synchronisiere das neue Telefon und lade es unter „Verfügbar“ herunter. Du kannst dieselbe Datei auch selbst übertragen.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Wenn du den Text auf dem alten Telefon bearbeitet hast, lade diese Version über Buchdateien hoch und lade sie auf dem neuen Telefon herunter, um die Buch-Identität zu bewahren. Lesepositionen können über verschiedene Textversionen hinweg falsch zugeordnet werden.';

  @override
  String get cloudSyncFrequency => 'Häufigkeit des automatischen Syncs';

  @override
  String get cloudSyncFrequencyOff => 'Aus (nur manuell)';

  @override
  String get cloudSyncFrequencyOnChange => 'Nach Änderungen';

  @override
  String get cloudSyncFrequency15Minutes => 'Alle 15 Minuten';

  @override
  String get cloudSyncFrequencyHourly => 'Stündlich';

  @override
  String get cloudSyncFrequencyDaily => 'Einmal täglich';

  @override
  String get cloudSyncFrequencyHint =>
      'Intervalle beginnen nach einem erfolgreichen automatischen Sync. Läuft die App nicht, holt sie beim nächsten Öffnen auf. Fehlgeschlagene Versuche werden wiederholt. „Jetzt synchronisieren“ funktioniert immer sofort.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Automatischer Sync: $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'Der Fortschritt wird in deiner gewählten Häufigkeit abgerufen. Das Öffnen eines Buchs setzt bei der zuletzt synchronisierten Position fort. Tippe bei Bedarf zuerst auf Jetzt synchronisieren, um den neuesten Fortschritt zu erhalten.';

  @override
  String get readerChapterProgressTitle => 'Kapitelfortschritt';

  @override
  String get readerChapterProgressHidden => 'Ausgeblendet';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return '$chapter/$total Kapitel';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return 'Noch $count Kapitel';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'Die Premium-Testphase läuft am $date ab.';
  }

  @override
  String get premiumTrialTitle => 'Premium-Testphase';

  @override
  String get bookSourceCheckUpdates => 'Nach Updates suchen';

  @override
  String get bookSourceUpdates => 'Buch-Updates';

  @override
  String get bookSourceNotChecked => 'Noch nicht geprüft';

  @override
  String get bookSourceUpToDate => 'Katalog ist aktuell';

  @override
  String get bookSourceUpdatesAvailable => 'Neue Kapitel verfügbar';

  @override
  String get bookSourceNeedsMapping => 'Bestätige, wo es weitergeht';

  @override
  String bookSourceLastChecked(String time) {
    return 'Zuletzt geprüft: $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Zuletzt aktualisiert: $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown => 'Update-Zeit nicht verfügbar';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Neuestes: $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Solange das Regal geöffnet ist, werden Kataloge alle 30 Minuten geprüft. Prüfe jederzeit manuell. Online-Bücher nutzen den neuesten Katalog; lokale TXT-Bücher laden neue Kapitel nur, wenn du das Fortsetzen wählst. Bestätige nach dem Verknüpfen oder Wechseln einer Quelle das letzte Kapitel, das bereits in deiner lokalen Datei ist. Updates ersetzen deinen Originaltext nicht. Die Update-Zeit stammt von der Quelle oder erfasst, wann ein neues Kapitel erstmals erkannt wurde.';

  @override
  String get bookSourceBindHelp =>
      'Finde dieses Buch in deinen Quellen, um sein Cover hinzuzufügen und Quellenwechsel und Kapitel-Updates zu aktivieren. Dein lokaler Text und deine Leseposition bleiben erhalten.';

  @override
  String get bookSourceContinueUpdate => 'Neue Kapitel herunterladen';

  @override
  String get settingsCloseReaderToLibraryTitle =>
      'Close reader to return to library';

  @override
  String get settingsCloseReaderToLibrarySubtitle =>
      'When a book is open, the window close button returns to the main window instead of quitting the app';

  @override
  String get navMe => 'Mein Bereich';

  @override
  String get settingsPreferencesTitle => 'Einstellungen';

  @override
  String get settingsPreferencesSubtitle => 'Darstellung, Lesen, Sprache';

  @override
  String get settingsManagementTitle => 'Einstellungen und Verwaltung';

  @override
  String get settingsDataSyncSubtitle => 'WebDAV-Sicherung, Cache';

  @override
  String get settingsContentServicesTitle => 'Inhalte und Dienste';

  @override
  String get settingsContentServicesSubtitle => 'Quellen, KI, Vorlesen';

  @override
  String get settingsAboutSupportSubtitle => 'Version, Updates, Open Source';

  @override
  String get settingsPremiumSubtitle =>
      'Weitere Quellen und Zugriff auf private Netzwerke';

  @override
  String get settingsGuestTitle => 'Nicht angemeldet';

  @override
  String get settingsGuestSubtitle => 'Lokales Lesen erfordert kein Konto';

  @override
  String get settingsWebDavConfigured => 'WebDAV-Sicherung eingerichtet';

  @override
  String get settingsPremiumActive => 'Premium aktiv';

  @override
  String get settingsPremiumSyncFailed =>
      'Mitgliedschaft konnte nicht synchronisiert werden';

  @override
  String get settingsWebDavWorking => 'WebDAV wird verarbeitet';

  @override
  String get storeReaderLockedTitle => 'Basisversion kaufen';

  @override
  String get storeReaderLockedBody =>
      'Zum Lesen in dieser Store-Version benötigst du eine aktive Testphase oder die gekaufte Basisversion. Deine Bücher und Notizen bleiben erhalten. Kehre zum Bücherregal zurück, um deine Daten zu exportieren.';

  @override
  String get storeReaderUnlock => 'Testen, kaufen oder wiederherstellen';

  @override
  String get storeReaderBack => 'Zurück zum Bücherregal';

  @override
  String get storeReaderChecking => 'Lesezugriff wird geprüft…';

  @override
  String get storeReaderBenefitTitle => 'Basisversion';

  @override
  String get storeReaderBenefitBody =>
      'Lokales Lesen dauerhaft nutzen. Kein Origo-Konto erforderlich.';

  @override
  String storeTrialStart(int days) {
    return '$days Tage kostenlos testen';
  }

  @override
  String storeTrialDetails(int days) {
    return 'Lokales Lesen $days Tage kostenlos testen. Keine automatische Abbuchung. Danach ist ein einmaliger Kauf der Basisversion nötig. Bücher und Notizen bleiben erhalten.';
  }

  @override
  String get storeTrialStarted =>
      'Deine Testphase für die Store-Version hat begonnen.';

  @override
  String get storeTrialExpired =>
      'Deine Testphase für die Store-Version ist beendet. Kaufe einmalig, um fortzufahren, oder stelle einen bestehenden Kauf wieder her.';

  @override
  String storePurchaseButton(String store) {
    return 'Basisversion über $store kaufen';
  }

  @override
  String storePurchaseBilling(String store) {
    return 'Einmaliger Kauf der Basisversion ohne automatische Verlängerung. $store zeigt den Preis an und verarbeitet die Zahlung.';
  }

  @override
  String storePurchaseRestoreHelp(String store) {
    return 'Mit dem beim Kauf verwendeten $store-Konto wiederherstellen. Keine Origo-Anmeldung und keine erneute Zahlung erforderlich.';
  }

  @override
  String storePurchaseAccess(String store) {
    return 'Du hast die Basisversion bereits über $store gekauft. Ein erneuter Kauf ist nicht erforderlich.';
  }

  @override
  String get storeRestoreEmpty =>
      'Es wurde kein wiederherstellbarer Kauf gefunden. Prüfe dein Store-Konto und das verknüpfte Origo X-Konto.';

  @override
  String get basicRestoreEmpty =>
      'Kein Kauf der Basisversion gefunden. Prüfe dein Store-Konto.';

  @override
  String get storeGoogleRefundTerms =>
      'Beantrage eine Rückerstattung über Google Play. Eine bestätigte Rückerstattung entzieht nur den Zugriff aus diesem Kauf; unabhängige Zugriffsrechte bleiben gültig.';

  @override
  String get storeReaderLegacyNotice =>
      'Dein bestehender grundlegender Lesezugriff bleibt erhalten. Für erweiterte Quellenkompatibilität ist weiterhin Premium erforderlich.';

  @override
  String get storePrivacyPurchaseBody =>
      'Verifizierungsdaten des Stores und eine Kontokennung werden an unseren Server gesendet, um den Zugriff zu prüfen und wiederherzustellen. Die Verifizierung bei Google Play umfasst ein Kauftoken und eine gehashte Kontokennung. Wir erhalten keine Zahlungskartendaten.';

  @override
  String storeTrialLegacyDetails(int days) {
    return 'Dein bisheriger Lesezugriff bleibt gültig. Die $days-tägige Testphase ist nicht erforderlich.';
  }

  @override
  String get storeReaderSupportSubtitle =>
      'Teste lokales Lesen oder kaufe die Basisversion einmalig zur dauerhaften Nutzung';

  @override
  String get storeBillingUnavailable =>
      'Käufe im Store sind noch nicht verfügbar. Versuche es später erneut. Dein bestehender Zugriff bleibt unverändert.';

  @override
  String get accountSignInTitle => 'Bei Origo X anmelden';

  @override
  String get accountSignInSubtitle => 'Konto und Käufe verwalten';

  @override
  String accountRegistrationStep(int step) {
    return 'Konto erstellen · $step / 3';
  }

  @override
  String get accountSetupTitle => 'Konto einrichten';

  @override
  String get accountSetupHint => 'Name und Foto können später ergänzt werden.';

  @override
  String get accountInvalidEmail => 'Gültige E-Mail-Adresse eingeben';

  @override
  String get accountCodeFormat => 'Den 6-stelligen E-Mail-Code eingeben';

  @override
  String get accountPasswordRequired => 'Passwort eingeben';

  @override
  String get accountShowPassword => 'Passwort anzeigen';

  @override
  String get accountHidePassword => 'Passwort verbergen';

  @override
  String accountResendIn(int seconds) {
    return 'In $seconds s erneut senden';
  }

  @override
  String get accountBackToCode => 'Zurück zum E-Mail-Code';

  @override
  String get accountAuthorizationTitle => 'Im Browser fortfahren';

  @override
  String get accountReopenAuthorization => 'Anmeldeseite erneut öffnen';

  @override
  String get accountSignOutHint =>
      'Lokale Bücher bleiben erhalten. Melde dich erneut an, um deine Kontorechte zu prüfen.';

  @override
  String get accountDiscardChanges => 'Änderungen verwerfen';

  @override
  String get accountUnsavedChanges =>
      'Deine Profiländerungen wurden noch nicht gespeichert.';

  @override
  String get accountAuthorizationExpired =>
      'Die Anmeldung ist abgelaufen. Bitte versuche es erneut.';

  @override
  String get purchaseDetailsTitle => 'Kaufdetails';

  @override
  String get purchaseBenefitsAction => 'Alle Vorteile ansehen';

  @override
  String get purchaseTermsAction => 'Bedingungen & Datenschutz';

  @override
  String get purchaseAccountCaption => 'Mit deinem Origo-Konto verknüpft';

  @override
  String get basicBenefitsTitle => 'Das komplette Leseerlebnis';

  @override
  String get basicReadingTitle => 'Lesen in vielen Formaten';

  @override
  String get basicReadingBody =>
      'Lies TXT, EPUB, PDF und weitere Formate. Importiere Bücher mit Inhaltsverzeichnis und Lesezeichen und nutze mehrere Umblätterarten, ablenkungsfreies Lesen und Doppelseiten auf Tablets.';

  @override
  String get basicFormatNote =>
      'Die Formatunterstützung variiert je nach Plattform; DRM-geschützte Bücher werden nicht unterstützt.';

  @override
  String get basicAppearanceTitle => 'Designs & Schriften';

  @override
  String get basicAppearanceBody =>
      'Passe Designs und Hintergründe an, importiere Schriften und justiere Schriftgröße, Zeilenabstand, Ränder und Absätze.';

  @override
  String get basicTtsTitle => 'Vorlesen & Hören';

  @override
  String get basicTtsBody =>
      'Höre mit Gerätestimmen, passe das Tempo an und stelle einen Einschlaftimer.';

  @override
  String get basicCloudTtsTitle => 'Cloud-TTS';

  @override
  String get basicCloudTtsBody =>
      'Richte Cloud-Sprachdienste ein, wähle Modelle und Stimmen und speichere mehrere Profile.';

  @override
  String get basicAiTitle => 'KI-Leseassistent';

  @override
  String get basicAiBody =>
      'Verbinde deinen KI-Dienst, stelle beim Lesen Fragen und vertiefe dein Verständnis.';

  @override
  String get basicNotesTitle => 'Notizen & Leseverlauf';

  @override
  String get basicNotesBody =>
      'Durchsuche Buchtexte, speichere Lesezeichen, Markierungen und Notizen, sieh Lesestatistiken an und exportiere Lesedaten.';

  @override
  String get basicSourcesTitle => 'Offene Buchquellen';

  @override
  String get basicSourcesBody =>
      'Importiere kompatible ORSP-Quellen, um Online-Inhalte zu suchen und zu lesen. Die App liefert keine Quellenadressen oder Buchinhalte.';

  @override
  String get basicSyncTitle => 'Bibliothek & Sicherung';

  @override
  String get basicSyncBody =>
      'Verwalte deine lokale Bibliothek und sichere oder stelle Bücher, Lesedaten und Einstellungen mit WebDAV wieder her.';

  @override
  String get basicServicesNote =>
      'KI und Cloud-TTS erfordern eigene Dienste; Gebühren von Drittanbietern sind nicht enthalten.';

  @override
  String get basicEditionTitle => 'Basisversion';

  @override
  String get basicEditionSummary => 'Ein Kauf. Das komplette Leseerlebnis.';

  @override
  String get basicEditionNoAccount => 'Keine Origo-Anmeldung nötig';

  @override
  String get premiumEditionSummary =>
      'Erweiterte Funktionen. Mehr Quellenformate.';

  @override
  String get storeReaderLicenseTitle => 'Basisversion kaufen';

  @override
  String get storeReaderLicenseSubtitle =>
      'Lokales Lesen 14 Tage testen und danach die Basisversion einmalig kaufen.';

  @override
  String get storeReaderLifetimeTitle => 'Basisversion';

  @override
  String storeReaderOwned(String store) {
    return 'Basisversion über $store gekauft.';
  }

  @override
  String get storePremiumPrerequisiteTitle => 'Zuerst die Basisversion kaufen';

  @override
  String get storePremiumPrerequisiteBody =>
      'Premium wird nach dem Kauf der Basisversion separat angeboten. Eine Testphase reicht nicht aus.';

  @override
  String get storePremiumPriceCaption =>
      'Dauerhaftes Premium · mit deinem Origo-Konto verknüpft';

  @override
  String storePremiumPurchaseButton(String store) {
    return 'Premium über $store kaufen';
  }

  @override
  String storePremiumBilling(String store) {
    return 'Premium ist ein separater Einmalkauf ohne automatische Verlängerung. $store zeigt den Preis an und verarbeitet die Zahlung. Premium wird mit deinem angemeldeten Origo-Konto verknüpft.';
  }

  @override
  String storePremiumRestoreHelp(String store) {
    return 'Melde dich beim verknüpften Origo-Konto an und stelle Premium mit dem beim Kauf verwendeten $store-Konto wieder her. Es entstehen keine erneuten Kosten.';
  }

  @override
  String storeReaderTrialExpiresAt(String date) {
    return 'Die Testphase der Basisversion endet am $date.';
  }

  @override
  String get storeReaderPurchaseSuccess => 'Basisversion gekauft';

  @override
  String get storeReaderRestoreSuccess =>
      'Kauf der Basisversion wiederhergestellt';

  @override
  String get storeReaderTestPurchaseVerified =>
      'Testkauf der Basisversion bestätigt; keine reguläre Lizenz erteilt.';

  @override
  String get storeReaderPurchaseRevoked =>
      'Dieser Kauf der Basisversion wurde widerrufen.';

  @override
  String storeReaderPendingApproval(String store) {
    return 'Warten auf die Genehmigung von $store. Nach der Prüfung wird die Basisversion aktiviert.';
  }

  @override
  String get storeReaderVerifying => 'Kauf der Basisversion wird geprüft…';

  @override
  String get storeReaderRestoring =>
      'Kauf der Basisversion wird wiederhergestellt…';
}
