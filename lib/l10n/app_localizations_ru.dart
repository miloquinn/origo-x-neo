// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Главная';

  @override
  String get library => 'Книжная полка';

  @override
  String get bookSources => 'Источники';

  @override
  String get discover => 'Обзор';

  @override
  String get discoverRecommended => 'Для вас';

  @override
  String get discoverCategories => 'Категории';

  @override
  String get discoverLatest => 'Новинки';

  @override
  String get discoverLoadFailed =>
      'Не удалось загрузить содержимое раздела «Обзор»';

  @override
  String get discoverRetry => 'Попробовать снова';

  @override
  String get discoverEmptyTitle => 'Пока нечего показать';

  @override
  String get discoverEmptyMessage => 'В этом разделе пока нет содержимого.';

  @override
  String get discoverUnsupportedTitle =>
      'Текущие источники не поддерживают этот раздел';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'Требуется источник с возможностью «$capability». Поиск по имеющимся источникам по-прежнему работает.';
  }

  @override
  String get discoverCategoryEmpty => 'В этой категории пока нет книг.';

  @override
  String get bookSourceChannelLoadFailed => 'Не удалось загрузить канал';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'Источник не вернул пригодных книг: $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'Не удалось подключиться к серверу источника, перепробовав все доступные сетевые адреса. Попробуйте позже.';

  @override
  String get bookSourceRedirectFailed =>
      'Сайт источника постоянно перенаправлял запросы. Cookies сайта сохранены, но адрес по-прежнему не возвращает содержимое.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'Сайт источника вернул HTTP $status. Адрес канала мог устареть или заблокирован сайтом.';
  }

  @override
  String get bookSourceStandardLayout => 'Стандартный вид';

  @override
  String get bookSourceListLayout => 'Список';

  @override
  String get bookSourceChangeChannel => 'Изменить';

  @override
  String get bookSourceChangeSourceTitle => 'Смена источника';

  @override
  String get bookSourceChangeCurrentSource => 'Текущий источник';

  @override
  String get bookSourceChangeTargetSource => 'Заменить на';

  @override
  String get bookSourceChangeNotSelected => 'Не выбран';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'Сейчас глава $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Найти эту книгу в других источниках';

  @override
  String get bookSourceChangeSearchAgain => 'Искать снова';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Искать во всех остальных источниках';

  @override
  String get bookSourceChangeCheckAuthor => 'Сверять автора';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return 'Проверено $completed из $total';
  }

  @override
  String get bookSourceChangeNoOtherSources => 'Другие источники недоступны';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Сначала добавьте и включите ещё один источник с поддержкой поиска.';

  @override
  String get bookSourceChangeSearching => 'Поиск в других источниках';

  @override
  String get bookSourceChangeSearchingHint =>
      'Совпадения появляются по мере завершения поиска каждым источником.';

  @override
  String get bookSourceChangeNoMatches => 'Подходящие источники не найдены';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Измените название или отключите сверку автора и повторите поиск.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return 'Ошибок запросов к источникам: $count. Можно повторить поиск.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Другой автор';

  @override
  String get bookSourceChangeValidating => 'Проверка каталога и текущей главы…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Проверка не удалась: $details';
  }

  @override
  String get bookSourceChangeReadable => 'Текущая глава читается';

  @override
  String bookSourceChangeChapterCount(int count) {
    return 'Глав: $count';
  }

  @override
  String bookSourceChangeResponseTime(int milliseconds) {
    return '$milliseconds мс';
  }

  @override
  String get bookSourceChangeTapToValidate =>
      'Выберите, чтобы проверить каталог и текущую главу.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Эта версия источника уже есть на книжной полке.';

  @override
  String get bookSourceChangeSwitching => 'Смена источника…';

  @override
  String get bookSourceChangeSwitchAction => 'Перейти на этот источник';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Источник изменён на $source';
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
    return 'Каналов: $count';
  }

  @override
  String get bookSourceManagementTitle => 'Управление источниками';

  @override
  String get bookSourceManagementSubtitle =>
      'Добавляйте, включайте, удаляйте и проверяйте поставщиков контента. Раздел «Обзор» остаётся сосредоточенным на поиске книг.';

  @override
  String get settingsContentSourcesTitle => 'Источники контента';

  @override
  String get settingsContentSourcesSubtitle =>
      'Добавление, включение или удаление открытых источников книг';

  @override
  String get bookSourcesSubtitle =>
      'Подключайте открытые источники и ищите читаемый контент у разных поставщиков';

  @override
  String get bookSourcesAdd => 'Добавить источник';

  @override
  String get bookSourcesSearchHint =>
      'Поиск по включённым источникам: название или автор';

  @override
  String get bookSourcesSearch => 'Найти';

  @override
  String get bookSourcesLoadMore => 'Показать ещё';

  @override
  String bookSourcesFailedCount(int count) {
    return 'Ошибок запросов к источникам: $count';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Настройки поиска';

  @override
  String get bookSourcesSearchSettingsTitle => 'Настройки поиска';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Одновременные запросы';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Тайм-аут на источник (с)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Лимит источников';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Когда включено много источников, за раз поиском охватываются только указанное количество (в порядке списка) — для экономии трафика и батареи.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return 'Включено источников: $enabledCount, что превышает текущий лимит ($limit). Источники сверх лимита не будут охвачены поиском.';
  }

  @override
  String get bookSourcesSearchResetDefaults =>
      'Сбросить настройки по умолчанию';

  @override
  String get bookSourcesSearchPrompt =>
      'Добавьте и включите источник, чтобы искать по нему здесь';

  @override
  String get bookSourcesNoResults => 'Подходящие книги не найдены';

  @override
  String get bookSourcesNoSourcesTitle => 'Источников пока нет';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Вставьте адрес сервиса, совместимого с Origo Source Protocol.';

  @override
  String get bookSourcesManageTitle => 'Подключённые источники';

  @override
  String get bookSourcesEnabled => 'Включён';

  @override
  String get bookSourcesDisabled => 'Отключён';

  @override
  String get bookSourcesRunnable => 'Готов к использованию';

  @override
  String get bookSourcesPendingCompatibility => 'Нет работоспособных правил';

  @override
  String get bookSourcesRequiresLogin => 'Требуется вход';

  @override
  String get bookSourcesManagementSearchHint =>
      'Поиск по названию, URL, заметкам или группе';

  @override
  String get bookSourcesClearSearch => 'Очистить поиск';

  @override
  String get bookSourcesAllGroups => 'Все группы';

  @override
  String get bookSourcesChooseGroup => 'Выбор группы источников';

  @override
  String get bookSourcesSearchGroups => 'Группы поиска';

  @override
  String get bookSourcesNoMatchingSources =>
      'Нет источников, соответствующих текущему поиску и фильтрам';

  @override
  String get bookSourcesResetFilters => 'Сбросить';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return 'Показано: $visible из $total';
  }

  @override
  String get bookSourcesRemove => 'Удалить';

  @override
  String get bookSourcesRemoveTitle => 'Удаление источника';

  @override
  String get bookSourcesRemoveMessage =>
      'Удаляется только конфигурация источника. Локальные книги не затрагиваются.';

  @override
  String get bookSourcesCancel => 'Отмена';

  @override
  String get bookSourcesConfirm => 'Подтвердить';

  @override
  String get bookSourcesAddTitle => 'Добавление источника';

  @override
  String get bookSourcesImportLink => 'Импорт ссылки';

  @override
  String get bookSourcesAnalyze => 'Прочитать источники';

  @override
  String get bookSourcesDetectedOrsp => 'Обнаружено: ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Обнаружено: Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'Источники ORSP';

  @override
  String get bookSourcesProtocolGroupAdditional =>
      'Источники других протоколов';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Этот источник недоступен для текущей учётной записи или настроек.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Ни один источник не прошёл проверку реальным поиском. Ничего не импортировано.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return 'Проверено $completed/$total; работает $available';
  }

  @override
  String get bookSourcesSelect => 'Выбор источников';

  @override
  String get bookSourcesSelectAll => 'Выбрать все';

  @override
  String get bookSourcesClearSelection => 'Снять выделение';

  @override
  String get bookSourcesEnableSelected => 'Включить выбранные';

  @override
  String get bookSourcesDisableSelected => 'Отключить выбранные';

  @override
  String get bookSourcesExportSelected => 'Экспортировать выбранные';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return 'Экспортировано $count источник(ов) в $location';
  }

  @override
  String get bookSourcesExportFailed =>
      'Не удалось экспортировать выбранные источники';

  @override
  String get bookSourcesExportUnsupported =>
      'Экспорт источников пока не поддерживается на этой платформе';

  @override
  String get bookSourcesExportReplaceTitle => 'Заменить существующий файл?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Файл уже существует: $path. Заменить его?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Заменить';

  @override
  String get bookSourcesDeleteSelected => 'Удалить выбранные';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return 'Удалить выбранные источники ($count)? Локальные книги не затрагиваются.';
  }

  @override
  String get bookSourcesCheckSelected => 'Проверить выбранные';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return 'Исправных источников: $healthy из $total';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Проверка и очистка источников';

  @override
  String get bookSourcesCleanupNoCheckableSources =>
      'Нет источников для проверки';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Все проверенные источники ($count) полностью доступны';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Результаты проверки';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return 'Полностью доступны: $fullyAvailable · требуют внимания: $needsAttention';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Отсутствующие функции или тайм-аут не означают, что источник неработоспособен. Выбирайте только те источники, которые хотите отключить.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return 'Отключить выбранные: $count';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return 'Отключено источников: $count';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Остановлено — проверено источников: $count. Позже запустите проверку снова, чтобы продолжить с места остановки.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Обслуживание источников';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Поиск дубликатов и проверка доступности источников';

  @override
  String get bookSourcesMaintenanceHealthTitle =>
      'Проверка работоспособности источников';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Тест поиска и чтения; повторное использование свежих успешных результатов';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Идёт проверка работоспособности источников';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Очистка дубликатов';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Локальное сравнение источников, сеть не требуется';

  @override
  String get bookSourcesMaintenanceReviewTitle =>
      'Результат последней проверки';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return 'Источников, требующих внимания: $count';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Отключаются только источники, которые вы подтвердите. Их конфигурации сохраняются.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Проверка источников';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Проверка поиска, сведений, каталогов и содержимого';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Проверка работоспособности источников завершена';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return 'Проверено источников: $checked; требуют внимания: $attention';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Остановить проверку';

  @override
  String get bookSourcesMaintenanceBackground => 'Продолжить в фоне';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Закройте этот экран прогресса — проверка тихо продолжится, пока приложение работает.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'Проверка источников тихо продолжается в фоне';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Просмотреть результаты';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Обслуживание источников $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Поиск дубликатов источников';

  @override
  String get bookSourcesDedupeNone => 'Дубликаты источников не найдены';

  @override
  String get bookSourcesDedupeReviewTitle => 'Просмотр дубликатов источников';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return 'Групп: $groups, дубликатов источников: $duplicates';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'Рекомендованный источник сохраняется. Выбранные дубликаты будут отключены, а не удалены.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return 'Отключить выбранные: $count';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return 'Отключено дубликатов источников: $count';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Точное совпадение';

  @override
  String get bookSourcesDedupeModeStandard => 'Стандартный';

  @override
  String get bookSourcesDedupeModeSite => 'Тот же сайт';

  @override
  String get bookSourcesDedupeExactReason => 'Тождественный источник';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Одинаковый нормализованный адрес источника';

  @override
  String get bookSourcesDedupeSiteReason => 'Тот же сайт; требуется проверка';

  @override
  String get bookSourcesDedupeRecommended => 'Рекомендуемый';

  @override
  String get bookSourcesDedupeReviewAction => 'Просмотреть дубликаты';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return 'Готовых: $ready, дубликатов: $duplicates, нерабочих: $errors';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return 'Книг: $books · комиксов: $comics · пока неработоспособных: $unsupported';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults => 'Восстановить рекомендации';

  @override
  String get bookSourcesUrlLabel => 'Адрес источника';

  @override
  String get bookSourcesUrlHint => 'https://example.com или URL JSON источника';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'Origo X не содержит источников и не управляет сторонними сервисами источников, не рекомендует и не одобряет их. Каждый адрес источника добавляете вы сами.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Я подтверждаю, что имею право доступа к этому контенту, и не буду использовать источник для обхода входа, оплаты, DRM или иных средств контроля доступа.';

  @override
  String get bookSourcesConnect => 'Прочитать и импортировать';

  @override
  String get bookSourcesConnecting => 'Обработка источников…';

  @override
  String get bookSourcesAdded => 'Источник добавлен';

  @override
  String get bookSourcesRefresh => 'Обновить источник';

  @override
  String get bookSourcesRefreshed => 'Источник книг обновлён';

  @override
  String get bookSourcesRefreshFailed =>
      'Не удалось обновить этот источник книг';

  @override
  String get bookSourcesProtocolTitle => 'Origo Source Protocol';

  @override
  String get bookSourcesInformationTitle => 'Протокол и информация';

  @override
  String get bookSourcesInformationSubtitle =>
      'Сведения о протоколе, ссылках проекта и правах на контент';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'О возможностях источников и открытом протоколе';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Репозиторий протокола на GitHub';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'О стороннем контенте и границах прав';

  @override
  String get bookSourcesProtocolDescription =>
      'Общий контракт для обзора, поиска, сведений о книгах, каталогов и содержимого глав. Разработчики могут размещать собственные источники или создавать адаптеры для контента, который им разрешено предоставлять.';

  @override
  String get bookSourcesProtocolDetails => 'Открыть протокол';

  @override
  String get bookSourcesProtocolRepository => 'Репозиторий протокола';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Открыть на GitHub';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'Не удалось открыть репозиторий протокола';

  @override
  String get bookSourcesProtocolDialogTitle =>
      'Открытый протокол источников v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Источник публикует /.well-known/open-reading-source.json и реализует возможности Core Reading: поиск, сведения о книге, постраничные каталоги глав и содержимое глав. Версия 1.4 сохраняет полную постраничную разбивку каталога, требует этих базовых возможностей и сохраняет метаданные оператора, контактов, лицензии и заявления о правах для публичных HTTP(S)-источников без обязательного входа.';

  @override
  String get bookSourcesRightsDetails => 'Оператор и права';

  @override
  String get bookSourcesOperator => 'Оператор источника';

  @override
  String get bookSourcesContentLicense => 'Лицензия на контент';

  @override
  String get bookSourcesRightsStatement => 'Заявление о правах';

  @override
  String get bookSourcesRightsNotProvided => 'Источник не предоставил';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Эти заявления предоставлены независимым оператором источника. Origo X показывает их для прозрачности, но не проверяет и не одобряет их.';

  @override
  String get bookSourcesContactOperator => 'Связаться с оператором';

  @override
  String get bookSourcesRightsReport => 'Отчёт о правах';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'Не удалось открыть форму отчёта о правах';

  @override
  String get bookSourcesClose => 'Закрыть';

  @override
  String get sourceLoginTitle => 'Вход в источник';

  @override
  String get sourceLoginInfo => 'Данные для входа';

  @override
  String get sourceLoginActions => 'Действия с источником';

  @override
  String get sourceLoginExtraSettings => 'Дополнительные настройки';

  @override
  String get sourceLoginSecureStorageNotice =>
      'Данные входа хранятся в защищённом системном хранилище этого устройства.';

  @override
  String get sourceLoginNoForm =>
      'Этот источник не предоставляет доступного способа входа.';

  @override
  String get sourceLoginBrowserTitle => 'Вход на оригинальном сайте';

  @override
  String get sourceLoginBrowserNotice =>
      'Завершите вход в браузере, затем нажмите «Готово». Cookies и локальное хранилище сайта будут сохранены на этом устройстве.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'Вход через сайт доступен на Android, iPhone, iPad и Mac.';

  @override
  String get sourceLoginBrowserOpen => 'Открыть сайт для входа';

  @override
  String get sourceLoginSave => 'Войти и сохранить сессию';

  @override
  String get sourceLoginClear => 'Очистить сессию входа';

  @override
  String get sourceLoginSaved => 'Сессия входа в источник обновлена';

  @override
  String get sourceLoginCleared => 'Сессия входа в источник очищена';

  @override
  String sourceLoginFailed(String details) {
    return 'Не удалось обновить сессию входа в источник: $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '«$sourceName» предоставляет вход для контента, доступного только по учётной записи.';
  }

  @override
  String get sourceDebugMenuLabel => 'Отладка';

  @override
  String get sourceDebugTitle => 'Отладчик источников';

  @override
  String get sourceDebugInputHint =>
      'Введите поисковый запрос или вставьте URL книги/каталога/главы';

  @override
  String get sourceDebugRun => 'Запустить';

  @override
  String get sourceDebugStop => 'Остановить';

  @override
  String get sourceDebugClear => 'Очистить журнал';

  @override
  String get sourceDebugEmpty =>
      'Введите запрос или URL и нажмите «Запустить», чтобы увидеть каждый шаг обработки источником.';

  @override
  String get sourceDebugCopy => 'Копировать';

  @override
  String get sourceDebugCopied => 'Скопировано в буфер обмена';

  @override
  String get sourceHealthMenuLabel => 'Проверить работоспособность';

  @override
  String get sourceHealthHealthy => 'Исправен';

  @override
  String get sourceHealthPartial => 'Частично неисправен';

  @override
  String get bookSourcesFullyAvailable => 'Полностью доступен';

  @override
  String get sourceHealthTimedOut => 'Время проверки истекло';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Не работает: $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'поиск';

  @override
  String get sourceHealthCapabilityDiscover => 'обзор';

  @override
  String get sourceHealthCapabilityInfo => 'сведения о книге';

  @override
  String get sourceHealthCapabilityCatalog => 'каталог';

  @override
  String get sourceHealthCapabilityContent => 'содержимое';

  @override
  String get sourceVerificationTitle => 'Проверка источника';

  @override
  String get sourceVerificationBrowserHint =>
      'Пройдите проверку сайта в защищённом браузере, затем выберите «Проверка завершена». Адрес страницы и cookies возвращаются только в эту задачу источника.';

  @override
  String get sourceVerificationCodeHint =>
      'Прочитайте изображение и введите код, чтобы продолжить задачу источника.';

  @override
  String get sourceVerificationCodeLabel => 'Код с изображения';

  @override
  String get sourceVerificationSubmit => 'Продолжить';

  @override
  String get sourceVerificationRetry => 'Открыть браузер снова';

  @override
  String get sourceVerificationCancel => 'Отменить проверку';

  @override
  String sourceVerificationFailed(String details) {
    return 'Не удалось открыть проверку источника: $details';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get statistics => 'Статистика';

  @override
  String get reading => 'Чтение';

  @override
  String get importBooks => 'Импорт книг';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get lightMode => 'Светлая тема';

  @override
  String get systemMode => 'Системная';

  @override
  String get theme => 'Тема';

  @override
  String get accent => 'Акцентный цвет';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get notes => 'Заметки';

  @override
  String get highlights => 'Выделения';

  @override
  String get ttsReading => 'Озвучивание текста';

  @override
  String get share => 'Поделиться';

  @override
  String get shareContent => 'Поделиться содержимым';

  @override
  String get shareCurrentPage => 'Поделиться текущей страницей';

  @override
  String get shareSelectedText => 'Поделиться выделенным текстом';

  @override
  String get shareProgress => 'Поделиться прогрессом чтения';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get stop => 'Стоп';

  @override
  String get speed => 'Скорость';

  @override
  String get pitch => 'Высота тона';

  @override
  String get language => 'Язык';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get readingProgress => 'Прогресс чтения';

  @override
  String get totalPages => 'Всего страниц';

  @override
  String get currentPage => 'Текущая страница';

  @override
  String get readingTime => 'Время чтения';

  @override
  String get booksRead => 'Прочитано книг';

  @override
  String get todayReading => 'Чтение сегодня';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get save => 'Сохранить';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Предыдущий';

  @override
  String get search => 'Поиск';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get initializationFailed => 'Не удалось инициализировать';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get appearanceSettings => 'Оформление';

  @override
  String get readingTips => 'Советы по чтению';

  @override
  String get readingFontSettingsMoved => 'Настройки шрифта чтения перенесены';

  @override
  String get readingFontSettingsHint =>
      'Откройте любую книгу, коснитесь центра экрана и настройте размер шрифта, межстрочный и межбуквенный интервалы, поля и шрифт чтения на нижней панели.';

  @override
  String get readingSettings => 'Настройки чтения';

  @override
  String get enableTts => 'Включить TTS';

  @override
  String get enableTtsHint => 'Включить чтение вслух';

  @override
  String get ttsSpeedLabel => 'Скорость';

  @override
  String get ttsSpeedHint => 'Настройка скорости чтения';

  @override
  String get ttsVolumeLabel => 'Громкость';

  @override
  String get ttsVolumeHint => 'Настройка громкости чтения';

  @override
  String get ttsPitchLabel => 'Высота тона';

  @override
  String get ttsPitchHint => 'Настройка высоты тона';

  @override
  String get appSettings => 'Настройки приложения';

  @override
  String get appFont => 'Шрифт приложения';

  @override
  String get appFontDescription =>
      'Применяется к навигации, кнопкам, настройкам и другому тексту интерфейса. Содержимое книг не меняет.';

  @override
  String get readerFont => 'Шрифт чтения';

  @override
  String get readerFontDescription =>
      'Для TXT и онлайн-книг. Для EPUB шрифт настраивается отдельно.';

  @override
  String get readerFontSelectionDescription =>
      'Выберите шрифт для чтения. EPUB предлагает шрифт книги, системный и установленные шрифты.';

  @override
  String get readerFontBookPriorityHint =>
      'Использует встроенный шрифт книги, если он есть; иначе — системный шрифт чтения по умолчанию.';

  @override
  String get readerFontOverrideHint => 'Заменяет шрифты, встроенные издателем.';

  @override
  String get fontBookEmbedded => 'Встроенный в книгу';

  @override
  String get fontSystem => 'Как в системе';

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
      'Оптимизированный для платформы шрифт чтения со стабильными глифами и разбивкой на страницы.';

  @override
  String get fontSerifDescription =>
      'Шрифт с засечками со спокойным редакционным характером для длительного чтения.';

  @override
  String get fontSansSerifDescription =>
      'Чёткий шрифт без засечек для компактных интерфейсов и повседневного чтения.';

  @override
  String get fontMonospaceDescription =>
      'Моноширинный шрифт для кода, технических текстов и строгой вёрстки.';

  @override
  String get fontPreviewText => 'Origo X · Read freely 开卷有益';

  @override
  String get customFonts => 'Мои шрифты';

  @override
  String get customFontsEmpty => 'Своих шрифтов пока нет';

  @override
  String get customFontsEmptyHint =>
      'Один раз импортируйте файл TTF или OTF и используйте его для интерфейса или чтения.';

  @override
  String customFontsCount(int count) {
    return 'Импортировано шрифтов: $count';
  }

  @override
  String get customFontsLocalOnly =>
      'Импортированные шрифты хранятся только на этом устройстве и автоматически не синхронизируются.';

  @override
  String get builtInFonts => 'Встроенные шрифты';

  @override
  String get onlineFonts => 'Онлайн-шрифты';

  @override
  String get fontDownload => 'Скачать';

  @override
  String get fontDownloading => 'Скачивание…';

  @override
  String get fontDownloaded => 'Скачано';

  @override
  String get fontDownloadFailed =>
      'Не удалось скачать, коснитесь, чтобы повторить';

  @override
  String get fontDownloadHint =>
      'Первое использование требует скачивания из сети';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Настраиваемая насыщенность $min–$max';
  }

  @override
  String get fontStaticWeight =>
      'Фиксированная насыщенность (жирное начертание синтезируется)';

  @override
  String get fontDeleteDownload => 'Удалить загрузку';

  @override
  String fontDeleteDownloadTitle(String name) {
    return 'Удалить загруженный шрифт «$name»?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Освободит $size памяти. При следующем использовании шрифт скачается заново.';
  }

  @override
  String get fontDownloadCancelled => 'Загрузка отменена';

  @override
  String get fontDownloadNetworkFailed => 'Сетевая ошибка, загрузка не удалась';

  @override
  String get fontDownloadInvalid => 'Скачанный файл шрифта недействителен';

  @override
  String get fontDownloadUnsupported =>
      'Скачивание онлайн-шрифтов не поддерживается на этой платформе';

  @override
  String get importFont => 'Импортировать шрифт';

  @override
  String get importingFont => 'Импорт шрифта…';

  @override
  String get customFontImported => 'Шрифт импортирован';

  @override
  String get customFontAlreadyImported =>
      'Этот шрифт уже импортирован и готов к использованию';

  @override
  String get customFontApplied => 'Выбор шрифта обновлён';

  @override
  String get customFontAppliedToApp =>
      'Импортирован и установлен как шрифт приложения';

  @override
  String get customFontAppliedToReader =>
      'Импортирован и установлен как шрифт чтения';

  @override
  String get customFontImportUnsupported =>
      'Постоянный импорт шрифтов пока не поддерживается на этой платформе.';

  @override
  String get customFontUnsupportedFormat => 'Выберите файл шрифта TTF или OTF.';

  @override
  String get customFontInvalid =>
      'Этот файл не является допустимым или поддерживаемым шрифтом.';

  @override
  String get customFontTooLarge => 'Файл шрифта больше 50 МБ.';

  @override
  String get customFontReadFailed => 'Не удалось прочитать файл шрифта.';

  @override
  String get customFontLoadFailed => 'Не удалось загрузить шрифт.';

  @override
  String get customFontStorageFailed =>
      'Не удалось сохранить шрифт на этом устройстве.';

  @override
  String get customFontUnavailable =>
      'Файл шрифта недоступен. Удалите его и импортируйте заново.';

  @override
  String get setAsAppFont => 'Использовать как шрифт приложения';

  @override
  String get setAsReaderFont => 'Использовать как шрифт чтения';

  @override
  String get setAsBothFonts => 'Использовать для обоих';

  @override
  String get renameFont => 'Переименовать шрифт';

  @override
  String deleteCustomFontTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get deleteCustomFontMessage =>
      'Файл шрифта будет удалён с этого устройства.';

  @override
  String get deleteCustomFontInUse =>
      'Этот шрифт сейчас используется. После удаления затронутые настройки шрифта вернутся к значениям по умолчанию.';

  @override
  String get deleteAndReset => 'Удалить и сбросить';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Официальный канал в Telegram';

  @override
  String get settingsTelegramOpenFailed => 'Не удалось открыть ссылку Telegram';

  @override
  String get settingsQqChannel => 'QQ Channel';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'Не удалось открыть ссылку-приглашение QQ Channel';

  @override
  String get languageSystem => 'Как в системе';

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
  String get typographySettings => 'Типографика';

  @override
  String get fontFamilyLabel => 'Шрифт';

  @override
  String get fontSizeLabel => 'Размер шрифта';

  @override
  String get readerFontWeightLabel => 'Насыщенность шрифта';

  @override
  String get readerFontWeightLight => 'Светлый';

  @override
  String get readerFontWeightRegular => 'Обычный';

  @override
  String get readerFontWeightMedium => 'Средний';

  @override
  String get readerFontWeightSemiBold => 'Полужирный';

  @override
  String get readerFontWeightBold => 'Жирный';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'Настройки чтения используют пять различимых ступеней от 300 до 700. Полный диапазон этого шрифта — $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'Настройки чтения используют пять ступеней от 300 до 700. У этого шрифта нет объявленной оси насыщенности, поэтому система подбирает начертание приблизительно; результат может отличаться на разных платформах.';

  @override
  String get readerFontWeightPreview => 'Тихая страница читается легче · 字里行间';

  @override
  String get lineSpacingLabel => 'Межстрочный интервал';

  @override
  String get letterSpacingLabel => 'Межбуквенный интервал';

  @override
  String get textAlignmentLabel => 'Выравнивание текста';

  @override
  String get textAlignmentNatural => 'Естественное';

  @override
  String get textAlignmentJustified => 'По ширине';

  @override
  String get firstLineIndentLabel => 'Отступ первой строки';

  @override
  String get paragraphSpacingLabel => 'Интервал между абзацами';

  @override
  String get pageMarginLabel => 'Поля страницы';

  @override
  String get resetDefault => 'Сбросить';

  @override
  String get ttsPanelTitle => 'Озвучивание текста';

  @override
  String get ttsPreviewEffect => 'Предпросмотр эффекта';

  @override
  String get ttsVolume => 'Громкость';

  @override
  String get ttsPitch => 'Высота тона';

  @override
  String get ttsSpeed => 'Скорость';

  @override
  String get ttsPreviousSentence => 'Предыдущее предложение';

  @override
  String get ttsNextSentence => 'Следующее предложение';

  @override
  String get ttsTimerStop => 'Таймер остановки';

  @override
  String get ttsTimerOff => 'Без ограничения';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes мин';
  }

  @override
  String get ttsPlaying => 'Воспроизведение';

  @override
  String get ttsPaused => 'Пауза';

  @override
  String get ttsStopped => 'Остановлено';

  @override
  String get ttsPreviousSentenceFailed =>
      'Не удалось воспроизвести предыдущее предложение';

  @override
  String get ttsNextSentenceFailed =>
      'Не удалось воспроизвести следующее предложение';

  @override
  String get ttsEmptyContentError => 'Содержимое текущей страницы пусто';

  @override
  String get ttsPlaybackFailed => 'Не удалось воспроизвести';

  @override
  String get ttsOperationFailed => 'Не удалось выполнить операцию';

  @override
  String get pageTurningMode => 'Режим страниц';

  @override
  String get pageTurningSlide => 'Горизонтальное перелистывание';

  @override
  String get pageTurningScroll => 'Вертикальная прокрутка';

  @override
  String get tapZoneSettings => 'Зоны нажатия';

  @override
  String get tapZoneNextPage => 'Следующая страница';

  @override
  String get tapZonePreviousPage => 'Предыдущая страница';

  @override
  String get tapZoneMenu => 'Меню';

  @override
  String get tapZoneLegend => 'Обозначения';

  @override
  String get tapZoneNextChapter => 'Следующая глава';

  @override
  String get tapZonePreviousChapter => 'Предыдущая глава';

  @override
  String get tapZoneNone => 'Без действия';

  @override
  String get tapZoneSettingsHint =>
      'Настройте действие для каждой из девяти зон нажатия';

  @override
  String get tapZoneChooseAction => 'Выберите действие';

  @override
  String get tapZoneMenuRequiredHint =>
      'Коснитесь зоны, чтобы изменить её действие. Хотя бы одна зона должна оставаться «Меню»; если убрать все зоны «Меню», центральная зона снова станет «Меню».';

  @override
  String get tapZoneReset => 'Восстановить по умолчанию';

  @override
  String get highlightColor => 'Цвет выделения';

  @override
  String get highlightPreview => 'Предпросмотр';

  @override
  String get highlightSampleText => 'Это пример текста,';

  @override
  String get highlightSampleText2 => 'эта часть будет выделена,';

  @override
  String get highlightSampleText3 => 'демонстрируя эффект выделения.';

  @override
  String get colorLightBlue => 'Голубой';

  @override
  String get colorRed => 'Красный';

  @override
  String get colorGreen => 'Зелёный';

  @override
  String get colorPurple => 'Фиолетовый';

  @override
  String get colorGold => 'Золотой';

  @override
  String get colorOrange => 'Оранжевый';

  @override
  String get colorYellow => 'Жёлтый';

  @override
  String get colorDarkGreen => 'Тёмно-зелёный';

  @override
  String get colorCustom => 'Свой цвет';

  @override
  String get noteTypeHighlight => 'Выделение';

  @override
  String get noteTypeUnderline => 'Подчёркивание';

  @override
  String get noteTypeNote => 'Заметка';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Импортировать книгу';

  @override
  String get importFromFiles => 'Импорт из файлов';

  @override
  String get importNoBooks => 'Книги пока не импортированы';

  @override
  String get importSuccess => 'Книга успешно импортирована';

  @override
  String get importFailed => 'Не удалось импортировать';

  @override
  String get importProcessing => 'Обработка книги...';

  @override
  String get author => 'Автор';

  @override
  String get progress => 'Прогресс';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String get recentBooks => 'Недавние книги';

  @override
  String get allBooks => 'Все книги';

  @override
  String get emptyLibrary => 'Библиотека пуста';

  @override
  String get deleteBook => 'Удалить книгу';

  @override
  String get deleteBookConfirm => 'Вы уверены, что хотите удалить эту книгу?';

  @override
  String get bookDeleted => 'Книга удалена';

  @override
  String get userAgreement => 'Пользовательское соглашение';

  @override
  String get acceptAgreement => 'Я прочитал(а) и согласен(а)';

  @override
  String get declineAgreement => 'Отклонить';

  @override
  String get statsToday => 'Сегодня';

  @override
  String get statsThisWeek => 'На этой неделе';

  @override
  String get statsTotal => 'Всего';

  @override
  String statsMinutes(Object minutes) {
    return '$minutes мин';
  }

  @override
  String statsHours(Object hours) {
    return '$hours ч';
  }

  @override
  String statsBooks(Object count) {
    return 'Книг: $count';
  }

  @override
  String get statsConsecutiveDays => 'Дни подряд';

  @override
  String get statsFocusTime => 'Время фокуса';

  @override
  String get statsThisWeekTotal => 'Итого за неделю';

  @override
  String get statsKeepReading => 'Читайте каждый день';

  @override
  String get statsMaxSession => 'Самая долгая сессия';

  @override
  String get statsWeeklyTrend => 'Недельный тренд';

  @override
  String get statsAchievements => 'Достижения';

  @override
  String get readerToolbarMenu => 'Меню';

  @override
  String get readerToolbarTOC => 'Оглавление';

  @override
  String get readerToolbarSettings => 'Настройки';

  @override
  String get readerAddBookmark => 'Добавить закладку';

  @override
  String get readerAddNote => 'Добавить заметку';

  @override
  String get readerShare => 'Поделиться';

  @override
  String get bookmarkAdded => 'Закладка добавлена';

  @override
  String get bookmarkRemoved => 'Закладка удалена';

  @override
  String get readerNavigationTitle => 'Навигация по чтению';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Глава $current из $total';
  }

  @override
  String get readerSearchChapters => 'Поиск по главам';

  @override
  String get readerBackToCurrentChapter => 'Вернуться к текущей главе';

  @override
  String get readerCurrentChapter => 'Текущая';

  @override
  String get readerCurrentPosition => 'Текущая позиция';

  @override
  String get readerNoChapterResults => 'Подходящих глав нет';

  @override
  String get readerNoChapterResultsHint =>
      'Попробуйте другое слово из названия главы.';

  @override
  String get readerNoBookmarks => 'Закладок пока нет';

  @override
  String get readerNoBookmarksHint =>
      'Коснитесь кнопки закладки в правом верхнем углу, чтобы сохранить место.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Прежде чем сохранять закладки, добавьте книгу на полку';

  @override
  String get themeBlue => 'Океанский синий';

  @override
  String get themeGreen => 'Лесной зелёный';

  @override
  String get themeOrange => 'Яркий оранжевый';

  @override
  String get themeRed => 'Пылкий красный';

  @override
  String get themeCustom => 'Свой';

  @override
  String get tapZoneLeftRight => 'Слева/справа';

  @override
  String get tapZoneLeftCenterRight => 'Слева/центр/справа';

  @override
  String get homeTagline => 'Читайте красиво';

  @override
  String get homeReadingStatsTitle => 'Статистика чтения';

  @override
  String get homeTodayReadingMoment => 'Момент чтения сегодня';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return 'Прочитано $minutes мин — так держать';
  }

  @override
  String get homeTodayReadingJourneyStart =>
      'Начните свой путь читателя сегодня';

  @override
  String get homeTodayReadingKeepRhythm => 'Сегодня вы в графике, держите ритм';

  @override
  String get homeTodayReadingPrompt => 'Найдите сегодня время для чтения';

  @override
  String homeTotalReadingHours(String hours) {
    return 'Всего чтения: $hours ч';
  }

  @override
  String get homeWeeklyReading => 'На этой неделе';

  @override
  String get homeTotalReading => 'Общее время чтения';

  @override
  String get homeLibraryCount => 'Книг в библиотеке';

  @override
  String get homeCollectionCount => 'Коллекция';

  @override
  String get homeKeyMetrics => 'Ключевые показатели';

  @override
  String get homeReadingRhythm => 'Ритм чтения';

  @override
  String get homeAchievements => 'Достижения в чтении';

  @override
  String get homeConsecutiveReading => 'Чтение без пропусков';

  @override
  String get homeConsecutiveReadingDesc =>
      'Сохраняйте ежедневную привычку читать';

  @override
  String get homeFocusDuration => 'Длительность фокуса';

  @override
  String get homeFocusDurationDesc => 'Самая долгая сессия чтения';

  @override
  String get homeWeeklyTotal => 'Итого за неделю';

  @override
  String get homeWeeklyTotalDesc => 'Время чтения за неделю';

  @override
  String get homeRecentReading => 'Недавнее чтение';

  @override
  String get homeWeeklyTrend => 'Недельный тренд чтения';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get unitMinute => 'мин';

  @override
  String get unitHour => 'ч';

  @override
  String get unitBook => 'книг';

  @override
  String get unitDay => 'дн.';

  @override
  String get weekdayMonShort => 'Пн';

  @override
  String get weekdayTueShort => 'Вт';

  @override
  String get weekdayWedShort => 'Ср';

  @override
  String get weekdayThuShort => 'Чт';

  @override
  String get weekdayFriShort => 'Пт';

  @override
  String get weekdaySatShort => 'Сб';

  @override
  String get weekdaySunShort => 'Вс';

  @override
  String get agreementTagline =>
      'Погружающее чтение · AI-ассистент · Локальные данные';

  @override
  String get agreementCardTitle => 'Соглашение об использовании сервиса';

  @override
  String get agreementCardSubtitle => 'Внимательно прочитайте следующее';

  @override
  String get agreementWelcomeTitle => 'Добро пожаловать в Origo X';

  @override
  String get agreementWelcomeBody =>
      'Чтобы чтение было стабильным и предсказуемым, сначала прочитайте и примите следующее соглашение.';

  @override
  String get agreementFeatureFormatsTitle => 'Поддержка многих форматов';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI и другие';

  @override
  String get agreementFeatureCustomizationTitle => 'Персональное чтение';

  @override
  String get agreementFeatureCustomizationBody =>
      'Настраивайте шрифты, цвета, типографику и не только';

  @override
  String get agreementFeatureSyncTitle => 'Локальные данные';

  @override
  String get agreementFeatureSyncBody =>
      'Книги, прогресс и заметки остаются на устройстве под вашим контролем';

  @override
  String get agreementFeatureTtsTitle => 'Озвучивание текста';

  @override
  String get agreementFeatureTtsBody =>
      'Умное озвучивание освобождает глаза — слушайте где угодно';

  @override
  String get agreementTapToAgreeHint =>
      'Нажимая «Согласиться и продолжить», вы подтверждаете, что прочитали условия и согласны использовать это приложение';

  @override
  String get agreementExitApp => 'Выйти из приложения';

  @override
  String get agreementAgreeAndContinue => 'Согласиться и продолжить';

  @override
  String get agreementExitDialogContent =>
      'Если вы не примете пользовательское соглашение, вы не сможете пользоваться приложением. Вы уверены, что хотите выйти?';

  @override
  String get agreementConfirmExit => 'Выйти';

  @override
  String get readerFileMissing =>
      'Файл книги не найден. Импортируйте его заново.';

  @override
  String get readerUnsupportedFormat =>
      'Этот формат пока не поддерживается для чтения.';

  @override
  String get readerKindleDrmProtected =>
      'Эта книга Kindle защищена DRM и не может быть прочитана здесь. Поддерживаются только книги без DRM.';

  @override
  String get readerComicNoPages =>
      'В этом архиве комикса не найдено страниц с изображениями.';

  @override
  String get readerComicCbrUnsupported =>
      'Этот комикс CBR использует настоящее сжатие RAR и пока не читается. Преобразуйте его в CBZ.';

  @override
  String get readerComicArchiveUnsupported =>
      'Формат архива этого комикса пока не читается. Преобразуйте его в CBZ.';

  @override
  String get readerComicChapterNoPages =>
      'В этой главе нет страниц с изображениями.';

  @override
  String get imageReaderSettings => 'Настройки чтения';

  @override
  String get imageReaderDirectionTitle => 'Направление чтения';

  @override
  String get imageReaderDirectionVertical => 'Непрерывно вниз';

  @override
  String get imageReaderDirectionLtr => 'Слева направо';

  @override
  String get imageReaderDirectionRtl => 'Справа налево (манга)';

  @override
  String get imageReaderJumpToPage => 'Перейти к странице';

  @override
  String get imageReaderBackgroundTitle => 'Фон страницы';

  @override
  String get imageReaderBackgroundBlack => 'Чёрный';

  @override
  String get imageReaderBackgroundGray => 'Серый';

  @override
  String get imageReaderBackgroundWhite => 'Белый';

  @override
  String get readerPdfLinuxUnsupported =>
      'Чтение PDF пока недоступно на Linux.';

  @override
  String get bootstrapImageManagerFailed =>
      'Не удалось инициализировать менеджер изображений';

  @override
  String homeFocusCompleted(int minutes) {
    return '$minutes-минутная сессия фокуса завершена. Отлично!';
  }

  @override
  String get homeDailyReadingGoal => 'Дневная цель чтения';

  @override
  String get homeAiAdviceSection => 'AI-советы по чтению';

  @override
  String get homeTodayGlance => 'Сегодня вкратце';

  @override
  String get homeViewAll => 'Смотреть все';

  @override
  String get homeGoalDoneSuggestReview =>
      'Цель на сегодня достигнута — возможно, стоит подвести итоги чтения';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Ещё $minutes мин до цели на сегодня';
  }

  @override
  String get homePickBookHint =>
      'Сначала выберите книгу с полки, чтобы продолжить, и завершите 1 сессию фокуса.';

  @override
  String homeContinueBookHint(String title) {
    return 'Сначала продолжите «$title», затем переходите к другим книгам.';
  }

  @override
  String get homeTodayActionAdvice => 'План на сегодня';

  @override
  String homeProgressPercent(int percent) {
    return 'Прогресс: $percent%';
  }

  @override
  String homeStreakDays(int days) {
    return 'Серия: $days дн.';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes мин за неделю';
  }

  @override
  String get homePlanLoading => 'План загружается';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Цель: $minutes мин/день';
  }

  @override
  String get homeAiAdviceForYou => 'AI-советы по чтению для вас';

  @override
  String homeBasedOnBook(String title) {
    return 'На основе книги «$title»';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Чтение сегодня (мин)';

  @override
  String get homeTotalReadingMinutesLabel => 'Всего чтения (мин)';

  @override
  String get homeGeneratingPlan => 'Составление плана чтения на сегодня...';

  @override
  String get homeCompletedLabel => 'Готово';

  @override
  String get homeTodayGoalAchieved => 'Цель на сегодня достигнута';

  @override
  String homeMinutesRemaining(int minutes) {
    return 'Осталось: $minutes мин';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return 'Прочитано $read / $goal мин';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'До цели на сегодня примерно $sessions сессий фокуса';
  }

  @override
  String get homeStreakLabel => 'Серия';

  @override
  String get homeWeekAchievedLabel => 'Недельная цель';

  @override
  String get homeFocusLabel => 'Фокус';

  @override
  String homeDaysCount(int days) {
    return 'Дней: $days';
  }

  @override
  String homeTimesCount(int times) {
    return 'Раз: $times';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Обратный отсчёт фокуса $time';
  }

  @override
  String get homeGoLibraryRead => 'Читать из библиотеки';

  @override
  String get homeEndFocus => 'Завершить фокус';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Фокус $minutes мин';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Изменить цель: $minutes мин';
  }

  @override
  String get homeNoRecentReading =>
      'Недавнего чтения пока нет. Откройте книгу из библиотеки, чтобы начать.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Прогресс $percent%';
  }

  @override
  String get librarySearchHint => 'Поиск по названию или автору';

  @override
  String libraryFilterAll(int count) {
    return 'Все ($count)';
  }

  @override
  String libraryFilterReading(int count) {
    return 'Читаются ($count)';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Прочитано ($count)';
  }

  @override
  String get libraryFilterTooltip => 'Фильтр по статусу чтения';

  @override
  String get libraryNoMatchingBooks => 'Подходящих книг нет';

  @override
  String get libraryNoReadingBooks => 'Нет читаемых книг';

  @override
  String get libraryNoFinishedBooks => 'Нет прочитанных книг';

  @override
  String get libraryNoBooks => 'Книг пока нет';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · продолжить чтение';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Страница $page';
  }

  @override
  String get libraryStartFromBeginning => 'Начать с начала';

  @override
  String get libraryBookInfo => 'О книге';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · страниц: $pages';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · глав: $chapters';
  }

  @override
  String get libraryRenameBook => 'Переименовать';

  @override
  String get libraryRenameBookHint =>
      'Изменение названия; файл на диске также переименовывается';

  @override
  String get libraryRenameBookSuccess => 'Переименовано';

  @override
  String get libraryRenameBookFailed => 'Не удалось переименовать книгу';

  @override
  String get libraryCustomCover => 'Своя обложка';

  @override
  String get libraryCustomCoverHint =>
      'Выберите изображение для обложки этой книги';

  @override
  String get libraryCustomCoverSuccess => 'Обложка обновлена';

  @override
  String get libraryCoverUnsupportedFormat =>
      'Неподдерживаемый формат изображения';

  @override
  String get libraryCoverFileTooLarge => 'Изображение превышает лимит в 20 МБ';

  @override
  String get libraryCoverReadFailed =>
      'Не удалось прочитать выбранное изображение';

  @override
  String get libraryCoverSaveFailed => 'Не удалось сохранить обложку';

  @override
  String get libraryResetCover => 'Восстановить стандартную обложку';

  @override
  String get libraryResetCoverHint => 'Убрать свою обложку и вернуть исходную';

  @override
  String get libraryResetCoverSuccess => 'Стандартная обложка восстановлена';

  @override
  String get libraryExportBook => 'Экспортировать файл книги';

  @override
  String get libraryExportOriginalHint =>
      'Копирование исходного файла в другое место';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Экспорт скачанной книги в виде созданного TXT-файла';

  @override
  String bookExportSuccess(String location) {
    return 'Экспортировано в $location';
  }

  @override
  String get bookExportSourceMissing =>
      'Файл книги отсутствует и не может быть экспортирован';

  @override
  String get bookExportUnsupported =>
      'Экспорт книг пока не поддерживается на этой платформе';

  @override
  String get bookExportFailed => 'Не удалось экспортировать книгу';

  @override
  String get bookExportInProgress => 'Экспорт книги…';

  @override
  String get incomingBooksImporting => 'Импорт книги из другого приложения…';

  @override
  String get incomingBooksNoBookFile =>
      'В переданном содержимом нет файла книги, который можно импортировать';

  @override
  String get incomingBooksPermissionExpired =>
      'Срок доступа к файлу истёк. Поделитесь файлом или откройте его снова';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Этот формат книг не поддерживается';

  @override
  String get incomingBooksFileTooLarge =>
      'Файл превышает лимит импорта в 500 МБ';

  @override
  String get incomingBooksTooManyFiles =>
      'Передано слишком много файлов книг за раз. Добавляйте их меньшими партиями';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Некоторые файлы распознать не удалось; остальные книги будут обработаны';

  @override
  String get incomingBooksContentMismatch =>
      'Формат файла не соответствует его содержимому';

  @override
  String get incomingBooksImportFailed =>
      'Не удалось импортировать книгу из другого приложения';

  @override
  String get libraryDeleteBookHint => 'Эта книга будет удалена навсегда';

  @override
  String get libraryBookTitle => 'Название';

  @override
  String get libraryFormat => 'Формат';

  @override
  String libraryPagesCount(int pages) {
    return 'Страниц: $pages';
  }

  @override
  String get totalChapters => 'Всего глав';

  @override
  String get currentChapter => 'Текущая глава';

  @override
  String libraryChaptersCount(int chapters) {
    return 'Глав: $chapters';
  }

  @override
  String get libraryClose => 'Закрыть';

  @override
  String get libraryConfirmDeleteTitle => 'Подтверждение удаления';

  @override
  String libraryDeleteBookMessage(String title) {
    return 'Удалить «$title»? Файл будет навсегда удалён с вашего устройства.';
  }

  @override
  String libraryDeletingBook(String title) {
    return 'Удаление «$title»...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '«$title» удалена';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get libraryReadingBadge => 'Читается';

  @override
  String get libraryDeletingBookFile => 'Удаление файла книги...';

  @override
  String get libraryDeletingCoverImage => 'Удаление изображения обложки...';

  @override
  String get libraryCleaningDatabase => 'Очистка записей базы данных...';

  @override
  String get libraryDeleteComplete => 'Удаление завершено';

  @override
  String get librarySelectMultiple => 'Выбрать несколько';

  @override
  String get librarySelectAll => 'Выбрать все';

  @override
  String librarySelectedBooks(int count) {
    return 'Выбрано: $count';
  }

  @override
  String libraryDeleteSelected(int count) {
    return 'Удалить: $count';
  }

  @override
  String get libraryBatchDeleteTitle => 'Удалить выбранные книги?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Выбранные книги ($count), связанные заметки и закладки, а также локальные файлы будут удалены навсегда. Это действие нельзя отменить.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return 'Удаление $done/$total';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return 'Удалено книг: $count';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return 'Удалено: $success; с ошибкой: $failed';
  }

  @override
  String get readerPrefaceTitle => 'Вступление';

  @override
  String get readerModeHorizontalPage => 'Без анимации';

  @override
  String get readerModeVerticalScrollHint =>
      'Листайте готовые страницы по вертикали; смахивайте в сторону для смены главы';

  @override
  String get readerModeWholeBookScrollHint =>
      'Готовые главы образуют один прокручиваемый вертикальный список';

  @override
  String get readerScrollByChapterTitle => 'Прокрутка по главам';

  @override
  String get readerScrollByChapterOnHint =>
      'Листайте одну главу по страницам, затем смахивайте в сторону для смены главы';

  @override
  String get readerScrollByChapterOffHint =>
      'Все главы соединяются постранично в один прокручиваемый вертикальный список';

  @override
  String get readerModeHorizontalPageHint =>
      'Касание слева — предыдущая страница, справа — следующая';

  @override
  String get readerModeHorizontalSlideHint =>
      'Страницы следуют за пальцем по горизонтали и фиксируются на месте';

  @override
  String get readerModeCoverSlide => 'Сдвиг листа';

  @override
  String get readerModeCoverSlideHint =>
      'Текущая страница уезжает влево, открывая следующую под ней';

  @override
  String get readerModePageCurl => 'Загиб страницы';

  @override
  String get readerModePageCurlHint =>
      'Потяните в сторону, чтобы загнуть страницу, затем отпустите для перелистывания или возврата';

  @override
  String get readerTextBrightnessLabel => 'Яркость текста';

  @override
  String get readerDimTextInDarkModeTitle => 'Приглушать текст в тёмной теме';

  @override
  String get readerDimTextInDarkModeHint =>
      'Использовать 70% яркости в тёмной теме';

  @override
  String readerFontSizeValue(int size) {
    return 'Размер шрифта  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Горизонтальные поля  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Горизонтальные поля';

  @override
  String get readerTopMarginLabel => 'Верхнее поле';

  @override
  String get readerBottomMarginLabel => 'Нижнее поле';

  @override
  String get readerTxtChapterTitlePageTitle =>
      'Название главы на отдельной странице';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Если выключено, название главы отображается над основным текстом';

  @override
  String get readerVerticalMarginLabel => 'Вертикальные поля';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Вертикальные поля  $margin';
  }

  @override
  String readerChapterCount(int count) {
    return 'Глав: $count';
  }

  @override
  String readerChapterFallback(int number) {
    return 'Глава $number';
  }

  @override
  String readerOpenFailed(String error) {
    return 'Не удалось открыть: $error';
  }

  @override
  String get readerNoContent => 'В этой книге нет читаемого содержимого';

  @override
  String readerStatusPaged(
    int chapter,
    int chapterCount,
    int page,
    int pageCount,
  ) {
    return 'Глава $chapter/$chapterCount · Страница $page/$pageCount';
  }

  @override
  String readerStatusScroll(int chapter, int chapterCount) {
    return 'Глава $chapter/$chapterCount · вертикальная прокрутка';
  }

  @override
  String get importPreparing => 'Подготовка импорта...';

  @override
  String importFailedWithError(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String get importLocalFile => 'Локальные файлы';

  @override
  String get settingsAiTempHintMinimax =>
      'Температура: MiniMax рекомендует 0.01 ~ 1.00';

  @override
  String get settingsAiCustomConfigTitle => 'Пользовательская настройка AI';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Текущий поставщик: $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'Температура MiniMax должна быть от 0.01 до 1.00';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'Температура вне допустимого диапазона, следуйте подсказке';

  @override
  String get settingsApply => 'Применить';

  @override
  String get settingsAiCustomApplied =>
      'Пользовательские параметры применены, не забудьте сохранить конфигурацию';

  @override
  String get settingsAiApiKeyRequired => 'API Key не может быть пустым';

  @override
  String get settingsAiModelRequired => 'Модель не может быть пустой';

  @override
  String get settingsAiBaseUrlInvalid =>
      'Base URL должен быть корректным адресом http/https';

  @override
  String get settingsAiSettingsSaved => 'Настройки AI сохранены';

  @override
  String settingsSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle => 'Перелистывание кнопками громкости';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Использовать кнопки громкости в постраничных режимах чтения';

  @override
  String get settingsAutoResumeReadingTitle => 'Продолжать чтение при запуске';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Если вы вышли из приложения во время чтения, следующий запуск вернёт вас к месту остановки';

  @override
  String get settingsShowStatusBarTitle =>
      'Показывать системную строку состояния при чтении';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Индикатор батареи и времени читалки скрыт';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Используется индикатор батареи и времени читалки';

  @override
  String get readerTopBarStyleTitle => 'Верхняя информация';

  @override
  String get readerTopBarStyleSystem => 'Системная строка состояния';

  @override
  String get readerTopBarStyleSystemHint =>
      'Показывать системное время, сигнал и батарею';

  @override
  String get readerTopBarStyleReader => 'Информационная панель читалки';

  @override
  String get readerTopBarStyleReaderHint =>
      'Показывать время, название главы и батарею';

  @override
  String get readerTopBarStyleFloating => 'Плавающая информационная панель';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Показывать время и батарею в области строки состояния, не занимая места для чтения';

  @override
  String get readerTopBarStyleHidden => 'Полное погружение';

  @override
  String get readerTopBarStyleHiddenHint =>
      'Не показывать никакой информации сверху';

  @override
  String get settingsAiAssistantTitle => 'AI-помощник чтения';

  @override
  String get settingsSystemSettingsTitle => 'Системные настройки';

  @override
  String get settingsSectionAppearanceFonts => 'Оформление и шрифты';

  @override
  String get settingsSectionDataServices => 'Данные и сервисы';

  @override
  String get settingsSectionGeneral => 'Общие';

  @override
  String get settingsSectionAdvancedFeatures => 'Продвинутые функции';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Другие протоколы источников';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Включите поддержку дополнительных протоколов источников.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Разрешить источники в частных сетях';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Разрешить источникам доступ к этому устройству, локальной сети и другим частным адресам. С Premium включено по умолчанию; используйте только доверенные источники.';

  @override
  String get additionalSourcesImport => 'Импорт других протоколов источников';

  @override
  String get additionalSourcesImportTitle => 'Импорт JSON источника';

  @override
  String get additionalSourcesImportNotice =>
      'Импорт только разбирает и дедуплицирует данные локально; онлайн-проверка каждого источника не выполняется. Источники с вызываемыми правилами сохраняют состояние «включён» после импорта, каждая возможность проверяется при использовании.';

  @override
  String get additionalSourcesChooseFile => 'Добавить из JSON-файла';

  @override
  String get additionalSourcesUrlLabel => 'URL JSON источника';

  @override
  String get additionalSourcesLoadUrl => 'Загрузить по URL';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return 'Доступных: $supported, частично поддерживаемых: $partial, не поддерживаемых: $unsupported';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return 'Стандартных правил: $supported, расширенных: $partial, продвинутых: $unsupported, пропущено: $skipped';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return 'Готово к импорту источников: $count, пропущено: $skipped';
  }

  @override
  String get additionalSourcesAvailable => 'Доступен';

  @override
  String get additionalSourcesPartial => 'Частично поддерживается';

  @override
  String get additionalSourcesUnsupported => 'Не поддерживается';

  @override
  String get additionalSourcesImportConfirm => 'Импортировать все';

  @override
  String additionalSourcesImported(int count) {
    return 'Импортировано источников: $count';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return 'Импортировано источников: $count; пропущено $conflicted, чей id уже зарегистрирован из другого источника';
  }

  @override
  String get settingsSectionAboutSupport => 'О приложении и поддержка';

  @override
  String get settingsKeepScreenOnTitle => 'Не выключать экран';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Не давать экрану гаснуть во время чтения';

  @override
  String get settingsPowerSavingModeTitle => 'Режим экономии энергии';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Ограничить приложение до 60 кадр./с вместо высокой частоты обновления';

  @override
  String get settingsAutoSaveTitle => 'Автосохранение';

  @override
  String get settingsAutoSaveSubtitle =>
      'Автоматически сохранять прогресс чтения';

  @override
  String get settingsHelpPlaceholder =>
      'Здесь может размещаться справочная информация';

  @override
  String get settingsAiConfigured => 'AI настроен';

  @override
  String get settingsAiNotConfigured => 'API Key ещё не настроен';

  @override
  String get settingsAiReadyToUse => 'Готово к использованию';

  @override
  String get settingsAiPendingConfig => 'Требуется настройка';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Текущий пресет: $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Текущая конфигурация: пользовательская · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'Распространённые поставщики и модели встроены; обычно достаточно выбрать пресет и ввести API Key.';

  @override
  String get settingsAiProviderLabel => 'Поставщик';

  @override
  String get settingsAiCustomProvider => 'Пользовательский';

  @override
  String get settingsAiProtocolLabel => 'Протокол API';

  @override
  String get settingsAiProtocolOpenAi => 'Совместимый с OpenAI';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Выберите модель из пресета';

  @override
  String get settingsAiPresetLabel => 'Модель из пресета';

  @override
  String get settingsAiCustomButton => 'Пользовательская';

  @override
  String get settingsAiPresetSelectedHint =>
      'После выбора пресета достаточно ввести API Key, чтобы начать пользоваться.';

  @override
  String get settingsAiCustomActiveHint =>
      'Используются пользовательские параметры; в любой момент можно вернуться к пресету.';

  @override
  String get settingsAiApiKeyHint => 'Введите, чтобы включить текущий пресет';

  @override
  String get settingsShow => 'Показать';

  @override
  String get settingsHide => 'Скрыть';

  @override
  String get settingsAiSaving => 'Сохранение...';

  @override
  String get settingsAiSaveConfig => 'Сохранить конфигурацию AI';

  @override
  String get settingsPageIntro =>
      'Только настройки, которые влияют на ваши впечатления от чтения.';

  @override
  String get settingsSupportDevelopmentTitle => 'Поддержать разработку';

  @override
  String get firstHomeSupportNow => 'Поддержать сейчас';

  @override
  String get firstHomeSupportLater => 'Позже';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Письмо разработчика Origo X с просьбой о добровольной поддержке';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Поддержать разработку';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'Пожертвования добровольны и поддерживают дальнейшую разработку.';

  @override
  String get settingsAccountGuestTitle => 'Войдите в Origo X';

  @override
  String get settingsAccountGuestSubtitle =>
      'Синхронизируйте профиль и настройки безопасности.';

  @override
  String get settingsAccountOpen => 'Центр учётной записи';

  @override
  String get settingsAccountVerified => 'Подтверждённая учётная запись';

  @override
  String get accountPageTitle => 'Учётная запись';

  @override
  String get accountIntroTitle => 'Учётная запись';

  @override
  String get accountPageSubtitle =>
      'Войдите, чтобы синхронизировать профиль и настройки учётной записи.';

  @override
  String get accountLoginTab => 'Вход по email';

  @override
  String get accountRegisterTab => 'Регистрация';

  @override
  String get accountCodeTab => 'Код по email';

  @override
  String get accountResetTab => 'Сброс';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailRequired => 'Введите адрес email';

  @override
  String get accountEmailFirstHint =>
      'Введите email, чтобы продолжить. По умолчанию используется вход по паролю.';

  @override
  String get accountContinue => 'Продолжить';

  @override
  String get accountPasswordLoginTitle => 'Вход по паролю';

  @override
  String get accountPasswordLoginHint =>
      'Введите пароль или используйте код из письма.';

  @override
  String get accountUseEmailCode => 'Войти по коду из письма';

  @override
  String get accountNoAccount => 'Нет учётной записи? Зарегистрируйтесь';

  @override
  String get accountForgotPassword => 'Забыли пароль?';

  @override
  String get accountHaveAccount => 'Уже зарегистрированы? Вернуться ко входу';

  @override
  String get accountBackToPassword => 'Вернуться ко входу по паролю';

  @override
  String get accountChangeEmail => 'Изменить';

  @override
  String get accountRegisterHint =>
      'Подтвердите email, затем создайте учётную запись и пароль.';

  @override
  String get accountCodeLoginHint => 'Мы отправим код на выбранный email.';

  @override
  String get accountResetHint =>
      'Подтвердите email, затем выберите новый пароль.';

  @override
  String get accountPassword => 'Пароль';

  @override
  String get accountConfirmPassword => 'Подтвердите пароль';

  @override
  String get accountAvatarCropTitle => 'Обрезка аватара';

  @override
  String get accountAvatarCropHint =>
      'Перетаскивайте, чтобы переместить, и сжимайте пальцами для масштаба, пока объект не впишется в круг.';

  @override
  String get accountUsername => 'Имя пользователя';

  @override
  String get accountDisplayName => 'Отображаемое имя';

  @override
  String get accountVerificationCode => 'Код подтверждения';

  @override
  String get accountSendCode => 'Отправить код';

  @override
  String get accountSignIn => 'Войти';

  @override
  String get accountCreate => 'Создать учётную запись';

  @override
  String get accountResetPassword => 'Сбросить пароль';

  @override
  String get accountUseApple => 'Войти через Apple';

  @override
  String get accountUseGithub => 'Вход через GitHub';

  @override
  String get accountUseGoogle => 'Продолжить с Google';

  @override
  String get accountUsePasskey => 'Продолжить с Passkey';

  @override
  String get accountMoreSignInMethods => 'Другие способы входа';

  @override
  String get accountExternalHint =>
      'Откроется защищённый браузер. Вернитесь сюда после подтверждения.';

  @override
  String get accountProfileTitle => 'Профиль';

  @override
  String get accountEditProfile => 'Изменить профиль';

  @override
  String get accountSignInMethodsTitle => 'Способы входа';

  @override
  String get accountSaveProfile => 'Сохранить профиль';

  @override
  String get accountChangeAvatar => 'Изменить аватар';

  @override
  String get accountRemoveAvatar => 'Удалить аватар';

  @override
  String get accountSignOut => 'Выйти';

  @override
  String get accountSupportTitle => 'Премиум-доступ';

  @override
  String get accountSupportFreeSubtitle => 'Базовые функции чтения бесплатны.';

  @override
  String get accountSupportAction => 'Получить Premium';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Минимум 12 символов';

  @override
  String get accountUsernameHint =>
      '3–30 строчных букв, цифр или знаков подчёркивания';

  @override
  String get settingsDonationAction => 'Пожертвовать через WeChat';

  @override
  String get settingsAlipayDonationAction => 'Пожертвовать через Alipay';

  @override
  String get settingsDonationDialogTitle => 'Пожертвование через WeChat';

  @override
  String get settingsDonationDialogHint =>
      'Отсканируйте QR-код в WeChat, чтобы поддержать разработку. Спасибо.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Пожертвование через Alipay';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Отсканируйте QR-код в Alipay, чтобы поддержать разработку. Спасибо.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'Пожертвования полностью добровольны. Они не разблокируют функции и не являются покупкой или договором на обслуживание.';

  @override
  String get settingsDonationQrCodeLabel =>
      'QR-код для пожертвования через WeChat';

  @override
  String get settingsAlipayDonationQrCodeLabel =>
      'QR-код для пожертвования через Alipay';

  @override
  String get settingsAiSwipeHint =>
      'Листайте модели, касайтесь для переключения, удерживайте для изменения или удаления.';

  @override
  String get settingsAiLegacyIntro =>
      'Выберите поставщика и модель, затем введите свой API Key.';

  @override
  String get settingsAiModelLabel => 'Модель';

  @override
  String get settingsAiUsingCustomParams =>
      'Используются пользовательские настройки модели';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Хранится только на этом устройстве';

  @override
  String get settingsAiSaveAndEnable => 'Сохранить и включить';

  @override
  String get settingsAboutTagline =>
      'Кроссплатформенное приложение, сосредоточенное на чтении';

  @override
  String get settingsVersionLabel => 'Версия';

  @override
  String get changelogHistoryTitle => 'История версий';

  @override
  String get changelogHistorySubtitle => 'Изменения во всех выпусках';

  @override
  String get openSourceLicensesTitle => 'Лицензии открытого кода и шрифтов';

  @override
  String get openSourceLicensesSubtitle =>
      'Лицензии приложения, встроенных шрифтов и стороннего ПО';

  @override
  String get openSourceLicensesIntro =>
      'Эти тексты лицензий и уведомления доступны в приложении офлайн. Origo X, шрифты по требованию и стороннее ПО по-прежнему подчиняются своим лицензиям.';

  @override
  String get openSourceProjectSection => 'Лицензии проекта';

  @override
  String get openSourceLegacyLicenseTitle => 'Более ранние выпуски';

  @override
  String get openSourceFontsSection => 'Лицензии шрифтов';

  @override
  String get openSourceDependenciesSection => 'Стороннее ПО';

  @override
  String get openSourceDependenciesTitle => 'Зависимости Flutter и Dart';

  @override
  String get openSourceDependenciesSubtitle =>
      'Сторонние лицензии, собранные Flutter автоматически';

  @override
  String get openSourceLicenseLegalese =>
      'Origo X и сторонние компоненты по-прежнему подчиняются своим лицензиям.';

  @override
  String get openSourceLicenseLoadFailed =>
      'Не удалось загрузить текст лицензии.';

  @override
  String get changelogPageTitle => 'История выпусков';

  @override
  String get changelogCurrentVersion => 'Текущая версия';

  @override
  String get changelogLoadFailed => 'Не удалось загрузить историю выпусков';

  @override
  String get settingsMaintainerLabel => 'Сопровождающий';

  @override
  String get settingsLicenseLabel => 'Лицензия';

  @override
  String get settingsViewSourceSubtitle => 'Открыть проект с открытым кодом';

  @override
  String get settingsJoinQqGroup => 'Вступить в группу QQ';

  @override
  String get settingsQqOpenFailed =>
      'Не удалось открыть QQ. Убедитесь, что QQ установлен.';

  @override
  String get settingsDarkModeTitle => 'Ночной режим';

  @override
  String settingsCurrentValue(String value) {
    return 'Текущее: $value';
  }

  @override
  String get settingsUiStyleTitle => 'Эффект стекла';

  @override
  String get settingsGlassEffectSubtitle =>
      'Полупрозрачные поверхности, размытие фона и эффект парения';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Скрыть подписи нижней навигации';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'Показывать только значки в нижней навигации на мобильных устройствах';

  @override
  String get settingsFloatingNavigationTitle => 'Плавающая панель навигации';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Настройка размера, стиля отображения и порядка разделов';

  @override
  String get floatingNavigationPreviewTitle => 'Предпросмотр';

  @override
  String get floatingNavigationSizeTitle => 'Размер';

  @override
  String get floatingNavigationSizeAutomatic => 'Автоматически';

  @override
  String get floatingNavigationSizeCustom => 'Своё';

  @override
  String get floatingNavigationHeightLabel => 'Высота';

  @override
  String get floatingNavigationSideMarginLabel => 'Боковые отступы';

  @override
  String get floatingNavigationDisplayModeTitle => 'Стиль отображения';

  @override
  String get floatingNavigationIconsOnly => 'Только значки';

  @override
  String get floatingNavigationIconsAndLabels => 'Значки и подписи';

  @override
  String get floatingNavigationOrderTitle => 'Порядок навигации';

  @override
  String get floatingNavigationOrderHint =>
      'Удерживайте маркер справа, чтобы изменить порядок';

  @override
  String get floatingNavigationSyncHint =>
      'Порядок также применяется к свайп-навигации и боковой панели на широких экранах';

  @override
  String get floatingNavigationResetOrder =>
      'Восстановить порядок по умолчанию';

  @override
  String get floatingNavigationResetDone => 'Порядок по умолчанию восстановлен';

  @override
  String get settingsLibraryLayoutTitle => 'Настройки библиотеки';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Настройка вида библиотеки и анимации открытия книг';

  @override
  String get settingsLibraryLayoutCard => 'Карточки';

  @override
  String get settingsLibraryLayoutGrid => 'Сетка';

  @override
  String get settingsLibraryGridColumnsTitle => 'Обложек в ряд на телефонах';

  @override
  String get settingsLibraryGridTwoColumns => '2 столбца';

  @override
  String get settingsLibraryGridThreeColumns => '3 столбца';

  @override
  String get settingsLibraryGridShowDetailsTitle =>
      'Показывать название и прогресс';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Добавляет строку с названием и компактный индикатор прогресса под каждой обложкой';

  @override
  String get settingsLibraryOpenAnimationTitle => 'Анимация открытия книги';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Применяется только при открытии книги из библиотеки';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Классическое развёртывание обложки';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Исходная обложка увеличивается на весь экран перед показом читалки';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Минимальное затухание';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Текст проявляется без направленного движения';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Подъём страницы';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'Страница чтения мягко встаёт на место снизу';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Сдвиг страницы';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'Страница чтения появляется коротким боковым движением';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Темп анимации';

  @override
  String get settingsLibraryOpenAnimationFast => 'Быстрый';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Быстрое проявление, как только текст готов';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Размеренный';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Более плавное проявление текста для спокойного перехода';

  @override
  String get settingsAccentFollowTheme => 'Акцентный цвет: как в теме';

  @override
  String settingsAccentValue(String name) {
    return 'Акцентный цвет: $name';
  }

  @override
  String get settingsAppThemeTitle => 'Тема приложения';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Текущая: $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'Как в теме приложения';

  @override
  String get settingsAccentColorTitle => 'Акцентный цвет';

  @override
  String get settingsThemeModeSystemHint =>
      'Переключается автоматически вместе с системным оформлением';

  @override
  String get settingsThemeModeLightHint =>
      'Всегда использовать светлое оформление';

  @override
  String get settingsThemeModeDarkHint =>
      'Всегда использовать тёмное оформление';

  @override
  String get settingsSelectAppTheme => 'Выбор темы приложения';

  @override
  String get settingsDone => 'Готово';

  @override
  String get settingsAccentColorAdvice =>
      'Акцентный цвет формирует полные цветовые схемы Material 3 для светлой и тёмной тем.';

  @override
  String get settingsAccentPresetColors => 'Быстрые цвета';

  @override
  String get settingsAccentCustomColor => 'Свой цвет';

  @override
  String get settingsAccentSaturationBrightness =>
      'Поле насыщенности и яркости';

  @override
  String get settingsAccentHue => 'Оттенок';

  @override
  String get settingsAccentPreview => 'Предпросмотр палитры темы';

  @override
  String get settingsAccentFollowThemeOption => 'Как в теме';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Использовать стандартный акцентный цвет текущей темы приложения';

  @override
  String get settingsAboutTitle => 'О приложении';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Сопровождающий: 小元Niki';

  @override
  String get settingsGithubRepo => 'Репозиторий GitHub';

  @override
  String get settingsNewYearGreeting =>
      'Сосредоточенная, сдержанная и свободно изменяемая кроссплатформенная читалка.';

  @override
  String get settingsGithubOpenFailed => 'Не удалось открыть ссылку GitHub';

  @override
  String get settingsOfficialWebsite => 'Официальный сайт';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Скачайте и установите с open.xxread.top';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'Не удалось открыть официальный сайт';

  @override
  String get updateCheckNow => 'Проверить обновления';

  @override
  String get updateCheckNowSubtitle =>
      'Получите последнюю версию с GitHub или официального сайта';

  @override
  String get updateAppStoreManaged =>
      'Эта сборка из Mac App Store обновляется через App Store';

  @override
  String get updateAvailableTitle => 'Доступна новая версия';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Текущая версия: $currentVersion\nПоследняя версия: $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Что нового';

  @override
  String get updateNotesEmpty =>
      'Для этой версии не предоставлено примечаний к выпуску.';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateSkipVersion => 'Пропустить эту версию';

  @override
  String get updateGoToDownload => 'Перейти к обновлению';

  @override
  String get updateFromGithub => 'Обновить с GitHub';

  @override
  String get updateFromWebsite => 'Открыть официальный сайт';

  @override
  String get updateFromWebsiteInstall => 'Скачать с сайта';

  @override
  String get updateWebsiteUnavailable =>
      'Пакет с официального сайта пока недоступен для этого устройства';

  @override
  String get updateDownloadingTitle => 'Загрузка обновления';

  @override
  String updateDownloadProgress(int percent) {
    return 'Загружено $percent%';
  }

  @override
  String get updatePreparingInstaller =>
      'Проверка пакета и подготовка системного установщика…';

  @override
  String get updateDownloadFailed =>
      'Не удалось скачать обновление с официального сайта';

  @override
  String get updateIntegrityFailed =>
      'Скачанное обновление не прошло проверку целостности и было удалено';

  @override
  String get updateInstallFailed =>
      'Не удалось установить пакет обновления. Проверьте права на установку и попробуйте снова.';

  @override
  String get updateAlreadyLatest => 'Вы уже используете последнюю версию';

  @override
  String get updateCheckFailed =>
      'Не удалось проверить обновления. Попробуйте позже.';

  @override
  String get updateOpenFailed => 'Не удалось открыть ссылку';

  @override
  String get settingsIosOnlyFeature => 'Эта функция доступна только на iOS';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Синхронизировано с $storage\nКниг: $books, скопировано файлов: $files';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Для полного применения этого изменения требуется перезапуск приложения.';

  @override
  String get settingsRestartRequiredTitle => 'Требуется перезапуск';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\nПерезапустить приложение сейчас?';
  }

  @override
  String get settingsRestartLater => 'Позже';

  @override
  String get settingsRestartNow => 'Перезапустить';

  @override
  String get statsDetailedTitle => 'Подробная статистика';

  @override
  String get statsRange7Days => '7 дней';

  @override
  String get statsRange30Days => '30 дней';

  @override
  String get statsRange90Days => '90 дней';

  @override
  String get statsRange1Year => '1 год';

  @override
  String get statsRangeAll => 'Всё';

  @override
  String get statsTabOverview => 'Обзор';

  @override
  String get statsTabCharts => 'Графики';

  @override
  String get statsTabBooks => 'Книги';

  @override
  String get statsTabAchievements => 'Достижения';

  @override
  String get statsReadingOverview => 'Обзор чтения';

  @override
  String statsCumulativeHours(Object hours) {
    return 'Всего $hours ч';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Держите ритм — вы читаете $days дней подряд';
  }

  @override
  String get statsTotalDuration => 'Общее время';

  @override
  String get statsAvgSession => 'Средняя сессия';

  @override
  String statsDaysCount(Object count) {
    return 'Дней: $count';
  }

  @override
  String get statsNoData => 'Нет данных';

  @override
  String get statsPeriodEarlyMorning => 'Раннее утро 05:00–08:59';

  @override
  String get statsPeriodMorning => 'Утро 09:00–11:59';

  @override
  String get statsPeriodAfternoon => 'День 12:00–17:59';

  @override
  String get statsPeriodEvening => 'Вечер 18:00–21:59';

  @override
  String get statsPeriodLateNight => 'Ночь 22:00–04:59';

  @override
  String get statsTotalReadingTime => 'Общее время чтения';

  @override
  String get statsTotalPagesRead => 'Всего прочитано страниц';

  @override
  String get statsBooksReadCount => 'Прочитано книг';

  @override
  String get statsUnitPage => 'стр.';

  @override
  String get statsTodayProgress => 'Прогресс чтения сегодня';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target мин';
  }

  @override
  String get statsPagesRead => 'Прочитано страниц';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target стр.';
  }

  @override
  String get statsReadingHabits => 'Привычки чтения';

  @override
  String get statsBestReadingPeriod => 'Лучшее время для чтения';

  @override
  String get statsAvgSessionReading => 'Средняя сессия чтения';

  @override
  String get statsMaxStreakDays => 'Самая длинная серия';

  @override
  String get statsFocusScore => 'Концентрация чтения';

  @override
  String get statsBookCount => 'Количество книг';

  @override
  String get statsTrendAnalysis => 'Анализ тренда чтения';

  @override
  String statsAxisMinutes(Object value) {
    return '$value мин';
  }

  @override
  String statsAxisPages(Object value) {
    return '$value стр.';
  }

  @override
  String statsAxisBooks(Object value) {
    return '$value кн.';
  }

  @override
  String statsAxisHour(Object hour) {
    return '$hour ч';
  }

  @override
  String get statsTimeDistribution => 'Распределение времени чтения';

  @override
  String get statsFormatDistribution => 'Распределение форматов книг';

  @override
  String get statsCompleted => 'Завершено';

  @override
  String get statsInProgress => 'Читается';

  @override
  String get statsDurationRanking => 'Рейтинг по времени чтения';

  @override
  String get statsProgressRanking => 'Рейтинг по прогрессу чтения';

  @override
  String statsPagesCount(Object count) {
    return 'Страниц: $count';
  }

  @override
  String statsSessionCount(Object count) {
    return 'Сессий: $count';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return 'Получено достижений: $achieved, осталось открыть: $remaining';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Первое чтение';

  @override
  String get statsAchievementFirstReadDesc => 'Завершите первую сессию чтения';

  @override
  String get statsAchievementNoviceTitle => 'Читатель-новичок';

  @override
  String get statsAchievementNoviceDesc => 'Прочитайте в сумме 10 часов';

  @override
  String get statsAchievementBookwormTitle => 'Книгочей';

  @override
  String get statsAchievementBookwormDesc => 'Прочитайте в сумме 100 часов';

  @override
  String get statsAchievementExpertTitle => 'Знаток чтения';

  @override
  String get statsAchievementExpertDesc => 'Читайте 7 дней подряд';

  @override
  String get statsAchievementOceanTitle => 'Океан знаний';

  @override
  String get statsAchievementOceanDesc => 'Прочитайте 10 000 страниц';

  @override
  String get statsAchievementScholarTitle => 'Эрудит';

  @override
  String get statsAchievementScholarDesc => 'Прочитайте 10 разных книг';

  @override
  String get statsAchievementMarathonTitle => 'Читательский марафон';

  @override
  String get statsAchievementMarathonDesc => 'Читайте 30 дней подряд';

  @override
  String get statsAchievementFocusTitle => 'Мастер концентрации';

  @override
  String get statsAchievementFocusDesc => 'Прочитайте в сумме 500 часов';

  @override
  String statsProgressPercent(Object percent) {
    return 'Прогресс: $percent%';
  }

  @override
  String get statsGoalProgress => 'Прогресс цели чтения';

  @override
  String get statsMonthlyReadingTime => 'Время чтения в этом месяце';

  @override
  String get statsWeeklyReadingTime => 'Время чтения на этой неделе';

  @override
  String get statsAvgDailyPages7d =>
      'В среднем страниц в день (последние 7 дней)';

  @override
  String statsHoursCount(Object count) {
    return 'Часов: $count';
  }

  @override
  String get statsSpeedTrend => 'Тренд скорости чтения';

  @override
  String statsAvgSpeed(Object speed) {
    return 'В среднем: $speed стр./мин';
  }

  @override
  String get statsReadingContinuity => 'Непрерывность чтения';

  @override
  String statsCurrentStreak(Object days) {
    return 'Текущая серия: $days дн.';
  }

  @override
  String get statsHeatmapLess => 'Меньше';

  @override
  String get statsHeatmapMore => 'Больше';

  @override
  String statsWeekNumber(Object week) {
    return 'Неделя $week';
  }

  @override
  String get bookSourceAddToShelf => 'Добавить на полку';

  @override
  String get bookSourceAddOnline => 'Добавить онлайн';

  @override
  String get bookSourceAddOnlineHint =>
      'Читать из источника и кэшировать главы по мере чтения';

  @override
  String get bookSourceDownloadLocal => 'Скачать локально';

  @override
  String get bookSourceDownloadLocalHint =>
      'Скачать все главы и добавить локальную копию TXT';

  @override
  String get bookSourceAddedOnline => 'Добавлено на полку как онлайн-книга';

  @override
  String get bookSourceAlreadyOnShelf => 'Эта книга уже есть на вашей полке';

  @override
  String get bookSourceDownloading => 'Скачивание локально';

  @override
  String get bookSourceFetchingCatalog => 'Получение каталога глав…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return 'Глав: $completed/$total';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Скачивание завершено, книга добавлена на локальную полку';

  @override
  String get bookSourceDownloadConverted =>
      'Скачивание завершено. Теперь это локальная книга';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Не удалось скачать: $error';
  }

  @override
  String get downloadTasksTitle => 'Загрузки';

  @override
  String get downloadTasksEmpty => 'Нет задач загрузки';

  @override
  String get downloadTaskQueued => 'Ожидает загрузки';

  @override
  String get downloadTaskDownloading => 'Скачивается в фоне';

  @override
  String get downloadTaskCompleted => 'Загрузка завершена';

  @override
  String get downloadTaskFailed => 'Загрузка не удалась';

  @override
  String get downloadTaskCancelled => 'Отменено';

  @override
  String get downloadTaskCancel => 'Отменить задачу';

  @override
  String get downloadContinueInBackground => 'Продолжить в фоне';

  @override
  String get downloadRunningInBackground => 'Загрузка продолжается в фоне';

  @override
  String get bookSourceExitAddTitle => 'Добавить на полку?';

  @override
  String bookSourceExitAddMessage(String title) {
    return 'Добавить «$title» на полку как онлайн-книгу? Ваш прогресс чтения сохранится.';
  }

  @override
  String get bookSourceNotNow => 'Не сейчас';

  @override
  String get bookSourceOnlineBadge => 'Онлайн';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'Данные онлайн-книги недействительны: $error';
  }

  @override
  String get readerThemeTitle => 'Тема чтения';

  @override
  String get readerThemeDescription =>
      'Меняет только страницу чтения и её элементы управления';

  @override
  String get readerSettingsTabTheme => 'Тема';

  @override
  String get readerSettingsTabText => 'Текст';

  @override
  String get readerSettingsTabLayout => 'Вёрстка';

  @override
  String get readerSettingsTabPaging => 'Страницы';

  @override
  String get readerSettingsAdvancedTypography => 'Дополнительная типографика';

  @override
  String get readerAutoPageTurnTitle => 'Автолистание';

  @override
  String get readerAutoPageTurnOff => 'Не запущено';

  @override
  String get readerAutoPageTurnShortcutTitle => 'Быстрый доступ к авточтению';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Показывать в элементах управления чтением для быстрого запуска или паузы';

  @override
  String get readerAutoPageTurnHint =>
      'Прокручивать на один экран через выбранный интервал, в том числе в вертикальном постраничном режиме.';

  @override
  String get readerAutoPageTurnModeTimed => 'Листание по таймеру';

  @override
  String get readerAutoPageTurnModeSweep => 'Плавное листание';

  @override
  String get readerAutoPageTurnModeContinuous => 'Непрерывная прокрутка';

  @override
  String get readerAutoPageTurnModeInterval => 'Прокрутка по интервалу';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Ждать выбранный интервал, затем перейти к следующей странице.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Линия опускается вниз, постепенно открывая следующую страницу над ней.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Непрерывная прокрутка вниз с постоянной скоростью чтения.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Ждать выбранный интервал, затем прокрутить вниз примерно на один экран.';

  @override
  String get readerAutoPageTurnSweepDurationLabel =>
      'Длительность плавного листания';

  @override
  String get readerAutoPageTurnScrollSpeedLabel => 'Скорость прокрутки';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds с на экран';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · $seconds с/экран';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'Пауза · $mode · $seconds с/экран';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Интервал страниц';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds с на экран';
  }

  @override
  String get readerAutoPageTurnStart => 'Запустить автолистание';

  @override
  String get readerAutoPageTurnResume => 'Возобновить автолистание';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Авто · $seconds с/экран';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'Пауза · $seconds с/экран';
  }

  @override
  String get readerThemeDay => 'День';

  @override
  String get readerThemeFollowSystem => 'Как в системе';

  @override
  String get readerThemeMist => 'Дымка';

  @override
  String get readerThemeGreen => 'Защита глаз';

  @override
  String get readerThemeRose => 'Роза';

  @override
  String get readerThemeNavy => 'Глубокий синий';

  @override
  String get readerThemeNight => 'Ночь';

  @override
  String get readerThemePureBlack => 'Чистый чёрный';

  @override
  String get readerThemeParchment => 'Пергамент';

  @override
  String get readerThemeCustom => 'Своя';

  @override
  String get readerPullBookmarkTitle => 'Закладка потягиванием вниз';

  @override
  String get readerPullBookmarkHint =>
      'Потяните от верхнего края и отпустите, чтобы добавить или удалить закладку для этой страницы';

  @override
  String get readerPullBookmarkAddHint =>
      'Потяните сильнее, чтобы добавить закладку';

  @override
  String get readerPullBookmarkRemoveHint =>
      'Потяните сильнее, чтобы удалить закладку';

  @override
  String get readerPullBookmarkReleaseHint => 'Отпустите для завершения';

  @override
  String get readerTapAnimationTitle => 'Анимация касания';

  @override
  String get readerTapAnimationHint =>
      'Использовать текущую анимацию перелистывания для боковых касаний; выключите для мгновенного обновления';

  @override
  String get readerTabletTwoPageTitle => 'Две страницы на планшете';

  @override
  String get readerTabletTwoPageHint =>
      'В альбомной ориентации показывать левую и правую страницы рядом; выключите, чтобы всегда использовать одну страницу';

  @override
  String get readerCustomThemeTitle => 'Своя тема чтения';

  @override
  String get readerCustomThemeReset => 'Сбросить';

  @override
  String get readerCustomThemeColors => 'Цвета темы';

  @override
  String get readerCustomThemeTextColor => 'Цвет текста';

  @override
  String get readerCustomThemeTextColorHint =>
      'Основной текст, заголовки и главные значки';

  @override
  String get readerCustomThemeBackground => 'Фон чтения';

  @override
  String get readerCustomThemeBackgroundHint => 'Цвет «бумаги» и холста чтения';

  @override
  String get readerCustomThemeControlBar => 'Цвет панели управления';

  @override
  String get readerCustomThemeControlBarHint =>
      'Верхняя и нижняя панели и поверхности настроек';

  @override
  String get readerCustomThemeContrastGood =>
      'Контраст текста достаточен для комфортного длительного чтения';

  @override
  String get readerCustomThemeContrastLow =>
      'Контраст текста низкий и может вызвать утомление';

  @override
  String get readerCustomThemeSave => 'Сохранить и использовать';

  @override
  String get readerCustomThemePreview => 'Живой предпросмотр';

  @override
  String get readerCustomThemePreviewChapter =>
      'Глава первая · Ветер между страниц';

  @override
  String get readerCustomThemePreviewBody =>
      'Это ваше пространство чтения. Настройте цвета текста, бумаги и панелей, пока каждая страница не станет по-настоящему вашей.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Введите 6-значный hex-цвет, например #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Hex-цвет';

  @override
  String get readerCustomThemesTitle => 'Свои темы чтения';

  @override
  String get readerCustomThemeAdd => 'Добавить тему';

  @override
  String get readerCustomThemeReorderHint =>
      'Удерживайте маркер справа, чтобы изменить порядок тем. Тот же порядок отображается в настройках чтения.';

  @override
  String get readerCustomThemeUse => 'Использовать выбранную тему';

  @override
  String get readerCustomThemeDeleteTitle => 'Удалить тему чтения?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return 'Тема «$name» будет удалена вместе с сохранённым фоновым изображением.';
  }

  @override
  String get readerCustomThemeEmptyTitle => 'Своих тем пока нет';

  @override
  String get readerCustomThemeEmptyHint =>
      'Создайте собственную комбинацию шрифта, цвета бумаги и фонового изображения.';

  @override
  String get readerCustomThemeNewTitle => 'Новая тема чтения';

  @override
  String get readerCustomThemeEditTitle => 'Изменить тему чтения';

  @override
  String get readerCustomThemeName => 'Название темы';

  @override
  String get readerCustomThemeNameHint =>
      'Например, «Дождливая ночь» или «Послеобеденная бумага»';

  @override
  String get readerCustomThemeBackgroundImage => 'Фоновое изображение';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Поддерживаются JPG, PNG и WebP. Изображение копируется в хранилище приложения.';

  @override
  String get readerCustomThemeChooseImage => 'Загрузить изображение';

  @override
  String get readerCustomThemeReplaceImage => 'Заменить изображение';

  @override
  String get readerCustomThemeRemoveImage => 'Убрать изображение';

  @override
  String get readerCustomThemeImageStrength =>
      'Интенсивность фонового изображения';

  @override
  String get readerCustomThemeImageUnsupported =>
      'Импорт фоновых изображений не поддерживается на этой платформе';

  @override
  String get readerCustomThemeImageTooLarge =>
      'Изображение должно быть не больше 20 МБ';

  @override
  String get readerCustomThemeImageFormat =>
      'Выберите изображение JPG, PNG или WebP';

  @override
  String get readerCustomThemeImageFailed =>
      'Не удалось импортировать фоновое изображение. Попробуйте снова.';

  @override
  String get importSourceTitle => 'Добавление книг';

  @override
  String get importSourceDescription =>
      'Сначала выберите несколько файлов. Проверьте очередь перед началом импорта.';

  @override
  String get importSelectFiles => 'Выбрать файлы';

  @override
  String get importIosSharedDocuments => 'На моём iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'iCloud Drive недоступен';

  @override
  String get importAndroidFolder => 'Разрешить доступ к папке книг';

  @override
  String get importAndroidRescan => 'Сканировать разрешённые папки';

  @override
  String get importFolderPermissionAvailable =>
      'Доступ есть · коснитесь для сканирования';

  @override
  String get importFolderPermissionLost =>
      'Доступ потерян · разрешите снова, чтобы восстановить';

  @override
  String get importRemoveFolder => 'Убрать папку';

  @override
  String importQueueTitle(int count) {
    return 'Очередь импорта ($count)';
  }

  @override
  String get importQueueHint =>
      'Уберите ошибочно выбранные файлы, затем импортируйте их по одному.';

  @override
  String get importQueueEmptyTitle => 'Книги не выбраны';

  @override
  String get importQueueEmptyBody =>
      'Выберите EPUB, PDF, TXT, MOBI или другой поддерживаемый файл книги.';

  @override
  String importAction(int count) {
    return 'Импортировать книг: $count';
  }

  @override
  String importRetryFailed(int count) {
    return 'Повторить неудачные ($count)';
  }

  @override
  String get importStatusQueued => 'Ожидание';

  @override
  String get importStatusPreparing => 'Подготовка файла';

  @override
  String get importStatusChecking => 'Проверка';

  @override
  String get importStatusCopying => 'Копирование';

  @override
  String get importStatusAnalyzing => 'Анализ';

  @override
  String get importStatusSaving => 'Сохранение';

  @override
  String get importStatusImported => 'Импортировано';

  @override
  String get importStatusSkipped => 'Уже существует, пропущено';

  @override
  String get importStatusFailed => 'Не удалось импортировать';

  @override
  String get importRemove => 'Убрать';

  @override
  String get importRetry => 'Повторить';

  @override
  String get importClearCompleted => 'Очистить завершённые';

  @override
  String get importDone => 'Готово';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return 'Импортировано: $succeeded · пропущено: $skipped · с ошибкой: $failed';
  }

  @override
  String get importNoSupportedFiles => 'Поддерживаемые файлы книг не найдены';

  @override
  String get importScanning => 'Сканирование файлов…';

  @override
  String get settingsAiApiKeyConfigured => 'API Key настроен';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Коснитесь, чтобы завершить настройку';

  @override
  String get settingsAiAddModel => 'Добавить модель';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Переключено на $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Сначала заполните Base URL и API Key';

  @override
  String get settingsAiEditModelTitle => 'Настройка модели';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Каждая быстрая карточка привязана к одной модели';

  @override
  String get settingsAiPresetModel => 'Модель из пресета';

  @override
  String get settingsAiBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'Совместимо с OpenAI: Base URL обычно должен включать /v1 (например, https://example.com/v1). Приложение добавит /chat/completions.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic: Base URL может включать /v1 или не включать его. Приложение не дублирует /v1 и добавляет /messages.';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiModelNameLabel => 'Название модели';

  @override
  String get settingsAiFetchModelsTooltip => 'Автоматически получить модели';

  @override
  String get settingsAiFetchModelsList =>
      'Автоматически получить список моделей';

  @override
  String get settingsAiSelectModel => 'Выберите модель';

  @override
  String get settingsAiTemperatureLabel => 'Температура';

  @override
  String get settingsAiAddAndEnable => 'Добавить и включить';

  @override
  String get settingsAiModelMismatchClaude =>
      'Названия моделей поставщика Claude обычно начинаются с \"claude\". Проверьте, что поставщик и модель соответствуют друг другу.';

  @override
  String get settingsAiModelMismatchGemini =>
      'Названия моделей поставщика Gemini обычно содержат \"gemini\". Проверьте, что поставщик и модель соответствуют друг другу.';

  @override
  String get settingsAiModelMismatchGlm =>
      'Названия моделей поставщика GLM обычно начинаются с \"glm\". Проверьте, что поставщик и модель соответствуют друг другу.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'Названия моделей поставщика MiniMax обычно содержат \"MiniMax\". Проверьте, что поставщик и модель соответствуют друг другу.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Формат ответа со списком моделей не распознан';

  @override
  String get settingsAiNoModelsReturned =>
      'Сервер не вернул список доступных моделей';

  @override
  String get settingsAiNoModelsAvailable => 'Нет доступных моделей';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Не удалось получить модели: $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'Предобработка книг с помощью AI';

  @override
  String get settingsAiPreprocessSubtitle =>
      'После импорта книги AI прочитает её и автоматически создаст локальную базу знаний с кратким содержанием';

  @override
  String get settingsAiPreprocessWarning =>
      'Предобработка отправляет всю книгу модели AI по частям. Это расходует много токенов и занимает время. Всё равно включить?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Сначала настройте рабочую модель AI с API-ключом';

  @override
  String get libraryAiPreprocess => 'Предобработка AI';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return 'Позволить AI прочитать «$title» и создать базу знаний с кратким содержанием? Это расходует много токенов.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'AI читает эту книгу… (шаг $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'База знаний AI создана';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'Ошибка предобработки AI: $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Этот формат книг пока не поддерживает предобработку AI';

  @override
  String get libraryAiPreprocessQueued =>
      'Добавлено в очередь предобработки AI. Прогресс — в разделе «Загрузки».';

  @override
  String get downloadTasksTabDownloads => 'Загрузки';

  @override
  String get aiPreprocessTaskRunning => 'AI читает…';

  @override
  String get aiPreprocessTasksEmpty => 'Нет задач предобработки AI';

  @override
  String get aiPreprocessClearFinished => 'Очистить завершённые';

  @override
  String get aiChatNewChat => 'Новый чат';

  @override
  String get aiChatSelectBook => 'Привязать книгу';

  @override
  String get aiChatNoBook => 'Без привязанной книги';

  @override
  String get navAi => 'AI';

  @override
  String get aiHistoryTitle => 'Чаты AI';

  @override
  String get aiHistoryEmpty =>
      'Чатов AI пока нет.\nКоснитесь «Спросить AI» во время чтения, чтобы начать первый разговор.';

  @override
  String aiHistoryMessageCount(int count) {
    return 'Сообщений: $count';
  }

  @override
  String get aiHistoryClearAll => 'Очистить все';

  @override
  String get aiHistoryClearAllConfirm =>
      'Удалить всю историю чатов AI? Это действие нельзя отменить.';

  @override
  String get aiHistoryDeleteConfirm => 'Удалить этот чат?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Выключите переключатель, чтобы скрыть страницу; «Настройки» скрыть нельзя.';

  @override
  String get readerAskAi => 'Спросить AI';

  @override
  String get readerAiInputHint => 'Спросите об этой книге…';

  @override
  String get readerAiSendButton => 'Отправить';

  @override
  String get readerAiThinking => 'Думает…';

  @override
  String get readerAiNotConfiguredHint =>
      'Модель AI ещё не настроена. Откройте Настройки → AI-помощник чтения и добавьте модель и API Key.';

  @override
  String get readerAiEmptyHint =>
      'Спросите AI о текущей странице или о чём угодно в этой книге.';

  @override
  String get readerAiSelectionQuestionLabel => 'Объяснить это выделение';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Объясните приведённый ниже отрывок и дайте 3 ключевых тезиса.\n\nВыделенный текст:\n$selection\n\nКонтекст до:\n$before\n\nКонтекст после:\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst => 'Введите вопрос перед отправкой';

  @override
  String get readerAiEmptyResponse =>
      'Модель вернула пустой ответ, попробуйте ещё раз';

  @override
  String readerAiRequestFailed(String error) {
    return 'Запрос не удался: $error';
  }

  @override
  String get readerAiUnknownError => 'Неизвестная ошибка';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'Ответ сервера пуст. Обычно причина — неверный Base URL, шлюз, не перенаправляющий запросы к эндпоинту модели, или раннее закрытие соединения сервером.\nURL запроса: $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'Ответ сервера не является корректным JSON. Текущий эндпоинт может быть несовместим с конфигурацией $provider.\nURL запроса: $endpoint\nФрагмент ответа: $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Запрос не удался$status: не удалось прочитать ответ сервера. Обычно причина — неверный Base URL, пустое содержимое от эндпоинта или обрыв ответа в сети.\nURL запроса: $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Сетевой запрос не удался$status: $error\nURL запроса: $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Запрос не удался($status): $text\nРекомендации: 1) температура MiniMax должна быть в (0,1]; 2) проверьте, что название модели соответствует эндпоинту; 3) используйте только одну системную инструкцию.\nURL запроса: $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Запрос не удался($status): $text\nПодсказка: Claude требует заголовок запроса anthropic-version.\nURL запроса: $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Запрос не удался($status): $text\nПодсказка: убедитесь, что поставщик и API Key соответствуют друг другу; их нельзя смешивать.\nURL запроса: $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Запрос не удался($status): $text\nURL запроса: $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'AI (тест): Вы выбрали текст \"$selectedText\".\n\nДо: $before\nПосле: $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'AI (тест): На этой странице $chars символов. Обратите внимание на тезисы в начале и конце абзацев.';
  }

  @override
  String get readerAiMockGreeting => 'Здравствуйте';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'AI (тест): Вы спросили \"$question\".\n\nЯ прочитал текущую страницу ($chars символов). Можете продолжать задавать вопросы.';
  }

  @override
  String get ttsSystemDefault => 'Системный по умолчанию';

  @override
  String get ttsUnavailable => 'Системный TTS недоступен';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'Система не поддерживает язык: $language';
  }

  @override
  String get ttsCallFailed => 'Не удалось вызвать системный TTS';

  @override
  String get importErrorSourceMissing => 'Исходный файл не существует';

  @override
  String get importErrorHashFailed => 'Не удалось проверить содержимое файла';

  @override
  String get importErrorTargetNameExhausted =>
      'Не удалось подобрать свободное имя для импортируемого файла';

  @override
  String get importErrorSourceNotMaterialized =>
      'Исходный файл ещё не перенесён в локальное хранилище';

  @override
  String get importErrorCopyVerificationFailed =>
      'Скопированный файл не совпадает с исходным';

  @override
  String get importErrorFileTooLarge => 'Файл превышает лимит импорта в 500 МБ';

  @override
  String get importErrorSourcePrepareFailed =>
      'Не удалось подготовить файл для импорта';

  @override
  String get importErrorFailed => 'Не удалось импортировать книгу';

  @override
  String get importUnknownTitle => 'Название неизвестно';

  @override
  String get importUnknownAuthor => 'Автор неизвестен';

  @override
  String get bookUntitled => 'Без названия';

  @override
  String get accentPurple => 'Элегантный фиолетовый';

  @override
  String get accentPink => 'Вишнёвый розовый';

  @override
  String get accentCyan => 'Свежий циан';

  @override
  String get accentBrown => 'Классический коричневый';

  @override
  String get accentGrey => 'Элегантный серый';

  @override
  String get accentDeepPurple => 'Обворожительный фиолетовый';

  @override
  String get accentAmber => 'Янтарное золото';

  @override
  String get accentLightGreen => 'Яркий зелёный';

  @override
  String get accentYellow => 'Солнечно-жёлтый';

  @override
  String get accentNeutralGrey => 'Минималистичный серый';

  @override
  String get accentIndigo => 'Глубокий индиго';

  @override
  String get accentDeepOrange => 'Пламенный оранжевый';

  @override
  String get agreementV2HeroTitle => 'Читайте на своём устройстве.';

  @override
  String get agreementV2HeroBody =>
      'Origo X — читалка электронных книг с открытым кодом, кроссплатформенная и ориентированная на локальные данные. Она предоставляет инструменты чтения; она не предоставляет, не размещает и не проверяет книги, которые вы импортируете.';

  @override
  String get agreementV2LocalTitle => 'Локальные данные прежде всего';

  @override
  String get agreementV2LocalBody =>
      'Книги, прогресс и заметки, как правило, остаются на вашем устройстве, чтобы вы управляли ими и создавали резервные копии.';

  @override
  String get agreementV2OpenSourceTitle => 'Лицензия AGPL-3.0';

  @override
  String get agreementV2OpenSourceBody =>
      'Исходный код предоставляется по лицензии GNU AGPL v3.0, а программное обеспечение поставляется «как есть», без гарантий.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Версия условий: $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Введение';

  @override
  String get agreementFlowStepTerms => 'Условия';

  @override
  String get agreementFlowStepSource => 'Источники книг';

  @override
  String get agreementFlowStepPrivacy => 'Конфиденциальность';

  @override
  String get agreementFlowNext => 'Далее';

  @override
  String get agreementFlowBack => 'Назад';

  @override
  String get agreementFlowTermsTitle =>
      'Используйте Origo X с ясными границами';

  @override
  String get agreementFlowTermsSubtitle =>
      'Ознакомьтесь с условиями использования программы и контента, который вы решите открыть.';

  @override
  String get agreementFlowTermsConsent =>
      'Я прочитал(а) и согласен(а) с условиями использования.';

  @override
  String get agreementFlowSourceTitle =>
      'Соглашение о сторонних источниках книг';

  @override
  String get agreementFlowSourceSubtitle =>
      'Подтвердите, как адреса источников, контент, авторизация и ответственность отделены от официального проекта.';

  @override
  String get agreementFlowSourceConsent =>
      'Я прочитал(а) и согласен(а) с соглашением о сторонних источниках книг.';

  @override
  String get agreementFlowPrivacyTitle =>
      'Ваши данные остаются под вашим контролем';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Посмотрите, что остаётся локально, когда происходят сетевые запросы и как хранятся записи о загрузках.';

  @override
  String get agreementFlowPrivacyConsent =>
      'Я прочитал(а) и согласен(а) с уведомлением о конфиденциальности.';

  @override
  String get agreementFlowEnterApp => 'Войти в Origo X';

  @override
  String get agreementFlowPrivacyLocalTitle => 'По умолчанию локально';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Книги, прогресс, заметки и настройки обычно остаются на этом устройстве.';

  @override
  String get agreementFlowPrivacyNetworkTitle => 'Сеть используется явно';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'Локальное чтение не отправляет текст книг. Проверка обновлений обращается к GitHub и официальному сайту; источники, AI и синхронизация подключаются только при использовании их функций.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Ограниченные записи о загрузках';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'Записи о загрузках с официального сайта, содержащие исходный IP, хранятся не более 180 дней, затем удаляются.';

  @override
  String get agreementV2Title =>
      'Условия использования и уведомление о конфиденциальности';

  @override
  String get agreementV2Subtitle => 'Прочитайте перед использованием Origo X';

  @override
  String get agreementV2ImportantNotice =>
      'Важно: официальное приложение Origo X не предустанавливает, не встраивает и не рекомендует сторонние источники книг, а его разработчики не управляют, не представляют и не размещают контент источников. Вы выбираете каждый импортируемый файл и каждый добавляемый источник; используйте только тот контент, к которому у вас есть право доступа.';

  @override
  String get agreementV2SourceBoundaryTitle => 'Граница сторонних источников';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'Официальный проект предоставляет только читалку с открытым кодом и протокол Origo Source Protocol. Он не предоставляет адреса источников или официальный каталог источников.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Каждый адрес источника вводите и добавляете вы. Приложение подключается к этому независимому сервису напрямую, не пропуская контент через сервер разработчиков.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'Совместимость с протоколом означает лишь возможность подключения интерфейса; она не подтверждает законность или наличие лицензии. Ответственность за контент несут операторы источников, а вы должны проверять его и использовать правомерно.';

  @override
  String get agreementV2Section1Title => 'Область действия и принятие';

  @override
  String get agreementV2Section1Body =>
      'Эти условия распространяются на скачивание, установку и использование Origo X и встроенных функций. Выбирая «Согласиться и продолжить», вы подтверждаете, что прочитали, поняли и приняли их. Если вы не согласны, прекратите использование и выйдите из приложения. Там, где этого требует местное законодательство, необходимо согласие опекуна.';

  @override
  String get agreementV2Section2Title => 'Лицензия открытого кода';

  @override
  String get agreementV2Section2Body =>
      'Будущие версии Origo X выпускаются по лицензии GNU Affero General Public License v3.0. Вы можете использовать, копировать, изменять, распространять или продавать программное обеспечение на условиях этой лицензии. Распространяемая изменённая версия должна предоставлять полный соответствующий исходный код по AGPL-3.0, а изменённая версия, используемая для предоставления сетевого сервиса, также должна предлагать соответствующий исходный код взаимодействующим с ней пользователям. Права MIT, уже предоставленные для версии 1.0.0 и более ранних, остаются в силе и не отзываются. Эти условия не ограничивают права, предоставленные лицензией открытого кода. Сторонние компоненты по-прежнему подчиняются собственным лицензиям.';

  @override
  String get agreementV2Section3Title => 'Пользовательский контент и права';

  @override
  String get agreementV2Section3Body =>
      '«Пользовательский контент» включает книги, документы, изображения, метаданные, ссылки и другие материалы, которые вы импортируете, скачиваете, открываете, конвертируете, кэшируете, аннотируете или слушаете. У вас должны быть все права и разрешения, необходимые для его использования. Вы несёте единоличную ответственность за претензии и убытки, связанные с пользовательским контентом: нарушение авторских прав, товарных знаков, неприкосновенности частной жизни, клевета, незаконный контент, вредоносное ПО и прочее. Программное обеспечение и его разработчики не загружают, не продают, не лицензируют, не одобряют и не проверяют этот контент, а поддержка формата не означает законного разрешения использовать файл.';

  @override
  String get agreementV2Section4Title => 'Запрещённое использование';

  @override
  String get agreementV2Section4Body =>
      'Запрещается использовать программное обеспечение для нарушения прав интеллектуальной собственности или иных прав; распространения незаконного, вредоносного или злонамеренного контента; обхода систем управления цифровыми правами, средств контроля доступа или платных стен; атак или нарушения работы сторонних систем; а также для деятельности, запрещённой применимым законодательством. Вы несёте ответственность за жалобы, претензии, штрафы и убытки, вытекающие из ваших действий.';

  @override
  String get agreementV2Section5Title => 'Источники книг и третьи стороны';

  @override
  String get agreementV2Section5Body =>
      'Официальное приложение не предустанавливает, не распространяет и не рекомендует источники книг и не ведёт официальный каталог источников. Источники, сетевые API, внешние ссылки, онлайн-контент, системный синтез речи, AI-сервисы и другие интеграции, которые вы добавляете, независимо предоставляются и контролируются третьими лицами. Разработчики ими не управляют, их не представляют, не лицензируют, не одобряют и не проверяют. Юридическую ответственность за предоставляемый контент несут операторы источников. Перед добавлением источника вы обязаны проверить его происхождение, права на контент, политику конфиденциальности и условия, а также несёте ответственность за собственный доступ, загрузки, кэширование, распространение и иное использование. В максимальной степени, допускаемой применимым законодательством, разработчики не несут ответственности за сторонний контент, списания, практики обработки данных, сбои или споры о нарушении прав.';

  @override
  String get agreementV2Section6Title => 'Данные и конфиденциальность';

  @override
  String get agreementV2Section6Body =>
      'Origo X работает по принципу локальности. Книги, прогресс чтения, заметки и настройки обычно хранятся на вашем устройстве. Пока вы не включите сетевой источник книг, AI, синхронизацию или другую онлайн-функцию, приложению не нужно отправлять текст книг разработчикам для локального чтения. Автоматическая и ручная проверка обновлений обращается к GitHub и официальному сайту open.xxread.top с необходимыми техническими параметрами: платформа, архитектура процессора, канал распространения; их серверы обрабатывают ваш IP-адрес и User-Agent как часть обычного сетевого обмена. Когда вы скачиваете установщик с официального сайта, серверная часть записывает версию, архитектуру, время загрузки, IP-адрес и User-Agent для подсчёта загрузок, защиты и диагностики. Записи о загрузках с исходным IP хранятся не более 180 дней и затем удаляются; дольше хранится только агрегированная статистика без исходных IP. Запросы обновлений не включают текст книг, вашу библиотеку, заметки, учётную запись или уникальный идентификатор устройства. Запросы к GitHub также регулируются условиями конфиденциальности GitHub. При использовании других онлайн-функций запросы, выделенный текст, сетевые сведения или необходимые параметры могут передаваться выбранному вами поставщику согласно его политикам. Защищайте устройство, API-ключи и резервные копии; удаление приложения, очистка данных, поломка устройства или ошибка пользователя могут безвозвратно стереть данные.';

  @override
  String get agreementV2Section7Title => 'AI и автоматическая генерация';

  @override
  String get agreementV2Section7Body =>
      'Краткие содержания, ответы, переводы, рекомендации и другой сгенерированный AI результат может быть неточным, неполным, устаревшим или вводящим в заблуждение. Это лишь помощники при чтении, а не юридическая, медицинская, финансовая, академическая или иная профессиональная консультация. Проверяйте результат самостоятельно и не полагайтесь на него в рискованных решениях. Материалы, отправляемые поставщику AI, также регулируются условиями этого поставщика.';

  @override
  String get agreementV2Section8Title => 'Отказ от гарантий';

  @override
  String get agreementV2Section8Body =>
      'В максимальной степени, допускаемой законодательством, программное обеспечение и связанные материалы предоставляются «как есть» и «как доступно», без явных, подразумеваемых или предусмотренных законом гарантий, включая товарное состояние, пригодность для определённой цели, права собственности, отсутствие нарушений, точность, совместимость, безопасность, работу без ошибок, бесперебойную доступность или сохранность данных. Участники открытого проекта не обязаны сопровождать, обновлять, поддерживать или исправлять программное обеспечение.';

  @override
  String get agreementV2Section9Title => 'Ограничение ответственности';

  @override
  String get agreementV2Section9Body =>
      'В максимальной степени, допускаемой законодательством, разработчики, обладатели авторских прав и участники не несут ответственности за прямой, косвенный, случайный, особый, штрафной или последующий ущерб, возникший из-за установки, использования или невозможности использования, пользовательского контента, сторонних сервисов, потери данных, проблем с устройством, перерыва в бизнесе или инцидентов безопасности, будь то по договору, деликту или иному основанию. Неисключаемая по закону ответственность ограничивается минимальным допускаемым объёмом.';

  @override
  String get agreementV2Section10Title => 'Возмещение убытков';

  @override
  String get agreementV2Section10Body =>
      'В допускаемой применимым законодательством мере вы несёте ответственность и освобождаете разработчиков, обладателей авторских прав и участников от сторонних претензий, расследований, штрафов, убытков и разумных расходов, возникших из-за вашего пользовательского контента, незаконных или нарушающих права действий, нарушения этих условий или использования сторонних сервисов.';

  @override
  String get agreementV2Section11Title => 'Изменения, прекращение и право';

  @override
  String get agreementV2Section11Body =>
      'Функции, статус сопровождения и эти условия могут меняться по мере развития открытого проекта, законодательства или управления рисками. Существенные обновления могут требовать повторного согласия; если вы не согласны — прекратите пользоваться приложением. Вы можете удалить приложение в любой момент. Споры сначала следует решать неформально. С учётом обязательной защиты прав потребителей применяется право по месту нахождения разработчика и суды с законной юрисдикцией. Если отдельное положение не подлежит исполнению, остальные сохраняют силу.';

  @override
  String get agreementV2ConfirmLabel =>
      'Я прочитал(а) и согласен(а) с условиями использования и уведомлением о конфиденциальности.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Я понимаю, что официальный проект не предоставляет источники книг; источники и контент, которые я добавляю, исходят от независимых третьих лиц, и я проверю авторизацию и останусь ответственным за собственное использование.';

  @override
  String get agreementV2ExitLabel => 'Отклонить';

  @override
  String get agreementV2ContinueLabel => 'Согласиться и продолжить';

  @override
  String get agreementV2ExitDialogTitle => 'Отклонить условия?';

  @override
  String get agreementV2ExitDialogBody =>
      'Чтобы продолжить пользоваться Origo X, необходимо принять условия использования. Если вы не согласны, выйдите из приложения.';

  @override
  String get agreementV2CancelLabel => 'Вернуться';

  @override
  String get agreementV2ConfirmExitLabel => 'Выйти';

  @override
  String get agreementV2SaveFailed =>
      'Не удалось сохранить ваше согласие. Попробуйте снова.';

  @override
  String get settingsDataSyncTitle => 'Данные и синхронизация';

  @override
  String get settingsCacheManagementTitle => 'Управление кэшем';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return 'Занято $size · Подробности и очистка кэша';
  }

  @override
  String get settingsCacheUsageTitle => 'Использование кэша';

  @override
  String get settingsCacheTotalUsage => 'Всего занято';

  @override
  String get settingsCacheSafeHint =>
      'Показаны только безопасно удаляемые кэши. Книги, прогресс чтения и настройки не включены.';

  @override
  String get settingsCacheSourceCovers => 'Кэш обложек источников';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Скачанные обложки источников · $size';
  }

  @override
  String get settingsCacheSourceData => 'Кэш глав источников';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Безопасно удаляемый кэш онлайн-глав · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Локальный кэш чтения';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Восстанавливаемый кэш разбора EPUB/TXT/Kindle · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'Временные файлы';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'Одноразовые файлы обновлений и временные файлы · $size';
  }

  @override
  String get settingsCacheClearAll => 'Очистить все безопасные кэши';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Очищаются только перечисленные выше категории · $size';
  }

  @override
  String get settingsCacheCalculating => 'Подсчёт…';

  @override
  String get settingsCacheClearConfirm =>
      'Удаляются только временные кэшированные данные. Книги, сохранённые обложки, прогресс чтения, базы данных, настройки и учётные данные сохраняются.';

  @override
  String get settingsCacheClearAction => 'Очистить';

  @override
  String get settingsCacheCleared => 'Кэш очищен';

  @override
  String get settingsCacheClearFailed => 'Не удалось очистить кэш';

  @override
  String get settingsWebDavSyncTitle => 'Синхронизация WebDAV';

  @override
  String get webDavNotConfigured => 'Не настроено';

  @override
  String get webDavConfigureSubtitle =>
      'Синхронизация данных чтения с вашим хранилищем WebDAV';

  @override
  String get webDavBetaBadge => 'Бета · Может быть нестабильно';

  @override
  String get webDavPageTitle => 'Синхронизация WebDAV';

  @override
  String get webDavConnected => 'Подключено';

  @override
  String get webDavSyncing => 'Синхронизация';

  @override
  String get webDavPartialFailure => 'Некоторые элементы требуют внимания';

  @override
  String get webDavSyncFailed => 'Синхронизация не удалась';

  @override
  String webDavPendingChanges(int count) {
    return 'Изменений в ожидании синхронизации: $count';
  }

  @override
  String webDavLastSync(String time) {
    return 'Последняя синхронизация: $time';
  }

  @override
  String get webDavNeverSynced => 'Пока не синхронизировалось';

  @override
  String get webDavSyncNow => 'Синхронизировать';

  @override
  String get webDavSetUp => 'Настроить WebDAV';

  @override
  String get webDavConnectionTitle => 'Подключение';

  @override
  String get webDavServerUrl => 'Адрес WebDAV';

  @override
  String get webDavUsername => 'Имя пользователя';

  @override
  String get webDavPassword => 'Пароль приложения';

  @override
  String get webDavPasswordHint =>
      'Хранится в защищённом виде только на этом устройстве';

  @override
  String get webDavRootPath => 'Удалённая папка';

  @override
  String get webDavTestConnection => 'Проверить подключение';

  @override
  String get webDavTestingConnection => 'Проверка подключения…';

  @override
  String get webDavConnectionSuccess =>
      'Подключение и доступ на запись подтверждены';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Проверка подключения не удалась: $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Сохранить конфигурацию';

  @override
  String get webDavAutomaticSync => 'Автоматическая синхронизация';

  @override
  String get webDavAutomaticSyncHint =>
      'Синхронизация после запуска или возврата приложения на передний план';

  @override
  String get webDavSyncContent => 'Содержимое синхронизации';

  @override
  String get webDavScopeBookSources => 'Источники книг';

  @override
  String get webDavScopeBookSourcesHint =>
      'Синхронизируются публичные источники ORSP и избранное, а также все названия групп, пустые группы и их порядок. Учётные данные источников и приватные конфигурации остаются на этом устройстве.';

  @override
  String get webDavScopeBooks => 'Библиотека и онлайн-книги';

  @override
  String get webDavScopeProgress => 'Прогресс чтения';

  @override
  String get webDavScopeBookmarks => 'Закладки';

  @override
  String get webDavScopeNotes => 'Заметки и выделения';

  @override
  String get webDavScopeNotesHint =>
      'Включает цитируемый текст, заметки и рукописные пометки. Данные WebDAV не шифруются сквозным образом.';

  @override
  String get webDavScopeReadingSessions => 'Статистика чтения';

  @override
  String get webDavScopeReaderSettings => 'Настройки читалки';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Синхронизация типографики, тем, перелистывания, настроек автолистания, зон нажатия и параметров читалки изображений.';

  @override
  String get webDavScopeReplaceRules => 'Правила замены';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Синхронизируются шаблоны правил и текст замены. Данные WebDAV не шифруются сквозным образом.';

  @override
  String get webDavScopeBookFiles => 'Файлы книг';

  @override
  String get webDavBookFilesHint =>
      'Выберите, какие книги загружать или скачивать';

  @override
  String get webDavBookFilesUnavailable =>
      'Передача файлов книг будет включена после стабилизации синхронизации метаданных';

  @override
  String get webDavSecurityNotice =>
      'Данные передаются по HTTPS, но ваш поставщик WebDAV может прочитать незашифрованное содержимое на сервере.';

  @override
  String get webDavConnectionDetails => 'Настройки подключения';

  @override
  String get webDavClearConfiguration => 'Очистить конфигурацию';

  @override
  String get webDavClearConfigurationTitle => 'Очистить конфигурацию WebDAV?';

  @override
  String get webDavClearConfigurationMessage =>
      'Удаляет адрес WebDAV и данные входа с этого устройства. Локальные данные чтения и удалённые файлы не удаляются.';

  @override
  String get webDavClearConfigurationConfirm => 'Удалить с этого устройства';

  @override
  String get webDavActivityTitle => 'Активность синхронизации';

  @override
  String get webDavActivityEmpty => 'Активности синхронизации пока нет';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return 'Отправлено: $uploaded, скачано: $downloaded';
  }

  @override
  String get webDavErrorAuthentication =>
      'Неверное имя пользователя, пароль или права на папку.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'Конфигурация WebDAV неполная или недействительная.';

  @override
  String get webDavErrorInsecureConnection =>
      'Подключение не отвечает требованиям безопасности.';

  @override
  String get webDavErrorCertificate =>
      'Не удалось проверить сертификат сервера.';

  @override
  String get webDavErrorPermission => 'Удалённая папка недоступна для записи.';

  @override
  String get webDavErrorNotFound =>
      'Удалённая папка синхронизации или необходимый файл не найдены.';

  @override
  String get webDavErrorConflict =>
      'Конфликт удалённых данных. Попробуйте синхронизировать снова.';

  @override
  String get webDavErrorStorageFull => 'Хранилище WebDAV переполнено.';

  @override
  String get webDavErrorRateLimited =>
      'Слишком много запросов WebDAV. Попробуйте позже.';

  @override
  String get webDavErrorTimeout => 'Сервер не ответил вовремя.';

  @override
  String get webDavErrorUnsupported =>
      'Ответ сервера несовместим с протоколом синхронизации.';

  @override
  String get webDavErrorServer => 'Серверу WebDAV не удалось выполнить запрос.';

  @override
  String get webDavErrorNetwork =>
      'Сеть недоступна. Изменения остаются сохранёнными на этом устройстве.';

  @override
  String get webDavErrorCorruptData =>
      'Часть удалённых данных синхронизации повреждена и не была применена.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'Локальные настройки чтения повреждены. Синхронизация остановлена без удаления удалённой резервной копии.';

  @override
  String get webDavErrorClockSkew =>
      'Часы этого устройства слишком сильно расходятся с сервером WebDAV.';

  @override
  String get webDavErrorSecureStorage =>
      'Не удалось прочитать пароль WebDAV из защищённого хранилища.';

  @override
  String get webDavErrorUnknown => 'WebDAV не удалось выполнить операцию.';

  @override
  String get webDavErrorDetails => 'Подробности ответа сервера';

  @override
  String get webDavErrorMissingEtagDetail =>
      'Сервер не вернул строгий идентификатор версии файла (ETag). ETag может отсутствовать или быть слишком слабым, поэтому приложение не может определить, изменило ли другое устройство удалённый файл.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'Сервер проигнорировал условие, разрешающее запись только при совпадении версии файла (If-Match). Продолжение может перезаписать более новое изменение с другого устройства.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'Сервер проигнорировал условие, разрешающее создание только при отсутствии файла (If-None-Match). Продолжение может перезаписать существующий файл.';

  @override
  String webDavErrorReason(String reason) {
    return 'Причина: $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'Статус HTTP: $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Метод запроса: $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Путь к ресурсу: $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Сбой на этапе: $phase';
  }

  @override
  String get webDavPhaseConnecting => 'подключение к удалённому серверу';

  @override
  String get webDavPhaseScanningLocal => 'сканирование этого устройства';

  @override
  String get webDavPhaseReadingRemote => 'чтение удалённых данных';

  @override
  String get webDavPhaseApplyingRemote => 'слияние удалённых данных';

  @override
  String get webDavPhaseUploadingLocal => 'отправка локальных изменений';

  @override
  String get webDavPhaseFinishing => 'завершение синхронизации';

  @override
  String get webDavPhaseUnknown => 'неизвестный шаг';

  @override
  String get webDavBookFilesTitle => 'Файлы книг';

  @override
  String get webDavFilesPendingUpload => 'К отправке';

  @override
  String get webDavFilesAvailableDownload => 'Доступны';

  @override
  String get webDavFilesSynced => 'Синхронизированы';

  @override
  String get webDavFilesUploadSelected => 'Отправить выбранные';

  @override
  String get webDavFilesDownloadSelected => 'Скачать выбранные';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return 'Выбрано: $count · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Только на этом устройстве';

  @override
  String get webDavFilesOnlyRemote => 'Файл не скачан на это устройство';

  @override
  String get webDavFilesUploadPermission => 'Разрешить отправку файлов книг';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Синхронизируются выбранные книги и обложки. TXT после первой отправки передаёт только изменённые блоки; EPUB и PDF сохраняют исходные байты. Полные читаемые файлы экспортируются отдельно.';

  @override
  String get webDavNewBookPolicyTitle => 'Новые файлы книг';

  @override
  String get webDavNewBookPolicyAsk => 'Спрашивать каждый раз (рекомендуется)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Выбирайте, какие книги загружать, после завершения импорта';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Загружать новые книги автоматически';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Загрузка сразу после импорта, возможно с расходом мобильного трафика';

  @override
  String get webDavNewBookPolicyManual => 'Всегда выбирать вручную';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Запускать загрузку только со страницы «Файлы книг»';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return 'Синхронизировать только что импортированные книги ($count)?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'Данные чтения синхронизируются автоматически. Выберите исходные файлы книг для отправки в WebDAV.';

  @override
  String get webDavNewBooksSkip => 'Не сейчас';

  @override
  String webDavNewBooksUploading(int count) {
    return 'Отправка новых книг: $count…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Отправка новых книг завершена: успешно $success, с ошибкой $failed';
  }

  @override
  String get webDavFilesTooLarge =>
      'Файл превышает лимит синхронизации для этого формата';

  @override
  String get webDavFilesEmpty => 'В этой категории нет книг';

  @override
  String get webDavFilesTransferComplete => 'Передача файлов книг завершена';

  @override
  String get readerAddAnnotation => 'Добавить аннотацию';

  @override
  String get readerAnnotationHint => 'Напишите свои мысли об этом отрывке…';

  @override
  String get readerAnnotationSaved => 'Аннотация сохранена';

  @override
  String get readerAnnotationDeleted => 'Аннотация удалена';

  @override
  String get readerAnnotationShelfRequired =>
      'Прежде чем сохранять аннотации, добавьте книгу на полку';

  @override
  String get readerNoAnnotations => 'Аннотаций пока нет';

  @override
  String get readerNoAnnotationsHint =>
      'Выделите текст, чтобы подсветить его или добавить комментарий. Коснитесь подчёркнутого комментария, чтобы прочитать его снова.';

  @override
  String get replaceRulesTitle => 'Замена и очистка';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Удаление рекламы, промо и другого нежелательного текста при чтении';

  @override
  String get replaceRulesImport => 'Импортировать правила';

  @override
  String get replaceRulesExport => 'Экспортировать правила';

  @override
  String get replaceRulesSearchHint => 'Поиск по названию, группе или шаблону';

  @override
  String get replaceRulesUnnamed => 'Правило без названия';

  @override
  String get replaceRulesDeleteValue => 'Убрать';

  @override
  String get replaceRulesCreate => 'Новое правило';

  @override
  String get replaceRulesEmptyTitle => 'Нет правил замены';

  @override
  String get replaceRulesEmptyBody =>
      'Импортируйте JSON-файл источников чтения или создайте правило на основе регулярного выражения.';

  @override
  String get replaceRulesNoSearchResults => 'Подходящих правил нет';

  @override
  String get replaceRulesCreateTitle => 'Новое правило замены';

  @override
  String get replaceRulesEditTitle => 'Изменить правило замены';

  @override
  String get replaceRulesNameLabel => 'Название правила';

  @override
  String get replaceRulesPatternLabel =>
      'Искомый текст или регулярное выражение';

  @override
  String get replaceRulesPatternHelper =>
      'Оставьте замену пустой, чтобы удалить найденный текст';

  @override
  String get replaceRulesReplacementLabel => 'Заменить на';

  @override
  String get replaceRulesRegexLabel => 'Использовать регулярное выражение';

  @override
  String get replaceRulesScopeTitleLabel => 'Применять к названиям глав';

  @override
  String get replaceRulesScopeContentLabel => 'Применять к содержимому глав';

  @override
  String get replaceRulesGroupLabel => 'Группа (необязательно)';

  @override
  String get replaceRulesScopeLabel => 'Область (необязательно)';

  @override
  String get replaceRulesScopeHelper =>
      'Разделяйте названия книг или имена источников точкой с запятой';

  @override
  String get replaceRulesExcludeScopeLabel =>
      'Исключённая область (необязательно)';

  @override
  String get replaceRulesDeleteConfirmTitle => 'Удалить это правило?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'Правило будет удалено с этого устройства.';

  @override
  String replaceRulesImported(int count) {
    return 'Импортировано правил: $count';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'Не удалось импортировать правила: $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'Файл правил превышает $max';
  }

  @override
  String get replaceRulesExported => 'Правила экспортированы';

  @override
  String get replaceRulesPatternRequired =>
      'Введите искомый текст или регулярное выражение';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'Шаблон превышает $max символов';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Недопустимое регулярное выражение: $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Поддерживается не более $max правил';
  }

  @override
  String get accountSecurityTitle => 'Безопасность';

  @override
  String get accountSecurityLoading => 'Загрузка состояния безопасности…';

  @override
  String get accountChangeEmailTitle => 'Изменить email';

  @override
  String get accountChangeEmailEnterTitle => 'Выберите новый email';

  @override
  String get accountChangeEmailEnterHint =>
      'Мы отправим один код на текущий email и один на новый адрес.';

  @override
  String get accountChangeEmailVerifyTitle => 'Подтвердите оба адреса';

  @override
  String get accountChangeEmailVerifyHint =>
      'Введите два кода, чтобы завершить смену email для входа.';

  @override
  String get accountCurrentEmail => 'Текущий email';

  @override
  String get accountNewEmail => 'Новый email';

  @override
  String get accountCurrentEmailCode => 'Код из текущего email';

  @override
  String get accountNewEmailCode => 'Код из нового email';

  @override
  String get accountSendBothCodes => 'Отправить оба кода';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Ваш текущий адрес — скрытый переадресующий email Apple, который не может получать коды. Один код будет отправлен на новый адрес.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Ваш текущий адрес — скрытый переадресующий email Apple, поэтому код для него не нужен. Введите код, отправленный на новый адрес, чтобы завершить.';

  @override
  String get accountCurrentPasswordInstead => 'Текущий пароль (вместо кода)';

  @override
  String get accountRelayEmailTitle => 'Вы используете скрытый email Apple';

  @override
  String get accountRelayEmailBody =>
      'Ваш адрес входа — частный переадресующий адрес Apple, поэтому письма с подтверждением могут не приходить. Подумайте о переходе на email, которым вы пользуетесь ежедневно.';

  @override
  String get accountChangeEmailAction => 'Изменить email';

  @override
  String get accountEmailChanged => 'Email изменён';

  @override
  String get accountChangePasswordTitle => 'Задать или изменить пароль';

  @override
  String get accountPasswordEmailTitle => 'Подтверждение по email';

  @override
  String get accountPasswordEmailHint =>
      'Отправьте код на текущий email, прежде чем выбирать новый пароль.';

  @override
  String get accountPasswordNewTitle => 'Выберите новый пароль';

  @override
  String get accountPasswordNewHint =>
      'Введите код из письма и задайте пароль, который будете использовать в дальнейшем.';

  @override
  String get accountNewPassword => 'Новый пароль';

  @override
  String get accountChangePasswordAction => 'Изменить пароль';

  @override
  String get accountPasswordChanged => 'Пароль изменён';

  @override
  String get accountPasswordsMismatch => 'Пароли не совпадают';

  @override
  String get accountMfaTitle => 'Двухфакторная аутентификация';

  @override
  String get accountMfaEnabled =>
      'Включена. При входе требуется код из приложения аутентификации или неиспользованный код восстановления.';

  @override
  String get accountMfaDisabledByDefault =>
      'По умолчанию выключена. Включите её для защиты входа по паролю и коду из письма.';

  @override
  String get accountMfaOnTitle => 'Двухфакторная аутентификация включена';

  @override
  String get accountMfaEmailTitle => 'Сначала подтвердите email';

  @override
  String accountMfaEmailHint(String email) {
    return 'Мы отправим код настройки на $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'Введите код из письма';

  @override
  String get accountMfaEmailCodeHint =>
      'После подтверждения на следующей странице откроются QR-код и секретный код для приложения аутентификации.';

  @override
  String get accountMfaAuthenticatorTitle =>
      'Добавьте Origo X в приложение аутентификации';

  @override
  String get accountMfaAuthenticatorHint =>
      'Отсканируйте QR-код или введите секретный код вручную, затем введите шестизначный код из приложения аутентификации.';

  @override
  String get accountMfaQrCodeLabel => 'QR-код для настройки аутентификатора';

  @override
  String get accountMfaSecretLabel => 'Секретный код настройки';

  @override
  String get accountMfaSecretCopied => 'Секретный код настройки скопирован';

  @override
  String get accountMfaRecoveryTitle => 'Сохраните коды восстановления';

  @override
  String get accountMfaChallengeTitle => 'Двухфакторное подтверждение';

  @override
  String get accountMfaChallengeHint =>
      'Введите код из приложения аутентификации или неиспользованный код восстановления, чтобы войти в учётную запись.';

  @override
  String get accountMfaCode => 'Код аутентификатора';

  @override
  String get accountMfaOrRecoveryCode =>
      'Код аутентификатора или восстановления';

  @override
  String get accountMfaVerify => 'Подтвердить и продолжить';

  @override
  String get accountMfaSendSetupCode => 'Отправить код настройки на email';

  @override
  String get accountMfaContinueSetup => 'Продолжить настройку';

  @override
  String get accountMfaSecretWarning =>
      'Добавьте этот секретный код в приложение аутентификации. Он показывается только во время настройки.';

  @override
  String get accountMfaOpenAuthenticator => 'Открыть аутентификатор';

  @override
  String get accountMfaConfirm => 'Подтвердить и включить';

  @override
  String get accountMfaDisable => 'Отключить двухфакторную аутентификацию';

  @override
  String get accountMfaDisabled => 'Двухфакторная аутентификация отключена';

  @override
  String get accountRecoveryCodesWarning =>
      'Сохраните эти коды восстановления сейчас. Каждый код работает один раз, и этот список больше не будет показан.';

  @override
  String get accountCopyRecoveryCodes => 'Скопировать коды восстановления';

  @override
  String get accountRecoveryCodesCopied => 'Коды восстановления скопированы';

  @override
  String get accountRecoveryCodesSaved => 'Я сохранил(а) коды';

  @override
  String get accountPremiumLifetime => 'Пожизненный Premium открыт';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'Premium привязан к этой учётной записи и синхронизируется между поддерживаемыми платформами.';

  @override
  String get accountRedemptionCode => 'Код пожизненного Premium';

  @override
  String get accountRedeemPremium => 'Активировать и открыть навсегда';

  @override
  String get accountApplePurchase => 'Открыть навсегда через App Store';

  @override
  String get accountApplePurchaseHint =>
      'Разовая покупка навсегда привязывает Premium к этой учётной записи Origo X и синхронизирует его между поддерживаемыми платформами.';

  @override
  String get accountAppleProductLoading => 'Загрузка сведений о продукте…';

  @override
  String get accountAppleProductRetry =>
      'Не удалось загрузить сведения о продукте. Коснитесь, чтобы повторить.';

  @override
  String get accountAppleRestore => 'Восстановить покупки';

  @override
  String get accountApplePurchasePending =>
      'Покупка ожидает подтверждения App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Покупка отправлена; идёт проверка доступа Premium';

  @override
  String get accountAppleRestoreSubmitted => 'Запрошено восстановление покупки';

  @override
  String get accountPremiumUnlocked => 'Пожизненный Premium открыт';

  @override
  String get accountPremiumUnlockedReferral =>
      'Активировано: вы и пригласивший открыли пожизненный Premium';

  @override
  String get accountInviteTitle => 'Приглашайте друзей';

  @override
  String get accountInviteSubtitle =>
      'Когда друг привяжет ваш код и активирует код пожизненного Premium, вы оба навсегда получите Premium.';

  @override
  String get accountInviteMyCode => 'Мой код приглашения';

  @override
  String get accountInviteCopyCode => 'Скопировать код приглашения';

  @override
  String get accountInviteCopyLink => 'Скопировать ссылку-приглашение';

  @override
  String get accountInviteShareAction =>
      'Скопировать ссылку-приглашение, чтобы поделиться';

  @override
  String get accountInviteCopied => 'Данные приглашения скопированы';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return 'Приглашено: $invited · успешно: $rewarded';
  }

  @override
  String get accountInviteStatsInvited => 'Коды привязаны';

  @override
  String get accountInviteStatsRewarded => 'Награды открыты';

  @override
  String accountInviterBound(String name) {
    return 'Приглашён пользователем $name';
  }

  @override
  String get accountInviteRewarded => 'Приглашение завершено';

  @override
  String get accountInviteWaiting => 'Ожидание активации кода';

  @override
  String get accountInviteBindLabel => 'Код приглашения друга';

  @override
  String get accountInviteBindHint =>
      'Учётная запись может привязать код один раз и не сможет изменить его позже';

  @override
  String get accountInviteBindAction => 'Привязать код приглашения';

  @override
  String get accountInviteBound => 'Код приглашения привязан';

  @override
  String get accountInviteHowItWorks => 'Как это работает';

  @override
  String get accountInviteStepShareTitle => 'Поделитесь ссылкой';

  @override
  String get accountInviteStepShareBody =>
      'Отправьте другу ссылку или код. Он откроет её и создаст учётную запись.';

  @override
  String get accountInviteStepBindTitle => 'Привяжите код';

  @override
  String get accountInviteStepBindBody =>
      'Ваш друг вводит ваш код в разделе «Учётная запись». Каждая учётная запись может привязать код один раз.';

  @override
  String get accountInviteStepRedeemTitle => 'Активируйте код';

  @override
  String get accountInviteStepRedeemBody =>
      'Когда друг активирует код пожизненного Premium, обе учётные записи сразу получат Premium.';

  @override
  String get accountInviteMyBinding => 'Моя связь по приглашению';

  @override
  String get accountInviteBindIntro =>
      'Если вас пригласили, привяжите код приглашающего здесь, чтобы награда осталась за вашей учётной записью.';

  @override
  String get accountInviteBindingNotNeeded =>
      'У этой учётной записи уже есть Premium, поэтому код приглашения не нужен.';

  @override
  String get readingDataExportAction => 'Экспортировать данные чтения';

  @override
  String get readingDataExportSubtitle => 'Выделения, подчёркивания и заметки';

  @override
  String get readingDataExportWholeBook => 'Вся книга';

  @override
  String get readingDataExportWholeBookHint =>
      'Экспортирует все ваши аннотации в этой книге. Текст книги и исходный файл не включаются.';

  @override
  String get readingDataExportPrivacySummary =>
      'Включает выделенные или подчёркнутые отрывки и ваши личные заметки. Файл книги, полный текст, данные учётной записи и сведения об устройстве не включаются.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return 'Выделений: $highlights · подчёркиваний: $underlines · заметок: $notes';
  }

  @override
  String readingDataExportButton(int count) {
    return 'Экспортировать аннотаций: $count';
  }

  @override
  String get readingDataExportPreparing => 'Подготовка Markdown…';

  @override
  String get readingDataExportEmpty =>
      'В этой книге нет выделений, подчёркиваний или заметок для экспорта.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Данные чтения экспортированы в $location';
  }

  @override
  String get readingDataExportFailed =>
      'Не удалось экспортировать данные чтения';

  @override
  String get readingDataExportUnsupported =>
      'Экспорт данных чтения пока не поддерживается на этой платформе';

  @override
  String get readingDataExportReplaceTitle => 'Заменить существующий файл?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Файл уже существует: $path. Замену нельзя отменить.';
  }

  @override
  String get readingDataExportReplaceAction => 'Заменить';

  @override
  String get readingDataExportExportedAt => 'Экспортировано';

  @override
  String get readingDataExportAuthor => 'Автор';

  @override
  String get readingDataExportContents => 'Содержание';

  @override
  String get readingDataExportMyNote => 'Моя заметка';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Страница $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Аннотации без позиции';

  @override
  String get cloudSyncTitle => 'Облачная синхронизация';

  @override
  String get cloudSyncTagline =>
      'Продолжайте с того же места на другом устройстве';

  @override
  String get cloudSyncResumeTitle => 'Продолжение между устройствами';

  @override
  String get cloudSyncAutoResume => 'Возобновлять при открытии книги';

  @override
  String get cloudSyncAutoResumeHint =>
      'Проверять последнюю позицию при открытии; предлагать обновления во время чтения';

  @override
  String get cloudSyncAutoHint =>
      'Сохранять прогресс во время чтения и проверять обновления при открытии книги';

  @override
  String get cloudSyncMoreContent => 'Другие настройки синхронизации';

  @override
  String get cloudSyncBooks => 'Книги и текст';

  @override
  String get cloudSyncBooksHint =>
      'Участвующие книги, обновления текста и загрузки';

  @override
  String get cloudSyncActivity => 'Подробности и проблемы синхронизации';

  @override
  String get cloudSyncStorage => 'Подключение хранилища';

  @override
  String get cloudSyncNoActivity => 'Активности синхронизации пока нет';

  @override
  String get cloudSyncProgress => 'Позиция чтения';

  @override
  String get cloudSyncText => 'Файлы текста книг';

  @override
  String get cloudSyncMetadataComplete =>
      'Выбранные данные чтения обмениваются через WebDAV';

  @override
  String get cloudSyncPaused => 'Автоматическая синхронизация приостановлена';

  @override
  String get cloudSyncLocalOnly => 'Хранить на этом устройстве';

  @override
  String get cloudSyncCheckHint =>
      'Подключение не подтверждает получение на других устройствах; проверьте каждый пункт ниже';

  @override
  String get cloudSyncPendingFiles => 'Обновления текста требуют внимания';

  @override
  String get cloudSyncFileIdle =>
      'Связанные текстовые файлы будут проверены при следующей синхронизации';

  @override
  String get cloudSyncManageBooks => 'Выбор книг и загрузок';

  @override
  String get cloudSyncNoBooks => 'Книги TXT пока не связаны';

  @override
  String get cloudSyncCompare => 'Сравнить версии';

  @override
  String get cloudSyncKeepLocal => 'Использовать версию этого устройства';

  @override
  String get cloudSyncUseRemote => 'Использовать облачную версию';

  @override
  String get cloudSyncBothKept =>
      'Обе версии сохранены. Синхронизация продолжится после вашего выбора.';

  @override
  String get cloudSyncPreviewLimited =>
      'Предпросмотр показывает первое различие. Обе полные версии сохранены.';

  @override
  String get cloudSyncPending => 'Ожидает синхронизации';

  @override
  String get cloudSyncConflict => 'Версии требуют проверки';

  @override
  String get cloudSyncCurrent => 'Текущий текст синхронизирован с WebDAV';

  @override
  String get cloudSyncFailed => 'Синхронизация не завершена. Доступен повтор.';

  @override
  String get cloudSyncHistory => 'История версий';

  @override
  String get cloudSyncApplyUpdate => 'Применить обновление текста';

  @override
  String get cloudSyncParticipate => 'Синхронизировать текст этой книги';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Перед применением обновления текста закройте читалку или редактор этой книги';

  @override
  String get cloudSyncTextLocation => 'Текущий облачный файл';

  @override
  String get cloudSyncTextLocationHint =>
      'Здесь управляются обновления, паузы и конфликты для участвующих книг.';

  @override
  String get bookSourcesImportIntro =>
      'Источники определяются автоматически. Проверьте перед импортом.';

  @override
  String get bookSourcesImportInputStep => 'Выбор источника';

  @override
  String get bookSourcesImportReviewStep => 'Проверка и импорт';

  @override
  String get bookSourcesImportFileHint => 'Выберите JSON-файл источника.';

  @override
  String get bookSourcesImportDownloading => 'Скачивание источника…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Чтение правил и проверка дубликатов…';

  @override
  String get bookSourcesImportSaving => 'Сохранение источников…';

  @override
  String get bookSourcesImportPicking => 'Открытие выбора файлов…';

  @override
  String get bookSourcesImportWaitHint =>
      'Большие списки источников могут занять больше времени. Вы можете отменить и повторить.';

  @override
  String get bookSourcesImportSaveHint =>
      'Держите это окно открытым до завершения сохранения.';

  @override
  String get bookSourcesImportReady => 'Готово к импорту';

  @override
  String get bookSourcesImportEmpty =>
      'Источники не выбраны. Проверьте файл или выбор дубликатов.';

  @override
  String get bookSourcesImportRetry => 'Попробовать снова';

  @override
  String get bookSourcesImportFailed =>
      'Не удалось прочитать источники. Проверьте адрес или файл и повторите.';

  @override
  String get bookSourcesImportWebPage =>
      'Этот URL вернул сайт или страницу входа. Скопируйте ссылку на JSON загрузки источников или подписки с этого сайта и импортируйте её. Войти в источник можно после импорта.';

  @override
  String get bookSourcesImportSaveFailed =>
      'Не удалось сохранить источники. Предпросмотр сохранён; попробуйте снова.';

  @override
  String get bookSourcesImportErrorDetails => 'Подробности ошибки';

  @override
  String get bookSourcesImportFileUnreadable =>
      'Не удалось прочитать выбранный файл. Выберите его снова.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировать источников: $count',
      one: 'Импортировать 1 источник',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'JSON-файл';

  @override
  String get bookSourcesImportTimedOut =>
      'Чтение заняло слишком много времени. Проверьте соединение или импортируйте скачанный JSON-файл.';

  @override
  String get bookSourcesImportUsageNotice =>
      'Сведения об использовании источников';

  @override
  String get bookSourcesMaintenanceScope => 'Область';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Включённые';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Все источники';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Выбранные';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return 'Источников в этой области: $count';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope =>
      'В этой области нет источников';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Проверка остановлена';

  @override
  String get bookSourcesMaintenanceCancellingTitle => 'Остановка проверки';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Завершение активных проверок с сохранением полученных результатов';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Проверка прервана';

  @override
  String get bookSourcesMaintenanceResume => 'Продолжить оставшиеся проверки';

  @override
  String get bookSourcesMaintenanceRetry => 'Повторить незавершённые проверки';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return 'Непроверенных источников: $count';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Результаты проверки';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Все результаты';

  @override
  String get bookSourcesMaintenanceAvailable => 'Доступен';

  @override
  String get bookSourcesMaintenanceLimited => 'Частично';

  @override
  String get bookSourcesMaintenanceFailed => 'Неудачные проверки';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Истёк тайм-аут';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Не подтверждён';

  @override
  String get bookSourcesMaintenanceReviewSearch =>
      'Поиск по названию или адресу';

  @override
  String get bookSourcesMaintenanceReviewEmpty => 'Подходящих результатов нет';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return 'Выбрано для отключения: $count';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Выбрать неудачные проверки';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Время ожидания соединения истекло; повторите позже';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Проверка не дала однозначного результата';

  @override
  String get bookSourcesMaintenanceAvailableReason =>
      'Основные проверки пройдены';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Поиск дубликатов…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Используется вашей полкой · сохраняется по умолчанию';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return 'Выбранные источники ($count) используются книгами на вашей полке. Их удаление может помешать обновлению этих книг или загрузке новых глав.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Проблемы';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return 'Выбрано источников: $count';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed => 'Используется вашей полкой';

  @override
  String get bookSourcesMaintenancePause => 'Пауза';

  @override
  String get bookSourcesMaintenancePausing => 'Пауза…';

  @override
  String get bookSourcesMaintenancePaused => 'Проверка на паузе';

  @override
  String get bookSourcesMaintenanceCompleted => 'Проверка завершена';

  @override
  String get bookSourcesMaintenanceStart => 'Начать проверку';

  @override
  String get bookSourcesMaintenanceRestart => 'Начать снова';

  @override
  String get bookSourcesMaintenanceCheckedThisRun => 'Проверено за этот запуск';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Выберите и обработайте полученные результаты или продолжите проверку оставшихся источников.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'Не удалось сохранить изменения. Попробуйте снова.';

  @override
  String get settingsQqGroup => 'Группа QQ';

  @override
  String get settingsOpenSourceTitle => 'Подробности об открытом коде';

  @override
  String get settingsOpenSourceDetails =>
      'Все функции, кроме продвинутых, поставляются с открытым кодом. Код лицензирован по AGPL-3.0; его объём смотрите в репозитории GitHub.';

  @override
  String get premiumLifetimeTitle => 'Пожизненный Premium';

  @override
  String get premiumLifetimeCaption => 'Разовая покупка · Без автопродления';

  @override
  String get premiumBenefitsTitle => 'Что входит в Premium';

  @override
  String get premiumProtocolsBenefit =>
      'Импорт и использование дополнительных совместимых протоколов источников.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Доступ к доверенным источникам на устройстве, в локальной или частной сети.';

  @override
  String get premiumSourceNotice =>
      'Premium не включает книги и адреса источников. Сторонние сервисы могут взимать плату отдельно.';

  @override
  String get premiumSetupHint =>
      'После разблокировки включено по умолчанию. Отключить можно в разделе Настройки → Продвинутые функции.';

  @override
  String get premiumBillingTitle => 'Подробности покупки';

  @override
  String get premiumBillingBody =>
      'Это непотребляемая разовая покупка, а не подписка. Она не продлевается автоматически. App Store показывает фактическую цену, а платёж обрабатывает Apple.';

  @override
  String get premiumRestoreHelp =>
      'После переустановки или смены устройства восстановите покупку с помощью Apple Account, использованной при покупке, и связанной учётной записи Origo X. Восстановление не списывает средства повторно.';

  @override
  String get premiumMembershipTerms => 'Условия участия';

  @override
  String get premiumPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get premiumAppleEula => 'Стандартное EULA Apple';

  @override
  String get premiumPurchaseConsent =>
      'Перед покупкой прочитайте условия участия, политику конфиденциальности и стандартное EULA Apple.';

  @override
  String get premiumAccountBindingTitle => 'Учётная запись и доступ';

  @override
  String get premiumAccountBindingBody =>
      'После подтверждения Premium привязывается к текущей учётной записи Origo X и синхронизируется между поддерживаемыми платформами. Продвинутые настройки становятся доступны вместе с членством. Выход из учётной записи или отзыв покупки отключают продвинутые функции. Проверьте учётную запись перед покупкой.';

  @override
  String get premiumRefundTitle => 'Запросить возврат';

  @override
  String get premiumRefundTerms =>
      'Apple рассматривает и обрабатывает запросы на возврат в App Store по своим правилам. Отправка запроса не означает его одобрения. Возвращённые или отозванные покупки больше не дают соответствующего доступа Premium.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Данные проверки покупки';

  @override
  String get premiumPrivacyPurchaseBody =>
      'Платёжную информацию обрабатывает Apple. Приложение отправляет идентификатор продукта и подписанные Apple данные проверки транзакции в сервис учётных записей Origo X для подтверждения покупки и привязки или восстановления Premium. Этот процесс покупки не передаёт разработчику полный номер вашей банковской карты или пароль Apple Account.';

  @override
  String get premiumPrivacyAccountTitle => 'Сервис учётных записей';

  @override
  String get premiumPrivacyAccountBody =>
      'Сервис учётных записей Origo X обрабатывает данные учётной записи и записи о членстве для входа, проверки безопасности и доступа с разных устройств. По вопросам поддержки или конфиденциальности свяжитесь с нами через контакты на официальном сайте.';

  @override
  String get premiumPurchaseSuccess => 'Premium открыт';

  @override
  String get premiumTestPurchaseVerified =>
      'Тестовая покупка подтверждена. Полноценный Premium не активирован.';

  @override
  String get premiumPurchaseRevoked =>
      'Доступ Premium по этой покупке отозван.';

  @override
  String get premiumRestoreSuccess =>
      'Покупка восстановлена. Premium синхронизирован.';

  @override
  String get premiumRestoreEmpty =>
      'Восстанавливаемых покупок не найдено. Проверьте Apple Account и учётную запись Origo X, связанную с покупкой.';

  @override
  String get premiumPurchaseCanceled => 'Покупка отменена';

  @override
  String get premiumPendingApproval =>
      'Ожидание одобрения Apple. Доступ откроется после одобрения и проверки.';

  @override
  String get premiumVerifying => 'Проверка вашей покупки…';

  @override
  String get premiumRestoring => 'Восстановление покупок…';

  @override
  String get premiumRefundSubmitted =>
      'Запрос на возврат отправлен Apple на рассмотрение.';

  @override
  String get premiumRefundNotFound =>
      'Для этого Apple Account не найдено покупок Premium, доступных к возврату. Вы также можете проверить историю через поддержку покупок Apple.';

  @override
  String get premiumApplePurchaseSupport => 'Поддержка покупок Apple';

  @override
  String get premiumLinkFailed =>
      'Не удалось открыть эту ссылку. Попробуйте позже.';

  @override
  String get premiumSignInRequired =>
      'Войдите в Origo X перед покупкой или восстановлением Premium.';

  @override
  String get premiumRefundUnavailable =>
      'Окно возврата Apple недоступно. Продолжите через поддержку покупок Apple.';

  @override
  String get premiumOperationFailed =>
      'Не удалось выполнить операцию. Попробуйте снова.';

  @override
  String get premiumPurchaseConsentOther =>
      'Перед разблокировкой Premium прочитайте условия участия и политику конфиденциальности.';

  @override
  String get premiumBillingBodyOther =>
      'Откройте Premium через доступные варианты покупки или активации кода. Канал покупки показывает цену и способ оплаты. Подтверждённое членство привязывается к вашей текущей учётной записи Origo X.';

  @override
  String get accountDeleteTitle => 'Удаление учётной записи';

  @override
  String get accountDeleteEntrySubtitle =>
      'Полное стирание этой учётной записи и всех её данных';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get accountDeleteReviewTitle => 'Что делает удаление';

  @override
  String get accountDeleteReviewBody =>
      'Прочитайте каждый пункт. После подтверждения всё перечисленное ниже удаляется немедленно, и мы не сможем это вернуть.';

  @override
  String get accountDeleteCurrentAccount => 'Текущая учётная запись';

  @override
  String get accountDeleteJoined => 'Дата регистрации';

  @override
  String get accountDeletePremiumActive => 'Premium открыт (будет удалён)';

  @override
  String get accountDeletePremiumNone => 'Premium не открыт';

  @override
  String get accountDeleteHasTitle => 'Сейчас у этой учётной записи есть';

  @override
  String accountDeleteHasSessions(int count) {
    return 'Устройств с активным входом: $count';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return 'Ключей Passkey: $count';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return 'Связанных способов входа: $count';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return 'Участников, пришедших по вашему коду: $count';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return 'Активированных кодов: $count';
  }

  @override
  String get accountDeleteTermsTitle => 'Условия удаления';

  @override
  String get accountDeleteTermsIrreversible =>
      'Удаление учётной записи окончательно и необратимо. После подтверждения никто — включая поддержку — не сможет восстановить удалённые данные.';

  @override
  String get accountDeleteTermsIdentity =>
      'Удаляется сама учётная запись: ваш email, имя пользователя, отображаемое имя и аватар.';

  @override
  String get accountDeleteTermsLogins =>
      'Удаляются все способы входа: пароль, ключи Passkey, а также привязки Google, GitHub и Apple.';

  @override
  String get accountDeleteTermsSessions =>
      'Вы немедленно выходите из системы везде — на телефонах, планшетах и компьютерах.';

  @override
  String get accountDeleteTermsMfa =>
      'Настройка двухфакторной аутентификации и все коды восстановления удаляются.';

  @override
  String get accountDeleteTermsPremium =>
      'Доступ Premium удаляется независимо от того, как он был открыт: код активации, награда за приглашение или покупка через Apple.';

  @override
  String get accountDeleteTermsReferrals =>
      'Ваш код приглашения перестаёт работать, а записи о связях между вами и приглашёнными удаляются. Награды, уже выданные другим, не отбираются.';

  @override
  String get accountDeleteTermsRedemptions =>
      'Уже активированные коды не возмещаются и не становятся доступными снова.';

  @override
  String get accountDeleteTermsApple =>
      'Вы купили пожизненный Premium в App Store. Удаление учётной записи не возвращает средства и не отменяет транзакцию в App Store — возврат можно запросить только у Apple. Чек покупки отвязывается от этой учётной записи и сохраняется, поэтому позже вы сможете нажать «Восстановить покупки» в новой учётной записи с тем же Apple ID и вернуть Premium.';

  @override
  String get accountDeleteTermsLocalData =>
      'Книги, полки и прогресс чтения на этом устройстве не удаляются — они всегда были только на вашем устройстве. Удалите их в приложении, если хотите.';

  @override
  String get accountDeleteTermsTombstone =>
      'Мы сохраняем лишь минимальные обезличенные данные об удалении, необходимые для защиты от злоупотреблений, вместе с записями проверки покупок App Store, нужными для восстановления или подтверждения покупок. Эти записи не используются для воссоздания вашей учётной записи.';

  @override
  String get accountDeleteTermsRejoin =>
      'После удаления на тот же email можно зарегистрироваться снова, но это будет совершенно новая пустая учётная запись без ваших старых данных и доступа.';

  @override
  String get accountDeleteBlockedTitle =>
      'Эту учётную запись пока нельзя удалить';

  @override
  String get accountDeleteBlockedOwner =>
      'Вы владелец консоли администрирования. Сначала передайте владение другому человеку, затем вернитесь — иначе администрировать её будет некому.';

  @override
  String get accountDeleteConsent =>
      'Я полностью прочитал(а) условия, понимаю, что удаление нельзя отменить, и согласен(а) навсегда удалить мою учётную запись и все её данные.';

  @override
  String get accountDeleteConsentRequired =>
      'Сначала примите условия удаления.';

  @override
  String get accountDeleteContinue => 'Понимаю, продолжить';

  @override
  String get accountDeleteVerifyTitle => 'Подтвердите ваш email';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Мы отправим 6-значный код на $email, чтобы подтвердить, что запрос действительно от вас.';
  }

  @override
  String get accountDeleteSendCode => 'Отправить код удаления';

  @override
  String get accountDeleteResendCode => 'Отправить снова';

  @override
  String get accountDeleteCodeSent =>
      'Код отправлен. Завершите удаление в течение 10 минут.';

  @override
  String get accountDeleteConfirmTitle => 'Последний шаг';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Введите email учётной записи $email, чтобы не осталось сомнений, какая учётная запись удаляется.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'В момент нажатия кнопки ниже учётная запись будет навсегда удалена.';

  @override
  String get accountDeleteConfirmField =>
      'Введите email учётной записи для подтверждения';

  @override
  String get accountDeleteMfaHint =>
      'У этой учётной записи включена двухфакторная аутентификация, поэтому нужен ещё один код.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Этот email не совпадает с текущей учётной записью.';

  @override
  String get accountDeleteAction => 'Навсегда удалить мою учётную запись';

  @override
  String get accountDeleteDoneTitle => 'Ваша учётная запись удалена';

  @override
  String get accountDeleteDoneBody =>
      'Ваша учётная запись и её данные удалены навсегда, выход выполнен на всех устройствах. Спасибо, что пользовались Origo X.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Закрыв это окно, откройте Настройки Apple Account > Вход и безопасность > Вход через Apple > Origo X и выберите «Прекратить использовать вход через Apple».';

  @override
  String get accountDeleteDoneClose => 'Закрыть';

  @override
  String get bookSourceDetailsTitle => 'Сведения о книге';

  @override
  String get bookSourceDetailsDescription => 'Об этой книге';

  @override
  String get bookSourceDetailsNoDescription =>
      'Источник не предоставил описание.';

  @override
  String get bookSourceDetailsLatestChapter => 'Последняя глава';

  @override
  String get bookSourceDetailsLoadFailed =>
      'Не удалось загрузить полные сведения. Повторите попытку или читайте с доступной информацией.';

  @override
  String get bookSourceDetailsOnShelf => 'На полке';

  @override
  String get bookSourceDetailsAddFailed =>
      'Не удалось добавить книгу на полку. Попробуйте снова.';

  @override
  String get bookSourceDetailsReadFailed =>
      'Не удалось открыть книгу. Попробуйте снова.';

  @override
  String get appTextSize => 'Размер текста интерфейса';

  @override
  String get appTextSizeDescription =>
      'Меняет только меню и элементы управления приложения, но не текст чтения.';

  @override
  String get appTextSizePreview =>
      'Меню и настройки будут использовать этот размер текста.';

  @override
  String get appTextSizeDefault => '100% (по умолчанию)';

  @override
  String get bookSourceTrackUpdatesTitle => 'Обновления и скачанный текст';

  @override
  String get bookSourceTrackUpdatesBody =>
      'У скачанных книг сохраняется источник. Проверяйте наличие новых глав, чтобы дополнить содержимое, или обновляйте скачанные главы, сохраняя ваши правки и историю.';

  @override
  String get bookSourceCheckNewChapters => 'Проверить новые главы';

  @override
  String get bookSourceRefreshDownloaded => 'Обновить скачанные главы';

  @override
  String get bookSourceNoNewChapters =>
      'В каталоге нет новых глав. Обновите скачанные главы, чтобы проверить более ранний текст на изменения.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return 'Добавлено глав: $added, обновлено: $refreshed';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Перед продолжением обновлений подтвердите последнюю уже скачанную главу. Существующий текст будет сохранён.';

  @override
  String get bookSourceSelectBoundary => 'Подтвердите скачанные главы';

  @override
  String get bookSourceBoundaryHelp =>
      'Выберите последнюю главу источника, вошедшую в ваш локальный текст. Будут добавлены только более поздние главы; существующий текст останется без изменений.';

  @override
  String get bookSourceTrackingEstablished =>
      'Граница отслеживания сохранена. Теперь можно проверять новые главы.';

  @override
  String get bookSourceMappingChanged =>
      'Источник изменил порядок глав или идентификаторы. Подтвердите скачанные главы заново. Существующий текст сохранён.';

  @override
  String get bookSourceContentConflicts => 'Изменения текста требуют проверки';

  @override
  String get bookSourceContentConflictBody =>
      'Эти главы изменили и вы, и источник. Активной остаётся ваша версия. Сравните и выберите, что читать; обе версии остаются в истории.';

  @override
  String get bookSourceCompareVersions => 'Сравнить текст';

  @override
  String get bookSourceLocalVersion => 'Мой текст';

  @override
  String get bookSourceRemoteVersion => 'Текст источника';

  @override
  String get bookSourceBaselineVersion => 'Скачанная базовая версия';

  @override
  String get bookSourceKeepLocal => 'Сохранить мой текст';

  @override
  String get bookSourceUseRemote => 'Взять текст источника';

  @override
  String get bookSourceUpdateFailed =>
      'Обновление не завершилось. Ваш текст сохранён. Повторите попытку.';

  @override
  String get cloudSyncReadableStorage =>
      'Изменённые книги загружаются как полные файлы. Неизменённые книги повторно не передаются. Прогресс чтения синхронизируется отдельно.';

  @override
  String get bookSourceBindSource => 'Привязать источник книг';

  @override
  String get bookSourceNotBound => 'Источник не привязан';

  @override
  String get bookSourceDownloadedUnchanged => 'Скачанные главы актуальны.';

  @override
  String get premiumSyncFailed =>
      'Статус членства не удалось синхронизировать. Повтор произойдёт автоматически; сбой соединения не отзывает подтверждённый доступ.';

  @override
  String get premiumGrantedAccess =>
      'У вас бесплатный доступ Premium. Дополнительная покупка не требуется.';

  @override
  String get premiumOtherChannelAccess =>
      'У вас есть Premium через другой канал. Дополнительная покупка не требуется.';

  @override
  String get premiumAppleAccess =>
      'У вас есть Premium через App Store. Дополнительная покупка не требуется.';

  @override
  String get premiumExistingAccess =>
      'У вас уже есть Premium. Дополнительная покупка не требуется.';

  @override
  String get premiumSyncPending => 'Синхронизация статуса членства';

  @override
  String get cloudSyncExportBook => 'Экспортировать полный файл в облако';

  @override
  String get cloudSyncExportDone => 'Полный файл экспортирован';

  @override
  String get cloudSyncDiagnostics => 'Скопировать диагностику синхронизации';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Эта папка относится к старому формату синхронизации. Выберите новую пустую папку. Локальные книги и существующие облачные файлы будут сохранены.';

  @override
  String get cloudSyncSettings => 'Настройки синхронизации';

  @override
  String get cloudSyncSettingsHint =>
      'Автоматическая синхронизация, другие данные и подключение';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Синхронизировать позиции чтения без загрузки файлов книг';

  @override
  String get cloudSyncProgressExplanation =>
      'Если книга есть на обоих устройствах, можно синхронизировать только прогресс чтения. На новом телефоне всё равно нужна читаемая копия; записи прогресса не содержат текст книги.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Загрузка и скачивание книг; правки загружаются целиком';

  @override
  String get cloudSyncOtherDataHint =>
      'Библиотека, источники, закладки, заметки и настройки чтения';

  @override
  String get cloudSyncActivityHint =>
      'Прогресс, статус файлов и подробности сбоев';

  @override
  String get cloudSyncNeedsAttention =>
      'Проблема синхронизации требует внимания';

  @override
  String get cloudSyncFileStatus => 'Обновления и конфликты';

  @override
  String get cloudSyncTransferGuide => 'Переезд на новый телефон';

  @override
  String get cloudSyncTransferGuideHint =>
      'Восстановление книг и прогресса чтения на новом телефоне';

  @override
  String get cloudSyncTransferIntro =>
      'Загрузка книги необязательна для синхронизации прогресса. Облачная копия нужна, только если на новом телефоне нет книги и вы хотите скачать её отсюда.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Синхронизируйте прогресс на старом телефоне';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Выйдите из читалки, чтобы сохранить последнюю позицию, включите «Прогресс чтения» и нажмите «Синхронизировать». Используйте одинаковые подключение WebDAV и папку синхронизации на обоих телефонах.';

  @override
  String get cloudSyncTransferHasBook => '2. На новом телефоне книга уже есть';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Импортируйте тот же локальный файл или откройте ту же онлайн-книгу из того же источника. Синхронизируйте прогресс и откройте книгу, чтобы продолжить. Совпадения названий сами по себе не гарантируют совпадения книг.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. Новому телефону нужен файл книги';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'На старом телефоне откройте «Файлы книг», разрешите загрузку и выберите книгу. После успешной загрузки синхронизируйте новый телефон и скачайте книгу из раздела «Доступны». Можно также передать тот же файл самостоятельно.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Если вы редактировали текст на старом телефоне, загрузите эту версию через «Файлы книг» и скачайте на новом, чтобы сохранить идентичность книги. Позиции чтения могут неверно соотноситься между разными версиями текста.';

  @override
  String get cloudSyncFrequency => 'Частота автоматической синхронизации';

  @override
  String get cloudSyncFrequencyOff => 'Выключено (только вручную)';

  @override
  String get cloudSyncFrequencyOnChange => 'После изменений';

  @override
  String get cloudSyncFrequency15Minutes => 'Каждые 15 минут';

  @override
  String get cloudSyncFrequencyHourly => 'Каждый час';

  @override
  String get cloudSyncFrequencyDaily => 'Раз в день';

  @override
  String get cloudSyncFrequencyHint =>
      'Интервалы отсчитываются после успешной автоматической синхронизации. Если приложение не запущено, оно догонит при следующем открытии. Неудачные попытки повторяются. «Синхронизировать» работает сразу.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Автоматическая синхронизация: $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'Прогресс получается с выбранной частотой. Открытие книги возобновляет с последней синхронизированной позиции. Если нужен самый свежий прогресс, сначала нажмите «Синхронизировать».';

  @override
  String get readerChapterProgressTitle => 'Прогресс по главам';

  @override
  String get readerChapterProgressHidden => 'Скрыто';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return 'Глав: $chapter/$total';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return 'Впереди глав: $count';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'Пробный период Premium истекает $date.';
  }

  @override
  String get premiumTrialTitle => 'Пробный период Premium';

  @override
  String get bookSourceCheckUpdates => 'Проверить обновления';

  @override
  String get bookSourceUpdates => 'Обновления книг';

  @override
  String get bookSourceNotChecked => 'Ещё не проверено';

  @override
  String get bookSourceUpToDate => 'Каталог актуален';

  @override
  String get bookSourceUpdatesAvailable => 'Доступны новые главы';

  @override
  String get bookSourceNeedsMapping => 'Подтвердите, где продолжить';

  @override
  String bookSourceLastChecked(String time) {
    return 'Последняя проверка: $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Последнее обновление: $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown => 'Время обновления неизвестно';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Последняя: $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Пока открыта библиотека, каталоги проверяются каждые 30 минут. Проверить вручную можно в любой момент. Онлайн-книги используют последний каталог; локальные книги TXT скачивают новые главы, только когда вы решите продолжить. После привязки или смены источника подтвердите последнюю главу, уже находящуюся в локальном файле. Обновления не заменяют ваш исходный текст. Время обновления предоставляется источником или фиксирует момент первого обнаружения новой главы.';

  @override
  String get bookSourceBindHelp =>
      'Найдите эту книгу в ваших источниках, чтобы добавить обложку и включить смену источника и обновление глав. Локальный текст и позиция чтения сохраняются.';

  @override
  String get bookSourceContinueUpdate => 'Скачать новые главы';

  @override
  String get settingsCloseReaderToLibraryTitle =>
      'Close reader to return to library';

  @override
  String get settingsCloseReaderToLibrarySubtitle =>
      'When a book is open, the window close button returns to the main window instead of quitting the app';

  @override
  String get navMe => 'Моё';

  @override
  String get settingsPreferencesTitle => 'Настройки';

  @override
  String get settingsPreferencesSubtitle => 'Оформление, чтение, язык';

  @override
  String get settingsManagementTitle => 'Настройки и управление';

  @override
  String get settingsDataSyncSubtitle => 'Резервное копирование WebDAV, кэш';

  @override
  String get settingsContentServicesTitle => 'Контент и сервисы';

  @override
  String get settingsContentServicesSubtitle => 'Источники, ИИ, чтение вслух';

  @override
  String get settingsAboutSupportSubtitle => 'Версия, обновления, открытый код';

  @override
  String get settingsPremiumSubtitle =>
      'Дополнительные источники и доступ к частной сети';

  @override
  String get settingsGuestTitle => 'Вход не выполнен';

  @override
  String get settingsGuestSubtitle =>
      'Для чтения на устройстве аккаунт не нужен';

  @override
  String get settingsWebDavConfigured =>
      'Резервное копирование WebDAV настроено';

  @override
  String get settingsPremiumActive => 'Премиум активен';

  @override
  String get settingsPremiumSyncFailed =>
      'Не удалось синхронизировать подписку';

  @override
  String get settingsWebDavWorking => 'WebDAV выполняет операцию';

  @override
  String get storeReaderLockedTitle => 'Купить базовую версию';

  @override
  String get storeReaderLockedBody =>
      'Для чтения в этой версии из магазина нужен действующий пробный период или покупка базовой версии. Ваши книги и заметки сохранятся. Вернитесь на книжную полку, чтобы экспортировать данные.';

  @override
  String get storeReaderUnlock => 'Попробовать, купить или восстановить';

  @override
  String get storeReaderBack => 'Вернуться на книжную полку';

  @override
  String get storeReaderChecking => 'Проверка доступа к чтению…';

  @override
  String get storeReaderBenefitTitle => 'Базовая версия';

  @override
  String get storeReaderBenefitBody =>
      'Локальное чтение навсегда. Аккаунт Origo не требуется.';

  @override
  String storeTrialStart(int days) {
    return 'Бесплатный пробный период: $days дн.';
  }

  @override
  String storeTrialDetails(int days) {
    return 'Попробуйте локальное чтение $days дней без автоматического списания. Затем один раз купите базовую версию. Книги и заметки сохранятся.';
  }

  @override
  String get storeTrialStarted => 'Пробный период версии из магазина начался.';

  @override
  String get storeTrialExpired =>
      'Пробный период версии из магазина закончился. Совершите разовую покупку, чтобы продолжить, или восстановите существующую покупку.';

  @override
  String storePurchaseButton(String store) {
    return 'Купить базовую версию через $store';
  }

  @override
  String storePurchaseBilling(String store) {
    return 'Разовая покупка базовой версии без автопродления. $store показывает цену и обрабатывает оплату.';
  }

  @override
  String storePurchaseRestoreHelp(String store) {
    return 'Восстановите покупку через использованный аккаунт $store. Вход в Origo и повторная оплата не нужны.';
  }

  @override
  String storePurchaseAccess(String store) {
    return 'Вы уже купили базовую версию через $store. Повторная покупка не требуется.';
  }

  @override
  String get storeRestoreEmpty =>
      'Покупка для восстановления не найдена. Проверьте аккаунт магазина и связанный аккаунт Origo X.';

  @override
  String get basicRestoreEmpty =>
      'Покупка базовой версии не найдена. Проверьте аккаунт магазина.';

  @override
  String get storeGoogleRefundTerms =>
      'Запросите возврат средств через Google Play. После подтверждения возврата будет удалён только доступ, связанный с этой покупкой; независимые права доступа останутся действительными.';

  @override
  String get storeReaderLegacyNotice =>
      'Ваш прежний базовый доступ к чтению сохраняется. Для расширенной совместимости с источниками по-прежнему нужен Premium.';

  @override
  String get storePrivacyPurchaseBody =>
      'Данные проверки магазина и идентификатор аккаунта отправляются на наш сервер для проверки и восстановления доступа. Проверка Google Play включает токен покупки и хешированный идентификатор аккаунта. Мы не получаем данные платёжных карт.';

  @override
  String storeTrialLegacyDetails(int days) {
    return 'Ваш прежний доступ к чтению сохраняется. Пробный период на $days дней не нужен.';
  }

  @override
  String get storeReaderSupportSubtitle =>
      'Попробуйте локальное чтение или один раз купите базовую версию';

  @override
  String get storeBillingUnavailable =>
      'Покупки в магазине пока недоступны. Повторите попытку позже. Ваш текущий доступ не изменится.';

  @override
  String get accountSignInTitle => 'Войти в Origo X';

  @override
  String get accountSignInSubtitle => 'Управляйте аккаунтом и покупками';

  @override
  String accountRegistrationStep(int step) {
    return 'Создание аккаунта · $step / 3';
  }

  @override
  String get accountSetupTitle => 'Настройте аккаунт';

  @override
  String get accountSetupHint => 'Имя и фото можно добавить позже.';

  @override
  String get accountInvalidEmail => 'Введите действительный адрес почты';

  @override
  String get accountCodeFormat => 'Введите 6-значный код из письма';

  @override
  String get accountPasswordRequired => 'Введите пароль';

  @override
  String get accountShowPassword => 'Показать пароль';

  @override
  String get accountHidePassword => 'Скрыть пароль';

  @override
  String accountResendIn(int seconds) {
    return 'Отправить снова через $seconds с';
  }

  @override
  String get accountBackToCode => 'Назад к коду из письма';

  @override
  String get accountAuthorizationTitle => 'Продолжите в браузере';

  @override
  String get accountReopenAuthorization => 'Открыть страницу входа снова';

  @override
  String get accountSignOutHint =>
      'Локальные книги сохранятся. Войдите снова, чтобы проверить права аккаунта.';

  @override
  String get accountDiscardChanges => 'Отменить изменения';

  @override
  String get accountUnsavedChanges => 'Изменения профиля не сохранены.';

  @override
  String get accountAuthorizationExpired =>
      'Запрос на вход истёк. Повторите попытку.';

  @override
  String get purchaseDetailsTitle => 'Сведения о покупке';

  @override
  String get purchaseBenefitsAction => 'Все преимущества';

  @override
  String get purchaseTermsAction => 'Условия и конфиденциальность';

  @override
  String get purchaseAccountCaption => 'Привязано к аккаунту Origo';

  @override
  String get basicBenefitsTitle => 'Полноценное чтение';

  @override
  String get basicEditorialTitle => 'Хорошая книга. По-вашему.';

  @override
  String get basicEditorialSubtitle =>
      'От первой строки до собственных мыслей.';

  @override
  String get basicReadingTab => 'Чтение и оформление';

  @override
  String get basicListeningTab => 'Прослушивание и ИИ';

  @override
  String get basicNotesTab => 'Заметки и копии';

  @override
  String get basicReadingHeadline =>
      'Каждая страница — именно как вам нравится.';

  @override
  String get basicListeningHeadline => 'Ещё один способ войти в хорошую книгу.';

  @override
  String get basicNotesHeadline => 'Сохраните то, что остаётся с вами.';

  @override
  String get basicReadingSummary => 'Форматы · Темы · Шрифты и вёрстка';

  @override
  String get basicListeningSummary =>
      'Голоса устройства · Облачный TTS · ИИ для чтения';

  @override
  String get basicNotesSummary =>
      'Заметки и закладки · Статистика · Копия WebDAV';

  @override
  String get premiumEditorialTitle => 'Расширьте возможности чтения.';

  @override
  String get premiumEditorialSubtitle =>
      'Больше источников для любознательных читателей.';

  @override
  String get basicReadingTitle => 'Чтение разных форматов';

  @override
  String get basicReadingBody =>
      'Читайте TXT, EPUB, PDF и другие форматы. Импортируйте книги с оглавлением и закладками, выбирайте способы перелистывания, режим чтения без отвлечений и развороты на планшете.';

  @override
  String get basicFormatNote =>
      'Поддержка форматов зависит от платформы; книги с DRM не поддерживаются.';

  @override
  String get basicAppearanceTitle => 'Темы и шрифты';

  @override
  String get basicAppearanceBody =>
      'Настраивайте темы и фон, импортируйте шрифты и точно регулируйте размер, интервалы, поля и абзацы.';

  @override
  String get basicTtsTitle => 'Чтение вслух и прослушивание';

  @override
  String get basicTtsBody =>
      'Слушайте голосами устройства, регулируйте скорость и ставьте таймер сна.';

  @override
  String get basicCloudTtsTitle => 'Облачный TTS';

  @override
  String get basicCloudTtsBody =>
      'Настраивайте облачные голосовые сервисы, выбирайте модели и голоса и сохраняйте несколько профилей.';

  @override
  String get basicAiTitle => 'ИИ-помощник для чтения';

  @override
  String get basicAiBody =>
      'Подключите свой ИИ-сервис, задавайте вопросы во время чтения и лучше понимайте текст.';

  @override
  String get basicNotesTitle => 'Заметки и история чтения';

  @override
  String get basicNotesBody =>
      'Ищите по тексту, сохраняйте закладки, выделения и заметки, смотрите статистику и экспортируйте данные чтения.';

  @override
  String get basicSourcesTitle => 'Открытые источники книг';

  @override
  String get basicSourcesBody =>
      'Импортируйте совместимые источники ORSP для поиска и чтения онлайн. Приложение не предоставляет адреса источников или книги.';

  @override
  String get basicSyncTitle => 'Библиотека и резервные копии';

  @override
  String get basicSyncBody =>
      'Управляйте локальной библиотекой и создавайте или восстанавливайте резервные копии книг, данных чтения и настроек через WebDAV.';

  @override
  String get basicServicesNote =>
      'Для ИИ и облачного TTS нужны ваши собственные сервисы; сторонние платежи не включены.';

  @override
  String get basicEditionTitle => 'Базовая версия';

  @override
  String get basicEditionSummary => 'Одна покупка. Полноценное чтение.';

  @override
  String get basicEditionNoAccount => 'Вход в Origo не требуется';

  @override
  String get premiumEditionSummary =>
      'Расширенные возможности. Больше форматов источников.';

  @override
  String get storeReaderLicenseTitle => 'Купить базовую версию';

  @override
  String get storeReaderLicenseSubtitle =>
      'Попробуйте локальное чтение 14 дней, затем один раз купите базовую версию.';

  @override
  String get storeReaderLifetimeTitle => 'Базовая версия';

  @override
  String storeReaderOwned(String store) {
    return 'Базовая версия куплена через $store.';
  }

  @override
  String get storePremiumPrerequisiteTitle => 'Сначала купите базовую версию';

  @override
  String get storePremiumPrerequisiteBody =>
      'Premium продаётся отдельно после покупки базовой версии. Пробного доступа недостаточно.';

  @override
  String get storePremiumPriceCaption =>
      'Premium навсегда · привязан к аккаунту Origo';

  @override
  String storePremiumPurchaseButton(String store) {
    return 'Купить Premium через $store';
  }

  @override
  String storePremiumBilling(String store) {
    return 'Premium приобретается отдельно разовым платежом без автопродления. $store показывает цену и обрабатывает оплату. Premium привязывается к текущему аккаунту Origo.';
  }

  @override
  String storePremiumRestoreHelp(String store) {
    return 'Войдите в привязанный аккаунт Origo и восстановите Premium через аккаунт $store, использованный при покупке. Повторного списания не будет.';
  }

  @override
  String storeReaderTrialExpiresAt(String date) {
    return 'Пробный период базовой версии заканчивается $date.';
  }

  @override
  String get storeReaderPurchaseSuccess => 'Базовая версия куплена';

  @override
  String get storeReaderRestoreSuccess =>
      'Покупка базовой версии восстановлена';

  @override
  String get storeReaderTestPurchaseVerified =>
      'Тестовая покупка базовой версии подтверждена; постоянная лицензия не выдана.';

  @override
  String get storeReaderPurchaseRevoked => 'Покупка базовой версии отозвана.';

  @override
  String storeReaderPendingApproval(String store) {
    return 'Ожидание одобрения $store. Базовая версия активируется после проверки.';
  }

  @override
  String get storeReaderVerifying => 'Проверка покупки базовой версии…';

  @override
  String get storeReaderRestoring => 'Восстановление покупки базовой версии…';
}
