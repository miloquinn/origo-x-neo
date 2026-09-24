// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Inicio';

  @override
  String get library => 'Estantería';

  @override
  String get bookSources => 'Fuentes';

  @override
  String get discover => 'Descubrir';

  @override
  String get discoverRecommended => 'Para ti';

  @override
  String get discoverCategories => 'Categorías';

  @override
  String get discoverLatest => 'Novedades';

  @override
  String get discoverLoadFailed =>
      'No se pudo cargar el contenido de descubrimiento';

  @override
  String get discoverRetry => 'Reintentar';

  @override
  String get discoverEmptyTitle => 'Aún no hay nada que mostrar';

  @override
  String get discoverEmptyMessage =>
      'Esta sección todavía no tiene contenido que mostrar.';

  @override
  String get discoverUnsupportedTitle =>
      'Las fuentes actuales no son compatibles con esta sección';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'Se necesita una fuente con la función $capability. Aún puedes buscar en las fuentes existentes.';
  }

  @override
  String get discoverCategoryEmpty =>
      'Todavía no hay libros que mostrar en esta categoría.';

  @override
  String get bookSourceChannelLoadFailed => 'No se pudo cargar el canal';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'La fuente no devolvió libros utilizables: $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'No se pudo conectar con el servidor de la fuente tras probar sus direcciones de red disponibles. Inténtalo de nuevo más tarde.';

  @override
  String get bookSourceRedirectFailed =>
      'El sitio de la fuente siguió redirigiendo. Las cookies del sitio se conservaron, pero la dirección sigue sin devolver contenido.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'El sitio de la fuente devolvió HTTP $status. Puede que la dirección del canal esté obsoleta o bloqueada por el sitio.';
  }

  @override
  String get bookSourceStandardLayout => 'Diseño estándar';

  @override
  String get bookSourceListLayout => 'Diseño de lista';

  @override
  String get bookSourceChangeChannel => 'Cambiar';

  @override
  String get bookSourceChangeSourceTitle => 'Cambiar fuente';

  @override
  String get bookSourceChangeCurrentSource => 'Fuente actual';

  @override
  String get bookSourceChangeTargetSource => 'Cambiar a';

  @override
  String get bookSourceChangeNotSelected => 'Sin seleccionar';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'Actualmente en el capítulo $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Buscar este libro en otras fuentes';

  @override
  String get bookSourceChangeSearchAgain => 'Buscar de nuevo';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Buscar en todas las fuentes restantes';

  @override
  String get bookSourceChangeCheckAuthor => 'Coincidir autor';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return 'Comprobadas $completed de $total';
  }

  @override
  String get bookSourceChangeNoOtherSources =>
      'No hay otras fuentes disponibles';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Añade y activa primero otra fuente que admita búsquedas.';

  @override
  String get bookSourceChangeSearching => 'Buscando otras fuentes';

  @override
  String get bookSourceChangeSearchingHint =>
      'Las coincidencias aparecen a medida que cada fuente termina de buscar.';

  @override
  String get bookSourceChangeNoMatches =>
      'No se encontraron fuentes coincidentes';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Edita el título o desactiva la coincidencia de autor y busca de nuevo.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return '$count solicitud(es) a fuentes fallaron. Puedes buscar de nuevo.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Autor diferente';

  @override
  String get bookSourceChangeValidating =>
      'Comprobando el catálogo y el capítulo actual…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Validación fallida: $details';
  }

  @override
  String get bookSourceChangeReadable => 'Capítulo actual legible';

  @override
  String bookSourceChangeChapterCount(int count) {
    return '$count capítulos';
  }

  @override
  String bookSourceChangeResponseTime(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get bookSourceChangeTapToValidate =>
      'Selecciona para comprobar el catálogo y el capítulo actual.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Esta versión de la fuente ya está en la estantería.';

  @override
  String get bookSourceChangeSwitching => 'Cambiando de fuente…';

  @override
  String get bookSourceChangeSwitchAction => 'Cambiar a esta fuente';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Fuente cambiada a $source';
  }

  @override
  String bookSourceChannelCount(int count) {
    return '$count canales';
  }

  @override
  String get bookSourceManagementTitle => 'Gestionar fuentes';

  @override
  String get bookSourceManagementSubtitle =>
      'Añade, activa, elimina e inspecciona proveedores de contenido. Descubrir se centra en encontrar libros.';

  @override
  String get settingsContentSourcesTitle => 'Fuentes de contenido';

  @override
  String get settingsContentSourcesSubtitle =>
      'Añade, activa o elimina fuentes de libros abiertas';

  @override
  String get bookSourcesSubtitle =>
      'Conecta fuentes abiertas y busca contenido legible entre proveedores';

  @override
  String get bookSourcesAdd => 'Añadir fuente';

  @override
  String get bookSourcesSearchHint =>
      'Busca en las fuentes activadas por título o autor';

  @override
  String get bookSourcesSearch => 'Buscar';

  @override
  String get bookSourcesLoadMore => 'Cargar más';

  @override
  String bookSourcesFailedCount(int count) {
    return '$count solicitud(es) a fuentes fallaron';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Ajustes de búsqueda';

  @override
  String get bookSourcesSearchSettingsTitle => 'Ajustes de búsqueda';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Solicitudes simultáneas';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Tiempo de espera por fuente (s)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Límite de fuentes';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Cuando hay muchas fuentes activadas, solo se busca a la vez en esta cantidad (en orden de lista), para limitar el uso de red y batería.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return 'Hay $enabledCount fuentes activadas, por encima del límite actual de $limit. Las fuentes que superan el límite no se buscarán.';
  }

  @override
  String get bookSourcesSearchResetDefaults =>
      'Restablecer valores predeterminados';

  @override
  String get bookSourcesSearchPrompt =>
      'Añade y activa una fuente para buscarla aquí';

  @override
  String get bookSourcesNoResults => 'No se encontraron libros coincidentes';

  @override
  String get bookSourcesNoSourcesTitle => 'Aún no hay fuentes';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Pega la dirección de un servicio compatible con el Origo Source Protocol.';

  @override
  String get bookSourcesManageTitle => 'Fuentes conectadas';

  @override
  String get bookSourcesEnabled => 'Activada';

  @override
  String get bookSourcesDisabled => 'Desactivada';

  @override
  String get bookSourcesRunnable => 'Lista para usar';

  @override
  String get bookSourcesPendingCompatibility => 'Sin reglas ejecutables';

  @override
  String get bookSourcesRequiresLogin => 'Requiere inicio de sesión';

  @override
  String get bookSourcesManagementSearchHint =>
      'Busca por nombre, URL, notas o grupo';

  @override
  String get bookSourcesClearSearch => 'Borrar búsqueda';

  @override
  String get bookSourcesAllGroups => 'Todos los grupos';

  @override
  String get bookSourcesChooseGroup => 'Elige un grupo de fuentes';

  @override
  String get bookSourcesSearchGroups => 'Grupos de búsqueda';

  @override
  String get bookSourcesNoMatchingSources =>
      'Ninguna fuente coincide con la búsqueda y los filtros actuales';

  @override
  String get bookSourcesResetFilters => 'Restablecer';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return 'Mostrando $visible de $total';
  }

  @override
  String get bookSourcesRemove => 'Eliminar';

  @override
  String get bookSourcesRemoveTitle => 'Eliminar fuente';

  @override
  String get bookSourcesRemoveMessage =>
      'Esto solo elimina la configuración de la fuente. Los libros locales no se ven afectados.';

  @override
  String get bookSourcesCancel => 'Cancelar';

  @override
  String get bookSourcesConfirm => 'Confirmar';

  @override
  String get bookSourcesAddTitle => 'Añadir fuente';

  @override
  String get bookSourcesImportLink => 'Importar enlace';

  @override
  String get bookSourcesAnalyze => 'Leer fuentes';

  @override
  String get bookSourcesDetectedOrsp => 'Detectado: ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Detectado: Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'Fuentes ORSP';

  @override
  String get bookSourcesProtocolGroupAdditional =>
      'Fuentes de otros protocolos';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Esta fuente no está disponible para la cuenta o los ajustes actuales.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Ninguna fuente pasó la comprobación de búsqueda en vivo. No se importó nada.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return 'Comprobadas $completed/$total; $available funcionan';
  }

  @override
  String get bookSourcesSelect => 'Seleccionar fuentes';

  @override
  String get bookSourcesSelectAll => 'Seleccionar todo';

  @override
  String get bookSourcesClearSelection => 'Borrar selección';

  @override
  String get bookSourcesEnableSelected => 'Activar seleccionadas';

  @override
  String get bookSourcesDisableSelected => 'Desactivar seleccionadas';

  @override
  String get bookSourcesExportSelected => 'Exportar seleccionadas';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return 'Se exportaron $count fuente(s) a $location';
  }

  @override
  String get bookSourcesExportFailed =>
      'No se pudieron exportar las fuentes seleccionadas';

  @override
  String get bookSourcesExportUnsupported =>
      'La exportación de fuentes aún no es compatible con esta plataforma';

  @override
  String get bookSourcesExportReplaceTitle =>
      '¿Reemplazar el archivo existente?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Ya existe un archivo en $path. ¿Quieres reemplazarlo?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Reemplazar';

  @override
  String get bookSourcesDeleteSelected => 'Eliminar seleccionadas';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return '¿Eliminar $count fuentes seleccionadas? Los libros locales no se ven afectados.';
  }

  @override
  String get bookSourcesCheckSelected => 'Comprobar seleccionadas';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return '$healthy de $total fuente(s) están en buen estado';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Comprobar y limpiar fuentes';

  @override
  String get bookSourcesCleanupNoCheckableSources =>
      'No hay fuentes que comprobar';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Las $count fuente(s) comprobadas están totalmente disponibles';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Resultados de estado';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return '$fullyAvailable totalmente disponibles · $needsAttention por revisar';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Que falten funciones o que se agote el tiempo de espera no significa que una fuente sea inutilizable. Selecciona solo las fuentes que quieras desactivar.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return 'Desactivar $count seleccionadas';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return 'Se desactivaron $count fuente(s)';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Detenida: se comprobaron $count fuente(s). Vuelve a ejecutarla más tarde para continuar donde lo dejaste.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Mantenimiento de fuentes';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Encuentra duplicados y comprueba la disponibilidad de las fuentes';

  @override
  String get bookSourcesMaintenanceHealthTitle =>
      'Comprobación de estado de fuentes';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Prueba la búsqueda y la lectura; reutiliza resultados recientes en buen estado';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Comprobación de estado de fuentes en curso';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Limpieza de duplicados';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Compara fuentes localmente, sin conexión de red';

  @override
  String get bookSourcesMaintenanceReviewTitle =>
      'Último resultado de la comprobación';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return '$count fuente(s) necesitan atención';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Solo se desactivan las fuentes que confirmes. Sus configuraciones se conservan.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Comprobando fuentes';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Comprobando búsqueda, detalles, catálogos y contenido';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Comprobación de estado de fuentes completada';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return 'Comprobadas $checked fuente(s); $attention necesitan atención';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Detener comprobación';

  @override
  String get bookSourcesMaintenanceBackground => 'Continuar en segundo plano';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Cierra esta vista de progreso y la comprobación seguirá en silencio mientras la app esté en ejecución.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'La comprobación de estado de fuentes continúa en silencio en segundo plano';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Revisar resultados';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Mantenimiento de fuentes $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Buscar fuentes duplicadas';

  @override
  String get bookSourcesDedupeNone => 'No se encontraron fuentes duplicadas';

  @override
  String get bookSourcesDedupeReviewTitle => 'Revisar fuentes duplicadas';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return '$groups grupo(s), $duplicates fuente(s) duplicada(s)';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'La fuente recomendada se conserva. Los duplicados seleccionados se desactivarán, no se eliminarán.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return 'Desactivar $count seleccionadas';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return 'Se desactivaron $count fuente(s) duplicada(s)';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Exacta';

  @override
  String get bookSourcesDedupeModeStandard => 'Estándar';

  @override
  String get bookSourcesDedupeModeSite => 'Mismo sitio';

  @override
  String get bookSourcesDedupeExactReason => 'Misma identidad de fuente';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Misma dirección de fuente normalizada';

  @override
  String get bookSourcesDedupeSiteReason => 'Mismo sitio; se requiere revisión';

  @override
  String get bookSourcesDedupeRecommended => 'Recomendada';

  @override
  String get bookSourcesDedupeReviewAction => 'Revisar deduplicación';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return '$ready listas, $duplicates duplicadas, $errors no válidas';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return '$books libro · $comics cómic · $unsupported no ejecutables actualmente';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults => 'Restablecer recomendaciones';

  @override
  String get bookSourcesUrlLabel => 'Dirección de la fuente';

  @override
  String get bookSourcesUrlHint =>
      'https://example.com o una URL JSON de fuente';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'Origo X no incluye fuentes y no gestiona, recomienda ni respalda servicios de fuentes de terceros. Cada dirección de fuente la añades tú.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Confirmo que estoy autorizado a acceder a este contenido y que no usaré la fuente para eludir inicios de sesión, pagos, DRM u otros controles de acceso.';

  @override
  String get bookSourcesConnect => 'Leer e importar';

  @override
  String get bookSourcesConnecting => 'Procesando fuentes…';

  @override
  String get bookSourcesAdded => 'Fuente añadida';

  @override
  String get bookSourcesRefresh => 'Actualizar fuente';

  @override
  String get bookSourcesRefreshed => 'Fuente de libros actualizada';

  @override
  String get bookSourcesRefreshFailed =>
      'No se pudo actualizar esta fuente de libros';

  @override
  String get bookSourcesProtocolTitle => 'Origo Source Protocol';

  @override
  String get bookSourcesInformationTitle => 'Protocolo e información';

  @override
  String get bookSourcesInformationSubtitle =>
      'Consulta el protocolo, los enlaces del proyecto y la información sobre derechos de contenido';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'Conoce las funciones de fuente admitidas y el protocolo abierto';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Ver el repositorio del protocolo en GitHub';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'Comprende el contenido de terceros y los límites de derechos';

  @override
  String get bookSourcesProtocolDescription =>
      'Un contrato común para descubrimiento, búsqueda, detalles de libros, catálogos y contenido de capítulos. Los desarrolladores pueden alojar fuentes nativas o crear adaptadores para contenido que estén autorizados a servir.';

  @override
  String get bookSourcesProtocolDetails => 'Ver protocolo';

  @override
  String get bookSourcesProtocolRepository => 'Repositorio del protocolo';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Ver en GitHub';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'No se pudo abrir el repositorio del protocolo';

  @override
  String get bookSourcesProtocolDialogTitle =>
      'Protocolo abierto de fuentes v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Una fuente publica /.well-known/open-reading-source.json e implementa las funciones de Core Reading: búsqueda, detalles de libros, catálogos de capítulos paginados y contenido de capítulos. La versión 1.4 mantiene la paginación completa del catálogo, exige estas funciones básicas y conserva los metadatos de operador, contacto, licencia y declaración de derechos para fuentes HTTP(S) públicas que no requieren inicio de sesión.';

  @override
  String get bookSourcesRightsDetails => 'Operador y derechos';

  @override
  String get bookSourcesOperator => 'Operador de la fuente';

  @override
  String get bookSourcesContentLicense => 'Licencia del contenido';

  @override
  String get bookSourcesRightsStatement => 'Declaración de derechos';

  @override
  String get bookSourcesRightsNotProvided => 'No proporcionado por esta fuente';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Estas declaraciones las suministra el operador independiente de la fuente. Origo X las muestra por transparencia, pero no las verifica ni las respalda.';

  @override
  String get bookSourcesContactOperator => 'Contactar con el operador';

  @override
  String get bookSourcesRightsReport => 'Informe de derechos';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'No se pudo abrir el formulario de informe de derechos';

  @override
  String get bookSourcesClose => 'Cerrar';

  @override
  String get sourceLoginTitle => 'Inicio de sesión en la fuente';

  @override
  String get sourceLoginInfo => 'Datos de inicio de sesión';

  @override
  String get sourceLoginActions => 'Acciones de la fuente';

  @override
  String get sourceLoginExtraSettings => 'Ajustes adicionales';

  @override
  String get sourceLoginSecureStorageNotice =>
      'Los datos de inicio de sesión permanecen en el almacenamiento seguro del sistema de este dispositivo.';

  @override
  String get sourceLoginNoForm =>
      'Esta fuente no ofrece ningún método de inicio de sesión disponible.';

  @override
  String get sourceLoginBrowserTitle =>
      'Iniciar sesión en el sitio web original';

  @override
  String get sourceLoginBrowserNotice =>
      'Completa el inicio de sesión en el navegador y toca Listo. Las cookies y el almacenamiento local del sitio se guardarán en este dispositivo.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'El inicio de sesión en el sitio web está disponible en Android, iPhone, iPad y Mac.';

  @override
  String get sourceLoginBrowserOpen => 'Abrir el sitio web para iniciar sesión';

  @override
  String get sourceLoginSave => 'Iniciar sesión y guardar la sesión';

  @override
  String get sourceLoginClear => 'Borrar la sesión de inicio de sesión';

  @override
  String get sourceLoginSaved => 'Sesión de la fuente actualizada';

  @override
  String get sourceLoginCleared => 'Sesión de la fuente borrada';

  @override
  String sourceLoginFailed(String details) {
    return 'No se pudo actualizar la sesión de la fuente: $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '“$sourceName” ofrece inicio de sesión para contenido exclusivo de cuentas.';
  }

  @override
  String get sourceDebugMenuLabel => 'Depurar';

  @override
  String get sourceDebugTitle => 'Depurador de fuentes';

  @override
  String get sourceDebugInputHint =>
      'Escribe una palabra clave de búsqueda o pega una URL de libro, catálogo o capítulo';

  @override
  String get sourceDebugRun => 'Ejecutar';

  @override
  String get sourceDebugStop => 'Detener';

  @override
  String get sourceDebugClear => 'Borrar registro';

  @override
  String get sourceDebugEmpty =>
      'Escribe una palabra clave o URL y toca Ejecutar para ver cada paso de cómo esta fuente la resuelve.';

  @override
  String get sourceDebugCopy => 'Copiar';

  @override
  String get sourceDebugCopied => 'Copiado al portapapeles';

  @override
  String get sourceHealthMenuLabel => 'Comprobar estado';

  @override
  String get sourceHealthHealthy => 'En buen estado';

  @override
  String get sourceHealthPartial => 'Parcialmente averiada';

  @override
  String get bookSourcesFullyAvailable => 'Totalmente disponible';

  @override
  String get sourceHealthTimedOut => 'Tiempo de comprobación agotado';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Averiada: $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'búsqueda';

  @override
  String get sourceHealthCapabilityDiscover => 'descubrir';

  @override
  String get sourceHealthCapabilityInfo => 'info del libro';

  @override
  String get sourceHealthCapabilityCatalog => 'catálogo';

  @override
  String get sourceHealthCapabilityContent => 'contenido';

  @override
  String get sourceVerificationTitle => 'Verificación de la fuente';

  @override
  String get sourceVerificationBrowserHint =>
      'Completa la comprobación del sitio en el navegador seguro y elige Verificación completada. La dirección de la página y las cookies vuelven solo a esta tarea de fuente.';

  @override
  String get sourceVerificationCodeHint =>
      'Lee la imagen y escribe su código para continuar con esta tarea de fuente.';

  @override
  String get sourceVerificationCodeLabel => 'Código de imagen';

  @override
  String get sourceVerificationSubmit => 'Continuar';

  @override
  String get sourceVerificationRetry => 'Abrir el navegador de nuevo';

  @override
  String get sourceVerificationCancel => 'Cancelar verificación';

  @override
  String sourceVerificationFailed(String details) {
    return 'No se pudo abrir la verificación de la fuente: $details';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get reading => 'Lectura';

  @override
  String get importBooks => 'Importar libros';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get accent => 'Color de acento';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get notes => 'Notas';

  @override
  String get highlights => 'Resaltados';

  @override
  String get ttsReading => 'Texto a voz';

  @override
  String get share => 'Compartir';

  @override
  String get shareContent => 'Compartir contenido';

  @override
  String get shareCurrentPage => 'Compartir página actual';

  @override
  String get shareSelectedText => 'Compartir texto seleccionado';

  @override
  String get shareProgress => 'Compartir progreso de lectura';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Detener';

  @override
  String get speed => 'Velocidad';

  @override
  String get pitch => 'Tono';

  @override
  String get language => 'Idioma';

  @override
  String get fontSize => 'Tamaño de letra';

  @override
  String get readingProgress => 'Progreso de lectura';

  @override
  String get totalPages => 'Páginas totales';

  @override
  String get currentPage => 'Página actual';

  @override
  String get readingTime => 'Tiempo de lectura';

  @override
  String get booksRead => 'Libros leídos';

  @override
  String get todayReading => 'Lectura de hoy';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get search => 'Buscar';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get initializationFailed => 'Error de inicialización';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get retry => 'Reintentar';

  @override
  String get appearanceSettings => 'Apariencia';

  @override
  String get readingTips => 'Consejos de lectura';

  @override
  String get readingFontSettingsMoved =>
      'Los ajustes de letra de lectura se han movido';

  @override
  String get readingFontSettingsHint =>
      'Abre cualquier libro, toca el centro de la pantalla y usa la barra de herramientas inferior para ajustar el tamaño de letra, el interlineado, el espaciado entre letras, los márgenes y la fuente de lectura.';

  @override
  String get readingSettings => 'Ajustes de lectura';

  @override
  String get enableTts => 'Activar TTS';

  @override
  String get enableTtsHint => 'Activa la lectura en voz alta';

  @override
  String get ttsSpeedLabel => 'Velocidad';

  @override
  String get ttsSpeedHint => 'Ajusta la velocidad de lectura';

  @override
  String get ttsVolumeLabel => 'Volumen';

  @override
  String get ttsVolumeHint => 'Ajusta el volumen de lectura';

  @override
  String get ttsPitchLabel => 'Tono';

  @override
  String get ttsPitchHint => 'Ajusta el tono de lectura';

  @override
  String get appSettings => 'Ajustes de la app';

  @override
  String get appFont => 'Fuente de la app';

  @override
  String get appFontDescription =>
      'La usan la navegación, los botones, los ajustes y otro texto de la interfaz. No cambia el contenido de los libros.';

  @override
  String get readerFont => 'Fuente de lectura';

  @override
  String get readerFontDescription =>
      'Se usa solo para el texto de los libros y los títulos de capítulos. No cambia la interfaz de la app.';

  @override
  String get readerFontSelectionDescription =>
      'Elige el tipo de letra para leer. Predeterminada de la plataforma mantiene las fuentes incrustadas por los editores de EPUB cuando están disponibles.';

  @override
  String get readerFontBookPriorityHint =>
      'Usa la fuente incrustada del libro cuando está disponible; si no, usa la fuente de lectura predeterminada de la plataforma.';

  @override
  String get readerFontOverrideHint =>
      'Anula las fuentes incrustadas por el editor.';

  @override
  String get fontSystem => 'Predeterminada de la plataforma';

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
      'Usa una fuente de lectura optimizada para la plataforma, con glifos y paginación estables.';

  @override
  String get fontSerifDescription =>
      'Tipografía serif de carácter sereno y editorial para lecturas prolongadas.';

  @override
  String get fontSansSerifDescription =>
      'Tipografía sans serif clara, ideal para interfaces compactas y lectura cotidiana.';

  @override
  String get fontMonospaceDescription =>
      'Tipografía de ancho fijo, indicada para código, material técnico y diseños centrados.';

  @override
  String get fontPreviewText => 'Origo X · Lee con libertad 开卷有益';

  @override
  String get customFonts => 'Mis fuentes';

  @override
  String get customFontsEmpty => 'Aún no hay fuentes personalizadas';

  @override
  String get customFontsEmptyHint =>
      'Importa una vez un archivo TTF u OTF y úsala para la interfaz de la app o la lectura.';

  @override
  String customFontsCount(int count) {
    return '$count fuentes importadas';
  }

  @override
  String get customFontsLocalOnly =>
      'Las fuentes importadas se guardan solo en este dispositivo y no se sincronizan automáticamente.';

  @override
  String get builtInFonts => 'Fuentes integradas';

  @override
  String get onlineFonts => 'Fuentes en línea';

  @override
  String get fontDownload => 'Descargar';

  @override
  String get fontDownloading => 'Descargando…';

  @override
  String get fontDownloaded => 'Descargada';

  @override
  String get fontDownloadFailed => 'Error de descarga; toca para reintentar';

  @override
  String get fontDownloadHint => 'El primer uso requiere una descarga en línea';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Grosor ajustable $min–$max';
  }

  @override
  String get fontStaticWeight => 'Grosor fijo (la negrita se sintetiza)';

  @override
  String get fontDeleteDownload => 'Eliminar descarga';

  @override
  String fontDeleteDownloadTitle(String name) {
    return '¿Eliminar la descarga de \"$name\"?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Liberará $size de almacenamiento. Se volverá a descargar la próxima vez que la uses.';
  }

  @override
  String get fontDownloadCancelled => 'Descarga cancelada';

  @override
  String get fontDownloadNetworkFailed => 'Error de red; la descarga falló';

  @override
  String get fontDownloadInvalid =>
      'El archivo de fuente descargado no es válido';

  @override
  String get fontDownloadUnsupported =>
      'La descarga de fuentes en línea no es compatible con esta plataforma';

  @override
  String get importFont => 'Importar fuente';

  @override
  String get importingFont => 'Importando fuente…';

  @override
  String get customFontImported => 'Fuente importada';

  @override
  String get customFontAlreadyImported =>
      'Esta fuente ya estaba importada y está lista para usar';

  @override
  String get customFontApplied => 'Selección de fuente actualizada';

  @override
  String get customFontAppliedToApp =>
      'Importada y establecida como fuente de la app';

  @override
  String get customFontAppliedToReader =>
      'Importada y establecida como fuente de lectura';

  @override
  String get customFontImportUnsupported =>
      'La importación persistente de fuentes aún no es compatible con esta plataforma.';

  @override
  String get customFontUnsupportedFormat =>
      'Elige un archivo de fuente TTF u OTF.';

  @override
  String get customFontInvalid =>
      'Este archivo no es una fuente válida o compatible.';

  @override
  String get customFontTooLarge => 'El archivo de fuente supera los 50 MB.';

  @override
  String get customFontReadFailed => 'No se pudo leer el archivo de fuente.';

  @override
  String get customFontLoadFailed => 'No se pudo cargar la fuente.';

  @override
  String get customFontStorageFailed =>
      'No se pudo guardar la fuente en este dispositivo.';

  @override
  String get customFontUnavailable =>
      'El archivo de fuente no está disponible. Elimínala e impórtala de nuevo.';

  @override
  String get setAsAppFont => 'Usar como fuente de la app';

  @override
  String get setAsReaderFont => 'Usar como fuente de lectura';

  @override
  String get setAsBothFonts => 'Usar para ambas';

  @override
  String get renameFont => 'Renombrar fuente';

  @override
  String deleteCustomFontTitle(String name) {
    return '¿Eliminar “$name”?';
  }

  @override
  String get deleteCustomFontMessage =>
      'El archivo de la fuente se eliminará de este dispositivo.';

  @override
  String get deleteCustomFontInUse =>
      'Esta fuente está en uso actualmente. Si la eliminas, los ajustes de fuente afectados volverán a sus valores predeterminados.';

  @override
  String get deleteAndReset => 'Eliminar y restablecer';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Canal oficial de Telegram';

  @override
  String get settingsTelegramOpenFailed =>
      'No se pudo abrir el enlace de Telegram';

  @override
  String get settingsQqChannel => 'Canal de QQ';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'No se pudo abrir el enlace de invitación del Canal de QQ';

  @override
  String get languageSystem => 'Seguir el sistema';

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
  String get typographySettings => 'Tipografía';

  @override
  String get fontFamilyLabel => 'Fuente';

  @override
  String get fontSizeLabel => 'Tamaño de letra';

  @override
  String get readerFontWeightLabel => 'Grosor de la fuente';

  @override
  String get readerFontWeightLight => 'Ligera';

  @override
  String get readerFontWeightRegular => 'Normal';

  @override
  String get readerFontWeightMedium => 'Media';

  @override
  String get readerFontWeightSemiBold => 'Seminegrita';

  @override
  String get readerFontWeightBold => 'Negrita';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'Los controles de lectura usan cinco pasos legibles de 300 a 700. El rango completo real de esta fuente es $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'Los controles de lectura usan cinco pasos de 300 a 700. Esta fuente no declara un eje de grosor variable, así que el sistema aproxima el resultado y puede variar según la plataforma.';

  @override
  String get readerFontWeightPreview =>
      'Una página tranquila llega más lejos · 字里行间';

  @override
  String get lineSpacingLabel => 'Interlineado';

  @override
  String get letterSpacingLabel => 'Espaciado entre letras';

  @override
  String get textAlignmentLabel => 'Alineación del texto';

  @override
  String get textAlignmentNatural => 'Natural';

  @override
  String get textAlignmentJustified => 'Justificado';

  @override
  String get firstLineIndentLabel => 'Sangría de primera línea';

  @override
  String get paragraphSpacingLabel => 'Espaciado entre párrafos';

  @override
  String get pageMarginLabel => 'Margen de página';

  @override
  String get resetDefault => 'Restablecer';

  @override
  String get ttsPanelTitle => 'Texto a voz';

  @override
  String get ttsPreviewEffect => 'Vista previa del efecto';

  @override
  String get ttsVolume => 'Volumen';

  @override
  String get ttsPitch => 'Tono';

  @override
  String get ttsSpeed => 'Velocidad';

  @override
  String get ttsPreviousSentence => 'Frase anterior';

  @override
  String get ttsNextSentence => 'Frase siguiente';

  @override
  String get ttsTimerStop => 'Temporizador';

  @override
  String get ttsTimerOff => 'Sin límite';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes minutos';
  }

  @override
  String get ttsPlaying => 'Reproduciendo';

  @override
  String get ttsPaused => 'En pausa';

  @override
  String get ttsStopped => 'Detenida';

  @override
  String get ttsPreviousSentenceFailed =>
      'No se pudo reproducir la frase anterior';

  @override
  String get ttsNextSentenceFailed =>
      'No se pudo reproducir la frase siguiente';

  @override
  String get ttsEmptyContentError =>
      'El contenido de la página actual está vacío';

  @override
  String get ttsPlaybackFailed => 'Error de reproducción';

  @override
  String get ttsOperationFailed => 'Error en la operación';

  @override
  String get pageTurningMode => 'Modo de página';

  @override
  String get pageTurningSlide => 'Deslizamiento horizontal';

  @override
  String get pageTurningScroll => 'Paginación vertical';

  @override
  String get tapZoneSettings => 'Zonas táctiles';

  @override
  String get tapZoneNextPage => 'Página siguiente';

  @override
  String get tapZonePreviousPage => 'Página anterior';

  @override
  String get tapZoneMenu => 'Menú';

  @override
  String get tapZoneLegend => 'Leyenda';

  @override
  String get tapZoneNextChapter => 'Capítulo siguiente';

  @override
  String get tapZonePreviousChapter => 'Capítulo anterior';

  @override
  String get tapZoneNone => 'Sin acción';

  @override
  String get tapZoneSettingsHint =>
      'Personaliza qué hace cada una de las nueve áreas táctiles';

  @override
  String get tapZoneChooseAction => 'Elige una acción';

  @override
  String get tapZoneMenuRequiredHint =>
      'Toca un área para cambiar su acción. Al menos una área debe seguir siendo Menú; si eliminas todos los Menús, el área central vuelve a ser Menú.';

  @override
  String get tapZoneReset => 'Restablecer valores predeterminados';

  @override
  String get highlightColor => 'Color de resaltado';

  @override
  String get highlightPreview => 'Vista previa';

  @override
  String get highlightSampleText => 'Este es un texto de ejemplo,';

  @override
  String get highlightSampleText2 => 'esta parte se resaltará,';

  @override
  String get highlightSampleText3 => 'mostrando el efecto de resaltado.';

  @override
  String get colorLightBlue => 'Azul claro';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorPurple => 'Morado';

  @override
  String get colorGold => 'Dorado';

  @override
  String get colorOrange => 'Naranja';

  @override
  String get colorYellow => 'Amarillo';

  @override
  String get colorDarkGreen => 'Verde oscuro';

  @override
  String get colorCustom => 'Personalizado';

  @override
  String get noteTypeHighlight => 'Resaltado';

  @override
  String get noteTypeUnderline => 'Subrayado';

  @override
  String get noteTypeNote => 'Nota';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Importar libro';

  @override
  String get importFromFiles => 'Importar desde Archivos';

  @override
  String get importNoBooks => 'Aún no se han importado libros';

  @override
  String get importSuccess => 'Libro importado correctamente';

  @override
  String get importFailed => 'Error de importación';

  @override
  String get importProcessing => 'Procesando libro...';

  @override
  String get author => 'Autor';

  @override
  String get progress => 'Progreso';

  @override
  String get continueReading => 'Seguir leyendo';

  @override
  String get recentBooks => 'Libros recientes';

  @override
  String get allBooks => 'Todos los libros';

  @override
  String get emptyLibrary => 'La biblioteca está vacía';

  @override
  String get deleteBook => 'Eliminar libro';

  @override
  String get deleteBookConfirm => '¿Seguro que quieres eliminar este libro?';

  @override
  String get bookDeleted => 'Libro eliminado';

  @override
  String get userAgreement => 'Acuerdo de usuario';

  @override
  String get acceptAgreement => 'Lo he leído y acepto';

  @override
  String get declineAgreement => 'Rechazar';

  @override
  String get statsToday => 'Hoy';

  @override
  String get statsThisWeek => 'Esta semana';

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
    return '$count libros';
  }

  @override
  String get statsConsecutiveDays => 'Días consecutivos';

  @override
  String get statsFocusTime => 'Tiempo de concentración';

  @override
  String get statsThisWeekTotal => 'Total de esta semana';

  @override
  String get statsKeepReading => 'Lee a diario';

  @override
  String get statsMaxSession => 'Sesión más larga';

  @override
  String get statsWeeklyTrend => 'Tendencia semanal';

  @override
  String get statsAchievements => 'Logros';

  @override
  String get readerToolbarMenu => 'Menú';

  @override
  String get readerToolbarTOC => 'Índice';

  @override
  String get readerToolbarSettings => 'Ajustes';

  @override
  String get readerAddBookmark => 'Añadir marcador';

  @override
  String get readerAddNote => 'Añadir nota';

  @override
  String get readerShare => 'Compartir';

  @override
  String get bookmarkAdded => 'Marcador añadido';

  @override
  String get bookmarkRemoved => 'Marcador eliminado';

  @override
  String get readerNavigationTitle => 'Navegación de lectura';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Capítulo $current de $total';
  }

  @override
  String get readerSearchChapters => 'Buscar capítulos';

  @override
  String get readerBackToCurrentChapter => 'Volver al capítulo actual';

  @override
  String get readerCurrentChapter => 'Actual';

  @override
  String get readerCurrentPosition => 'Posición actual';

  @override
  String get readerNoChapterResults => 'No hay capítulos coincidentes';

  @override
  String get readerNoChapterResultsHint =>
      'Prueba con otra palabra del título del capítulo.';

  @override
  String get readerNoBookmarks => 'Aún no hay marcadores';

  @override
  String get readerNoBookmarksHint =>
      'Toca el botón de marcador de la esquina superior derecha para guardar tu lugar.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Añade este libro a la estantería antes de guardar marcadores';

  @override
  String get themeBlue => 'Azul océano';

  @override
  String get themeGreen => 'Verde bosque';

  @override
  String get themeOrange => 'Naranja vibrante';

  @override
  String get themeRed => 'Rojo pasión';

  @override
  String get themeCustom => 'Personalizado';

  @override
  String get tapZoneLeftRight => 'Izquierda/Derecha';

  @override
  String get tapZoneLeftCenterRight => 'Izquierda/Centro/Derecha';

  @override
  String get homeTagline => 'Lee con belleza';

  @override
  String get homeReadingStatsTitle => 'Estadísticas de lectura';

  @override
  String get homeTodayReadingMoment => 'Tu momento de lectura de hoy';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return 'Has leído $minutes minutos; sigue así';
  }

  @override
  String get homeTodayReadingJourneyStart => 'Empieza hoy tu viaje de lectura';

  @override
  String get homeTodayReadingKeepRhythm =>
      'Hoy vas por buen camino; mantén el ritmo';

  @override
  String get homeTodayReadingPrompt => 'Reserva hoy algo de tiempo para leer';

  @override
  String homeTotalReadingHours(String hours) {
    return 'Lectura total: $hours horas';
  }

  @override
  String get homeWeeklyReading => 'Esta semana';

  @override
  String get homeTotalReading => 'Lectura total';

  @override
  String get homeLibraryCount => 'Libros en la biblioteca';

  @override
  String get homeCollectionCount => 'Colección';

  @override
  String get homeKeyMetrics => 'Métricas clave';

  @override
  String get homeReadingRhythm => 'Ritmo de lectura';

  @override
  String get homeAchievements => 'Logros de lectura';

  @override
  String get homeConsecutiveReading => 'Lectura consecutiva';

  @override
  String get homeConsecutiveReadingDesc => 'Mantén un hábito de lectura diario';

  @override
  String get homeFocusDuration => 'Duración de concentración';

  @override
  String get homeFocusDurationDesc => 'Sesión de lectura más larga';

  @override
  String get homeWeeklyTotal => 'Total semanal';

  @override
  String get homeWeeklyTotalDesc => 'Tiempo de lectura de esta semana';

  @override
  String get homeRecentReading => 'Lecturas recientes';

  @override
  String get homeWeeklyTrend => 'Tendencia de lectura semanal';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get unitMinute => 'min';

  @override
  String get unitHour => 'hora';

  @override
  String get unitBook => 'libros';

  @override
  String get unitDay => 'días';

  @override
  String get weekdayMonShort => 'Lun';

  @override
  String get weekdayTueShort => 'Mar';

  @override
  String get weekdayWedShort => 'Mié';

  @override
  String get weekdayThuShort => 'Jue';

  @override
  String get weekdayFriShort => 'Vie';

  @override
  String get weekdaySatShort => 'Sáb';

  @override
  String get weekdaySunShort => 'Dom';

  @override
  String get agreementTagline =>
      'Lectura inmersiva · Asistente de IA · Local primero';

  @override
  String get agreementCardTitle => 'Acuerdo de servicio al usuario';

  @override
  String get agreementCardSubtitle => 'Lee atentamente lo siguiente';

  @override
  String get agreementWelcomeTitle => 'Bienvenido a Origo X';

  @override
  String get agreementWelcomeBody =>
      'Para garantizar una experiencia de lectura estable y predecible, lee y acepta primero el siguiente acuerdo.';

  @override
  String get agreementFeatureFormatsTitle =>
      'Compatibilidad con múltiples formatos';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI y más';

  @override
  String get agreementFeatureCustomizationTitle => 'Lectura personalizada';

  @override
  String get agreementFeatureCustomizationBody =>
      'Personaliza fuentes, colores, tipografía y más';

  @override
  String get agreementFeatureSyncTitle => 'Local primero';

  @override
  String get agreementFeatureSyncBody =>
      'Los libros, el progreso y las notas permanecen en el dispositivo que tú controlas';

  @override
  String get agreementFeatureTtsTitle => 'Texto a voz';

  @override
  String get agreementFeatureTtsBody =>
      'La narración inteligente por voz libera tus ojos para que escuches donde quieras';

  @override
  String get agreementTapToAgreeHint =>
      'Al tocar \"Aceptar y continuar\", confirmas que has leído y aceptas usar esta app';

  @override
  String get agreementExitApp => 'Salir de la app';

  @override
  String get agreementAgreeAndContinue => 'Aceptar y continuar';

  @override
  String get agreementExitDialogContent =>
      'Si no aceptas el acuerdo de usuario, no podrás usar esta app. ¿Seguro que quieres salir?';

  @override
  String get agreementConfirmExit => 'Salir';

  @override
  String get readerFileMissing =>
      'No se encontró el archivo del libro. Vuelve a importarlo.';

  @override
  String get readerUnsupportedFormat =>
      'Este formato todavía no se puede leer.';

  @override
  String get readerKindleDrmProtected =>
      'Este libro de Kindle está protegido con DRM y no se puede leer aquí. Solo se admiten libros sin DRM.';

  @override
  String get readerComicNoPages =>
      'No se encontraron páginas de imagen en este archivo de cómic.';

  @override
  String get readerComicCbrUnsupported =>
      'Este cómic CBR usa compresión RAR real y todavía no se puede leer. Conviértelo a CBZ.';

  @override
  String get readerComicArchiveUnsupported =>
      'El formato de archivo de este cómic todavía no se puede leer. Conviértelo a CBZ.';

  @override
  String get readerComicChapterNoPages =>
      'Este capítulo no tiene páginas de imagen.';

  @override
  String get imageReaderSettings => 'Ajustes de lectura';

  @override
  String get imageReaderDirectionTitle => 'Dirección de lectura';

  @override
  String get imageReaderDirectionVertical => 'Vertical continuo';

  @override
  String get imageReaderDirectionLtr => 'De izquierda a derecha';

  @override
  String get imageReaderDirectionRtl => 'De derecha a izquierda (manga)';

  @override
  String get imageReaderJumpToPage => 'Ir a la página';

  @override
  String get imageReaderBackgroundTitle => 'Fondo de página';

  @override
  String get imageReaderBackgroundBlack => 'Negro';

  @override
  String get imageReaderBackgroundGray => 'Gris';

  @override
  String get imageReaderBackgroundWhite => 'Blanco';

  @override
  String get readerPdfLinuxUnsupported =>
      'La lectura de PDF aún no está disponible en Linux.';

  @override
  String get bootstrapImageManagerFailed =>
      'No se pudo inicializar el gestor de imágenes';

  @override
  String homeFocusCompleted(int minutes) {
    return 'Sesión de concentración de $minutes minutos completada. ¡Bien hecho!';
  }

  @override
  String get homeDailyReadingGoal => 'Objetivo de lectura diario';

  @override
  String get homeAiAdviceSection => 'Consejos de lectura con IA';

  @override
  String get homeTodayGlance => 'Hoy de un vistazo';

  @override
  String get homeViewAll => 'Ver todo';

  @override
  String get homeGoalDoneSuggestReview =>
      'El objetivo de hoy está completo; plantéate un repaso de lectura';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Solo $minutes minutos más para alcanzar el objetivo de hoy';
  }

  @override
  String get homePickBookHint =>
      'Elige un libro de tu estantería para continuar y completa primero 1 sesión de concentración.';

  @override
  String homeContinueBookHint(String title) {
    return 'Continúa primero \"$title\" y luego cambia a otros libros.';
  }

  @override
  String get homeTodayActionAdvice => 'Plan de acción de hoy';

  @override
  String homeProgressPercent(int percent) {
    return '$percent% de progreso';
  }

  @override
  String homeStreakDays(int days) {
    return 'Racha de $days días';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes min esta semana';
  }

  @override
  String get homePlanLoading => 'Cargando plan';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Objetivo: $minutes min/día';
  }

  @override
  String get homeAiAdviceForYou => 'Consejos de lectura con IA para ti';

  @override
  String homeBasedOnBook(String title) {
    return 'Basado en \"$title\"';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Lectura de hoy (min)';

  @override
  String get homeTotalReadingMinutesLabel => 'Lectura total (min)';

  @override
  String get homeGeneratingPlan => 'Generando el plan de lectura de hoy...';

  @override
  String get homeCompletedLabel => 'Hecho';

  @override
  String get homeTodayGoalAchieved => 'Objetivo de hoy alcanzado';

  @override
  String homeMinutesRemaining(int minutes) {
    return '$minutes minutos restantes';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return 'Leídos $read / $goal min';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'Unas $sessions sesiones de concentración para terminar el objetivo de hoy';
  }

  @override
  String get homeStreakLabel => 'Racha';

  @override
  String get homeWeekAchievedLabel => 'Objetivo semanal';

  @override
  String get homeFocusLabel => 'Concentración';

  @override
  String homeDaysCount(int days) {
    return '$days días';
  }

  @override
  String homeTimesCount(int times) {
    return '$times veces';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Cuenta atrás de concentración $time';
  }

  @override
  String get homeGoLibraryRead => 'Leer desde la biblioteca';

  @override
  String get homeEndFocus => 'Terminar concentración';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Concentración de $minutes min';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Ajustar objetivo: $minutes min';
  }

  @override
  String get homeNoRecentReading =>
      'Aún no hay lecturas recientes. Abre un libro de tu biblioteca para empezar.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Progreso $percent%';
  }

  @override
  String get librarySearchHint => 'Busca por título o autor';

  @override
  String libraryFilterAll(int count) {
    return 'Todos $count';
  }

  @override
  String libraryFilterReading(int count) {
    return 'Leyendo $count';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Terminados $count';
  }

  @override
  String get libraryFilterTooltip => 'Filtrar por estado de lectura';

  @override
  String get libraryNoMatchingBooks => 'No hay libros coincidentes';

  @override
  String get libraryNoReadingBooks => 'No hay libros en curso';

  @override
  String get libraryNoFinishedBooks => 'No hay libros terminados';

  @override
  String get libraryNoBooks => 'Aún no hay libros';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · Continuar leyendo';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Página $page';
  }

  @override
  String get libraryStartFromBeginning => 'Empezar desde el principio';

  @override
  String get libraryBookInfo => 'Info del libro';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · $pages páginas';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · $chapters capítulos';
  }

  @override
  String get libraryRenameBook => 'Renombrar';

  @override
  String get libraryRenameBookHint =>
      'Cambia el título; el archivo en el disco también se renombra';

  @override
  String get libraryRenameBookSuccess => 'Renombrado';

  @override
  String get libraryRenameBookFailed => 'No se pudo renombrar el libro';

  @override
  String get libraryCustomCover => 'Portada personalizada';

  @override
  String get libraryCustomCoverHint =>
      'Elige una imagen para usarla como portada de este libro';

  @override
  String get libraryCustomCoverSuccess => 'Portada actualizada';

  @override
  String get libraryCoverUnsupportedFormat => 'Formato de imagen no compatible';

  @override
  String get libraryCoverFileTooLarge => 'La imagen supera el límite de 20 MB';

  @override
  String get libraryCoverReadFailed => 'No se pudo leer la imagen seleccionada';

  @override
  String get libraryCoverSaveFailed => 'No se pudo guardar la portada';

  @override
  String get libraryResetCover => 'Restaurar portada predeterminada';

  @override
  String get libraryResetCoverHint =>
      'Quita la portada personalizada y restaura la original';

  @override
  String get libraryResetCoverSuccess => 'Portada predeterminada restaurada';

  @override
  String get libraryExportBook => 'Exportar archivo del libro';

  @override
  String get libraryExportOriginalHint =>
      'Copia el archivo original a otra ubicación';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Exporta el libro descargado como un archivo TXT generado';

  @override
  String bookExportSuccess(String location) {
    return 'Exportado a $location';
  }

  @override
  String get bookExportSourceMissing =>
      'Falta el archivo del libro y no se puede exportar';

  @override
  String get bookExportUnsupported =>
      'La exportación de libros aún no es compatible con esta plataforma';

  @override
  String get bookExportFailed => 'No se pudo exportar el libro';

  @override
  String get bookExportInProgress => 'Exportando libro…';

  @override
  String get incomingBooksImporting => 'Importando un libro desde otra app…';

  @override
  String get incomingBooksNoBookFile =>
      'El contenido compartido no contiene ningún archivo de libro importable';

  @override
  String get incomingBooksPermissionExpired =>
      'El acceso al archivo ha caducado. Comparte o abre de nuevo el archivo';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Este formato de libro no es compatible';

  @override
  String get incomingBooksFileTooLarge =>
      'El archivo supera el límite de importación de 500 MB';

  @override
  String get incomingBooksTooManyFiles =>
      'Se compartieron demasiados archivos de libro a la vez. Añádelos en lotes más pequeños';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Algunos archivos no se pudieron reconocer; los libros restantes continuarán';

  @override
  String get incomingBooksContentMismatch =>
      'El formato del archivo no coincide con su contenido';

  @override
  String get incomingBooksImportFailed =>
      'No se pudo importar el libro desde otra app';

  @override
  String get libraryDeleteBookHint => 'Este libro se eliminará permanentemente';

  @override
  String get libraryBookTitle => 'Título';

  @override
  String get libraryFormat => 'Formato';

  @override
  String libraryPagesCount(int pages) {
    return '$pages páginas';
  }

  @override
  String get totalChapters => 'Capítulos totales';

  @override
  String get currentChapter => 'Capítulo actual';

  @override
  String libraryChaptersCount(int chapters) {
    return '$chapters capítulos';
  }

  @override
  String get libraryClose => 'Cerrar';

  @override
  String get libraryConfirmDeleteTitle => 'Confirmar eliminación';

  @override
  String libraryDeleteBookMessage(String title) {
    return '¿Eliminar \"$title\"? El archivo se eliminará permanentemente de tu dispositivo.';
  }

  @override
  String libraryDeletingBook(String title) {
    return 'Eliminando \"$title\"...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '\"$title\" eliminado';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get libraryReadingBadge => 'Leyendo';

  @override
  String get libraryDeletingBookFile => 'Eliminando archivo del libro...';

  @override
  String get libraryDeletingCoverImage => 'Eliminando imagen de portada...';

  @override
  String get libraryCleaningDatabase =>
      'Limpiando registros de la base de datos...';

  @override
  String get libraryDeleteComplete => 'Eliminación completada';

  @override
  String get librarySelectMultiple => 'Selección múltiple';

  @override
  String get librarySelectAll => 'Seleccionar todo';

  @override
  String librarySelectedBooks(int count) {
    return '$count seleccionados';
  }

  @override
  String libraryDeleteSelected(int count) {
    return 'Eliminar $count';
  }

  @override
  String get libraryBatchDeleteTitle => '¿Eliminar los libros seleccionados?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Esto elimina permanentemente los $count libros seleccionados, las notas y marcadores relacionados, y los archivos locales. No se puede deshacer.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return 'Eliminando $done/$total';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return 'Se eliminaron $count libros';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return 'Eliminados $success; $failed fallaron';
  }

  @override
  String get readerPrefaceTitle => 'Preliminares';

  @override
  String get readerModeHorizontalPage => 'Sin animación';

  @override
  String get readerModeVerticalScrollHint =>
      'Desliza páginas prepaginadas verticalmente; desliza lateralmente para cambiar de capítulo';

  @override
  String get readerModeWholeBookScrollHint =>
      'Los capítulos prepaginados forman una lista vertical posicionable';

  @override
  String get readerScrollByChapterTitle => 'Desplazar por capítulo';

  @override
  String get readerScrollByChapterOnHint =>
      'Pasa página a página dentro de un capítulo y desliza lateralmente para cambiar de capítulo';

  @override
  String get readerScrollByChapterOffHint =>
      'Todos los capítulos se enlazan página a página en una lista vertical posicionable';

  @override
  String get readerModeHorizontalPageHint =>
      'Toca el lado izquierdo para la página anterior y el derecho para la siguiente';

  @override
  String get readerModeHorizontalSlideHint =>
      'Las páginas siguen tu dedo horizontalmente y encajan en su sitio';

  @override
  String get readerModeCoverSlide => 'Cubierta';

  @override
  String get readerModeCoverSlideHint =>
      'La página actual se desliza hacia la izquierda, descubriendo la página siguiente debajo';

  @override
  String get readerModePageCurl => 'Vuelta de página';

  @override
  String get readerModePageCurlHint =>
      'Arrastra lateralmente para curvar la página y suelta para girarla o que vuelva';

  @override
  String get readerTextBrightnessLabel => 'Brillo del texto';

  @override
  String get readerDimTextInDarkModeTitle => 'Atenuar el texto en modo oscuro';

  @override
  String get readerDimTextInDarkModeHint =>
      'Usa un 70 % de brillo en modo oscuro';

  @override
  String readerFontSizeValue(int size) {
    return 'Tamaño de letra  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Margen horizontal  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Margen horizontal';

  @override
  String get readerTopMarginLabel => 'Margen superior';

  @override
  String get readerBottomMarginLabel => 'Margen inferior';

  @override
  String get readerTxtChapterTitlePageTitle =>
      'Título del capítulo en su propia página';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Cuando está desactivado, el título del capítulo aparece sobre el cuerpo del texto';

  @override
  String get readerVerticalMarginLabel => 'Margen vertical';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Margen vertical  $margin';
  }

  @override
  String readerChapterCount(int count) {
    return '$count capítulos';
  }

  @override
  String readerChapterFallback(int number) {
    return 'Capítulo $number';
  }

  @override
  String readerOpenFailed(String error) {
    return 'Error al abrir: $error';
  }

  @override
  String get readerNoContent => 'Este libro no tiene contenido legible';

  @override
  String readerStatusPaged(
    int chapter,
    int chapterCount,
    int page,
    int pageCount,
  ) {
    return 'Capítulo $chapter/$chapterCount · Página $page/$pageCount';
  }

  @override
  String readerStatusScroll(int chapter, int chapterCount) {
    return 'Capítulo $chapter/$chapterCount · Desplazamiento vertical';
  }

  @override
  String get importPreparing => 'Preparando la importación...';

  @override
  String importFailedWithError(String error) {
    return 'Error de importación: $error';
  }

  @override
  String get importLocalFile => 'Archivos locales';

  @override
  String get settingsAiTempHintMinimax =>
      'Temperatura: MiniMax recomienda de 0.01 a 1.00';

  @override
  String get settingsAiCustomConfigTitle => 'Configuración de IA personalizada';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Proveedor actual: $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'La temperatura de MiniMax debe estar entre 0.01 y 1.00';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'La temperatura está fuera de rango; sigue la indicación';

  @override
  String get settingsApply => 'Aplicar';

  @override
  String get settingsAiCustomApplied =>
      'Parámetros personalizados aplicados; recuerda guardar la configuración';

  @override
  String get settingsAiApiKeyRequired => 'La API Key no puede estar vacía';

  @override
  String get settingsAiModelRequired => 'El modelo no puede estar vacío';

  @override
  String get settingsAiBaseUrlInvalid =>
      'La URL base debe ser una dirección http/https válida';

  @override
  String get settingsAiSettingsSaved => 'Ajustes de IA guardados';

  @override
  String settingsSaveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle =>
      'Pasar páginas con las teclas de volumen';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Usa las teclas de volumen en los modos de lectura paginados';

  @override
  String get settingsAutoResumeReadingTitle => 'Reanudar la lectura al abrir';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Si sales de la app mientras lees, la próxima vez volverá al punto donde lo dejaste';

  @override
  String get settingsShowStatusBarTitle =>
      'Mostrar la barra de estado del sistema al leer';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Interfaz de batería/hora del lector oculta';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Usando la interfaz de batería/hora del lector';

  @override
  String get readerTopBarStyleTitle => 'Información superior';

  @override
  String get readerTopBarStyleSystem => 'Barra de estado del sistema';

  @override
  String get readerTopBarStyleSystemHint =>
      'Muestra la hora, la señal y la batería del sistema';

  @override
  String get readerTopBarStyleReader => 'Barra de información del lector';

  @override
  String get readerTopBarStyleReaderHint =>
      'Muestra la hora, el título del capítulo y la batería';

  @override
  String get readerTopBarStyleFloating => 'Barra de información flotante';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Muestra la hora y la batería en la zona de la barra de estado sin ocupar espacio de lectura';

  @override
  String get readerTopBarStyleHidden => 'Totalmente inmersivo';

  @override
  String get readerTopBarStyleHiddenHint =>
      'No muestra información en la parte superior';

  @override
  String get settingsAiAssistantTitle => 'Asistente de lectura con IA';

  @override
  String get settingsSystemSettingsTitle => 'Ajustes del sistema';

  @override
  String get settingsSectionAppearanceFonts => 'Apariencia y fuentes';

  @override
  String get settingsSectionDataServices => 'Datos y servicios';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionAdvancedFeatures => 'Funciones avanzadas';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Más protocolos de fuentes';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Activa la compatibilidad con protocolos de fuente adicionales.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Permitir fuentes en redes privadas';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Permite fuentes de libros en este dispositivo, la red local y otras direcciones privadas. Deja esto desactivado salvo que confíes en la fuente.';

  @override
  String get additionalSourcesImport => 'Importar más protocolos de fuentes';

  @override
  String get additionalSourcesImportTitle => 'Importar JSON de fuentes';

  @override
  String get additionalSourcesImportNotice =>
      'La importación solo analiza y deduplica localmente; no comprueba cada fuente en línea. Las fuentes con reglas ejecutables conservan su estado de activación importado y cada función se comprueba al usarse.';

  @override
  String get additionalSourcesChooseFile => 'Añadir desde archivo JSON';

  @override
  String get additionalSourcesUrlLabel => 'URL del JSON de fuentes';

  @override
  String get additionalSourcesLoadUrl => 'Cargar URL';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return '$supported disponibles, $partial parcialmente compatibles, $unsupported no compatibles';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return '$supported de reglas estándar, $partial de reglas ampliadas, $unsupported de reglas avanzadas, $skipped omitidas';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return '$count fuentes listas para importar, $skipped omitidas';
  }

  @override
  String get additionalSourcesAvailable => 'Disponible';

  @override
  String get additionalSourcesPartial => 'Parcialmente compatible';

  @override
  String get additionalSourcesUnsupported => 'No compatible';

  @override
  String get additionalSourcesImportConfirm => 'Importar todo';

  @override
  String additionalSourcesImported(int count) {
    return 'Se importaron $count fuentes';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return 'Se importaron $count fuentes; se omitieron $conflicted cuyo id ya estaba registrado desde otro origen';
  }

  @override
  String get settingsSectionAboutSupport => 'Acerca de y soporte';

  @override
  String get settingsKeepScreenOnTitle => 'Mantener la pantalla encendida';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Evita que la pantalla se apague mientras lees';

  @override
  String get settingsPowerSavingModeTitle => 'Modo de ahorro de energía';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Limita la app a 60 fps en lugar de usar una tasa de refresco alta';

  @override
  String get settingsAutoSaveTitle => 'Guardado automático';

  @override
  String get settingsAutoSaveSubtitle =>
      'Guarda el progreso de lectura automáticamente';

  @override
  String get settingsHelpPlaceholder => 'Aquí puede ir la información de ayuda';

  @override
  String get settingsAiConfigured => 'IA configurada';

  @override
  String get settingsAiNotConfigured => 'Aún no hay API Key configurada';

  @override
  String get settingsAiReadyToUse => 'Lista para usar';

  @override
  String get settingsAiPendingConfig => 'Pendiente de configurar';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Preajuste actual: $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Configuración actual: personalizada · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'Los proveedores y modelos habituales están integrados; normalmente basta con elegir un preajuste e introducir una API Key.';

  @override
  String get settingsAiProviderLabel => 'Proveedor';

  @override
  String get settingsAiCustomProvider => 'Personalizado';

  @override
  String get settingsAiProtocolLabel => 'Protocolo de API';

  @override
  String get settingsAiProtocolOpenAi => 'Compatible con OpenAI';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Selecciona un modelo preajustado';

  @override
  String get settingsAiPresetLabel => 'Modelo preajustado';

  @override
  String get settingsAiCustomButton => 'Personalizado';

  @override
  String get settingsAiPresetSelectedHint =>
      'Tras seleccionar un preajuste, solo tienes que introducir una API Key para empezar a usarlo.';

  @override
  String get settingsAiCustomActiveHint =>
      'Hay parámetros personalizados en uso; puedes volver a un preajuste en cualquier momento.';

  @override
  String get settingsAiApiKeyHint =>
      'Introdúcela para activar el preajuste actual';

  @override
  String get settingsShow => 'Mostrar';

  @override
  String get settingsHide => 'Ocultar';

  @override
  String get settingsAiSaving => 'Guardando...';

  @override
  String get settingsAiSaveConfig => 'Guardar configuración de IA';

  @override
  String get settingsPageIntro =>
      'Solo las opciones que moldean tu experiencia de lectura.';

  @override
  String get settingsSupportDevelopmentTitle => 'Apoyar el desarrollo';

  @override
  String get firstHomeSupportNow => 'Apoyar ahora';

  @override
  String get firstHomeSupportLater => 'Quizá más tarde';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Una carta del desarrollador de Origo X pidiendo apoyo voluntario';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Apoyar el desarrollo';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'Las donaciones son voluntarias y apoyan el desarrollo continuo.';

  @override
  String get settingsAccountGuestTitle => 'Inicia sesión en Origo X';

  @override
  String get settingsAccountGuestSubtitle =>
      'Sincroniza tu perfil y tus ajustes de seguridad.';

  @override
  String get settingsAccountOpen => 'Centro de cuenta';

  @override
  String get settingsAccountVerified => 'Cuenta verificada';

  @override
  String get accountPageTitle => 'Cuenta';

  @override
  String get accountIntroTitle => 'Cuenta';

  @override
  String get accountPageSubtitle =>
      'Inicia sesión para sincronizar tu perfil y los ajustes de tu cuenta.';

  @override
  String get accountLoginTab => 'Correo y contraseña';

  @override
  String get accountRegisterTab => 'Registrarse';

  @override
  String get accountCodeTab => 'Código por correo';

  @override
  String get accountResetTab => 'Restablecer';

  @override
  String get accountEmail => 'Correo electrónico';

  @override
  String get accountEmailRequired => 'Introduce tu correo electrónico';

  @override
  String get accountEmailFirstHint =>
      'Introduce tu correo para continuar. El inicio de sesión con contraseña es lo predeterminado.';

  @override
  String get accountContinue => 'Continuar';

  @override
  String get accountPasswordLoginTitle => 'Iniciar sesión con contraseña';

  @override
  String get accountPasswordLoginHint =>
      'Introduce tu contraseña o usa un código por correo.';

  @override
  String get accountUseEmailCode => 'Iniciar sesión con un código por correo';

  @override
  String get accountNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get accountForgotPassword => 'Olvidé mi contraseña';

  @override
  String get accountHaveAccount => '¿Ya registrado? Vuelve al inicio de sesión';

  @override
  String get accountBackToPassword =>
      'Volver al inicio de sesión con contraseña';

  @override
  String get accountChangeEmail => 'Cambiar';

  @override
  String get accountRegisterHint =>
      'Verifica tu correo y luego crea una cuenta y contraseña.';

  @override
  String get accountCodeLoginHint =>
      'Enviaremos un código al correo seleccionado.';

  @override
  String get accountResetHint =>
      'Verifica tu correo y luego elige una contraseña nueva.';

  @override
  String get accountPassword => 'Contraseña';

  @override
  String get accountConfirmPassword => 'Confirmar contraseña';

  @override
  String get accountAvatarCropTitle => 'Recortar avatar';

  @override
  String get accountAvatarCropHint =>
      'Arrastra para reposicionar y pellizca para ampliar hasta que el sujeto quede dentro del círculo.';

  @override
  String get accountUsername => 'Nombre de usuario';

  @override
  String get accountDisplayName => 'Nombre visible';

  @override
  String get accountVerificationCode => 'Código de verificación';

  @override
  String get accountSendCode => 'Enviar código';

  @override
  String get accountSignIn => 'Iniciar sesión';

  @override
  String get accountCreate => 'Crear cuenta';

  @override
  String get accountResetPassword => 'Restablecer contraseña';

  @override
  String get accountUseApple => 'Iniciar sesión con Apple';

  @override
  String get accountUseGithub => 'Iniciar sesión con GitHub';

  @override
  String get accountUseGoogle => 'Continuar con Google';

  @override
  String get accountUsePasskey => 'Continuar con Passkey';

  @override
  String get accountMoreSignInMethods => 'Más métodos de inicio de sesión';

  @override
  String get accountExternalHint =>
      'Se abrirá un navegador seguro. Vuelve aquí tras aprobarlo.';

  @override
  String get accountProfileTitle => 'Perfil';

  @override
  String get accountEditProfile => 'Editar perfil';

  @override
  String get accountSignInMethodsTitle => 'Métodos de inicio de sesión';

  @override
  String get accountSaveProfile => 'Guardar perfil';

  @override
  String get accountChangeAvatar => 'Cambiar avatar';

  @override
  String get accountRemoveAvatar => 'Quitar avatar';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSupportTitle => 'Membresía Premium';

  @override
  String get accountSupportFreeSubtitle =>
      'Las funciones básicas de lectura son de uso gratuito.';

  @override
  String get accountSupportAction => 'Obtener Premium';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Al menos 12 caracteres';

  @override
  String get accountUsernameHint =>
      'De 3 a 30 letras minúsculas, números o guiones bajos';

  @override
  String get settingsDonationAction => 'Donar con WeChat';

  @override
  String get settingsAlipayDonationAction => 'Donar con Alipay';

  @override
  String get settingsDonationDialogTitle => 'Donación con WeChat';

  @override
  String get settingsDonationDialogHint =>
      'Escanea el código QR con WeChat para apoyar el desarrollo continuo. Gracias.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Donación con Alipay';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Escanea el código QR con Alipay para apoyar el desarrollo continuo. Gracias.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'Las donaciones son completamente opcionales. No desbloquean funciones ni constituyen una compra ni un contrato de servicio.';

  @override
  String get settingsDonationQrCodeLabel => 'Código QR de donación de WeChat';

  @override
  String get settingsAlipayDonationQrCodeLabel =>
      'Código QR de donación de Alipay';

  @override
  String get settingsAiSwipeHint =>
      'Desliza por los modelos, toca para cambiar y mantén pulsado para editar o eliminar.';

  @override
  String get settingsAiLegacyIntro =>
      'Elige un proveedor y un modelo, e introduce tu API key.';

  @override
  String get settingsAiModelLabel => 'Modelo';

  @override
  String get settingsAiUsingCustomParams =>
      'Usando ajustes de modelo personalizados';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Guardada solo en este dispositivo';

  @override
  String get settingsAiSaveAndEnable => 'Guardar y activar';

  @override
  String get settingsAboutTagline => 'Multiplataforma, centrado en la lectura';

  @override
  String get settingsVersionLabel => 'Versión';

  @override
  String get changelogHistoryTitle => 'Historial de versiones';

  @override
  String get changelogHistorySubtitle => 'Consulta los cambios de cada versión';

  @override
  String get openSourceLicensesTitle => 'Licencias de código abierto y fuentes';

  @override
  String get openSourceLicensesSubtitle =>
      'Consulta las licencias de la app, las fuentes incluidas y el software de terceros';

  @override
  String get openSourceLicensesIntro =>
      'Estos textos y avisos de licencia están disponibles sin conexión en la app. Origo X, las fuentes bajo demanda y el software de terceros siguen sujetos a sus respectivas licencias.';

  @override
  String get openSourceProjectSection => 'Licencias del proyecto';

  @override
  String get openSourceLegacyLicenseTitle => 'Versiones anteriores';

  @override
  String get openSourceFontsSection => 'Licencias de fuentes';

  @override
  String get openSourceDependenciesSection => 'Software de terceros';

  @override
  String get openSourceDependenciesTitle => 'Dependencias de Flutter y Dart';

  @override
  String get openSourceDependenciesSubtitle =>
      'Consulta las licencias de terceros recopiladas automáticamente por Flutter';

  @override
  String get openSourceLicenseLegalese =>
      'Origo X y los componentes de terceros siguen sujetos a sus respectivas licencias.';

  @override
  String get openSourceLicenseLoadFailed =>
      'No se pudo cargar el texto de la licencia.';

  @override
  String get changelogPageTitle => 'Historial de versiones';

  @override
  String get changelogCurrentVersion => 'Versión actual';

  @override
  String get changelogLoadFailed =>
      'No se pudo cargar el historial de versiones';

  @override
  String get settingsMaintainerLabel => 'Mantenedor';

  @override
  String get settingsLicenseLabel => 'Licencia';

  @override
  String get settingsViewSourceSubtitle => 'Ver proyecto de código abierto';

  @override
  String get settingsJoinQqGroup => 'Unirse al grupo de QQ';

  @override
  String get settingsQqOpenFailed =>
      'No se pudo abrir QQ. Asegúrate de que QQ esté instalado.';

  @override
  String get settingsDarkModeTitle => 'Modo nocturno';

  @override
  String settingsCurrentValue(String value) {
    return 'Actual: $value';
  }

  @override
  String get settingsUiStyleTitle => 'Efecto cristal';

  @override
  String get settingsGlassEffectSubtitle =>
      'Usa superficies translúcidas, desenfoque de fondo y profundidad flotante';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Ocultar etiquetas de la navegación inferior';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'Muestra solo iconos en la navegación inferior del móvil';

  @override
  String get settingsFloatingNavigationTitle => 'Barra de navegación flotante';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Ajusta tamaño, estilo de visualización y orden de destinos';

  @override
  String get floatingNavigationPreviewTitle => 'Vista previa';

  @override
  String get floatingNavigationSizeTitle => 'Tamaño';

  @override
  String get floatingNavigationSizeAutomatic => 'Automático';

  @override
  String get floatingNavigationSizeCustom => 'Personalizado';

  @override
  String get floatingNavigationHeightLabel => 'Altura';

  @override
  String get floatingNavigationSideMarginLabel => 'Margen lateral';

  @override
  String get floatingNavigationDisplayModeTitle => 'Estilo de visualización';

  @override
  String get floatingNavigationIconsOnly => 'Solo iconos';

  @override
  String get floatingNavigationIconsAndLabels => 'Iconos y etiquetas';

  @override
  String get floatingNavigationOrderTitle => 'Orden de navegación';

  @override
  String get floatingNavigationOrderHint =>
      'Mantén pulsado el tirador de la derecha para reordenar';

  @override
  String get floatingNavigationSyncHint =>
      'El orden también se aplica a la navegación por deslizamiento y a la barra lateral de pantallas anchas';

  @override
  String get floatingNavigationResetOrder => 'Restaurar orden predeterminado';

  @override
  String get floatingNavigationResetDone => 'Orden predeterminado restaurado';

  @override
  String get settingsLibraryLayoutTitle => 'Ajustes de la biblioteca';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Ajusta el diseño de la biblioteca y la experiencia de apertura de libros';

  @override
  String get settingsLibraryLayoutCard => 'Tarjetas';

  @override
  String get settingsLibraryLayoutGrid => 'Cuadrícula';

  @override
  String get settingsLibraryGridColumnsTitle =>
      'Portadas por fila en teléfonos';

  @override
  String get settingsLibraryGridTwoColumns => '2 columnas';

  @override
  String get settingsLibraryGridThreeColumns => '3 columnas';

  @override
  String get settingsLibraryGridShowDetailsTitle => 'Mostrar título y progreso';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Añade una línea de título y una barra compacta de progreso bajo cada portada';

  @override
  String get settingsLibraryOpenAnimationTitle => 'Animación al abrir libros';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Se usa solo al abrir un libro desde la biblioteca';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Ampliación clásica de portada';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Amplía la portada original a pantalla completa antes de mostrar el lector';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Desvanecimiento mínimo';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Desvanece el texto sin movimiento direccional';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Ascenso del papel';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'El papel de lectura se asienta suavemente desde abajo';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Deslizamiento de página';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'La página de lectura entra con un breve movimiento lateral';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Ritmo de animación';

  @override
  String get settingsLibraryOpenAnimationFast => 'Rápido';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Aparece rápidamente una vez que el texto está listo';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Elegante';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Revela el texto de forma más gradual para una transición más serena';

  @override
  String get settingsAccentFollowTheme => 'Color de acento: seguir el tema';

  @override
  String settingsAccentValue(String name) {
    return 'Color de acento: $name';
  }

  @override
  String get settingsAppThemeTitle => 'Tema de la app';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Actual: $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'Seguir el tema de la app';

  @override
  String get settingsAccentColorTitle => 'Color de acento';

  @override
  String get settingsThemeModeSystemHint =>
      'Cambia automáticamente con la apariencia del sistema';

  @override
  String get settingsThemeModeLightHint => 'Usa siempre la apariencia clara';

  @override
  String get settingsThemeModeDarkHint => 'Usa siempre la apariencia oscura';

  @override
  String get settingsSelectAppTheme => 'Elige el tema de la app';

  @override
  String get settingsDone => 'Listo';

  @override
  String get settingsAccentColorAdvice =>
      'El color de acento genera los esquemas de color completos de Material 3 en claro y oscuro.';

  @override
  String get settingsAccentPresetColors => 'Colores rápidos';

  @override
  String get settingsAccentCustomColor => 'Color personalizado';

  @override
  String get settingsAccentSaturationBrightness =>
      'Campo de saturación y brillo';

  @override
  String get settingsAccentHue => 'Tono';

  @override
  String get settingsAccentPreview => 'Vista previa de la paleta del tema';

  @override
  String get settingsAccentFollowThemeOption => 'Seguir el tema';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Usa el color de acento predeterminado del tema actual de la app';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Mantenedor: 小元Niki';

  @override
  String get settingsGithubRepo => 'Repositorio de GitHub';

  @override
  String get settingsNewYearGreeting =>
      'Un lector multiplataforma centrado, contenido y libremente modificable.';

  @override
  String get settingsGithubOpenFailed => 'No se pudo abrir el enlace de GitHub';

  @override
  String get settingsOfficialWebsite => 'Sitio web oficial';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Descarga e instala desde open.xxread.top';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'No se pudo abrir el sitio web oficial';

  @override
  String get updateCheckNow => 'Buscar actualizaciones';

  @override
  String get updateCheckNowSubtitle =>
      'Consigue la última versión desde GitHub o el sitio web oficial';

  @override
  String get updateAppStoreManaged =>
      'Esta versión de la Mac App Store se actualiza a través del App Store';

  @override
  String get updateAvailableTitle => 'Hay una nueva versión disponible';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Versión actual: $currentVersion\nVersión más reciente: $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Novedades';

  @override
  String get updateNotesEmpty =>
      'No se proporcionaron notas de la versión para esta versión.';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateSkipVersion => 'Omitir esta versión';

  @override
  String get updateGoToDownload => 'Ir a la actualización';

  @override
  String get updateFromGithub => 'Actualizar desde GitHub';

  @override
  String get updateFromWebsite => 'Abrir el sitio web oficial';

  @override
  String get updateFromWebsiteInstall => 'Descargar del sitio web';

  @override
  String get updateWebsiteUnavailable =>
      'El paquete del sitio web oficial aún no está disponible para este dispositivo';

  @override
  String get updateDownloadingTitle => 'Descargando actualización';

  @override
  String updateDownloadProgress(int percent) {
    return 'Descargado $percent%';
  }

  @override
  String get updatePreparingInstaller =>
      'Verificando el paquete y preparando el instalador del sistema…';

  @override
  String get updateDownloadFailed =>
      'No se pudo descargar la actualización desde el sitio web oficial';

  @override
  String get updateIntegrityFailed =>
      'La actualización descargada no superó la comprobación de integridad y se eliminó';

  @override
  String get updateInstallFailed =>
      'No se pudo instalar el paquete de actualización. Comprueba los permisos de instalación e inténtalo de nuevo.';

  @override
  String get updateAlreadyLatest => 'Ya estás usando la última versión';

  @override
  String get updateCheckFailed =>
      'No se pudieron buscar actualizaciones. Inténtalo de nuevo más tarde.';

  @override
  String get updateOpenFailed => 'No se pudo abrir el enlace';

  @override
  String get settingsIosOnlyFeature =>
      'Esta función solo está disponible en iOS';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Sincronizado con $storage\n$books libros, $files archivos copiados';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Este cambio de ajustes requiere reiniciar la app para surtir efecto por completo.';

  @override
  String get settingsRestartRequiredTitle => 'Reinicio necesario';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\n¿Reiniciar la app ahora?';
  }

  @override
  String get settingsRestartLater => 'Más tarde';

  @override
  String get settingsRestartNow => 'Reiniciar';

  @override
  String get statsDetailedTitle => 'Estadísticas detalladas';

  @override
  String get statsRange7Days => '7 días';

  @override
  String get statsRange30Days => '30 días';

  @override
  String get statsRange90Days => '90 días';

  @override
  String get statsRange1Year => '1 año';

  @override
  String get statsRangeAll => 'Todo';

  @override
  String get statsTabOverview => 'Resumen';

  @override
  String get statsTabCharts => 'Gráficas';

  @override
  String get statsTabBooks => 'Libros';

  @override
  String get statsTabAchievements => 'Logros';

  @override
  String get statsReadingOverview => 'Resumen de lectura';

  @override
  String statsCumulativeHours(Object hours) {
    return 'Total $hours horas';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Mantén el ritmo: has leído $days días seguidos';
  }

  @override
  String get statsTotalDuration => 'Tiempo total';

  @override
  String get statsAvgSession => 'Sesión promedio';

  @override
  String statsDaysCount(Object count) {
    return '$count días';
  }

  @override
  String get statsNoData => 'Sin datos';

  @override
  String get statsPeriodEarlyMorning => 'Madrugada 05:00-08:59';

  @override
  String get statsPeriodMorning => 'Mañana 09:00-11:59';

  @override
  String get statsPeriodAfternoon => 'Tarde 12:00-17:59';

  @override
  String get statsPeriodEvening => 'Noche 18:00-21:59';

  @override
  String get statsPeriodLateNight => 'Trasnoche 22:00-04:59';

  @override
  String get statsTotalReadingTime => 'Tiempo total de lectura';

  @override
  String get statsTotalPagesRead => 'Páginas leídas en total';

  @override
  String get statsBooksReadCount => 'Libros leídos';

  @override
  String get statsUnitPage => 'páginas';

  @override
  String get statsTodayProgress => 'Progreso de lectura de hoy';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target min';
  }

  @override
  String get statsPagesRead => 'Páginas leídas';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target páginas';
  }

  @override
  String get statsReadingHabits => 'Hábitos de lectura';

  @override
  String get statsBestReadingPeriod => 'Mejor momento para leer';

  @override
  String get statsAvgSessionReading => 'Sesión promedio de lectura';

  @override
  String get statsMaxStreakDays => 'Racha más larga';

  @override
  String get statsFocusScore => 'Concentración lectora';

  @override
  String get statsBookCount => 'Número de libros';

  @override
  String get statsTrendAnalysis => 'Análisis de tendencias de lectura';

  @override
  String statsAxisMinutes(Object value) {
    return '$value min';
  }

  @override
  String statsAxisPages(Object value) {
    return '$value pág';
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
  String get statsTimeDistribution => 'Distribución del tiempo de lectura';

  @override
  String get statsFormatDistribution => 'Distribución de formatos de libros';

  @override
  String get statsCompleted => 'Terminados';

  @override
  String get statsInProgress => 'En curso';

  @override
  String get statsDurationRanking => 'Ranking por tiempo de lectura';

  @override
  String get statsProgressRanking => 'Ranking por progreso de lectura';

  @override
  String statsPagesCount(Object count) {
    return '$count páginas';
  }

  @override
  String statsSessionCount(Object count) {
    return '$count sesiones';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return '$achieved logros conseguidos, $remaining más por desbloquear';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Primera lectura';

  @override
  String get statsAchievementFirstReadDesc =>
      'Completa tu primera sesión de lectura';

  @override
  String get statsAchievementNoviceTitle => 'Novato lector';

  @override
  String get statsAchievementNoviceDesc => 'Lee un total de 10 horas';

  @override
  String get statsAchievementBookwormTitle => 'Ratón de biblioteca';

  @override
  String get statsAchievementBookwormDesc => 'Lee un total de 100 horas';

  @override
  String get statsAchievementExpertTitle => 'Experto lector';

  @override
  String get statsAchievementExpertDesc => 'Lee 7 días seguidos';

  @override
  String get statsAchievementOceanTitle => 'Océano de conocimiento';

  @override
  String get statsAchievementOceanDesc => 'Lee 10 000 páginas';

  @override
  String get statsAchievementScholarTitle => 'Erudito';

  @override
  String get statsAchievementScholarDesc => 'Lee 10 libros diferentes';

  @override
  String get statsAchievementMarathonTitle => 'Maratón de lectura';

  @override
  String get statsAchievementMarathonDesc => 'Lee 30 días seguidos';

  @override
  String get statsAchievementFocusTitle => 'Maestro de la concentración';

  @override
  String get statsAchievementFocusDesc => 'Lee un total de 500 horas';

  @override
  String statsProgressPercent(Object percent) {
    return 'Progreso: $percent%';
  }

  @override
  String get statsGoalProgress => 'Progreso del objetivo de lectura';

  @override
  String get statsMonthlyReadingTime => 'Tiempo de lectura de este mes';

  @override
  String get statsWeeklyReadingTime => 'Tiempo de lectura de esta semana';

  @override
  String get statsAvgDailyPages7d =>
      'Promedio diario de páginas (últimos 7 días)';

  @override
  String statsHoursCount(Object count) {
    return '$count horas';
  }

  @override
  String get statsSpeedTrend => 'Tendencia de velocidad de lectura';

  @override
  String statsAvgSpeed(Object speed) {
    return 'Promedio: $speed páginas/min';
  }

  @override
  String get statsReadingContinuity => 'Continuidad de lectura';

  @override
  String statsCurrentStreak(Object days) {
    return 'Racha actual: $days días';
  }

  @override
  String get statsHeatmapLess => 'Menos';

  @override
  String get statsHeatmapMore => 'Más';

  @override
  String statsWeekNumber(Object week) {
    return 'Semana $week';
  }

  @override
  String get bookSourceAddToShelf => 'Añadir a la estantería';

  @override
  String get bookSourceAddOnline => 'Añadir en línea';

  @override
  String get bookSourceAddOnlineHint =>
      'Lee desde la fuente y guarda los capítulos en caché según avanzas';

  @override
  String get bookSourceDownloadLocal => 'Descargar localmente';

  @override
  String get bookSourceDownloadLocalHint =>
      'Descarga todos los capítulos y añade una copia TXT local';

  @override
  String get bookSourceAddedOnline =>
      'Añadido a la estantería como libro en línea';

  @override
  String get bookSourceAlreadyOnShelf => 'Este libro ya está en tu estantería';

  @override
  String get bookSourceDownloading => 'Descargando localmente';

  @override
  String get bookSourceFetchingCatalog =>
      'Obteniendo el catálogo de capítulos…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return '$completed/$total capítulos';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Descarga completada y añadida a la estantería local';

  @override
  String get bookSourceDownloadConverted =>
      'Descarga completada. Ahora es un libro local';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Error de descarga: $error';
  }

  @override
  String get downloadTasksTitle => 'Descargas';

  @override
  String get downloadTasksEmpty => 'No hay tareas de descarga';

  @override
  String get downloadTaskQueued => 'Esperando para descargar';

  @override
  String get downloadTaskDownloading => 'Descargando en segundo plano';

  @override
  String get downloadTaskCompleted => 'Descarga completada';

  @override
  String get downloadTaskFailed => 'Error de descarga';

  @override
  String get downloadTaskCancelled => 'Cancelada';

  @override
  String get downloadTaskCancel => 'Cancelar tarea';

  @override
  String get downloadContinueInBackground => 'Continuar en segundo plano';

  @override
  String get downloadRunningInBackground =>
      'La descarga continúa en segundo plano';

  @override
  String get bookSourceExitAddTitle => '¿Añadir a la estantería?';

  @override
  String bookSourceExitAddMessage(String title) {
    return '¿Añadir “$title” a tu estantería como libro en línea? Se conservará tu progreso de lectura.';
  }

  @override
  String get bookSourceNotNow => 'Ahora no';

  @override
  String get bookSourceOnlineBadge => 'En línea';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'Los datos del libro en línea no son válidos: $error';
  }

  @override
  String get readerThemeTitle => 'Tema de lectura';

  @override
  String get readerThemeDescription =>
      'Solo cambia la página de lectura y sus controles';

  @override
  String get readerSettingsTabTheme => 'Tema';

  @override
  String get readerSettingsTabText => 'Texto';

  @override
  String get readerSettingsTabLayout => 'Diseño';

  @override
  String get readerSettingsTabPaging => 'Paginación';

  @override
  String get readerSettingsAdvancedTypography => 'Tipografía avanzada';

  @override
  String get readerAutoPageTurnTitle => 'Pasar páginas automáticamente';

  @override
  String get readerAutoPageTurnOff => 'Sin iniciar';

  @override
  String get readerAutoPageTurnShortcutTitle => 'Atajo de lectura automática';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Mostrar con los controles de lectura para iniciar o pausar rápidamente';

  @override
  String get readerAutoPageTurnHint =>
      'Avanza una pantalla en el intervalo elegido, también en el modo de paginación vertical.';

  @override
  String get readerAutoPageTurnModeTimed => 'Paso de página temporizado';

  @override
  String get readerAutoPageTurnModeSweep => 'Paso de página con barrido';

  @override
  String get readerAutoPageTurnModeContinuous => 'Desplazamiento continuo';

  @override
  String get readerAutoPageTurnModeInterval => 'Desplazamiento por intervalos';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Espera el intervalo elegido y pasa a la página siguiente.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Una línea barre hacia abajo, revelando gradualmente la página siguiente encima.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Se desplaza hacia abajo de forma continua a una velocidad de lectura constante.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Espera el intervalo elegido y luego se desplaza aproximadamente una pantalla.';

  @override
  String get readerAutoPageTurnSweepDurationLabel => 'Duración del barrido';

  @override
  String get readerAutoPageTurnScrollSpeedLabel =>
      'Velocidad de desplazamiento';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds segundos por pantalla';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · ${seconds}s/pantalla';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'En pausa · $mode · ${seconds}s/pantalla';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Intervalo de páginas';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds segundos por pantalla';
  }

  @override
  String get readerAutoPageTurnStart => 'Iniciar el paso automático de páginas';

  @override
  String get readerAutoPageTurnResume =>
      'Reanudar el paso automático de páginas';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Auto · ${seconds}s/pantalla';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'En pausa · ${seconds}s/pantalla';
  }

  @override
  String get readerThemeDay => 'Día';

  @override
  String get readerThemeFollowSystem => 'Seguir el sistema';

  @override
  String get readerThemeMist => 'Bruma';

  @override
  String get readerThemeGreen => 'Cuidado de ojos';

  @override
  String get readerThemeRose => 'Rosa';

  @override
  String get readerThemeNavy => 'Azul profundo';

  @override
  String get readerThemeNight => 'Noche';

  @override
  String get readerThemePureBlack => 'Negro puro';

  @override
  String get readerThemeParchment => 'Pergamino';

  @override
  String get readerThemeCustom => 'Personalizado';

  @override
  String get readerPullBookmarkTitle => 'Marcador desplegable';

  @override
  String get readerPullBookmarkHint =>
      'Desliza hacia abajo desde el borde superior y suelta para añadir o quitar un marcador de esta página';

  @override
  String get readerPullBookmarkAddHint =>
      'Sigue tirando para añadir el marcador';

  @override
  String get readerPullBookmarkRemoveHint =>
      'Sigue tirando para quitar el marcador';

  @override
  String get readerPullBookmarkReleaseHint => 'Suelta para terminar';

  @override
  String get readerTapAnimationTitle => 'Animación al tocar';

  @override
  String get readerTapAnimationHint =>
      'Usa la animación de paso de página actual para los toques laterales; desactívala para refrescar al instante';

  @override
  String get readerTabletTwoPageTitle => 'Diseño de dos páginas en tablet';

  @override
  String get readerTabletTwoPageHint =>
      'Muestra las páginas izquierda y derecha lado a lado en horizontal; desactívalo para usar siempre una sola página';

  @override
  String get readerCustomThemeTitle => 'Tema de lectura personalizado';

  @override
  String get readerCustomThemeReset => 'Restablecer';

  @override
  String get readerCustomThemeColors => 'Colores del tema';

  @override
  String get readerCustomThemeTextColor => 'Color del texto';

  @override
  String get readerCustomThemeTextColorHint =>
      'Texto del cuerpo, títulos e iconos principales';

  @override
  String get readerCustomThemeBackground => 'Fondo de lectura';

  @override
  String get readerCustomThemeBackgroundHint =>
      'El color del papel y del lienzo de lectura';

  @override
  String get readerCustomThemeControlBar => 'Color de la barra de control';

  @override
  String get readerCustomThemeControlBarHint =>
      'Controles superior e inferior y superficies de ajustes';

  @override
  String get readerCustomThemeContrastGood =>
      'El texto tiene un contraste claro para una lectura prolongada cómoda';

  @override
  String get readerCustomThemeContrastLow =>
      'El contraste del texto es bajo y puede causar fatiga visual';

  @override
  String get readerCustomThemeSave => 'Guardar y usar';

  @override
  String get readerCustomThemePreview => 'Vista previa en vivo';

  @override
  String get readerCustomThemePreviewChapter =>
      'Capítulo uno · Viento entre las páginas';

  @override
  String get readerCustomThemePreviewBody =>
      'Este es tu espacio de lectura. Ajusta los colores del texto, el papel y los controles hasta que cada página se sienta verdaderamente tuya.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Introduce un color hexadecimal de 6 dígitos, como #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Color hexadecimal';

  @override
  String get readerCustomThemesTitle => 'Temas de lectura personalizados';

  @override
  String get readerCustomThemeAdd => 'Añadir tema';

  @override
  String get readerCustomThemeReorderHint =>
      'Mantén pulsado el tirador de la derecha para reordenar los temas. El mismo orden aparece en los ajustes de lectura.';

  @override
  String get readerCustomThemeUse => 'Usar el tema seleccionado';

  @override
  String get readerCustomThemeDeleteTitle => '¿Eliminar el tema de lectura?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return '“$name” se eliminará de tus temas, junto con su imagen de fondo guardada.';
  }

  @override
  String get readerCustomThemeEmptyTitle => 'Aún no hay temas personalizados';

  @override
  String get readerCustomThemeEmptyHint =>
      'Crea tu propia combinación de tipografía, color de papel e imagen de fondo.';

  @override
  String get readerCustomThemeNewTitle => 'Nuevo tema de lectura';

  @override
  String get readerCustomThemeEditTitle => 'Editar tema de lectura';

  @override
  String get readerCustomThemeName => 'Nombre del tema';

  @override
  String get readerCustomThemeNameHint =>
      'Por ejemplo, Noche de lluvia o Tarde de papel';

  @override
  String get readerCustomThemeBackgroundImage => 'Imagen de fondo';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Admite JPG, PNG y WebP. La imagen se copia al almacenamiento de la app.';

  @override
  String get readerCustomThemeChooseImage => 'Subir imagen';

  @override
  String get readerCustomThemeReplaceImage => 'Reemplazar imagen';

  @override
  String get readerCustomThemeRemoveImage => 'Quitar imagen';

  @override
  String get readerCustomThemeImageStrength =>
      'Intensidad de la imagen de fondo';

  @override
  String get readerCustomThemeImageUnsupported =>
      'La importación de imágenes de fondo no es compatible con esta plataforma';

  @override
  String get readerCustomThemeImageTooLarge =>
      'La imagen no debe superar los 20 MB';

  @override
  String get readerCustomThemeImageFormat => 'Elige una imagen JPG, PNG o WebP';

  @override
  String get readerCustomThemeImageFailed =>
      'No se pudo importar la imagen de fondo. Inténtalo de nuevo.';

  @override
  String get importSourceTitle => 'Añadir libros';

  @override
  String get importSourceDescription =>
      'Elige primero varios archivos. Revisa la cola antes de iniciar la importación.';

  @override
  String get importSelectFiles => 'Elegir archivos';

  @override
  String get importIosSharedDocuments => 'En Mi iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'iCloud Drive no está disponible';

  @override
  String get importAndroidFolder => 'Autorizar una carpeta de libros';

  @override
  String get importAndroidRescan => 'Escanear carpetas autorizadas';

  @override
  String get importFolderPermissionAvailable =>
      'Autorizada · toca para escanear';

  @override
  String get importFolderPermissionLost =>
      'Permiso perdido · autoriza de nuevo para recuperar el acceso';

  @override
  String get importRemoveFolder => 'Quitar carpeta';

  @override
  String importQueueTitle(int count) {
    return 'Cola de importación ($count)';
  }

  @override
  String get importQueueHint =>
      'Quita los archivos elegidos por error e impórtalos de uno en uno.';

  @override
  String get importQueueEmptyTitle => 'No hay libros seleccionados';

  @override
  String get importQueueEmptyBody =>
      'Elige un archivo EPUB, PDF, TXT, MOBI u otro libro compatible.';

  @override
  String importAction(int count) {
    return 'Importar $count libros';
  }

  @override
  String importRetryFailed(int count) {
    return 'Reintentar $count fallidos';
  }

  @override
  String get importStatusQueued => 'En espera';

  @override
  String get importStatusPreparing => 'Preparando archivo';

  @override
  String get importStatusChecking => 'Comprobando';

  @override
  String get importStatusCopying => 'Copiando';

  @override
  String get importStatusAnalyzing => 'Analizando';

  @override
  String get importStatusSaving => 'Guardando';

  @override
  String get importStatusImported => 'Importado';

  @override
  String get importStatusSkipped => 'Ya existe; omitido';

  @override
  String get importStatusFailed => 'Error de importación';

  @override
  String get importRemove => 'Quitar';

  @override
  String get importRetry => 'Reintentar';

  @override
  String get importClearCompleted => 'Limpiar completados';

  @override
  String get importDone => 'Hecho';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return '$succeeded importados · $skipped omitidos · $failed fallidos';
  }

  @override
  String get importNoSupportedFiles =>
      'No se encontraron archivos de libro compatibles';

  @override
  String get importScanning => 'Escaneando archivos…';

  @override
  String get settingsAiApiKeyConfigured => 'API Key configurada';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Toca para completar la configuración';

  @override
  String get settingsAiAddModel => 'Añadir modelo';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Cambiado a $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Primero rellena la URL base y la API Key';

  @override
  String get settingsAiEditModelTitle => 'Configurar modelo';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Cada tarjeta rápida está vinculada a un modelo';

  @override
  String get settingsAiPresetModel => 'Modelo preajustado';

  @override
  String get settingsAiBaseUrlLabel => 'URL base';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'Compatible con OpenAI: la URL base normalmente debe incluir /v1 (por ejemplo, https://example.com/v1). La app añade /chat/completions.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic: la URL base puede incluir /v1 u omitirlo. La app evita duplicar /v1 y añade /messages.';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiModelNameLabel => 'Nombre del modelo';

  @override
  String get settingsAiFetchModelsTooltip => 'Obtener modelos automáticamente';

  @override
  String get settingsAiFetchModelsList =>
      'Obtener la lista de modelos automáticamente';

  @override
  String get settingsAiSelectModel => 'Selecciona un modelo';

  @override
  String get settingsAiTemperatureLabel => 'Temperatura';

  @override
  String get settingsAiAddAndEnable => 'Añadir y activar';

  @override
  String get settingsAiModelMismatchClaude =>
      'Los nombres de modelo del proveedor Claude suelen empezar por \"claude\". Comprueba que el proveedor y el modelo coincidan.';

  @override
  String get settingsAiModelMismatchGemini =>
      'Los nombres de modelo del proveedor Gemini suelen contener \"gemini\". Comprueba que el proveedor y el modelo coincidan.';

  @override
  String get settingsAiModelMismatchGlm =>
      'Los nombres de modelo del proveedor GLM suelen empezar por \"glm\". Comprueba que el proveedor y el modelo coincidan.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'Los nombres de modelo del proveedor MiniMax suelen contener \"MiniMax\". Comprueba que el proveedor y el modelo coincidan.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Formato de respuesta de la lista de modelos no reconocido';

  @override
  String get settingsAiNoModelsReturned =>
      'El servidor no devolvió ninguna lista de modelos disponibles';

  @override
  String get settingsAiNoModelsAvailable => 'No hay modelos disponibles';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Error al obtener modelos: $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'Preprocesamiento de libros con IA';

  @override
  String get settingsAiPreprocessSubtitle =>
      'Tras importar un libro, deja que la IA lo lea y cree automáticamente una base de conocimiento local de resúmenes';

  @override
  String get settingsAiPreprocessWarning =>
      'El preprocesamiento envía el libro completo al modelo de IA por fragmentos. Consume muchos tokens y lleva tiempo. ¿Activarlo de todos modos?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Configura primero un modelo de IA funcional con una API key';

  @override
  String get libraryAiPreprocess => 'Preprocesamiento con IA';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return '¿Dejar que la IA lea \"$title\" y cree una base de conocimiento de resúmenes? Esto consume muchos tokens.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'La IA está leyendo este libro… (paso $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'Base de conocimiento de IA generada';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'Error de preprocesamiento con IA: $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Este formato de libro aún no admite el preprocesamiento con IA';

  @override
  String get libraryAiPreprocessQueued =>
      'Añadido a la cola de preprocesamiento con IA. Consulta el progreso en Tareas de descarga.';

  @override
  String get downloadTasksTabDownloads => 'Descargas';

  @override
  String get aiPreprocessTaskRunning => 'La IA está leyendo…';

  @override
  String get aiPreprocessTasksEmpty =>
      'No hay tareas de preprocesamiento con IA';

  @override
  String get aiPreprocessClearFinished => 'Limpiar terminadas';

  @override
  String get aiChatNewChat => 'Nueva conversación';

  @override
  String get aiChatSelectBook => 'Vincular un libro';

  @override
  String get aiChatNoBook => 'Sin libro vinculado';

  @override
  String get navAi => 'IA';

  @override
  String get aiHistoryTitle => 'Conversaciones de IA';

  @override
  String get aiHistoryEmpty =>
      'Aún no hay conversaciones de IA.\nToca Preguntar a la IA mientras lees para iniciar tu primera conversación.';

  @override
  String aiHistoryMessageCount(int count) {
    return '$count mensajes';
  }

  @override
  String get aiHistoryClearAll => 'Borrar todo';

  @override
  String get aiHistoryClearAllConfirm =>
      '¿Eliminar todo el historial de conversaciones de IA? Esto no se puede deshacer.';

  @override
  String get aiHistoryDeleteConfirm => '¿Eliminar esta conversación?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Desactiva un interruptor para ocultar esa página; Ajustes no se puede ocultar.';

  @override
  String get readerAskAi => 'Preguntar a la IA';

  @override
  String get readerAiInputHint => 'Pregunta sobre este libro…';

  @override
  String get readerAiSendButton => 'Enviar';

  @override
  String get readerAiThinking => 'Pensando…';

  @override
  String get readerAiNotConfiguredHint =>
      'Aún no hay ningún modelo de IA configurado. Ve a Ajustes → Asistente de lectura con IA para añadir un modelo y una API key.';

  @override
  String get readerAiEmptyHint =>
      'Pregunta a la IA sobre la página actual o cualquier cosa de este libro.';

  @override
  String get readerAiSelectionQuestionLabel => 'Explicar esta selección';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Explica el pasaje seleccionado a continuación y da 3 puntos clave.\n\nTexto seleccionado:\n$selection\n\nContexto anterior:\n$before\n\nContexto posterior:\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst =>
      'Introduce una pregunta antes de enviar';

  @override
  String get readerAiEmptyResponse =>
      'El modelo devolvió una respuesta vacía; reinténtalo';

  @override
  String readerAiRequestFailed(String error) {
    return 'Error en la solicitud: $error';
  }

  @override
  String get readerAiUnknownError => 'Error desconocido';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'La respuesta del servidor está vacía. Suele deberse a una URL base incorrecta, a una pasarela que no reenvía al endpoint del modelo o a que el servidor cierra la conexión antes de tiempo.\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'La respuesta del servidor no es JSON válido. El endpoint actual puede ser incompatible con la configuración de $provider.\nURL de la solicitud: $endpoint\nFragmento de la respuesta: $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Error en la solicitud$status: no se pudo leer la respuesta del servidor. Suele deberse a una URL base incorrecta, a que el endpoint devuelve contenido vacío o a que la red trunca la respuesta.\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Error de red en la solicitud$status: $error\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Error en la solicitud($status): $text\nSugerencias: 1) la temperatura de MiniMax debe estar en (0,1]; 2) comprueba que el nombre del modelo coincida con el endpoint; 3) usa una sola instrucción de sistema.\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Error en la solicitud($status): $text\nConsejo: Claude requiere la cabecera de solicitud anthropic-version.\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Error en la solicitud($status): $text\nConsejo: confirma que el proveedor y la API Key coincidan; no se pueden mezclar.\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Error en la solicitud($status): $text\nURL de la solicitud: $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'IA (simulada): El texto que seleccionaste es \"$selectedText\".\n\nAntes: $before\nDespués: $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'IA (simulada): Esta página tiene $chars caracteres. Céntrate en los argumentos del principio y del final de los párrafos.';
  }

  @override
  String get readerAiMockGreeting => 'Hola';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'IA (simulada): Preguntaste \"$question\".\n\nHe leído la página actual ($chars caracteres). Puedes seguir preguntando.';
  }

  @override
  String get ttsSystemDefault => 'Predeterminado del sistema';

  @override
  String get ttsUnavailable => 'TTS del sistema no disponible';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'El sistema no admite el idioma: $language';
  }

  @override
  String get ttsCallFailed => 'Error en la llamada al TTS del sistema';

  @override
  String get importErrorSourceMissing => 'El archivo de origen no existe';

  @override
  String get importErrorHashFailed =>
      'No se puede verificar el contenido del archivo';

  @override
  String get importErrorTargetNameExhausted =>
      'No se puede asignar un nombre disponible al archivo de importación';

  @override
  String get importErrorSourceNotMaterialized =>
      'El archivo de origen aún no está en el almacenamiento local';

  @override
  String get importErrorCopyVerificationFailed =>
      'El archivo copiado no coincide con el origen';

  @override
  String get importErrorFileTooLarge =>
      'El archivo supera el límite de importación de 500 MB';

  @override
  String get importErrorSourcePrepareFailed =>
      'No se puede preparar el archivo de importación';

  @override
  String get importErrorFailed => 'Error al importar el libro';

  @override
  String get importUnknownTitle => 'Título desconocido';

  @override
  String get importUnknownAuthor => 'Autor desconocido';

  @override
  String get bookUntitled => 'Sin título';

  @override
  String get accentPurple => 'Morado elegante';

  @override
  String get accentPink => 'Rosa cereza';

  @override
  String get accentCyan => 'Cian fresco';

  @override
  String get accentBrown => 'Marrón clásico';

  @override
  String get accentGrey => 'Gris elegante';

  @override
  String get accentDeepPurple => 'Morado cautivador';

  @override
  String get accentAmber => 'Ámbar dorado';

  @override
  String get accentLightGreen => 'Verde vivo';

  @override
  String get accentYellow => 'Amarillo sol';

  @override
  String get accentNeutralGrey => 'Gris minimalista';

  @override
  String get accentIndigo => 'Índigo profundo';

  @override
  String get accentDeepOrange => 'Naranja llama';

  @override
  String get agreementV2HeroTitle => 'Sigue leyendo en tu propio dispositivo.';

  @override
  String get agreementV2HeroBody =>
      'Origo X es un lector de libros electrónicos de código abierto, multiplataforma y con prioridad local. Ofrece herramientas de lectura; no proporciona, aloja ni revisa los libros que importas.';

  @override
  String get agreementV2LocalTitle => 'Prioridad local';

  @override
  String get agreementV2LocalBody =>
      'Los libros, el progreso y las notas suelen permanecer en tu dispositivo para que los gestiones y hagas copias de seguridad.';

  @override
  String get agreementV2OpenSourceTitle => 'Licencia AGPL-3.0';

  @override
  String get agreementV2OpenSourceBody =>
      'El código fuente se proporciona bajo GNU AGPL v3.0 y el software se entrega “tal cual”, sin garantías.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Versión de los términos $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Introducción';

  @override
  String get agreementFlowStepTerms => 'Términos';

  @override
  String get agreementFlowStepSource => 'Fuentes de libros';

  @override
  String get agreementFlowStepPrivacy => 'Privacidad';

  @override
  String get agreementFlowNext => 'Siguiente';

  @override
  String get agreementFlowBack => 'Atrás';

  @override
  String get agreementFlowTermsTitle => 'Usa Origo X con límites claros';

  @override
  String get agreementFlowTermsSubtitle =>
      'Revisa los términos que rigen el uso del software y del contenido que elijas abrir.';

  @override
  String get agreementFlowTermsConsent =>
      'He leído y acepto los Términos de uso.';

  @override
  String get agreementFlowSourceTitle =>
      'Acuerdo de fuentes de libros de terceros';

  @override
  String get agreementFlowSourceSubtitle =>
      'Confirma cómo se separan del proyecto oficial las direcciones de fuentes, el contenido, la autorización y la responsabilidad.';

  @override
  String get agreementFlowSourceConsent =>
      'He leído y acepto el Acuerdo de fuentes de libros de terceros.';

  @override
  String get agreementFlowPrivacyTitle =>
      'Tus datos permanecen bajo tu control';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Revisa qué permanece local, cuándo se realizan solicitudes de red y cómo se conservan los registros de descarga.';

  @override
  String get agreementFlowPrivacyConsent =>
      'He leído y acepto el Aviso de privacidad.';

  @override
  String get agreementFlowEnterApp => 'Entrar en Origo X';

  @override
  String get agreementFlowPrivacyLocalTitle => 'Local por defecto';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Los libros, el progreso, las notas y los ajustes normalmente permanecen en este dispositivo.';

  @override
  String get agreementFlowPrivacyNetworkTitle =>
      'El uso de la red es explícito';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'La lectura local no sube el texto de los libros. Las comprobaciones de actualizaciones contactan con GitHub y el sitio oficial; las fuentes, la IA y la sincronización se conectan solo cuando se usan sus funciones.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Registros de descarga limitados';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'Los registros de descarga del sitio oficial que contienen una IP sin procesar se conservan un máximo de 180 días y luego se eliminan.';

  @override
  String get agreementV2Title => 'Términos de uso y Aviso de privacidad';

  @override
  String get agreementV2Subtitle => 'Léelo antes de usar Origo X';

  @override
  String get agreementV2ImportantNotice =>
      'Importante: La app oficial de Origo X no preinstala, agrupa ni recomienda ninguna fuente de libros de terceros, y sus desarrolladores no gestionan, representan ni alojan contenido de fuentes. Tú eliges cada archivo importado y cada fuente que añades; usa solo contenido al que estés autorizado a acceder.';

  @override
  String get agreementV2SourceBoundaryTitle => 'Límite con fuentes de terceros';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'El proyecto oficial solo proporciona software de lectura de código abierto y el Origo Source Protocol. No proporciona direcciones de fuentes ni un directorio oficial de fuentes.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Cada dirección de fuente debes introducirla y añadirla tú. La app se conecta directamente a ese servicio independiente sin enrutar el contenido por un servidor de los desarrolladores.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'La compatibilidad con el protocolo solo significa que una interfaz puede conectarse; no demuestra legalidad ni licencia. Los operadores de fuentes son responsables de su contenido y debes revisarlo y usarlo conforme a la ley.';

  @override
  String get agreementV2Section1Title => 'Ámbito y aceptación';

  @override
  String get agreementV2Section1Body =>
      'Estos términos se aplican a la descarga, instalación y uso de Origo X y sus funciones incluidas. Al seleccionar “Aceptar y continuar”, confirmas que los has leído, entendido y aceptado. Si no estás de acuerdo, deja de usar la app y sal de ella. Un tutor debe dar su consentimiento cuando la ley local lo exija.';

  @override
  String get agreementV2Section2Title => 'Licencia de código abierto';

  @override
  String get agreementV2Section2Body =>
      'Las futuras versiones de Origo X se publican bajo la GNU Affero General Public License v3.0. Puedes usar, copiar, modificar, distribuir o vender el software bajo esa licencia. Una versión modificada distribuida debe proporcionar su código fuente correspondiente completo bajo AGPL-3.0, y una versión modificada usada para prestar un servicio de red también debe ofrecer el código fuente correspondiente a los usuarios que interactúen con ella. Los derechos MIT ya concedidos para la v1.0.0 y versiones anteriores siguen vigentes y no se revocan. Estos términos no restringen los derechos concedidos por la licencia de código abierto. Los componentes de terceros siguen sujetos a sus propias licencias.';

  @override
  String get agreementV2Section3Title => 'Contenido del usuario y derechos';

  @override
  String get agreementV2Section3Body =>
      'El “contenido del usuario” incluye libros, documentos, imágenes, metadatos, enlaces y otro material que importes, descargues, abras, conviertas, guardes en caché, anotes o leas en voz alta. Debes contar con todos los derechos y permisos necesarios para usarlo. Eres el único responsable de reclamaciones o pérdidas por derechos de autor, marcas, privacidad, difamación, contenido ilícito, malware u otras causas que afecten al contenido del usuario. El software y sus desarrolladores no suben, venden, licencian, respaldan ni revisan ese contenido, y la compatibilidad de un formato no implica permiso legal para usar un archivo.';

  @override
  String get agreementV2Section4Title => 'Usos prohibidos';

  @override
  String get agreementV2Section4Body =>
      'No puedes usar el software para infringir propiedad intelectual u otros derechos; distribuir contenido ilícito, dañino o malicioso; eludir la gestión de derechos digitales, los controles de acceso o los muros de pago; atacar o perturbar sistemas de terceros; ni realizar actividades prohibidas por la ley aplicable. Eres responsable de reclamaciones, denuncias, sanciones y pérdidas derivadas de tu conducta.';

  @override
  String get agreementV2Section5Title => 'Fuentes de libros y terceros';

  @override
  String get agreementV2Section5Body =>
      'La app oficial no preinstala, distribuye ni recomienda fuentes de libros y no gestiona un directorio oficial de fuentes. Las fuentes, las API de red, los enlaces externos, el contenido en línea, el texto a voz del sistema, los servicios de IA y otras integraciones que añadas son proporcionadas y controladas de forma independiente por terceros. No están gestionados, representados, licenciados, respaldados ni revisados por los desarrolladores. Los operadores de fuentes son legalmente responsables del contenido que proporcionan. Antes de añadir una, debes revisar su origen, los derechos del contenido, su política de privacidad y sus términos, y eres responsable de tu propio acceso, descargas, caché, distribución y otro uso. En la máxima medida permitida por la ley aplicable, los desarrolladores no son responsables del contenido de terceros, cargos, prácticas de datos, interrupciones o disputas por infracción.';

  @override
  String get agreementV2Section6Title => 'Datos y privacidad';

  @override
  String get agreementV2Section6Body =>
      'Origo X funciona con prioridad local. Los libros, el progreso de lectura, las notas y los ajustes se guardan normalmente en tu dispositivo. Salvo que actives una fuente de libros en red, la IA, la sincronización u otra función en línea, la app no necesita enviar el texto de los libros a los desarrolladores para ofrecer la lectura local. Las comprobaciones de actualizaciones automáticas y manuales contactan con GitHub y el sitio oficial en open.xxread.top con parámetros técnicos necesarios como la plataforma, la arquitectura del procesador y el canal de distribución; sus servidores procesan tu dirección IP y tu User-Agent como parte de la comunicación de red ordinaria. Cuando descargas un instalador del sitio oficial, el servidor registra la versión, la arquitectura, la hora de descarga, la dirección IP y el User-Agent para contadores de descarga, protección de seguridad y diagnóstico. Los registros de eventos de descarga que contienen una IP sin procesar se conservan un máximo de 180 días y luego se eliminan; solo las estadísticas agregadas sin direcciones IP sin procesar se conservan más tiempo. Las solicitudes de actualización no incluyen texto de libros, tu biblioteca, notas, una cuenta ni un identificador único de dispositivo. Las solicitudes a GitHub también se rigen por los términos de privacidad de GitHub. Cuando se usa otra función en línea, es posible que las consultas, el texto seleccionado, la información de red o los parámetros necesarios se envíen al proveedor que hayas elegido conforme a sus políticas. Protege tu dispositivo, tus API keys y tus copias de seguridad; desinstalar, borrar datos, una avería del dispositivo o un error del usuario pueden borrar datos de forma permanente.';

  @override
  String get agreementV2Section7Title => 'IA y resultados automatizados';

  @override
  String get agreementV2Section7Body =>
      'Los resúmenes, respuestas, traducciones, recomendaciones y otras salidas generadas por IA pueden ser inexactos, incompletos, obsoletos o engañosos. Son solo ayudas de lectura y no constituyen asesoramiento legal, médico, financiero, académico ni de otro tipo profesional. Verifica las salidas de forma independiente y no recurras a ellas para decisiones de alto riesgo. El material enviado a un proveedor de IA también se rige por los términos de ese proveedor.';

  @override
  String get agreementV2Section8Title => 'Renuncia de garantías';

  @override
  String get agreementV2Section8Body =>
      'En la máxima medida permitida por la ley, el software y los materiales relacionados se proporcionan “tal cual” y “según disponibilidad”, sin garantías expresas, implícitas o legales, incluidas la comerciabilidad, la idoneidad para un propósito particular, la titularidad, la no infracción, la exactitud, la compatibilidad, la seguridad, el funcionamiento sin errores, la disponibilidad ininterrumpida o la preservación de datos. Los colaboradores de código abierto no tienen obligación de mantener, actualizar, dar soporte ni corregir el software.';

  @override
  String get agreementV2Section9Title => 'Limitación de responsabilidad';

  @override
  String get agreementV2Section9Body =>
      'En la máxima medida permitida por la ley, los desarrolladores, los titulares de derechos de autor y los colaboradores no son responsables de pérdidas directas, indirectas, incidentales, especiales, punitivas o consecuenciales derivadas de la instalación, el uso, la imposibilidad de uso, el contenido del usuario, servicios de terceros, la pérdida de datos, problemas del dispositivo, interrupciones del negocio o incidentes de seguridad, ya sea por contrato, agravio u otra teoría. La responsabilidad que legalmente no pueda excluirse queda limitada al mínimo permitido por la ley.';

  @override
  String get agreementV2Section10Title => 'Indemnización';

  @override
  String get agreementV2Section10Body =>
      'En la medida permitida por la ley aplicable, eres responsable de y mantendrás indemnes a los desarrolladores, titulares de derechos de autor y colaboradores frente a reclamaciones de terceros, investigaciones, sanciones, pérdidas y costos razonables derivados de tu contenido de usuario, conducta ilícita o infractora, del incumplimiento de estos términos o del uso de servicios de terceros.';

  @override
  String get agreementV2Section11Title => 'Cambios, terminación y ley';

  @override
  String get agreementV2Section11Body =>
      'Las funciones, el estado del mantenimiento y estos términos pueden cambiar a medida que evolucionen el proyecto de código abierto, la ley o los controles de riesgo. Las actualizaciones importantes pueden requerir un consentimiento renovado; si no estás de acuerdo, deja de usar la app. Puedes desinstalarla en cualquier momento. Las disputas deben resolverse primero de manera informal. Salvo por las protecciones obligatorias al consumidor, se aplican la ley del lugar del desarrollador y los tribunales con jurisdicción legítima. Si una disposición es inaplicable, el resto sigue vigente.';

  @override
  String get agreementV2ConfirmLabel =>
      'He leído y acepto los Términos de uso y el Aviso de privacidad.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Entiendo que el proyecto oficial no proporciona fuentes de libros; las fuentes y el contenido que añado provienen de terceros independientes, y verificaré la autorización y seguiré siendo responsable de mi propio uso.';

  @override
  String get agreementV2ExitLabel => 'Rechazar';

  @override
  String get agreementV2ContinueLabel => 'Aceptar y continuar';

  @override
  String get agreementV2ExitDialogTitle => '¿Rechazar los términos?';

  @override
  String get agreementV2ExitDialogBody =>
      'Debes aceptar los Términos de uso para seguir usando Origo X. Si no estás de acuerdo, sal de la app.';

  @override
  String get agreementV2CancelLabel => 'Volver';

  @override
  String get agreementV2ConfirmExitLabel => 'Salir';

  @override
  String get agreementV2SaveFailed =>
      'No se pudo guardar tu consentimiento. Inténtalo de nuevo.';

  @override
  String get settingsDataSyncTitle => 'Datos y sincronización';

  @override
  String get settingsCacheManagementTitle => 'Gestión de caché';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return 'En uso: $size · Ver detalles y limpiar cachés';
  }

  @override
  String get settingsCacheUsageTitle => 'Uso de caché';

  @override
  String get settingsCacheTotalUsage => 'Total usado';

  @override
  String get settingsCacheSafeHint =>
      'Solo se muestran las cachés que se pueden eliminar con seguridad. Los libros, el progreso de lectura y los ajustes no están incluidos.';

  @override
  String get settingsCacheSourceCovers => 'Caché de portadas de fuentes';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Portadas de fuentes descargadas · $size';
  }

  @override
  String get settingsCacheSourceData => 'Caché de capítulos de fuentes';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Caché de capítulos en línea que se puede eliminar con seguridad · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Caché de lectura local';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Caché de análisis de EPUB/TXT reconstruible · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'Archivos temporales';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'Archivos temporales y de actualización desechables · $size';
  }

  @override
  String get settingsCacheClearAll => 'Limpiar todas las cachés seguras';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Limpia solo las categorías anteriores · $size';
  }

  @override
  String get settingsCacheCalculating => 'Calculando…';

  @override
  String get settingsCacheClearConfirm =>
      'Esto elimina solo datos de caché temporales. Los libros, las portadas guardadas, el progreso de lectura, las bases de datos, los ajustes y las credenciales se conservan.';

  @override
  String get settingsCacheClearAction => 'Limpiar';

  @override
  String get settingsCacheCleared => 'Caché limpiada';

  @override
  String get settingsCacheClearFailed => 'No se pudo limpiar la caché';

  @override
  String get settingsWebDavSyncTitle => 'Sincronización WebDAV';

  @override
  String get webDavNotConfigured => 'Sin configurar';

  @override
  String get webDavConfigureSubtitle =>
      'Sincroniza tus datos de lectura con tu propio almacenamiento WebDAV';

  @override
  String get webDavBetaBadge => 'Beta · Puede ser inestable';

  @override
  String get webDavPageTitle => 'Sincronización WebDAV';

  @override
  String get webDavConnected => 'Conectado';

  @override
  String get webDavSyncing => 'Sincronizando';

  @override
  String get webDavPartialFailure => 'Algunos elementos necesitan atención';

  @override
  String get webDavSyncFailed => 'Error de sincronización';

  @override
  String webDavPendingChanges(int count) {
    return '$count cambios pendientes de sincronizar';
  }

  @override
  String webDavLastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get webDavNeverSynced => 'Aún no se ha sincronizado';

  @override
  String get webDavSyncNow => 'Sincronizar ahora';

  @override
  String get webDavSetUp => 'Configurar WebDAV';

  @override
  String get webDavConnectionTitle => 'Conexión';

  @override
  String get webDavServerUrl => 'Dirección WebDAV';

  @override
  String get webDavUsername => 'Nombre de usuario';

  @override
  String get webDavPassword => 'Contraseña de la app';

  @override
  String get webDavPasswordHint =>
      'Guardada de forma segura solo en este dispositivo';

  @override
  String get webDavRootPath => 'Carpeta remota';

  @override
  String get webDavTestConnection => 'Probar conexión';

  @override
  String get webDavTestingConnection => 'Probando conexión…';

  @override
  String get webDavConnectionSuccess =>
      'Conexión y permiso de escritura verificados';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Error en la prueba de conexión: $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Guardar configuración';

  @override
  String get webDavAutomaticSync => 'Sincronización automática';

  @override
  String get webDavAutomaticSyncHint =>
      'Sincroniza tras el arranque o cuando la app vuelve al primer plano';

  @override
  String get webDavSyncContent => 'Contenido a sincronizar';

  @override
  String get webDavScopeBookSources => 'Fuentes de libros';

  @override
  String get webDavScopeBookSourcesHint =>
      'Sincroniza fuentes ORSP públicas y favoritas, además de todos los nombres de grupo, los grupos vacíos y su orden. Las credenciales de fuentes y las configuraciones privadas permanecen en este dispositivo.';

  @override
  String get webDavScopeBooks => 'Biblioteca y libros en línea';

  @override
  String get webDavScopeProgress => 'Progreso de lectura';

  @override
  String get webDavScopeBookmarks => 'Marcadores';

  @override
  String get webDavScopeNotes => 'Notas y resaltados';

  @override
  String get webDavScopeNotesHint =>
      'Incluye texto citado, notas y tinta. Los datos de WebDAV no están cifrados de extremo a extremo.';

  @override
  String get webDavScopeReadingSessions => 'Estadísticas de lectura';

  @override
  String get webDavScopeReaderSettings => 'Ajustes del lector';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Sincroniza tipografía, temas, paso de páginas, preferencias de paginación automática, zonas táctiles y preferencias del lector de imágenes.';

  @override
  String get webDavScopeReplaceRules => 'Reglas de reemplazo';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Sincroniza los patrones de las reglas y el texto de reemplazo. Los datos de WebDAV no están cifrados de extremo a extremo.';

  @override
  String get webDavScopeBookFiles => 'Archivos de libros';

  @override
  String get webDavBookFilesHint => 'Elige qué libros subir o descargar';

  @override
  String get webDavBookFilesUnavailable =>
      'La transferencia de archivos de libros se activará cuando la sincronización de metadatos sea estable';

  @override
  String get webDavSecurityNotice =>
      'Los datos se envían por HTTPS, pero tu proveedor WebDAV puede leer el contenido remoto sin cifrar.';

  @override
  String get webDavConnectionDetails => 'Ajustes de conexión';

  @override
  String get webDavClearConfiguration => 'Borrar configuración';

  @override
  String get webDavClearConfigurationTitle =>
      '¿Borrar la configuración de WebDAV?';

  @override
  String get webDavClearConfigurationMessage =>
      'Esto elimina la dirección y el inicio de sesión de WebDAV de este dispositivo. Los datos de lectura locales y los archivos remotos no se eliminarán.';

  @override
  String get webDavClearConfigurationConfirm => 'Borrar de este dispositivo';

  @override
  String get webDavActivityTitle => 'Actividad de sincronización';

  @override
  String get webDavActivityEmpty => 'Aún no hay actividad de sincronización';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return 'Subidos $uploaded, descargados $downloaded';
  }

  @override
  String get webDavErrorAuthentication =>
      'El nombre de usuario, la contraseña o el permiso de la carpeta son incorrectos.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'La configuración de WebDAV está incompleta o no es válida.';

  @override
  String get webDavErrorInsecureConnection =>
      'La conexión no cumple los requisitos de seguridad.';

  @override
  String get webDavErrorCertificate =>
      'No se pudo verificar el certificado del servidor.';

  @override
  String get webDavErrorPermission => 'La carpeta remota no permite escritura.';

  @override
  String get webDavErrorNotFound =>
      'No se encontró la carpeta remota de sincronización o un archivo necesario.';

  @override
  String get webDavErrorConflict =>
      'Los datos remotos están en conflicto. Prueba a sincronizar de nuevo.';

  @override
  String get webDavErrorStorageFull => 'El almacenamiento WebDAV está lleno.';

  @override
  String get webDavErrorRateLimited =>
      'Se hicieron demasiadas solicitudes WebDAV. Inténtalo de nuevo más tarde.';

  @override
  String get webDavErrorTimeout => 'El servidor no respondió a tiempo.';

  @override
  String get webDavErrorUnsupported =>
      'La respuesta del servidor es incompatible con el protocolo de sincronización.';

  @override
  String get webDavErrorServer =>
      'El servidor WebDAV no pudo completar la solicitud.';

  @override
  String get webDavErrorNetwork =>
      'La red no está disponible. Los cambios quedan guardados en este dispositivo.';

  @override
  String get webDavErrorCorruptData =>
      'Algunos datos remotos de sincronización están dañados y no se aplicaron.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'Los ajustes de lectura locales están dañados. La sincronización se detuvo sin borrar la copia remota.';

  @override
  String get webDavErrorClockSkew =>
      'El reloj de este dispositivo difiere demasiado del servidor WebDAV.';

  @override
  String get webDavErrorSecureStorage =>
      'No se pudo leer la contraseña de WebDAV del almacenamiento seguro.';

  @override
  String get webDavErrorUnknown => 'WebDAV no pudo completar la operación.';

  @override
  String get webDavErrorDetails => 'Detalles de la respuesta del servidor';

  @override
  String get webDavErrorMissingEtagDetail =>
      'El servidor no devolvió un identificador fuerte de versión de archivo (ETag). El ETag puede faltar o ser demasiado débil, así que la app no puede saber si otro dispositivo cambió el archivo remoto.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'El servidor ignoró la condición que permite escribir solo cuando coincide la versión del archivo (If-Match). Continuar podría sobrescribir un cambio más reciente de otro dispositivo.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'El servidor ignoró la condición que permite crear solo cuando el archivo no existe (If-None-Match). Continuar podría sobrescribir un archivo existente.';

  @override
  String webDavErrorReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'Estado HTTP: $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Método de solicitud: $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Ruta del recurso: $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Fallo mientras: $phase';
  }

  @override
  String get webDavPhaseConnecting => 'conectando con el servidor remoto';

  @override
  String get webDavPhaseScanningLocal => 'escaneando este dispositivo';

  @override
  String get webDavPhaseReadingRemote => 'leyendo datos remotos';

  @override
  String get webDavPhaseApplyingRemote => 'combinando datos remotos';

  @override
  String get webDavPhaseUploadingLocal => 'subiendo cambios locales';

  @override
  String get webDavPhaseFinishing => 'finalizando la sincronización';

  @override
  String get webDavPhaseUnknown => 'un paso desconocido';

  @override
  String get webDavBookFilesTitle => 'Archivos de libros';

  @override
  String get webDavFilesPendingUpload => 'Pendientes de subir';

  @override
  String get webDavFilesAvailableDownload => 'Disponibles';

  @override
  String get webDavFilesSynced => 'Sincronizados';

  @override
  String get webDavFilesUploadSelected => 'Subir seleccionados';

  @override
  String get webDavFilesDownloadSelected => 'Descargar seleccionados';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return '$count seleccionados · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Solo en este dispositivo';

  @override
  String get webDavFilesOnlyRemote =>
      'Archivo no descargado en este dispositivo';

  @override
  String get webDavFilesUploadPermission =>
      'Permitir la subida de archivos de libros';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Sincroniza los libros y portadas seleccionados. TXT solo transfiere los bloques cambiados tras su primera subida; EPUB y PDF conservan sus bytes originales. Los archivos completos legibles se exportan por separado.';

  @override
  String get webDavNewBookPolicyTitle => 'Archivos de libros nuevos';

  @override
  String get webDavNewBookPolicyAsk => 'Preguntar cada vez (recomendado)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Elige qué libros subir cuando termine una importación';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Subir libros nuevos automáticamente';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Sube justo tras importar y puede usar datos móviles';

  @override
  String get webDavNewBookPolicyManual => 'Elegir siempre manualmente';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Inicia subidas solo desde la página Archivos de libros';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return '¿Sincronizar los $count libros recién importados?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'Los datos de lectura se sincronizan automáticamente. Elige los archivos de libro originales que subir a WebDAV.';

  @override
  String get webDavNewBooksSkip => 'Ahora no';

  @override
  String webDavNewBooksUploading(int count) {
    return 'Subiendo $count libros nuevos…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Subida de libros nuevos completada: $success con éxito, $failed fallidos';
  }

  @override
  String get webDavFilesTooLarge =>
      'Este archivo supera el límite de tamaño de sincronización para su formato';

  @override
  String get webDavFilesEmpty => 'No hay libros en esta categoría';

  @override
  String get webDavFilesTransferComplete =>
      'Transferencia de archivos de libros completada';

  @override
  String get readerAddAnnotation => 'Añadir anotación';

  @override
  String get readerAnnotationHint =>
      'Escribe lo que piensas sobre este pasaje…';

  @override
  String get readerAnnotationSaved => 'Anotación guardada';

  @override
  String get readerAnnotationDeleted => 'Anotación eliminada';

  @override
  String get readerAnnotationShelfRequired =>
      'Añade este libro a la estantería antes de guardar anotaciones';

  @override
  String get readerNoAnnotations => 'Aún no hay anotaciones';

  @override
  String get readerNoAnnotationsHint =>
      'Selecciona texto para resaltarlo o añadir un comentario. Toca un comentario subrayado para volver a leerlo.';

  @override
  String get replaceRulesTitle => 'Reemplazar y limpiar';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Quita anuncios, promociones y otro texto no deseado al leer';

  @override
  String get replaceRulesImport => 'Importar reglas';

  @override
  String get replaceRulesExport => 'Exportar reglas';

  @override
  String get replaceRulesSearchHint => 'Busca por nombre, grupo o patrón';

  @override
  String get replaceRulesUnnamed => 'Regla sin nombre';

  @override
  String get replaceRulesDeleteValue => 'Quitar';

  @override
  String get replaceRulesCreate => 'Nueva regla';

  @override
  String get replaceRulesEmptyTitle => 'No hay reglas de reemplazo';

  @override
  String get replaceRulesEmptyBody =>
      'Importa un archivo JSON de fuentes de lectura o crea una regla de expresión regular.';

  @override
  String get replaceRulesNoSearchResults => 'No hay reglas coincidentes';

  @override
  String get replaceRulesCreateTitle => 'Nueva regla de reemplazo';

  @override
  String get replaceRulesEditTitle => 'Editar regla de reemplazo';

  @override
  String get replaceRulesNameLabel => 'Nombre de la regla';

  @override
  String get replaceRulesPatternLabel => 'Texto o expresión regular a buscar';

  @override
  String get replaceRulesPatternHelper =>
      'Deja el reemplazo vacío para eliminar el texto encontrado';

  @override
  String get replaceRulesReplacementLabel => 'Reemplazar con';

  @override
  String get replaceRulesRegexLabel => 'Usar una expresión regular';

  @override
  String get replaceRulesScopeTitleLabel => 'Aplicar a títulos de capítulos';

  @override
  String get replaceRulesScopeContentLabel =>
      'Aplicar al contenido de capítulos';

  @override
  String get replaceRulesGroupLabel => 'Grupo (opcional)';

  @override
  String get replaceRulesScopeLabel => 'Ámbito (opcional)';

  @override
  String get replaceRulesScopeHelper =>
      'Separa títulos de libros o nombres de fuentes con punto y coma';

  @override
  String get replaceRulesExcludeScopeLabel => 'Ámbito excluido (opcional)';

  @override
  String get replaceRulesDeleteConfirmTitle => '¿Eliminar esta regla?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'La regla se eliminará de este dispositivo.';

  @override
  String replaceRulesImported(int count) {
    return 'Se importaron $count reglas';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'No se pudieron importar reglas: $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'El archivo de reglas supera $max';
  }

  @override
  String get replaceRulesExported => 'Reglas exportadas';

  @override
  String get replaceRulesPatternRequired =>
      'Introduce un texto o una expresión regular a buscar';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'El patrón supera los $max caracteres';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Expresión regular no válida: $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Se admite un máximo de $max reglas';
  }

  @override
  String get accountSecurityTitle => 'Seguridad';

  @override
  String get accountSecurityLoading => 'Cargando estado de seguridad…';

  @override
  String get accountChangeEmailTitle => 'Cambiar correo electrónico';

  @override
  String get accountChangeEmailEnterTitle => 'Elige un correo nuevo';

  @override
  String get accountChangeEmailEnterHint =>
      'Enviaremos un código a tu correo actual y otro a la nueva dirección.';

  @override
  String get accountChangeEmailVerifyTitle =>
      'Verifica ambas direcciones de correo';

  @override
  String get accountChangeEmailVerifyHint =>
      'Introduce los dos códigos para terminar de cambiar tu correo de inicio de sesión.';

  @override
  String get accountCurrentEmail => 'Correo actual';

  @override
  String get accountNewEmail => 'Correo nuevo';

  @override
  String get accountCurrentEmailCode => 'Código enviado al correo actual';

  @override
  String get accountNewEmailCode => 'Código enviado al correo nuevo';

  @override
  String get accountSendBothCodes => 'Enviar ambos códigos';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Tu dirección actual es un correo oculto de Apple que no puede recibir códigos. Se enviará un único código a la nueva dirección.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Tu dirección actual es un correo oculto de Apple, así que no necesita código. Introduce el código enviado a la nueva dirección para terminar.';

  @override
  String get accountCurrentPasswordInstead =>
      'Contraseña actual (en lugar del código)';

  @override
  String get accountRelayEmailTitle => 'Estás usando un correo oculto de Apple';

  @override
  String get accountRelayEmailBody =>
      'Tu dirección de inicio de sesión es una dirección de retransmisión privada de Apple, por lo que los correos de verificación pueden no llegar. Plantéate cambiar a una dirección que uses a diario.';

  @override
  String get accountChangeEmailAction => 'Cambiar correo electrónico';

  @override
  String get accountEmailChanged => 'Correo electrónico cambiado';

  @override
  String get accountChangePasswordTitle => 'Establecer o cambiar contraseña';

  @override
  String get accountPasswordEmailTitle => 'Verificar por correo electrónico';

  @override
  String get accountPasswordEmailHint =>
      'Envía un código a tu correo actual antes de elegir una contraseña nueva.';

  @override
  String get accountPasswordNewTitle => 'Elige una contraseña nueva';

  @override
  String get accountPasswordNewHint =>
      'Introduce el código del correo y establece la contraseña que usarás la próxima vez.';

  @override
  String get accountNewPassword => 'Contraseña nueva';

  @override
  String get accountChangePasswordAction => 'Cambiar contraseña';

  @override
  String get accountPasswordChanged => 'Contraseña cambiada';

  @override
  String get accountPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get accountMfaTitle => 'Autenticación de dos factores';

  @override
  String get accountMfaEnabled =>
      'Activada. Se necesita un autenticador o un código de recuperación sin usar al iniciar sesión.';

  @override
  String get accountMfaDisabledByDefault =>
      'Desactivada por defecto. Actívala para proteger los inicios de sesión con contraseña y código por correo.';

  @override
  String get accountMfaOnTitle =>
      'La autenticación de dos factores está activada';

  @override
  String get accountMfaEmailTitle => 'Verifica primero tu correo electrónico';

  @override
  String accountMfaEmailHint(String email) {
    return 'Enviaremos un código de configuración a $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'Introduce el código del correo';

  @override
  String get accountMfaEmailCodeHint =>
      'Tras la verificación, el código QR del autenticador y el secreto se abrirán en la página siguiente.';

  @override
  String get accountMfaAuthenticatorTitle => 'Añade Origo X a tu autenticador';

  @override
  String get accountMfaAuthenticatorHint =>
      'Escanea el código QR o introduce el secreto manualmente y luego escribe el código de seis dígitos del autenticador.';

  @override
  String get accountMfaQrCodeLabel =>
      'Código QR de configuración del autenticador';

  @override
  String get accountMfaSecretLabel => 'Secreto de configuración';

  @override
  String get accountMfaSecretCopied => 'Secreto de configuración copiado';

  @override
  String get accountMfaRecoveryTitle => 'Guarda tus códigos de recuperación';

  @override
  String get accountMfaChallengeTitle => 'Verificación de dos factores';

  @override
  String get accountMfaChallengeHint =>
      'Introduce el código de tu autenticador o un código de recuperación sin usar para acceder a tu cuenta.';

  @override
  String get accountMfaCode => 'Código del autenticador';

  @override
  String get accountMfaOrRecoveryCode =>
      'Código del autenticador o de recuperación';

  @override
  String get accountMfaVerify => 'Verificar y continuar';

  @override
  String get accountMfaSendSetupCode =>
      'Enviar código de configuración por correo';

  @override
  String get accountMfaContinueSetup => 'Continuar configuración';

  @override
  String get accountMfaSecretWarning =>
      'Añade este secreto a tu autenticador. Solo se muestra durante la configuración.';

  @override
  String get accountMfaOpenAuthenticator => 'Abrir autenticador';

  @override
  String get accountMfaConfirm => 'Confirmar y activar';

  @override
  String get accountMfaDisable => 'Desactivar la autenticación de dos factores';

  @override
  String get accountMfaDisabled => 'Autenticación de dos factores desactivada';

  @override
  String get accountRecoveryCodesWarning =>
      'Guarda ahora estos códigos de recuperación. Cada código funciona una vez y esta lista no se volverá a mostrar.';

  @override
  String get accountCopyRecoveryCodes => 'Copiar códigos de recuperación';

  @override
  String get accountRecoveryCodesCopied => 'Códigos de recuperación copiados';

  @override
  String get accountRecoveryCodesSaved => 'He guardado estos códigos';

  @override
  String get accountPremiumLifetime => 'Premium de por vida desbloqueado';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'Premium está vinculado a esta cuenta y se sincroniza entre las plataformas compatibles.';

  @override
  String get accountRedemptionCode => 'Código de Premium de por vida';

  @override
  String get accountRedeemPremium => 'Canjear y desbloquear para siempre';

  @override
  String get accountApplePurchase =>
      'Desbloquear para siempre con el App Store';

  @override
  String get accountApplePurchaseHint =>
      'Una compra única vincula Premium permanentemente a esta cuenta de Origo X y lo sincroniza con las plataformas compatibles.';

  @override
  String get accountAppleProductLoading => 'Cargando información del producto…';

  @override
  String get accountAppleProductRetry =>
      'No se pudo cargar la información del producto. Toca para reintentar.';

  @override
  String get accountAppleRestore => 'Restaurar compras';

  @override
  String get accountApplePurchasePending =>
      'La compra está esperando la aprobación del App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Compra enviada; verificando el acceso Premium';

  @override
  String get accountAppleRestoreSubmitted =>
      'Restauración de compra solicitada';

  @override
  String get accountPremiumUnlocked => 'Premium de por vida desbloqueado';

  @override
  String get accountPremiumUnlockedReferral =>
      'Canjeado: tú y quien te invitó habéis desbloqueado Premium de por vida';

  @override
  String get accountInviteTitle => 'Invitar amigos';

  @override
  String get accountInviteSubtitle =>
      'Cuando un amigo vincula tu código y canjea un código de Premium de por vida, ambos desbloqueáis Premium para siempre.';

  @override
  String get accountInviteMyCode => 'Mi código de invitación';

  @override
  String get accountInviteCopyCode => 'Copiar código de invitación';

  @override
  String get accountInviteCopyLink => 'Copiar enlace de invitación';

  @override
  String get accountInviteShareAction =>
      'Copiar enlace de invitación para compartir';

  @override
  String get accountInviteCopied => 'Datos de invitación copiados';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return '$invited invitados · $rewarded con éxito';
  }

  @override
  String get accountInviteStatsInvited => 'Códigos vinculados';

  @override
  String get accountInviteStatsRewarded => 'Recompensas desbloqueadas';

  @override
  String accountInviterBound(String name) {
    return 'Invitado por $name';
  }

  @override
  String get accountInviteRewarded => 'Invitación completada';

  @override
  String get accountInviteWaiting => 'Esperando el canje del código';

  @override
  String get accountInviteBindLabel => 'Código de invitación del amigo';

  @override
  String get accountInviteBindHint =>
      'Una cuenta puede vincular una sola vez y no puede cambiarlo después';

  @override
  String get accountInviteBindAction => 'Vincular código de invitación';

  @override
  String get accountInviteBound => 'Código de invitación vinculado';

  @override
  String get accountInviteHowItWorks => 'Cómo funciona';

  @override
  String get accountInviteStepShareTitle => 'Comparte el enlace';

  @override
  String get accountInviteStepShareBody =>
      'Envía el enlace o el código a un amigo. Él lo abre y crea una cuenta.';

  @override
  String get accountInviteStepBindTitle => 'Vincula el código';

  @override
  String get accountInviteStepBindBody =>
      'Tu amigo introduce tu código en Cuenta. Cada cuenta puede vincular una sola vez.';

  @override
  String get accountInviteStepRedeemTitle => 'Canjea un código';

  @override
  String get accountInviteStepRedeemBody =>
      'Cuando canjeen un código de Premium de por vida, ambas cuentas desbloquean Premium al instante.';

  @override
  String get accountInviteMyBinding => 'Mi relación de invitación';

  @override
  String get accountInviteBindIntro =>
      'Si alguien te invitó, vincula su código aquí para mantener la recompensa adjunta a tu cuenta.';

  @override
  String get accountInviteBindingNotNeeded =>
      'Esta cuenta ya tiene Premium, así que no necesitas código de invitación.';

  @override
  String get readingDataExportAction => 'Exportar datos de lectura';

  @override
  String get readingDataExportSubtitle => 'Resaltados, subrayados y notas';

  @override
  String get readingDataExportWholeBook => 'Todo el libro';

  @override
  String get readingDataExportWholeBookHint =>
      'Exporta todas tus anotaciones de este libro. El texto del libro y el archivo de origen no se incluyen.';

  @override
  String get readingDataExportPrivacySummary =>
      'Incluye los fragmentos resaltados o subrayados y tus notas privadas. El archivo del libro, el texto completo, los datos de la cuenta y la información del dispositivo no se incluyen.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return '$highlights resaltados · $underlines subrayados · $notes notas';
  }

  @override
  String readingDataExportButton(int count) {
    return 'Exportar $count anotaciones';
  }

  @override
  String get readingDataExportPreparing => 'Preparando Markdown…';

  @override
  String get readingDataExportEmpty =>
      'Este libro no tiene resaltados, subrayados ni notas que exportar.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Datos de lectura exportados a $location';
  }

  @override
  String get readingDataExportFailed =>
      'No se pudieron exportar los datos de lectura';

  @override
  String get readingDataExportUnsupported =>
      'La exportación de datos de lectura aún no es compatible con esta plataforma';

  @override
  String get readingDataExportReplaceTitle =>
      '¿Reemplazar el archivo existente?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Ya existe un archivo en $path. Reemplazarlo no se puede deshacer.';
  }

  @override
  String get readingDataExportReplaceAction => 'Reemplazar';

  @override
  String get readingDataExportExportedAt => 'Exportado';

  @override
  String get readingDataExportAuthor => 'Autor';

  @override
  String get readingDataExportContents => 'Contenido';

  @override
  String get readingDataExportMyNote => 'Mi nota';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Página $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Anotaciones sin ubicar';

  @override
  String get cloudSyncTitle => 'Sincronización en la nube';

  @override
  String get cloudSyncTagline => 'Retoma donde lo dejaste en otro dispositivo';

  @override
  String get cloudSyncResumeTitle => 'Continúa entre dispositivos';

  @override
  String get cloudSyncAutoResume => 'Reanudar al abrir un libro';

  @override
  String get cloudSyncAutoResumeHint =>
      'Comprueba la última posición al abrir; ofrece actualizaciones mientras lees';

  @override
  String get cloudSyncAutoHint =>
      'Guarda el progreso mientras lees y comprueba actualizaciones al abrir un libro';

  @override
  String get cloudSyncMoreContent => 'Más opciones de sincronización';

  @override
  String get cloudSyncBooks => 'Libros y texto';

  @override
  String get cloudSyncBooksHint =>
      'Libros participantes, actualizaciones y descargas de texto';

  @override
  String get cloudSyncActivity => 'Detalles e incidencias de la sincronización';

  @override
  String get cloudSyncStorage => 'Conexión de almacenamiento';

  @override
  String get cloudSyncNoActivity => 'Aún no hay actividad de sincronización';

  @override
  String get cloudSyncProgress => 'Posición de lectura';

  @override
  String get cloudSyncText => 'Archivos de texto de libros';

  @override
  String get cloudSyncMetadataComplete =>
      'Datos de lectura seleccionados intercambiados con WebDAV';

  @override
  String get cloudSyncPaused => 'La sincronización automática está en pausa';

  @override
  String get cloudSyncLocalOnly => 'Mantener en este dispositivo';

  @override
  String get cloudSyncCheckHint =>
      'Una conexión no confirma la recepción en otros dispositivos; comprueba cada elemento a continuación';

  @override
  String get cloudSyncPendingFiles =>
      'Las actualizaciones de texto necesitan atención';

  @override
  String get cloudSyncFileIdle =>
      'Los archivos de texto vinculados se comprobarán en la próxima sincronización';

  @override
  String get cloudSyncManageBooks => 'Elegir libros y descargas';

  @override
  String get cloudSyncNoBooks => 'Aún no hay libros TXT vinculados';

  @override
  String get cloudSyncCompare => 'Comparar versiones';

  @override
  String get cloudSyncKeepLocal => 'Usar la versión de este dispositivo';

  @override
  String get cloudSyncUseRemote => 'Usar la versión de la nube';

  @override
  String get cloudSyncBothKept =>
      'Ambas versiones se conservan. La sincronización continúa tras tu elección.';

  @override
  String get cloudSyncPreviewLimited =>
      'La vista previa muestra la primera diferencia. Ambas versiones completas se conservan.';

  @override
  String get cloudSyncPending => 'Pendiente de sincronizar';

  @override
  String get cloudSyncConflict => 'Las versiones necesitan revisión';

  @override
  String get cloudSyncCurrent => 'El texto actual está sincronizado con WebDAV';

  @override
  String get cloudSyncFailed =>
      'Sincronización incompleta. Hay un reintento disponible.';

  @override
  String get cloudSyncHistory => 'Historial de versiones';

  @override
  String get cloudSyncApplyUpdate => 'Aplicar actualización de texto';

  @override
  String get cloudSyncParticipate => 'Sincronizar el texto de este libro';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Cierra el lector o el editor de este libro antes de aplicar la actualización de texto';

  @override
  String get cloudSyncTextLocation => 'Archivo en la nube actual';

  @override
  String get cloudSyncTextLocationHint =>
      'Gestiona aquí actualizaciones, pausas y conflictos de los libros participantes.';

  @override
  String get bookSourcesImportIntro =>
      'Detecta fuentes automáticamente. Revisa antes de importar.';

  @override
  String get bookSourcesImportInputStep => 'Elegir fuente';

  @override
  String get bookSourcesImportReviewStep => 'Revisar e importar';

  @override
  String get bookSourcesImportFileHint =>
      'Selecciona un archivo JSON de fuentes.';

  @override
  String get bookSourcesImportDownloading => 'Descargando fuente…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Leyendo reglas y comprobando duplicados…';

  @override
  String get bookSourcesImportSaving => 'Guardando fuentes…';

  @override
  String get bookSourcesImportPicking => 'Abriendo el selector de archivos…';

  @override
  String get bookSourcesImportWaitHint =>
      'Las listas de fuentes grandes pueden tardar más. Puedes cancelar e intentarlo de nuevo.';

  @override
  String get bookSourcesImportSaveHint =>
      'Mantén esta ventana abierta hasta que termine el guardado.';

  @override
  String get bookSourcesImportReady => 'Listo para importar';

  @override
  String get bookSourcesImportEmpty =>
      'No hay fuentes seleccionadas. Comprueba el archivo o la selección de duplicados.';

  @override
  String get bookSourcesImportRetry => 'Reintentar';

  @override
  String get bookSourcesImportFailed =>
      'No se pudieron leer las fuentes. Comprueba la dirección o el archivo e inténtalo de nuevo.';

  @override
  String get bookSourcesImportWebPage =>
      'Esta URL devolvió un sitio web o una página de inicio de sesión. Copia el enlace JSON de descarga o de suscripción de fuentes del sitio e impórtalo en su lugar. Podrás iniciar sesión después de importar la fuente.';

  @override
  String get bookSourcesImportSaveFailed =>
      'No se pudieron guardar las fuentes. Tu vista previa se conserva; inténtalo de nuevo.';

  @override
  String get bookSourcesImportErrorDetails => 'Detalles del error';

  @override
  String get bookSourcesImportFileUnreadable =>
      'No se pudo leer el archivo seleccionado. Vuelve a elegirlo.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count fuentes',
      one: 'Importar 1 fuente',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'Archivo JSON';

  @override
  String get bookSourcesImportTimedOut =>
      'La lectura tardó demasiado. Comprueba tu conexión o intenta importar un archivo JSON descargado.';

  @override
  String get bookSourcesImportUsageNotice => 'Información de uso de fuentes';

  @override
  String get bookSourcesMaintenanceScope => 'Ámbito';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Activadas';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Todas las fuentes';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Seleccionadas';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return '$count fuentes en este ámbito';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope =>
      'No hay fuentes en este ámbito';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Comprobación detenida';

  @override
  String get bookSourcesMaintenanceCancellingTitle =>
      'Deteniendo comprobaciones';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Terminando las comprobaciones activas y conservando los resultados completados';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Comprobación interrumpida';

  @override
  String get bookSourcesMaintenanceResume =>
      'Reanudar las comprobaciones pendientes';

  @override
  String get bookSourcesMaintenanceRetry =>
      'Reintentar comprobaciones sin resolver';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return '$count fuentes aún sin comprobar';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Resultados de estado';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Todos los resultados';

  @override
  String get bookSourcesMaintenanceAvailable => 'Disponible';

  @override
  String get bookSourcesMaintenanceLimited => 'Parcial';

  @override
  String get bookSourcesMaintenanceFailed => 'Comprobaciones fallidas';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Tiempo agotado';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Sin confirmar';

  @override
  String get bookSourcesMaintenanceReviewSearch =>
      'Busca por nombre o dirección';

  @override
  String get bookSourcesMaintenanceReviewEmpty =>
      'No hay resultados coincidentes';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return '$count seleccionadas para desactivar';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Seleccionar comprobaciones fallidas';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Tiempo de conexión agotado; reinténtalo más tarde';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Sin resultado concluyente de esta comprobación';

  @override
  String get bookSourcesMaintenanceAvailableReason =>
      'Comprobaciones básicas superadas';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Buscando duplicados…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Usada por tu estantería · se conserva por defecto';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return '$count fuente(s) seleccionada(s) están en uso por libros de tu estantería. Eliminarlas puede impedir que esos libros se actualicen o carguen capítulos nuevos.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Problemas';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return 'Seleccionadas $count fuente(s)';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed => 'En uso por tu estantería';

  @override
  String get bookSourcesMaintenancePause => 'Pausar';

  @override
  String get bookSourcesMaintenancePausing => 'Pausando…';

  @override
  String get bookSourcesMaintenancePaused => 'Comprobación en pausa';

  @override
  String get bookSourcesMaintenanceCompleted => 'Comprobación completada';

  @override
  String get bookSourcesMaintenanceStart => 'Iniciar comprobación';

  @override
  String get bookSourcesMaintenanceRestart => 'Empezar de nuevo';

  @override
  String get bookSourcesMaintenanceCheckedThisRun =>
      'Comprobadas en esta ejecución';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Selecciona y gestiona ahora los resultados completados, o continúa comprobando las fuentes restantes.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'No se pudieron guardar los cambios. Inténtalo de nuevo.';

  @override
  String get settingsQqGroup => 'Grupo de QQ';

  @override
  String get settingsOpenSourceTitle => 'Detalles del código abierto';

  @override
  String get settingsOpenSourceDetails =>
      'Todas las funciones excepto las avanzadas son de código abierto. El código abierto está bajo licencia AGPL-3.0; consulta su ámbito en el repositorio de GitHub.';

  @override
  String get premiumLifetimeTitle => 'Premium de por vida';

  @override
  String get premiumLifetimeCaption =>
      'Compra única · Sin renovación automática';

  @override
  String get premiumBenefitsTitle => 'Incluido con Premium';

  @override
  String get premiumProtocolsBenefit =>
      'Importa y usa protocolos de fuente compatibles adicionales.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Accede a fuentes de confianza en tu dispositivo, red local o red privada.';

  @override
  String get premiumSourceNotice =>
      'Premium no incluye libros ni direcciones de fuentes. Los servicios de terceros pueden cobrar aparte.';

  @override
  String get premiumSetupHint =>
      'Tras desbloquear, activa estas opciones en Ajustes → Funciones avanzadas.';

  @override
  String get premiumBillingTitle => 'Detalles de la compra';

  @override
  String get premiumBillingBody =>
      'Es una compra única no consumible, no una suscripción. No se renueva automáticamente. El App Store muestra el precio real y Apple gestiona el pago.';

  @override
  String get premiumRestoreHelp =>
      'Tras reinstalar o cambiar de dispositivo, restaura con la cuenta de Apple usada para la compra y la cuenta de Origo X vinculada. Restaurar no te cobra de nuevo.';

  @override
  String get premiumMembershipTerms => 'Términos de membresía';

  @override
  String get premiumPrivacyPolicy => 'Política de privacidad';

  @override
  String get premiumAppleEula => 'EULA estándar de Apple';

  @override
  String get premiumPurchaseConsent =>
      'Antes de comprar, lee los términos de membresía, la política de privacidad y el EULA estándar de Apple.';

  @override
  String get premiumAccountBindingTitle => 'Cuenta y acceso';

  @override
  String get premiumAccountBindingBody =>
      'Tras la verificación, Premium se vincula a la cuenta actual de Origo X y se sincroniza entre las plataformas compatibles. Los ajustes avanzados estarán disponibles con la membresía. Cerrar sesión o una revocación desactiva las funciones avanzadas. Comprueba tu cuenta antes de comprar.';

  @override
  String get premiumRefundTitle => 'Solicitar un reembolso';

  @override
  String get premiumRefundTerms =>
      'Apple revisa y procesa las solicitudes de reembolso del App Store según sus normas aplicables. Enviar una solicitud no significa que se apruebe. Las compras reembolsadas o revocadas dejan de proporcionar el acceso Premium correspondiente.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Datos de verificación de compra';

  @override
  String get premiumPrivacyPurchaseBody =>
      'Apple gestiona la información de pago. La app envía el identificador del producto y los datos de verificación de transacción firmados por Apple al servicio de cuentas de Origo X para verificar compras y vincular o restaurar Premium. Este flujo de compra no entrega al desarrollador tu número completo de tarjeta ni tu contraseña de la cuenta de Apple.';

  @override
  String get premiumPrivacyAccountTitle => 'Servicio de cuentas';

  @override
  String get premiumPrivacyAccountBody =>
      'El servicio de cuentas de Origo X procesa los datos de la cuenta y los registros de membresía para el inicio de sesión, la verificación de seguridad y el acceso entre dispositivos. Contáctanos para soporte o privacidad mediante las opciones de contacto del sitio web oficial.';

  @override
  String get premiumPurchaseSuccess => 'Premium desbloqueado';

  @override
  String get premiumTestPurchaseVerified =>
      'Compra de prueba verificada. No se activó el Premium formal.';

  @override
  String get premiumPurchaseRevoked =>
      'El acceso Premium de esta compra ha sido revocado.';

  @override
  String get premiumRestoreSuccess =>
      'Compra restaurada. Premium está sincronizado.';

  @override
  String get premiumRestoreEmpty =>
      'No se encontró ninguna compra restaurable. Comprueba tu cuenta de Apple y la cuenta de Origo X vinculada a la compra.';

  @override
  String get premiumPurchaseCanceled => 'Compra cancelada';

  @override
  String get premiumPendingApproval =>
      'Esperando la aprobación de Apple. El acceso se desbloquea tras la aprobación y verificación.';

  @override
  String get premiumVerifying => 'Verificando tu compra…';

  @override
  String get premiumRestoring => 'Restaurando compras…';

  @override
  String get premiumRefundSubmitted =>
      'Solicitud de reembolso enviada a Apple para su revisión.';

  @override
  String get premiumRefundNotFound =>
      'No se encontró ninguna compra de Premium reembolsable para esta cuenta de Apple. También puedes consultar tu historial con el soporte de compras de Apple.';

  @override
  String get premiumApplePurchaseSupport => 'Soporte de compras de Apple';

  @override
  String get premiumLinkFailed =>
      'No se pudo abrir este enlace. Inténtalo de nuevo más tarde.';

  @override
  String get premiumSignInRequired =>
      'Inicia sesión en Origo X antes de comprar o restaurar Premium.';

  @override
  String get premiumRefundUnavailable =>
      'La hoja de reembolso de Apple no está disponible. Continúa por el soporte de compras de Apple.';

  @override
  String get premiumOperationFailed =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get premiumPurchaseConsentOther =>
      'Lee los términos de membresía y la política de privacidad antes de desbloquear Premium.';

  @override
  String get premiumBillingBodyOther =>
      'Desbloquea Premium con las opciones de compra o canje disponibles. El canal de compra muestra el precio y el método de pago. La membresía verificada se vincula a tu cuenta actual de Origo X.';

  @override
  String get accountDeleteTitle => 'Eliminar cuenta';

  @override
  String get accountDeleteEntrySubtitle =>
      'Borra permanentemente esta cuenta y todos sus datos';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get accountDeleteReviewTitle => 'Qué hace la eliminación';

  @override
  String get accountDeleteReviewBody =>
      'Lee cada punto. En cuanto confirmes, todo lo que aparece abajo se elimina de inmediato y no podremos recuperarlo por ti.';

  @override
  String get accountDeleteCurrentAccount => 'Cuenta actual';

  @override
  String get accountDeleteJoined => 'Fecha de registro';

  @override
  String get accountDeletePremiumActive =>
      'Premium desbloqueado (se eliminará)';

  @override
  String get accountDeletePremiumNone => 'Premium no desbloqueado';

  @override
  String get accountDeleteHasTitle => 'Esta cuenta tiene actualmente';

  @override
  String accountDeleteHasSessions(int count) {
    return '$count dispositivos con sesión iniciada';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return '$count passkeys';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return '$count proveedores de inicio de sesión vinculados';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return '$count miembros que se unieron con tu código de invitación';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return '$count códigos canjeados';
  }

  @override
  String get accountDeleteTermsTitle => 'Términos de la eliminación';

  @override
  String get accountDeleteTermsIrreversible =>
      'La eliminación de la cuenta es definitiva y no puede revertirse. En cuanto confirmes, nadie —ni el soporte— tendrá forma de restaurar los datos eliminados.';

  @override
  String get accountDeleteTermsIdentity =>
      'La cuenta en sí se elimina: tu correo electrónico, nombre de usuario, nombre visible y avatar.';

  @override
  String get accountDeleteTermsLogins =>
      'Se elimina todo método de inicio de sesión: tu contraseña, tus passkeys y tus vínculos con Google, GitHub y Apple.';

  @override
  String get accountDeleteTermsSessions =>
      'Cierras sesión en todas partes de inmediato, en teléfonos, tabletas y computadoras por igual.';

  @override
  String get accountDeleteTermsMfa =>
      'Tu configuración de dos factores y todos los códigos de recuperación se eliminan.';

  @override
  String get accountDeleteTermsPremium =>
      'El acceso Premium se elimina, sin importar cómo lo desbloquearas: un código de canje, una recompensa por invitación o una compra en Apple.';

  @override
  String get accountDeleteTermsReferrals =>
      'Tu código de invitación deja de funcionar y se eliminan los registros de referidos entre tú y las personas que invitaste. Las recompensas ya entregadas a otros no se retiran.';

  @override
  String get accountDeleteTermsRedemptions =>
      'Los códigos de canje que ya hayas usado no se reembolsan ni vuelven a estar disponibles.';

  @override
  String get accountDeleteTermsApple =>
      'Compraste Premium de por vida en el App Store. Eliminar tu cuenta no lo reembolsa ni cancela ninguna transacción del App Store: los reembolsos solo pueden solicitarse a Apple. El recibo de tu compra se desvincula de esta cuenta y se conserva, para que luego puedas tocar Restaurar compras en una cuenta nueva con el mismo Apple ID y recuperar Premium.';

  @override
  String get accountDeleteTermsLocalData =>
      'Los libros, estanterías y progreso de lectura de este dispositivo no se eliminan: siempre han vivido solo en tu dispositivo. Elimínalos en la app si también quieres prescindir de ellos.';

  @override
  String get accountDeleteTermsTombstone =>
      'Conservamos solo los datos mínimos de eliminación desidentificados necesarios para prevenir abusos, junto con los registros de verificación de compras del App Store necesarios para restaurar o verificar compras. Estos registros no se usan para recrear tu cuenta.';

  @override
  String get accountDeleteTermsRejoin =>
      'Tras la eliminación, el mismo correo puede registrarse de nuevo, pero será una cuenta nueva y vacía, sin ninguno de tus datos o accesos anteriores.';

  @override
  String get accountDeleteBlockedTitle =>
      'Esta cuenta todavía no se puede eliminar';

  @override
  String get accountDeleteBlockedOwner =>
      'Eres el propietario de la consola de administración. Transfiere la propiedad a otra persona primero y vuelve; de lo contrario, no quedaría nadie para administrarla.';

  @override
  String get accountDeleteConsent =>
      'He leído los términos completos, entiendo que la eliminación no puede deshacerse y acepto eliminar permanentemente mi cuenta y todos sus datos.';

  @override
  String get accountDeleteConsentRequired =>
      'Acepta primero los términos de la eliminación.';

  @override
  String get accountDeleteContinue => 'Lo entiendo, continuar';

  @override
  String get accountDeleteVerifyTitle => 'Verifica tu correo electrónico';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Enviaremos un código de 6 dígitos a $email para confirmar que esta solicitud es realmente tuya.';
  }

  @override
  String get accountDeleteSendCode => 'Enviar código de eliminación';

  @override
  String get accountDeleteResendCode => 'Enviar de nuevo';

  @override
  String get accountDeleteCodeSent =>
      'Código enviado. Completa la eliminación en un plazo de 10 minutos.';

  @override
  String get accountDeleteConfirmTitle => 'Último paso';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Escribe el correo de tu cuenta $email para que no haya dudas de qué cuenta se elimina.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'En el momento en que pulses el botón de abajo, la cuenta se elimina permanentemente.';

  @override
  String get accountDeleteConfirmField =>
      'Escribe el correo de tu cuenta para confirmar';

  @override
  String get accountDeleteMfaHint =>
      'Esta cuenta tiene la autenticación de dos factores activada, así que se necesita un código más.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Ese correo no coincide con la cuenta actual.';

  @override
  String get accountDeleteAction => 'Eliminar mi cuenta permanentemente';

  @override
  String get accountDeleteDoneTitle => 'Tu cuenta ha sido eliminada';

  @override
  String get accountDeleteDoneBody =>
      'Tu cuenta y sus datos han desaparecido para siempre y se ha cerrado la sesión en todos los dispositivos. Gracias por haber usado Origo X.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Tras cerrar este cuadro de diálogo, abre Ajustes de la cuenta de Apple > Inicio de sesión y seguridad > Iniciar sesión con Apple > Origo X y elige Dejar de usar Iniciar sesión con Apple.';

  @override
  String get accountDeleteDoneClose => 'Cerrar';

  @override
  String get bookSourceDetailsTitle => 'Detalles del libro';

  @override
  String get bookSourceDetailsDescription => 'Sobre este libro';

  @override
  String get bookSourceDetailsNoDescription =>
      'Esta fuente no proporciona descripción.';

  @override
  String get bookSourceDetailsLatestChapter => 'Capítulo más reciente';

  @override
  String get bookSourceDetailsLoadFailed =>
      'No se pudieron cargar los detalles completos. Puedes reintentar o leer con la información disponible.';

  @override
  String get bookSourceDetailsOnShelf => 'En la estantería';

  @override
  String get bookSourceDetailsAddFailed =>
      'No se pudo añadir este libro a tu estantería. Inténtalo de nuevo.';

  @override
  String get bookSourceDetailsReadFailed =>
      'No se pudo abrir este libro. Inténtalo de nuevo.';

  @override
  String get appTextSize => 'Tamaño del texto de la interfaz';

  @override
  String get appTextSizeDescription =>
      'Solo cambia los menús y controles de la app, no el texto de lectura.';

  @override
  String get appTextSizePreview =>
      'Los menús y ajustes usarán este tamaño de texto.';

  @override
  String get appTextSizeDefault => '100 % (predeterminado)';

  @override
  String get bookSourceTrackUpdatesTitle =>
      'Actualizaciones y texto descargado';

  @override
  String get bookSourceTrackUpdatesBody =>
      'Los libros descargados conservan su fuente. Comprueba si hay capítulos nuevos para añadir contenido, o actualiza los capítulos descargados preservando tus ediciones e historial.';

  @override
  String get bookSourceCheckNewChapters => 'Comprobar capítulos nuevos';

  @override
  String get bookSourceRefreshDownloaded => 'Actualizar capítulos descargados';

  @override
  String get bookSourceNoNewChapters =>
      'No hay capítulos nuevos en el catálogo. Actualiza los capítulos descargados para comprobar si el texto anterior cambió.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return '$added capítulos añadidos, $refreshed actualizados';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Confirma el último capítulo ya descargado antes de continuar con las actualizaciones. Tu texto existente se conservará.';

  @override
  String get bookSourceSelectBoundary => 'Confirmar capítulos descargados';

  @override
  String get bookSourceBoundaryHelp =>
      'Selecciona el último capítulo de la fuente incluido en tu texto local. Solo se añadirán los capítulos posteriores; el texto existente queda intacto.';

  @override
  String get bookSourceTrackingEstablished =>
      'Límite de seguimiento guardado. Ya puedes comprobar si hay capítulos nuevos.';

  @override
  String get bookSourceMappingChanged =>
      'La fuente cambió el orden o los identificadores de sus capítulos. Confirma de nuevo tus capítulos descargados. El texto existente se conservó.';

  @override
  String get bookSourceContentConflicts =>
      'Los cambios de texto necesitan revisión';

  @override
  String get bookSourceContentConflictBody =>
      'Tú y la fuente modificasteis estos capítulos. Tu versión sigue activa. Compara y elige qué leer; ambas versiones permanecen en el historial.';

  @override
  String get bookSourceCompareVersions => 'Comparar texto';

  @override
  String get bookSourceLocalVersion => 'Mi texto';

  @override
  String get bookSourceRemoteVersion => 'Texto de la fuente';

  @override
  String get bookSourceBaselineVersion => 'Base descargada';

  @override
  String get bookSourceKeepLocal => 'Conservar mi texto';

  @override
  String get bookSourceUseRemote => 'Usar el texto de la fuente';

  @override
  String get bookSourceUpdateFailed =>
      'La actualización no terminó. Tu texto se conservó. Reinténtalo.';

  @override
  String get cloudSyncReadableStorage =>
      'Los libros editados se suben como archivos completos. Los libros sin cambios no se vuelven a transferir. El progreso de lectura se sincroniza aparte.';

  @override
  String get bookSourceBindSource => 'Vincular una fuente de libros';

  @override
  String get bookSourceNotBound => 'Sin fuente vinculada';

  @override
  String get bookSourceDownloadedUnchanged =>
      'Los capítulos descargados están al día.';

  @override
  String get premiumSyncFailed =>
      'No se pudo sincronizar el estado de la membresía. Se reintentará automáticamente; un fallo de conexión no revoca el acceso verificado.';

  @override
  String get premiumGrantedAccess =>
      'Tienes acceso Premium de cortesía. No necesitas ninguna compra adicional.';

  @override
  String get premiumOtherChannelAccess =>
      'Tienes Premium por otro canal. No necesitas ninguna compra adicional.';

  @override
  String get premiumAppleAccess =>
      'Tienes Premium a través del App Store. No necesitas ninguna compra adicional.';

  @override
  String get premiumExistingAccess =>
      'Ya tienes Premium. No necesitas ninguna compra adicional.';

  @override
  String get premiumSyncPending => 'Sincronizando el estado de la membresía';

  @override
  String get cloudSyncExportBook => 'Exportar archivo completo a la nube';

  @override
  String get cloudSyncExportDone => 'Archivo completo exportado';

  @override
  String get cloudSyncDiagnostics => 'Copiar diagnóstico de sincronización';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Esta carpeta pertenece a un formato de sincronización anterior. Elige una carpeta nueva vacía. Tus libros locales y los archivos existentes en la nube se conservarán.';

  @override
  String get cloudSyncSettings => 'Ajustes de sincronización';

  @override
  String get cloudSyncSettingsHint =>
      'Sincronización automática, otros datos y conexión';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Sincroniza posiciones de lectura sin subir archivos de libros';

  @override
  String get cloudSyncProgressExplanation =>
      'Si ambos dispositivos tienen el mismo libro, puedes sincronizar solo el progreso de lectura. El teléfono nuevo necesita igualmente una copia legible; los registros de progreso no contienen el texto del libro.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Sube o descarga libros; las ediciones suben el archivo completo';

  @override
  String get cloudSyncOtherDataHint =>
      'Biblioteca, fuentes, marcadores, notas y ajustes de lectura';

  @override
  String get cloudSyncActivityHint =>
      'Progreso, estado de los archivos y detalles de los fallos';

  @override
  String get cloudSyncNeedsAttention =>
      'Una incidencia de sincronización necesita atención';

  @override
  String get cloudSyncFileStatus => 'Actualizaciones y conflictos';

  @override
  String get cloudSyncTransferGuide => 'Cambiar a un teléfono nuevo';

  @override
  String get cloudSyncTransferGuideHint =>
      'Restaura libros y progreso de lectura en un teléfono nuevo';

  @override
  String get cloudSyncTransferIntro =>
      'Subir un libro es opcional para la sincronización del progreso. Solo necesitas una copia en la nube si el teléfono nuevo aún no tiene el libro y quieres descargarlo desde aquí.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Sincroniza el progreso en el teléfono antiguo';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Sal del lector para guardar tu última posición, activa Progreso de lectura y toca Sincronizar ahora. Usa la misma conexión WebDAV y la misma carpeta de sincronización en ambos teléfonos.';

  @override
  String get cloudSyncTransferHasBook =>
      '2. El teléfono nuevo ya tiene el libro';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Importa el mismo archivo local o abre el mismo libro en línea desde la misma fuente. Sincroniza el progreso y abre el libro para continuar. Que los títulos coincidan no garantiza una coincidencia.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. El teléfono nuevo necesita el archivo del libro';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'En el teléfono antiguo, abre Archivos de libros, permite las subidas y selecciona el libro. Cuando la subida termine, sincroniza el teléfono nuevo y descárgalo desde Disponibles para descargar. También puedes transferir tú mismo el mismo archivo.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Si editaste el texto en el teléfono antiguo, sube esa versión mediante Archivos de libros y descárgala en el teléfono nuevo para preservar la identidad del libro. Las posiciones de lectura pueden no corresponderse entre versiones distintas del texto.';

  @override
  String get cloudSyncFrequency => 'Frecuencia de sincronización automática';

  @override
  String get cloudSyncFrequencyOff => 'Desactivada (solo manual)';

  @override
  String get cloudSyncFrequencyOnChange => 'Tras los cambios';

  @override
  String get cloudSyncFrequency15Minutes => 'Cada 15 minutos';

  @override
  String get cloudSyncFrequencyHourly => 'Cada hora';

  @override
  String get cloudSyncFrequencyDaily => 'Una vez al día';

  @override
  String get cloudSyncFrequencyHint =>
      'Los intervalos empiezan tras una sincronización automática correcta. Si la app no está en ejecución, se pone al día la próxima vez que la abras. Los intentos fallidos se reintentan. Sincronizar ahora siempre funciona de inmediato.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Sincronización automática: $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'El progreso se obtiene con la frecuencia que elijas. Abrir un libro reanuda desde la última posición sincronizada. Toca primero Sincronizar ahora cuando necesites el progreso más reciente.';

  @override
  String get readerChapterProgressTitle => 'Progreso de capítulos';

  @override
  String get readerChapterProgressHidden => 'Oculto';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return '$chapter/$total capítulos';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return '$count capítulos por delante';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'La prueba de Premium caduca el $date.';
  }

  @override
  String get premiumTrialTitle => 'Prueba de Premium';

  @override
  String get bookSourceCheckUpdates => 'Comprobar actualizaciones';

  @override
  String get bookSourceUpdates => 'Actualizaciones del libro';

  @override
  String get bookSourceNotChecked => 'Aún sin comprobar';

  @override
  String get bookSourceUpToDate => 'El catálogo está al día';

  @override
  String get bookSourceUpdatesAvailable => 'Hay capítulos nuevos disponibles';

  @override
  String get bookSourceNeedsMapping => 'Confirma dónde continuar';

  @override
  String bookSourceLastChecked(String time) {
    return 'Última comprobación: $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Última actualización: $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown =>
      'Fecha de actualización no disponible';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Lo más reciente: $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Mientras la biblioteca está abierta, los catálogos se comprueban cada 30 minutos. Compruébalo manualmente cuando quieras. Los libros en línea usan el catálogo más reciente; los libros TXT locales solo descargan capítulos nuevos cuando eliges continuar. Tras vincular o cambiar una fuente, confirma el último capítulo ya presente en tu archivo local. Las actualizaciones no sustituyen tu texto original. La fecha de actualización la suministra la fuente o registra cuándo se detectó por primera vez un capítulo nuevo.';

  @override
  String get bookSourceBindHelp =>
      'Busca este libro en tus fuentes para añadir su portada y activar el cambio de fuente y las actualizaciones de capítulos. Tu texto local y tu posición de lectura se conservan.';

  @override
  String get bookSourceContinueUpdate => 'Descargar capítulos nuevos';
}
