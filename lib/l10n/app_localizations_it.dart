// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Home';

  @override
  String get library => 'Libreria';

  @override
  String get bookSources => 'Sorgenti';

  @override
  String get discover => 'Scopri';

  @override
  String get discoverRecommended => 'Per te';

  @override
  String get discoverCategories => 'Categorie';

  @override
  String get discoverLatest => 'Novità';

  @override
  String get discoverLoadFailed => 'Impossibile caricare i contenuti di Scopri';

  @override
  String get discoverRetry => 'Riprova';

  @override
  String get discoverEmptyTitle => 'Ancora niente da mostrare';

  @override
  String get discoverEmptyMessage =>
      'Questa sezione non ha ancora contenuti da mostrare.';

  @override
  String get discoverUnsupportedTitle =>
      'Le sorgenti attuali non supportano questa sezione';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'È necessaria una sorgente con la funzionalità $capability. Quelle esistenti restano comunque utilizzabili per la ricerca.';
  }

  @override
  String get discoverCategoryEmpty =>
      'Non ci sono ancora libri da mostrare in questa categoria.';

  @override
  String get bookSourceChannelLoadFailed => 'Impossibile caricare il canale';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'La sorgente non ha restituito libri utilizzabili: $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'Impossibile connettersi al server della sorgente dopo aver provato tutti gli indirizzi di rete disponibili. Riprova più tardi.';

  @override
  String get bookSourceRedirectFailed =>
      'Il sito della sorgente continuava a reindirizzare. I cookie del sito sono stati conservati, ma l\'indirizzo non ha comunque restituito contenuti.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'Il sito della sorgente ha restituito HTTP $status. L\'indirizzo del canale potrebbe non essere più valido oppure essere bloccato dal sito.';
  }

  @override
  String get bookSourceStandardLayout => 'Layout standard';

  @override
  String get bookSourceListLayout => 'Layout a elenco';

  @override
  String get bookSourceChangeChannel => 'Cambia';

  @override
  String get bookSourceChangeSourceTitle => 'Cambia sorgente';

  @override
  String get bookSourceChangeCurrentSource => 'Sorgente attuale';

  @override
  String get bookSourceChangeTargetSource => 'Cambia con';

  @override
  String get bookSourceChangeNotSelected => 'Nessuna selezione';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'Sei al capitolo $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Trova questo libro in altre sorgenti';

  @override
  String get bookSourceChangeSearchAgain => 'Cerca di nuovo';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Cerca in tutte le sorgenti rimanenti';

  @override
  String get bookSourceChangeCheckAuthor => 'Corrispondenza autore';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return 'Verificate $completed di $total';
  }

  @override
  String get bookSourceChangeNoOtherSources =>
      'Nessun\'altra sorgente disponibile';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Aggiungi e attiva prima un\'altra sorgente che supporti la ricerca.';

  @override
  String get bookSourceChangeSearching => 'Ricerca di altre sorgenti';

  @override
  String get bookSourceChangeSearchingHint =>
      'Le corrispondenze appaiono man mano che ogni sorgente completa la ricerca.';

  @override
  String get bookSourceChangeNoMatches =>
      'Nessuna sorgente corrispondente trovata';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Modifica il titolo o disattiva la corrispondenza dell\'autore, poi cerca di nuovo.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return '$count richieste alle sorgenti non riuscite. Puoi cercare di nuovo.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Autore diverso';

  @override
  String get bookSourceChangeValidating =>
      'Verifica del catalogo e del capitolo attuale…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Verifica non riuscita: $details';
  }

  @override
  String get bookSourceChangeReadable => 'Capitolo attuale leggibile';

  @override
  String bookSourceChangeChapterCount(int count) {
    return '$count capitoli';
  }

  @override
  String bookSourceChangeResponseTime(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get bookSourceChangeTapToValidate =>
      'Seleziona per verificare il catalogo e il capitolo attuale.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Questa versione della sorgente è già nella libreria.';

  @override
  String get bookSourceChangeSwitching => 'Cambio sorgente…';

  @override
  String get bookSourceChangeSwitchAction => 'Passa a questa sorgente';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Sorgente cambiata in $source';
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
    return '$count canali';
  }

  @override
  String get bookSourceManagementTitle => 'Gestisci sorgenti';

  @override
  String get bookSourceManagementSubtitle =>
      'Aggiungi, attiva, rimuovi ed esamina i fornitori di contenuti. Scopri resta concentrato sulla ricerca di libri.';

  @override
  String get settingsContentSourcesTitle => 'Sorgenti di contenuti';

  @override
  String get settingsContentSourcesSubtitle =>
      'Aggiungi, attiva o rimuovi sorgenti di libri aperte';

  @override
  String get bookSourcesSubtitle =>
      'Collega sorgenti aperte e cerca contenuti leggibili tra i vari fornitori';

  @override
  String get bookSourcesAdd => 'Aggiungi sorgente';

  @override
  String get bookSourcesSearchHint =>
      'Cerca nelle sorgenti attive per titolo o autore';

  @override
  String get bookSourcesSearch => 'Cerca';

  @override
  String get bookSourcesLoadMore => 'Carica altri';

  @override
  String bookSourcesFailedCount(int count) {
    return '$count richieste alle sorgenti non riuscite';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Impostazioni di ricerca';

  @override
  String get bookSourcesSearchSettingsTitle => 'Impostazioni di ricerca';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Richieste simultanee';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Timeout per sorgente (s)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Limite sorgenti';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Quando sono attive molte sorgenti, se ne cercano al massimo questo numero (in ordine di elenco) per limitare l\'uso di rete e batteria.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return 'Sono attive $enabledCount sorgenti, oltre l\'attuale limite di $limit. Le sorgenti oltre il limite non saranno cercate.';
  }

  @override
  String get bookSourcesSearchResetDefaults => 'Ripristina predefiniti';

  @override
  String get bookSourcesSearchPrompt =>
      'Aggiungi e attiva una sorgente per cercarla qui';

  @override
  String get bookSourcesNoResults => 'Nessun libro corrispondente trovato';

  @override
  String get bookSourcesNoSourcesTitle => 'Ancora nessuna sorgente';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Incolla l\'indirizzo di un servizio compatibile con l\'Origo Source Protocol.';

  @override
  String get bookSourcesManageTitle => 'Sorgenti collegate';

  @override
  String get bookSourcesEnabled => 'Attiva';

  @override
  String get bookSourcesDisabled => 'Disattivata';

  @override
  String get bookSourcesRunnable => 'Pronta all\'uso';

  @override
  String get bookSourcesPendingCompatibility => 'Nessuna regola eseguibile';

  @override
  String get bookSourcesRequiresLogin => 'Richiede accesso';

  @override
  String get bookSourcesManagementSearchHint =>
      'Cerca nome, URL, note o gruppo';

  @override
  String get bookSourcesClearSearch => 'Cancella ricerca';

  @override
  String get bookSourcesAllGroups => 'Tutti i gruppi';

  @override
  String get bookSourcesChooseGroup => 'Scegli un gruppo di sorgenti';

  @override
  String get bookSourcesSearchGroups => 'Cerca gruppi';

  @override
  String get bookSourcesNoMatchingSources =>
      'Nessuna sorgente corrisponde alla ricerca e ai filtri attuali';

  @override
  String get bookSourcesResetFilters => 'Azzera';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return 'Mostrate $visible su $total';
  }

  @override
  String get bookSourcesRemove => 'Rimuovi';

  @override
  String get bookSourcesRemoveTitle => 'Rimuovi sorgente';

  @override
  String get bookSourcesRemoveMessage =>
      'Rimuove solo la configurazione della sorgente. I libri locali non vengono toccati.';

  @override
  String get bookSourcesCancel => 'Annulla';

  @override
  String get bookSourcesConfirm => 'Conferma';

  @override
  String get bookSourcesAddTitle => 'Aggiungi sorgente';

  @override
  String get bookSourcesImportLink => 'Importa link';

  @override
  String get bookSourcesAnalyze => 'Leggi sorgenti';

  @override
  String get bookSourcesDetectedOrsp => 'Rilevato: ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Rilevata: Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'Sorgenti ORSP';

  @override
  String get bookSourcesProtocolGroupAdditional =>
      'Sorgenti con altri protocolli';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Questa sorgente non è disponibile per l\'account o le impostazioni attuali.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Nessuna sorgente ha superato la verifica di ricerca dal vivo. Non è stato importato nulla.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return 'Verificate $completed/$total; $available funzionanti';
  }

  @override
  String get bookSourcesSelect => 'Seleziona sorgenti';

  @override
  String get bookSourcesSelectAll => 'Seleziona tutte';

  @override
  String get bookSourcesClearSelection => 'Cancella selezione';

  @override
  String get bookSourcesEnableSelected => 'Attiva selezionate';

  @override
  String get bookSourcesDisableSelected => 'Disattiva selezionate';

  @override
  String get bookSourcesExportSelected => 'Esporta selezionate';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return 'Esportate $count sorgenti in $location';
  }

  @override
  String get bookSourcesExportFailed =>
      'Impossibile esportare le sorgenti selezionate';

  @override
  String get bookSourcesExportUnsupported =>
      'L\'esportazione delle sorgenti non è ancora supportata su questa piattaforma';

  @override
  String get bookSourcesExportReplaceTitle => 'Sostituire il file esistente?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Un file esiste già in $path. Sostituirlo?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Sostituisci';

  @override
  String get bookSourcesDeleteSelected => 'Elimina selezionate';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return 'Eliminare $count sorgenti selezionate? I libri locali non vengono toccati.';
  }

  @override
  String get bookSourcesCheckSelected => 'Verifica selezionate';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return '$healthy su $total sorgenti sono sane';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Verifica e pulisci le sorgenti';

  @override
  String get bookSourcesCleanupNoCheckableSources =>
      'Nessuna sorgente da verificare';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Tutte le $count sorgenti verificate sono pienamente disponibili';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Risultati di integrità';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return '$fullyAvailable pienamente disponibili · $needsAttention da rivedere';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Funzionalità mancanti o un timeout non significano che una sorgente sia inutilizzabile. Seleziona solo le sorgenti che vuoi disattivare.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return 'Disattiva $count selezionate';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return 'Disattivate $count sorgenti';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Interrotto — verificate $count sorgenti. Eseguila di nuovo più tardi per riprendere da dove hai lasciato.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Manutenzione sorgenti';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Trova duplicati e verifica la disponibilità delle sorgenti';

  @override
  String get bookSourcesMaintenanceHealthTitle => 'Verifica integrità sorgenti';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Verifica ricerca e lettura; riusa i risultati integri recenti';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Verifica integrità sorgenti in corso';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Pulizia dei duplicati';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Confronta le sorgenti in locale, senza rete';

  @override
  String get bookSourcesMaintenanceReviewTitle =>
      'Ultimo risultato della verifica';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return '$count sorgenti richiedono attenzione';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Vengono disattivate solo le sorgenti che confermi. Le loro configurazioni vengono conservate.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Verifica delle sorgenti';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Verifica di ricerca, dettagli, cataloghi e contenuti';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Verifica integrità sorgenti completata';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return 'Verificate $checked sorgenti; $attention richiedono attenzione';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Interrompi verifica';

  @override
  String get bookSourcesMaintenanceBackground => 'Continua in background';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Chiudi questa vista d\'avanzamento e la verifica continuerà in silenzio mentre l\'app è in esecuzione.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'La verifica integrità sorgenti continua in silenzio in background';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Rivedi risultati';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Manutenzione sorgenti $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Trova sorgenti duplicate';

  @override
  String get bookSourcesDedupeNone => 'Nessuna sorgente duplicata trovata';

  @override
  String get bookSourcesDedupeReviewTitle => 'Rivedi le sorgenti duplicate';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return '$groups gruppi, $duplicates sorgenti duplicate';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'La sorgente consigliata viene conservata. I duplicati selezionati verranno disattivati, non eliminati.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return 'Disattiva $count selezionate';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return 'Disattivate $count sorgenti duplicate';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Esatta';

  @override
  String get bookSourcesDedupeModeStandard => 'Standard';

  @override
  String get bookSourcesDedupeModeSite => 'Stesso sito';

  @override
  String get bookSourcesDedupeExactReason => 'Stessa identità di sorgente';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Stesso indirizzo di sorgente normalizzato';

  @override
  String get bookSourcesDedupeSiteReason => 'Stesso sito; revisione necessaria';

  @override
  String get bookSourcesDedupeRecommended => 'Consigliata';

  @override
  String get bookSourcesDedupeReviewAction => 'Rivedi deduplicazione';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return '$ready pronte, $duplicates duplicate, $errors non valide';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return '$books libri · $comics fumetti · $unsupported attualmente non eseguibili';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults => 'Ripristina consigli';

  @override
  String get bookSourcesUrlLabel => 'Indirizzo sorgente';

  @override
  String get bookSourcesUrlHint =>
      'https://example.com o un URL JSON di una sorgente';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'Origo X non include sorgenti e non gestisce, consiglia o promuove servizi di sorgenti di terze parti. Ogni indirizzo di sorgente viene aggiunto da te.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Confermo di essere autorizzato ad accedere a questi contenuti e di non usare la sorgente per aggirare accesso, pagamento, DRM o altri sistemi di controllo degli accessi.';

  @override
  String get bookSourcesConnect => 'Leggi e importa';

  @override
  String get bookSourcesConnecting => 'Elaborazione delle sorgenti…';

  @override
  String get bookSourcesAdded => 'Sorgente aggiunta';

  @override
  String get bookSourcesRefresh => 'Aggiorna sorgente';

  @override
  String get bookSourcesRefreshed => 'Sorgente aggiornata';

  @override
  String get bookSourcesRefreshFailed =>
      'Impossibile aggiornare questa sorgente';

  @override
  String get bookSourcesProtocolTitle => 'Origo Source Protocol';

  @override
  String get bookSourcesInformationTitle => 'Protocollo e informazioni';

  @override
  String get bookSourcesInformationSubtitle =>
      'Consulta il protocollo, i link del progetto e le informazioni sui diritti dei contenuti';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'Scopri le funzionalità delle sorgenti supportate e il protocollo aperto';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Visita il repository del protocollo su GitHub';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'Comprendi i contenuti di terze parti e i limiti dei diritti';

  @override
  String get bookSourcesProtocolDescription =>
      'Un contratto comune per scoperta, ricerca, dettagli dei libri, cataloghi e contenuti dei capitoli. Gli sviluppatori possono ospitare sorgenti native o creare adattatori per contenuti che sono autorizzati a fornire.';

  @override
  String get bookSourcesProtocolDetails => 'Visita il protocollo';

  @override
  String get bookSourcesProtocolRepository => 'Repository del protocollo';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Visita su GitHub';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'Impossibile aprire il repository del protocollo';

  @override
  String get bookSourcesProtocolDialogTitle =>
      'Protocollo sorgenti aperte v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Una sorgente pubblica /.well-known/open-reading-source.json e implementa le funzionalità di lettura principali: ricerca, dettagli del libro, cataloghi dei capitoli paginati e contenuti dei capitoli. La versione 1.4 mantiene la paginazione completa del catalogo, richiede queste funzionalità principali e conserva i metadati di operatore, contatto, licenza e dichiarazione dei diritti per le sorgenti HTTP(S) pubbliche che non richiedono accesso.';

  @override
  String get bookSourcesRightsDetails => 'Operatore e diritti';

  @override
  String get bookSourcesOperator => 'Operatore della sorgente';

  @override
  String get bookSourcesContentLicense => 'Licenza dei contenuti';

  @override
  String get bookSourcesRightsStatement => 'Dichiarazione dei diritti';

  @override
  String get bookSourcesRightsNotProvided => 'Non fornita da questa sorgente';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Queste dichiarazioni sono fornite dall\'operatore indipendente della sorgente. Origo X le mostra per trasparenza, ma non le verifica né le avalla.';

  @override
  String get bookSourcesContactOperator => 'Contatta l\'operatore';

  @override
  String get bookSourcesRightsReport => 'Segnalazione diritti';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'Impossibile aprire il modulo di segnalazione diritti';

  @override
  String get bookSourcesClose => 'Chiudi';

  @override
  String get sourceLoginTitle => 'Accesso alla sorgente';

  @override
  String get sourceLoginInfo => 'Dati di accesso';

  @override
  String get sourceLoginActions => 'Azioni sorgente';

  @override
  String get sourceLoginExtraSettings => 'Impostazioni aggiuntive';

  @override
  String get sourceLoginSecureStorageNotice =>
      'I dati di accesso restano nell\'archivio di sistema sicuro di questo dispositivo.';

  @override
  String get sourceLoginNoForm =>
      'Questa sorgente non offre un metodo di accesso disponibile.';

  @override
  String get sourceLoginBrowserTitle => 'Accedi sul sito originale';

  @override
  String get sourceLoginBrowserNotice =>
      'Completa l\'accesso nel browser, poi tocca Fine. Cookie e archiviazione locale del sito verranno salvati su questo dispositivo.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'L\'accesso dal sito è disponibile su Android, iPhone, iPad e Mac.';

  @override
  String get sourceLoginBrowserOpen => 'Apri il sito per accedere';

  @override
  String get sourceLoginSave => 'Accedi e salva la sessione';

  @override
  String get sourceLoginClear => 'Elimina la sessione di accesso';

  @override
  String get sourceLoginSaved => 'Sessione di accesso alla sorgente aggiornata';

  @override
  String get sourceLoginCleared =>
      'Sessione di accesso alla sorgente eliminata';

  @override
  String sourceLoginFailed(String details) {
    return 'Impossibile aggiornare la sessione di accesso alla sorgente: $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '“$sourceName” offre l\'accesso per i contenuti riservati agli account.';
  }

  @override
  String get sourceDebugMenuLabel => 'Debug';

  @override
  String get sourceDebugTitle => 'Debugger sorgenti';

  @override
  String get sourceDebugInputHint =>
      'Inserisci una parola chiave di ricerca oppure incolla l\'URL di un libro/catalogo/capitolo';

  @override
  String get sourceDebugRun => 'Esegui';

  @override
  String get sourceDebugStop => 'Ferma';

  @override
  String get sourceDebugClear => 'Cancella log';

  @override
  String get sourceDebugEmpty =>
      'Inserisci una parola chiave o un URL e tocca Esegui per vedere passo passo come questa sorgente lo risolve.';

  @override
  String get sourceDebugCopy => 'Copia';

  @override
  String get sourceDebugCopied => 'Copiato negli appunti';

  @override
  String get sourceHealthMenuLabel => 'Verifica integrità';

  @override
  String get sourceHealthHealthy => 'Integra';

  @override
  String get sourceHealthPartial => 'Parzialmente danneggiata';

  @override
  String get bookSourcesFullyAvailable => 'Pienamente disponibile';

  @override
  String get sourceHealthTimedOut => 'Verifica scaduta';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Danneggiate: $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'ricerca';

  @override
  String get sourceHealthCapabilityDiscover => 'scoperta';

  @override
  String get sourceHealthCapabilityInfo => 'info libro';

  @override
  String get sourceHealthCapabilityCatalog => 'catalogo';

  @override
  String get sourceHealthCapabilityContent => 'contenuto';

  @override
  String get sourceVerificationTitle => 'Verifica della sorgente';

  @override
  String get sourceVerificationBrowserHint =>
      'Completa la verifica del sito nel browser sicuro, poi scegli Verifica completata. L\'indirizzo della pagina e i cookie tornano solo a questa attività della sorgente.';

  @override
  String get sourceVerificationCodeHint =>
      'Leggi l\'immagine e inserisci il suo codice per continuare questa attività della sorgente.';

  @override
  String get sourceVerificationCodeLabel => 'Codice immagine';

  @override
  String get sourceVerificationSubmit => 'Continua';

  @override
  String get sourceVerificationRetry => 'Riapri il browser';

  @override
  String get sourceVerificationCancel => 'Annulla verifica';

  @override
  String sourceVerificationFailed(String details) {
    return 'Impossibile aprire la verifica della sorgente: $details';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get statistics => 'Statistiche';

  @override
  String get reading => 'Lettura';

  @override
  String get importBooks => 'Importa libri';

  @override
  String get darkMode => 'Modalità scura';

  @override
  String get lightMode => 'Modalità chiara';

  @override
  String get systemMode => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get accent => 'Colore accento';

  @override
  String get bookmarks => 'Segnalibri';

  @override
  String get notes => 'Note';

  @override
  String get highlights => 'Evidenziazioni';

  @override
  String get ttsReading => 'Sintesi vocale';

  @override
  String get share => 'Condividi';

  @override
  String get shareContent => 'Condividi contenuto';

  @override
  String get shareCurrentPage => 'Condividi pagina attuale';

  @override
  String get shareSelectedText => 'Condividi testo selezionato';

  @override
  String get shareProgress => 'Condividi progressi di lettura';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get stop => 'Ferma';

  @override
  String get speed => 'Velocità';

  @override
  String get pitch => 'Tono';

  @override
  String get language => 'Lingua';

  @override
  String get fontSize => 'Dimensione carattere';

  @override
  String get readingProgress => 'Progressi di lettura';

  @override
  String get totalPages => 'Pagine totali';

  @override
  String get currentPage => 'Pagina attuale';

  @override
  String get readingTime => 'Tempo di lettura';

  @override
  String get booksRead => 'Libri letti';

  @override
  String get todayReading => 'Lettura di oggi';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get save => 'Salva';

  @override
  String get back => 'Indietro';

  @override
  String get next => 'Avanti';

  @override
  String get previous => 'Precedente';

  @override
  String get search => 'Cerca';

  @override
  String get noResults => 'Nessun risultato trovato';

  @override
  String get loading => 'Caricamento...';

  @override
  String get error => 'Errore';

  @override
  String get initializationFailed => 'Inizializzazione non riuscita';

  @override
  String get unknownError => 'Errore sconosciuto';

  @override
  String get retry => 'Riprova';

  @override
  String get appearanceSettings => 'Aspetto';

  @override
  String get readingTips => 'Consigli di lettura';

  @override
  String get readingFontSettingsMoved =>
      'Impostazioni caratteri di lettura spostate';

  @override
  String get readingFontSettingsHint =>
      'Apri un libro, tocca il centro dello schermo, poi usa la barra degli strumenti in basso per regolare dimensione carattere, interlinea, spaziatura lettere, margini e carattere di lettura.';

  @override
  String get readingSettings => 'Impostazioni di lettura';

  @override
  String get enableTts => 'Attiva TTS';

  @override
  String get enableTtsHint => 'Attiva la lettura con sintesi vocale';

  @override
  String get ttsSpeedLabel => 'Velocità';

  @override
  String get ttsSpeedHint => 'Regola la velocità di lettura';

  @override
  String get ttsVolumeLabel => 'Volume';

  @override
  String get ttsVolumeHint => 'Regola il volume della lettura';

  @override
  String get ttsPitchLabel => 'Tono';

  @override
  String get ttsPitchHint => 'Regola il tono della lettura';

  @override
  String get appSettings => 'Impostazioni app';

  @override
  String get appFont => 'Carattere dell\'app';

  @override
  String get appFontDescription =>
      'Usato da navigazione, pulsanti, impostazioni e altro testo dell\'interfaccia. Non modifica i contenuti dei libri.';

  @override
  String get readerFont => 'Carattere di lettura';

  @override
  String get readerFontDescription =>
      'Per libri TXT e online. EPUB ha un’impostazione del carattere separata.';

  @override
  String get readerFontSelectionDescription =>
      'Scegli il carattere di lettura. EPUB offre il carattere del libro, quello di sistema e i caratteri installati.';

  @override
  String get readerFontBookPriorityHint =>
      'Usa il carattere incorporato nel libro quando disponibile; altrimenti usa il carattere di lettura predefinito della piattaforma.';

  @override
  String get readerFontOverrideHint =>
      'Sostituisce i caratteri incorporati dall\'editore.';

  @override
  String get fontBookEmbedded => 'Incorporato nel libro';

  @override
  String get fontSystem => 'Predefinito della piattaforma';

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
      'Usa un carattere di lettura ottimizzato per la piattaforma, per glifi e paginazione stabili.';

  @override
  String get fontSerifDescription =>
      'Carattere serif dal tono calmo ed editoriale, per la lettura prolungata.';

  @override
  String get fontSansSerifDescription =>
      'Carattere sans serif chiaro, adatto a interfacce compatte e alla lettura quotidiana.';

  @override
  String get fontMonospaceDescription =>
      'Carattere a spaziatura fissa, adatto a codice, materiale tecnico e layout essenziali.';

  @override
  String get fontPreviewText => 'Origo X · Leggi liberamente 开卷有益';

  @override
  String get customFonts => 'I miei caratteri';

  @override
  String get customFontsEmpty => 'Ancora nessun carattere personalizzato';

  @override
  String get customFontsEmptyHint =>
      'Importa una volta un file TTF o OTF, poi usalo per l\'interfaccia dell\'app o per la lettura.';

  @override
  String customFontsCount(int count) {
    return '$count caratteri importati';
  }

  @override
  String get customFontsLocalOnly =>
      'I caratteri importati sono salvati solo su questo dispositivo e non vengono sincronizzati automaticamente.';

  @override
  String get builtInFonts => 'Caratteri incorporati';

  @override
  String get onlineFonts => 'Caratteri online';

  @override
  String get fontDownload => 'Scarica';

  @override
  String get fontDownloading => 'Download…';

  @override
  String get fontDownloaded => 'Scaricato';

  @override
  String get fontDownloadFailed => 'Download non riuscito, tocca per riprovare';

  @override
  String get fontDownloadHint => 'Il primo uso richiede un download online';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Spessore regolabile $min–$max';
  }

  @override
  String get fontStaticWeight => 'Spessore fisso (il grassetto è sintetizzato)';

  @override
  String get fontDeleteDownload => 'Elimina download';

  @override
  String fontDeleteDownloadTitle(String name) {
    return 'Eliminare \"$name\" scaricato?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Libererà $size di spazio. Verrà riscaricato al prossimo uso.';
  }

  @override
  String get fontDownloadCancelled => 'Download annullato';

  @override
  String get fontDownloadNetworkFailed =>
      'Errore di rete, download non riuscito';

  @override
  String get fontDownloadInvalid =>
      'Il file del carattere scaricato non è valido';

  @override
  String get fontDownloadUnsupported =>
      'Il download di caratteri online non è supportato su questa piattaforma';

  @override
  String get importFont => 'Importa carattere';

  @override
  String get importingFont => 'Importazione carattere…';

  @override
  String get customFontImported => 'Carattere importato';

  @override
  String get customFontAlreadyImported =>
      'Questo carattere è già stato importato ed è pronto all\'uso';

  @override
  String get customFontApplied => 'Selezione carattere aggiornata';

  @override
  String get customFontAppliedToApp =>
      'Importato e impostato come carattere dell\'app';

  @override
  String get customFontAppliedToReader =>
      'Importato e impostato come carattere di lettura';

  @override
  String get customFontImportUnsupported =>
      'L\'importazione permanente dei caratteri non è ancora supportata su questa piattaforma.';

  @override
  String get customFontUnsupportedFormat =>
      'Scegli un file di carattere TTF o OTF.';

  @override
  String get customFontInvalid =>
      'Questo file non è un carattere valido o supportato.';

  @override
  String get customFontTooLarge => 'Il file del carattere supera 50 MB.';

  @override
  String get customFontReadFailed =>
      'Impossibile leggere il file del carattere.';

  @override
  String get customFontLoadFailed => 'Impossibile caricare il carattere.';

  @override
  String get customFontStorageFailed =>
      'Impossibile salvare il carattere su questo dispositivo.';

  @override
  String get customFontUnavailable =>
      'Il file del carattere non è disponibile. Eliminalo e importalo di nuovo.';

  @override
  String get setAsAppFont => 'Usa come carattere dell\'app';

  @override
  String get setAsReaderFont => 'Usa come carattere di lettura';

  @override
  String get setAsBothFonts => 'Usa per entrambi';

  @override
  String get renameFont => 'Rinomina carattere';

  @override
  String deleteCustomFontTitle(String name) {
    return 'Eliminare “$name”?';
  }

  @override
  String get deleteCustomFontMessage =>
      'Il file del carattere verrà rimosso da questo dispositivo.';

  @override
  String get deleteCustomFontInUse =>
      'Questo carattere è attualmente in uso. Eliminandolo, le impostazioni dei caratteri interessate torneranno ai valori predefiniti.';

  @override
  String get deleteAndReset => 'Elimina e ripristina';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Canale Telegram ufficiale';

  @override
  String get settingsTelegramOpenFailed =>
      'Impossibile aprire il link di Telegram';

  @override
  String get settingsQqChannel => 'Canale QQ';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'Impossibile aprire il link di invito del canale QQ';

  @override
  String get languageSystem => 'Segui il sistema';

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
  String get typographySettings => 'Tipografia';

  @override
  String get fontFamilyLabel => 'Carattere';

  @override
  String get fontSizeLabel => 'Dimensione carattere';

  @override
  String get readerFontWeightLabel => 'Spessore carattere';

  @override
  String get readerFontWeightLight => 'Sottile';

  @override
  String get readerFontWeightRegular => 'Normale';

  @override
  String get readerFontWeightMedium => 'Medio';

  @override
  String get readerFontWeightSemiBold => 'Semi-grassetto';

  @override
  String get readerFontWeightBold => 'Grassetto';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'I controlli di lettura usano cinque gradazioni leggibili da 300 a 700. L\'intervallo completo reale di questo carattere è $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'I controlli di lettura usano cinque gradazioni da 300 a 700. Questo carattere non dichiara un asse di spessore variabile, quindi il sistema approssima il risultato, che può variare tra piattaforme.';

  @override
  String get readerFontWeightPreview =>
      'Una pagina quieta porta più lontano · 字里行间';

  @override
  String get lineSpacingLabel => 'Interlinea';

  @override
  String get letterSpacingLabel => 'Spaziatura lettere';

  @override
  String get textAlignmentLabel => 'Allineamento testo';

  @override
  String get textAlignmentNatural => 'Naturale';

  @override
  String get textAlignmentJustified => 'Giustificato';

  @override
  String get firstLineIndentLabel => 'Rientro prima riga';

  @override
  String get paragraphSpacingLabel => 'Spaziatura paragrafi';

  @override
  String get pageMarginLabel => 'Margini pagina';

  @override
  String get resetDefault => 'Ripristina';

  @override
  String get ttsPanelTitle => 'Sintesi vocale';

  @override
  String get ttsPreviewEffect => 'Anteprima effetto';

  @override
  String get ttsVolume => 'Volume';

  @override
  String get ttsPitch => 'Tono';

  @override
  String get ttsSpeed => 'Velocità';

  @override
  String get ttsPreviousSentence => 'Frase precedente';

  @override
  String get ttsNextSentence => 'Frase successiva';

  @override
  String get ttsTimerStop => 'Arresto timer';

  @override
  String get ttsTimerOff => 'Nessun limite';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes minuti';
  }

  @override
  String get ttsPlaying => 'In riproduzione';

  @override
  String get ttsPaused => 'In pausa';

  @override
  String get ttsStopped => 'Fermata';

  @override
  String get ttsPreviousSentenceFailed =>
      'Riproduzione della frase precedente non riuscita';

  @override
  String get ttsNextSentenceFailed =>
      'Riproduzione della frase successiva non riuscita';

  @override
  String get ttsEmptyContentError =>
      'Il contenuto della pagina attuale è vuoto';

  @override
  String get ttsPlaybackFailed => 'Riproduzione non riuscita';

  @override
  String get ttsOperationFailed => 'Operazione non riuscita';

  @override
  String get pageTurningMode => 'Modalità pagina';

  @override
  String get pageTurningSlide => 'Scorrimento orizzontale';

  @override
  String get pageTurningScroll => 'Paginazione verticale';

  @override
  String get tapZoneSettings => 'Zone touch';

  @override
  String get tapZoneNextPage => 'Pagina successiva';

  @override
  String get tapZonePreviousPage => 'Pagina precedente';

  @override
  String get tapZoneMenu => 'Menu';

  @override
  String get tapZoneLegend => 'Legenda';

  @override
  String get tapZoneNextChapter => 'Capitolo successivo';

  @override
  String get tapZonePreviousChapter => 'Capitolo precedente';

  @override
  String get tapZoneNone => 'Nessuna azione';

  @override
  String get tapZoneSettingsHint =>
      'Personalizza l\'azione di ognuna delle nove zone touch';

  @override
  String get tapZoneChooseAction => 'Scegli un\'azione';

  @override
  String get tapZoneMenuRequiredHint =>
      'Tocca un\'area per cambiarne l\'azione. Almeno un\'area deve restare Menu; se rimuovi tutti i Menu, l\'area centrale tornerà a essere Menu.';

  @override
  String get tapZoneReset => 'Ripristina predefiniti';

  @override
  String get highlightColor => 'Colore evidenziazione';

  @override
  String get highlightPreview => 'Anteprima';

  @override
  String get highlightSampleText => 'Questo è un testo di esempio,';

  @override
  String get highlightSampleText2 => 'questa parte verrà evidenziata,';

  @override
  String get highlightSampleText3 =>
      'mostrando l\'effetto dell\'evidenziazione.';

  @override
  String get colorLightBlue => 'Azzurro';

  @override
  String get colorRed => 'Rosso';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorPurple => 'Viola';

  @override
  String get colorGold => 'Oro';

  @override
  String get colorOrange => 'Arancione';

  @override
  String get colorYellow => 'Giallo';

  @override
  String get colorDarkGreen => 'Verde scuro';

  @override
  String get colorCustom => 'Personalizzato';

  @override
  String get noteTypeHighlight => 'Evidenziazione';

  @override
  String get noteTypeUnderline => 'Sottolineatura';

  @override
  String get noteTypeNote => 'Nota';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Importa libro';

  @override
  String get importFromFiles => 'Importa da File';

  @override
  String get importNoBooks => 'Ancora nessun libro importato';

  @override
  String get importSuccess => 'Libro importato correttamente';

  @override
  String get importFailed => 'Importazione non riuscita';

  @override
  String get importProcessing => 'Elaborazione del libro...';

  @override
  String get author => 'Autore';

  @override
  String get progress => 'Avanzamento';

  @override
  String get continueReading => 'Continua a leggere';

  @override
  String get recentBooks => 'Libri recenti';

  @override
  String get allBooks => 'Tutti i libri';

  @override
  String get emptyLibrary => 'La libreria è vuota';

  @override
  String get deleteBook => 'Elimina libro';

  @override
  String get deleteBookConfirm => 'Vuoi davvero eliminare questo libro?';

  @override
  String get bookDeleted => 'Libro eliminato';

  @override
  String get userAgreement => 'Contratto utente';

  @override
  String get acceptAgreement => 'Ho letto e accetto';

  @override
  String get declineAgreement => 'Rifiuta';

  @override
  String get statsToday => 'Oggi';

  @override
  String get statsThisWeek => 'Questa settimana';

  @override
  String get statsTotal => 'Totale';

  @override
  String statsMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String statsHours(Object hours) {
    return '$hours h';
  }

  @override
  String statsBooks(Object count) {
    return '$count libri';
  }

  @override
  String get statsConsecutiveDays => 'Giorni consecutivi';

  @override
  String get statsFocusTime => 'Tempo di concentrazione';

  @override
  String get statsThisWeekTotal => 'Totale settimana';

  @override
  String get statsKeepReading => 'Leggi ogni giorno';

  @override
  String get statsMaxSession => 'Sessione più lunga';

  @override
  String get statsWeeklyTrend => 'Andamento settimanale';

  @override
  String get statsAchievements => 'Obiettivi';

  @override
  String get readerToolbarMenu => 'Menu';

  @override
  String get readerToolbarTOC => 'Indice';

  @override
  String get readerToolbarSettings => 'Impostazioni';

  @override
  String get readerAddBookmark => 'Aggiungi segnalibro';

  @override
  String get readerAddNote => 'Aggiungi nota';

  @override
  String get readerShare => 'Condividi';

  @override
  String get bookmarkAdded => 'Segnalibro aggiunto';

  @override
  String get bookmarkRemoved => 'Segnalibro rimosso';

  @override
  String get readerNavigationTitle => 'Navigazione di lettura';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Capitolo $current di $total';
  }

  @override
  String get readerSearchChapters => 'Cerca capitoli';

  @override
  String get readerBackToCurrentChapter => 'Torna al capitolo attuale';

  @override
  String get readerCurrentChapter => 'Attuale';

  @override
  String get readerCurrentPosition => 'Posizione attuale';

  @override
  String get readerNoChapterResults => 'Nessun capitolo corrispondente';

  @override
  String get readerNoChapterResultsHint =>
      'Prova un\'altra parola del titolo del capitolo.';

  @override
  String get readerNoBookmarks => 'Ancora nessun segnalibro';

  @override
  String get readerNoBookmarksHint =>
      'Tocca il pulsante segnalibro in alto a destra per salvare il tuo punto.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Aggiungi questo libro alla libreria prima di salvare segnalibri';

  @override
  String get themeBlue => 'Blu oceano';

  @override
  String get themeGreen => 'Verde foresta';

  @override
  String get themeOrange => 'Arancione vivace';

  @override
  String get themeRed => 'Rosso passionale';

  @override
  String get themeCustom => 'Personalizzato';

  @override
  String get tapZoneLeftRight => 'Sinistra/Destra';

  @override
  String get tapZoneLeftCenterRight => 'Sinistra/Centro/Destra';

  @override
  String get homeTagline => 'Leggi con eleganza';

  @override
  String get homeReadingStatsTitle => 'Statistiche di lettura';

  @override
  String get homeTodayReadingMoment => 'Il momento di lettura di oggi';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return 'Hai letto $minutes minuti, continua così';
  }

  @override
  String get homeTodayReadingJourneyStart =>
      'Inizia oggi il tuo viaggio nella lettura';

  @override
  String get homeTodayReadingKeepRhythm =>
      'Oggi sei in linea, mantieni il ritmo';

  @override
  String get homeTodayReadingPrompt =>
      'Riserva un po\' di tempo per leggere oggi';

  @override
  String homeTotalReadingHours(String hours) {
    return 'Totale di $hours ore di lettura';
  }

  @override
  String get homeWeeklyReading => 'Questa settimana';

  @override
  String get homeTotalReading => 'Lettura totale';

  @override
  String get homeLibraryCount => 'Libri in libreria';

  @override
  String get homeCollectionCount => 'Collezione';

  @override
  String get homeKeyMetrics => 'Indicatori principali';

  @override
  String get homeReadingRhythm => 'Ritmo di lettura';

  @override
  String get homeAchievements => 'Obiettivi di lettura';

  @override
  String get homeConsecutiveReading => 'Lettura consecutiva';

  @override
  String get homeConsecutiveReadingDesc =>
      'Mantieni un\'abitudine di lettura quotidiana';

  @override
  String get homeFocusDuration => 'Durata della concentrazione';

  @override
  String get homeFocusDurationDesc => 'Sessione di lettura più lunga';

  @override
  String get homeWeeklyTotal => 'Totale settimanale';

  @override
  String get homeWeeklyTotalDesc => 'Tempo di lettura di questa settimana';

  @override
  String get homeRecentReading => 'Letture recenti';

  @override
  String get homeWeeklyTrend => 'Andamento di lettura settimanale';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get unitMinute => 'min';

  @override
  String get unitHour => 'ora';

  @override
  String get unitBook => 'libri';

  @override
  String get unitDay => 'giorni';

  @override
  String get weekdayMonShort => 'Lun';

  @override
  String get weekdayTueShort => 'Mar';

  @override
  String get weekdayWedShort => 'Mer';

  @override
  String get weekdayThuShort => 'Gio';

  @override
  String get weekdayFriShort => 'Ven';

  @override
  String get weekdaySatShort => 'Sab';

  @override
  String get weekdaySunShort => 'Dom';

  @override
  String get agreementTagline =>
      'Lettura immersiva · Assistente AI · Prima il locale';

  @override
  String get agreementCardTitle => 'Contratto di servizio utente';

  @override
  String get agreementCardSubtitle => 'Leggi attentamente quanto segue';

  @override
  String get agreementWelcomeTitle => 'Benvenuto in Origo X';

  @override
  String get agreementWelcomeBody =>
      'Per garantire un\'esperienza di lettura stabile e prevedibile, leggi e accetta prima il seguente contratto.';

  @override
  String get agreementFeatureFormatsTitle => 'Supporto multiformato';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI e altri';

  @override
  String get agreementFeatureCustomizationTitle => 'Lettura personalizzata';

  @override
  String get agreementFeatureCustomizationBody =>
      'Personalizza caratteri, colori, tipografia e altro';

  @override
  String get agreementFeatureSyncTitle => 'Prima il locale';

  @override
  String get agreementFeatureSyncBody =>
      'Libri, progressi e note restano sul dispositivo che controlli tu';

  @override
  String get agreementFeatureTtsTitle => 'Sintesi vocale';

  @override
  String get agreementFeatureTtsBody =>
      'La narrazione vocale intelligente libera gli occhi, così puoi ascoltare ovunque';

  @override
  String get agreementTapToAgreeHint =>
      'Toccando \"Accetta e continua\" confermi di aver letto e accettato di usare questa app';

  @override
  String get agreementExitApp => 'Esci dall\'app';

  @override
  String get agreementAgreeAndContinue => 'Accetta e continua';

  @override
  String get agreementExitDialogContent =>
      'Se non accetti il contratto utente, non potrai usare questa app. Vuoi davvero uscire?';

  @override
  String get agreementConfirmExit => 'Esci';

  @override
  String get readerFileMissing => 'File del libro non trovato. Reimportalo.';

  @override
  String get readerUnsupportedFormat =>
      'Questo formato non può ancora essere letto.';

  @override
  String get readerKindleDrmProtected =>
      'Questo libro Kindle è protetto da DRM e non può essere letto qui. Sono supportati solo libri senza DRM.';

  @override
  String get readerComicNoPages =>
      'Nessuna pagina immagine trovata in questo archivio di fumetti.';

  @override
  String get readerComicCbrUnsupported =>
      'Questo fumetto CBR usa la compressione RAR vera e non è ancora leggibile. Convertilo in CBZ.';

  @override
  String get readerComicArchiveUnsupported =>
      'Il formato di questo archivio di fumetti non è ancora leggibile. Convertilo in CBZ.';

  @override
  String get readerComicChapterNoPages =>
      'Questo capitolo non ha pagine immagine.';

  @override
  String get imageReaderSettings => 'Impostazioni di lettura';

  @override
  String get imageReaderDirectionTitle => 'Direzione di lettura';

  @override
  String get imageReaderDirectionVertical => 'Verticale continuo';

  @override
  String get imageReaderDirectionLtr => 'Da sinistra a destra';

  @override
  String get imageReaderDirectionRtl => 'Da destra a sinistra (manga)';

  @override
  String get imageReaderJumpToPage => 'Vai alla pagina';

  @override
  String get imageReaderBackgroundTitle => 'Sfondo pagina';

  @override
  String get imageReaderBackgroundBlack => 'Nero';

  @override
  String get imageReaderBackgroundGray => 'Grigio';

  @override
  String get imageReaderBackgroundWhite => 'Bianco';

  @override
  String get readerPdfLinuxUnsupported =>
      'La lettura dei PDF non è ancora disponibile su Linux.';

  @override
  String get bootstrapImageManagerFailed =>
      'Impossibile inizializzare il gestore immagini';

  @override
  String homeFocusCompleted(int minutes) {
    return 'Sessione di concentrazione di $minutes minuti completata. Ben fatto!';
  }

  @override
  String get homeDailyReadingGoal => 'Obiettivo di lettura giornaliero';

  @override
  String get homeAiAdviceSection => 'Consigli di lettura AI';

  @override
  String get homeTodayGlance => 'Oggi in breve';

  @override
  String get homeViewAll => 'Vedi tutto';

  @override
  String get homeGoalDoneSuggestReview =>
      'L\'obiettivo di oggi è completo — valuta un riepilogo di lettura';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Bastano ancora $minutes minuti per raggiungere l\'obiettivo di oggi';
  }

  @override
  String get homePickBookHint =>
      'Scegli un libro dalla tua libreria per continuare e completa prima 1 sessione di concentrazione.';

  @override
  String homeContinueBookHint(String title) {
    return 'Continua prima \"$title\", poi passa ad altri libri.';
  }

  @override
  String get homeTodayActionAdvice => 'Piano d\'azione di oggi';

  @override
  String homeProgressPercent(int percent) {
    return '$percent% completato';
  }

  @override
  String homeStreakDays(int days) {
    return '$days giorni di fila';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes min questa settimana';
  }

  @override
  String get homePlanLoading => 'Caricamento piano';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Obiettivo: $minutes min/giorno';
  }

  @override
  String get homeAiAdviceForYou => 'Consigli di lettura AI per te';

  @override
  String homeBasedOnBook(String title) {
    return 'Basato su \"$title\"';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Lettura di oggi (min)';

  @override
  String get homeTotalReadingMinutesLabel => 'Lettura totale (min)';

  @override
  String get homeGeneratingPlan =>
      'Generazione del piano di lettura di oggi...';

  @override
  String get homeCompletedLabel => 'Completato';

  @override
  String get homeTodayGoalAchieved => 'Obiettivo di oggi raggiunto';

  @override
  String homeMinutesRemaining(int minutes) {
    return 'Ancora $minutes minuti';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return 'Letti $read / $goal min';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'Circa $sessions sessioni di concentrazione per finire l\'obiettivo di oggi';
  }

  @override
  String get homeStreakLabel => 'Serie';

  @override
  String get homeWeekAchievedLabel => 'Obiettivo settimanale';

  @override
  String get homeFocusLabel => 'Concentrazione';

  @override
  String homeDaysCount(int days) {
    return '$days giorni';
  }

  @override
  String homeTimesCount(int times) {
    return '$times volte';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Countdown concentrazione $time';
  }

  @override
  String get homeGoLibraryRead => 'Leggi dalla libreria';

  @override
  String get homeEndFocus => 'Termina concentrazione';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Concentrazione $minutes min';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Regola obiettivo: $minutes min';
  }

  @override
  String get homeNoRecentReading =>
      'Ancora nessuna lettura recente. Apri un libro dalla tua libreria per iniziare.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Avanzamento $percent%';
  }

  @override
  String get librarySearchHint => 'Cerca per titolo o autore';

  @override
  String libraryFilterAll(int count) {
    return 'Tutti $count';
  }

  @override
  String libraryFilterReading(int count) {
    return 'In lettura $count';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Completati $count';
  }

  @override
  String get libraryFilterTooltip => 'Filtra per stato di lettura';

  @override
  String get libraryNoMatchingBooks => 'Nessun libro corrispondente';

  @override
  String get libraryNoReadingBooks => 'Nessun libro in corso';

  @override
  String get libraryNoFinishedBooks => 'Nessun libro completato';

  @override
  String get libraryNoBooks => 'Ancora nessun libro';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · Continua a leggere';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Pagina $page';
  }

  @override
  String get libraryStartFromBeginning => 'Inizia dall\'inizio';

  @override
  String get libraryBookInfo => 'Info libro';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · $pages pagine';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · $chapters capitoli';
  }

  @override
  String get libraryRenameBook => 'Rinomina';

  @override
  String get libraryRenameBookHint =>
      'Cambia il titolo; anche il file su disco viene rinominato';

  @override
  String get libraryRenameBookSuccess => 'Rinominato';

  @override
  String get libraryRenameBookFailed => 'Impossibile rinominare il libro';

  @override
  String get libraryCustomCover => 'Copertina personalizzata';

  @override
  String get libraryCustomCoverHint =>
      'Scegli un\'immagine da usare come copertina di questo libro';

  @override
  String get libraryCustomCoverSuccess => 'Copertina aggiornata';

  @override
  String get libraryCoverUnsupportedFormat => 'Formato immagine non supportato';

  @override
  String get libraryCoverFileTooLarge =>
      'L\'immagine supera il limite di 20 MB';

  @override
  String get libraryCoverReadFailed =>
      'Impossibile leggere l\'immagine selezionata';

  @override
  String get libraryCoverSaveFailed => 'Impossibile salvare la copertina';

  @override
  String get libraryResetCover => 'Ripristina copertina predefinita';

  @override
  String get libraryResetCoverHint =>
      'Rimuovi la copertina personalizzata e ripristina l\'originale';

  @override
  String get libraryResetCoverSuccess => 'Copertina predefinita ripristinata';

  @override
  String get libraryExportBook => 'Esporta file del libro';

  @override
  String get libraryExportOriginalHint =>
      'Copia il file originale in un\'altra posizione';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Esporta il libro scaricato come file TXT generato';

  @override
  String bookExportSuccess(String location) {
    return 'Esportato in $location';
  }

  @override
  String get bookExportSourceMissing =>
      'Il file del libro è mancante e non può essere esportato';

  @override
  String get bookExportUnsupported =>
      'L\'esportazione dei libri non è ancora supportata su questa piattaforma';

  @override
  String get bookExportFailed => 'Impossibile esportare il libro';

  @override
  String get bookExportInProgress => 'Esportazione del libro…';

  @override
  String get incomingBooksImporting =>
      'Importazione di un libro da un\'altra app…';

  @override
  String get incomingBooksNoBookFile =>
      'Il contenuto condiviso non contiene un file di libro importabile';

  @override
  String get incomingBooksPermissionExpired =>
      'L\'accesso al file è scaduto. Condividi o apri di nuovo il file';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Questo formato di libro non è supportato';

  @override
  String get incomingBooksFileTooLarge =>
      'Il file supera il limite di importazione di 500 MB';

  @override
  String get incomingBooksTooManyFiles =>
      'Sono stati condivisi troppi file di libri in una volta. Aggiungine in gruppi più piccoli';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Alcuni file non sono stati riconosciuti; i libri rimanenti continueranno';

  @override
  String get incomingBooksContentMismatch =>
      'Il formato del file non corrisponde al contenuto';

  @override
  String get incomingBooksImportFailed =>
      'Impossibile importare il libro da un\'altra app';

  @override
  String get libraryDeleteBookHint =>
      'Questo libro verrà eliminato definitivamente';

  @override
  String get libraryBookTitle => 'Titolo';

  @override
  String get libraryFormat => 'Formato';

  @override
  String libraryPagesCount(int pages) {
    return '$pages pagine';
  }

  @override
  String get totalChapters => 'Capitoli totali';

  @override
  String get currentChapter => 'Capitolo attuale';

  @override
  String libraryChaptersCount(int chapters) {
    return '$chapters capitoli';
  }

  @override
  String get libraryClose => 'Chiudi';

  @override
  String get libraryConfirmDeleteTitle => 'Conferma eliminazione';

  @override
  String libraryDeleteBookMessage(String title) {
    return 'Eliminare \"$title\"? Il file verrà rimosso definitivamente dal tuo dispositivo.';
  }

  @override
  String libraryDeletingBook(String title) {
    return 'Eliminazione di \"$title\"...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '\"$title\" eliminato';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Eliminazione non riuscita: $error';
  }

  @override
  String get libraryReadingBadge => 'In lettura';

  @override
  String get libraryDeletingBookFile => 'Eliminazione del file del libro...';

  @override
  String get libraryDeletingCoverImage =>
      'Eliminazione dell\'immagine di copertina...';

  @override
  String get libraryCleaningDatabase => 'Pulizia dei record del database...';

  @override
  String get libraryDeleteComplete => 'Eliminazione completata';

  @override
  String get librarySelectMultiple => 'Selezione multipla';

  @override
  String get librarySelectAll => 'Seleziona tutti';

  @override
  String librarySelectedBooks(int count) {
    return '$count selezionati';
  }

  @override
  String libraryDeleteSelected(int count) {
    return 'Elimina $count';
  }

  @override
  String get libraryBatchDeleteTitle => 'Eliminare i libri selezionati?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Questo elimina definitivamente i $count libri selezionati, le note e i segnalibri correlati e i file locali. Non è possibile annullare.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return 'Eliminazione $done/$total';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return 'Eliminati $count libri';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return 'Eliminati $success; $failed non riusciti';
  }

  @override
  String get readerPrefaceTitle => 'Frontespizio';

  @override
  String get readerModeHorizontalPage => 'Nessuna animazione';

  @override
  String get readerModeVerticalScrollHint =>
      'Scorri verticalmente le pagine pre-impaginate; scorri di lato per cambiare capitolo';

  @override
  String get readerModeWholeBookScrollHint =>
      'I capitoli pre-impaginati formano un\'unica lista verticale posizionabile';

  @override
  String get readerScrollByChapterTitle => 'Scorrimento per capitolo';

  @override
  String get readerScrollByChapterOnHint =>
      'Scorri un capitolo pagina per pagina, poi scorri di lato per cambiare capitolo';

  @override
  String get readerScrollByChapterOffHint =>
      'Tutti i capitoli si collegano pagina per pagina in un\'unica lista verticale posizionabile';

  @override
  String get readerModeHorizontalPageHint =>
      'Tocca il lato sinistro per la pagina precedente, il destro per la successiva';

  @override
  String get readerModeHorizontalSlideHint =>
      'Le pagine seguono il dito in orizzontale e si bloccano al loro posto';

  @override
  String get readerModeCoverSlide => 'Copertina';

  @override
  String get readerModeCoverSlideHint =>
      'La pagina attuale scorre verso sinistra, scoprendo la pagina successiva sotto di essa';

  @override
  String get readerModePageCurl => 'Curva pagina';

  @override
  String get readerModePageCurlHint =>
      'Trascina di lato per curvare la pagina, poi rilascia per girarla o farla tornare';

  @override
  String get readerTextBrightnessLabel => 'Luminosità testo';

  @override
  String get readerDimTextInDarkModeTitle =>
      'Abbassa il testo in modalità scura';

  @override
  String get readerDimTextInDarkModeHint =>
      'Usa il 70% di luminosità in modalità scura';

  @override
  String readerFontSizeValue(int size) {
    return 'Dimensione carattere  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Margine orizzontale  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Margine orizzontale';

  @override
  String get readerTopMarginLabel => 'Margine superiore';

  @override
  String get readerBottomMarginLabel => 'Margine inferiore';

  @override
  String get readerTxtChapterTitlePageTitle =>
      'Titolo del capitolo in una pagina a parte';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Se disattivato, il titolo del capitolo appare sopra il testo';

  @override
  String get readerVerticalMarginLabel => 'Margine verticale';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Margine verticale  $margin';
  }

  @override
  String readerChapterCount(int count) {
    return '$count capitoli';
  }

  @override
  String readerChapterFallback(int number) {
    return 'Capitolo $number';
  }

  @override
  String readerOpenFailed(String error) {
    return 'Apertura non riuscita: $error';
  }

  @override
  String get readerNoContent => 'Questo libro non ha contenuti leggibili';

  @override
  String readerStatusPaged(
    int chapter,
    int chapterCount,
    int page,
    int pageCount,
  ) {
    return 'Capitolo $chapter/$chapterCount · Pagina $page/$pageCount';
  }

  @override
  String readerStatusScroll(int chapter, int chapterCount) {
    return 'Capitolo $chapter/$chapterCount · Scorrimento verticale';
  }

  @override
  String get importPreparing => 'Preparazione importazione...';

  @override
  String importFailedWithError(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String get importLocalFile => 'File locali';

  @override
  String get settingsAiTempHintMinimax =>
      'Temperatura: MiniMax consiglia 0.01 ~ 1.00';

  @override
  String get settingsAiCustomConfigTitle => 'Configurazione AI personalizzata';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Provider attuale: $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'La temperatura MiniMax deve essere compresa tra 0.01 e 1.00';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'La temperatura è fuori intervallo, segui il suggerimento';

  @override
  String get settingsApply => 'Applica';

  @override
  String get settingsAiCustomApplied =>
      'Parametri personalizzati applicati, ricorda di salvare la configurazione';

  @override
  String get settingsAiApiKeyRequired => 'L\'API Key non può essere vuota';

  @override
  String get settingsAiModelRequired => 'Il modello non può essere vuoto';

  @override
  String get settingsAiBaseUrlInvalid =>
      'Il Base URL deve essere un indirizzo http/https valido';

  @override
  String get settingsAiSettingsSaved => 'Impostazioni AI salvate';

  @override
  String settingsSaveFailed(String error) {
    return 'Salvataggio non riuscito: $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle => 'Sfogliamento con tasti del volume';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Usa i tasti del volume nelle modalità di lettura a pagine';

  @override
  String get settingsAutoResumeReadingTitle => 'Riprendi la lettura all\'avvio';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Se esci dall\'app mentre leggi, al prossimo avvio torni dove ti eri fermato';

  @override
  String get settingsShowStatusBarTitle =>
      'Mostra la barra di stato di sistema durante la lettura';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Interfaccia batteria/ora del lettore nascosta';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Uso dell\'interfaccia batteria/ora del lettore';

  @override
  String get readerTopBarStyleTitle => 'Informazioni in alto';

  @override
  String get readerTopBarStyleSystem => 'Barra di stato di sistema';

  @override
  String get readerTopBarStyleSystemHint =>
      'Mostra ora, segnale e batteria di sistema';

  @override
  String get readerTopBarStyleReader => 'Barra informativa del lettore';

  @override
  String get readerTopBarStyleReaderHint =>
      'Mostra ora, titolo del capitolo e batteria';

  @override
  String get readerTopBarStyleFloating => 'Barra info flottante';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Mostra ora e batteria nell\'area della barra di stato senza occupare spazio di lettura';

  @override
  String get readerTopBarStyleHidden => 'Completamente immersivo';

  @override
  String get readerTopBarStyleHiddenHint => 'Non mostra informazioni in alto';

  @override
  String get settingsAiAssistantTitle => 'Assistente di lettura AI';

  @override
  String get settingsSystemSettingsTitle => 'Impostazioni di sistema';

  @override
  String get settingsSectionAppearanceFonts => 'Aspetto e caratteri';

  @override
  String get settingsSectionDataServices => 'Dati e servizi';

  @override
  String get settingsSectionGeneral => 'Generali';

  @override
  String get settingsSectionAdvancedFeatures => 'Funzioni avanzate';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Altri protocolli di sorgente';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Attiva il supporto per protocolli di sorgente aggiuntivi.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Consenti sorgenti su reti private';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Consenti alle sorgenti di accedere a questo dispositivo, alla rete locale e ad altri indirizzi privati. Attivo per impostazione predefinita con Premium; usa solo sorgenti attendibili.';

  @override
  String get additionalSourcesImport => 'Importa altri protocolli di sorgente';

  @override
  String get additionalSourcesImportTitle => 'Importa JSON sorgente';

  @override
  String get additionalSourcesImportNotice =>
      'L\'importazione analizza e deduplica solo in locale; non verifica online ogni sorgente. Le sorgenti con regole eseguibili mantengono lo stato attivo importato e ogni funzionalità viene verificata all\'uso.';

  @override
  String get additionalSourcesChooseFile => 'Aggiungi da file JSON';

  @override
  String get additionalSourcesUrlLabel => 'URL JSON sorgente';

  @override
  String get additionalSourcesLoadUrl => 'Carica URL';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return '$supported disponibili, $partial parzialmente supportate, $unsupported non supportate';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return '$supported regole standard, $partial regole estese, $unsupported regole avanzate, $skipped saltate';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return '$count sorgenti pronte da importare, $skipped saltate';
  }

  @override
  String get additionalSourcesAvailable => 'Disponibile';

  @override
  String get additionalSourcesPartial => 'Parzialmente supportata';

  @override
  String get additionalSourcesUnsupported => 'Non supportata';

  @override
  String get additionalSourcesImportConfirm => 'Importa tutte';

  @override
  String additionalSourcesImported(int count) {
    return 'Importate $count sorgenti';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return 'Importate $count sorgenti; saltate $conflicted il cui id è già registrato da un\'origine diversa';
  }

  @override
  String get settingsSectionAboutSupport => 'Informazioni e supporto';

  @override
  String get settingsKeepScreenOnTitle => 'Mantieni schermo acceso';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Impedisci allo schermo di spegnersi durante la lettura';

  @override
  String get settingsPowerSavingModeTitle => 'Modalità risparmio energia';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Limita l\'app a 60 fps invece di usare un\'alta frequenza di aggiornamento';

  @override
  String get settingsAutoSaveTitle => 'Salvataggio automatico';

  @override
  String get settingsAutoSaveSubtitle =>
      'Salva automaticamente i progressi di lettura';

  @override
  String get settingsHelpPlaceholder =>
      'Qui possono andare le informazioni di aiuto';

  @override
  String get settingsAiConfigured => 'AI configurata';

  @override
  String get settingsAiNotConfigured => 'API Key non ancora configurata';

  @override
  String get settingsAiReadyToUse => 'Pronta all\'uso';

  @override
  String get settingsAiPendingConfig => 'Configurazione in sospeso';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Preset attuale: $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Configurazione attuale: personalizzata · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'I provider e i modelli comuni sono integrati; di solito basta scegliere un preset e inserire un\'API Key.';

  @override
  String get settingsAiProviderLabel => 'Provider';

  @override
  String get settingsAiCustomProvider => 'Personalizzato';

  @override
  String get settingsAiProtocolLabel => 'Protocollo API';

  @override
  String get settingsAiProtocolOpenAi => 'Compatibile OpenAI';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Seleziona un modello predefinito';

  @override
  String get settingsAiPresetLabel => 'Modello predefinito';

  @override
  String get settingsAiCustomButton => 'Personalizzato';

  @override
  String get settingsAiPresetSelectedHint =>
      'Dopo aver scelto un preset, inserisci solo un\'API Key per iniziare a usarlo.';

  @override
  String get settingsAiCustomActiveHint =>
      'Sono in uso parametri personalizzati; puoi tornare a un preset in qualsiasi momento.';

  @override
  String get settingsAiApiKeyHint =>
      'Inseriscila per attivare il preset attuale';

  @override
  String get settingsShow => 'Mostra';

  @override
  String get settingsHide => 'Nascondi';

  @override
  String get settingsAiSaving => 'Salvataggio...';

  @override
  String get settingsAiSaveConfig => 'Salva configurazione AI';

  @override
  String get settingsPageIntro =>
      'Solo le opzioni che plasmano la tua esperienza di lettura.';

  @override
  String get settingsSupportDevelopmentTitle => 'Sostieni lo sviluppo';

  @override
  String get firstHomeSupportNow => 'Sostieni ora';

  @override
  String get firstHomeSupportLater => 'Forse più tardi';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Una lettera dello sviluppatore di Origo X che chiede un sostegno volontario';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Sostieni lo sviluppo';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'Le donazioni sono volontarie e sostengono lo sviluppo continuo.';

  @override
  String get settingsAccountGuestTitle => 'Accedi a Origo X';

  @override
  String get settingsAccountGuestSubtitle =>
      'Sincronizza il tuo profilo e le impostazioni di sicurezza.';

  @override
  String get settingsAccountOpen => 'Centro account';

  @override
  String get settingsAccountVerified => 'Account verificato';

  @override
  String get accountPageTitle => 'Account';

  @override
  String get accountIntroTitle => 'Account';

  @override
  String get accountPageSubtitle =>
      'Accedi per sincronizzare il tuo profilo e le impostazioni dell\'account.';

  @override
  String get accountLoginTab => 'Accesso con email';

  @override
  String get accountRegisterTab => 'Registrati';

  @override
  String get accountCodeTab => 'Codice email';

  @override
  String get accountResetTab => 'Reimposta';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailRequired => 'Inserisci il tuo indirizzo email';

  @override
  String get accountEmailFirstHint =>
      'Inserisci la tua email per continuare. L\'accesso con password è la modalità predefinita.';

  @override
  String get accountContinue => 'Continua';

  @override
  String get accountPasswordLoginTitle => 'Accedi con password';

  @override
  String get accountPasswordLoginHint =>
      'Inserisci la password oppure usa un codice email.';

  @override
  String get accountUseEmailCode => 'Accedi con un codice email';

  @override
  String get accountNoAccount => 'Non hai un account? Registrati';

  @override
  String get accountForgotPassword => 'Password dimenticata';

  @override
  String get accountHaveAccount => 'Già registrato? Torna all\'accesso';

  @override
  String get accountBackToPassword => 'Torna all\'accesso con password';

  @override
  String get accountChangeEmail => 'Cambia';

  @override
  String get accountRegisterHint =>
      'Verifica la tua email, poi crea un account e una password.';

  @override
  String get accountCodeLoginHint =>
      'Invieremo un codice all\'email selezionata.';

  @override
  String get accountResetHint =>
      'Verifica la tua email, poi scegli una nuova password.';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountConfirmPassword => 'Conferma password';

  @override
  String get accountAvatarCropTitle => 'Ritaglia avatar';

  @override
  String get accountAvatarCropHint =>
      'Trascina per riposizionare e pizzica per zoomare finché il soggetto non rientra nel cerchio.';

  @override
  String get accountUsername => 'Nome utente';

  @override
  String get accountDisplayName => 'Nome visualizzato';

  @override
  String get accountVerificationCode => 'Codice di verifica';

  @override
  String get accountSendCode => 'Invia codice';

  @override
  String get accountSignIn => 'Accedi';

  @override
  String get accountCreate => 'Crea account';

  @override
  String get accountResetPassword => 'Reimposta password';

  @override
  String get accountUseApple => 'Accedi con Apple';

  @override
  String get accountUseGithub => 'Accesso con GitHub';

  @override
  String get accountUseGoogle => 'Continua con Google';

  @override
  String get accountUsePasskey => 'Continua con Passkey';

  @override
  String get accountMoreSignInMethods => 'Altri metodi di accesso';

  @override
  String get accountExternalHint =>
      'Si aprirà un browser sicuro. Torna qui dopo l\'approvazione.';

  @override
  String get accountProfileTitle => 'Profilo';

  @override
  String get accountEditProfile => 'Modifica profilo';

  @override
  String get accountSignInMethodsTitle => 'Metodi di accesso';

  @override
  String get accountSaveProfile => 'Salva profilo';

  @override
  String get accountChangeAvatar => 'Cambia avatar';

  @override
  String get accountRemoveAvatar => 'Rimuovi avatar';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountSupportTitle => 'Abbonamento Premium';

  @override
  String get accountSupportFreeSubtitle =>
      'Le funzioni di lettura di base sono gratuite.';

  @override
  String get accountSupportAction => 'Ottieni Premium';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Almeno 12 caratteri';

  @override
  String get accountUsernameHint =>
      '3–30 lettere minuscole, numeri o trattini bassi';

  @override
  String get settingsDonationAction => 'Dona con WeChat';

  @override
  String get settingsAlipayDonationAction => 'Dona con Alipay';

  @override
  String get settingsDonationDialogTitle => 'Donazione WeChat';

  @override
  String get settingsDonationDialogHint =>
      'Scansiona il codice QR con WeChat per sostenere lo sviluppo continuo. Grazie.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Donazione Alipay';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Scansiona il codice QR con Alipay per sostenere lo sviluppo continuo. Grazie.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'Le donazioni sono del tutto facoltative. Non sbloccano funzioni né costituiscono un acquisto o un contratto di servizio.';

  @override
  String get settingsDonationQrCodeLabel => 'Codice QR donazione WeChat';

  @override
  String get settingsAlipayDonationQrCodeLabel => 'Codice QR donazione Alipay';

  @override
  String get settingsAiSwipeHint =>
      'Scorri tra i modelli, tocca per passare a uno, tieni premuto per modificare o eliminare.';

  @override
  String get settingsAiLegacyIntro =>
      'Scegli un provider e un modello, poi inserisci la tua API key.';

  @override
  String get settingsAiModelLabel => 'Modello';

  @override
  String get settingsAiUsingCustomParams =>
      'Uso di impostazioni modello personalizzate';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Salvata solo su questo dispositivo';

  @override
  String get settingsAiSaveAndEnable => 'Salva e attiva';

  @override
  String get settingsAboutTagline =>
      'Multipiattaforma, concentrato sulla lettura';

  @override
  String get settingsVersionLabel => 'Versione';

  @override
  String get changelogHistoryTitle => 'Cronologia versioni';

  @override
  String get changelogHistorySubtitle => 'Consulta le novità di ogni versione';

  @override
  String get openSourceLicensesTitle => 'Licenze open source e dei caratteri';

  @override
  String get openSourceLicensesSubtitle =>
      'Consulta le licenze dell\'app, dei caratteri inclusi e del software di terze parti';

  @override
  String get openSourceLicensesIntro =>
      'Questi testi di licenza e avvisi sono disponibili offline nell\'app. Origo X, i caratteri su richiesta e il software di terze parti restano soggetti alle rispettive licenze.';

  @override
  String get openSourceProjectSection => 'Licenze del progetto';

  @override
  String get openSourceLegacyLicenseTitle => 'Versioni precedenti';

  @override
  String get openSourceFontsSection => 'Licenze dei caratteri';

  @override
  String get openSourceDependenciesSection => 'Software di terze parti';

  @override
  String get openSourceDependenciesTitle => 'Dipendenze Flutter e Dart';

  @override
  String get openSourceDependenciesSubtitle =>
      'Consulta le licenze di terze parti raccolte automaticamente da Flutter';

  @override
  String get openSourceLicenseLegalese =>
      'Origo X e i componenti di terze parti restano soggetti alle rispettive licenze.';

  @override
  String get openSourceLicenseLoadFailed =>
      'Impossibile caricare il testo della licenza.';

  @override
  String get changelogPageTitle => 'Cronologia delle versioni';

  @override
  String get changelogCurrentVersion => 'Versione attuale';

  @override
  String get changelogLoadFailed =>
      'Impossibile caricare la cronologia delle versioni';

  @override
  String get settingsMaintainerLabel => 'Maintainer';

  @override
  String get settingsLicenseLabel => 'Licenza';

  @override
  String get settingsViewSourceSubtitle => 'Visita il progetto open source';

  @override
  String get settingsJoinQqGroup => 'Entra nel gruppo QQ';

  @override
  String get settingsQqOpenFailed =>
      'Impossibile aprire QQ. Verifica che QQ sia installato.';

  @override
  String get settingsDarkModeTitle => 'Modalità notturna';

  @override
  String settingsCurrentValue(String value) {
    return 'Attuale: $value';
  }

  @override
  String get settingsUiStyleTitle => 'Effetto vetro';

  @override
  String get settingsGlassEffectSubtitle =>
      'Usa superfici traslucide, sfocatura dello sfondo e profondità flottante';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Nascondi etichette della barra di navigazione inferiore';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'Mostra solo le icone nella barra di navigazione inferiore mobile';

  @override
  String get settingsFloatingNavigationTitle =>
      'Barra di navigazione flottante';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Regola dimensione, stile di visualizzazione e ordine delle destinazioni';

  @override
  String get floatingNavigationPreviewTitle => 'Anteprima';

  @override
  String get floatingNavigationSizeTitle => 'Dimensione';

  @override
  String get floatingNavigationSizeAutomatic => 'Automatica';

  @override
  String get floatingNavigationSizeCustom => 'Personalizzata';

  @override
  String get floatingNavigationHeightLabel => 'Altezza';

  @override
  String get floatingNavigationSideMarginLabel => 'Margine laterale';

  @override
  String get floatingNavigationDisplayModeTitle => 'Stile di visualizzazione';

  @override
  String get floatingNavigationIconsOnly => 'Solo icone';

  @override
  String get floatingNavigationIconsAndLabels => 'Icone ed etichette';

  @override
  String get floatingNavigationOrderTitle => 'Ordine di navigazione';

  @override
  String get floatingNavigationOrderHint =>
      'Tieni premuta la maniglia a destra per riordinare';

  @override
  String get floatingNavigationSyncHint =>
      'L\'ordine si applica anche alla navigazione a scorrimento e alla barra laterale a schermo largo';

  @override
  String get floatingNavigationResetOrder => 'Ripristina ordine predefinito';

  @override
  String get floatingNavigationResetDone => 'Ordine predefinito ripristinato';

  @override
  String get settingsLibraryLayoutTitle => 'Impostazioni libreria';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Regola il layout della libreria e l\'esperienza di apertura dei libri';

  @override
  String get settingsLibraryLayoutCard => 'Schede';

  @override
  String get settingsLibraryLayoutGrid => 'Griglia';

  @override
  String get settingsLibraryGridColumnsTitle =>
      'Copertine per riga su telefoni';

  @override
  String get settingsLibraryGridTwoColumns => '2 colonne';

  @override
  String get settingsLibraryGridThreeColumns => '3 colonne';

  @override
  String get settingsLibraryGridShowDetailsTitle =>
      'Mostra titolo e avanzamento';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Aggiungi una riga col titolo e una barra compatta di avanzamento sotto ogni copertina';

  @override
  String get settingsLibraryOpenAnimationTitle =>
      'Animazione di apertura del libro';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Usata solo quando apri un libro dalla libreria';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Espansione classica della copertina';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Ingrandisci la copertina originale a tutto schermo prima di mostrare il lettore';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Dissolvenza minimale';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Fai comparire il testo in dissolvenza senza movimenti direzionali';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Risalita della carta';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'La carta di lettura si assesta dolcemente dal basso';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Scorrimento pagina';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'La pagina di lettura entra con un breve movimento laterale';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Ritmo dell\'animazione';

  @override
  String get settingsLibraryOpenAnimationFast => 'Veloce';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Dissolvenza rapida appena il testo è pronto';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Elegante';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Mostra il testo più gradualmente per un passaggio più calmo';

  @override
  String get settingsAccentFollowTheme => 'Colore accento: segui il tema';

  @override
  String settingsAccentValue(String name) {
    return 'Colore accento: $name';
  }

  @override
  String get settingsAppThemeTitle => 'Tema dell\'app';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Attuale: $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'Segui il tema dell\'app';

  @override
  String get settingsAccentColorTitle => 'Colore accento';

  @override
  String get settingsThemeModeSystemHint =>
      'Cambia automaticamente con l\'aspetto del sistema';

  @override
  String get settingsThemeModeLightHint => 'Usa sempre l\'aspetto chiaro';

  @override
  String get settingsThemeModeDarkHint => 'Usa sempre l\'aspetto scuro';

  @override
  String get settingsSelectAppTheme => 'Scegli il tema dell\'app';

  @override
  String get settingsDone => 'Fine';

  @override
  String get settingsAccentColorAdvice =>
      'Il colore accento genera gli schemi colori completi chiaro e scuro di Material 3.';

  @override
  String get settingsAccentPresetColors => 'Colori rapidi';

  @override
  String get settingsAccentCustomColor => 'Colore personalizzato';

  @override
  String get settingsAccentSaturationBrightness =>
      'Campo saturazione e luminosità';

  @override
  String get settingsAccentHue => 'Tonalità';

  @override
  String get settingsAccentPreview => 'Anteprima tavolozza tema';

  @override
  String get settingsAccentFollowThemeOption => 'Segui il tema';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Usa il colore accento predefinito del tema attuale dell\'app';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Maintainer: 小元Niki';

  @override
  String get settingsGithubRepo => 'Repository GitHub';

  @override
  String get settingsNewYearGreeting =>
      'Un lettore multipiattaforma, focalizzato, sobrio e liberamente modificabile.';

  @override
  String get settingsGithubOpenFailed => 'Impossibile aprire il link GitHub';

  @override
  String get settingsOfficialWebsite => 'Sito ufficiale';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Scarica e installa da open.xxread.top';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'Impossibile aprire il sito ufficiale';

  @override
  String get updateCheckNow => 'Cerca aggiornamenti';

  @override
  String get updateCheckNowSubtitle =>
      'Ottieni l\'ultima versione da GitHub o dal sito ufficiale';

  @override
  String get updateAppStoreManaged =>
      'Questa build del Mac App Store si aggiorna tramite l\'App Store';

  @override
  String get updateAvailableTitle => 'È disponibile una nuova versione';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Versione attuale: $currentVersion\nUltima versione: $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Novità';

  @override
  String get updateNotesEmpty =>
      'Nessuna nota di versione fornita per questa versione.';

  @override
  String get updateLater => 'Più tardi';

  @override
  String get updateSkipVersion => 'Salta questa versione';

  @override
  String get updateGoToDownload => 'Vai all\'aggiornamento';

  @override
  String get updateFromGithub => 'Aggiorna da GitHub';

  @override
  String get updateFromWebsite => 'Apri il sito ufficiale';

  @override
  String get updateFromWebsiteInstall => 'Scarica dal sito';

  @override
  String get updateWebsiteUnavailable =>
      'Il pacchetto del sito ufficiale non è ancora disponibile per questo dispositivo';

  @override
  String get updateDownloadingTitle => 'Download dell\'aggiornamento';

  @override
  String updateDownloadProgress(int percent) {
    return 'Scaricato $percent%';
  }

  @override
  String get updatePreparingInstaller =>
      'Verifica del pacchetto e preparazione del programma di installazione…';

  @override
  String get updateDownloadFailed =>
      'Impossibile scaricare l\'aggiornamento dal sito ufficiale';

  @override
  String get updateIntegrityFailed =>
      'L\'aggiornamento scaricato non ha superato il controllo di integrità ed è stato eliminato';

  @override
  String get updateInstallFailed =>
      'Impossibile installare il pacchetto dell\'aggiornamento. Controlla i permessi di installazione e riprova.';

  @override
  String get updateAlreadyLatest => 'Stai già usando l\'ultima versione';

  @override
  String get updateCheckFailed =>
      'Impossibile cercare aggiornamenti. Riprova più tardi.';

  @override
  String get updateOpenFailed => 'Impossibile aprire il link';

  @override
  String get settingsIosOnlyFeature =>
      'Questa funzione è disponibile solo su iOS';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Sincronizzato su $storage\n$books libri, $files file copiati';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Questa modifica delle impostazioni richiede il riavvio dell\'app per avere pieno effetto.';

  @override
  String get settingsRestartRequiredTitle => 'Riavvio richiesto';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\nRiavviare l\'app ora?';
  }

  @override
  String get settingsRestartLater => 'Più tardi';

  @override
  String get settingsRestartNow => 'Riavvia';

  @override
  String get statsDetailedTitle => 'Statistiche dettagliate';

  @override
  String get statsRange7Days => '7 giorni';

  @override
  String get statsRange30Days => '30 giorni';

  @override
  String get statsRange90Days => '90 giorni';

  @override
  String get statsRange1Year => '1 anno';

  @override
  String get statsRangeAll => 'Tutto';

  @override
  String get statsTabOverview => 'Panoramica';

  @override
  String get statsTabCharts => 'Grafici';

  @override
  String get statsTabBooks => 'Libri';

  @override
  String get statsTabAchievements => 'Obiettivi';

  @override
  String get statsReadingOverview => 'Panoramica di lettura';

  @override
  String statsCumulativeHours(Object hours) {
    return 'Totale $hours ore';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Mantieni il ritmo: hai letto $days giorni di fila';
  }

  @override
  String get statsTotalDuration => 'Tempo totale';

  @override
  String get statsAvgSession => 'Sessione media';

  @override
  String statsDaysCount(Object count) {
    return '$count giorni';
  }

  @override
  String get statsNoData => 'Nessun dato';

  @override
  String get statsPeriodEarlyMorning => 'Prima mattina 05:00-08:59';

  @override
  String get statsPeriodMorning => 'Mattina 09:00-11:59';

  @override
  String get statsPeriodAfternoon => 'Pomeriggio 12:00-17:59';

  @override
  String get statsPeriodEvening => 'Sera 18:00-21:59';

  @override
  String get statsPeriodLateNight => 'Notte fonda 22:00-04:59';

  @override
  String get statsTotalReadingTime => 'Tempo di lettura totale';

  @override
  String get statsTotalPagesRead => 'Pagine totali lette';

  @override
  String get statsBooksReadCount => 'Libri letti';

  @override
  String get statsUnitPage => 'pagine';

  @override
  String get statsTodayProgress => 'Avanzamento di lettura di oggi';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target min';
  }

  @override
  String get statsPagesRead => 'Pagine lette';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target pagine';
  }

  @override
  String get statsReadingHabits => 'Abitudini di lettura';

  @override
  String get statsBestReadingPeriod => 'Miglior orario di lettura';

  @override
  String get statsAvgSessionReading => 'Lettura media per sessione';

  @override
  String get statsMaxStreakDays => 'Serie più lunga';

  @override
  String get statsFocusScore => 'Concentrazione di lettura';

  @override
  String get statsBookCount => 'Numero di libri';

  @override
  String get statsTrendAnalysis => 'Analisi dell\'andamento di lettura';

  @override
  String statsAxisMinutes(Object value) {
    return '$value min';
  }

  @override
  String statsAxisPages(Object value) {
    return '$value pag';
  }

  @override
  String statsAxisBooks(Object value) {
    return '$value lib';
  }

  @override
  String statsAxisHour(Object hour) {
    return '${hour}h';
  }

  @override
  String get statsTimeDistribution => 'Distribuzione del tempo di lettura';

  @override
  String get statsFormatDistribution => 'Distribuzione dei formati dei libri';

  @override
  String get statsCompleted => 'Completati';

  @override
  String get statsInProgress => 'In corso';

  @override
  String get statsDurationRanking => 'Classifica per tempo di lettura';

  @override
  String get statsProgressRanking => 'Classifica per avanzamento di lettura';

  @override
  String statsPagesCount(Object count) {
    return '$count pagine';
  }

  @override
  String statsSessionCount(Object count) {
    return '$count sessioni';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return 'Ottenuti $achieved obiettivi, ne restano $remaining da sbloccare';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Prima lettura';

  @override
  String get statsAchievementFirstReadDesc =>
      'Completa la tua prima sessione di lettura';

  @override
  String get statsAchievementNoviceTitle => 'Principiante di lettura';

  @override
  String get statsAchievementNoviceDesc => 'Leggi per un totale di 10 ore';

  @override
  String get statsAchievementBookwormTitle => 'Topo di biblioteca';

  @override
  String get statsAchievementBookwormDesc => 'Leggi per un totale di 100 ore';

  @override
  String get statsAchievementExpertTitle => 'Esperto di lettura';

  @override
  String get statsAchievementExpertDesc => 'Leggi 7 giorni di fila';

  @override
  String get statsAchievementOceanTitle => 'Oceano di conoscenza';

  @override
  String get statsAchievementOceanDesc => 'Leggi 10.000 pagine';

  @override
  String get statsAchievementScholarTitle => 'Erudito';

  @override
  String get statsAchievementScholarDesc => 'Leggi 10 libri diversi';

  @override
  String get statsAchievementMarathonTitle => 'Maratona di lettura';

  @override
  String get statsAchievementMarathonDesc => 'Leggi 30 giorni di fila';

  @override
  String get statsAchievementFocusTitle => 'Maestro della concentrazione';

  @override
  String get statsAchievementFocusDesc => 'Leggi per un totale di 500 ore';

  @override
  String statsProgressPercent(Object percent) {
    return 'Avanzamento: $percent%';
  }

  @override
  String get statsGoalProgress => 'Avanzamento verso l\'obiettivo di lettura';

  @override
  String get statsMonthlyReadingTime => 'Tempo di lettura di questo mese';

  @override
  String get statsWeeklyReadingTime => 'Tempo di lettura di questa settimana';

  @override
  String get statsAvgDailyPages7d =>
      'Media giornaliera pagine (ultimi 7 giorni)';

  @override
  String statsHoursCount(Object count) {
    return '$count ore';
  }

  @override
  String get statsSpeedTrend => 'Andamento della velocità di lettura';

  @override
  String statsAvgSpeed(Object speed) {
    return 'Media: $speed pagine/min';
  }

  @override
  String get statsReadingContinuity => 'Continuità di lettura';

  @override
  String statsCurrentStreak(Object days) {
    return 'Serie attuale: $days giorni';
  }

  @override
  String get statsHeatmapLess => 'Meno';

  @override
  String get statsHeatmapMore => 'Più';

  @override
  String statsWeekNumber(Object week) {
    return 'Settimana $week';
  }

  @override
  String get bookSourceAddToShelf => 'Aggiungi alla libreria';

  @override
  String get bookSourceAddOnline => 'Aggiungi online';

  @override
  String get bookSourceAddOnlineHint =>
      'Leggi dalla sorgente e salva in cache i capitoli man mano';

  @override
  String get bookSourceDownloadLocal => 'Scarica in locale';

  @override
  String get bookSourceDownloadLocalHint =>
      'Scarica tutti i capitoli e aggiungi una copia TXT locale';

  @override
  String get bookSourceAddedOnline =>
      'Aggiunto alla libreria come libro online';

  @override
  String get bookSourceAlreadyOnShelf =>
      'Questo libro è già nella tua libreria';

  @override
  String get bookSourceDownloading => 'Download in locale';

  @override
  String get bookSourceFetchingCatalog => 'Recupero del catalogo dei capitoli…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return '$completed/$total capitoli';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Download completato e aggiunto alla libreria locale';

  @override
  String get bookSourceDownloadConverted =>
      'Download completato. Ora è un libro locale';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get downloadTasksTitle => 'Download';

  @override
  String get downloadTasksEmpty => 'Nessuna attività di download';

  @override
  String get downloadTaskQueued => 'In attesa del download';

  @override
  String get downloadTaskDownloading => 'Download in background';

  @override
  String get downloadTaskCompleted => 'Download completato';

  @override
  String get downloadTaskFailed => 'Download non riuscito';

  @override
  String get downloadTaskCancelled => 'Annullato';

  @override
  String get downloadTaskCancel => 'Annulla attività';

  @override
  String get downloadContinueInBackground => 'Continua in background';

  @override
  String get downloadRunningInBackground =>
      'Il download continua in background';

  @override
  String get bookSourceExitAddTitle => 'Aggiungere alla libreria?';

  @override
  String bookSourceExitAddMessage(String title) {
    return 'Aggiungere “$title” alla libreria come libro online? I tuoi progressi di lettura verranno conservati.';
  }

  @override
  String get bookSourceNotNow => 'Non ora';

  @override
  String get bookSourceOnlineBadge => 'Online';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'I dati del libro online non sono validi: $error';
  }

  @override
  String get readerThemeTitle => 'Tema di lettura';

  @override
  String get readerThemeDescription =>
      'Modifica solo la pagina di lettura e i suoi controlli';

  @override
  String get readerSettingsTabTheme => 'Tema';

  @override
  String get readerSettingsTabText => 'Testo';

  @override
  String get readerSettingsTabLayout => 'Layout';

  @override
  String get readerSettingsTabPaging => 'Paginazione';

  @override
  String get readerSettingsAdvancedTypography => 'Tipografia avanzata';

  @override
  String get readerAutoPageTurnTitle => 'Sfogliamento automatico';

  @override
  String get readerAutoPageTurnOff => 'Non avviato';

  @override
  String get readerAutoPageTurnShortcutTitle =>
      'Scorciatoia di lettura automatica';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Mostra con i controlli di lettura per avviare o mettere in pausa rapidamente';

  @override
  String get readerAutoPageTurnHint =>
      'Avanza di uno schermo all\'intervallo scelto, anche in modalità paginazione verticale.';

  @override
  String get readerAutoPageTurnModeTimed => 'Sfoglio a tempo';

  @override
  String get readerAutoPageTurnModeSweep => 'Sfoglio a scansione';

  @override
  String get readerAutoPageTurnModeContinuous => 'Scorrimento continuo';

  @override
  String get readerAutoPageTurnModeInterval => 'Scorrimento a intervalli';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Attende l\'intervallo scelto, poi passa alla pagina successiva.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Una riga scende verso il basso, rivelando gradualmente la pagina successiva sopra di essa.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Scorre continuamente verso il basso a una velocità di lettura costante.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Attende l\'intervallo scelto, poi scorre in giù di circa uno schermo.';

  @override
  String get readerAutoPageTurnSweepDurationLabel => 'Durata della scansione';

  @override
  String get readerAutoPageTurnScrollSpeedLabel => 'Velocità di scorrimento';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds secondi per schermo';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · ${seconds}s/schermo';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'In pausa · $mode · ${seconds}s/schermo';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Intervallo pagine';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds secondi per schermo';
  }

  @override
  String get readerAutoPageTurnStart => 'Avvia sfogliamento automatico';

  @override
  String get readerAutoPageTurnResume => 'Riprendi sfogliamento automatico';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Auto · ${seconds}s/schermo';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'In pausa · ${seconds}s/schermo';
  }

  @override
  String get readerThemeDay => 'Giorno';

  @override
  String get readerThemeFollowSystem => 'Segui il sistema';

  @override
  String get readerThemeMist => 'Nebbia';

  @override
  String get readerThemeGreen => 'Riposo oculare';

  @override
  String get readerThemeRose => 'Rosa';

  @override
  String get readerThemeNavy => 'Blu profondo';

  @override
  String get readerThemeNight => 'Notte';

  @override
  String get readerThemePureBlack => 'Nero puro';

  @override
  String get readerThemeParchment => 'Pergamena';

  @override
  String get readerThemeCustom => 'Personalizzato';

  @override
  String get readerPullBookmarkTitle => 'Segnalibro a tendina';

  @override
  String get readerPullBookmarkHint =>
      'Trascina verso il basso dal bordo superiore e rilascia per aggiungere o rimuovere un segnalibro per questa pagina';

  @override
  String get readerPullBookmarkAddHint =>
      'Trascina più giù per aggiungere il segnalibro';

  @override
  String get readerPullBookmarkRemoveHint =>
      'Trascina più giù per rimuovere il segnalibro';

  @override
  String get readerPullBookmarkReleaseHint => 'Rilascia per completare';

  @override
  String get readerTapAnimationTitle => 'Animazione al tocco';

  @override
  String get readerTapAnimationHint =>
      'Usa l\'animazione di sfogliamento attuale per i tocchi laterali; disattiva per aggiornare all\'istante';

  @override
  String get readerTabletTwoPageTitle => 'Layout a due pagine su tablet';

  @override
  String get readerTabletTwoPageHint =>
      'Mostra le pagine sinistra e destra affiancate in orizzontale; disattiva per usare sempre una pagina singola';

  @override
  String get readerCustomThemeTitle => 'Tema di lettura personalizzato';

  @override
  String get readerCustomThemeReset => 'Ripristina';

  @override
  String get readerCustomThemeColors => 'Colori del tema';

  @override
  String get readerCustomThemeTextColor => 'Colore del testo';

  @override
  String get readerCustomThemeTextColorHint =>
      'Testo principale, titoli e icone principali';

  @override
  String get readerCustomThemeBackground => 'Sfondo di lettura';

  @override
  String get readerCustomThemeBackgroundHint =>
      'Il colore della carta e dell\'area di lettura';

  @override
  String get readerCustomThemeControlBar => 'Colore della barra di controllo';

  @override
  String get readerCustomThemeControlBarHint =>
      'Controlli superiore e inferiore e superfici delle impostazioni';

  @override
  String get readerCustomThemeContrastGood =>
      'Il testo ha un contrasto chiaro per una lettura prolungata confortevole';

  @override
  String get readerCustomThemeContrastLow =>
      'Il contrasto del testo è basso e può affaticare la lettura';

  @override
  String get readerCustomThemeSave => 'Salva e usa';

  @override
  String get readerCustomThemePreview => 'Anteprima dal vivo';

  @override
  String get readerCustomThemePreviewChapter =>
      'Capitolo uno · Vento tra le pagine';

  @override
  String get readerCustomThemePreviewBody =>
      'Questo è il tuo spazio di lettura. Regola i colori di testo, carta e controlli finché ogni pagina non sembra decisamente tua.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Inserisci un colore esadecimale a 6 cifre, ad esempio #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Colore esadecimale';

  @override
  String get readerCustomThemesTitle => 'Temi di lettura personalizzati';

  @override
  String get readerCustomThemeAdd => 'Aggiungi tema';

  @override
  String get readerCustomThemeReorderHint =>
      'Tieni premuta la maniglia a destra per riordinare i temi. Lo stesso ordine appare nelle impostazioni di lettura.';

  @override
  String get readerCustomThemeUse => 'Usa il tema selezionato';

  @override
  String get readerCustomThemeDeleteTitle => 'Eliminare il tema di lettura?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return '“$name” verrà rimosso dai tuoi temi, insieme alla sua immagine di sfondo salvata.';
  }

  @override
  String get readerCustomThemeEmptyTitle => 'Ancora nessun tema personalizzato';

  @override
  String get readerCustomThemeEmptyHint =>
      'Crea la tua combinazione di carattere, colore della carta e immagine di sfondo.';

  @override
  String get readerCustomThemeNewTitle => 'Nuovo tema di lettura';

  @override
  String get readerCustomThemeEditTitle => 'Modifica tema di lettura';

  @override
  String get readerCustomThemeName => 'Nome del tema';

  @override
  String get readerCustomThemeNameHint =>
      'Ad esempio, Notte di pioggia o Carta del pomeriggio';

  @override
  String get readerCustomThemeBackgroundImage => 'Immagine di sfondo';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Supporta JPG, PNG e WebP. L\'immagine viene copiata nell\'archivio dell\'app.';

  @override
  String get readerCustomThemeChooseImage => 'Carica immagine';

  @override
  String get readerCustomThemeReplaceImage => 'Sostituisci immagine';

  @override
  String get readerCustomThemeRemoveImage => 'Rimuovi immagine';

  @override
  String get readerCustomThemeImageStrength =>
      'Intensità dell\'immagine di sfondo';

  @override
  String get readerCustomThemeImageUnsupported =>
      'L\'importazione di immagini di sfondo non è supportata su questa piattaforma';

  @override
  String get readerCustomThemeImageTooLarge =>
      'L\'immagine non deve superare 20 MB';

  @override
  String get readerCustomThemeImageFormat =>
      'Scegli un\'immagine JPG, PNG o WebP';

  @override
  String get readerCustomThemeImageFailed =>
      'Impossibile importare l\'immagine di sfondo. Riprova.';

  @override
  String get importSourceTitle => 'Aggiungi libri';

  @override
  String get importSourceDescription =>
      'Scegli prima alcuni file. Rivedi la coda prima di avviare l\'importazione.';

  @override
  String get importSelectFiles => 'Scegli file';

  @override
  String get importIosSharedDocuments => 'Sul mio iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'iCloud Drive non è disponibile';

  @override
  String get importAndroidFolder => 'Autorizza una cartella di libri';

  @override
  String get importAndroidRescan => 'Scansiona le cartelle autorizzate';

  @override
  String get importFolderPermissionAvailable =>
      'Autorizzata · tocca per scansionare';

  @override
  String get importFolderPermissionLost =>
      'Permesso perso · autorizza di nuovo per ripristinare l\'accesso';

  @override
  String get importRemoveFolder => 'Rimuovi cartella';

  @override
  String importQueueTitle(int count) {
    return 'Coda di importazione ($count)';
  }

  @override
  String get importQueueHint =>
      'Rimuovi i file scelti per errore, poi importali uno alla volta.';

  @override
  String get importQueueEmptyTitle => 'Nessun libro selezionato';

  @override
  String get importQueueEmptyBody =>
      'Scegli un file EPUB, PDF, TXT, MOBI o un altro formato di libro supportato.';

  @override
  String importAction(int count) {
    return 'Importa $count libri';
  }

  @override
  String importRetryFailed(int count) {
    return 'Riprova $count non riusciti';
  }

  @override
  String get importStatusQueued => 'In attesa';

  @override
  String get importStatusPreparing => 'Preparazione file';

  @override
  String get importStatusChecking => 'Verifica';

  @override
  String get importStatusCopying => 'Copia';

  @override
  String get importStatusAnalyzing => 'Analisi';

  @override
  String get importStatusSaving => 'Salvataggio';

  @override
  String get importStatusImported => 'Importato';

  @override
  String get importStatusSkipped => 'Già presente, saltato';

  @override
  String get importStatusFailed => 'Importazione non riuscita';

  @override
  String get importRemove => 'Rimuovi';

  @override
  String get importRetry => 'Riprova';

  @override
  String get importClearCompleted => 'Cancella completati';

  @override
  String get importDone => 'Fine';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return '$succeeded importati · $skipped saltati · $failed non riusciti';
  }

  @override
  String get importNoSupportedFiles =>
      'Nessun file di libro supportato trovato';

  @override
  String get importScanning => 'Scansione dei file…';

  @override
  String get settingsAiApiKeyConfigured => 'API Key configurata';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Tocca per completare la configurazione';

  @override
  String get settingsAiAddModel => 'Aggiungi modello';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Passato a $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Compila prima Base URL e API Key';

  @override
  String get settingsAiEditModelTitle => 'Configura modello';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Ogni scheda rapida è collegata a un modello';

  @override
  String get settingsAiPresetModel => 'Modello predefinito';

  @override
  String get settingsAiBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'Compatibile OpenAI: il Base URL di solito deve includere /v1 (ad esempio, https://example.com/v1). L\'app aggiunge /chat/completions.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic: il Base URL può includere /v1 oppure ometterlo. L\'app evita di duplicare /v1 e aggiunge /messages.';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiModelNameLabel => 'Nome del modello';

  @override
  String get settingsAiFetchModelsTooltip => 'Recupero automatico modelli';

  @override
  String get settingsAiFetchModelsList =>
      'Recupera automaticamente l\'elenco modelli';

  @override
  String get settingsAiSelectModel => 'Seleziona un modello';

  @override
  String get settingsAiTemperatureLabel => 'Temperatura';

  @override
  String get settingsAiAddAndEnable => 'Aggiungi e attiva';

  @override
  String get settingsAiModelMismatchClaude =>
      'I nomi dei modelli del provider Claude di solito iniziano con \"claude\". Verifica che provider e modello corrispondano.';

  @override
  String get settingsAiModelMismatchGemini =>
      'I nomi dei modelli del provider Gemini di solito contengono \"gemini\". Verifica che provider e modello corrispondano.';

  @override
  String get settingsAiModelMismatchGlm =>
      'I nomi dei modelli del provider GLM di solito iniziano con \"glm\". Verifica che provider e modello corrispondano.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'I nomi dei modelli del provider MiniMax di solito contengono \"MiniMax\". Verifica che provider e modello corrispondano.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Formato della risposta dell\'elenco modelli non riconosciuto';

  @override
  String get settingsAiNoModelsReturned =>
      'Il server non ha restituito un elenco di modelli disponibili';

  @override
  String get settingsAiNoModelsAvailable => 'Nessun modello disponibile';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Recupero dei modelli non riuscito: $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'Pre-elaborazione AI dei libri';

  @override
  String get settingsAiPreprocessSubtitle =>
      'Dopo l\'importazione di un libro, lascia che l\'AI lo legga e costruisca automaticamente una base di conoscenza locale di riepiloghi';

  @override
  String get settingsAiPreprocessWarning =>
      'La pre-elaborazione invia l\'intero libro al modello AI a blocchi. Consuma un gran numero di token e richiede tempo. Attivarla comunque?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Configura prima un modello AI funzionante con una API key';

  @override
  String get libraryAiPreprocess => 'Pre-elaborazione AI';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return 'Lasciare che l\'AI legga \"$title\" e costruisca una base di conoscenza di riepiloghi? Consuma un gran numero di token.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'L\'AI sta leggendo questo libro… (passo $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'Base di conoscenza AI generata';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'Pre-elaborazione AI non riuscita: $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Questo formato di libro non supporta ancora la pre-elaborazione AI';

  @override
  String get libraryAiPreprocessQueued =>
      'Aggiunto alla coda di pre-elaborazione AI. Controlla l\'avanzamento in Attività di download.';

  @override
  String get downloadTasksTabDownloads => 'Download';

  @override
  String get aiPreprocessTaskRunning => 'L\'AI sta leggendo…';

  @override
  String get aiPreprocessTasksEmpty =>
      'Nessuna attività di pre-elaborazione AI';

  @override
  String get aiPreprocessClearFinished => 'Cancella completate';

  @override
  String get aiChatNewChat => 'Nuova chat';

  @override
  String get aiChatSelectBook => 'Collega un libro';

  @override
  String get aiChatNoBook => 'Nessun libro collegato';

  @override
  String get navAi => 'AI';

  @override
  String get aiHistoryTitle => 'Chat AI';

  @override
  String get aiHistoryEmpty =>
      'Ancora nessuna chat AI.\nTocca Chiedi all\'AI durante la lettura per avviare la tua prima conversazione.';

  @override
  String aiHistoryMessageCount(int count) {
    return '$count messaggi';
  }

  @override
  String get aiHistoryClearAll => 'Cancella tutte';

  @override
  String get aiHistoryClearAllConfirm =>
      'Eliminare tutta la cronologia delle chat AI? Non è possibile annullare.';

  @override
  String get aiHistoryDeleteConfirm => 'Eliminare questa chat?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Disattiva un interruttore per nascondere quella pagina; Impostazioni non può essere nascosta.';

  @override
  String get readerAskAi => 'Chiedi all\'AI';

  @override
  String get readerAiInputHint => 'Chiedi qualcosa su questo libro…';

  @override
  String get readerAiSendButton => 'Invia';

  @override
  String get readerAiThinking => 'Sto pensando…';

  @override
  String get readerAiNotConfiguredHint =>
      'Nessun modello AI ancora configurato. Vai in Impostazioni → Assistente di lettura AI per aggiungere un modello e una API key.';

  @override
  String get readerAiEmptyHint =>
      'Chiedi all\'AI della pagina attuale o di qualsiasi cosa in questo libro.';

  @override
  String get readerAiSelectionQuestionLabel => 'Spiega questa selezione';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Spiega il passaggio selezionato qui sotto e fornisci 3 punti chiave.\n\nTesto selezionato:\n$selection\n\nContesto precedente:\n$before\n\nContesto successivo:\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst =>
      'Inserisci una domanda prima di inviare';

  @override
  String get readerAiEmptyResponse =>
      'Il modello ha restituito una risposta vuota, riprova';

  @override
  String readerAiRequestFailed(String error) {
    return 'Richiesta non riuscita: $error';
  }

  @override
  String get readerAiUnknownError => 'Errore sconosciuto';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'La risposta del server è vuota. La causa è di solito un Base URL errato, un gateway che non inoltra all\'endpoint del modello o il server che chiude la connessione in anticipo.\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'La risposta del server non è JSON valido. L\'endpoint attuale potrebbe essere incompatibile con la configurazione $provider.\nURL della richiesta: $endpoint\nFrammento della risposta: $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Richiesta non riuscita$status: impossibile leggere la risposta del server. La causa è di solito un Base URL errato, l\'endpoint che restituisce contenuto vuoto o la rete che tronca la risposta.\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Richiesta di rete non riuscita$status: $error\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Richiesta non riuscita($status): $text\nSuggerimenti: 1) la temperatura MiniMax deve essere in (0,1]; 2) verifica che il nome del modello corrisponda all\'endpoint; 3) usa una sola istruzione di sistema.\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Richiesta non riuscita($status): $text\nSuggerimento: Claude richiede l\'header di richiesta anthropic-version.\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Richiesta non riuscita($status): $text\nSuggerimento: conferma che provider e API Key corrispondano; non possono essere mescolati.\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Richiesta non riuscita($status): $text\nURL della richiesta: $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'AI (simulata): il testo che hai selezionato è \"$selectedText\".\n\nPrima: $before\nDopo: $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'AI (simulata): questa pagina ha $chars caratteri. Concentrati sugli argomenti all\'inizio e alla fine dei paragrafi.';
  }

  @override
  String get readerAiMockGreeting => 'Ciao';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'AI (simulata): hai chiesto \"$question\".\n\nHo letto la pagina attuale ($chars caratteri). Puoi continuare a chiedere.';
  }

  @override
  String get ttsSystemDefault => 'Predefinita di sistema';

  @override
  String get ttsUnavailable => 'TTS di sistema non disponibile';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'Il sistema non supporta la lingua: $language';
  }

  @override
  String get ttsCallFailed => 'Chiamata TTS di sistema non riuscita';

  @override
  String get importErrorSourceMissing => 'Il file sorgente non esiste';

  @override
  String get importErrorHashFailed =>
      'Impossibile verificare il contenuto del file';

  @override
  String get importErrorTargetNameExhausted =>
      'Impossibile allocare un nome disponibile per il file da importare';

  @override
  String get importErrorSourceNotMaterialized =>
      'Il file sorgente non è ancora nella memoria locale';

  @override
  String get importErrorCopyVerificationFailed =>
      'Il file copiato non corrisponde alla sorgente';

  @override
  String get importErrorFileTooLarge =>
      'Il file supera il limite di importazione di 500 MB';

  @override
  String get importErrorSourcePrepareFailed =>
      'Impossibile preparare il file da importare';

  @override
  String get importErrorFailed => 'Importazione del libro non riuscita';

  @override
  String get importUnknownTitle => 'Titolo sconosciuto';

  @override
  String get importUnknownAuthor => 'Autore sconosciuto';

  @override
  String get bookUntitled => 'Senza titolo';

  @override
  String get accentPurple => 'Viola elegante';

  @override
  String get accentPink => 'Rosa ciliegia';

  @override
  String get accentCyan => 'Ciano fresco';

  @override
  String get accentBrown => 'Marrone classico';

  @override
  String get accentGrey => 'Grigio elegante';

  @override
  String get accentDeepPurple => 'Viola avvolgente';

  @override
  String get accentAmber => 'Ambra dorata';

  @override
  String get accentLightGreen => 'Verde vivace';

  @override
  String get accentYellow => 'Giallo sole';

  @override
  String get accentNeutralGrey => 'Grigio minimale';

  @override
  String get accentIndigo => 'Indaco profondo';

  @override
  String get accentDeepOrange => 'Arancione fiamma';

  @override
  String get agreementV2HeroTitle => 'Continua a leggere sul tuo dispositivo.';

  @override
  String get agreementV2HeroBody =>
      'Origo X è un lettore di ebook open source, multipiattaforma e local-first. Fornisce strumenti di lettura; non fornisce, ospita né esamina i libri che importi.';

  @override
  String get agreementV2LocalTitle => 'Prima il locale';

  @override
  String get agreementV2LocalBody =>
      'Libri, progressi e note in generale restano sul tuo dispositivo, da gestire e salvare tu.';

  @override
  String get agreementV2OpenSourceTitle => 'Con licenza AGPL-3.0';

  @override
  String get agreementV2OpenSourceBody =>
      'Il codice sorgente è fornito con la GNU AGPL v3.0 e il software è consegnato “così com\'è”, senza garanzie.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Versione dei termini $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Introduzione';

  @override
  String get agreementFlowStepTerms => 'Termini';

  @override
  String get agreementFlowStepSource => 'Sorgenti di libri';

  @override
  String get agreementFlowStepPrivacy => 'Privacy';

  @override
  String get agreementFlowNext => 'Avanti';

  @override
  String get agreementFlowBack => 'Indietro';

  @override
  String get agreementFlowTermsTitle => 'Usa Origo X con confini chiari';

  @override
  String get agreementFlowTermsSubtitle =>
      'Esamina i termini che regolano l\'uso del software e dei contenuti che scegli di aprire.';

  @override
  String get agreementFlowTermsConsent =>
      'Ho letto e accetto i Termini di utilizzo.';

  @override
  String get agreementFlowSourceTitle =>
      'Contratto sorgenti di libri di terze parti';

  @override
  String get agreementFlowSourceSubtitle =>
      'Conferma come indirizzi delle sorgenti, contenuti, autorizzazioni e responsabilità sono separati dal progetto ufficiale.';

  @override
  String get agreementFlowSourceConsent =>
      'Ho letto e accetto il Contratto sorgenti di libri di terze parti.';

  @override
  String get agreementFlowPrivacyTitle =>
      'I tuoi dati restano sotto il tuo controllo';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Esamina cosa resta in locale, quando avvengono le richieste di rete e come vengono conservati i record dei download.';

  @override
  String get agreementFlowPrivacyConsent =>
      'Ho letto e accetto l\'Informativa sulla privacy.';

  @override
  String get agreementFlowEnterApp => 'Entra in Origo X';

  @override
  String get agreementFlowPrivacyLocalTitle =>
      'Locale per impostazione predefinita';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Libri, progressi, note e impostazioni in genere restano su questo dispositivo.';

  @override
  String get agreementFlowPrivacyNetworkTitle =>
      'L\'uso della rete è esplicito';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'La lettura locale non carica il testo dei libri. I controlli aggiornamenti contattano GitHub e il sito ufficiale; sorgenti, AI e sincronizzazione si connettono solo quando le loro funzioni vengono usate.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Record di download limitati';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'I record di download dal sito ufficiale contenenti un IP grezzo sono conservati al massimo 180 giorni, poi eliminati.';

  @override
  String get agreementV2Title =>
      'Termini di utilizzo e Informativa sulla privacy';

  @override
  String get agreementV2Subtitle => 'Leggi prima di usare Origo X';

  @override
  String get agreementV2ImportantNotice =>
      'Importante: l\'app ufficiale di Origo X non preinstalla, include né consiglia sorgenti di libri di terze parti, e i suoi sviluppatori non gestiscono, rappresentano né ospitano contenuti delle sorgenti. Scegli tu ogni file importato e ogni sorgente che aggiungi; usa solo contenuti che sei autorizzato ad accedere.';

  @override
  String get agreementV2SourceBoundaryTitle =>
      'Confini delle sorgenti di terze parti';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'Il progetto ufficiale fornisce solo il software di lettura open source e l\'Origo Source Protocol. Non fornisce indirizzi di sorgenti né una directory ufficiale delle sorgenti.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Ogni indirizzo di sorgente deve essere inserito e aggiunto da te. L\'app si connette direttamente a quel servizio indipendente, senza instradare i contenuti attraverso un server gestito dagli sviluppatori.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'La compatibilità col protocollo significa solo che un\'interfaccia può connettersi; non prova legalità o licenza. Gli operatori delle sorgenti sono responsabili dei loro contenuti e tu devi esaminarli e usarli in modo legittimo.';

  @override
  String get agreementV2Section1Title => 'Ambito e accettazione';

  @override
  String get agreementV2Section1Body =>
      'Questi termini si applicano al download, all\'installazione e all\'uso di Origo X e delle funzioni incluse. Selezionando “Accetta e continua” confermi di averli letti, compresi e accettati. Se non li accetti, smetti di usare l\'app ed esci. Dove richiesto dalla legge locale deve acconsentire un tutore.';

  @override
  String get agreementV2Section2Title => 'Licenza open source';

  @override
  String get agreementV2Section2Body =>
      'Le future versioni di Origo X sono rilasciate con la GNU Affero General Public License v3.0. Puoi usare, copiare, modificare, distribuire o vendere il software in base a quella licenza. Una versione modificata distribuita deve fornire il suo completo codice sorgente corrispondente in base alla AGPL-3.0, e una versione modificata usata per fornire un servizio di rete deve anche offrire il sorgente corrispondente agli utenti che vi interagiscono. I diritti MIT già concessi per la v1.0.0 e le versioni precedenti restano validi e non sono revocati. Questi termini non limitano i diritti concessi dalla licenza open source. I componenti di terze parti restano soggetti alle proprie licenze.';

  @override
  String get agreementV2Section3Title => 'Contenuti utente e diritti';

  @override
  String get agreementV2Section3Body =>
      'Per “contenuti utente” si intendono libri, documenti, immagini, metadati, link e altro materiale che importi, scarichi, apri, converti, memorizzi in cache, annoti o leggi ad alta voce. Devi avere tutti i diritti e le autorizzazioni necessarie per usarlo. Sei l\'unico responsabile di rivendicazioni o perdite legate a diritti d\'autore, marchi, privacy, diffamazione, contenuti illeciti, malware e altro che coinvolgono i contenuti utente. Il software e i suoi sviluppatori non caricano, vendono, licenziano, avallano né esaminano tali contenuti, e il supporto di un formato non implica il permesso legittimo di usare un file.';

  @override
  String get agreementV2Section4Title => 'Uso vietato';

  @override
  String get agreementV2Section4Body =>
      'Non puoi usare il software per violare la proprietà intellettuale o altri diritti; distribuire contenuti illeciti, dannosi o malevoli; aggirare la gestione dei diritti digitali, i controlli di accesso o i paywall; attaccare o disturbare sistemi di terze parti; né dedicarti ad attività vietate dalla legge applicabile. Sei responsabile di reclami, rivendicazioni, sanzioni e perdite derivanti dalla tua condotta.';

  @override
  String get agreementV2Section5Title => 'Sorgenti di libri e terze parti';

  @override
  String get agreementV2Section5Body =>
      'L\'app ufficiale non preinstalla, distribuisce né consiglia sorgenti di libri e non gestisce una directory ufficiale delle sorgenti. Le sorgenti, le API di rete, i link esterni, i contenuti online, la sintesi vocale di sistema, i servizi AI e le altre integrazioni che aggiungi sono fornite e controllate in modo indipendente da terze parti. Non sono gestite, rappresentate, licenziate, avallate né esaminate dagli sviluppatori. Gli operatori delle sorgenti sono legalmente responsabili dei contenuti che forniscono. Prima di aggiungerne una, devi esaminarne origine, diritti dei contenuti, informativa sulla privacy e termini, e sei responsabile del tuo accesso, download, cache, distribuzione e altro uso. Nella misura massima consentita dalla legge applicabile, gli sviluppatori non sono responsabili per contenuti di terze parti, addebiti, pratiche sui dati, interruzioni o dispute di violazione.';

  @override
  String get agreementV2Section6Title => 'Dati e privacy';

  @override
  String get agreementV2Section6Body =>
      'Origo X è local-first. Libri, progressi di lettura, note e impostazioni sono in genere salvati sul tuo dispositivo. A meno che tu non attivi una sorgente di libri di rete, l\'AI, la sincronizzazione o un\'altra funzione online, l\'app non deve inviare il testo dei libri agli sviluppatori per fornire la lettura locale. I controlli aggiornamenti automatici e manuali contattano GitHub e il sito ufficiale su open.xxread.top con i parametri tecnici necessari come piattaforma, architettura del processore e canale di rilascio; i loro server elaborano il tuo indirizzo IP e lo User-Agent come parte della normale comunicazione di rete. Quando scarichi un programma di installazione dal sito ufficiale, il backend registra versione, architettura, orario di download, indirizzo IP e User-Agent per i conteggi di download, la protezione della sicurezza e la risoluzione dei problemi. I record degli eventi di download contenenti un IP grezzo sono conservati al massimo 180 giorni e poi eliminati; solo le statistiche aggregate senza indirizzi IP grezzi sono conservate più a lungo. Le richieste di aggiornamento non includono testo dei libri, la tua libreria, le note, un account né un identificatore univoco del dispositivo. Le richieste a GitHub sono governate anche dai termini sulla privacy di GitHub. Quando usi un\'altra funzione online, query, testo selezionato, informazioni di rete o parametri necessari possono essere inviati al provider che hai scelto, secondo le politiche di quel provider. Proteggi il tuo dispositivo, le API key e i backup; la disinstallazione, la cancellazione dei dati, un guasto del dispositivo o un errore utente possono cancellare definitivamente i dati.';

  @override
  String get agreementV2Section7Title => 'AI e output automatico';

  @override
  String get agreementV2Section7Body =>
      'Riepiloghi, risposte, traduzioni, raccomandazioni e altri output generati dall\'AI possono essere imprecisi, incompleti, superati o fuorvianti. Sono solo ausili di lettura e non costituiscono consulenza legale, medica, finanziaria, accademica o altro consiglio professionale. Verifica gli output in modo indipendente e non basartene per decisioni ad alto rischio. Il materiale inviato a un provider AI è governato anche dai termini di quel provider.';

  @override
  String get agreementV2Section8Title => 'Esclusione di garanzie';

  @override
  String get agreementV2Section8Body =>
      'Nella misura massima consentita dalla legge, il software e i materiali correlati sono forniti “così com\'è” e “come disponibili”, senza garanzie espresse, implicite o legali, incluse commerciabilità, idoneità a uno scopo particolare, titolarità, non violazione, accuratezza, compatibilità, sicurezza, funzionamento senza errori, disponibilità ininterrotta o conservazione dei dati. I contributori open source non hanno alcun obbligo di mantenere, aggiornare, supportare o correggere il software.';

  @override
  String get agreementV2Section9Title => 'Limitazione di responsabilità';

  @override
  String get agreementV2Section9Body =>
      'Nella misura massima consentita dalla legge, sviluppatori, titolari del copyright e contributori non sono responsabili di perdite dirette, indirette, incidentali, speciali, punitive o consequenziali derivanti da installazione, uso, impossibilità di uso, contenuti utente, servizi di terze parti, perdita di dati, problemi del dispositivo, interruzione di attività o incidenti di sicurezza, sia su base contrattuale, extracontrattuale o secondo altro principio. La responsabilità che non può essere legalmente esclusa resta limitata al minimo consentito dalla legge.';

  @override
  String get agreementV2Section10Title => 'Manleva';

  @override
  String get agreementV2Section10Body =>
      'Nella misura consentita dalla legge applicabile, sei responsabile e manterrai indenni sviluppatori, titolari del copyright e contributori da rivendicazioni, indagini, sanzioni, perdite e costi ragionevoli di terze parti derivanti dai tuoi contenuti utente, da condotte illecite o violatrici, dalla violazione di questi termini o dall\'uso di servizi di terze parti.';

  @override
  String get agreementV2Section11Title => 'Modifiche, cessazione e legge';

  @override
  String get agreementV2Section11Body =>
      'Funzioni, stato di manutenzione e questi termini possono cambiare con l\'evolversi del progetto open source, della legge o dei controlli di rischio. Aggiornamenti sostanziali possono richiedere un nuovo consenso; se non sei d\'accordo, smetti di usare l\'app. Puoi disinstallare in qualsiasi momento. Le dispute dovrebbero prima essere risolte informalmente. Fatte salve le tutele obbligatorie dei consumatori, si applicano la legge del luogo dello sviluppatore e i tribunali con giurisdizione legittima. Se una disposizione è inapplicabile, le altre restano valide.';

  @override
  String get agreementV2ConfirmLabel =>
      'Ho letto e accetto i Termini di utilizzo e l\'Informativa sulla privacy.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Comprendo che il progetto ufficiale non fornisce sorgenti di libri; le sorgenti e i contenuti che aggiungo provengono da terze parti indipendenti, e verificherò l\'autorizzazione restando responsabile del mio uso.';

  @override
  String get agreementV2ExitLabel => 'Rifiuta';

  @override
  String get agreementV2ContinueLabel => 'Accetta e continua';

  @override
  String get agreementV2ExitDialogTitle => 'Rifiutare i termini?';

  @override
  String get agreementV2ExitDialogBody =>
      'Devi accettare i Termini di utilizzo per continuare a usare Origo X. Se non li accetti, esci dall\'app.';

  @override
  String get agreementV2CancelLabel => 'Torna indietro';

  @override
  String get agreementV2ConfirmExitLabel => 'Esci';

  @override
  String get agreementV2SaveFailed =>
      'Impossibile salvare il tuo consenso. Riprova.';

  @override
  String get settingsDataSyncTitle => 'Dati e sincronizzazione';

  @override
  String get settingsCacheManagementTitle => 'Gestione cache';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return 'In uso $size · Vedi dettagli e svuota le cache';
  }

  @override
  String get settingsCacheUsageTitle => 'Uso della cache';

  @override
  String get settingsCacheTotalUsage => 'Totale usato';

  @override
  String get settingsCacheSafeHint =>
      'Vengono mostrate solo le cache rimovibili in sicurezza. Libri, progressi di lettura e impostazioni non sono inclusi.';

  @override
  String get settingsCacheSourceCovers => 'Cache copertine sorgenti';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Copertine delle sorgenti scaricate · $size';
  }

  @override
  String get settingsCacheSourceData => 'Cache capitoli sorgenti';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Cache dei capitoli online rimovibile in sicurezza · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Cache di lettura locale';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Cache di analisi EPUB/TXT/Kindle ricostruibile · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'File temporanei';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'File temporanei e di aggiornamento eliminabili · $size';
  }

  @override
  String get settingsCacheClearAll => 'Svuota tutte le cache sicure';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Svuota solo le categorie sopra · $size';
  }

  @override
  String get settingsCacheCalculating => 'Calcolo…';

  @override
  String get settingsCacheClearConfirm =>
      'Rimuove solo dati temporanei della cache. Libri, copertine salvate, progressi di lettura, database, impostazioni e credenziali vengono conservati.';

  @override
  String get settingsCacheClearAction => 'Svuota';

  @override
  String get settingsCacheCleared => 'Cache svuotata';

  @override
  String get settingsCacheClearFailed => 'Impossibile svuotare la cache';

  @override
  String get settingsWebDavSyncTitle => 'Sincronizzazione WebDAV';

  @override
  String get webDavNotConfigured => 'Non configurata';

  @override
  String get webDavConfigureSubtitle =>
      'Sincronizza i dati di lettura sul tuo spazio WebDAV';

  @override
  String get webDavBetaBadge => 'Beta · Può essere instabile';

  @override
  String get webDavPageTitle => 'Sincronizzazione WebDAV';

  @override
  String get webDavConnected => 'Connesso';

  @override
  String get webDavSyncing => 'Sincronizzazione';

  @override
  String get webDavPartialFailure => 'Alcuni elementi richiedono attenzione';

  @override
  String get webDavSyncFailed => 'Sincronizzazione non riuscita';

  @override
  String webDavPendingChanges(int count) {
    return '$count modifiche in attesa di sincronizzazione';
  }

  @override
  String webDavLastSync(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String get webDavNeverSynced => 'Ancora nessuna sincronizzazione';

  @override
  String get webDavSyncNow => 'Sincronizza ora';

  @override
  String get webDavSetUp => 'Configura WebDAV';

  @override
  String get webDavConnectionTitle => 'Connessione';

  @override
  String get webDavServerUrl => 'Indirizzo WebDAV';

  @override
  String get webDavUsername => 'Nome utente';

  @override
  String get webDavPassword => 'Password dell\'app';

  @override
  String get webDavPasswordHint =>
      'Salvata in modo sicuro solo su questo dispositivo';

  @override
  String get webDavRootPath => 'Cartella remota';

  @override
  String get webDavTestConnection => 'Testa connessione';

  @override
  String get webDavTestingConnection => 'Test della connessione…';

  @override
  String get webDavConnectionSuccess =>
      'Connessione e accesso in scrittura verificati';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Test della connessione non riuscito: $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Salva configurazione';

  @override
  String get webDavAutomaticSync => 'Sincronizzazione automatica';

  @override
  String get webDavAutomaticSyncHint =>
      'Sincronizza dopo l\'avvio o quando l\'app torna in primo piano';

  @override
  String get webDavSyncContent => 'Contenuti sincronizzati';

  @override
  String get webDavScopeBookSources => 'Sorgenti di libri';

  @override
  String get webDavScopeBookSourcesHint =>
      'Sincronizza le sorgenti ORSP pubbliche e i preferiti, più tutti i nomi dei gruppi, i gruppi vuoti e il loro ordine. Credenziali delle sorgenti e configurazioni private restano su questo dispositivo.';

  @override
  String get webDavScopeBooks => 'Libreria e libri online';

  @override
  String get webDavScopeProgress => 'Progressi di lettura';

  @override
  String get webDavScopeBookmarks => 'Segnalibri';

  @override
  String get webDavScopeNotes => 'Note ed evidenziazioni';

  @override
  String get webDavScopeNotesHint =>
      'Include testi citati, note e input penna. I dati WebDAV non sono cifrati end-to-end.';

  @override
  String get webDavScopeReadingSessions => 'Statistiche di lettura';

  @override
  String get webDavScopeReaderSettings => 'Impostazioni lettore';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Sincronizza tipografia, temi, sfogliamento, preferenze di paginazione automatica, zone touch e preferenze del lettore immagini.';

  @override
  String get webDavScopeReplaceRules => 'Regole di sostituzione';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Sincronizza i pattern delle regole e il testo sostitutivo. I dati WebDAV non sono cifrati end-to-end.';

  @override
  String get webDavScopeBookFiles => 'File dei libri';

  @override
  String get webDavBookFilesHint => 'Scegli quali libri caricare o scaricare';

  @override
  String get webDavBookFilesUnavailable =>
      'Il trasferimento dei file dei libri sarà attivato quando la sincronizzazione dei metadati sarà stabile';

  @override
  String get webDavSecurityNotice =>
      'I dati vengono inviati via HTTPS, ma il tuo provider WebDAV può leggere i contenuti remoti non cifrati.';

  @override
  String get webDavConnectionDetails => 'Impostazioni connessione';

  @override
  String get webDavClearConfiguration => 'Cancella configurazione';

  @override
  String get webDavClearConfigurationTitle =>
      'Cancellare la configurazione WebDAV?';

  @override
  String get webDavClearConfigurationMessage =>
      'Rimuove l\'indirizzo WebDAV e le credenziali da questo dispositivo. I dati di lettura locali e i file remoti non verranno eliminati.';

  @override
  String get webDavClearConfigurationConfirm =>
      'Cancella da questo dispositivo';

  @override
  String get webDavActivityTitle => 'Attività di sincronizzazione';

  @override
  String get webDavActivityEmpty =>
      'Ancora nessuna attività di sincronizzazione';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return 'Caricati $uploaded, scaricati $downloaded';
  }

  @override
  String get webDavErrorAuthentication =>
      'Nome utente, password o permesso della cartella non corretti.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'La configurazione WebDAV è incompleta o non valida.';

  @override
  String get webDavErrorInsecureConnection =>
      'La connessione non soddisfa i requisiti di sicurezza.';

  @override
  String get webDavErrorCertificate =>
      'Impossibile verificare il certificato del server.';

  @override
  String get webDavErrorPermission => 'La cartella remota non è scrivibile.';

  @override
  String get webDavErrorNotFound =>
      'Cartella di sincronizzazione remota o file richiesto non trovato.';

  @override
  String get webDavErrorConflict =>
      'I dati remoti sono in conflitto. Prova a sincronizzare di nuovo.';

  @override
  String get webDavErrorStorageFull => 'Lo spazio WebDAV è pieno.';

  @override
  String get webDavErrorRateLimited =>
      'Troppe richieste WebDAV inviate. Riprova più tardi.';

  @override
  String get webDavErrorTimeout => 'Il server non ha risposto in tempo.';

  @override
  String get webDavErrorUnsupported =>
      'La risposta del server è incompatibile con il protocollo di sincronizzazione.';

  @override
  String get webDavErrorServer =>
      'Il server WebDAV non ha potuto completare la richiesta.';

  @override
  String get webDavErrorNetwork =>
      'La rete non è disponibile. Le modifiche restano salvate su questo dispositivo.';

  @override
  String get webDavErrorCorruptData =>
      'Alcuni dati di sincronizzazione remoti sono danneggiati e non sono stati applicati.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'Le impostazioni di lettura locali sono danneggiate. Sincronizzazione interrotta senza eliminare il backup remoto.';

  @override
  String get webDavErrorClockSkew =>
      'L\'orologio di questo dispositivo differisce troppo da quello del server WebDAV.';

  @override
  String get webDavErrorSecureStorage =>
      'Impossibile leggere la password WebDAV dall\'archivio sicuro.';

  @override
  String get webDavErrorUnknown =>
      'WebDAV non ha potuto completare l\'operazione.';

  @override
  String get webDavErrorDetails => 'Dettagli della risposta del server';

  @override
  String get webDavErrorMissingEtagDetail =>
      'Il server non ha restituito un identificatore forte della versione del file (ETag). L\'ETag potrebbe mancare o essere troppo debole, quindi l\'app non può sapere se un altro dispositivo ha modificato il file remoto.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'Il server ha ignorato la condizione che consente la scrittura solo quando la versione del file corrisponde (If-Match). Continuare potrebbe sovrascrivere una modifica più recente di un altro dispositivo.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'Il server ha ignorato la condizione che consente la creazione solo quando il file non esiste (If-None-Match). Continuare potrebbe sovrascrivere un file esistente.';

  @override
  String webDavErrorReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'Stato HTTP: $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Metodo della richiesta: $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Percorso della risorsa: $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Non riuscito durante: $phase';
  }

  @override
  String get webDavPhaseConnecting => 'connessione al server remoto';

  @override
  String get webDavPhaseScanningLocal => 'scansione di questo dispositivo';

  @override
  String get webDavPhaseReadingRemote => 'lettura dei dati remoti';

  @override
  String get webDavPhaseApplyingRemote => 'unione dei dati remoti';

  @override
  String get webDavPhaseUploadingLocal => 'caricamento delle modifiche locali';

  @override
  String get webDavPhaseFinishing => 'finalizzazione della sincronizzazione';

  @override
  String get webDavPhaseUnknown => 'un passaggio sconosciuto';

  @override
  String get webDavBookFilesTitle => 'File dei libri';

  @override
  String get webDavFilesPendingUpload => 'Da caricare';

  @override
  String get webDavFilesAvailableDownload => 'Disponibili';

  @override
  String get webDavFilesSynced => 'Sincronizzati';

  @override
  String get webDavFilesUploadSelected => 'Carica selezionati';

  @override
  String get webDavFilesDownloadSelected => 'Scarica selezionati';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return '$count selezionati · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Solo su questo dispositivo';

  @override
  String get webDavFilesOnlyRemote =>
      'File non scaricato su questo dispositivo';

  @override
  String get webDavFilesUploadPermission =>
      'Consenti caricamento file dei libri';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Sincronizza i libri e le copertine selezionati. I TXT trasferiscono solo i blocchi modificati dopo il primo caricamento; EPUB e PDF mantengono i byte originali. I file completi leggibili vengono esportati separatamente.';

  @override
  String get webDavNewBookPolicyTitle => 'Nuovi file dei libri';

  @override
  String get webDavNewBookPolicyAsk => 'Chiedi ogni volta (consigliato)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Scegli quali libri caricare al termine di un\'importazione';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Carica automaticamente i nuovi libri';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Carica subito dopo l\'importazione e potrebbe usare dati mobili';

  @override
  String get webDavNewBookPolicyManual => 'Scegli sempre manualmente';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Avvia i caricamenti solo dalla pagina File dei libri';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return 'Sincronizzare i $count libri appena importati?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'I dati di lettura si sincronizzano automaticamente. Scegli i file originali dei libri da caricare su WebDAV.';

  @override
  String get webDavNewBooksSkip => 'Non ora';

  @override
  String webDavNewBooksUploading(int count) {
    return 'Caricamento di $count nuovi libri…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Caricamento dei nuovi libri completato: $success riusciti, $failed non riusciti';
  }

  @override
  String get webDavFilesTooLarge =>
      'Questo file supera il limite di dimensione di sincronizzazione per il suo formato';

  @override
  String get webDavFilesEmpty => 'Nessun libro in questa categoria';

  @override
  String get webDavFilesTransferComplete =>
      'Trasferimento dei file dei libri completato';

  @override
  String get readerAddAnnotation => 'Aggiungi annotazione';

  @override
  String get readerAnnotationHint => 'Scrivi cosa pensi di questo passaggio…';

  @override
  String get readerAnnotationSaved => 'Annotazione salvata';

  @override
  String get readerAnnotationDeleted => 'Annotazione eliminata';

  @override
  String get readerAnnotationShelfRequired =>
      'Aggiungi questo libro alla libreria prima di salvare annotazioni';

  @override
  String get readerNoAnnotations => 'Ancora nessuna annotazione';

  @override
  String get readerNoAnnotationsHint =>
      'Seleziona del testo per evidenziarlo o aggiungere un commento. Tocca un commento sottolineato per rileggerlo.';

  @override
  String get replaceRulesTitle => 'Sostituisci e pulisci';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Rimuovi pubblicità, promozioni e altro testo indesiderato durante la lettura';

  @override
  String get replaceRulesImport => 'Importa regole';

  @override
  String get replaceRulesExport => 'Esporta regole';

  @override
  String get replaceRulesSearchHint => 'Cerca nomi, gruppi o pattern';

  @override
  String get replaceRulesUnnamed => 'Regola senza nome';

  @override
  String get replaceRulesDeleteValue => 'Rimuovi';

  @override
  String get replaceRulesCreate => 'Nuova regola';

  @override
  String get replaceRulesEmptyTitle => 'Nessuna regola di sostituzione';

  @override
  String get replaceRulesEmptyBody =>
      'Importa un file JSON di sorgente di lettura o crea una regola con espressione regolare.';

  @override
  String get replaceRulesNoSearchResults => 'Nessuna regola corrispondente';

  @override
  String get replaceRulesCreateTitle => 'Nuova regola di sostituzione';

  @override
  String get replaceRulesEditTitle => 'Modifica regola di sostituzione';

  @override
  String get replaceRulesNameLabel => 'Nome della regola';

  @override
  String get replaceRulesPatternLabel =>
      'Testo o espressione regolare da trovare';

  @override
  String get replaceRulesPatternHelper =>
      'Lascia vuota la sostituzione per rimuovere il testo trovato';

  @override
  String get replaceRulesReplacementLabel => 'Sostituisci con';

  @override
  String get replaceRulesRegexLabel => 'Usa un\'espressione regolare';

  @override
  String get replaceRulesScopeTitleLabel => 'Applica ai titoli dei capitoli';

  @override
  String get replaceRulesScopeContentLabel =>
      'Applica ai contenuti dei capitoli';

  @override
  String get replaceRulesGroupLabel => 'Gruppo (facoltativo)';

  @override
  String get replaceRulesScopeLabel => 'Ambito (facoltativo)';

  @override
  String get replaceRulesScopeHelper =>
      'Separa i titoli dei libri o i nomi delle sorgenti con punti e virgola';

  @override
  String get replaceRulesExcludeScopeLabel => 'Ambito escluso (facoltativo)';

  @override
  String get replaceRulesDeleteConfirmTitle => 'Eliminare questa regola?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'La regola verrà rimossa da questo dispositivo.';

  @override
  String replaceRulesImported(int count) {
    return 'Importate $count regole';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'Impossibile importare le regole: $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'Il file delle regole supera $max';
  }

  @override
  String get replaceRulesExported => 'Regole esportate';

  @override
  String get replaceRulesPatternRequired =>
      'Inserisci il testo o l\'espressione regolare da trovare';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'Il pattern supera $max caratteri';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Espressione regolare non valida: $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Sono supportate al massimo $max regole';
  }

  @override
  String get accountSecurityTitle => 'Sicurezza';

  @override
  String get accountSecurityLoading => 'Caricamento dello stato di sicurezza…';

  @override
  String get accountChangeEmailTitle => 'Cambia email';

  @override
  String get accountChangeEmailEnterTitle => 'Scegli una nuova email';

  @override
  String get accountChangeEmailEnterHint =>
      'Invieremo un codice alla tua email attuale e uno al nuovo indirizzo.';

  @override
  String get accountChangeEmailVerifyTitle =>
      'Verifica entrambi gli indirizzi email';

  @override
  String get accountChangeEmailVerifyHint =>
      'Inserisci i due codici per completare il cambio dell\'email di accesso.';

  @override
  String get accountCurrentEmail => 'Email attuale';

  @override
  String get accountNewEmail => 'Nuova email';

  @override
  String get accountCurrentEmailCode => 'Codice inviato all\'email attuale';

  @override
  String get accountNewEmailCode => 'Codice inviato alla nuova email';

  @override
  String get accountSendBothCodes => 'Invia entrambi i codici';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Il tuo indirizzo attuale è un\'email di inoltro nascosta Apple che non può ricevere codici. Un solo codice verrà inviato al nuovo indirizzo.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Il tuo indirizzo attuale è un\'email di inoltro nascosta Apple, quindi non serve un codice per lui. Inserisci il codice inviato al nuovo indirizzo per completare.';

  @override
  String get accountCurrentPasswordInstead =>
      'Password attuale (invece del codice)';

  @override
  String get accountRelayEmailTitle => 'Stai usando un\'email nascosta Apple';

  @override
  String get accountRelayEmailBody =>
      'Il tuo indirizzo di accesso è un indirizzo di inoltro privato Apple, quindi le email di verifica potrebbero non arrivare. Valuta di passare a un indirizzo email che usi ogni giorno.';

  @override
  String get accountChangeEmailAction => 'Cambia email';

  @override
  String get accountEmailChanged => 'Email cambiata';

  @override
  String get accountChangePasswordTitle => 'Imposta o cambia la password';

  @override
  String get accountPasswordEmailTitle => 'Verifica via email';

  @override
  String get accountPasswordEmailHint =>
      'Invia un codice alla tua email attuale prima di scegliere una nuova password.';

  @override
  String get accountPasswordNewTitle => 'Scegli una nuova password';

  @override
  String get accountPasswordNewHint =>
      'Inserisci il codice email e imposta la password che userai la prossima volta.';

  @override
  String get accountNewPassword => 'Nuova password';

  @override
  String get accountChangePasswordAction => 'Cambia password';

  @override
  String get accountPasswordChanged => 'Password cambiata';

  @override
  String get accountPasswordsMismatch => 'Le password non corrispondono';

  @override
  String get accountMfaTitle => 'Autenticazione a due fattori';

  @override
  String get accountMfaEnabled =>
      'Attiva. All\'accesso è richiesto un codice dell\'autenticatore o un codice di recupero inutilizzato.';

  @override
  String get accountMfaDisabledByDefault =>
      'Disattivata per impostazione predefinita. Attivala per proteggere gli accessi con password e codice email.';

  @override
  String get accountMfaOnTitle => 'L\'autenticazione a due fattori è attiva';

  @override
  String get accountMfaEmailTitle => 'Verifica prima la tua email';

  @override
  String accountMfaEmailHint(String email) {
    return 'Invieremo un codice di configurazione a $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'Inserisci il codice email';

  @override
  String get accountMfaEmailCodeHint =>
      'Dopo la verifica, il codice QR e la chiave segreta dell\'autenticatore si apriranno nella pagina successiva.';

  @override
  String get accountMfaAuthenticatorTitle =>
      'Aggiungi Origo X alla tua app di autenticazione';

  @override
  String get accountMfaAuthenticatorHint =>
      'Scansiona il codice QR o inserisci manualmente la chiave segreta, poi inserisci il codice a sei cifre dell\'app di autenticazione.';

  @override
  String get accountMfaQrCodeLabel =>
      'Codice QR di configurazione dell\'app di autenticazione';

  @override
  String get accountMfaSecretLabel => 'Chiave segreta di configurazione';

  @override
  String get accountMfaSecretCopied => 'Chiave segreta copiata';

  @override
  String get accountMfaRecoveryTitle => 'Salva i tuoi codici di recupero';

  @override
  String get accountMfaChallengeTitle => 'Verifica a due fattori';

  @override
  String get accountMfaChallengeHint =>
      'Inserisci il codice della tua app di autenticazione o un codice di recupero inutilizzato per accedere al tuo account.';

  @override
  String get accountMfaCode => 'Codice dell\'autenticatore';

  @override
  String get accountMfaOrRecoveryCode => 'Codice autenticatore o di recupero';

  @override
  String get accountMfaVerify => 'Verifica e continua';

  @override
  String get accountMfaSendSetupCode => 'Invia codice email di configurazione';

  @override
  String get accountMfaContinueSetup => 'Continua configurazione';

  @override
  String get accountMfaSecretWarning =>
      'Aggiungi questa chiave segreta alla tua app di autenticazione. Viene mostrata solo durante la configurazione.';

  @override
  String get accountMfaOpenAuthenticator => 'Apri app di autenticazione';

  @override
  String get accountMfaConfirm => 'Conferma e attiva';

  @override
  String get accountMfaDisable => 'Disattiva l\'autenticazione a due fattori';

  @override
  String get accountMfaDisabled => 'Autenticazione a due fattori disattivata';

  @override
  String get accountRecoveryCodesWarning =>
      'Salva subito questi codici di recupero. Ogni codice funziona una volta sola e questo elenco non verrà mostrato di nuovo.';

  @override
  String get accountCopyRecoveryCodes => 'Copia codici di recupero';

  @override
  String get accountRecoveryCodesCopied => 'Codici di recupero copiati';

  @override
  String get accountRecoveryCodesSaved => 'Ho salvato questi codici';

  @override
  String get accountPremiumLifetime => 'Premium a vita sbloccato';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'Il Premium è collegato a questo account e si sincronizza sulle piattaforme supportate.';

  @override
  String get accountRedemptionCode => 'Codice Premium a vita';

  @override
  String get accountRedeemPremium => 'Riscatta e sblocca per sempre';

  @override
  String get accountApplePurchase => 'Sblocca per sempre con l\'App Store';

  @override
  String get accountApplePurchaseHint =>
      'Un acquisto una tantum collega permanentemente il Premium a questo account Origo X e lo sincronizza sulle piattaforme supportate.';

  @override
  String get accountAppleProductLoading => 'Caricamento informazioni prodotto…';

  @override
  String get accountAppleProductRetry =>
      'Impossibile caricare le informazioni sul prodotto. Tocca per riprovare.';

  @override
  String get accountAppleRestore => 'Ripristina acquisti';

  @override
  String get accountApplePurchasePending =>
      'L\'acquisto è in attesa di approvazione dall\'App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Acquisto inviato; verifica dell\'accesso Premium in corso';

  @override
  String get accountAppleRestoreSubmitted =>
      'Ripristino dell\'acquisto richiesto';

  @override
  String get accountPremiumUnlocked => 'Premium a vita sbloccato';

  @override
  String get accountPremiumUnlockedReferral =>
      'Riscattato: tu e chi ti ha invitato avete entrambi sbloccato il Premium a vita';

  @override
  String get accountInviteTitle => 'Invita amici';

  @override
  String get accountInviteSubtitle =>
      'Quando un amico associa il tuo codice e riscatta un codice Premium a vita, entrambi sbloccate il Premium per sempre.';

  @override
  String get accountInviteMyCode => 'Il mio codice invito';

  @override
  String get accountInviteCopyCode => 'Copia codice invito';

  @override
  String get accountInviteCopyLink => 'Copia link invito';

  @override
  String get accountInviteShareAction => 'Copia link invito da condividere';

  @override
  String get accountInviteCopied => 'Dettagli invito copiati';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return '$invited invitati · $rewarded riusciti';
  }

  @override
  String get accountInviteStatsInvited => 'Codici associati';

  @override
  String get accountInviteStatsRewarded => 'Premi sbloccati';

  @override
  String accountInviterBound(String name) {
    return 'Invitato da $name';
  }

  @override
  String get accountInviteRewarded => 'Invito completato';

  @override
  String get accountInviteWaiting => 'In attesa del riscatto del codice';

  @override
  String get accountInviteBindLabel => 'Codice invito dell\'amico';

  @override
  String get accountInviteBindHint =>
      'Un account può associarsi una sola volta e non può più cambiarlo';

  @override
  String get accountInviteBindAction => 'Associa codice invito';

  @override
  String get accountInviteBound => 'Codice invito associato';

  @override
  String get accountInviteHowItWorks => 'Come funziona';

  @override
  String get accountInviteStepShareTitle => 'Condividi il link';

  @override
  String get accountInviteStepShareBody =>
      'Invia il link o il codice a un amico. Lui lo apre e crea un account.';

  @override
  String get accountInviteStepBindTitle => 'Associa il codice';

  @override
  String get accountInviteStepBindBody =>
      'Il tuo amico inserisce il tuo codice in Account. Ogni account può associarsi una sola volta.';

  @override
  String get accountInviteStepRedeemTitle => 'Riscatta un codice';

  @override
  String get accountInviteStepRedeemBody =>
      'Quando riscattano un codice Premium a vita, entrambi gli account sbloccano subito il Premium.';

  @override
  String get accountInviteMyBinding => 'La mia relazione di invito';

  @override
  String get accountInviteBindIntro =>
      'Se qualcuno ti ha invitato, associa qui il suo codice per tenere il premio legato al tuo account.';

  @override
  String get accountInviteBindingNotNeeded =>
      'Questo account ha già il Premium, quindi non serve alcun codice invito.';

  @override
  String get readingDataExportAction => 'Esporta dati di lettura';

  @override
  String get readingDataExportSubtitle =>
      'Evidenziazioni, sottolineature e note';

  @override
  String get readingDataExportWholeBook => 'Intero libro';

  @override
  String get readingDataExportWholeBookHint =>
      'Esporta tutte le tue annotazioni in questo libro. Il testo del libro e il file sorgente non sono inclusi.';

  @override
  String get readingDataExportPrivacySummary =>
      'Include i brani evidenziati o sottolineati e le tue note private. Il file del libro, il testo completo, i dati dell\'account e le informazioni sul dispositivo non sono inclusi.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return '$highlights evidenziazioni · $underlines sottolineature · $notes note';
  }

  @override
  String readingDataExportButton(int count) {
    return 'Esporta $count annotazioni';
  }

  @override
  String get readingDataExportPreparing => 'Preparazione Markdown…';

  @override
  String get readingDataExportEmpty =>
      'Questo libro non ha evidenziazioni, sottolineature o note da esportare.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Dati di lettura esportati in $location';
  }

  @override
  String get readingDataExportFailed =>
      'Impossibile esportare i dati di lettura';

  @override
  String get readingDataExportUnsupported =>
      'L\'esportazione dei dati di lettura non è ancora supportata su questa piattaforma';

  @override
  String get readingDataExportReplaceTitle => 'Sostituire il file esistente?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Un file esiste già in $path. La sostituzione non può essere annullata.';
  }

  @override
  String get readingDataExportReplaceAction => 'Sostituisci';

  @override
  String get readingDataExportExportedAt => 'Esportato';

  @override
  String get readingDataExportAuthor => 'Autore';

  @override
  String get readingDataExportContents => 'Contenuti';

  @override
  String get readingDataExportMyNote => 'La mia nota';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Pagina $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Annotazioni senza posizione';

  @override
  String get cloudSyncTitle => 'Sincronizzazione cloud';

  @override
  String get cloudSyncTagline =>
      'Riprendi da dove hai lasciato su un altro dispositivo';

  @override
  String get cloudSyncResumeTitle => 'Continua tra dispositivi';

  @override
  String get cloudSyncAutoResume => 'Riprendi all\'apertura di un libro';

  @override
  String get cloudSyncAutoResumeHint =>
      'Verifica l\'ultima posizione all\'apertura; propone aggiornamenti durante la lettura';

  @override
  String get cloudSyncAutoHint =>
      'Salva i progressi durante la lettura e verifica gli aggiornamenti all\'apertura di un libro';

  @override
  String get cloudSyncMoreContent => 'Altre opzioni di sincronizzazione';

  @override
  String get cloudSyncBooks => 'Libri e testo';

  @override
  String get cloudSyncBooksHint =>
      'Libri partecipanti, aggiornamenti e download del testo';

  @override
  String get cloudSyncActivity => 'Dettagli e problemi di sincronizzazione';

  @override
  String get cloudSyncStorage => 'Connessione archiviazione';

  @override
  String get cloudSyncNoActivity =>
      'Ancora nessuna attività di sincronizzazione';

  @override
  String get cloudSyncProgress => 'Posizione di lettura';

  @override
  String get cloudSyncText => 'File di testo dei libri';

  @override
  String get cloudSyncMetadataComplete =>
      'Dati di lettura selezionati scambiati con WebDAV';

  @override
  String get cloudSyncPaused => 'La sincronizzazione automatica è in pausa';

  @override
  String get cloudSyncLocalOnly => 'Mantieni su questo dispositivo';

  @override
  String get cloudSyncCheckHint =>
      'Una connessione non conferma la ricezione sugli altri dispositivi; controlla ogni elemento qui sotto';

  @override
  String get cloudSyncPendingFiles =>
      'Gli aggiornamenti del testo richiedono attenzione';

  @override
  String get cloudSyncFileIdle =>
      'I file di testo collegati verranno verificati alla prossima sincronizzazione';

  @override
  String get cloudSyncManageBooks => 'Scegli libri e download';

  @override
  String get cloudSyncNoBooks => 'Ancora nessun libro TXT collegato';

  @override
  String get cloudSyncCompare => 'Confronta versioni';

  @override
  String get cloudSyncKeepLocal => 'Usa la versione di questo dispositivo';

  @override
  String get cloudSyncUseRemote => 'Usa la versione nel cloud';

  @override
  String get cloudSyncBothKept =>
      'Entrambe le versioni vengono conservate. La sincronizzazione continua dopo la tua scelta.';

  @override
  String get cloudSyncPreviewLimited =>
      'L\'anteprima mostra la prima differenza. Entrambe le versioni complete vengono conservate.';

  @override
  String get cloudSyncPending => 'In attesa di sincronizzazione';

  @override
  String get cloudSyncConflict => 'Le versioni richiedono revisione';

  @override
  String get cloudSyncCurrent => 'Il testo attuale è sincronizzato su WebDAV';

  @override
  String get cloudSyncFailed =>
      'Sincronizzazione incompleta. Nuovo tentativo disponibile.';

  @override
  String get cloudSyncHistory => 'Cronologia versioni';

  @override
  String get cloudSyncApplyUpdate => 'Applica aggiornamento del testo';

  @override
  String get cloudSyncParticipate => 'Sincronizza il testo di questo libro';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Chiudi il lettore o l\'editor di questo libro prima di applicare l\'aggiornamento del testo';

  @override
  String get cloudSyncTextLocation => 'File cloud attuale';

  @override
  String get cloudSyncTextLocationHint =>
      'Gestisci qui aggiornamenti, pause e conflitti dei libri partecipanti.';

  @override
  String get bookSourcesImportIntro =>
      'Rileva le sorgenti automaticamente. Rivedi prima di importare.';

  @override
  String get bookSourcesImportInputStep => 'Scegli sorgente';

  @override
  String get bookSourcesImportReviewStep => 'Rivedi e importa';

  @override
  String get bookSourcesImportFileHint => 'Seleziona un file JSON di sorgente.';

  @override
  String get bookSourcesImportDownloading => 'Download della sorgente…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Lettura delle regole e controllo duplicati…';

  @override
  String get bookSourcesImportSaving => 'Salvataggio delle sorgenti…';

  @override
  String get bookSourcesImportPicking => 'Apertura selettore file…';

  @override
  String get bookSourcesImportWaitHint =>
      'Elenchi di sorgenti grandi possono richiedere più tempo. Puoi annullare e riprovare.';

  @override
  String get bookSourcesImportSaveHint =>
      'Mantieni questa finestra aperta finché il salvataggio non termina.';

  @override
  String get bookSourcesImportReady => 'Pronte per l\'importazione';

  @override
  String get bookSourcesImportEmpty =>
      'Nessuna sorgente selezionata. Controlla il file o la selezione dei duplicati.';

  @override
  String get bookSourcesImportRetry => 'Riprova';

  @override
  String get bookSourcesImportFailed =>
      'Impossibile leggere le sorgenti. Controlla l\'indirizzo o il file e riprova.';

  @override
  String get bookSourcesImportWebPage =>
      'Questo URL ha restituito un sito web o una pagina di accesso. Copia il link JSON di download o sottoscrizione della sorgente dal sito e importa quello. Puoi accedere dopo aver importato la sorgente.';

  @override
  String get bookSourcesImportSaveFailed =>
      'Impossibile salvare le sorgenti. La tua anteprima è conservata; riprova.';

  @override
  String get bookSourcesImportErrorDetails => 'Dettagli errore';

  @override
  String get bookSourcesImportFileUnreadable =>
      'Impossibile leggere il file selezionato. Scegline di nuovo uno.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count sorgenti',
      one: 'Importa 1 sorgente',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'File JSON';

  @override
  String get bookSourcesImportTimedOut =>
      'La lettura ha richiesto troppo tempo. Controlla la connessione o prova a importare un file JSON scaricato.';

  @override
  String get bookSourcesImportUsageNotice =>
      'Informazioni sull\'uso delle sorgenti';

  @override
  String get bookSourcesMaintenanceScope => 'Ambito';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Attive';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Tutte le sorgenti';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Selezionate';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return '$count sorgenti in questo ambito';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope =>
      'Nessuna sorgente in questo ambito';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Verifica fermata';

  @override
  String get bookSourcesMaintenanceCancellingTitle =>
      'Interruzione delle verifiche';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Completa le verifiche attive e conserva i risultati completati';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Verifica interrotta';

  @override
  String get bookSourcesMaintenanceResume => 'Riprendi le verifiche rimanenti';

  @override
  String get bookSourcesMaintenanceRetry => 'Riprova le verifiche non risolte';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return '$count sorgenti non ancora verificate';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Risultati di integrità';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Tutti i risultati';

  @override
  String get bookSourcesMaintenanceAvailable => 'Disponibile';

  @override
  String get bookSourcesMaintenanceLimited => 'Parziale';

  @override
  String get bookSourcesMaintenanceFailed => 'Verifiche non riuscite';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Scadute';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Non confermate';

  @override
  String get bookSourcesMaintenanceReviewSearch => 'Cerca nome o indirizzo';

  @override
  String get bookSourcesMaintenanceReviewEmpty =>
      'Nessun risultato corrispondente';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return '$count selezionate da disattivare';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Seleziona verifiche non riuscite';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Connessione scaduta; riprova più tardi';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Nessun risultato conclusivo da questa verifica';

  @override
  String get bookSourcesMaintenanceAvailableReason =>
      'Verifiche principali superate';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Ricerca duplicati…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Usata dalla tua libreria · conservata per impostazione predefinita';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return '$count sorgenti selezionate sono usate da libri nella tua libreria. Eliminarle potrebbe impedire a quei libri di aggiornarsi o caricare nuovi capitoli.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Problemi';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return 'Selezionate $count sorgenti';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed => 'Usata dalla tua libreria';

  @override
  String get bookSourcesMaintenancePause => 'Pausa';

  @override
  String get bookSourcesMaintenancePausing => 'Pausa…';

  @override
  String get bookSourcesMaintenancePaused => 'Verifica in pausa';

  @override
  String get bookSourcesMaintenanceCompleted => 'Verifica completata';

  @override
  String get bookSourcesMaintenanceStart => 'Avvia verifica';

  @override
  String get bookSourcesMaintenanceRestart => 'Ricomincia';

  @override
  String get bookSourcesMaintenanceCheckedThisRun =>
      'Verificate in questa esecuzione';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Seleziona e gestisci ora i risultati completati, oppure continua a verificare le sorgenti rimanenti.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'Impossibile salvare le modifiche. Riprova.';

  @override
  String get settingsQqGroup => 'Gruppo QQ';

  @override
  String get settingsOpenSourceTitle => 'Dettagli open source';

  @override
  String get settingsOpenSourceDetails =>
      'Tutte le funzioni tranne quelle avanzate sono open source. Il codice open source è concesso in licenza AGPL-3.0; consulta il repository GitHub per il suo ambito.';

  @override
  String get premiumLifetimeTitle => 'Premium a vita';

  @override
  String get premiumLifetimeCaption =>
      'Acquisto una tantum · Nessun rinnovo automatico';

  @override
  String get premiumBenefitsTitle => 'Incluso con Premium';

  @override
  String get premiumProtocolsBenefit =>
      'Importa e usa protocolli di sorgente compatibili aggiuntivi.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Accedi a sorgenti attendibili sul tuo dispositivo, rete locale o rete privata.';

  @override
  String get premiumSourceNotice =>
      'Il Premium non include libri né indirizzi di sorgente. I servizi di terze parti possono richiedere pagamenti a parte.';

  @override
  String get premiumSetupHint =>
      'Attive per impostazione predefinita dopo lo sblocco. Puoi disattivarle in Impostazioni → Funzioni avanzate.';

  @override
  String get premiumBillingTitle => 'Dettagli dell\'acquisto';

  @override
  String get premiumBillingBody =>
      'È un acquisto una tantum non consumabile, non un abbonamento. Non si rinnova automaticamente. L\'App Store mostra il prezzo effettivo e Apple gestisce il pagamento.';

  @override
  String get premiumRestoreHelp =>
      'Dopo una reinstallazione o un cambio dispositivo, ripristina usando l\'Apple Account usato per l\'acquisto e l\'account Origo X collegato. Il ripristino non comporta un nuovo addebito.';

  @override
  String get premiumMembershipTerms => 'Termini di adesione';

  @override
  String get premiumPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get premiumAppleEula => 'EULA standard Apple';

  @override
  String get premiumPurchaseConsent =>
      'Prima di acquistare, leggi i termini di adesione, l\'informativa sulla privacy e l\'EULA standard Apple.';

  @override
  String get premiumAccountBindingTitle => 'Account e accesso';

  @override
  String get premiumAccountBindingBody =>
      'Dopo la verifica, il Premium è collegato all\'account Origo X attuale e si sincronizza sulle piattaforme supportate. Le impostazioni avanzate diventano disponibili con l\'adesione. Uscendo dall\'account o in caso di revoca le funzioni avanzate vengono disattivate. Controlla il tuo account prima di acquistare.';

  @override
  String get premiumRefundTitle => 'Richiedi un rimborso';

  @override
  String get premiumRefundTerms =>
      'Apple esamina ed elabora le richieste di rimborso dell\'App Store secondo le proprie regole applicabili. Inviare una richiesta non significa che sia approvata. Gli acquisti rimborsati o revocati non forniscono più il corrispondente accesso Premium.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Dati di verifica dell\'acquisto';

  @override
  String get premiumPrivacyPurchaseBody =>
      'Apple gestisce le informazioni di pagamento. L\'app invia l\'identificatore del prodotto e i dati di verifica della transazione firmati da Apple al servizio account Origo X per verificare gli acquisti e collegare o ripristinare il Premium. Questo flusso d\'acquisto non fornisce allo sviluppatore il numero completo della tua carta o la password dell\'Apple Account.';

  @override
  String get premiumPrivacyAccountTitle => 'Servizio account';

  @override
  String get premiumPrivacyAccountBody =>
      'Il servizio account Origo X elabora i dati dell\'account e i registri di adesione per accesso, verifica di sicurezza e accesso tra dispositivi. Contattaci per supporto o privacy usando le opzioni di contatto sul sito ufficiale.';

  @override
  String get premiumPurchaseSuccess => 'Premium sbloccato';

  @override
  String get premiumTestPurchaseVerified =>
      'Acquisto di test verificato. Il Premium formale non è stato attivato.';

  @override
  String get premiumPurchaseRevoked =>
      'L\'accesso Premium di questo acquisto è stato revocato.';

  @override
  String get premiumRestoreSuccess =>
      'Acquisto ripristinato. Il Premium è sincronizzato.';

  @override
  String get premiumRestoreEmpty =>
      'Nessun acquisto ripristinabile trovato. Controlla il tuo Apple Account e l\'account Origo X collegato all\'acquisto.';

  @override
  String get premiumPurchaseCanceled => 'Acquisto annullato';

  @override
  String get premiumPendingApproval =>
      'In attesa dell\'approvazione di Apple. L\'accesso si sblocca dopo approvazione e verifica.';

  @override
  String get premiumVerifying => 'Verifica dell\'acquisto in corso…';

  @override
  String get premiumRestoring => 'Ripristino degli acquisti…';

  @override
  String get premiumRefundSubmitted =>
      'Richiesta di rimborso inviata ad Apple per la revisione.';

  @override
  String get premiumRefundNotFound =>
      'Nessun acquisto Premium rimborsabile trovato per questo Apple Account. Puoi anche controllare lo storico con l\'assistenza acquisti Apple.';

  @override
  String get premiumApplePurchaseSupport => 'Assistenza acquisti Apple';

  @override
  String get premiumLinkFailed =>
      'Impossibile aprire questo link. Riprova più tardi.';

  @override
  String get premiumSignInRequired =>
      'Accedi a Origo X prima di acquistare o ripristinare il Premium.';

  @override
  String get premiumRefundUnavailable =>
      'La finestra di rimborso Apple non è disponibile. Prosegui con l\'assistenza acquisti Apple.';

  @override
  String get premiumOperationFailed =>
      'Impossibile completare l\'operazione. Riprova.';

  @override
  String get premiumPurchaseConsentOther =>
      'Leggi i termini di adesione e l\'informativa sulla privacy prima di sbloccare il Premium.';

  @override
  String get premiumBillingBodyOther =>
      'Sblocca il Premium tramite le opzioni di acquisto o riscatto disponibili. Il canale di acquisto mostra prezzo e metodo di pagamento. L\'adesione verificata è collegata al tuo account Origo X attuale.';

  @override
  String get accountDeleteTitle => 'Elimina account';

  @override
  String get accountDeleteEntrySubtitle =>
      'Cancella definitivamente questo account e tutti i suoi dati';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Passo $current di $total';
  }

  @override
  String get accountDeleteReviewTitle => 'Cosa fa l\'eliminazione';

  @override
  String get accountDeleteReviewBody =>
      'Leggi ogni punto. Una volta confermato, tutto ciò che segue viene eliminato immediatamente e non possiamo recuperarlo per te.';

  @override
  String get accountDeleteCurrentAccount => 'Account attuale';

  @override
  String get accountDeleteJoined => 'Iscritto';

  @override
  String get accountDeletePremiumActive => 'Premium sbloccato (verrà rimosso)';

  @override
  String get accountDeletePremiumNone => 'Premium non sbloccato';

  @override
  String get accountDeleteHasTitle => 'Questo account attualmente ha';

  @override
  String accountDeleteHasSessions(int count) {
    return '$count dispositivi con accesso';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return '$count passkey';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return '$count provider di accesso collegati';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return '$count membri entrati con il tuo codice invito';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return '$count codici riscattati';
  }

  @override
  String get accountDeleteTermsTitle => 'Termini di eliminazione';

  @override
  String get accountDeleteTermsIrreversible =>
      'L\'eliminazione dell\'account è definitiva e non può essere annullata. Una volta confermato, nessuno — assistenza inclusa — può in alcun modo ripristinare i dati eliminati.';

  @override
  String get accountDeleteTermsIdentity =>
      'Viene eliminato l\'account stesso: indirizzo email, nome utente, nome visualizzato e avatar.';

  @override
  String get accountDeleteTermsLogins =>
      'Ogni metodo di accesso viene eliminato: password, passkey e collegamenti Google, GitHub e Apple.';

  @override
  String get accountDeleteTermsSessions =>
      'Veni disconnesso ovunque immediatamente, su telefoni, tablet e computer.';

  @override
  String get accountDeleteTermsMfa =>
      'La configurazione a due fattori e tutti i codici di recupero vengono eliminati.';

  @override
  String get accountDeleteTermsPremium =>
      'L\'accesso Premium viene rimosso, qualunque sia il modo in cui l\'hai sbloccato: un codice di riscatto, un premio invito o un acquisto Apple.';

  @override
  String get accountDeleteTermsReferrals =>
      'Il tuo codice invito smette di funzionare e i registri di referral tra te e le persone che hai invitato vengono eliminati. I premi già assegnati ad altri non vengono revocati.';

  @override
  String get accountDeleteTermsRedemptions =>
      'I codici di riscatto già usati non vengono rimborsati e non tornano disponibili.';

  @override
  String get accountDeleteTermsApple =>
      'Hai acquistato il Premium a vita sull\'App Store. Eliminare l\'account non lo rimborsa e non annulla alcuna transazione dell\'App Store: i rimborsi possono essere richiesti solo ad Apple. La ricevuta d\'acquisto viene scollegata da questo account e conservata, così potrai poi toccare Ripristina acquisti su un nuovo account con lo stesso Apple ID e riottenere il Premium.';

  @override
  String get accountDeleteTermsLocalData =>
      'Libri, scaffali e progressi di lettura su questo dispositivo non vengono eliminati: sono sempre esistiti solo sul tuo dispositivo. Rimuovili dall\'app se vuoi eliminare anche quelli.';

  @override
  String get accountDeleteTermsTombstone =>
      'Conserviamo solo i minimi dati di eliminazione deidentificati necessari a prevenire abusi, insieme ai record di verifica degli acquisti dall\'App Store richiesti per ripristinare o verificare gli acquisti. Questi record non vengono usati per ricreare il tuo account.';

  @override
  String get accountDeleteTermsRejoin =>
      'Dopo l\'eliminazione lo stesso indirizzo email può registrarsi di nuovo, ma sarà un account nuovo di zecca e vuoto, senza alcun dato o accesso precedente.';

  @override
  String get accountDeleteBlockedTitle =>
      'Questo account non può ancora essere eliminato';

  @override
  String get accountDeleteBlockedOwner =>
      'Sei il proprietario della console di amministrazione. Passa prima la proprietà a qualcun altro, poi torna — altrimenti non resterebbe nessuno ad amministrarla.';

  @override
  String get accountDeleteConsent =>
      'Ho letto i termini per intero, capisco che l\'eliminazione non può essere annullata e accetto di eliminare definitivamente il mio account e tutti i suoi dati.';

  @override
  String get accountDeleteConsentRequired =>
      'Accetta prima i termini di eliminazione.';

  @override
  String get accountDeleteContinue => 'Ho capito, continua';

  @override
  String get accountDeleteVerifyTitle => 'Verifica la tua email';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Invieremo un codice a 6 cifre a $email per confermare che questa richiesta arriva davvero da te.';
  }

  @override
  String get accountDeleteSendCode => 'Invia codice di eliminazione';

  @override
  String get accountDeleteResendCode => 'Invia di nuovo';

  @override
  String get accountDeleteCodeSent =>
      'Codice inviato. Completa l\'eliminazione entro 10 minuti.';

  @override
  String get accountDeleteConfirmTitle => 'Passo finale';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Digita l\'email del tuo account $email così non ci sono dubbi su quale account viene eliminato.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'Nell\'attimo in cui premi il pulsante qui sotto, l\'account viene eliminato definitivamente.';

  @override
  String get accountDeleteConfirmField =>
      'Digita l\'email del tuo account per confermare';

  @override
  String get accountDeleteMfaHint =>
      'Questo account ha l\'autenticazione a due fattori attiva, quindi è richiesto un codice in più.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Quell\'email non corrisponde all\'account attuale.';

  @override
  String get accountDeleteAction => 'Elimina definitivamente il mio account';

  @override
  String get accountDeleteDoneTitle => 'Il tuo account è stato eliminato';

  @override
  String get accountDeleteDoneBody =>
      'Il tuo account e i suoi dati sono spariti per sempre e ogni dispositivo è stato disconnesso. Grazie di aver usato Origo X.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Dopo aver chiuso questa finestra, apri Impostazioni Apple Account > Accesso e sicurezza > Accedi con Apple > Origo X, poi scegli Interrompi l\'uso di Accedi con Apple.';

  @override
  String get accountDeleteDoneClose => 'Chiudi';

  @override
  String get bookSourceDetailsTitle => 'Dettagli libro';

  @override
  String get bookSourceDetailsDescription => 'Info su questo libro';

  @override
  String get bookSourceDetailsNoDescription =>
      'Nessuna descrizione fornita da questa sorgente.';

  @override
  String get bookSourceDetailsLatestChapter => 'Ultimo capitolo';

  @override
  String get bookSourceDetailsLoadFailed =>
      'Impossibile caricare i dettagli completi. Puoi riprovare o leggere con le informazioni disponibili.';

  @override
  String get bookSourceDetailsOnShelf => 'In libreria';

  @override
  String get bookSourceDetailsAddFailed =>
      'Impossibile aggiungere questo libro alla tua libreria. Riprova.';

  @override
  String get bookSourceDetailsReadFailed =>
      'Impossibile aprire questo libro. Riprova.';

  @override
  String get appTextSize => 'Dimensione testo interfaccia';

  @override
  String get appTextSizeDescription =>
      'Modifica solo menu e controlli dell\'app, non il testo di lettura.';

  @override
  String get appTextSizePreview =>
      'Menu e impostazioni useranno questa dimensione del testo.';

  @override
  String get appTextSizeDefault => '100% (predefinita)';

  @override
  String get bookSourceTrackUpdatesTitle => 'Aggiornamenti e testo scaricato';

  @override
  String get bookSourceTrackUpdatesBody =>
      'I libri scaricati mantengono la loro sorgente. Cerca nuovi capitoli per aggiungere nuovo contenuto, oppure aggiorna i capitoli scaricati conservando le tue modifiche e lo storico.';

  @override
  String get bookSourceCheckNewChapters => 'Cerca nuovi capitoli';

  @override
  String get bookSourceRefreshDownloaded => 'Aggiorna i capitoli scaricati';

  @override
  String get bookSourceNoNewChapters =>
      'Nessun nuovo capitolo nel catalogo. Aggiorna i capitoli scaricati per verificare modifiche al testo precedente.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return '$added capitoli aggiunti, $refreshed aggiornati';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Conferma l\'ultimo capitolo già scaricato prima di continuare gli aggiornamenti. Il tuo testo esistente verrà conservato.';

  @override
  String get bookSourceSelectBoundary => 'Conferma i capitoli scaricati';

  @override
  String get bookSourceBoundaryHelp =>
      'Seleziona l\'ultimo capitolo della sorgente incluso nel tuo testo locale. Solo i capitoli successivi verranno aggiunti; il testo esistente resta intatto.';

  @override
  String get bookSourceTrackingEstablished =>
      'Limite di tracciamento salvato. Ora puoi cercare nuovi capitoli.';

  @override
  String get bookSourceMappingChanged =>
      'La sorgente ha cambiato l\'ordine o gli identificatori dei capitoli. Conferma di nuovo i capitoli scaricati. Il testo esistente è stato conservato.';

  @override
  String get bookSourceContentConflicts =>
      'Le modifiche al testo richiedono revisione';

  @override
  String get bookSourceContentConflictBody =>
      'Tu e la sorgente avete modificato questi capitoli. La tua versione resta attiva. Confronta e scegli cosa leggere; entrambe le versioni restano nello storico.';

  @override
  String get bookSourceCompareVersions => 'Confronta testo';

  @override
  String get bookSourceLocalVersion => 'Il mio testo';

  @override
  String get bookSourceRemoteVersion => 'Testo della sorgente';

  @override
  String get bookSourceBaselineVersion => 'Base scaricata';

  @override
  String get bookSourceKeepLocal => 'Mantieni il mio testo';

  @override
  String get bookSourceUseRemote => 'Usa il testo della sorgente';

  @override
  String get bookSourceUpdateFailed =>
      'L\'aggiornamento non è terminato. Il tuo testo è stato conservato. Riprova.';

  @override
  String get cloudSyncReadableStorage =>
      'I libri modificati vengono caricati come file completi. I libri non modificati non vengono trasferiti di nuovo. I progressi di lettura si sincronizzano separatamente.';

  @override
  String get bookSourceBindSource => 'Collega una sorgente di libri';

  @override
  String get bookSourceNotBound => 'Nessuna sorgente collegata';

  @override
  String get bookSourceDownloadedUnchanged =>
      'I capitoli scaricati sono aggiornati.';

  @override
  String get premiumSyncFailed =>
      'Impossibile sincronizzare lo stato dell\'adesione. Riproverà automaticamente; un errore di connessione non revoca l\'accesso verificato.';

  @override
  String get premiumGrantedAccess =>
      'Hai accesso Premium omaggio. Non serve un acquisto aggiuntivo.';

  @override
  String get premiumOtherChannelAccess =>
      'Hai il Premium tramite un altro canale. Non serve un acquisto aggiuntivo.';

  @override
  String get premiumAppleAccess =>
      'Hai il Premium tramite l\'App Store. Non serve un acquisto aggiuntivo.';

  @override
  String get premiumExistingAccess =>
      'Hai già il Premium. Non serve un acquisto aggiuntivo.';

  @override
  String get premiumSyncPending =>
      'Sincronizzazione dello stato dell\'adesione';

  @override
  String get cloudSyncExportBook => 'Esporta file completo nel cloud';

  @override
  String get cloudSyncExportDone => 'File completo esportato';

  @override
  String get cloudSyncDiagnostics => 'Copia diagnostica sincronizzazione';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Questa cartella appartiene a un formato di sincronizzazione precedente. Scegli una nuova cartella vuota. I tuoi libri locali e i file cloud esistenti verranno conservati.';

  @override
  String get cloudSyncSettings => 'Impostazioni sincronizzazione';

  @override
  String get cloudSyncSettingsHint =>
      'Sincronizzazione automatica, altri dati e connessione';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Sincronizza le posizioni di lettura senza caricare i file dei libri';

  @override
  String get cloudSyncProgressExplanation =>
      'Se entrambi i dispositivi hanno lo stesso libro, puoi sincronizzare solo i progressi di lettura. Il nuovo telefono ha comunque bisogno di una copia leggibile; i registri dei progressi non contengono il testo del libro.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Carica o scarica libri; le modifiche caricano l\'intero file';

  @override
  String get cloudSyncOtherDataHint =>
      'Libreria, sorgenti, segnalibri, note e impostazioni di lettura';

  @override
  String get cloudSyncActivityHint =>
      'Progressi, stato dei file e dettagli degli errori';

  @override
  String get cloudSyncNeedsAttention =>
      'Un problema di sincronizzazione richiede attenzione';

  @override
  String get cloudSyncFileStatus => 'Aggiornamenti e conflitti';

  @override
  String get cloudSyncTransferGuide => 'Passa a un nuovo telefono';

  @override
  String get cloudSyncTransferGuideHint =>
      'Ripristina libri e progressi di lettura su un nuovo telefono';

  @override
  String get cloudSyncTransferIntro =>
      'Caricare un libro è facoltativo per la sincronizzazione dei progressi. Ti serve una copia nel cloud solo se il nuovo telefono non ha già il libro e vuoi scaricarla da qui.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Sincronizza i progressi sul telefono vecchio';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Esci dal lettore per salvare l\'ultima posizione, attiva Progressi di lettura e tocca Sincronizza ora. Usa la stessa connessione WebDAV e la stessa cartella di sincronizzazione su entrambi i telefoni.';

  @override
  String get cloudSyncTransferHasBook => '2. Il nuovo telefono ha già il libro';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Importa lo stesso file locale, oppure apri lo stesso libro online dalla stessa sorgente. Sincronizza i progressi, poi apri il libro per continuare. Solo titoli uguali non garantiscono una corrispondenza.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. Il nuovo telefono ha bisogno del file del libro';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'Sul telefono vecchio, apri File dei libri, consenti i caricamenti e seleziona il libro. Dopo il caricamento, sincronizza il nuovo telefono e scaricalo da Disponibili per il download. Puoi anche trasferire tu lo stesso file.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Se hai modificato il testo sul telefono vecchio, carica quella versione tramite File dei libri e scaricala sul nuovo telefono per preservarne l\'identità del libro. Le posizioni di lettura potrebbero non corrispondere tra versioni del testo diverse.';

  @override
  String get cloudSyncFrequency => 'Frequenza sincronizzazione automatica';

  @override
  String get cloudSyncFrequencyOff => 'Disattivata (solo manuale)';

  @override
  String get cloudSyncFrequencyOnChange => 'Dopo le modifiche';

  @override
  String get cloudSyncFrequency15Minutes => 'Ogni 15 minuti';

  @override
  String get cloudSyncFrequencyHourly => 'Ogni ora';

  @override
  String get cloudSyncFrequencyDaily => 'Una volta al giorno';

  @override
  String get cloudSyncFrequencyHint =>
      'Gli intervalli partono dopo una sincronizzazione automatica riuscita. Se l\'app non è in esecuzione, recupera al prossimo avvio. I tentativi falliti vengono ripetuti. Sincronizza ora funziona sempre immediatamente.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Sincronizzazione automatica: $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'I progressi vengono recuperati alla frequenza scelta. L\'apertura di un libro riprende dall\'ultima posizione sincronizzata. Tocca prima Sincronizza ora quando ti serve l\'ultimo progresso.';

  @override
  String get readerChapterProgressTitle => 'Avanzamento capitolo';

  @override
  String get readerChapterProgressHidden => 'Nascosto';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return '$chapter/$total capitoli';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return '$count capitoli rimanenti';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'La prova Premium scade il $date.';
  }

  @override
  String get premiumTrialTitle => 'Prova Premium';

  @override
  String get bookSourceCheckUpdates => 'Cerca aggiornamenti';

  @override
  String get bookSourceUpdates => 'Aggiornamenti libro';

  @override
  String get bookSourceNotChecked => 'Non ancora verificato';

  @override
  String get bookSourceUpToDate => 'Il catalogo è aggiornato';

  @override
  String get bookSourceUpdatesAvailable => 'Nuovi capitoli disponibili';

  @override
  String get bookSourceNeedsMapping => 'Conferma da dove continuare';

  @override
  String bookSourceLastChecked(String time) {
    return 'Ultima verifica: $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Ultimo aggiornamento: $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown =>
      'Orario di aggiornamento non disponibile';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Ultimo: $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Finché la libreria è aperta, i cataloghi vengono controllati ogni 30 minuti. Controlla manualmente in qualsiasi momento. I libri online usano il catalogo più recente; i libri TXT locali scaricano nuovi capitoli solo se scegli di continuare. Dopo il collegamento o il cambio di una sorgente, conferma l\'ultimo capitolo già presente nel tuo file locale. Gli aggiornamenti non sostituiscono il tuo testo originale. L\'orario di aggiornamento è fornito dalla sorgente, oppure registra quando è stato rilevato per la prima volta un nuovo capitolo.';

  @override
  String get bookSourceBindHelp =>
      'Trova questo libro nelle tue sorgenti per aggiungerne la copertina e attivare il cambio sorgente e gli aggiornamenti dei capitoli. Il tuo testo locale e la posizione di lettura vengono conservati.';

  @override
  String get bookSourceContinueUpdate => 'Scarica nuovi capitoli';

  @override
  String get settingsCloseReaderToLibraryTitle =>
      'Close reader to return to library';

  @override
  String get settingsCloseReaderToLibrarySubtitle =>
      'When a book is open, the window close button returns to the main window instead of quitting the app';

  @override
  String get navMe => 'Il mio spazio';

  @override
  String get settingsPreferencesTitle => 'Preferenze';

  @override
  String get settingsPreferencesSubtitle => 'Aspetto, lettura, lingua';

  @override
  String get settingsManagementTitle => 'Impostazioni e gestione';

  @override
  String get settingsDataSyncSubtitle => 'Backup WebDAV, cache';

  @override
  String get settingsContentServicesTitle => 'Contenuti e servizi';

  @override
  String get settingsContentServicesSubtitle => 'Fonti, IA, lettura vocale';

  @override
  String get settingsAboutSupportSubtitle =>
      'Versione, aggiornamenti, open source';

  @override
  String get settingsPremiumSubtitle =>
      'Altre fonti e accesso alla rete privata';

  @override
  String get settingsGuestTitle => 'Accesso non effettuato';

  @override
  String get settingsGuestSubtitle =>
      'La lettura locale non richiede un account';

  @override
  String get settingsWebDavConfigured => 'Backup WebDAV configurato';

  @override
  String get settingsPremiumActive => 'Premium attivo';

  @override
  String get settingsPremiumSyncFailed =>
      'Impossibile sincronizzare l’abbonamento';

  @override
  String get settingsWebDavWorking => 'WebDAV in corso';

  @override
  String get storeReaderLockedTitle => 'Sblocca Origo X';

  @override
  String get storeReaderLockedBody =>
      'Per leggere in questa versione dello store serve una prova attiva o una licenza. I tuoi libri e le tue note vengono conservati. Torna alla libreria per esportare i tuoi dati.';

  @override
  String get storeReaderUnlock => 'Prova, acquista o ripristina';

  @override
  String get storeReaderBack => 'Torna alla libreria';

  @override
  String get storeReaderChecking => 'Verifica dell’accesso alla lettura…';

  @override
  String get storeReaderBenefitTitle => 'Accesso completo alla lettura';

  @override
  String get storeReaderBenefitBody =>
      'Sblocca per sempre la lettura locale. Non serve un account Origo.';

  @override
  String storeTrialStart(int days) {
    return 'Prova gratis per $days giorni';
  }

  @override
  String storeTrialDetails(int days) {
    return 'Prova la lettura locale per $days giorni, senza addebiti automatici. Poi è necessario un acquisto unico per continuare. Libri e note vengono conservati.';
  }

  @override
  String get storeTrialStarted =>
      'La tua prova della versione dello store è iniziata.';

  @override
  String get storeTrialExpired =>
      'La tua prova della versione dello store è terminata. Effettua un acquisto una tantum per continuare o ripristina un acquisto esistente.';

  @override
  String storePurchaseButton(String store) {
    return 'Sblocca per sempre con $store';
  }

  @override
  String storePurchaseBilling(String store) {
    return 'Sblocco dell’app con acquisto unico, senza rinnovo automatico. $store mostra il prezzo ed elabora il pagamento.';
  }

  @override
  String storePurchaseRestoreHelp(String store) {
    return 'Ripristina con l’account $store usato per l’acquisto. Non serve accedere a Origo né pagare di nuovo.';
  }

  @override
  String storePurchaseAccess(String store) {
    return 'Hai già accesso tramite $store. Non serve acquistare di nuovo.';
  }

  @override
  String get storeRestoreEmpty =>
      'Non è stato trovato alcun acquisto ripristinabile. Controlla il tuo account dello store e l’account Origo X collegato.';

  @override
  String get storeGoogleRefundTerms =>
      'Richiedi un rimborso tramite Google Play. Un rimborso verificato rimuove solo l’accesso associato a quell’acquisto; i diritti di accesso indipendenti restano validi.';

  @override
  String get storeReaderLegacyNotice =>
      'Il tuo accesso di base alla lettura viene mantenuto. La compatibilità avanzata con le sorgenti richiede ancora Premium.';

  @override
  String get storePrivacyPurchaseBody =>
      'I dati di verifica dello store e un identificativo dell’account vengono inviati al nostro server per verificare e ripristinare l’accesso. La verifica di Google Play include un token di acquisto e un identificativo dell’account sottoposto a hashing. Non riceviamo i dati delle carte di pagamento.';

  @override
  String storeTrialLegacyDetails(int days) {
    return 'Il tuo accesso alla lettura resta valido. Non serve la prova di $days giorni.';
  }

  @override
  String get storeReaderSupportSubtitle =>
      'Prova l’esperienza di lettura completa o sbloccala per sempre con un unico acquisto';

  @override
  String get storeBillingUnavailable =>
      'Gli acquisti nello store non sono ancora disponibili. Riprova più tardi. Il tuo accesso attuale resta invariato.';

  @override
  String get accountSignInTitle => 'Accedi a Origo X';

  @override
  String get accountSignInSubtitle =>
      'Gestisci il tuo account e i tuoi acquisti';

  @override
  String accountRegistrationStep(int step) {
    return 'Crea account · $step / 3';
  }

  @override
  String get accountSetupTitle => 'Configura il tuo account';

  @override
  String get accountSetupHint => 'Puoi aggiungere nome e foto in seguito.';

  @override
  String get accountInvalidEmail => 'Inserisci un indirizzo email valido';

  @override
  String get accountCodeFormat =>
      'Inserisci il codice di 6 cifre ricevuto via email';

  @override
  String get accountPasswordRequired => 'Inserisci la password';

  @override
  String get accountShowPassword => 'Mostra password';

  @override
  String get accountHidePassword => 'Nascondi password';

  @override
  String accountResendIn(int seconds) {
    return 'Invia di nuovo tra $seconds s';
  }

  @override
  String get accountBackToCode => 'Torna al codice email';

  @override
  String get accountAuthorizationTitle => 'Continua nel browser';

  @override
  String get accountReopenAuthorization => 'Riapri la pagina di accesso';

  @override
  String get accountSignOutHint =>
      'I libri locali verranno conservati. Accedi di nuovo per verificare i diritti del tuo account.';

  @override
  String get accountDiscardChanges => 'Scarta modifiche';

  @override
  String get accountUnsavedChanges =>
      'Le modifiche al profilo non sono state salvate.';

  @override
  String get accountAuthorizationExpired =>
      'La richiesta è scaduta. Riprova ad accedere.';

  @override
  String get storeReaderLicenseTitle => 'Sblocca app';

  @override
  String get storeReaderLicenseSubtitle =>
      'Prova la lettura locale per 14 giorni, poi sbloccala con un acquisto unico.';

  @override
  String get storeReaderLifetimeTitle => 'Sblocco permanente dell’app';

  @override
  String storeReaderOwned(String store) {
    return 'L’app è sbloccata permanentemente tramite $store.';
  }

  @override
  String get storePremiumPrerequisiteTitle => 'Sblocca prima l’app';

  @override
  String get storePremiumPrerequisiteBody =>
      'Premium è venduto separatamente dopo lo sblocco permanente dell’app. La prova non è sufficiente.';

  @override
  String get storePremiumPriceCaption =>
      'Premium permanente · collegato al tuo account Origo';

  @override
  String storePremiumPurchaseButton(String store) {
    return 'Acquista Premium tramite $store';
  }

  @override
  String storePremiumBilling(String store) {
    return 'Premium è un acquisto separato e una tantum, senza rinnovo automatico. $store mostra il prezzo e gestisce il pagamento. Premium è collegato al tuo account Origo attuale.';
  }

  @override
  String storePremiumRestoreHelp(String store) {
    return 'Accedi all’account Origo collegato e ripristina Premium con l’account $store usato per acquistarlo. Non verrà addebitato alcun nuovo pagamento.';
  }

  @override
  String storeReaderTrialExpiresAt(String date) {
    return 'La prova dell’app termina il $date.';
  }

  @override
  String get storeReaderPurchaseSuccess => 'App sbloccata per sempre';

  @override
  String get storeReaderRestoreSuccess => 'Acquisto dell’app ripristinato';

  @override
  String get storeReaderTestPurchaseVerified =>
      'Acquisto di prova verificato; nessuna licenza definitiva concessa.';

  @override
  String get storeReaderPurchaseRevoked =>
      'Lo sblocco dell’app è stato revocato.';

  @override
  String storeReaderPendingApproval(String store) {
    return 'In attesa dell’approvazione di $store. La lettura si sbloccherà dopo la verifica.';
  }

  @override
  String get storeReaderVerifying => 'Verifica dell’acquisto dell’app…';

  @override
  String get storeReaderRestoring => 'Ripristino dell’acquisto dell’app…';
}
