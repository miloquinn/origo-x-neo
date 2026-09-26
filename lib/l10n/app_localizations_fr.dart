// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Accueil';

  @override
  String get library => 'Bibliothèque';

  @override
  String get bookSources => 'Sources';

  @override
  String get discover => 'Découvrir';

  @override
  String get discoverRecommended => 'Pour vous';

  @override
  String get discoverCategories => 'Catégories';

  @override
  String get discoverLatest => 'Nouveautés';

  @override
  String get discoverLoadFailed => 'Impossible de charger le contenu Découvrir';

  @override
  String get discoverRetry => 'Réessayer';

  @override
  String get discoverEmptyTitle => 'Rien à afficher pour le moment';

  @override
  String get discoverEmptyMessage =>
      'Cette section n\'a pas encore de contenu à afficher.';

  @override
  String get discoverUnsupportedTitle =>
      'Les sources actuelles ne prennent pas en charge cette section';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'Une source offrant la capacité $capability est requise. Les sources existantes restent utilisables pour la recherche.';
  }

  @override
  String get discoverCategoryEmpty =>
      'Il n\'y a pas encore de livres à afficher dans cette catégorie.';

  @override
  String get bookSourceChannelLoadFailed => 'Impossible de charger le canal';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'La source n\'a renvoyé aucun livre exploitable : $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'Impossible de se connecter au serveur de la source après avoir essayé ses adresses réseau disponibles. Réessayez plus tard.';

  @override
  String get bookSourceRedirectFailed =>
      'Le site de la source n\'a cessé de rediriger. Les cookies du site ont été conservés, mais l\'adresse ne renvoie toujours aucun contenu.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'Le site de la source a renvoyé HTTP $status. L\'adresse du canal est peut-être obsolète ou bloquée par le site.';
  }

  @override
  String get bookSourceStandardLayout => 'Disposition standard';

  @override
  String get bookSourceListLayout => 'Disposition en liste';

  @override
  String get bookSourceChangeChannel => 'Changer';

  @override
  String get bookSourceChangeSourceTitle => 'Changer de source';

  @override
  String get bookSourceChangeCurrentSource => 'Source actuelle';

  @override
  String get bookSourceChangeTargetSource => 'Changer pour';

  @override
  String get bookSourceChangeNotSelected => 'Aucune sélection';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'Actuellement au chapitre $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Trouver ce livre dans d\'autres sources';

  @override
  String get bookSourceChangeSearchAgain => 'Rechercher à nouveau';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Rechercher dans toutes les sources restantes';

  @override
  String get bookSourceChangeCheckAuthor => 'Faire correspondre l\'auteur';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return '$completed sur $total vérifiées';
  }

  @override
  String get bookSourceChangeNoOtherSources => 'Aucune autre source disponible';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Ajoutez et activez d\'abord une autre source prenant en charge la recherche.';

  @override
  String get bookSourceChangeSearching => 'Recherche d\'autres sources';

  @override
  String get bookSourceChangeSearchingHint =>
      'Les correspondances apparaissent au fur et à mesure que chaque source termine sa recherche.';

  @override
  String get bookSourceChangeNoMatches =>
      'Aucune source correspondante trouvée';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Modifiez le titre ou désactivez la correspondance de l\'auteur, puis relancez la recherche.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return '$count requête(s) de source ont échoué. Vous pouvez relancer la recherche.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Auteur différent';

  @override
  String get bookSourceChangeValidating =>
      'Vérification du catalogue et du chapitre actuel…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Échec de la validation : $details';
  }

  @override
  String get bookSourceChangeReadable => 'Chapitre actuel lisible';

  @override
  String bookSourceChangeChapterCount(int count) {
    return '$count chapitres';
  }

  @override
  String bookSourceChangeResponseTime(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get bookSourceChangeTapToValidate =>
      'Sélectionnez pour vérifier le catalogue et le chapitre actuel.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Cette version de la source est déjà dans la bibliothèque.';

  @override
  String get bookSourceChangeSwitching => 'Changement de source…';

  @override
  String get bookSourceChangeSwitchAction => 'Passer à cette source';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Source changée pour $source';
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
    return '$count canaux';
  }

  @override
  String get bookSourceManagementTitle => 'Gérer les sources';

  @override
  String get bookSourceManagementSubtitle =>
      'Ajoutez, activez, supprimez et inspectez les fournisseurs de contenu. Découvrir reste centré sur la recherche de livres.';

  @override
  String get settingsContentSourcesTitle => 'Sources de contenu';

  @override
  String get settingsContentSourcesSubtitle =>
      'Ajouter, activer ou supprimer des sources de livres ouvertes';

  @override
  String get bookSourcesSubtitle =>
      'Connectez des sources ouvertes et recherchez du contenu lisible sur plusieurs fournisseurs';

  @override
  String get bookSourcesAdd => 'Ajouter une source';

  @override
  String get bookSourcesSearchHint =>
      'Rechercher dans les sources activées par titre ou auteur';

  @override
  String get bookSourcesSearch => 'Rechercher';

  @override
  String get bookSourcesLoadMore => 'Charger plus';

  @override
  String bookSourcesFailedCount(int count) {
    return '$count requête(s) de source ont échoué';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Paramètres de recherche';

  @override
  String get bookSourcesSearchSettingsTitle => 'Paramètres de recherche';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Requêtes simultanées';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Délai par source (s)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Limite de sources';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Quand de nombreuses sources sont activées, seule cette quantité (dans l\'ordre de la liste) est interrogée à la fois, afin de limiter l\'utilisation du réseau et de la batterie.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return '$enabledCount sources sont activées, au-delà de la limite actuelle de $limit. Les sources au-delà de la limite ne seront pas recherchées.';
  }

  @override
  String get bookSourcesSearchResetDefaults =>
      'Rétablir les valeurs par défaut';

  @override
  String get bookSourcesSearchPrompt =>
      'Ajoutez et activez une source pour la rechercher ici';

  @override
  String get bookSourcesNoResults => 'Aucun livre correspondant trouvé';

  @override
  String get bookSourcesNoSourcesTitle => 'Aucune source pour le moment';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Collez l\'adresse d\'un service compatible avec le protocole Origo Source.';

  @override
  String get bookSourcesManageTitle => 'Sources connectées';

  @override
  String get bookSourcesEnabled => 'Activée';

  @override
  String get bookSourcesDisabled => 'Désactivée';

  @override
  String get bookSourcesRunnable => 'Prête à l\'emploi';

  @override
  String get bookSourcesPendingCompatibility => 'Aucune règle exécutable';

  @override
  String get bookSourcesRequiresLogin => 'Connexion requise';

  @override
  String get bookSourcesManagementSearchHint =>
      'Rechercher par nom, URL, notes ou groupe';

  @override
  String get bookSourcesClearSearch => 'Effacer la recherche';

  @override
  String get bookSourcesAllGroups => 'Tous les groupes';

  @override
  String get bookSourcesChooseGroup => 'Choisir un groupe de sources';

  @override
  String get bookSourcesSearchGroups => 'Rechercher des groupes';

  @override
  String get bookSourcesNoMatchingSources =>
      'Aucune source ne correspond à la recherche et aux filtres actuels';

  @override
  String get bookSourcesResetFilters => 'Réinitialiser';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return '$visible affichées sur $total';
  }

  @override
  String get bookSourcesRemove => 'Supprimer';

  @override
  String get bookSourcesRemoveTitle => 'Supprimer la source';

  @override
  String get bookSourcesRemoveMessage =>
      'Seule la configuration de la source est supprimée. Les livres locaux ne sont pas affectés.';

  @override
  String get bookSourcesCancel => 'Annuler';

  @override
  String get bookSourcesConfirm => 'Confirmer';

  @override
  String get bookSourcesAddTitle => 'Ajouter une source';

  @override
  String get bookSourcesImportLink => 'Importer un lien';

  @override
  String get bookSourcesAnalyze => 'Lire les sources';

  @override
  String get bookSourcesDetectedOrsp => 'Détecté : ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Détecté : Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'Sources ORSP';

  @override
  String get bookSourcesProtocolGroupAdditional =>
      'Sources d\'autres protocoles';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Cette source n\'est pas disponible pour le compte ou les paramètres actuels.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Aucune source n\'a réussi le test de recherche en direct. Rien n\'a été importé.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return '$completed/$total vérifiées ; $available fonctionnelles';
  }

  @override
  String get bookSourcesSelect => 'Sélectionner des sources';

  @override
  String get bookSourcesSelectAll => 'Tout sélectionner';

  @override
  String get bookSourcesClearSelection => 'Effacer la sélection';

  @override
  String get bookSourcesEnableSelected => 'Activer la sélection';

  @override
  String get bookSourcesDisableSelected => 'Désactiver la sélection';

  @override
  String get bookSourcesExportSelected => 'Exporter la sélection';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return '$count source(s) exportée(s) vers $location';
  }

  @override
  String get bookSourcesExportFailed =>
      'Impossible d\'exporter les sources sélectionnées';

  @override
  String get bookSourcesExportUnsupported =>
      'L\'exportation de sources n\'est pas encore prise en charge sur cette plateforme';

  @override
  String get bookSourcesExportReplaceTitle => 'Remplacer le fichier existant ?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Un fichier existe déjà à $path. Le remplacer ?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Remplacer';

  @override
  String get bookSourcesDeleteSelected => 'Supprimer la sélection';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return 'Supprimer $count sources sélectionnées ? Les livres locaux ne sont pas affectés.';
  }

  @override
  String get bookSourcesCheckSelected => 'Vérifier la sélection';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return '$healthy sur $total source(s) sont saines';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Vérifier et nettoyer les sources';

  @override
  String get bookSourcesCleanupNoCheckableSources => 'Aucune source à vérifier';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Les $count sources vérifiées sont toutes entièrement disponibles';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Résultats de santé';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return '$fullyAvailable entièrement disponibles · $needsAttention à examiner';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Des fonctionnalités manquantes ou un délai dépassé ne signifient pas qu\'une source est inutilisable. Sélectionnez uniquement les sources que vous voulez désactiver.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return 'Désactiver $count sélectionnée(s)';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return '$count source(s) désactivée(s)';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Interrompu — $count source(s) vérifiée(s). Relancez plus tard pour reprendre là où vous vous êtes arrêté.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Maintenance des sources';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Trouvez les doublons et vérifiez la disponibilité des sources';

  @override
  String get bookSourcesMaintenanceHealthTitle =>
      'Vérification de santé des sources';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Testez la recherche et la lecture ; réutilisez les résultats sains récents';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Vérification de santé des sources en cours';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Nettoyage des doublons';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Comparez les sources localement, sans réseau';

  @override
  String get bookSourcesMaintenanceReviewTitle => 'Dernier résultat de santé';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return '$count source(s) à examiner';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Seules les sources que vous confirmez sont désactivées. Leurs configurations sont conservées.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Vérification des sources';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Vérification de la recherche, des détails, des catalogues et du contenu';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Vérification de santé des sources terminée';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return '$checked source(s) vérifiée(s) ; $attention à examiner';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Arrêter la vérification';

  @override
  String get bookSourcesMaintenanceBackground => 'Continuer en arrière-plan';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Fermez cette vue de progression et la vérification continuera discrètement pendant que l\'application fonctionne.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'La vérification de santé des sources continue discrètement en arrière-plan';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Examiner les résultats';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Maintenance des sources $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Trouver les sources en doublon';

  @override
  String get bookSourcesDedupeNone => 'Aucune source en doublon trouvée';

  @override
  String get bookSourcesDedupeReviewTitle => 'Examiner les sources en doublon';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return '$groups groupe(s), $duplicates source(s) en doublon';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'La source recommandée est conservée. Les doublons sélectionnés seront désactivés, pas supprimés.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return 'Désactiver $count sélectionnée(s)';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return '$count source(s) en doublon désactivée(s)';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Exacte';

  @override
  String get bookSourcesDedupeModeStandard => 'Standard';

  @override
  String get bookSourcesDedupeModeSite => 'Même site';

  @override
  String get bookSourcesDedupeExactReason => 'Même identité de source';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Même adresse de source normalisée';

  @override
  String get bookSourcesDedupeSiteReason => 'Même site ; examen requis';

  @override
  String get bookSourcesDedupeRecommended => 'Recommandée';

  @override
  String get bookSourcesDedupeReviewAction => 'Examiner la déduplication';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return '$ready prêtes, $duplicates en doublon, $errors invalides';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return '$books livre · $comics BD · $unsupported non exécutable(s) actuellement';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults => 'Rétablir les recommandations';

  @override
  String get bookSourcesUrlLabel => 'Adresse de la source';

  @override
  String get bookSourcesUrlHint =>
      'https://example.com ou une URL JSON de source';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'Origo X n\'inclut aucune source et n\'exploite, ne recommande ni n\'approuve de services de sources tiers. Chaque adresse de source est ajoutée par vous.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Je confirme que je suis autorisé à accéder à ce contenu et que je n\'utiliserai pas la source pour contourner une connexion, un paiement, un DRM ou d\'autres contrôles d\'accès.';

  @override
  String get bookSourcesConnect => 'Lire et importer';

  @override
  String get bookSourcesConnecting => 'Traitement des sources…';

  @override
  String get bookSourcesAdded => 'Source ajoutée';

  @override
  String get bookSourcesRefresh => 'Actualiser la source';

  @override
  String get bookSourcesRefreshed => 'Source de livre actualisée';

  @override
  String get bookSourcesRefreshFailed =>
      'Impossible d\'actualiser cette source de livre';

  @override
  String get bookSourcesProtocolTitle => 'Protocole Origo Source';

  @override
  String get bookSourcesInformationTitle => 'Protocole et informations';

  @override
  String get bookSourcesInformationSubtitle =>
      'Consultez le protocole, les liens du projet et les informations sur les droits du contenu';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'Découvrez les capacités prises en charge des sources et le protocole ouvert';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Consultez le dépôt du protocole sur GitHub';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'Comprenez le contenu tiers et les limites des droits';

  @override
  String get bookSourcesProtocolDescription =>
      'Un contrat commun pour la découverte, la recherche, les détails de livre, les catalogues et le contenu des chapitres. Les développeurs peuvent héberger des sources natives ou créer des adaptateurs pour du contenu qu\'ils sont autorisés à servir.';

  @override
  String get bookSourcesProtocolDetails => 'Voir le protocole';

  @override
  String get bookSourcesProtocolRepository => 'Dépôt du protocole';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Voir sur GitHub';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'Impossible d\'ouvrir le dépôt du protocole';

  @override
  String get bookSourcesProtocolDialogTitle =>
      'Protocole de source ouverte v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Une source publie /.well-known/open-reading-source.json et implémente les capacités Core Reading : recherche, détails de livre, catalogues de chapitres paginés et contenu de chapitre. La version 1.4 conserve la pagination complète du catalogue, exige ces capacités principales et conserve les métadonnées d\'opérateur, de contact, de licence et de déclaration de droits pour les sources HTTP(S) publiques ne nécessitant pas de connexion.';

  @override
  String get bookSourcesRightsDetails => 'Opérateur et droits';

  @override
  String get bookSourcesOperator => 'Opérateur de la source';

  @override
  String get bookSourcesContentLicense => 'Licence du contenu';

  @override
  String get bookSourcesRightsStatement => 'Déclaration de droits';

  @override
  String get bookSourcesRightsNotProvided => 'Non fournie par cette source';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Ces déclarations sont fournies par l\'opérateur indépendant de la source. Origo X les affiche par transparence mais ne les vérifie ni ne les approuve.';

  @override
  String get bookSourcesContactOperator => 'Contacter l\'opérateur';

  @override
  String get bookSourcesRightsReport => 'Signalement de droits';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'Impossible d\'ouvrir le formulaire de signalement de droits';

  @override
  String get bookSourcesClose => 'Fermer';

  @override
  String get sourceLoginTitle => 'Connexion à la source';

  @override
  String get sourceLoginInfo => 'Informations de connexion';

  @override
  String get sourceLoginActions => 'Actions de la source';

  @override
  String get sourceLoginExtraSettings => 'Paramètres supplémentaires';

  @override
  String get sourceLoginSecureStorageNotice =>
      'Les informations de connexion restent dans le stockage sécurisé du système de cet appareil.';

  @override
  String get sourceLoginNoForm =>
      'Cette source ne fournit pas de méthode de connexion disponible.';

  @override
  String get sourceLoginBrowserTitle => 'Se connecter sur le site d\'origine';

  @override
  String get sourceLoginBrowserNotice =>
      'Terminez la connexion dans le navigateur, puis touchez Terminé. Les cookies et le stockage local du site seront enregistrés sur cet appareil.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'La connexion via site web est disponible sur Android, iPhone, iPad et Mac.';

  @override
  String get sourceLoginBrowserOpen => 'Ouvrir le site web pour se connecter';

  @override
  String get sourceLoginSave => 'Se connecter et enregistrer la session';

  @override
  String get sourceLoginClear => 'Effacer la session de connexion';

  @override
  String get sourceLoginSaved => 'Session de connexion à la source mise à jour';

  @override
  String get sourceLoginCleared => 'Session de connexion à la source effacée';

  @override
  String sourceLoginFailed(String details) {
    return 'Impossible de mettre à jour la session de connexion à la source : $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '\"$sourceName\" fournit une connexion pour le contenu réservé aux comptes.';
  }

  @override
  String get sourceDebugMenuLabel => 'Débogage';

  @override
  String get sourceDebugTitle => 'Débogueur de source';

  @override
  String get sourceDebugInputHint =>
      'Saisissez un mot-clé de recherche ou collez une URL de livre/catalogue/chapitre';

  @override
  String get sourceDebugRun => 'Exécuter';

  @override
  String get sourceDebugStop => 'Arrêter';

  @override
  String get sourceDebugClear => 'Effacer le journal';

  @override
  String get sourceDebugEmpty =>
      'Saisissez un mot-clé ou une URL et touchez Exécuter pour voir chaque étape de la résolution par cette source.';

  @override
  String get sourceDebugCopy => 'Copier';

  @override
  String get sourceDebugCopied => 'Copié dans le presse-papiers';

  @override
  String get sourceHealthMenuLabel => 'Vérifier la santé';

  @override
  String get sourceHealthHealthy => 'Saine';

  @override
  String get sourceHealthPartial => 'Partiellement défaillante';

  @override
  String get bookSourcesFullyAvailable => 'Entièrement disponible';

  @override
  String get sourceHealthTimedOut => 'Délai de vérification dépassé';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Défaillante : $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'recherche';

  @override
  String get sourceHealthCapabilityDiscover => 'découverte';

  @override
  String get sourceHealthCapabilityInfo => 'infos du livre';

  @override
  String get sourceHealthCapabilityCatalog => 'catalogue';

  @override
  String get sourceHealthCapabilityContent => 'contenu';

  @override
  String get sourceVerificationTitle => 'Vérification de la source';

  @override
  String get sourceVerificationBrowserHint =>
      'Terminez la vérification du site dans le navigateur sécurisé, puis choisissez Vérification terminée. L\'adresse de la page et les cookies reviennent uniquement à cette tâche de source.';

  @override
  String get sourceVerificationCodeHint =>
      'Lisez l\'image et saisissez son code pour continuer cette tâche de source.';

  @override
  String get sourceVerificationCodeLabel => 'Code de l\'image';

  @override
  String get sourceVerificationSubmit => 'Continuer';

  @override
  String get sourceVerificationRetry => 'Rouvrir le navigateur';

  @override
  String get sourceVerificationCancel => 'Annuler la vérification';

  @override
  String sourceVerificationFailed(String details) {
    return 'Impossible d\'ouvrir la vérification de la source : $details';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get statistics => 'Statistiques';

  @override
  String get reading => 'Lecture';

  @override
  String get importBooks => 'Importer des livres';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get systemMode => 'Système';

  @override
  String get theme => 'Thème';

  @override
  String get accent => 'Couleur d\'accentuation';

  @override
  String get bookmarks => 'Marque-pages';

  @override
  String get notes => 'Notes';

  @override
  String get highlights => 'Surlignages';

  @override
  String get ttsReading => 'Synthèse vocale';

  @override
  String get share => 'Partager';

  @override
  String get shareContent => 'Partager le contenu';

  @override
  String get shareCurrentPage => 'Partager la page actuelle';

  @override
  String get shareSelectedText => 'Partager le texte sélectionné';

  @override
  String get shareProgress => 'Partager la progression de lecture';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Arrêter';

  @override
  String get speed => 'Vitesse';

  @override
  String get pitch => 'Tonalité';

  @override
  String get language => 'Langue';

  @override
  String get fontSize => 'Taille de police';

  @override
  String get readingProgress => 'Progression de lecture';

  @override
  String get totalPages => 'Pages au total';

  @override
  String get currentPage => 'Page actuelle';

  @override
  String get readingTime => 'Temps de lecture';

  @override
  String get booksRead => 'Livres lus';

  @override
  String get todayReading => 'Lecture du jour';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get search => 'Rechercher';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get initializationFailed => 'Échec de l\'initialisation';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get retry => 'Réessayer';

  @override
  String get appearanceSettings => 'Apparence';

  @override
  String get readingTips => 'Astuces de lecture';

  @override
  String get readingFontSettingsMoved =>
      'Paramètres de police de lecture déplacés';

  @override
  String get readingFontSettingsHint =>
      'Ouvrez un livre, touchez le centre de l\'écran, puis utilisez la barre d\'outils du bas pour ajuster la taille de police, l\'interligne, l\'espacement des caractères, les marges et la police de lecture.';

  @override
  String get readingSettings => 'Paramètres de lecture';

  @override
  String get enableTts => 'Activer la synthèse vocale';

  @override
  String get enableTtsHint => 'Activer la lecture par synthèse vocale';

  @override
  String get ttsSpeedLabel => 'Vitesse';

  @override
  String get ttsSpeedHint => 'Ajuster la vitesse de lecture';

  @override
  String get ttsVolumeLabel => 'Volume';

  @override
  String get ttsVolumeHint => 'Ajuster le volume de lecture';

  @override
  String get ttsPitchLabel => 'Tonalité';

  @override
  String get ttsPitchHint => 'Ajuster la tonalité de lecture';

  @override
  String get appSettings => 'Paramètres de l\'application';

  @override
  String get appFont => 'Police de l\'application';

  @override
  String get appFontDescription =>
      'Utilisée par la navigation, les boutons, les paramètres et les autres textes d\'interface. Elle ne modifie pas le contenu des livres.';

  @override
  String get readerFont => 'Police de lecture';

  @override
  String get readerFontDescription =>
      'Pour les livres TXT et en ligne. EPUB possède son propre réglage de police.';

  @override
  String get readerFontSelectionDescription =>
      'Choisissez la police de lecture. EPUB propose la police du livre, celle du système et vos polices installées.';

  @override
  String get readerFontBookPriorityHint =>
      'Utilise la police intégrée au livre si disponible ; sinon utilise la police de lecture par défaut de la plateforme.';

  @override
  String get readerFontOverrideHint =>
      'Remplace les polices intégrées par l\'éditeur.';

  @override
  String get fontBookEmbedded => 'Intégrée au livre';

  @override
  String get fontSystem => 'Par défaut de la plateforme';

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
      'Utilise une police de lecture optimisée pour la plateforme, pour des glyphes et une pagination stables.';

  @override
  String get fontSerifDescription =>
      'Une police avec empattements au caractère calme et éditorial, idéale pour la lecture prolongée.';

  @override
  String get fontSansSerifDescription =>
      'Une police sans empattements et claire, adaptée aux interfaces compactes et à la lecture quotidienne.';

  @override
  String get fontMonospaceDescription =>
      'Une police à chasse fixe, adaptée au code, au contenu technique et aux mises en page épurées.';

  @override
  String get fontPreviewText => 'Origo X · Lisez librement 开卷有益';

  @override
  String get customFonts => 'Mes polices';

  @override
  String get customFontsEmpty => 'Aucune police personnalisée pour le moment';

  @override
  String get customFontsEmptyHint =>
      'Importez une fois un fichier TTF ou OTF, puis utilisez-le pour l\'interface ou la lecture.';

  @override
  String customFontsCount(int count) {
    return '$count polices importées';
  }

  @override
  String get customFontsLocalOnly =>
      'Les polices importées sont stockées uniquement sur cet appareil et ne sont pas synchronisées automatiquement.';

  @override
  String get builtInFonts => 'Polices intégrées';

  @override
  String get onlineFonts => 'Polices en ligne';

  @override
  String get fontDownload => 'Télécharger';

  @override
  String get fontDownloading => 'Téléchargement…';

  @override
  String get fontDownloaded => 'Téléchargée';

  @override
  String get fontDownloadFailed =>
      'Échec du téléchargement, touchez pour réessayer';

  @override
  String get fontDownloadHint =>
      'La première utilisation nécessite un téléchargement en ligne';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Graisse réglable $min–$max';
  }

  @override
  String get fontStaticWeight => 'Graisse fixe (le gras est synthétisé)';

  @override
  String get fontDeleteDownload => 'Supprimer le téléchargement';

  @override
  String fontDeleteDownloadTitle(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Libérera $size de stockage. Sera retéléchargée à la prochaine utilisation.';
  }

  @override
  String get fontDownloadCancelled => 'Téléchargement annulé';

  @override
  String get fontDownloadNetworkFailed =>
      'Erreur réseau, échec du téléchargement';

  @override
  String get fontDownloadInvalid =>
      'Le fichier de police téléchargé est invalide';

  @override
  String get fontDownloadUnsupported =>
      'Le téléchargement de polices en ligne n\'est pas pris en charge sur cette plateforme';

  @override
  String get importFont => 'Importer une police';

  @override
  String get importingFont => 'Importation de la police…';

  @override
  String get customFontImported => 'Police importée';

  @override
  String get customFontAlreadyImported =>
      'Cette police a déjà été importée et est prête à l\'emploi';

  @override
  String get customFontApplied => 'Sélection de police mise à jour';

  @override
  String get customFontAppliedToApp =>
      'Importée et définie comme police de l\'application';

  @override
  String get customFontAppliedToReader =>
      'Importée et définie comme police de lecture';

  @override
  String get customFontImportUnsupported =>
      'L\'importation persistante de polices n\'est pas encore prise en charge sur cette plateforme.';

  @override
  String get customFontUnsupportedFormat =>
      'Choisissez un fichier de police TTF ou OTF.';

  @override
  String get customFontInvalid =>
      'Ce fichier n\'est pas une police valide ou prise en charge.';

  @override
  String get customFontTooLarge => 'Le fichier de police dépasse 50 Mo.';

  @override
  String get customFontReadFailed =>
      'Le fichier de police n\'a pas pu être lu.';

  @override
  String get customFontLoadFailed => 'La police n\'a pas pu être chargée.';

  @override
  String get customFontStorageFailed =>
      'La police n\'a pas pu être enregistrée sur cet appareil.';

  @override
  String get customFontUnavailable =>
      'Le fichier de police est indisponible. Supprimez-le et importez-le à nouveau.';

  @override
  String get setAsAppFont => 'Utiliser comme police de l\'application';

  @override
  String get setAsReaderFont => 'Utiliser comme police de lecture';

  @override
  String get setAsBothFonts => 'Utiliser pour les deux';

  @override
  String get renameFont => 'Renommer la police';

  @override
  String deleteCustomFontTitle(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String get deleteCustomFontMessage =>
      'Le fichier de police sera supprimé de cet appareil.';

  @override
  String get deleteCustomFontInUse =>
      'Cette police est actuellement utilisée. La supprimer rétablira les paramètres de police concernés à leurs valeurs par défaut.';

  @override
  String get deleteAndReset => 'Supprimer et réinitialiser';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Canal Telegram officiel';

  @override
  String get settingsTelegramOpenFailed =>
      'Impossible d\'ouvrir le lien Telegram';

  @override
  String get settingsQqChannel => 'Canal QQ';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'Impossible d\'ouvrir le lien d\'invitation du canal QQ';

  @override
  String get languageSystem => 'Suivre le système';

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
  String get typographySettings => 'Typographie';

  @override
  String get fontFamilyLabel => 'Police';

  @override
  String get fontSizeLabel => 'Taille de police';

  @override
  String get readerFontWeightLabel => 'Graisse de police';

  @override
  String get readerFontWeightLight => 'Légère';

  @override
  String get readerFontWeightRegular => 'Normale';

  @override
  String get readerFontWeightMedium => 'Moyenne';

  @override
  String get readerFontWeightSemiBold => 'Demi-grasse';

  @override
  String get readerFontWeightBold => 'Grasse';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'Les réglages de lecture utilisent cinq paliers lisibles de 300 à 700. La vraie plage complète de cette police est $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'Les réglages de lecture utilisent cinq paliers de 300 à 700. Cette police ne déclare pas d\'axe de graisse variable ; le système approxime le résultat, qui peut différer selon la plateforme.';

  @override
  String get readerFontWeightPreview =>
      'Une page paisible se lit plus loin · 字里行间';

  @override
  String get lineSpacingLabel => 'Interligne';

  @override
  String get letterSpacingLabel => 'Espacement des caractères';

  @override
  String get textAlignmentLabel => 'Alignement du texte';

  @override
  String get textAlignmentNatural => 'Naturel';

  @override
  String get textAlignmentJustified => 'Justifié';

  @override
  String get firstLineIndentLabel => 'Retrait de première ligne';

  @override
  String get paragraphSpacingLabel => 'Espacement des paragraphes';

  @override
  String get pageMarginLabel => 'Marge de page';

  @override
  String get resetDefault => 'Réinitialiser';

  @override
  String get ttsPanelTitle => 'Synthèse vocale';

  @override
  String get ttsPreviewEffect => 'Aperçu de l\'effet';

  @override
  String get ttsVolume => 'Volume';

  @override
  String get ttsPitch => 'Tonalité';

  @override
  String get ttsSpeed => 'Vitesse';

  @override
  String get ttsPreviousSentence => 'Phrase précédente';

  @override
  String get ttsNextSentence => 'Phrase suivante';

  @override
  String get ttsTimerStop => 'Arrêt minuté';

  @override
  String get ttsTimerOff => 'Illimité';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get ttsPlaying => 'Lecture en cours';

  @override
  String get ttsPaused => 'En pause';

  @override
  String get ttsStopped => 'Arrêtée';

  @override
  String get ttsPreviousSentenceFailed =>
      'Échec de la lecture de la phrase précédente';

  @override
  String get ttsNextSentenceFailed =>
      'Échec de la lecture de la phrase suivante';

  @override
  String get ttsEmptyContentError => 'Le contenu de la page actuelle est vide';

  @override
  String get ttsPlaybackFailed => 'Échec de la lecture audio';

  @override
  String get ttsOperationFailed => 'Échec de l\'opération';

  @override
  String get pageTurningMode => 'Mode de pagination';

  @override
  String get pageTurningSlide => 'Glissement horizontal';

  @override
  String get pageTurningScroll => 'Pagination verticale';

  @override
  String get tapZoneSettings => 'Zones tactiles';

  @override
  String get tapZoneNextPage => 'Page suivante';

  @override
  String get tapZonePreviousPage => 'Page précédente';

  @override
  String get tapZoneMenu => 'Menu';

  @override
  String get tapZoneLegend => 'Légende';

  @override
  String get tapZoneNextChapter => 'Chapitre suivant';

  @override
  String get tapZonePreviousChapter => 'Chapitre précédent';

  @override
  String get tapZoneNone => 'Aucune action';

  @override
  String get tapZoneSettingsHint =>
      'Personnalisez l\'action de chacune des neuf zones tactiles';

  @override
  String get tapZoneChooseAction => 'Choisir une action';

  @override
  String get tapZoneMenuRequiredHint =>
      'Touchez une zone pour changer son action. Au moins une zone doit rester sur Menu ; si tous les menus sont retirés, la zone centrale redevient Menu.';

  @override
  String get tapZoneReset => 'Rétablir les valeurs par défaut';

  @override
  String get highlightColor => 'Couleur de surlignage';

  @override
  String get highlightPreview => 'Aperçu';

  @override
  String get highlightSampleText => 'Voici un texte d\'exemple,';

  @override
  String get highlightSampleText2 => 'cette partie sera surlignée,';

  @override
  String get highlightSampleText3 => 'montrant l\'effet du surlignage.';

  @override
  String get colorLightBlue => 'Bleu clair';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorPurple => 'Violet';

  @override
  String get colorGold => 'Or';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Jaune';

  @override
  String get colorDarkGreen => 'Vert foncé';

  @override
  String get colorCustom => 'Personnalisée';

  @override
  String get noteTypeHighlight => 'Surlignage';

  @override
  String get noteTypeUnderline => 'Soulignement';

  @override
  String get noteTypeNote => 'Note';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Importer un livre';

  @override
  String get importFromFiles => 'Importer depuis Fichiers';

  @override
  String get importNoBooks => 'Aucun livre importé pour le moment';

  @override
  String get importSuccess => 'Livre importé avec succès';

  @override
  String get importFailed => 'Échec de l\'importation';

  @override
  String get importProcessing => 'Traitement du livre...';

  @override
  String get author => 'Auteur';

  @override
  String get progress => 'Progression';

  @override
  String get continueReading => 'Reprendre la lecture';

  @override
  String get recentBooks => 'Livres récents';

  @override
  String get allBooks => 'Tous les livres';

  @override
  String get emptyLibrary => 'La bibliothèque est vide';

  @override
  String get deleteBook => 'Supprimer le livre';

  @override
  String get deleteBookConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce livre ?';

  @override
  String get bookDeleted => 'Livre supprimé';

  @override
  String get userAgreement => 'Conditions d\'utilisation';

  @override
  String get acceptAgreement => 'J\'ai lu et j\'accepte';

  @override
  String get declineAgreement => 'Refuser';

  @override
  String get statsToday => 'Aujourd\'hui';

  @override
  String get statsThisWeek => 'Cette semaine';

  @override
  String get statsTotal => 'Total';

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
    return '$count livres';
  }

  @override
  String get statsConsecutiveDays => 'Jours consécutifs';

  @override
  String get statsFocusTime => 'Temps de concentration';

  @override
  String get statsThisWeekTotal => 'Total de la semaine';

  @override
  String get statsKeepReading => 'Lisez chaque jour';

  @override
  String get statsMaxSession => 'Session la plus longue';

  @override
  String get statsWeeklyTrend => 'Tendance hebdomadaire';

  @override
  String get statsAchievements => 'Réussites';

  @override
  String get readerToolbarMenu => 'Menu';

  @override
  String get readerToolbarTOC => 'Table des matières';

  @override
  String get readerToolbarSettings => 'Paramètres';

  @override
  String get readerAddBookmark => 'Ajouter un marque-page';

  @override
  String get readerAddNote => 'Ajouter une note';

  @override
  String get readerShare => 'Partager';

  @override
  String get bookmarkAdded => 'Marque-page ajouté';

  @override
  String get bookmarkRemoved => 'Marque-page supprimé';

  @override
  String get readerNavigationTitle => 'Navigation de lecture';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Chapitre $current sur $total';
  }

  @override
  String get readerSearchChapters => 'Rechercher des chapitres';

  @override
  String get readerBackToCurrentChapter => 'Retour au chapitre actuel';

  @override
  String get readerCurrentChapter => 'Actuel';

  @override
  String get readerCurrentPosition => 'Position actuelle';

  @override
  String get readerNoChapterResults => 'Aucun chapitre correspondant';

  @override
  String get readerNoChapterResultsHint =>
      'Essayez un autre mot du titre du chapitre.';

  @override
  String get readerNoBookmarks => 'Aucun marque-page pour le moment';

  @override
  String get readerNoBookmarksHint =>
      'Touchez le bouton marque-page en haut à droite pour conserver votre position.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Ajoutez ce livre à la bibliothèque avant d\'enregistrer des marque-pages';

  @override
  String get themeBlue => 'Bleu océan';

  @override
  String get themeGreen => 'Vert forêt';

  @override
  String get themeOrange => 'Orange vif';

  @override
  String get themeRed => 'Rouge passion';

  @override
  String get themeCustom => 'Personnalisé';

  @override
  String get tapZoneLeftRight => 'Gauche/Droite';

  @override
  String get tapZoneLeftCenterRight => 'Gauche/Centre/Droite';

  @override
  String get homeTagline => 'Lisez en beauté';

  @override
  String get homeReadingStatsTitle => 'Statistiques de lecture';

  @override
  String get homeTodayReadingMoment => 'Moment de lecture du jour';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return '$minutes minutes lues, continuez';
  }

  @override
  String get homeTodayReadingJourneyStart =>
      'Commencez votre voyage de lecture aujourd\'hui';

  @override
  String get homeTodayReadingKeepRhythm =>
      'Vous êtes dans le rythme aujourd\'hui, continuez ainsi';

  @override
  String get homeTodayReadingPrompt =>
      'Gardez un peu de temps pour lire aujourd\'hui';

  @override
  String homeTotalReadingHours(String hours) {
    return '$hours heures de lecture au total';
  }

  @override
  String get homeWeeklyReading => 'Cette semaine';

  @override
  String get homeTotalReading => 'Lecture totale';

  @override
  String get homeLibraryCount => 'Livres de la bibliothèque';

  @override
  String get homeCollectionCount => 'Collection';

  @override
  String get homeKeyMetrics => 'Indicateurs clés';

  @override
  String get homeReadingRhythm => 'Rythme de lecture';

  @override
  String get homeAchievements => 'Réussites de lecture';

  @override
  String get homeConsecutiveReading => 'Lecture consécutive';

  @override
  String get homeConsecutiveReadingDesc =>
      'Gardez une habitude de lecture quotidienne';

  @override
  String get homeFocusDuration => 'Durée de concentration';

  @override
  String get homeFocusDurationDesc => 'Plus longue session de lecture';

  @override
  String get homeWeeklyTotal => 'Total hebdomadaire';

  @override
  String get homeWeeklyTotalDesc => 'Temps de lecture cette semaine';

  @override
  String get homeRecentReading => 'Lecture récente';

  @override
  String get homeWeeklyTrend => 'Tendance de lecture hebdomadaire';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get unitMinute => 'min';

  @override
  String get unitHour => 'heure';

  @override
  String get unitBook => 'livres';

  @override
  String get unitDay => 'jours';

  @override
  String get weekdayMonShort => 'Lun';

  @override
  String get weekdayTueShort => 'Mar';

  @override
  String get weekdayWedShort => 'Mer';

  @override
  String get weekdayThuShort => 'Jeu';

  @override
  String get weekdayFriShort => 'Ven';

  @override
  String get weekdaySatShort => 'Sam';

  @override
  String get weekdaySunShort => 'Dim';

  @override
  String get agreementTagline =>
      'Lecture immersive · Assistant IA · Local d\'abord';

  @override
  String get agreementCardTitle => 'Contrat de service utilisateur';

  @override
  String get agreementCardSubtitle => 'Veuillez lire attentivement ce qui suit';

  @override
  String get agreementWelcomeTitle => 'Bienvenue dans Origo X';

  @override
  String get agreementWelcomeBody =>
      'Pour garantir une expérience de lecture stable et prévisible, veuillez d\'abord lire et accepter le contrat suivant.';

  @override
  String get agreementFeatureFormatsTitle => 'Prise en charge multi-formats';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI et plus';

  @override
  String get agreementFeatureCustomizationTitle => 'Lecture personnalisée';

  @override
  String get agreementFeatureCustomizationBody =>
      'Personnalisez polices, couleurs, typographie et plus encore';

  @override
  String get agreementFeatureSyncTitle => 'Local d\'abord';

  @override
  String get agreementFeatureSyncBody =>
      'Livres, progression et notes restent sur l\'appareil que vous contrôlez';

  @override
  String get agreementFeatureTtsTitle => 'Synthèse vocale';

  @override
  String get agreementFeatureTtsBody =>
      'La narration vocale intelligente libère vos yeux et vous permet d\'écouter partout';

  @override
  String get agreementTapToAgreeHint =>
      'En touchant \"Accepter et continuer\", vous confirmez avoir lu et accepté d\'utiliser cette application';

  @override
  String get agreementExitApp => 'Quitter l\'application';

  @override
  String get agreementAgreeAndContinue => 'Accepter et continuer';

  @override
  String get agreementExitDialogContent =>
      'Si vous n\'acceptez pas les conditions d\'utilisation, vous ne pourrez pas utiliser cette application. Êtes-vous sûr de vouloir quitter ?';

  @override
  String get agreementConfirmExit => 'Quitter';

  @override
  String get readerFileMissing =>
      'Fichier du livre introuvable. Veuillez le réimporter.';

  @override
  String get readerUnsupportedFormat => 'Ce format ne peut pas encore être lu.';

  @override
  String get readerKindleDrmProtected =>
      'Ce livre Kindle est protégé par DRM et ne peut pas être lu ici. Seuls les livres sans DRM sont pris en charge.';

  @override
  String get readerComicNoPages =>
      'Aucune page image n\'a été trouvée dans cette archive de BD.';

  @override
  String get readerComicCbrUnsupported =>
      'Cette BD CBR utilise une vraie compression RAR et n\'est pas encore lisible. Veuillez la convertir en CBZ.';

  @override
  String get readerComicArchiveUnsupported =>
      'Le format d\'archive de cette BD n\'est pas encore lisible. Veuillez la convertir en CBZ.';

  @override
  String get readerComicChapterNoPages =>
      'Ce chapitre ne contient aucune page image.';

  @override
  String get imageReaderSettings => 'Paramètres de lecture';

  @override
  String get imageReaderDirectionTitle => 'Sens de lecture';

  @override
  String get imageReaderDirectionVertical => 'Vertical continu';

  @override
  String get imageReaderDirectionLtr => 'De gauche à droite';

  @override
  String get imageReaderDirectionRtl => 'De droite à gauche (manga)';

  @override
  String get imageReaderJumpToPage => 'Aller à la page';

  @override
  String get imageReaderBackgroundTitle => 'Arrière-plan de la page';

  @override
  String get imageReaderBackgroundBlack => 'Noir';

  @override
  String get imageReaderBackgroundGray => 'Gris';

  @override
  String get imageReaderBackgroundWhite => 'Blanc';

  @override
  String get readerPdfLinuxUnsupported =>
      'La lecture PDF n\'est pas encore disponible sur Linux.';

  @override
  String get bootstrapImageManagerFailed =>
      'Échec de l\'initialisation du gestionnaire d\'images';

  @override
  String homeFocusCompleted(int minutes) {
    return 'Session de concentration de $minutes minutes terminée. Bravo !';
  }

  @override
  String get homeDailyReadingGoal => 'Objectif de lecture quotidien';

  @override
  String get homeAiAdviceSection => 'Conseils de lecture IA';

  @override
  String get homeTodayGlance => 'Aujourd\'hui en un coup d\'œil';

  @override
  String get homeViewAll => 'Tout voir';

  @override
  String get homeGoalDoneSuggestReview =>
      'Objectif du jour atteint — pensez à une révision de lecture';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Encore $minutes minutes pour atteindre l\'objectif du jour';
  }

  @override
  String get homePickBookHint =>
      'Choisissez un livre de votre bibliothèque pour continuer et terminez d\'abord 1 session de concentration.';

  @override
  String homeContinueBookHint(String title) {
    return 'Continuez d\'abord \"$title\", puis passez à d\'autres livres.';
  }

  @override
  String get homeTodayActionAdvice => 'Plan d\'action du jour';

  @override
  String homeProgressPercent(int percent) {
    return '$percent% de progression';
  }

  @override
  String homeStreakDays(int days) {
    return '$days jours de suite';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes min cette semaine';
  }

  @override
  String get homePlanLoading => 'Chargement du plan';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Objectif : $minutes min/jour';
  }

  @override
  String get homeAiAdviceForYou => 'Conseils de lecture IA pour vous';

  @override
  String homeBasedOnBook(String title) {
    return 'D\'après \"$title\"';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Lecture du jour (min)';

  @override
  String get homeTotalReadingMinutesLabel => 'Lecture totale (min)';

  @override
  String get homeGeneratingPlan => 'Génération du plan de lecture du jour...';

  @override
  String get homeCompletedLabel => 'Terminé';

  @override
  String get homeTodayGoalAchieved => 'Objectif du jour atteint';

  @override
  String homeMinutesRemaining(int minutes) {
    return '$minutes minutes restantes';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return 'Lu $read / $goal min';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'Environ $sessions sessions de concentration pour terminer l\'objectif du jour';
  }

  @override
  String get homeStreakLabel => 'Série';

  @override
  String get homeWeekAchievedLabel => 'Objectif hebdo';

  @override
  String get homeFocusLabel => 'Concentration';

  @override
  String homeDaysCount(int days) {
    return '$days jours';
  }

  @override
  String homeTimesCount(int times) {
    return '$times fois';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Compte à rebours de concentration $time';
  }

  @override
  String get homeGoLibraryRead => 'Lire depuis la bibliothèque';

  @override
  String get homeEndFocus => 'Terminer la concentration';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Concentration $minutes min';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Ajuster l\'objectif : $minutes min';
  }

  @override
  String get homeNoRecentReading =>
      'Aucune lecture récente pour le moment. Ouvrez un livre de votre bibliothèque pour commencer.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Progression $percent%';
  }

  @override
  String get librarySearchHint => 'Rechercher par titre ou auteur';

  @override
  String libraryFilterAll(int count) {
    return 'Tous ($count)';
  }

  @override
  String libraryFilterReading(int count) {
    return 'En cours ($count)';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Terminés ($count)';
  }

  @override
  String get libraryFilterTooltip => 'Filtrer par statut de lecture';

  @override
  String get libraryNoMatchingBooks => 'Aucun livre correspondant';

  @override
  String get libraryNoReadingBooks => 'Aucun livre en cours';

  @override
  String get libraryNoFinishedBooks => 'Aucun livre terminé';

  @override
  String get libraryNoBooks => 'Aucun livre pour le moment';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · Continuer la lecture';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Page $page';
  }

  @override
  String get libraryStartFromBeginning => 'Reprendre au début';

  @override
  String get libraryBookInfo => 'Infos du livre';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · $pages pages';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · $chapters chapitres';
  }

  @override
  String get libraryRenameBook => 'Renommer';

  @override
  String get libraryRenameBookHint =>
      'Changez le titre ; le fichier sur le disque est aussi renommé';

  @override
  String get libraryRenameBookSuccess => 'Renommé';

  @override
  String get libraryRenameBookFailed => 'Impossible de renommer le livre';

  @override
  String get libraryCustomCover => 'Couverture personnalisée';

  @override
  String get libraryCustomCoverHint =>
      'Choisissez une image à utiliser comme couverture de ce livre';

  @override
  String get libraryCustomCoverSuccess => 'Couverture mise à jour';

  @override
  String get libraryCoverUnsupportedFormat =>
      'Format d\'image non pris en charge';

  @override
  String get libraryCoverFileTooLarge =>
      'L\'image dépasse la limite de taille de 20 Mo';

  @override
  String get libraryCoverReadFailed =>
      'Impossible de lire l\'image sélectionnée';

  @override
  String get libraryCoverSaveFailed =>
      'Impossible d\'enregistrer la couverture';

  @override
  String get libraryResetCover => 'Rétablir la couverture par défaut';

  @override
  String get libraryResetCoverHint =>
      'Retirer la couverture personnalisée et rétablir l\'originale';

  @override
  String get libraryResetCoverSuccess => 'Couverture par défaut rétablie';

  @override
  String get libraryExportBook => 'Exporter le fichier du livre';

  @override
  String get libraryExportOriginalHint =>
      'Copier le fichier original vers un autre emplacement';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Exporter le livre téléchargé sous forme de fichier TXT généré';

  @override
  String bookExportSuccess(String location) {
    return 'Exporté vers $location';
  }

  @override
  String get bookExportSourceMissing =>
      'Le fichier du livre est introuvable et ne peut pas être exporté';

  @override
  String get bookExportUnsupported =>
      'L\'exportation de livres n\'est pas encore prise en charge sur cette plateforme';

  @override
  String get bookExportFailed => 'Impossible d\'exporter le livre';

  @override
  String get bookExportInProgress => 'Exportation du livre…';

  @override
  String get incomingBooksImporting =>
      'Importation d\'un livre depuis une autre application…';

  @override
  String get incomingBooksNoBookFile =>
      'Le contenu partagé ne contient aucun fichier de livre importable';

  @override
  String get incomingBooksPermissionExpired =>
      'L\'accès au fichier a expiré. Partagez ou rouvrez le fichier';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Ce format de livre n\'est pas pris en charge';

  @override
  String get incomingBooksFileTooLarge =>
      'Le fichier dépasse la limite d\'importation de 500 Mo';

  @override
  String get incomingBooksTooManyFiles =>
      'Trop de fichiers de livres partagés à la fois. Ajoutez-les par lots plus petits';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Certains fichiers n\'ont pas pu être reconnus ; les livres restants continuent';

  @override
  String get incomingBooksContentMismatch =>
      'Le format du fichier ne correspond pas à son contenu';

  @override
  String get incomingBooksImportFailed =>
      'Impossible d\'importer le livre depuis une autre application';

  @override
  String get libraryDeleteBookHint => 'Ce livre sera définitivement supprimé';

  @override
  String get libraryBookTitle => 'Titre';

  @override
  String get libraryFormat => 'Format';

  @override
  String libraryPagesCount(int pages) {
    return '$pages pages';
  }

  @override
  String get totalChapters => 'Chapitres au total';

  @override
  String get currentChapter => 'Chapitre actuel';

  @override
  String libraryChaptersCount(int chapters) {
    return '$chapters chapitres';
  }

  @override
  String get libraryClose => 'Fermer';

  @override
  String get libraryConfirmDeleteTitle => 'Confirmer la suppression';

  @override
  String libraryDeleteBookMessage(String title) {
    return 'Supprimer \"$title\" ? Le fichier sera définitivement retiré de votre appareil.';
  }

  @override
  String libraryDeletingBook(String title) {
    return 'Suppression de \"$title\"...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '\"$title\" supprimé';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get libraryReadingBadge => 'En cours';

  @override
  String get libraryDeletingBookFile => 'Suppression du fichier du livre...';

  @override
  String get libraryDeletingCoverImage =>
      'Suppression de l\'image de couverture...';

  @override
  String get libraryCleaningDatabase =>
      'Nettoyage des enregistrements de la base de données...';

  @override
  String get libraryDeleteComplete => 'Suppression terminée';

  @override
  String get librarySelectMultiple => 'Sélection multiple';

  @override
  String get librarySelectAll => 'Tout sélectionner';

  @override
  String librarySelectedBooks(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String libraryDeleteSelected(int count) {
    return 'Supprimer $count';
  }

  @override
  String get libraryBatchDeleteTitle => 'Supprimer les livres sélectionnés ?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Cette action supprime définitivement les $count livres sélectionnés, les notes et marque-pages associés, et les fichiers locaux. Cela ne peut pas être annulé.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return 'Suppression $done/$total';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return '$count livres supprimés';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return '$success supprimés ; $failed en échec';
  }

  @override
  String get readerPrefaceTitle => 'Préambule';

  @override
  String get readerModeHorizontalPage => 'Sans animation';

  @override
  String get readerModeVerticalScrollHint =>
      'Faites défiler verticalement des pages prépaginées ; balayez latéralement pour changer de chapitre';

  @override
  String get readerModeWholeBookScrollHint =>
      'Les chapitres prépaginés forment une liste verticale positionnable';

  @override
  String get readerScrollByChapterTitle => 'Défilement par chapitre';

  @override
  String get readerScrollByChapterOnHint =>
      'Parcourez un chapitre page par page, puis balayez latéralement pour changer de chapitre';

  @override
  String get readerScrollByChapterOffHint =>
      'Tous les chapitres s\'enchaînent page par page dans une liste verticale positionnable';

  @override
  String get readerModeHorizontalPageHint =>
      'Touchez le côté gauche pour la page précédente, le côté droit pour la page suivante';

  @override
  String get readerModeHorizontalSlideHint =>
      'Les pages suivent votre doigt horizontalement puis se mettent en place';

  @override
  String get readerModeCoverSlide => 'Couverture';

  @override
  String get readerModeCoverSlideHint =>
      'La page actuelle glisse vers la gauche, découvrant la page suivante en dessous';

  @override
  String get readerModePageCurl => 'Curl de page';

  @override
  String get readerModePageCurlHint =>
      'Faites glisser latéralement pour courber la page, puis relâchez pour tourner ou revenir';

  @override
  String get readerTextBrightnessLabel => 'Luminosité du texte';

  @override
  String get readerDimTextInDarkModeTitle => 'Atténuer le texte en mode sombre';

  @override
  String get readerDimTextInDarkModeHint =>
      'Utiliser 70% de luminosité en mode sombre';

  @override
  String readerFontSizeValue(int size) {
    return 'Taille de police  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Marge horizontale  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Marge horizontale';

  @override
  String get readerTopMarginLabel => 'Marge supérieure';

  @override
  String get readerBottomMarginLabel => 'Marge inférieure';

  @override
  String get readerTxtChapterTitlePageTitle =>
      'Titre de chapitre sur sa propre page';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Désactivé, le titre du chapitre apparaît au-dessus du corps du texte';

  @override
  String get readerVerticalMarginLabel => 'Marge verticale';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Marge verticale  $margin';
  }

  @override
  String readerChapterCount(int count) {
    return '$count chapitres';
  }

  @override
  String readerChapterFallback(int number) {
    return 'Chapitre $number';
  }

  @override
  String readerOpenFailed(String error) {
    return 'Échec de l\'ouverture : $error';
  }

  @override
  String get readerNoContent => 'Ce livre n\'a aucun contenu lisible';

  @override
  String readerStatusPaged(
    int chapter,
    int chapterCount,
    int page,
    int pageCount,
  ) {
    return 'Chapitre $chapter/$chapterCount · Page $page/$pageCount';
  }

  @override
  String readerStatusScroll(int chapter, int chapterCount) {
    return 'Chapitre $chapter/$chapterCount · Défilement vertical';
  }

  @override
  String get importPreparing => 'Préparation de l\'importation...';

  @override
  String importFailedWithError(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get importLocalFile => 'Fichiers locaux';

  @override
  String get settingsAiTempHintMinimax =>
      'Température : MiniMax recommande 0,01 ~ 1,00';

  @override
  String get settingsAiCustomConfigTitle => 'Configuration IA personnalisée';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Fournisseur actuel : $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'La température MiniMax doit être comprise entre 0,01 et 1,00';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'La température est hors limites, veuillez suivre l\'indication';

  @override
  String get settingsApply => 'Appliquer';

  @override
  String get settingsAiCustomApplied =>
      'Paramètres personnalisés appliqués, pensez à enregistrer la configuration';

  @override
  String get settingsAiApiKeyRequired => 'La clé API ne peut pas être vide';

  @override
  String get settingsAiModelRequired => 'Le modèle ne peut pas être vide';

  @override
  String get settingsAiBaseUrlInvalid =>
      'L\'URL de base doit être une adresse http/https valide';

  @override
  String get settingsAiSettingsSaved => 'Paramètres IA enregistrés';

  @override
  String settingsSaveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle =>
      'Tourner les pages avec les boutons de volume';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Utilisez les boutons de volume dans les modes de lecture paginés';

  @override
  String get settingsAutoResumeReadingTitle =>
      'Reprendre la lecture au lancement';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Si vous quittez l\'application en lisant, le prochain lancement revient là où vous vous étiez arrêté';

  @override
  String get settingsShowStatusBarTitle =>
      'Afficher la barre d\'état système pendant la lecture';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Interface batterie/heure du lecteur masquée';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Utilisation de l\'interface batterie/heure du lecteur';

  @override
  String get readerTopBarStyleTitle => 'Informations en haut';

  @override
  String get readerTopBarStyleSystem => 'Barre d\'état système';

  @override
  String get readerTopBarStyleSystemHint =>
      'Afficher l\'heure, le signal et la batterie du système';

  @override
  String get readerTopBarStyleReader => 'Barre d\'informations du lecteur';

  @override
  String get readerTopBarStyleReaderHint =>
      'Afficher l\'heure, le titre du chapitre et la batterie';

  @override
  String get readerTopBarStyleFloating => 'Barre d\'infos flottante';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Afficher l\'heure et la batterie dans la zone de la barre d\'état sans prendre d\'espace de lecture';

  @override
  String get readerTopBarStyleHidden => 'Pleinement immersif';

  @override
  String get readerTopBarStyleHiddenHint => 'Ne rien afficher en haut';

  @override
  String get settingsAiAssistantTitle => 'Assistant de lecture IA';

  @override
  String get settingsSystemSettingsTitle => 'Paramètres système';

  @override
  String get settingsSectionAppearanceFonts => 'Apparence et polices';

  @override
  String get settingsSectionDataServices => 'Données et services';

  @override
  String get settingsSectionGeneral => 'Général';

  @override
  String get settingsSectionAdvancedFeatures => 'Fonctionnalités avancées';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Plus de protocoles de sources';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Activez la prise en charge de protocoles de sources supplémentaires.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Autoriser les sources en réseau privé';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Autorise les sources à accéder à cet appareil, au réseau local et à d\'autres adresses privées. Activé par défaut avec Premium ; utilisez uniquement des sources fiables.';

  @override
  String get additionalSourcesImport =>
      'Importer plus de protocoles de sources';

  @override
  String get additionalSourcesImportTitle => 'Importer un JSON de sources';

  @override
  String get additionalSourcesImportNotice =>
      'L\'importation analyse et déduplique uniquement en local ; elle ne sonde pas chaque source en ligne. Les sources avec des règles appelables conservent leur état activé à l\'import, et chaque capacité est vérifiée lors de l\'utilisation.';

  @override
  String get additionalSourcesChooseFile => 'Ajouter depuis un fichier JSON';

  @override
  String get additionalSourcesUrlLabel => 'URL du JSON de sources';

  @override
  String get additionalSourcesLoadUrl => 'Charger l\'URL';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return '$supported disponibles, $partial partiellement prises en charge, $unsupported non prises en charge';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return '$supported règles standard, $partial règles étendues, $unsupported règles avancées, $skipped ignorées';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return '$count sources prêtes à importer, $skipped ignorées';
  }

  @override
  String get additionalSourcesAvailable => 'Disponible';

  @override
  String get additionalSourcesPartial => 'Partiellement pris en charge';

  @override
  String get additionalSourcesUnsupported => 'Non pris en charge';

  @override
  String get additionalSourcesImportConfirm => 'Tout importer';

  @override
  String additionalSourcesImported(int count) {
    return '$count sources importées';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return '$count sources importées ; $conflicted ignorées car leur identifiant est déjà enregistré depuis une autre origine';
  }

  @override
  String get settingsSectionAboutSupport => 'À propos et assistance';

  @override
  String get settingsKeepScreenOnTitle => 'Garder l\'écran allumé';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Empêcher l\'extinction de l\'écran pendant la lecture';

  @override
  String get settingsPowerSavingModeTitle => 'Mode économie d\'énergie';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Limiter l\'application à 60 fps au lieu d\'utiliser un taux de rafraîchissement élevé';

  @override
  String get settingsAutoSaveTitle => 'Enregistrement automatique';

  @override
  String get settingsAutoSaveSubtitle =>
      'Enregistrer automatiquement la progression de lecture';

  @override
  String get settingsHelpPlaceholder =>
      'Les informations d\'aide peuvent aller ici';

  @override
  String get settingsAiConfigured => 'IA configurée';

  @override
  String get settingsAiNotConfigured => 'Clé API non configurée';

  @override
  String get settingsAiReadyToUse => 'Prête à l\'emploi';

  @override
  String get settingsAiPendingConfig => 'Configuration en attente';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Préréglage actuel : $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Configuration actuelle : personnalisée · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'Les fournisseurs et modèles courants sont intégrés ; en général, choisissez simplement un préréglage et saisissez une clé API.';

  @override
  String get settingsAiProviderLabel => 'Fournisseur';

  @override
  String get settingsAiCustomProvider => 'Personnalisé';

  @override
  String get settingsAiProtocolLabel => 'Protocole API';

  @override
  String get settingsAiProtocolOpenAi => 'Compatible OpenAI';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Sélectionnez un modèle prédéfini';

  @override
  String get settingsAiPresetLabel => 'Modèle prédéfini';

  @override
  String get settingsAiCustomButton => 'Personnalisé';

  @override
  String get settingsAiPresetSelectedHint =>
      'Après avoir sélectionné un préréglage, saisissez simplement une clé API pour commencer à l\'utiliser.';

  @override
  String get settingsAiCustomActiveHint =>
      'Des paramètres personnalisés sont en cours d\'utilisation ; vous pouvez revenir à un préréglage à tout moment.';

  @override
  String get settingsAiApiKeyHint =>
      'Saisissez pour activer le préréglage actuel';

  @override
  String get settingsShow => 'Afficher';

  @override
  String get settingsHide => 'Masquer';

  @override
  String get settingsAiSaving => 'Enregistrement...';

  @override
  String get settingsAiSaveConfig => 'Enregistrer la configuration IA';

  @override
  String get settingsPageIntro =>
      'Seulement les options qui façonnent votre expérience de lecture.';

  @override
  String get settingsSupportDevelopmentTitle => 'Soutenir le développement';

  @override
  String get firstHomeSupportNow => 'Soutenir maintenant';

  @override
  String get firstHomeSupportLater => 'Peut-être plus tard';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Une lettre du développeur d\'Origo X demandant un soutien volontaire';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Soutenir le développement';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'Les dons sont volontaires et soutiennent le développement en cours.';

  @override
  String get settingsAccountGuestTitle => 'Se connecter à Origo X';

  @override
  String get settingsAccountGuestSubtitle =>
      'Synchronisez votre profil et vos paramètres de sécurité.';

  @override
  String get settingsAccountOpen => 'Centre de compte';

  @override
  String get settingsAccountVerified => 'Compte vérifié';

  @override
  String get accountPageTitle => 'Compte';

  @override
  String get accountIntroTitle => 'Compte';

  @override
  String get accountPageSubtitle =>
      'Connectez-vous pour synchroniser votre profil et vos paramètres de compte.';

  @override
  String get accountLoginTab => 'Connexion par e-mail';

  @override
  String get accountRegisterTab => 'S\'inscrire';

  @override
  String get accountCodeTab => 'Code e-mail';

  @override
  String get accountResetTab => 'Réinitialiser';

  @override
  String get accountEmail => 'E-mail';

  @override
  String get accountEmailRequired => 'Saisissez votre adresse e-mail';

  @override
  String get accountEmailFirstHint =>
      'Saisissez votre e-mail pour continuer. La connexion par mot de passe est le mode par défaut.';

  @override
  String get accountContinue => 'Continuer';

  @override
  String get accountPasswordLoginTitle => 'Connexion avec mot de passe';

  @override
  String get accountPasswordLoginHint =>
      'Saisissez votre mot de passe ou utilisez plutôt un code e-mail.';

  @override
  String get accountUseEmailCode => 'Se connecter avec un code e-mail';

  @override
  String get accountNoAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get accountForgotPassword => 'Mot de passe oublié';

  @override
  String get accountHaveAccount => 'Déjà inscrit ? Retour à la connexion';

  @override
  String get accountBackToPassword => 'Retour à la connexion par mot de passe';

  @override
  String get accountChangeEmail => 'Changer';

  @override
  String get accountRegisterHint =>
      'Vérifiez votre e-mail, puis créez un compte et un mot de passe.';

  @override
  String get accountCodeLoginHint =>
      'Nous enverrons un code à l\'e-mail sélectionné.';

  @override
  String get accountResetHint =>
      'Vérifiez votre e-mail, puis choisissez un nouveau mot de passe.';

  @override
  String get accountPassword => 'Mot de passe';

  @override
  String get accountConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountAvatarCropTitle => 'Recadrer l\'avatar';

  @override
  String get accountAvatarCropHint =>
      'Faites glisser pour repositionner et pincez pour zoomer jusqu\'à ce que le sujet tienne dans le cercle.';

  @override
  String get accountUsername => 'Nom d\'utilisateur';

  @override
  String get accountDisplayName => 'Nom affiché';

  @override
  String get accountVerificationCode => 'Code de vérification';

  @override
  String get accountSendCode => 'Envoyer le code';

  @override
  String get accountSignIn => 'Se connecter';

  @override
  String get accountCreate => 'Créer un compte';

  @override
  String get accountResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get accountUseApple => 'Se connecter avec Apple';

  @override
  String get accountUseGithub => 'Connexion GitHub';

  @override
  String get accountUseGoogle => 'Continuer avec Google';

  @override
  String get accountUsePasskey => 'Continuer avec Passkey';

  @override
  String get accountMoreSignInMethods => 'Plus de méthodes de connexion';

  @override
  String get accountExternalHint =>
      'Un navigateur sécurisé va s\'ouvrir. Revenez ici après approbation.';

  @override
  String get accountProfileTitle => 'Profil';

  @override
  String get accountEditProfile => 'Modifier le profil';

  @override
  String get accountSignInMethodsTitle => 'Méthodes de connexion';

  @override
  String get accountSaveProfile => 'Enregistrer le profil';

  @override
  String get accountChangeAvatar => 'Changer d\'avatar';

  @override
  String get accountRemoveAvatar => 'Supprimer l\'avatar';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountSupportTitle => 'Abonnement Premium';

  @override
  String get accountSupportFreeSubtitle =>
      'Les fonctions de lecture de base sont gratuites.';

  @override
  String get accountSupportAction => 'Obtenir Premium';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Au moins 12 caractères';

  @override
  String get accountUsernameHint =>
      '3–30 lettres minuscules, chiffres ou traits de soulignement';

  @override
  String get settingsDonationAction => 'Faire un don avec WeChat';

  @override
  String get settingsAlipayDonationAction => 'Faire un don avec Alipay';

  @override
  String get settingsDonationDialogTitle => 'Don WeChat';

  @override
  String get settingsDonationDialogHint =>
      'Scannez le code QR avec WeChat pour soutenir le développement continu. Merci.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Don Alipay';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Scannez le code QR avec Alipay pour soutenir le développement continu. Merci.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'Les dons sont entièrement facultatifs. Ils ne débloquent aucune fonction et ne constituent ni un achat ni un contrat de service.';

  @override
  String get settingsDonationQrCodeLabel => 'Code QR de don WeChat';

  @override
  String get settingsAlipayDonationQrCodeLabel => 'Code QR de don Alipay';

  @override
  String get settingsAiSwipeHint =>
      'Balayez les modèles, touchez pour changer, appuyez longuement pour modifier ou supprimer.';

  @override
  String get settingsAiLegacyIntro =>
      'Choisissez un fournisseur et un modèle, puis saisissez votre clé API.';

  @override
  String get settingsAiModelLabel => 'Modèle';

  @override
  String get settingsAiUsingCustomParams =>
      'Utilisation de paramètres de modèle personnalisés';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Stockée uniquement sur cet appareil';

  @override
  String get settingsAiSaveAndEnable => 'Enregistrer et activer';

  @override
  String get settingsAboutTagline =>
      'Multiplateforme, concentré sur la lecture';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get changelogHistoryTitle => 'Historique des versions';

  @override
  String get changelogHistorySubtitle =>
      'Consultez les changements de chaque version';

  @override
  String get openSourceLicensesTitle => 'Licences open-source et polices';

  @override
  String get openSourceLicensesSubtitle =>
      'Consultez les licences de l\'application, des polices incluses et des logiciels tiers';

  @override
  String get openSourceLicensesIntro =>
      'Ces textes de licence et mentions sont disponibles hors ligne dans l\'application. Origo X, les polices à la demande et les logiciels tiers restent soumis à leurs licences respectives.';

  @override
  String get openSourceProjectSection => 'Licences du projet';

  @override
  String get openSourceLegacyLicenseTitle => 'Versions antérieures';

  @override
  String get openSourceFontsSection => 'Licences de polices';

  @override
  String get openSourceDependenciesSection => 'Logiciels tiers';

  @override
  String get openSourceDependenciesTitle => 'Dépendances Flutter et Dart';

  @override
  String get openSourceDependenciesSubtitle =>
      'Consultez les licences tierces collectées automatiquement par Flutter';

  @override
  String get openSourceLicenseLegalese =>
      'Origo X et les composants tiers restent soumis à leurs licences respectives.';

  @override
  String get openSourceLicenseLoadFailed =>
      'Impossible de charger le texte de licence.';

  @override
  String get changelogPageTitle => 'Historique des versions';

  @override
  String get changelogCurrentVersion => 'Version actuelle';

  @override
  String get changelogLoadFailed =>
      'Impossible de charger l\'historique des versions';

  @override
  String get settingsMaintainerLabel => 'Mainteneur';

  @override
  String get settingsLicenseLabel => 'Licence';

  @override
  String get settingsViewSourceSubtitle => 'Voir le projet open-source';

  @override
  String get settingsJoinQqGroup => 'Rejoindre le groupe QQ';

  @override
  String get settingsQqOpenFailed =>
      'Impossible d\'ouvrir QQ. Vérifiez que QQ est installé.';

  @override
  String get settingsDarkModeTitle => 'Mode nuit';

  @override
  String settingsCurrentValue(String value) {
    return 'Actuel : $value';
  }

  @override
  String get settingsUiStyleTitle => 'Effet verre';

  @override
  String get settingsGlassEffectSubtitle =>
      'Utiliser des surfaces translucides, un flou d\'arrière-plan et une profondeur flottante';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Masquer les libellés de la barre de navigation inférieure';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'Afficher uniquement les icônes dans la barre de navigation inférieure mobile';

  @override
  String get settingsFloatingNavigationTitle => 'Barre de navigation flottante';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Ajustez la taille, le style d\'affichage et l\'ordre des destinations';

  @override
  String get floatingNavigationPreviewTitle => 'Aperçu';

  @override
  String get floatingNavigationSizeTitle => 'Taille';

  @override
  String get floatingNavigationSizeAutomatic => 'Automatique';

  @override
  String get floatingNavigationSizeCustom => 'Personnalisée';

  @override
  String get floatingNavigationHeightLabel => 'Hauteur';

  @override
  String get floatingNavigationSideMarginLabel => 'Marge latérale';

  @override
  String get floatingNavigationDisplayModeTitle => 'Style d\'affichage';

  @override
  String get floatingNavigationIconsOnly => 'Icônes seules';

  @override
  String get floatingNavigationIconsAndLabels => 'Icônes et libellés';

  @override
  String get floatingNavigationOrderTitle => 'Ordre de navigation';

  @override
  String get floatingNavigationOrderHint =>
      'Maintenez la poignée à droite pour réordonner';

  @override
  String get floatingNavigationSyncHint =>
      'L\'ordre s\'applique aussi à la navigation par balayage et à la barre latérale grand écran';

  @override
  String get floatingNavigationResetOrder => 'Rétablir l\'ordre par défaut';

  @override
  String get floatingNavigationResetDone => 'Ordre par défaut rétabli';

  @override
  String get settingsLibraryLayoutTitle => 'Paramètres de la bibliothèque';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Ajustez la disposition de la bibliothèque et l\'expérience d\'ouverture des livres';

  @override
  String get settingsLibraryLayoutCard => 'Cartes';

  @override
  String get settingsLibraryLayoutGrid => 'Grille';

  @override
  String get settingsLibraryGridColumnsTitle =>
      'Couvertures par ligne sur téléphone';

  @override
  String get settingsLibraryGridTwoColumns => '2 colonnes';

  @override
  String get settingsLibraryGridThreeColumns => '3 colonnes';

  @override
  String get settingsLibraryGridShowDetailsTitle =>
      'Afficher le titre et la progression';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Ajouter une ligne de titre et une barre de progression compacte sous chaque couverture';

  @override
  String get settingsLibraryOpenAnimationTitle =>
      'Animation d\'ouverture du livre';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Utilisée uniquement à l\'ouverture d\'un livre depuis la bibliothèque';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Agrandissement de couverture classique';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Agrandir la couverture d\'origine en plein écran avant de révéler le lecteur';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Fondu minimal';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Faire apparaître le texte en fondu sans mouvement directionnel';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Montée du papier';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'La feuille de lecture se pose doucement en place depuis le bas';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Glissement de page';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'La page de lecture entre par un bref mouvement latéral';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Rythme d\'animation';

  @override
  String get settingsLibraryOpenAnimationFast => 'Rapide';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Fondu rapide dès que le texte est prêt';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Élégant';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Révéler le texte plus progressivement pour une transition plus calme';

  @override
  String get settingsAccentFollowTheme =>
      'Couleur d\'accentuation : suivre le thème';

  @override
  String settingsAccentValue(String name) {
    return 'Couleur d\'accentuation : $name';
  }

  @override
  String get settingsAppThemeTitle => 'Thème de l\'application';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Actuel : $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'Suivre le thème de l\'application';

  @override
  String get settingsAccentColorTitle => 'Couleur d\'accentuation';

  @override
  String get settingsThemeModeSystemHint =>
      'Changer automatiquement selon l\'apparence du système';

  @override
  String get settingsThemeModeLightHint =>
      'Toujours utiliser l\'apparence claire';

  @override
  String get settingsThemeModeDarkHint =>
      'Toujours utiliser l\'apparence sombre';

  @override
  String get settingsSelectAppTheme => 'Choisir le thème de l\'application';

  @override
  String get settingsDone => 'Terminé';

  @override
  String get settingsAccentColorAdvice =>
      'La couleur d\'accentuation génère les jeux de couleurs Material 3 complets en clair et en sombre.';

  @override
  String get settingsAccentPresetColors => 'Couleurs rapides';

  @override
  String get settingsAccentCustomColor => 'Couleur personnalisée';

  @override
  String get settingsAccentSaturationBrightness =>
      'Champ saturation et luminosité';

  @override
  String get settingsAccentHue => 'Teinte';

  @override
  String get settingsAccentPreview => 'Aperçu de la palette du thème';

  @override
  String get settingsAccentFollowThemeOption => 'Suivre le thème';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Utiliser la couleur d\'accentuation par défaut du thème d\'application actuel';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Mainteneur : 小元Niki';

  @override
  String get settingsGithubRepo => 'Dépôt GitHub';

  @override
  String get settingsNewYearGreeting =>
      'Un lecteur multiplateforme, concentré, sobre et librement modifiable.';

  @override
  String get settingsGithubOpenFailed => 'Impossible d\'ouvrir le lien GitHub';

  @override
  String get settingsOfficialWebsite => 'Site officiel';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Téléchargez et installez depuis open.xxread.top';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'Impossible d\'ouvrir le site officiel';

  @override
  String get updateCheckNow => 'Rechercher des mises à jour';

  @override
  String get updateCheckNowSubtitle =>
      'Obtenez la dernière version depuis GitHub ou le site officiel';

  @override
  String get updateAppStoreManaged =>
      'Cette version du Mac App Store se met à jour via l\'App Store';

  @override
  String get updateAvailableTitle => 'Une nouvelle version est disponible';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Version actuelle : $currentVersion\nVersion la plus récente : $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Nouveautés';

  @override
  String get updateNotesEmpty =>
      'Aucune note de version n\'a été fournie pour cette version.';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateSkipVersion => 'Ignorer cette version';

  @override
  String get updateGoToDownload => 'Aller à la mise à jour';

  @override
  String get updateFromGithub => 'Mettre à jour depuis GitHub';

  @override
  String get updateFromWebsite => 'Ouvrir le site officiel';

  @override
  String get updateFromWebsiteInstall => 'Télécharger depuis le site';

  @override
  String get updateWebsiteUnavailable =>
      'Le paquet du site officiel n\'est pas encore disponible pour cet appareil';

  @override
  String get updateDownloadingTitle => 'Téléchargement de la mise à jour';

  @override
  String updateDownloadProgress(int percent) {
    return 'Téléchargé à $percent%';
  }

  @override
  String get updatePreparingInstaller =>
      'Vérification du paquet et préparation du programme d\'installation système…';

  @override
  String get updateDownloadFailed =>
      'Impossible de télécharger la mise à jour depuis le site officiel';

  @override
  String get updateIntegrityFailed =>
      'La mise à jour téléchargée a échoué à sa vérification d\'intégrité et a été supprimée';

  @override
  String get updateInstallFailed =>
      'Le paquet de mise à jour n\'a pas pu être installé. Vérifiez les autorisations d\'installation et réessayez.';

  @override
  String get updateAlreadyLatest => 'Vous utilisez déjà la dernière version';

  @override
  String get updateCheckFailed =>
      'Impossible de rechercher des mises à jour. Veuillez réessayer plus tard.';

  @override
  String get updateOpenFailed => 'Impossible d\'ouvrir le lien';

  @override
  String get settingsIosOnlyFeature =>
      'Cette fonctionnalité est uniquement disponible sur iOS';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Synchronisé vers $storage\n$books livres, $files fichiers copiés';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Ce changement de paramètre nécessite un redémarrage de l\'application pour prendre pleinement effet.';

  @override
  String get settingsRestartRequiredTitle => 'Redémarrage requis';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\nRedémarrer l\'application maintenant ?';
  }

  @override
  String get settingsRestartLater => 'Plus tard';

  @override
  String get settingsRestartNow => 'Redémarrer';

  @override
  String get statsDetailedTitle => 'Statistiques détaillées';

  @override
  String get statsRange7Days => '7 jours';

  @override
  String get statsRange30Days => '30 jours';

  @override
  String get statsRange90Days => '90 jours';

  @override
  String get statsRange1Year => '1 an';

  @override
  String get statsRangeAll => 'Tout';

  @override
  String get statsTabOverview => 'Aperçu';

  @override
  String get statsTabCharts => 'Graphiques';

  @override
  String get statsTabBooks => 'Livres';

  @override
  String get statsTabAchievements => 'Réussites';

  @override
  String get statsReadingOverview => 'Aperçu de lecture';

  @override
  String statsCumulativeHours(Object hours) {
    return '$hours heures au total';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Gardez le rythme — vous avez lu $days jours d\'affilée';
  }

  @override
  String get statsTotalDuration => 'Durée totale';

  @override
  String get statsAvgSession => 'Session moyenne';

  @override
  String statsDaysCount(Object count) {
    return '$count jours';
  }

  @override
  String get statsNoData => 'Aucune donnée';

  @override
  String get statsPeriodEarlyMorning => 'Tôt le matin 05:00-08:59';

  @override
  String get statsPeriodMorning => 'Matin 09:00-11:59';

  @override
  String get statsPeriodAfternoon => 'Après-midi 12:00-17:59';

  @override
  String get statsPeriodEvening => 'Soirée 18:00-21:59';

  @override
  String get statsPeriodLateNight => 'Nuit 22:00-04:59';

  @override
  String get statsTotalReadingTime => 'Temps de lecture total';

  @override
  String get statsTotalPagesRead => 'Pages lues au total';

  @override
  String get statsBooksReadCount => 'Livres lus';

  @override
  String get statsUnitPage => 'pages';

  @override
  String get statsTodayProgress => 'Progression de lecture du jour';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target min';
  }

  @override
  String get statsPagesRead => 'Pages lues';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target pages';
  }

  @override
  String get statsReadingHabits => 'Habitudes de lecture';

  @override
  String get statsBestReadingPeriod => 'Meilleur moment de lecture';

  @override
  String get statsAvgSessionReading => 'Session de lecture moyenne';

  @override
  String get statsMaxStreakDays => 'Plus longue série';

  @override
  String get statsFocusScore => 'Concentration de lecture';

  @override
  String get statsBookCount => 'Nombre de livres';

  @override
  String get statsTrendAnalysis => 'Analyse de la tendance de lecture';

  @override
  String statsAxisMinutes(Object value) {
    return '$value min';
  }

  @override
  String statsAxisPages(Object value) {
    return '$value p.';
  }

  @override
  String statsAxisBooks(Object value) {
    return '$value liv.';
  }

  @override
  String statsAxisHour(Object hour) {
    return '${hour}h';
  }

  @override
  String get statsTimeDistribution => 'Répartition du temps de lecture';

  @override
  String get statsFormatDistribution => 'Répartition des formats de livres';

  @override
  String get statsCompleted => 'Terminés';

  @override
  String get statsInProgress => 'En cours';

  @override
  String get statsDurationRanking => 'Classement par temps de lecture';

  @override
  String get statsProgressRanking => 'Classement par progression de lecture';

  @override
  String statsPagesCount(Object count) {
    return '$count pages';
  }

  @override
  String statsSessionCount(Object count) {
    return '$count sessions';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return '$achieved réussites obtenues, $remaining encore à débloquer';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Première lecture';

  @override
  String get statsAchievementFirstReadDesc =>
      'Terminez votre première session de lecture';

  @override
  String get statsAchievementNoviceTitle => 'Novice de lecture';

  @override
  String get statsAchievementNoviceDesc => 'Lisez pour un total de 10 heures';

  @override
  String get statsAchievementBookwormTitle => 'Rat de bibliothèque';

  @override
  String get statsAchievementBookwormDesc =>
      'Lisez pour un total de 100 heures';

  @override
  String get statsAchievementExpertTitle => 'Expert de lecture';

  @override
  String get statsAchievementExpertDesc => 'Lisez 7 jours d\'affilée';

  @override
  String get statsAchievementOceanTitle => 'Océan de connaissances';

  @override
  String get statsAchievementOceanDesc => 'Lisez 10 000 pages';

  @override
  String get statsAchievementScholarTitle => 'Polymathe';

  @override
  String get statsAchievementScholarDesc => 'Lisez 10 livres différents';

  @override
  String get statsAchievementMarathonTitle => 'Marathon de lecture';

  @override
  String get statsAchievementMarathonDesc => 'Lisez 30 jours d\'affilée';

  @override
  String get statsAchievementFocusTitle => 'Maître de concentration';

  @override
  String get statsAchievementFocusDesc => 'Lisez pour un total de 500 heures';

  @override
  String statsProgressPercent(Object percent) {
    return 'Progression : $percent%';
  }

  @override
  String get statsGoalProgress => 'Progression de l\'objectif de lecture';

  @override
  String get statsMonthlyReadingTime => 'Temps de lecture ce mois-ci';

  @override
  String get statsWeeklyReadingTime => 'Temps de lecture cette semaine';

  @override
  String get statsAvgDailyPages7d =>
      'Moyenne de pages par jour (7 derniers jours)';

  @override
  String statsHoursCount(Object count) {
    return '$count heures';
  }

  @override
  String get statsSpeedTrend => 'Tendance de vitesse de lecture';

  @override
  String statsAvgSpeed(Object speed) {
    return 'Moy. : $speed pages/min';
  }

  @override
  String get statsReadingContinuity => 'Régularité de lecture';

  @override
  String statsCurrentStreak(Object days) {
    return 'Série actuelle : $days jours';
  }

  @override
  String get statsHeatmapLess => 'Moins';

  @override
  String get statsHeatmapMore => 'Plus';

  @override
  String statsWeekNumber(Object week) {
    return 'Semaine $week';
  }

  @override
  String get bookSourceAddToShelf => 'Ajouter à la bibliothèque';

  @override
  String get bookSourceAddOnline => 'Ajouter en ligne';

  @override
  String get bookSourceAddOnlineHint =>
      'Lisez depuis la source et mettez les chapitres en cache au fil de la lecture';

  @override
  String get bookSourceDownloadLocal => 'Télécharger localement';

  @override
  String get bookSourceDownloadLocalHint =>
      'Téléchargez chaque chapitre et ajoutez une copie TXT locale';

  @override
  String get bookSourceAddedOnline =>
      'Ajouté à la bibliothèque comme livre en ligne';

  @override
  String get bookSourceAlreadyOnShelf =>
      'Ce livre est déjà dans votre bibliothèque';

  @override
  String get bookSourceDownloading => 'Téléchargement local en cours';

  @override
  String get bookSourceFetchingCatalog =>
      'Récupération du catalogue des chapitres…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return '$completed/$total chapitres';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Téléchargement terminé et ajouté à la bibliothèque locale';

  @override
  String get bookSourceDownloadConverted =>
      'Téléchargement terminé. C\'est maintenant un livre local';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get downloadTasksTitle => 'Téléchargements';

  @override
  String get downloadTasksEmpty => 'Aucune tâche de téléchargement';

  @override
  String get downloadTaskQueued => 'En attente de téléchargement';

  @override
  String get downloadTaskDownloading => 'Téléchargement en arrière-plan';

  @override
  String get downloadTaskCompleted => 'Téléchargement terminé';

  @override
  String get downloadTaskFailed => 'Échec du téléchargement';

  @override
  String get downloadTaskCancelled => 'Annulé';

  @override
  String get downloadTaskCancel => 'Annuler la tâche';

  @override
  String get downloadContinueInBackground => 'Continuer en arrière-plan';

  @override
  String get downloadRunningInBackground =>
      'Le téléchargement continue en arrière-plan';

  @override
  String get bookSourceExitAddTitle => 'Ajouter à la bibliothèque ?';

  @override
  String bookSourceExitAddMessage(String title) {
    return 'Ajouter \"$title\" à votre bibliothèque comme livre en ligne ? Votre progression de lecture sera conservée.';
  }

  @override
  String get bookSourceNotNow => 'Pas maintenant';

  @override
  String get bookSourceOnlineBadge => 'En ligne';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'Les données du livre en ligne sont invalides : $error';
  }

  @override
  String get readerThemeTitle => 'Thème de lecture';

  @override
  String get readerThemeDescription =>
      'Ne modifie que la page de lecture et ses commandes';

  @override
  String get readerSettingsTabTheme => 'Thème';

  @override
  String get readerSettingsTabText => 'Texte';

  @override
  String get readerSettingsTabLayout => 'Disposition';

  @override
  String get readerSettingsTabPaging => 'Pagination';

  @override
  String get readerSettingsAdvancedTypography => 'Typographie avancée';

  @override
  String get readerAutoPageTurnTitle => 'Tourne-page automatique';

  @override
  String get readerAutoPageTurnOff => 'Non démarré';

  @override
  String get readerAutoPageTurnShortcutTitle =>
      'Raccourci de lecture automatique';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Afficher avec les commandes de lecture pour démarrer ou mettre en pause rapidement';

  @override
  String get readerAutoPageTurnHint =>
      'Avance d\'un écran à l\'intervalle choisi, y compris en mode pagination verticale.';

  @override
  String get readerAutoPageTurnModeTimed => 'Tourne-page minuté';

  @override
  String get readerAutoPageTurnModeSweep => 'Tourne-page par balayage';

  @override
  String get readerAutoPageTurnModeContinuous => 'Défilement continu';

  @override
  String get readerAutoPageTurnModeInterval => 'Défilement par intervalle';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Attend l\'intervalle choisi, puis passe à la page suivante.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Une ligne balaie vers le bas, révélant progressivement la page suivante au-dessus d\'elle.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Défile vers le bas en continu à une vitesse de lecture régulière.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Attend l\'intervalle choisi, puis fait défiler vers le bas d\'environ un écran.';

  @override
  String get readerAutoPageTurnSweepDurationLabel => 'Durée du balayage';

  @override
  String get readerAutoPageTurnScrollSpeedLabel => 'Vitesse de défilement';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds secondes par écran';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · ${seconds}s/écran';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'En pause · $mode · ${seconds}s/écran';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Intervalle de page';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds secondes par écran';
  }

  @override
  String get readerAutoPageTurnStart => 'Démarrer le tourne-page automatique';

  @override
  String get readerAutoPageTurnResume => 'Reprendre le tourne-page automatique';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Auto · ${seconds}s/écran';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'En pause · ${seconds}s/écran';
  }

  @override
  String get readerThemeDay => 'Jour';

  @override
  String get readerThemeFollowSystem => 'Suivre le système';

  @override
  String get readerThemeMist => 'Brume';

  @override
  String get readerThemeGreen => 'Confort des yeux';

  @override
  String get readerThemeRose => 'Rose';

  @override
  String get readerThemeNavy => 'Bleu profond';

  @override
  String get readerThemeNight => 'Nuit';

  @override
  String get readerThemePureBlack => 'Noir pur';

  @override
  String get readerThemeParchment => 'Parchemin';

  @override
  String get readerThemeCustom => 'Personnalisé';

  @override
  String get readerPullBookmarkTitle => 'Marque-page déroulant';

  @override
  String get readerPullBookmarkHint =>
      'Tirez depuis le bord supérieur et relâchez pour ajouter ou retirer un marque-page sur cette page';

  @override
  String get readerPullBookmarkAddHint =>
      'Tirez plus loin pour ajouter le marque-page';

  @override
  String get readerPullBookmarkRemoveHint =>
      'Tirez plus loin pour retirer le marque-page';

  @override
  String get readerPullBookmarkReleaseHint => 'Relâchez pour terminer';

  @override
  String get readerTapAnimationTitle => 'Animation tactile';

  @override
  String get readerTapAnimationHint =>
      'Utiliser l\'animation de changement de page actuelle pour les touches latérales ; désactiver pour un rafraîchissement instantané';

  @override
  String get readerTabletTwoPageTitle => 'Disposition deux pages sur tablette';

  @override
  String get readerTabletTwoPageHint =>
      'Afficher les pages gauche et droite côte à côte en paysage ; désactiver pour toujours utiliser une seule page';

  @override
  String get readerCustomThemeTitle => 'Thème de lecture personnalisé';

  @override
  String get readerCustomThemeReset => 'Réinitialiser';

  @override
  String get readerCustomThemeColors => 'Couleurs du thème';

  @override
  String get readerCustomThemeTextColor => 'Couleur du texte';

  @override
  String get readerCustomThemeTextColorHint =>
      'Corps du texte, titres et icônes principales';

  @override
  String get readerCustomThemeBackground => 'Arrière-plan de lecture';

  @override
  String get readerCustomThemeBackgroundHint =>
      'La couleur du papier et du canevas de lecture';

  @override
  String get readerCustomThemeControlBar => 'Couleur de la barre de commande';

  @override
  String get readerCustomThemeControlBarHint =>
      'Commandes supérieures et inférieures et surfaces de réglages';

  @override
  String get readerCustomThemeContrastGood =>
      'Le texte offre un contraste net pour une longue lecture confortable';

  @override
  String get readerCustomThemeContrastLow =>
      'Le contraste du texte est faible et peut causer de la fatigue visuelle';

  @override
  String get readerCustomThemeSave => 'Enregistrer et utiliser';

  @override
  String get readerCustomThemePreview => 'Aperçu en direct';

  @override
  String get readerCustomThemePreviewChapter =>
      'Chapitre un · Le vent entre les pages';

  @override
  String get readerCustomThemePreviewBody =>
      'Voici votre espace de lecture. Ajustez les couleurs du texte, du papier et des commandes jusqu\'à ce que chaque page soit vraiment vôtre.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Saisissez une couleur hexadécimale à 6 chiffres, par exemple #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Couleur hexadécimale';

  @override
  String get readerCustomThemesTitle => 'Thèmes de lecture personnalisés';

  @override
  String get readerCustomThemeAdd => 'Ajouter un thème';

  @override
  String get readerCustomThemeReorderHint =>
      'Maintenez la poignée à droite pour réordonner les thèmes. Le même ordre apparaît dans les paramètres de lecture.';

  @override
  String get readerCustomThemeUse => 'Utiliser le thème sélectionné';

  @override
  String get readerCustomThemeDeleteTitle => 'Supprimer le thème de lecture ?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return '\"$name\" sera retiré de vos thèmes, ainsi que son image d\'arrière-plan enregistrée.';
  }

  @override
  String get readerCustomThemeEmptyTitle =>
      'Aucun thème personnalisé pour le moment';

  @override
  String get readerCustomThemeEmptyHint =>
      'Créez votre propre combinaison de police, couleur de papier et image d\'arrière-plan.';

  @override
  String get readerCustomThemeNewTitle => 'Nouveau thème de lecture';

  @override
  String get readerCustomThemeEditTitle => 'Modifier le thème de lecture';

  @override
  String get readerCustomThemeName => 'Nom du thème';

  @override
  String get readerCustomThemeNameHint =>
      'Par exemple, Nuit pluvieuse ou Papier d\'après-midi';

  @override
  String get readerCustomThemeBackgroundImage => 'Image d\'arrière-plan';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Prend en charge JPG, PNG et WebP. L\'image est copiée dans le stockage de l\'application.';

  @override
  String get readerCustomThemeChooseImage => 'Téléverser une image';

  @override
  String get readerCustomThemeReplaceImage => 'Remplacer l\'image';

  @override
  String get readerCustomThemeRemoveImage => 'Retirer l\'image';

  @override
  String get readerCustomThemeImageStrength =>
      'Intensité de l\'image d\'arrière-plan';

  @override
  String get readerCustomThemeImageUnsupported =>
      'L\'importation d\'image d\'arrière-plan n\'est pas prise en charge sur cette plateforme';

  @override
  String get readerCustomThemeImageTooLarge =>
      'L\'image ne doit pas dépasser 20 Mo';

  @override
  String get readerCustomThemeImageFormat =>
      'Choisissez une image JPG, PNG ou WebP';

  @override
  String get readerCustomThemeImageFailed =>
      'Impossible d\'importer l\'image d\'arrière-plan. Réessayez.';

  @override
  String get importSourceTitle => 'Ajouter des livres';

  @override
  String get importSourceDescription =>
      'Choisissez d\'abord plusieurs fichiers. Vérifiez la file avant de lancer l\'importation.';

  @override
  String get importSelectFiles => 'Choisir des fichiers';

  @override
  String get importIosSharedDocuments => 'Sur mon iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'iCloud Drive est indisponible';

  @override
  String get importAndroidFolder => 'Autoriser un dossier de livres';

  @override
  String get importAndroidRescan => 'Scanner les dossiers autorisés';

  @override
  String get importFolderPermissionAvailable =>
      'Autorisé · touchez pour scanner';

  @override
  String get importFolderPermissionLost =>
      'Autorisation perdue · autorisez à nouveau pour rétablir l\'accès';

  @override
  String get importRemoveFolder => 'Retirer le dossier';

  @override
  String importQueueTitle(int count) {
    return 'File d\'importation ($count)';
  }

  @override
  String get importQueueHint =>
      'Retirez les fichiers sélectionnés par erreur, puis importez-les un par un.';

  @override
  String get importQueueEmptyTitle => 'Aucun livre sélectionné';

  @override
  String get importQueueEmptyBody =>
      'Choisissez un fichier EPUB, PDF, TXT, MOBI ou un autre fichier de livre pris en charge.';

  @override
  String importAction(int count) {
    return 'Importer $count livres';
  }

  @override
  String importRetryFailed(int count) {
    return 'Réessayer les $count en échec';
  }

  @override
  String get importStatusQueued => 'En attente';

  @override
  String get importStatusPreparing => 'Préparation du fichier';

  @override
  String get importStatusChecking => 'Vérification';

  @override
  String get importStatusCopying => 'Copie';

  @override
  String get importStatusAnalyzing => 'Analyse';

  @override
  String get importStatusSaving => 'Enregistrement';

  @override
  String get importStatusImported => 'Importé';

  @override
  String get importStatusSkipped => 'Existe déjà, ignoré';

  @override
  String get importStatusFailed => 'Échec de l\'importation';

  @override
  String get importRemove => 'Retirer';

  @override
  String get importRetry => 'Réessayer';

  @override
  String get importClearCompleted => 'Effacer les terminés';

  @override
  String get importDone => 'Terminé';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return '$succeeded importés · $skipped ignorés · $failed en échec';
  }

  @override
  String get importNoSupportedFiles =>
      'Aucun fichier de livre pris en charge n\'a été trouvé';

  @override
  String get importScanning => 'Analyse des fichiers…';

  @override
  String get settingsAiApiKeyConfigured => 'Clé API configurée';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Touchez pour terminer la configuration';

  @override
  String get settingsAiAddModel => 'Ajouter un modèle';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Passé à $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Veuillez d\'abord renseigner l\'URL de base et la clé API';

  @override
  String get settingsAiEditModelTitle => 'Configurer le modèle';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Chaque carte rapide est liée à un modèle';

  @override
  String get settingsAiPresetModel => 'Modèle prédéfini';

  @override
  String get settingsAiBaseUrlLabel => 'URL de base';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'Compatible OpenAI : l\'URL de base doit généralement inclure /v1 (par exemple, https://example.com/v1). L\'application ajoute /chat/completions.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic : l\'URL de base peut inclure /v1 ou l\'omettre. L\'application évite de dupliquer /v1 et ajoute /messages.';

  @override
  String get settingsAiApiKeyLabel => 'Clé API';

  @override
  String get settingsAiModelNameLabel => 'Nom du modèle';

  @override
  String get settingsAiFetchModelsTooltip =>
      'Récupérer les modèles automatiquement';

  @override
  String get settingsAiFetchModelsList =>
      'Récupérer automatiquement la liste des modèles';

  @override
  String get settingsAiSelectModel => 'Sélectionnez un modèle';

  @override
  String get settingsAiTemperatureLabel => 'Température';

  @override
  String get settingsAiAddAndEnable => 'Ajouter et activer';

  @override
  String get settingsAiModelMismatchClaude =>
      'Les noms de modèles du fournisseur Claude commencent généralement par \"claude\". Vérifiez que le fournisseur et le modèle correspondent.';

  @override
  String get settingsAiModelMismatchGemini =>
      'Les noms de modèles du fournisseur Gemini contiennent généralement \"gemini\". Vérifiez que le fournisseur et le modèle correspondent.';

  @override
  String get settingsAiModelMismatchGlm =>
      'Les noms de modèles du fournisseur GLM commencent généralement par \"glm\". Vérifiez que le fournisseur et le modèle correspondent.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'Les noms de modèles du fournisseur MiniMax contiennent généralement \"MiniMax\". Vérifiez que le fournisseur et le modèle correspondent.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Format de réponse de la liste de modèles non reconnu';

  @override
  String get settingsAiNoModelsReturned =>
      'Le serveur n\'a renvoyé aucune liste de modèles disponibles';

  @override
  String get settingsAiNoModelsAvailable => 'Aucun modèle disponible';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Échec de la récupération des modèles : $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'Prétraitement IA des livres';

  @override
  String get settingsAiPreprocessSubtitle =>
      'Après l\'importation d\'un livre, laissez l\'IA le lire et construire automatiquement une base de connaissances locale de résumés';

  @override
  String get settingsAiPreprocessWarning =>
      'Le prétraitement envoie tout le livre au modèle IA par blocs. Cela consomme un grand nombre de jetons et prend du temps. Activer quand même ?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Configurez d\'abord un modèle IA fonctionnel avec une clé API';

  @override
  String get libraryAiPreprocess => 'Prétraitement IA';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return 'Laisser l\'IA lire \"$title\" et construire une base de connaissances de résumés ? Cela consomme un grand nombre de jetons.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'L\'IA lit ce livre… (étape $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'Base de connaissances IA générée';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'Échec du prétraitement IA : $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Ce format de livre ne prend pas encore en charge le prétraitement IA';

  @override
  String get libraryAiPreprocessQueued =>
      'Ajouté à la file de prétraitement IA. Suivez la progression dans les tâches de téléchargement.';

  @override
  String get downloadTasksTabDownloads => 'Téléchargements';

  @override
  String get aiPreprocessTaskRunning => 'L\'IA lit…';

  @override
  String get aiPreprocessTasksEmpty => 'Aucune tâche de prétraitement IA';

  @override
  String get aiPreprocessClearFinished => 'Effacer les terminées';

  @override
  String get aiChatNewChat => 'Nouvelle discussion';

  @override
  String get aiChatSelectBook => 'Lier un livre';

  @override
  String get aiChatNoBook => 'Aucun livre lié';

  @override
  String get navAi => 'IA';

  @override
  String get aiHistoryTitle => 'Discussions IA';

  @override
  String get aiHistoryEmpty =>
      'Aucune discussion IA pour le moment.\nTouchez Demander à l\'IA pendant la lecture pour commencer votre première conversation.';

  @override
  String aiHistoryMessageCount(int count) {
    return '$count messages';
  }

  @override
  String get aiHistoryClearAll => 'Tout effacer';

  @override
  String get aiHistoryClearAllConfirm =>
      'Supprimer tout l\'historique des discussions IA ? Cela ne peut pas être annulé.';

  @override
  String get aiHistoryDeleteConfirm => 'Supprimer cette discussion ?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Désactivez un interrupteur pour masquer cette page ; les Paramètres ne peuvent pas être masqués.';

  @override
  String get readerAskAi => 'Demander à l\'IA';

  @override
  String get readerAiInputHint => 'Posez une question sur ce livre…';

  @override
  String get readerAiSendButton => 'Envoyer';

  @override
  String get readerAiThinking => 'Réflexion…';

  @override
  String get readerAiNotConfiguredHint =>
      'Aucun modèle IA n\'est configuré pour le moment. Allez dans Paramètres → Assistant de lecture IA pour ajouter un modèle et une clé API.';

  @override
  String get readerAiEmptyHint =>
      'Demandez à l\'IA la page actuelle ou n\'importe quoi dans ce livre.';

  @override
  String get readerAiSelectionQuestionLabel => 'Expliquer cette sélection';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Expliquez le passage sélectionné ci-dessous et donnez 3 points clés.\n\nTexte sélectionné :\n$selection\n\nContexte avant :\n$before\n\nContexte après :\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst =>
      'Veuillez saisir une question avant d\'envoyer';

  @override
  String get readerAiEmptyResponse =>
      'Le modèle a renvoyé une réponse vide, veuillez réessayer';

  @override
  String readerAiRequestFailed(String error) {
    return 'Échec de la requête : $error';
  }

  @override
  String get readerAiUnknownError => 'Erreur inconnue';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'La réponse du serveur est vide. Cause habituelle : URL de base incorrecte, passerelle qui ne transmet pas au point de terminaison du modèle, ou serveur fermant la connexion trop tôt.\nURL de la requête : $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'La réponse du serveur n\'est pas un JSON valide. Le point de terminaison actuel est peut-être incompatible avec la configuration $provider.\nURL de la requête : $endpoint\nExtrait de la réponse : $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Échec de la requête$status : impossible de lire la réponse du serveur. Cause habituelle : URL de base incorrecte, point de terminaison renvoyant un contenu vide, ou réseau tronquant la réponse.\nURL de la requête : $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Échec de la requête réseau$status : $error\nURL de la requête : $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Échec de la requête($status) : $text\nSuggestions : 1) la température MiniMax doit être dans (0,1] ; 2) vérifiez que le nom du modèle correspond au point de terminaison ; 3) n\'utilisez qu\'une seule instruction système.\nURL de la requête : $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Échec de la requête($status) : $text\nAstuce : Claude exige l\'en-tête de requête anthropic-version.\nURL de la requête : $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Échec de la requête($status) : $text\nAstuce : confirmez que le fournisseur et la clé API correspondent ; ils ne peuvent pas être mélangés.\nURL de la requête : $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Échec de la requête($status) : $text\nURL de la requête : $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'IA (simulation) : Le texte que vous avez sélectionné est \"$selectedText\".\n\nAvant : $before\nAprès : $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'IA (simulation) : Cette page compte $chars caractères. Concentrez-vous sur les arguments au début et à la fin des paragraphes.';
  }

  @override
  String get readerAiMockGreeting => 'Bonjour';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'IA (simulation) : Vous avez demandé \"$question\".\n\nJ\'ai lu la page actuelle ($chars caractères). Vous pouvez continuer à poser des questions.';
  }

  @override
  String get ttsSystemDefault => 'Voix système par défaut';

  @override
  String get ttsUnavailable => 'Synthèse vocale système indisponible';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'Le système ne prend pas en charge la langue : $language';
  }

  @override
  String get ttsCallFailed => 'Échec de l\'appel de synthèse vocale système';

  @override
  String get importErrorSourceMissing => 'Le fichier source n\'existe pas';

  @override
  String get importErrorHashFailed =>
      'Impossible de vérifier le contenu du fichier';

  @override
  String get importErrorTargetNameExhausted =>
      'Impossible d\'allouer un nom disponible pour le fichier importé';

  @override
  String get importErrorSourceNotMaterialized =>
      'Le fichier source n\'est pas encore sur le stockage local';

  @override
  String get importErrorCopyVerificationFailed =>
      'Le fichier copié ne correspond pas à la source';

  @override
  String get importErrorFileTooLarge =>
      'Le fichier dépasse la limite d\'importation de 500 Mo';

  @override
  String get importErrorSourcePrepareFailed =>
      'Impossible de préparer le fichier d\'importation';

  @override
  String get importErrorFailed => 'Échec de l\'importation du livre';

  @override
  String get importUnknownTitle => 'Titre inconnu';

  @override
  String get importUnknownAuthor => 'Auteur inconnu';

  @override
  String get bookUntitled => 'Sans titre';

  @override
  String get accentPurple => 'Violet élégant';

  @override
  String get accentPink => 'Rose cerise';

  @override
  String get accentCyan => 'Cyan frais';

  @override
  String get accentBrown => 'Marron classique';

  @override
  String get accentGrey => 'Gris élégant';

  @override
  String get accentDeepPurple => 'Violet captivant';

  @override
  String get accentAmber => 'Or ambré';

  @override
  String get accentLightGreen => 'Vert vif';

  @override
  String get accentYellow => 'Jaune soleil';

  @override
  String get accentNeutralGrey => 'Gris minimal';

  @override
  String get accentIndigo => 'Indigo profond';

  @override
  String get accentDeepOrange => 'Orange flamme';

  @override
  String get agreementV2HeroTitle =>
      'Continuez à lire sur votre propre appareil.';

  @override
  String get agreementV2HeroBody =>
      'Origo X est un lecteur de livres numériques open-source, multiplateforme et local d\'abord. Il fournit des outils de lecture ; il ne fournit, n\'héberge ni n\'examine les livres que vous importez.';

  @override
  String get agreementV2LocalTitle => 'Local d\'abord';

  @override
  String get agreementV2LocalBody =>
      'Les livres, la progression et les notes restent en général sur votre appareil, pour que vous les gériez et les sauvegardiez.';

  @override
  String get agreementV2OpenSourceTitle => 'Sous licence AGPL-3.0';

  @override
  String get agreementV2OpenSourceBody =>
      'Le code source est fourni sous GNU AGPL v3.0 et le logiciel est livré en l\'état, sans garantie.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Version des conditions $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Introduction';

  @override
  String get agreementFlowStepTerms => 'Conditions';

  @override
  String get agreementFlowStepSource => 'Sources de livres';

  @override
  String get agreementFlowStepPrivacy => 'Confidentialité';

  @override
  String get agreementFlowNext => 'Suivant';

  @override
  String get agreementFlowBack => 'Retour';

  @override
  String get agreementFlowTermsTitle =>
      'Utilisez Origo X avec des limites claires';

  @override
  String get agreementFlowTermsSubtitle =>
      'Consultez les conditions régissant l\'utilisation du logiciel et du contenu que vous choisissez d\'ouvrir.';

  @override
  String get agreementFlowTermsConsent =>
      'J\'ai lu et j\'accepte les Conditions d\'utilisation.';

  @override
  String get agreementFlowSourceTitle =>
      'Accord sur les sources de livres tiers';

  @override
  String get agreementFlowSourceSubtitle =>
      'Confirmez comment les adresses de sources, le contenu, l\'autorisation et la responsabilité sont séparés du projet officiel.';

  @override
  String get agreementFlowSourceConsent =>
      'J\'ai lu et j\'accepte l\'Accord sur les sources de livres tiers.';

  @override
  String get agreementFlowPrivacyTitle =>
      'Vos données restent sous votre contrôle';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Consultez ce qui reste local, quand les requêtes réseau ont lieu et comment les enregistrements de téléchargement sont conservés.';

  @override
  String get agreementFlowPrivacyConsent =>
      'J\'ai lu et j\'accepte la Politique de confidentialité.';

  @override
  String get agreementFlowEnterApp => 'Entrer dans Origo X';

  @override
  String get agreementFlowPrivacyLocalTitle => 'Local par défaut';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Livres, progression, notes et paramètres restent normalement sur cet appareil.';

  @override
  String get agreementFlowPrivacyNetworkTitle =>
      'L\'utilisation du réseau est explicite';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'La lecture locale n\'envoie pas le texte des livres. La vérification de mises à jour contacte GitHub et le site officiel ; les sources, l\'IA et la synchronisation ne se connectent que lorsque leurs fonctions sont utilisées.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Enregistrements de téléchargement limités';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'Les enregistrements de téléchargement du site officiel contenant une IP brute sont conservés au plus 180 jours, puis supprimés.';

  @override
  String get agreementV2Title => 'Conditions d\'utilisation et confidentialité';

  @override
  String get agreementV2Subtitle => 'Veuillez lire avant d\'utiliser Origo X';

  @override
  String get agreementV2ImportantNotice =>
      'Important : l\'application officielle Origo X ne préinstalle, n\'intègre ni ne recommande aucune source de livres tierce, et ses développeurs n\'exploitent, ne représentent ni n\'hébergent de contenu de source. Vous choisissez chaque fichier importé et chaque source ajoutée ; n\'utilisez que du contenu auquel vous êtes autorisé à accéder.';

  @override
  String get agreementV2SourceBoundaryTitle => 'Limite des sources tierces';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'Le projet officiel fournit uniquement un logiciel de lecture open-source et le protocole Origo Source. Il ne fournit aucune adresse de source ni de répertoire de sources officiel.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Chaque adresse de source doit être saisie et ajoutée par vous. L\'application se connecte directement à ce service indépendant sans router le contenu via un serveur opéré par les développeurs.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'La compatibilité avec le protocole signifie seulement qu\'une interface peut se connecter ; elle ne prouve ni légalité ni licence. Les opérateurs de sources sont responsables de leur contenu, et vous devez l\'examiner et l\'utiliser légalement.';

  @override
  String get agreementV2Section1Title => 'Portée et acceptation';

  @override
  String get agreementV2Section1Body =>
      'Ces conditions s\'appliquent au téléchargement, à l\'installation et à l\'utilisation d\'Origo X et de ses fonctions incluses. En sélectionnant \"Accepter et continuer\", vous confirmez les avoir lues, comprises et acceptées. Si vous n\'acceptez pas, cessez d\'utiliser l\'application et quittez-la. Un tuteur doit consentir lorsque la loi locale l\'exige.';

  @override
  String get agreementV2Section2Title => 'Licence open-source';

  @override
  String get agreementV2Section2Body =>
      'Les futures versions d\'Origo X sont publiées sous la licence GNU Affero General Public License v3.0. Vous pouvez utiliser, copier, modifier, distribuer ou vendre le logiciel sous cette licence. Une version modifiée distribuée doit fournir l\'intégralité de son code source correspondant sous AGPL-3.0, et une version modifiée utilisée pour fournir un service en réseau doit également offrir le code source correspondant aux utilisateurs qui interagissent avec elle. Les droits MIT déjà accordés pour la v1.0.0 et les versions antérieures restent valables et ne sont pas révoqués. Ces conditions ne restreignent pas les droits accordés par la licence open-source. Les composants tiers restent soumis à leurs propres licences.';

  @override
  String get agreementV2Section3Title => 'Contenu de l\'utilisateur et droits';

  @override
  String get agreementV2Section3Body =>
      'Le \"contenu utilisateur\" comprend les livres, documents, images, métadonnées, liens et autres éléments que vous importez, téléchargez, ouvrez, convertissez, mettez en cache, annotez ou lisez à voix haute. Vous devez détenir tous les droits et autorisations requis pour l\'utiliser. Vous êtes seul responsable du droit d\'auteur, des marques, de la vie privée, de la diffamation, du contenu illégal, des logiciels malveillants et d\'autres réclamations ou pertes impliquant le contenu utilisateur. Le logiciel et ses développeurs ne téléversent, ne vendent, ne concèdent sous licence, n\'approuvent ni n\'examinent ce contenu, et la prise en charge d\'un format n\'implique pas une autorisation légale d\'utiliser un fichier.';

  @override
  String get agreementV2Section4Title => 'Usage interdit';

  @override
  String get agreementV2Section4Body =>
      'Vous ne pouvez pas utiliser le logiciel pour enfreindre la propriété intellectuelle ou d\'autres droits ; distribuer du contenu illégal, nuisible ou malveillant ; contourner la gestion des droits numériques, les contrôles d\'accès ou les paywalls ; attaquer ou perturber des systèmes tiers ; ni vous livrer à une activité interdite par la loi applicable. Vous êtes responsable des plaintes, réclamations, pénalités et pertes résultant de votre conduite.';

  @override
  String get agreementV2Section5Title => 'Sources de livres et tiers';

  @override
  String get agreementV2Section5Body =>
      'L\'application officielle ne préinstalle, ne distribue ni ne recommande de sources de livres et n\'exploite pas de répertoire de sources officiel. Les sources, API réseau, liens externes, contenus en ligne, synthèse vocale système, services IA et autres intégrations que vous ajoutez sont fournis et contrôlés indépendamment par des tiers. Ils ne sont ni exploités, représentés, concédés sous licence, approuvés ni examinés par les développeurs. Les opérateurs de sources sont légalement responsables du contenu qu\'ils fournissent. Avant d\'en ajouter une, vous devez examiner son origine, ses droits de contenu, sa politique de confidentialité et ses conditions, et vous êtes responsable de votre propre accès, de vos téléchargements, de votre mise en cache, de votre distribution et de tout autre usage. Dans toute la mesure permise par la loi applicable, les développeurs ne sont pas responsables du contenu tiers, des frais, des pratiques de données, des pannes ou des litiges de contrefaçon.';

  @override
  String get agreementV2Section6Title => 'Données et confidentialité';

  @override
  String get agreementV2Section6Body =>
      'Origo X est local d\'abord. Les livres, la progression de lecture, les notes et les paramètres sont normalement stockés sur votre appareil. Sauf si vous activez une source de livre réseau, l\'IA, la synchronisation ou une autre fonction en ligne, l\'application n\'a pas besoin d\'envoyer le texte des livres aux développeurs pour fournir la lecture locale. Les vérifications de mise à jour automatiques et manuelles contactent GitHub et le site officiel open.xxread.top avec les paramètres techniques nécessaires tels que la plateforme, l\'architecture du processeur et le canal de distribution ; leurs serveurs traitent votre adresse IP et votre User-Agent dans le cadre d\'une communication réseau ordinaire. Lorsque vous téléchargez un programme d\'installation depuis le site officiel, le backend enregistre la version, l\'architecture, l\'heure de téléchargement, l\'adresse IP et le User-Agent pour les compteurs de téléchargement, la protection de sécurité et le dépannage. Les enregistrements d\'événements de téléchargement contenant une IP brute sont conservés au plus 180 jours puis supprimés ; seules des statistiques agrégées sans adresses IP brutes sont conservées plus longtemps. Les requêtes de mise à jour n\'incluent ni le texte des livres, ni votre bibliothèque, ni vos notes, ni un compte, ni un identifiant unique d\'appareil. Les requêtes GitHub sont également régies par les conditions de confidentialité de GitHub. Lorsqu\'une autre fonction en ligne est utilisée, des requêtes, du texte sélectionné, des informations réseau ou des paramètres nécessaires peuvent être envoyés au fournisseur que vous avez choisi, selon les règles de ce fournisseur. Protégez votre appareil, vos clés API et vos sauvegardes ; la désinstallation, l\'effacement des données, une panne de l\'appareil ou une erreur de l\'utilisateur peuvent effacer définitivement des données.';

  @override
  String get agreementV2Section7Title => 'IA et sorties automatisées';

  @override
  String get agreementV2Section7Body =>
      'Les résumés, réponses, traductions, recommandations et autres sorties générées par IA peuvent être inexacts, incomplets, obsolètes ou trompeurs. Ce sont uniquement des aides à la lecture et non des conseils juridiques, médicaux, financiers, académiques ou autres conseils professionnels. Vérifiez les sorties de manière indépendante et ne vous y fiez pas pour des décisions à haut risque. Le matériel envoyé à un fournisseur IA est également régi par les conditions de ce fournisseur.';

  @override
  String get agreementV2Section8Title => 'Exclusion de garanties';

  @override
  String get agreementV2Section8Body =>
      'Dans toute la mesure permise par la loi, le logiciel et le matériel associé sont fournis \"en l\'état\" et \"selon disponibilité\", sans garanties expresses, implicites ou légales, y compris de qualité marchande, d\'adéquation à un usage particulier, de titularité, de non-contrefaçon, d\'exactitude, de compatibilité, de sécurité, de fonctionnement sans erreur, de disponibilité ininterrompue ou de conservation des données. Les contributeurs open-source n\'ont aucune obligation de maintenir, mettre à jour, prendre en charge ou corriger le logiciel.';

  @override
  String get agreementV2Section9Title => 'Limitation de responsabilité';

  @override
  String get agreementV2Section9Body =>
      'Dans toute la mesure permise par la loi, les développeurs, titulaires de droits et contributeurs ne sont pas responsables des pertes directes, indirectes, accessoires, spéciales, punitives ou consécutives résultant de l\'installation, de l\'utilisation, de l\'impossibilité d\'utiliser, du contenu utilisateur, des services tiers, de la perte de données, de problèmes d\'appareil, de l\'interruption d\'activité ou d\'incidents de sécurité, que ce soit au titre du contrat, d\'un délit ou d\'un autre fondement. La responsabilité qui ne peut légalement être exclue reste limitée au minimum permis par la loi.';

  @override
  String get agreementV2Section10Title => 'Indemnisation';

  @override
  String get agreementV2Section10Body =>
      'Dans la mesure permise par la loi applicable, vous êtes responsable et vous dégagerez les développeurs, titulaires de droits et contributeurs de toute réclamation, enquête, pénalité, perte et coût raisonnable émanant de tiers résultant de votre contenu utilisateur, d\'une conduite illégale ou contrefaisante, d\'une violation de ces conditions ou de l\'utilisation de services tiers.';

  @override
  String get agreementV2Section11Title => 'Modifications, résiliation et droit';

  @override
  String get agreementV2Section11Body =>
      'Les fonctionnalités, l\'état de maintenance et ces conditions peuvent évoluer à mesure que le projet open-source, le droit ou les contrôles de risque évoluent. Les mises à jour importantes peuvent nécessiter un nouveau consentement ; si vous n\'êtes pas d\'accord, cessez d\'utiliser l\'application. Vous pouvez la désinstaller à tout moment. Les différends devraient d\'abord être résolus à l\'amiable. Sous réserve des protections obligatoires des consommateurs, le droit du lieu du développeur et les juridictions légalement compétentes s\'appliquent. Si une clause est inapplicable, les autres restent en vigueur.';

  @override
  String get agreementV2ConfirmLabel =>
      'J\'ai lu et j\'accepte les Conditions d\'utilisation et la Politique de confidentialité.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Je comprends que le projet officiel ne fournit aucune source de livres ; les sources et contenus que j\'ajoute proviennent de tiers indépendants, et je vérifierai les autorisations et resterai responsable de mon propre usage.';

  @override
  String get agreementV2ExitLabel => 'Refuser';

  @override
  String get agreementV2ContinueLabel => 'Accepter et continuer';

  @override
  String get agreementV2ExitDialogTitle => 'Refuser les conditions ?';

  @override
  String get agreementV2ExitDialogBody =>
      'Vous devez accepter les Conditions d\'utilisation pour continuer à utiliser Origo X. Si vous n\'acceptez pas, veuillez quitter l\'application.';

  @override
  String get agreementV2CancelLabel => 'Retour';

  @override
  String get agreementV2ConfirmExitLabel => 'Quitter';

  @override
  String get agreementV2SaveFailed =>
      'Impossible d\'enregistrer votre consentement. Veuillez réessayer.';

  @override
  String get settingsDataSyncTitle => 'Données et synchronisation';

  @override
  String get settingsCacheManagementTitle => 'Gestion du cache';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return '$size utilisés · Voir les détails et vider les caches';
  }

  @override
  String get settingsCacheUsageTitle => 'Utilisation du cache';

  @override
  String get settingsCacheTotalUsage => 'Total utilisé';

  @override
  String get settingsCacheSafeHint =>
      'Seuls les caches pouvant être supprimés sans risque sont affichés. Les livres, la progression de lecture et les paramètres ne sont pas inclus.';

  @override
  String get settingsCacheSourceCovers => 'Cache des couvertures de sources';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Couvertures de sources téléchargées · $size';
  }

  @override
  String get settingsCacheSourceData => 'Cache des chapitres de sources';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Cache de chapitres en ligne supprimable sans risque · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Cache de lecture local';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Cache d\'analyse EPUB/TXT/Kindle reconstruisible · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'Fichiers temporaires';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'Fichiers de mise à jour et temporaires jetables · $size';
  }

  @override
  String get settingsCacheClearAll => 'Vider tous les caches sûrs';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Ne vide que les catégories ci-dessus · $size';
  }

  @override
  String get settingsCacheCalculating => 'Calcul en cours…';

  @override
  String get settingsCacheClearConfirm =>
      'Cela ne supprime que des données de cache temporaires. Les livres, couvertures enregistrées, progression de lecture, bases de données, paramètres et identifiants sont conservés.';

  @override
  String get settingsCacheClearAction => 'Vider';

  @override
  String get settingsCacheCleared => 'Cache vidé';

  @override
  String get settingsCacheClearFailed => 'Impossible de vider le cache';

  @override
  String get settingsWebDavSyncTitle => 'Synchronisation WebDAV';

  @override
  String get webDavNotConfigured => 'Non configuré';

  @override
  String get webDavConfigureSubtitle =>
      'Synchronisez vos données de lecture vers votre propre stockage WebDAV';

  @override
  String get webDavBetaBadge => 'Bêta · Peut être instable';

  @override
  String get webDavPageTitle => 'Synchronisation WebDAV';

  @override
  String get webDavConnected => 'Connecté';

  @override
  String get webDavSyncing => 'Synchronisation en cours';

  @override
  String get webDavPartialFailure =>
      'Certains éléments demandent votre attention';

  @override
  String get webDavSyncFailed => 'Échec de la synchronisation';

  @override
  String webDavPendingChanges(int count) {
    return '$count changements en attente de synchronisation';
  }

  @override
  String webDavLastSync(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get webDavNeverSynced => 'Pas encore synchronisé';

  @override
  String get webDavSyncNow => 'Synchroniser maintenant';

  @override
  String get webDavSetUp => 'Configurer WebDAV';

  @override
  String get webDavConnectionTitle => 'Connexion';

  @override
  String get webDavServerUrl => 'Adresse WebDAV';

  @override
  String get webDavUsername => 'Nom d\'utilisateur';

  @override
  String get webDavPassword => 'Mot de passe d\'application';

  @override
  String get webDavPasswordHint =>
      'Stocké de manière sécurisée sur cet appareil uniquement';

  @override
  String get webDavRootPath => 'Dossier distant';

  @override
  String get webDavTestConnection => 'Tester la connexion';

  @override
  String get webDavTestingConnection => 'Test de la connexion…';

  @override
  String get webDavConnectionSuccess =>
      'Connexion et accès en écriture vérifiés';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Échec du test de connexion : $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Enregistrer la configuration';

  @override
  String get webDavAutomaticSync => 'Synchronisation automatique';

  @override
  String get webDavAutomaticSyncHint =>
      'Synchroniser au lancement ou au retour de l\'application au premier plan';

  @override
  String get webDavSyncContent => 'Contenu synchronisé';

  @override
  String get webDavScopeBookSources => 'Sources de livres';

  @override
  String get webDavScopeBookSourcesHint =>
      'Synchronise les sources ORSP publiques et les favorites, plus tous les noms de groupes, groupes vides et leur ordre. Les identifiants de sources et les configurations privées restent sur cet appareil.';

  @override
  String get webDavScopeBooks => 'Bibliothèque et livres en ligne';

  @override
  String get webDavScopeProgress => 'Progression de lecture';

  @override
  String get webDavScopeBookmarks => 'Marque-pages';

  @override
  String get webDavScopeNotes => 'Notes et surlignages';

  @override
  String get webDavScopeNotesHint =>
      'Inclut les citations, notes et annotations manuscrites. Les données WebDAV ne sont pas chiffrées de bout en bout.';

  @override
  String get webDavScopeReadingSessions => 'Statistiques de lecture';

  @override
  String get webDavScopeReaderSettings => 'Paramètres du lecteur';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Synchronise la typographie, les thèmes, le changement de page, les préférences de pagination automatique, les zones tactiles et les préférences du lecteur d\'images.';

  @override
  String get webDavScopeReplaceRules => 'Règles de remplacement';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Synchronise les motifs de règles et les textes de remplacement. Les données WebDAV ne sont pas chiffrées de bout en bout.';

  @override
  String get webDavScopeBookFiles => 'Fichiers de livres';

  @override
  String get webDavBookFilesHint =>
      'Choisissez quels livres téléverser ou télécharger';

  @override
  String get webDavBookFilesUnavailable =>
      'Le transfert de fichiers de livres sera activé lorsque la synchronisation des métadonnées sera stable';

  @override
  String get webDavSecurityNotice =>
      'Les données sont envoyées via HTTPS, mais votre fournisseur WebDAV peut lire le contenu distant non chiffré.';

  @override
  String get webDavConnectionDetails => 'Paramètres de connexion';

  @override
  String get webDavClearConfiguration => 'Effacer la configuration';

  @override
  String get webDavClearConfigurationTitle =>
      'Effacer la configuration WebDAV ?';

  @override
  String get webDavClearConfigurationMessage =>
      'Cela retire l\'adresse et l\'identifiant WebDAV de cet appareil. Les données de lecture locales et les fichiers distants ne seront pas supprimés.';

  @override
  String get webDavClearConfigurationConfirm => 'Effacer de cet appareil';

  @override
  String get webDavActivityTitle => 'Activité de synchronisation';

  @override
  String get webDavActivityEmpty =>
      'Aucune activité de synchronisation pour le moment';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return '$uploaded téléversés, $downloaded téléchargés';
  }

  @override
  String get webDavErrorAuthentication =>
      'Le nom d\'utilisateur, le mot de passe ou l\'autorisation du dossier est incorrect.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'La configuration WebDAV est incomplète ou invalide.';

  @override
  String get webDavErrorInsecureConnection =>
      'La connexion ne répond pas aux exigences de sécurité.';

  @override
  String get webDavErrorCertificate =>
      'Le certificat du serveur n\'a pas pu être vérifié.';

  @override
  String get webDavErrorPermission =>
      'Le dossier distant n\'est pas accessible en écriture.';

  @override
  String get webDavErrorNotFound =>
      'Le dossier de synchronisation distant ou un fichier requis est introuvable.';

  @override
  String get webDavErrorConflict =>
      'Les données distantes sont en conflit. Essayez de synchroniser à nouveau.';

  @override
  String get webDavErrorStorageFull => 'Le stockage WebDAV est plein.';

  @override
  String get webDavErrorRateLimited =>
      'Trop de requêtes WebDAV ont été envoyées. Réessayez plus tard.';

  @override
  String get webDavErrorTimeout => 'Le serveur n\'a pas répondu à temps.';

  @override
  String get webDavErrorUnsupported =>
      'La réponse du serveur est incompatible avec le protocole de synchronisation.';

  @override
  String get webDavErrorServer =>
      'Le serveur WebDAV n\'a pas pu traiter la requête.';

  @override
  String get webDavErrorNetwork =>
      'Le réseau est indisponible. Les changements restent enregistrés sur cet appareil.';

  @override
  String get webDavErrorCorruptData =>
      'Certaines données de synchronisation distantes sont endommagées et n\'ont pas été appliquées.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'Les paramètres de lecture locaux sont endommagés. Synchronisation arrêtée sans supprimer la sauvegarde distante.';

  @override
  String get webDavErrorClockSkew =>
      'L\'horloge de cet appareil diffère trop de celle du serveur WebDAV.';

  @override
  String get webDavErrorSecureStorage =>
      'Le mot de passe WebDAV n\'a pas pu être lu depuis le stockage sécurisé.';

  @override
  String get webDavErrorUnknown => 'WebDAV n\'a pas pu terminer l\'opération.';

  @override
  String get webDavErrorDetails => 'Détails de la réponse du serveur';

  @override
  String get webDavErrorMissingEtagDetail =>
      'Le serveur n\'a pas renvoyé d\'identifiant fort de version de fichier (ETag). L\'ETag est peut-être manquant ou trop faible, et l\'application ne peut donc pas déterminer si un autre appareil a modifié le fichier distant.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'Le serveur a ignoré la condition permettant d\'écrire uniquement lorsque la version du fichier correspond (If-Match). Continuer pourrait écraser un changement plus récent d\'un autre appareil.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'Le serveur a ignoré la condition permettant la création uniquement lorsque le fichier n\'existe pas (If-None-Match). Continuer pourrait écraser un fichier existant.';

  @override
  String webDavErrorReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'Statut HTTP : $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Méthode de requête : $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Chemin de la ressource : $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Échec pendant : $phase';
  }

  @override
  String get webDavPhaseConnecting => 'la connexion au serveur distant';

  @override
  String get webDavPhaseScanningLocal => 'l\'analyse de cet appareil';

  @override
  String get webDavPhaseReadingRemote => 'la lecture des données distantes';

  @override
  String get webDavPhaseApplyingRemote => 'la fusion des données distantes';

  @override
  String get webDavPhaseUploadingLocal =>
      'le téléversement des changements locaux';

  @override
  String get webDavPhaseFinishing => 'la finalisation de la synchronisation';

  @override
  String get webDavPhaseUnknown => 'une étape inconnue';

  @override
  String get webDavBookFilesTitle => 'Fichiers de livres';

  @override
  String get webDavFilesPendingUpload => 'À téléverser';

  @override
  String get webDavFilesAvailableDownload => 'Disponibles';

  @override
  String get webDavFilesSynced => 'Synchronisés';

  @override
  String get webDavFilesUploadSelected => 'Téléverser la sélection';

  @override
  String get webDavFilesDownloadSelected => 'Télécharger la sélection';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return '$count sélectionnés · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Uniquement sur cet appareil';

  @override
  String get webDavFilesOnlyRemote => 'Fichier non téléchargé sur cet appareil';

  @override
  String get webDavFilesUploadPermission =>
      'Autoriser le téléversement de fichiers de livres';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Synchronisez les livres et couvertures sélectionnés. Le TXT ne transfère que les blocs modifiés après son premier téléversement ; l\'EPUB et le PDF conservent leurs octets d\'origine. Les fichiers lisibles complets sont exportés séparément.';

  @override
  String get webDavNewBookPolicyTitle => 'Nouveaux fichiers de livres';

  @override
  String get webDavNewBookPolicyAsk => 'Demander à chaque fois (recommandé)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Choisissez les livres à téléverser une fois une importation terminée';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Téléverser automatiquement les nouveaux livres';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Téléverse immédiatement après l\'importation et peut utiliser les données mobiles';

  @override
  String get webDavNewBookPolicyManual => 'Toujours choisir manuellement';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Lance les téléversements uniquement depuis la page Fichiers de livres';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return 'Synchroniser les $count livres récemment importés ?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'Les données de lecture se synchronisent automatiquement. Choisissez les fichiers de livres d\'origine à téléverser vers WebDAV.';

  @override
  String get webDavNewBooksSkip => 'Pas maintenant';

  @override
  String webDavNewBooksUploading(int count) {
    return 'Téléversement de $count nouveaux livres…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Téléversement des nouveaux livres terminé : $success réussis, $failed en échec';
  }

  @override
  String get webDavFilesTooLarge =>
      'Ce fichier dépasse la limite de taille de synchronisation pour son format';

  @override
  String get webDavFilesEmpty => 'Aucun livre dans cette catégorie';

  @override
  String get webDavFilesTransferComplete =>
      'Transfert de fichiers de livres terminé';

  @override
  String get readerAddAnnotation => 'Ajouter une annotation';

  @override
  String get readerAnnotationHint => 'Écrivez vos réflexions sur ce passage…';

  @override
  String get readerAnnotationSaved => 'Annotation enregistrée';

  @override
  String get readerAnnotationDeleted => 'Annotation supprimée';

  @override
  String get readerAnnotationShelfRequired =>
      'Ajoutez ce livre à la bibliothèque avant d\'enregistrer des annotations';

  @override
  String get readerNoAnnotations => 'Aucune annotation pour le moment';

  @override
  String get readerNoAnnotationsHint =>
      'Sélectionnez du texte pour surligner ou ajouter un commentaire. Touchez un commentaire souligné pour le relire.';

  @override
  String get replaceRulesTitle => 'Remplacer et nettoyer';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Supprimez les publicités, promotions et autres textes indésirables pendant la lecture';

  @override
  String get replaceRulesImport => 'Importer des règles';

  @override
  String get replaceRulesExport => 'Exporter des règles';

  @override
  String get replaceRulesSearchHint => 'Rechercher des noms, groupes ou motifs';

  @override
  String get replaceRulesUnnamed => 'Règle sans nom';

  @override
  String get replaceRulesDeleteValue => 'Retirer';

  @override
  String get replaceRulesCreate => 'Nouvelle règle';

  @override
  String get replaceRulesEmptyTitle => 'Aucune règle de remplacement';

  @override
  String get replaceRulesEmptyBody =>
      'Importez un fichier JSON de source de lecture ou créez une règle d\'expression régulière.';

  @override
  String get replaceRulesNoSearchResults => 'Aucune règle correspondante';

  @override
  String get replaceRulesCreateTitle => 'Nouvelle règle de remplacement';

  @override
  String get replaceRulesEditTitle => 'Modifier la règle de remplacement';

  @override
  String get replaceRulesNameLabel => 'Nom de la règle';

  @override
  String get replaceRulesPatternLabel =>
      'Texte ou expression régulière à rechercher';

  @override
  String get replaceRulesPatternHelper =>
      'Laissez le remplacement vide pour supprimer le texte trouvé';

  @override
  String get replaceRulesReplacementLabel => 'Remplacer par';

  @override
  String get replaceRulesRegexLabel => 'Utiliser une expression régulière';

  @override
  String get replaceRulesScopeTitleLabel => 'Appliquer aux titres de chapitres';

  @override
  String get replaceRulesScopeContentLabel =>
      'Appliquer au contenu des chapitres';

  @override
  String get replaceRulesGroupLabel => 'Groupe (facultatif)';

  @override
  String get replaceRulesScopeLabel => 'Portée (facultatif)';

  @override
  String get replaceRulesScopeHelper =>
      'Séparez les titres de livres ou noms de sources par des points-virgules';

  @override
  String get replaceRulesExcludeScopeLabel => 'Portée exclue (facultatif)';

  @override
  String get replaceRulesDeleteConfirmTitle => 'Supprimer cette règle ?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'La règle sera retirée de cet appareil.';

  @override
  String replaceRulesImported(int count) {
    return '$count règles importées';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'Impossible d\'importer les règles : $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'Le fichier de règles dépasse $max';
  }

  @override
  String get replaceRulesExported => 'Règles exportées';

  @override
  String get replaceRulesPatternRequired =>
      'Saisissez un texte ou une expression régulière à rechercher';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'Le motif dépasse $max caractères';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Expression régulière invalide : $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Un maximum de $max règles est pris en charge';
  }

  @override
  String get accountSecurityTitle => 'Sécurité';

  @override
  String get accountSecurityLoading => 'Chargement de l\'état de sécurité…';

  @override
  String get accountChangeEmailTitle => 'Changer d\'e-mail';

  @override
  String get accountChangeEmailEnterTitle => 'Choisir un nouvel e-mail';

  @override
  String get accountChangeEmailEnterHint =>
      'Nous enverrons un code à votre e-mail actuel et un autre à la nouvelle adresse.';

  @override
  String get accountChangeEmailVerifyTitle =>
      'Vérifier les deux adresses e-mail';

  @override
  String get accountChangeEmailVerifyHint =>
      'Saisissez les deux codes pour terminer le changement de votre e-mail de connexion.';

  @override
  String get accountCurrentEmail => 'E-mail actuel';

  @override
  String get accountNewEmail => 'Nouvel e-mail';

  @override
  String get accountCurrentEmailCode => 'Code envoyé à l\'e-mail actuel';

  @override
  String get accountNewEmailCode => 'Code envoyé au nouvel e-mail';

  @override
  String get accountSendBothCodes => 'Envoyer les deux codes';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Votre adresse actuelle est un e-mail de relais masqué Apple qui ne peut pas recevoir de codes. Un seul code sera envoyé à la nouvelle adresse.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Votre adresse actuelle est un e-mail de relais masqué Apple, aucun code n\'est donc nécessaire pour elle. Saisissez le code envoyé à la nouvelle adresse pour terminer.';

  @override
  String get accountCurrentPasswordInstead =>
      'Mot de passe actuel (à la place du code)';

  @override
  String get accountRelayEmailTitle => 'Vous utilisez un e-mail masqué Apple';

  @override
  String get accountRelayEmailBody =>
      'Votre adresse de connexion est une adresse de relais privé Apple ; les e-mails de vérification risquent de ne pas arriver. Pensez à passer à une adresse que vous utilisez quotidiennement.';

  @override
  String get accountChangeEmailAction => 'Changer d\'e-mail';

  @override
  String get accountEmailChanged => 'E-mail changé';

  @override
  String get accountChangePasswordTitle => 'Définir ou changer le mot de passe';

  @override
  String get accountPasswordEmailTitle => 'Vérifier par e-mail';

  @override
  String get accountPasswordEmailHint =>
      'Envoyez un code à votre e-mail actuel avant de choisir un nouveau mot de passe.';

  @override
  String get accountPasswordNewTitle => 'Choisir un nouveau mot de passe';

  @override
  String get accountPasswordNewHint =>
      'Saisissez le code e-mail et définissez le mot de passe que vous utiliserez la prochaine fois.';

  @override
  String get accountNewPassword => 'Nouveau mot de passe';

  @override
  String get accountChangePasswordAction => 'Changer le mot de passe';

  @override
  String get accountPasswordChanged => 'Mot de passe changé';

  @override
  String get accountPasswordsMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get accountMfaTitle => 'Authentification à deux facteurs';

  @override
  String get accountMfaEnabled =>
      'Activée. Un authentificateur ou un code de récupération inutilisé est requis à la connexion.';

  @override
  String get accountMfaDisabledByDefault =>
      'Désactivée par défaut. Activez-la pour protéger les connexions par mot de passe et par code e-mail.';

  @override
  String get accountMfaOnTitle =>
      'L\'authentification à deux facteurs est activée';

  @override
  String get accountMfaEmailTitle => 'Vérifiez d\'abord votre e-mail';

  @override
  String accountMfaEmailHint(String email) {
    return 'Nous enverrons un code de configuration à $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'Saisissez le code e-mail';

  @override
  String get accountMfaEmailCodeHint =>
      'Après vérification, le code QR d\'authentificateur et le secret s\'ouvriront à la page suivante.';

  @override
  String get accountMfaAuthenticatorTitle =>
      'Ajoutez Origo X à votre authentificateur';

  @override
  String get accountMfaAuthenticatorHint =>
      'Scannez le code QR ou saisissez le secret manuellement, puis entrez le code à six chiffres de l\'authentificateur.';

  @override
  String get accountMfaQrCodeLabel =>
      'Code QR de configuration de l\'authentificateur';

  @override
  String get accountMfaSecretLabel => 'Secret de configuration';

  @override
  String get accountMfaSecretCopied => 'Secret de configuration copié';

  @override
  String get accountMfaRecoveryTitle => 'Enregistrez vos codes de récupération';

  @override
  String get accountMfaChallengeTitle => 'Vérification à deux facteurs';

  @override
  String get accountMfaChallengeHint =>
      'Saisissez le code de votre authentificateur ou un code de récupération inutilisé pour accéder à votre compte.';

  @override
  String get accountMfaCode => 'Code d\'authentificateur';

  @override
  String get accountMfaOrRecoveryCode =>
      'Code d\'authentificateur ou de récupération';

  @override
  String get accountMfaVerify => 'Vérifier et continuer';

  @override
  String get accountMfaSendSetupCode =>
      'Envoyer le code e-mail de configuration';

  @override
  String get accountMfaContinueSetup => 'Continuer la configuration';

  @override
  String get accountMfaSecretWarning =>
      'Ajoutez ce secret à votre authentificateur. Il n\'est affiché que pendant la configuration.';

  @override
  String get accountMfaOpenAuthenticator => 'Ouvrir l\'authentificateur';

  @override
  String get accountMfaConfirm => 'Confirmer et activer';

  @override
  String get accountMfaDisable =>
      'Désactiver l\'authentification à deux facteurs';

  @override
  String get accountMfaDisabled =>
      'Authentification à deux facteurs désactivée';

  @override
  String get accountRecoveryCodesWarning =>
      'Enregistrez ces codes de récupération maintenant. Chaque code ne fonctionne qu\'une seule fois et cette liste ne sera plus affichée.';

  @override
  String get accountCopyRecoveryCodes => 'Copier les codes de récupération';

  @override
  String get accountRecoveryCodesCopied => 'Codes de récupération copiés';

  @override
  String get accountRecoveryCodesSaved => 'J\'ai enregistré ces codes';

  @override
  String get accountPremiumLifetime => 'Premium à vie débloqué';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'Premium est lié à ce compte et se synchronise sur les plateformes prises en charge.';

  @override
  String get accountRedemptionCode => 'Code Premium à vie';

  @override
  String get accountRedeemPremium => 'Utiliser et débloquer pour toujours';

  @override
  String get accountApplePurchase =>
      'Débloquer pour toujours avec l\'App Store';

  @override
  String get accountApplePurchaseHint =>
      'Un achat unique lie définitivement Premium à ce compte Origo X et le synchronise sur les plateformes prises en charge.';

  @override
  String get accountAppleProductLoading =>
      'Chargement des informations produit…';

  @override
  String get accountAppleProductRetry =>
      'Impossible de charger les informations produit. Touchez pour réessayer.';

  @override
  String get accountAppleRestore => 'Restaurer les achats';

  @override
  String get accountApplePurchasePending =>
      'L\'achat attend l\'approbation de l\'App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Achat envoyé ; vérification de l\'accès Premium';

  @override
  String get accountAppleRestoreSubmitted => 'Restauration des achats demandée';

  @override
  String get accountPremiumUnlocked => 'Premium à vie débloqué';

  @override
  String get accountPremiumUnlockedReferral =>
      'Code utilisé : vous et votre parrain avez tous les deux débloqué Premium à vie';

  @override
  String get accountInviteTitle => 'Inviter des amis';

  @override
  String get accountInviteSubtitle =>
      'Quand un ami lie votre code et utilise un code Premium à vie, vous débloquez tous les deux Premium pour toujours.';

  @override
  String get accountInviteMyCode => 'Mon code d\'invitation';

  @override
  String get accountInviteCopyCode => 'Copier le code d\'invitation';

  @override
  String get accountInviteCopyLink => 'Copier le lien d\'invitation';

  @override
  String get accountInviteShareAction =>
      'Copier le lien d\'invitation à partager';

  @override
  String get accountInviteCopied => 'Détails de l\'invitation copiés';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return '$invited invités · $rewarded réussis';
  }

  @override
  String get accountInviteStatsInvited => 'Codes liés';

  @override
  String get accountInviteStatsRewarded => 'Récompenses débloquées';

  @override
  String accountInviterBound(String name) {
    return 'Invité par $name';
  }

  @override
  String get accountInviteRewarded => 'Invitation terminée';

  @override
  String get accountInviteWaiting => 'En attente d\'utilisation du code';

  @override
  String get accountInviteBindLabel => 'Code d\'invitation d\'un ami';

  @override
  String get accountInviteBindHint =>
      'Un compte ne peut lier qu\'une fois et ne peut plus changer ensuite';

  @override
  String get accountInviteBindAction => 'Lier le code d\'invitation';

  @override
  String get accountInviteBound => 'Code d\'invitation lié';

  @override
  String get accountInviteHowItWorks => 'Comment ça marche';

  @override
  String get accountInviteStepShareTitle => 'Partagez le lien';

  @override
  String get accountInviteStepShareBody =>
      'Envoyez le lien ou le code à un ami. Il l\'ouvre et crée un compte.';

  @override
  String get accountInviteStepBindTitle => 'Lier le code';

  @override
  String get accountInviteStepBindBody =>
      'Votre ami saisit votre code dans Compte. Chaque compte ne peut lier qu\'une seule fois.';

  @override
  String get accountInviteStepRedeemTitle => 'Utiliser un code';

  @override
  String get accountInviteStepRedeemBody =>
      'Quand il utilise un code Premium à vie, les deux comptes débloquent immédiatement Premium.';

  @override
  String get accountInviteMyBinding => 'Ma relation d\'invitation';

  @override
  String get accountInviteBindIntro =>
      'Si quelqu\'un vous a invité, liez son code ici pour garder la récompense attachée à votre compte.';

  @override
  String get accountInviteBindingNotNeeded =>
      'Ce compte a déjà Premium, aucun code d\'invitation n\'est donc nécessaire.';

  @override
  String get readingDataExportAction => 'Exporter les données de lecture';

  @override
  String get readingDataExportSubtitle => 'Surlignages, soulignements et notes';

  @override
  String get readingDataExportWholeBook => 'Tout le livre';

  @override
  String get readingDataExportWholeBookHint =>
      'Exporte toutes vos annotations dans ce livre. Le texte du livre et le fichier source ne sont pas inclus.';

  @override
  String get readingDataExportPrivacySummary =>
      'Inclut les extraits surlignés ou soulignés et vos notes privées. Le fichier du livre, le texte complet, les détails de compte et les informations sur l\'appareil ne sont pas inclus.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return '$highlights surlignages · $underlines soulignements · $notes notes';
  }

  @override
  String readingDataExportButton(int count) {
    return 'Exporter $count annotations';
  }

  @override
  String get readingDataExportPreparing => 'Préparation du Markdown…';

  @override
  String get readingDataExportEmpty =>
      'Ce livre n\'a aucun surlignage, soulignement ou note à exporter.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Données de lecture exportées vers $location';
  }

  @override
  String get readingDataExportFailed =>
      'Impossible d\'exporter les données de lecture';

  @override
  String get readingDataExportUnsupported =>
      'L\'exportation de données de lecture n\'est pas encore prise en charge sur cette plateforme';

  @override
  String get readingDataExportReplaceTitle => 'Remplacer le fichier existant ?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Un fichier existe déjà à $path. Le remplacer ne pourra pas être annulé.';
  }

  @override
  String get readingDataExportReplaceAction => 'Remplacer';

  @override
  String get readingDataExportExportedAt => 'Exporté';

  @override
  String get readingDataExportAuthor => 'Auteur';

  @override
  String get readingDataExportContents => 'Contenu';

  @override
  String get readingDataExportMyNote => 'Ma note';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Page $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Annotations non localisées';

  @override
  String get cloudSyncTitle => 'Synchronisation dans le cloud';

  @override
  String get cloudSyncTagline =>
      'Reprenez là où vous en étiez sur un autre appareil';

  @override
  String get cloudSyncResumeTitle => 'Continuer entre appareils';

  @override
  String get cloudSyncAutoResume => 'Reprendre à l\'ouverture d\'un livre';

  @override
  String get cloudSyncAutoResumeHint =>
      'Vérifier la dernière position à l\'ouverture ; proposer des mises à jour pendant la lecture';

  @override
  String get cloudSyncAutoHint =>
      'Enregistrer la progression pendant la lecture et vérifier les mises à jour à l\'ouverture d\'un livre';

  @override
  String get cloudSyncMoreContent => 'Plus d\'options de synchronisation';

  @override
  String get cloudSyncBooks => 'Livres et texte';

  @override
  String get cloudSyncBooksHint =>
      'Livres participants, mises à jour et téléchargements de texte';

  @override
  String get cloudSyncActivity => 'Détails et problèmes de synchronisation';

  @override
  String get cloudSyncStorage => 'Connexion de stockage';

  @override
  String get cloudSyncNoActivity =>
      'Aucune activité de synchronisation pour le moment';

  @override
  String get cloudSyncProgress => 'Position de lecture';

  @override
  String get cloudSyncText => 'Fichiers de texte de livres';

  @override
  String get cloudSyncMetadataComplete =>
      'Données de lecture sélectionnées échangées avec WebDAV';

  @override
  String get cloudSyncPaused => 'La synchronisation automatique est en pause';

  @override
  String get cloudSyncLocalOnly => 'Garder sur cet appareil';

  @override
  String get cloudSyncCheckHint =>
      'Une connexion ne confirme pas la réception sur les autres appareils ; vérifiez chaque élément ci-dessous';

  @override
  String get cloudSyncPendingFiles =>
      'Les mises à jour de texte demandent votre attention';

  @override
  String get cloudSyncFileIdle =>
      'Les fichiers de texte liés seront vérifiés à la prochaine synchronisation';

  @override
  String get cloudSyncManageBooks => 'Choisir livres et téléchargements';

  @override
  String get cloudSyncNoBooks => 'Aucun livre TXT lié pour le moment';

  @override
  String get cloudSyncCompare => 'Comparer les versions';

  @override
  String get cloudSyncKeepLocal => 'Utiliser la version de cet appareil';

  @override
  String get cloudSyncUseRemote => 'Utiliser la version du cloud';

  @override
  String get cloudSyncBothKept =>
      'Les deux versions sont conservées. La synchronisation continue après votre choix.';

  @override
  String get cloudSyncPreviewLimited =>
      'L\'aperçu montre la première différence. Les deux versions complètes sont conservées.';

  @override
  String get cloudSyncPending => 'En attente de synchronisation';

  @override
  String get cloudSyncConflict => 'Versions à examiner';

  @override
  String get cloudSyncCurrent => 'Le texte actuel est synchronisé vers WebDAV';

  @override
  String get cloudSyncFailed =>
      'Synchronisation incomplète. Nouvelle tentative disponible.';

  @override
  String get cloudSyncHistory => 'Historique des versions';

  @override
  String get cloudSyncApplyUpdate => 'Appliquer la mise à jour du texte';

  @override
  String get cloudSyncParticipate => 'Synchroniser le texte de ce livre';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Fermez le lecteur ou l\'éditeur de ce livre avant d\'appliquer la mise à jour du texte';

  @override
  String get cloudSyncTextLocation => 'Fichier cloud actuel';

  @override
  String get cloudSyncTextLocationHint =>
      'Gérez ici les mises à jour, pauses et conflits des livres participants.';

  @override
  String get bookSourcesImportIntro =>
      'Détecte automatiquement les sources. Vérifiez avant d\'importer.';

  @override
  String get bookSourcesImportInputStep => 'Choisir la source';

  @override
  String get bookSourcesImportReviewStep => 'Vérifier et importer';

  @override
  String get bookSourcesImportFileHint =>
      'Sélectionnez un fichier JSON de sources.';

  @override
  String get bookSourcesImportDownloading => 'Téléchargement de la source…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Lecture des règles et recherche de doublons…';

  @override
  String get bookSourcesImportSaving => 'Enregistrement des sources…';

  @override
  String get bookSourcesImportPicking => 'Ouverture du sélecteur de fichiers…';

  @override
  String get bookSourcesImportWaitHint =>
      'Les grandes listes de sources peuvent prendre plus de temps. Vous pouvez annuler et réessayer.';

  @override
  String get bookSourcesImportSaveHint =>
      'Gardez cette fenêtre ouverte jusqu\'à la fin de l\'enregistrement.';

  @override
  String get bookSourcesImportReady => 'Prêt à importer';

  @override
  String get bookSourcesImportEmpty =>
      'Aucune source sélectionnée. Vérifiez le fichier ou la sélection de doublons.';

  @override
  String get bookSourcesImportRetry => 'Réessayer';

  @override
  String get bookSourcesImportFailed =>
      'Impossible de lire les sources. Vérifiez l\'adresse ou le fichier et réessayez.';

  @override
  String get bookSourcesImportWebPage =>
      'Cette URL a renvoyé un site web ou une page de connexion. Copiez le lien JSON de téléchargement de sources ou d\'abonnement du site et importez-le à la place. Vous pourrez vous connecter après avoir importé la source.';

  @override
  String get bookSourcesImportSaveFailed =>
      'Impossible d\'enregistrer les sources. Votre aperçu est conservé ; veuillez réessayer.';

  @override
  String get bookSourcesImportErrorDetails => 'Détails de l\'erreur';

  @override
  String get bookSourcesImportFileUnreadable =>
      'Impossible de lire le fichier sélectionné. Choisissez-le à nouveau.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count sources',
      one: 'Importer 1 source',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'Fichier JSON';

  @override
  String get bookSourcesImportTimedOut =>
      'La lecture a pris trop de temps. Vérifiez votre connexion ou essayez d\'importer un fichier JSON téléchargé.';

  @override
  String get bookSourcesImportUsageNotice =>
      'Informations d\'utilisation des sources';

  @override
  String get bookSourcesMaintenanceScope => 'Portée';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Activées';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Toutes les sources';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Sélectionnées';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return '$count sources dans cette portée';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope =>
      'Aucune source dans cette portée';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Vérification arrêtée';

  @override
  String get bookSourcesMaintenanceCancellingTitle => 'Arrêt des vérifications';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Termine les vérifications actives et conserve les résultats complétés';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Vérification interrompue';

  @override
  String get bookSourcesMaintenanceResume =>
      'Reprendre les vérifications restantes';

  @override
  String get bookSourcesMaintenanceRetry =>
      'Réessayer les vérifications non résolues';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return '$count sources non encore vérifiées';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Résultats de santé';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Tous les résultats';

  @override
  String get bookSourcesMaintenanceAvailable => 'Disponibles';

  @override
  String get bookSourcesMaintenanceLimited => 'Partielles';

  @override
  String get bookSourcesMaintenanceFailed => 'Vérifications en échec';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Délai dépassé';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Non confirmées';

  @override
  String get bookSourcesMaintenanceReviewSearch =>
      'Rechercher par nom ou adresse';

  @override
  String get bookSourcesMaintenanceReviewEmpty =>
      'Aucun résultat correspondant';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return '$count sélectionnées pour désactivation';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Sélectionner les vérifications en échec';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Délai de connexion dépassé ; réessayez plus tard';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Aucun résultat concluant de cette vérification';

  @override
  String get bookSourcesMaintenanceAvailableReason =>
      'Vérifications principales réussies';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Recherche de doublons…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Utilisée par votre bibliothèque · conservée par défaut';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return '$count source(s) sélectionnée(s) sont utilisées par des livres de votre bibliothèque. Les supprimer peut empêcher ces livres de se mettre à jour ou de charger de nouveaux chapitres.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Problèmes';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return '$count source(s) sélectionnée(s)';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed =>
      'Utilisée par votre bibliothèque';

  @override
  String get bookSourcesMaintenancePause => 'Pause';

  @override
  String get bookSourcesMaintenancePausing => 'Mise en pause…';

  @override
  String get bookSourcesMaintenancePaused => 'Vérification en pause';

  @override
  String get bookSourcesMaintenanceCompleted => 'Vérification terminée';

  @override
  String get bookSourcesMaintenanceStart => 'Démarrer la vérification';

  @override
  String get bookSourcesMaintenanceRestart => 'Recommencer';

  @override
  String get bookSourcesMaintenanceCheckedThisRun => 'Vérifiées cette fois';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Sélectionnez et gérez les résultats complétés maintenant, ou continuez la vérification des sources restantes.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'Impossible d\'enregistrer les changements. Réessayez.';

  @override
  String get settingsQqGroup => 'Groupe QQ';

  @override
  String get settingsOpenSourceTitle => 'Détails open-source';

  @override
  String get settingsOpenSourceDetails =>
      'Toutes les fonctionnalités, hormis les fonctionnalités avancées, sont open-source. Le code open-source est sous licence AGPL-3.0 ; consultez le dépôt GitHub pour son périmètre.';

  @override
  String get premiumLifetimeTitle => 'Premium à vie';

  @override
  String get premiumLifetimeCaption =>
      'Achat unique · Sans renouvellement automatique';

  @override
  String get premiumBenefitsTitle => 'Inclus avec Premium';

  @override
  String get premiumProtocolsBenefit =>
      'Importez et utilisez des protocoles de sources compatibles supplémentaires.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Accédez à des sources de confiance sur votre appareil, votre réseau local ou un réseau privé.';

  @override
  String get premiumSourceNotice =>
      'Premium n\'inclut ni livres ni adresses de sources. Les services tiers peuvent facturer séparément.';

  @override
  String get premiumSetupHint =>
      'Activées par défaut après le déblocage. Vous pouvez les désactiver dans Paramètres → Fonctionnalités avancées.';

  @override
  String get premiumBillingTitle => 'Détails de l\'achat';

  @override
  String get premiumBillingBody =>
      'Ceci est un achat unique non consommable, pas un abonnement. Il ne se renouvelle pas automatiquement. L\'App Store affiche le prix réel et Apple gère le paiement.';

  @override
  String get premiumRestoreHelp =>
      'Après une réinstallation ou un changement d\'appareil, restaurez avec le compte Apple utilisé pour l\'achat et le compte Origo X lié. La restauration ne vous facture rien à nouveau.';

  @override
  String get premiumMembershipTerms => 'Conditions d\'adhésion';

  @override
  String get premiumPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get premiumAppleEula => 'EULA standard d\'Apple';

  @override
  String get premiumPurchaseConsent =>
      'Avant d\'acheter, lisez les conditions d\'adhésion, la politique de confidentialité et l\'EULA standard d\'Apple.';

  @override
  String get premiumAccountBindingTitle => 'Compte et accès';

  @override
  String get premiumAccountBindingBody =>
      'Après vérification, Premium est lié au compte Origo X actuel et se synchronise sur les plateformes prises en charge. Les paramètres avancés deviennent disponibles avec l\'adhésion. Se déconnecter ou une révocation désactive les fonctionnalités avancées. Vérifiez votre compte avant d\'acheter.';

  @override
  String get premiumRefundTitle => 'Demander un remboursement';

  @override
  String get premiumRefundTerms =>
      'Apple examine et traite les demandes de remboursement de l\'App Store selon ses règles applicables. Soumettre une demande ne signifie pas qu\'elle est approuvée. Les achats remboursés ou révoqués ne fournissent plus l\'accès Premium correspondant.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Données de vérification d\'achat';

  @override
  String get premiumPrivacyPurchaseBody =>
      'Apple gère les informations de paiement. L\'application envoie l\'identifiant du produit et les données de vérification de transaction signées par Apple au service de compte Origo X pour vérifier les achats et lier ou restaurer Premium. Ce flux d\'achat ne transmet pas au développeur votre numéro de carte bancaire complet ni votre mot de passe de compte Apple.';

  @override
  String get premiumPrivacyAccountTitle => 'Service de compte';

  @override
  String get premiumPrivacyAccountBody =>
      'Le service de compte Origo X traite les détails de compte et les enregistrements d\'adhésion pour la connexion, la vérification de sécurité et l\'accès entre appareils. Contactez-nous pour l\'assistance ou la confidentialité via les options de contact du site officiel.';

  @override
  String get premiumPurchaseSuccess => 'Premium débloqué';

  @override
  String get premiumTestPurchaseVerified =>
      'Achat de test vérifié. Le Premium officiel n\'a pas été activé.';

  @override
  String get premiumPurchaseRevoked =>
      'L\'accès Premium de cet achat a été révoqué.';

  @override
  String get premiumRestoreSuccess =>
      'Achat restauré. Premium est synchronisé.';

  @override
  String get premiumRestoreEmpty =>
      'Aucun achat restaurable n\'a été trouvé. Vérifiez votre compte Apple et le compte Origo X lié à l\'achat.';

  @override
  String get premiumPurchaseCanceled => 'Achat annulé';

  @override
  String get premiumPendingApproval =>
      'En attente de l\'approbation d\'Apple. L\'accès se débloque après approbation et vérification.';

  @override
  String get premiumVerifying => 'Vérification de votre achat…';

  @override
  String get premiumRestoring => 'Restauration des achats…';

  @override
  String get premiumRefundSubmitted =>
      'Demande de remboursement envoyée à Apple pour examen.';

  @override
  String get premiumRefundNotFound =>
      'Aucun achat Premium remboursable n\'a été trouvé pour ce compte Apple. Vous pouvez aussi consulter votre historique avec l\'assistance d\'achat Apple.';

  @override
  String get premiumApplePurchaseSupport => 'Assistance d\'achat Apple';

  @override
  String get premiumLinkFailed =>
      'Impossible d\'ouvrir ce lien. Veuillez réessayer plus tard.';

  @override
  String get premiumSignInRequired =>
      'Connectez-vous à Origo X avant d\'acheter ou de restaurer Premium.';

  @override
  String get premiumRefundUnavailable =>
      'La feuille de remboursement Apple est indisponible. Continuez via l\'assistance d\'achat Apple.';

  @override
  String get premiumOperationFailed =>
      'L\'opération n\'a pas pu être terminée. Veuillez réessayer.';

  @override
  String get premiumPurchaseConsentOther =>
      'Veuillez lire les conditions d\'adhésion et la politique de confidentialité avant de débloquer Premium.';

  @override
  String get premiumBillingBodyOther =>
      'Débloquez Premium via les options d\'achat ou d\'utilisation de code disponibles. Le canal d\'achat affiche le prix et le moyen de paiement. L\'adhésion vérifiée est liée à votre compte Origo X actuel.';

  @override
  String get accountDeleteTitle => 'Supprimer le compte';

  @override
  String get accountDeleteEntrySubtitle =>
      'Effacer définitivement ce compte et toutes ses données';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get accountDeleteReviewTitle => 'Ce que fait la suppression';

  @override
  String get accountDeleteReviewBody =>
      'Lisez chaque point. Une fois que vous confirmez, tout ce qui suit est supprimé immédiatement et nous ne pouvons pas le récupérer pour vous.';

  @override
  String get accountDeleteCurrentAccount => 'Compte actuel';

  @override
  String get accountDeleteJoined => 'Inscrit le';

  @override
  String get accountDeletePremiumActive => 'Premium débloqué (sera retiré)';

  @override
  String get accountDeletePremiumNone => 'Premium non débloqué';

  @override
  String get accountDeleteHasTitle => 'Ce compte possède actuellement';

  @override
  String accountDeleteHasSessions(int count) {
    return '$count appareils connectés';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return '$count passkeys';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return '$count fournisseurs de connexion liés';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return '$count membres inscrits avec votre code d\'invitation';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return '$count codes utilisés';
  }

  @override
  String get accountDeleteTermsTitle => 'Conditions de suppression';

  @override
  String get accountDeleteTermsIrreversible =>
      'La suppression du compte est définitive et ne peut pas être annulée. Une fois que vous confirmez, personne — pas même l\'assistance — ne peut restaurer les données supprimées.';

  @override
  String get accountDeleteTermsIdentity =>
      'Le compte lui-même est supprimé : votre adresse e-mail, votre nom d\'utilisateur, votre nom affiché et votre avatar.';

  @override
  String get accountDeleteTermsLogins =>
      'Chaque méthode de connexion est supprimée : votre mot de passe, vos passkeys, et vos liens Google, GitHub et Apple.';

  @override
  String get accountDeleteTermsSessions =>
      'Vous êtes immédiatement déconnecté partout, sur téléphones, tablettes et ordinateurs.';

  @override
  String get accountDeleteTermsMfa =>
      'Votre configuration à deux facteurs et tous vos codes de récupération sont supprimés.';

  @override
  String get accountDeleteTermsPremium =>
      'L\'accès Premium est retiré, quelle que soit la façon dont vous l\'avez débloqué — un code d\'échange, une récompense d\'invitation ou un achat Apple.';

  @override
  String get accountDeleteTermsReferrals =>
      'Votre code d\'invitation cesse de fonctionner et les enregistrements de parrainage entre vous et vos invités sont supprimés. Les récompenses déjà données aux autres ne sont pas reprises.';

  @override
  String get accountDeleteTermsRedemptions =>
      'Les codes d\'échange déjà utilisés ne sont pas remboursés et ne redeviennent pas disponibles.';

  @override
  String get accountDeleteTermsApple =>
      'Vous avez acheté Premium à vie sur l\'App Store. Supprimer votre compte ne le rembourse pas et n\'annule aucune transaction de l\'App Store — les remboursements ne peuvent être demandés qu\'à Apple. Votre reçu d\'achat est détaché de ce compte et conservé, vous pourrez donc plus tard toucher Restaurer les achats sur un nouveau compte avec le même identifiant Apple et retrouver Premium.';

  @override
  String get accountDeleteTermsLocalData =>
      'Les livres, étagères et progression de lecture sur cet appareil ne sont pas supprimés — ils n\'ont jamais existé que sur votre appareil. Supprimez-les dans l\'application si vous voulez aussi vous en débarrasser.';

  @override
  String get accountDeleteTermsTombstone =>
      'Nous ne conservons que les données de suppression minimales et déidentifiées nécessaires à la prévention des abus, ainsi que les enregistrements de vérification d\'achat de l\'App Store requis pour restaurer ou vérifier des achats. Ces enregistrements ne servent pas à recréer votre compte.';

  @override
  String get accountDeleteTermsRejoin =>
      'Après la suppression, la même adresse e-mail peut s\'inscrire à nouveau, mais ce sera un compte tout neuf et vide, sans vos anciennes données ni accès.';

  @override
  String get accountDeleteBlockedTitle =>
      'Ce compte ne peut pas encore être supprimé';

  @override
  String get accountDeleteBlockedOwner =>
      'Vous êtes le propriétaire de la console d\'administration. Transmettez d\'abord la propriété à quelqu\'un d\'autre, puis revenez — sinon personne ne resterait pour l\'administrer.';

  @override
  String get accountDeleteConsent =>
      'J\'ai lu les conditions en entier, je comprends que la suppression ne peut pas être annulée, et j\'accepte de supprimer définitivement mon compte et toutes ses données.';

  @override
  String get accountDeleteConsentRequired =>
      'Veuillez d\'abord accepter les conditions de suppression.';

  @override
  String get accountDeleteContinue => 'Je comprends, continuer';

  @override
  String get accountDeleteVerifyTitle => 'Vérifiez votre e-mail';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Nous enverrons un code à 6 chiffres à $email pour confirmer que cette demande vient bien de vous.';
  }

  @override
  String get accountDeleteSendCode => 'Envoyer le code de suppression';

  @override
  String get accountDeleteResendCode => 'Renvoyer';

  @override
  String get accountDeleteCodeSent =>
      'Code envoyé. Terminez la suppression dans les 10 minutes.';

  @override
  String get accountDeleteConfirmTitle => 'Dernière étape';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Saisissez l\'e-mail de votre compte $email pour qu\'il ne fasse aucun doute quel compte est supprimé.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'Dès que vous touchez le bouton ci-dessous, le compte est définitivement supprimé.';

  @override
  String get accountDeleteConfirmField =>
      'Saisissez l\'e-mail de votre compte pour confirmer';

  @override
  String get accountDeleteMfaHint =>
      'Ce compte a l\'authentification à deux facteurs activée, un code supplémentaire est donc requis.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Cet e-mail ne correspond pas au compte actuel.';

  @override
  String get accountDeleteAction => 'Supprimer définitivement mon compte';

  @override
  String get accountDeleteDoneTitle => 'Votre compte est supprimé';

  @override
  String get accountDeleteDoneBody =>
      'Votre compte et ses données ont définitivement disparu, et chaque appareil a été déconnecté. Merci d\'avoir utilisé Origo X.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Après avoir fermé cette boîte de dialogue, ouvrez Réglages du compte Apple > Connexion et sécurité > Se connecter avec Apple > Origo X, puis choisissez Cesser d\'utiliser Se connecter avec Apple.';

  @override
  String get accountDeleteDoneClose => 'Fermer';

  @override
  String get bookSourceDetailsTitle => 'Détails du livre';

  @override
  String get bookSourceDetailsDescription => 'À propos de ce livre';

  @override
  String get bookSourceDetailsNoDescription =>
      'Aucune description fournie par cette source.';

  @override
  String get bookSourceDetailsLatestChapter => 'Dernier chapitre';

  @override
  String get bookSourceDetailsLoadFailed =>
      'Impossible de charger les détails complets. Vous pouvez réessayer ou lire avec les informations disponibles.';

  @override
  String get bookSourceDetailsOnShelf => 'Dans la bibliothèque';

  @override
  String get bookSourceDetailsAddFailed =>
      'Impossible d\'ajouter ce livre à votre bibliothèque. Réessayez.';

  @override
  String get bookSourceDetailsReadFailed =>
      'Impossible d\'ouvrir ce livre. Réessayez.';

  @override
  String get appTextSize => 'Taille du texte de l\'interface';

  @override
  String get appTextSizeDescription =>
      'Ne modifie que les menus et commandes de l\'application, pas le texte de lecture.';

  @override
  String get appTextSizePreview =>
      'Les menus et paramètres utiliseront cette taille de texte.';

  @override
  String get appTextSizeDefault => '100% (par défaut)';

  @override
  String get bookSourceTrackUpdatesTitle => 'Mises à jour et texte téléchargé';

  @override
  String get bookSourceTrackUpdatesBody =>
      'Les livres téléchargés conservent leur source. Vérifiez les nouveaux chapitres pour ajouter du contenu, ou actualisez les chapitres téléchargés tout en préservant vos modifications et votre historique.';

  @override
  String get bookSourceCheckNewChapters => 'Vérifier les nouveaux chapitres';

  @override
  String get bookSourceRefreshDownloaded =>
      'Actualiser les chapitres téléchargés';

  @override
  String get bookSourceNoNewChapters =>
      'Aucun nouveau chapitre dans le catalogue. Actualisez les chapitres téléchargés pour vérifier si le texte antérieur a changé.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return '$added chapitres ajoutés, $refreshed actualisés';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Confirmez le dernier chapitre déjà téléchargé avant de continuer les mises à jour. Votre texte existant sera préservé.';

  @override
  String get bookSourceSelectBoundary => 'Confirmer les chapitres téléchargés';

  @override
  String get bookSourceBoundaryHelp =>
      'Sélectionnez le dernier chapitre de source inclus dans votre texte local. Seuls les chapitres ultérieurs seront ajoutés ; le texte existant reste intact.';

  @override
  String get bookSourceTrackingEstablished =>
      'Point de repère enregistré. Vous pouvez maintenant vérifier les nouveaux chapitres.';

  @override
  String get bookSourceMappingChanged =>
      'La source a changé l\'ordre ou les identifiants de ses chapitres. Confirmez à nouveau vos chapitres téléchargés. Le texte existant a été préservé.';

  @override
  String get bookSourceContentConflicts =>
      'Des changements de texte à examiner';

  @override
  String get bookSourceContentConflictBody =>
      'Vous et la source avez modifié ces chapitres. Votre version reste active. Comparez et choisissez ce que vous voulez lire ; les deux versions restent dans l\'historique.';

  @override
  String get bookSourceCompareVersions => 'Comparer le texte';

  @override
  String get bookSourceLocalVersion => 'Mon texte';

  @override
  String get bookSourceRemoteVersion => 'Texte de la source';

  @override
  String get bookSourceBaselineVersion => 'Référence téléchargée';

  @override
  String get bookSourceKeepLocal => 'Garder mon texte';

  @override
  String get bookSourceUseRemote => 'Utiliser le texte de la source';

  @override
  String get bookSourceUpdateFailed =>
      'La mise à jour ne s\'est pas terminée. Votre texte a été préservé. Veuillez réessayer.';

  @override
  String get cloudSyncReadableStorage =>
      'Les livres modifiés sont téléversés comme fichiers complets. Les livres inchangés ne sont pas retransférés. La progression de lecture se synchronise séparément.';

  @override
  String get bookSourceBindSource => 'Lier une source de livre';

  @override
  String get bookSourceNotBound => 'Aucune source liée';

  @override
  String get bookSourceDownloadedUnchanged =>
      'Les chapitres téléchargés sont à jour.';

  @override
  String get premiumSyncFailed =>
      'L\'état de l\'adhésion n\'a pas pu être synchronisé. Une nouvelle tentative aura lieu automatiquement ; un échec de connexion ne révoque pas un accès vérifié.';

  @override
  String get premiumGrantedAccess =>
      'Vous avez un accès Premium offert. Aucun achat supplémentaire n\'est nécessaire.';

  @override
  String get premiumOtherChannelAccess =>
      'Vous avez Premium via un autre canal. Aucun achat supplémentaire n\'est nécessaire.';

  @override
  String get premiumAppleAccess =>
      'Vous avez Premium via l\'App Store. Aucun achat supplémentaire n\'est nécessaire.';

  @override
  String get premiumExistingAccess =>
      'Vous avez déjà Premium. Aucun achat supplémentaire n\'est nécessaire.';

  @override
  String get premiumSyncPending => 'Synchronisation de l\'état de l\'adhésion';

  @override
  String get cloudSyncExportBook => 'Exporter le fichier complet vers le cloud';

  @override
  String get cloudSyncExportDone => 'Fichier complet exporté';

  @override
  String get cloudSyncDiagnostics =>
      'Copier les diagnostics de synchronisation';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Ce dossier appartient à un format de synchronisation plus ancien. Choisissez un nouveau dossier vide. Vos livres locaux et fichiers cloud existants seront conservés.';

  @override
  String get cloudSyncSettings => 'Paramètres de synchronisation';

  @override
  String get cloudSyncSettingsHint =>
      'Synchronisation automatique, autres données et connexion';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Synchroniser les positions de lecture sans téléverser de fichiers de livres';

  @override
  String get cloudSyncProgressExplanation =>
      'Si les deux appareils ont le même livre, vous pouvez synchroniser uniquement la progression de lecture. Le nouveau téléphone a quand même besoin d\'une copie lisible ; les enregistrements de progression ne contiennent pas le texte du livre.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Téléversez ou téléchargez des livres ; les modifications téléversent le fichier entier';

  @override
  String get cloudSyncOtherDataHint =>
      'Bibliothèque, sources, marque-pages, notes et paramètres de lecture';

  @override
  String get cloudSyncActivityHint =>
      'Progression, état des fichiers et détails des échecs';

  @override
  String get cloudSyncNeedsAttention =>
      'Un problème de synchronisation demande votre attention';

  @override
  String get cloudSyncFileStatus => 'Mises à jour et conflits';

  @override
  String get cloudSyncTransferGuide => 'Passer à un nouveau téléphone';

  @override
  String get cloudSyncTransferGuideHint =>
      'Restaurez livres et progression de lecture sur un nouveau téléphone';

  @override
  String get cloudSyncTransferIntro =>
      'Le téléversement d\'un livre est facultatif pour la synchronisation de la progression. Vous n\'avez besoin d\'une copie cloud que si le nouveau téléphone n\'a pas déjà le livre et que vous voulez le télécharger d\'ici.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Synchronisez la progression sur l\'ancien téléphone';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Quittez le lecteur pour enregistrer votre dernière position, activez Progression de lecture, puis touchez Synchroniser maintenant. Utilisez la même connexion WebDAV et le même dossier de synchronisation sur les deux téléphones.';

  @override
  String get cloudSyncTransferHasBook =>
      '2. Le nouveau téléphone a déjà le livre';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Importez le même fichier local, ou ouvrez le même livre en ligne depuis la même source. Synchronisez la progression, puis ouvrez le livre pour continuer. Des titres identiques ne garantissent pas à eux seuls une correspondance.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. Le nouveau téléphone a besoin du fichier du livre';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'Sur l\'ancien téléphone, ouvrez Fichiers de livres, autorisez les téléversements et sélectionnez le livre. Après la réussite du téléversement, synchronisez le nouveau téléphone et téléchargez-le depuis Disponibles au téléchargement. Vous pouvez aussi transférer le même fichier vous-même.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Si vous avez modifié le texte sur l\'ancien téléphone, téléversez cette version via Fichiers de livres et téléchargez-la sur le nouveau téléphone pour préserver son identité de livre. Les positions de lecture peuvent ne pas correspondre entre des versions de texte différentes.';

  @override
  String get cloudSyncFrequency => 'Fréquence de synchronisation automatique';

  @override
  String get cloudSyncFrequencyOff => 'Désactivée (manuel uniquement)';

  @override
  String get cloudSyncFrequencyOnChange => 'Après les changements';

  @override
  String get cloudSyncFrequency15Minutes => 'Toutes les 15 minutes';

  @override
  String get cloudSyncFrequencyHourly => 'Toutes les heures';

  @override
  String get cloudSyncFrequencyDaily => 'Une fois par jour';

  @override
  String get cloudSyncFrequencyHint =>
      'Les intervalles démarrent après une synchronisation automatique réussie. Si l\'application ne tourne pas, elle rattrape à la prochaine ouverture. Les tentatives échouées sont réessayées. Synchroniser maintenant fonctionne toujours immédiatement.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Synchronisation automatique : $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'La progression est récupérée à la fréquence choisie. L\'ouverture d\'un livre reprend depuis la dernière position synchronisée. Touchez d\'abord Synchroniser maintenant quand vous voulez la progression la plus récente.';

  @override
  String get readerChapterProgressTitle => 'Progression du chapitre';

  @override
  String get readerChapterProgressHidden => 'Masquée';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return '$chapter/$total chapitres';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return '$count chapitres à venir';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'L\'essai Premium expire le $date.';
  }

  @override
  String get premiumTrialTitle => 'Essai Premium';

  @override
  String get bookSourceCheckUpdates => 'Vérifier les mises à jour';

  @override
  String get bookSourceUpdates => 'Mises à jour du livre';

  @override
  String get bookSourceNotChecked => 'Pas encore vérifié';

  @override
  String get bookSourceUpToDate => 'Le catalogue est à jour';

  @override
  String get bookSourceUpdatesAvailable => 'Nouveaux chapitres disponibles';

  @override
  String get bookSourceNeedsMapping => 'Confirmer où continuer';

  @override
  String bookSourceLastChecked(String time) {
    return 'Dernière vérification : $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Dernière mise à jour : $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown => 'Heure de mise à jour indisponible';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Dernier : $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Pendant que la bibliothèque est ouverte, les catalogues sont vérifiés toutes les 30 minutes. Vérifiez manuellement à tout moment. Les livres en ligne utilisent le dernier catalogue ; les livres TXT locaux ne téléchargent de nouveaux chapitres que si vous choisissez de continuer. Après la liaison ou le changement d\'une source, confirmez le dernier chapitre déjà présent dans votre fichier local. Les mises à jour ne remplacent pas votre texte d\'origine. L\'heure de mise à jour est fournie par la source, ou enregistre le moment où un nouveau chapitre a été détecté pour la première fois.';

  @override
  String get bookSourceBindHelp =>
      'Trouvez ce livre dans vos sources pour ajouter sa couverture et activer le changement de source et les mises à jour de chapitres. Votre texte local et votre position de lecture sont préservés.';

  @override
  String get bookSourceContinueUpdate => 'Télécharger les nouveaux chapitres';

  @override
  String get settingsCloseReaderToLibraryTitle =>
      'Close reader to return to library';

  @override
  String get settingsCloseReaderToLibrarySubtitle =>
      'When a book is open, the window close button returns to the main window instead of quitting the app';

  @override
  String get navMe => 'Mon espace';

  @override
  String get settingsPreferencesTitle => 'Préférences';

  @override
  String get settingsPreferencesSubtitle => 'Apparence, lecture, langue';

  @override
  String get settingsManagementTitle => 'Réglages et gestion';

  @override
  String get settingsDataSyncSubtitle => 'Sauvegarde WebDAV, cache';

  @override
  String get settingsContentServicesTitle => 'Contenu et services';

  @override
  String get settingsContentServicesSubtitle => 'Sources, IA, lecture audio';

  @override
  String get settingsAboutSupportSubtitle =>
      'Version, mises à jour, open source';

  @override
  String get settingsPremiumSubtitle =>
      'Plus de sources et accès au réseau privé';

  @override
  String get settingsGuestTitle => 'Non connecté';

  @override
  String get settingsGuestSubtitle =>
      'La lecture locale ne nécessite pas de compte';

  @override
  String get settingsWebDavConfigured => 'Sauvegarde WebDAV configurée';

  @override
  String get settingsPremiumActive => 'Premium actif';

  @override
  String get settingsPremiumSyncFailed =>
      'Synchronisation de l’abonnement impossible';

  @override
  String get settingsWebDavWorking => 'WebDAV est en cours';

  @override
  String get storeReaderLockedTitle => 'Acheter la version de base';

  @override
  String get storeReaderLockedBody =>
      'La lecture dans cette version de la boutique nécessite un essai actif ou l’achat de la version de base. Vos livres et vos notes sont conservés. Retournez à la bibliothèque pour exporter vos données.';

  @override
  String get storeReaderUnlock => 'Essayer, acheter ou restaurer';

  @override
  String get storeReaderBack => 'Retour à la bibliothèque';

  @override
  String get storeReaderChecking => 'Vérification de l’accès à la lecture…';

  @override
  String get storeReaderBenefitTitle => 'Version de base';

  @override
  String get storeReaderBenefitBody =>
      'Lecture locale à vie. Aucun compte Origo requis.';

  @override
  String storeTrialStart(int days) {
    return 'Essayer gratuitement pendant $days jours';
  }

  @override
  String storeTrialDetails(int days) {
    return 'Essayez la lecture locale pendant $days jours, sans prélèvement automatique. Ensuite, achetez la version de base une seule fois. Vos livres et notes sont conservés.';
  }

  @override
  String get storeTrialStarted =>
      'Votre essai de la version de la boutique a commencé.';

  @override
  String get storeTrialExpired =>
      'Votre essai de la version de la boutique est terminé. Effectuez un achat unique pour continuer ou restaurez un achat existant.';

  @override
  String storePurchaseButton(String store) {
    return 'Acheter la version de base via $store';
  }

  @override
  String storePurchaseBilling(String store) {
    return 'Achat unique de la version de base, sans renouvellement automatique. $store affiche le prix et traite le paiement.';
  }

  @override
  String storePurchaseRestoreHelp(String store) {
    return 'Restaurez avec le compte $store utilisé pour l’achat. Aucune connexion Origo ni nouveau paiement requis.';
  }

  @override
  String storePurchaseAccess(String store) {
    return 'Vous avez déjà acheté la version de base via $store. Aucun nouvel achat n’est nécessaire.';
  }

  @override
  String get storeRestoreEmpty =>
      'Aucun achat à restaurer n’a été trouvé. Vérifiez votre compte de la boutique et le compte Origo X associé.';

  @override
  String get basicRestoreEmpty =>
      'Aucun achat de la version de base trouvé. Vérifiez votre compte de la boutique.';

  @override
  String get storeGoogleRefundTerms =>
      'Demandez un remboursement via Google Play. Un remboursement vérifié supprime uniquement l’accès associé à cet achat ; les droits d’accès indépendants restent valables.';

  @override
  String get storeReaderLegacyNotice =>
      'Votre accès de base à la lecture est conservé. La compatibilité avancée avec les sources nécessite toujours Premium.';

  @override
  String get storePrivacyPurchaseBody =>
      'Les données de vérification de la boutique et un identifiant de compte sont envoyés à notre serveur pour vérifier et restaurer l’accès. La vérification Google Play comprend un jeton d’achat et un identifiant de compte haché. Nous ne recevons aucune donnée de carte de paiement.';

  @override
  String storeTrialLegacyDetails(int days) {
    return 'Votre accès existant à la lecture reste valable. L’essai de $days jours n’est pas nécessaire.';
  }

  @override
  String get storeReaderSupportSubtitle =>
      'Essayez la lecture locale ou achetez la version de base une seule fois';

  @override
  String get storeBillingUnavailable =>
      'Les achats dans la boutique ne sont pas encore disponibles. Réessayez plus tard. Votre accès existant reste inchangé.';

  @override
  String get accountSignInTitle => 'Connexion à Origo X';

  @override
  String get accountSignInSubtitle => 'Gérez votre compte et vos achats';

  @override
  String accountRegistrationStep(int step) {
    return 'Créer un compte · $step / 3';
  }

  @override
  String get accountSetupTitle => 'Configurez votre compte';

  @override
  String get accountSetupHint =>
      'Vous pourrez ajouter votre nom et votre photo plus tard.';

  @override
  String get accountInvalidEmail => 'Saisissez une adresse e-mail valide';

  @override
  String get accountCodeFormat =>
      'Saisissez le code à 6 chiffres reçu par e-mail';

  @override
  String get accountPasswordRequired => 'Saisissez votre mot de passe';

  @override
  String get accountShowPassword => 'Afficher le mot de passe';

  @override
  String get accountHidePassword => 'Masquer le mot de passe';

  @override
  String accountResendIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get accountBackToCode => 'Revenir au code e-mail';

  @override
  String get accountAuthorizationTitle => 'Continuez dans le navigateur';

  @override
  String get accountReopenAuthorization => 'Rouvrir la page de connexion';

  @override
  String get accountSignOutHint =>
      'Vos livres locaux seront conservés. Reconnectez-vous pour vérifier les droits de votre compte.';

  @override
  String get accountDiscardChanges => 'Abandonner les modifications';

  @override
  String get accountUnsavedChanges =>
      'Les modifications du profil ne sont pas enregistrées.';

  @override
  String get accountAuthorizationExpired =>
      'La demande a expiré. Veuillez réessayer.';

  @override
  String get purchaseDetailsTitle => 'Détails de l’achat';

  @override
  String get purchaseBenefitsAction => 'Voir tous les avantages';

  @override
  String get purchaseTermsAction => 'Conditions et confidentialité';

  @override
  String get purchaseAccountCaption => 'Lié à votre compte Origo';

  @override
  String get basicBenefitsTitle => 'L’expérience de lecture complète';

  @override
  String get basicReadingTitle => 'Lecture multiformat';

  @override
  String get basicReadingBody =>
      'Lisez les formats TXT, EPUB, PDF et plus. Importez des livres avec sommaire et signets, profitez de plusieurs modes de page, de la lecture immersive et des doubles pages sur tablette.';

  @override
  String get basicFormatNote =>
      'La prise en charge des formats varie selon la plateforme ; les livres protégés par DRM ne sont pas pris en charge.';

  @override
  String get basicAppearanceTitle => 'Thèmes et polices';

  @override
  String get basicAppearanceBody =>
      'Personnalisez thèmes et arrière-plans, importez des polices et ajustez taille, interligne, marges et paragraphes.';

  @override
  String get basicTtsTitle => 'Lecture à voix haute et écoute';

  @override
  String get basicTtsBody =>
      'Écoutez avec les voix de l’appareil, réglez la vitesse et programmez une minuterie de veille.';

  @override
  String get basicCloudTtsTitle => 'TTS cloud';

  @override
  String get basicCloudTtsBody =>
      'Configurez des services vocaux cloud, choisissez les modèles et les voix et enregistrez plusieurs profils.';

  @override
  String get basicAiTitle => 'Assistant de lecture IA';

  @override
  String get basicAiBody =>
      'Connectez votre service IA pour poser des questions et approfondir vos lectures.';

  @override
  String get basicNotesTitle => 'Notes et historique de lecture';

  @override
  String get basicNotesBody =>
      'Recherchez dans le texte, enregistrez signets, surlignages et notes, consultez les statistiques et exportez vos données de lecture.';

  @override
  String get basicSourcesTitle => 'Sources de livres ouvertes';

  @override
  String get basicSourcesBody =>
      'Importez des sources ORSP compatibles pour rechercher et lire du contenu en ligne. L’app ne fournit ni adresses de sources ni livres.';

  @override
  String get basicSyncTitle => 'Bibliothèque et sauvegarde';

  @override
  String get basicSyncBody =>
      'Gérez votre bibliothèque locale et sauvegardez ou restaurez livres, données de lecture et réglages avec WebDAV.';

  @override
  String get basicServicesNote =>
      'L’IA et le TTS cloud nécessitent vos propres services ; les frais de tiers ne sont pas inclus.';

  @override
  String get basicEditionTitle => 'Version de base';

  @override
  String get basicEditionSummary =>
      'Un achat unique. L’expérience de lecture complète.';

  @override
  String get basicEditionNoAccount => 'Aucune connexion Origo requise';

  @override
  String get premiumEditionSummary =>
      'Extensions avancées. Plus de formats de sources.';

  @override
  String get storeReaderLicenseTitle => 'Acheter la version de base';

  @override
  String get storeReaderLicenseSubtitle =>
      'Essayez la lecture locale pendant 14 jours, puis achetez la version de base une seule fois.';

  @override
  String get storeReaderLifetimeTitle => 'Version de base';

  @override
  String storeReaderOwned(String store) {
    return 'Version de base achetée via $store.';
  }

  @override
  String get storePremiumPrerequisiteTitle =>
      'Achetez d’abord la version de base';

  @override
  String get storePremiumPrerequisiteBody =>
      'Premium est vendu séparément après l’achat de la version de base. La période d’essai ne suffit pas.';

  @override
  String get storePremiumPriceCaption =>
      'Premium permanent · lié à votre compte Origo';

  @override
  String storePremiumPurchaseButton(String store) {
    return 'Acheter Premium via $store';
  }

  @override
  String storePremiumBilling(String store) {
    return 'Premium est un achat distinct et unique, sans renouvellement automatique. $store affiche le prix et traite le paiement. Premium est lié à votre compte Origo connecté.';
  }

  @override
  String storePremiumRestoreHelp(String store) {
    return 'Connectez-vous au compte Origo lié et restaurez Premium avec le compte $store utilisé lors de l’achat. Aucun nouveau paiement ne sera effectué.';
  }

  @override
  String storeReaderTrialExpiresAt(String date) {
    return 'L’essai de la version de base se termine le $date.';
  }

  @override
  String get storeReaderPurchaseSuccess => 'Version de base achetée';

  @override
  String get storeReaderRestoreSuccess =>
      'Achat de la version de base restauré';

  @override
  String get storeReaderTestPurchaseVerified =>
      'Achat test de la version de base vérifié ; aucune licence définitive accordée.';

  @override
  String get storeReaderPurchaseRevoked =>
      'L’achat de cette version de base a été révoqué.';

  @override
  String storeReaderPendingApproval(String store) {
    return 'En attente de l’approbation de $store. La version de base sera activée après vérification.';
  }

  @override
  String get storeReaderVerifying =>
      'Vérification de l’achat de la version de base…';

  @override
  String get storeReaderRestoring =>
      'Restauration de l’achat de la version de base…';
}
