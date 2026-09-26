// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Origo X';

  @override
  String get home => 'Início';

  @override
  String get library => 'Estante';

  @override
  String get bookSources => 'Fontes';

  @override
  String get discover => 'Descobrir';

  @override
  String get discoverRecommended => 'Para você';

  @override
  String get discoverCategories => 'Categorias';

  @override
  String get discoverLatest => 'Novidades';

  @override
  String get discoverLoadFailed =>
      'Não foi possível carregar o conteúdo de descoberta';

  @override
  String get discoverRetry => 'Tentar novamente';

  @override
  String get discoverEmptyTitle => 'Nada para mostrar ainda';

  @override
  String get discoverEmptyMessage =>
      'Esta seção ainda não tem conteúdo para exibir.';

  @override
  String get discoverUnsupportedTitle =>
      'As fontes atuais não suportam esta seção';

  @override
  String discoverUnsupportedMessage(String capability) {
    return 'É necessária uma fonte com a funcionalidade $capability. As fontes existentes ainda podem ser pesquisadas.';
  }

  @override
  String get discoverCategoryEmpty =>
      'Ainda não há livros para mostrar nesta categoria.';

  @override
  String get bookSourceChannelLoadFailed => 'Não foi possível carregar o canal';

  @override
  String bookSourceChannelLoadFailedMessage(String details) {
    return 'A fonte não retornou livros utilizáveis: $details';
  }

  @override
  String get bookSourceConnectionFailed =>
      'Não foi possível conectar ao servidor da fonte após tentar os endereços de rede disponíveis. Tente novamente mais tarde.';

  @override
  String get bookSourceRedirectFailed =>
      'O site da fonte ficou redirecionando continuamente. Os cookies do site foram mantidos, mas o endereço ainda não retornou conteúdo.';

  @override
  String bookSourceHttpFailed(int status) {
    return 'O site da fonte retornou HTTP $status. O endereço do canal pode estar desatualizado ou bloqueado pelo site.';
  }

  @override
  String get bookSourceStandardLayout => 'Layout padrão';

  @override
  String get bookSourceListLayout => 'Layout em lista';

  @override
  String get bookSourceChangeChannel => 'Alterar';

  @override
  String get bookSourceChangeSourceTitle => 'Alterar fonte';

  @override
  String get bookSourceChangeCurrentSource => 'Fonte atual';

  @override
  String get bookSourceChangeTargetSource => 'Alterar para';

  @override
  String get bookSourceChangeNotSelected => 'Nenhuma selecionada';

  @override
  String bookSourceChangeCurrentChapter(int chapter) {
    return 'No capítulo $chapter';
  }

  @override
  String get bookSourceChangeSearchLabel =>
      'Encontrar este livro em outras fontes';

  @override
  String get bookSourceChangeSearchAgain => 'Pesquisar novamente';

  @override
  String get bookSourceChangeSearchRemaining =>
      'Pesquisar todas as fontes restantes';

  @override
  String get bookSourceChangeCheckAuthor => 'Corresponder autor';

  @override
  String bookSourceChangeSearchProgress(int completed, int total) {
    return 'Verificadas $completed de $total';
  }

  @override
  String get bookSourceChangeNoOtherSources => 'Nenhuma outra fonte disponível';

  @override
  String get bookSourceChangeNoOtherSourcesHint =>
      'Adicione e ative outra fonte com suporte a pesquisa primeiro.';

  @override
  String get bookSourceChangeSearching => 'Localizando outras fontes';

  @override
  String get bookSourceChangeSearchingHint =>
      'As correspondências aparecem conforme cada fonte termina a pesquisa.';

  @override
  String get bookSourceChangeNoMatches =>
      'Nenhuma fonte correspondente encontrada';

  @override
  String get bookSourceChangeNoMatchesHint =>
      'Edite o título ou desative a correspondência de autor e pesquise novamente.';

  @override
  String bookSourceChangeFailedSources(int count) {
    return '$count solicitação(ões) de fonte falharam. Você pode pesquisar novamente.';
  }

  @override
  String get bookSourceChangeAuthorDifferent => 'Autor diferente';

  @override
  String get bookSourceChangeValidating =>
      'Verificando o catálogo e o capítulo atual…';

  @override
  String bookSourceChangeValidationFailed(String details) {
    return 'Falha na validação: $details';
  }

  @override
  String get bookSourceChangeReadable => 'Capítulo atual legível';

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
      'Selecione para verificar o catálogo e o capítulo atual.';

  @override
  String get bookSourceChangeAlreadyOnShelf =>
      'Esta versão da fonte já está na estante.';

  @override
  String get bookSourceChangeSwitching => 'Alterando fonte…';

  @override
  String get bookSourceChangeSwitchAction => 'Alterar para esta fonte';

  @override
  String bookSourceChangeSuccess(String source) {
    return 'Fonte alterada para $source';
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
    return '$count canais';
  }

  @override
  String get bookSourceManagementTitle => 'Gerenciar fontes';

  @override
  String get bookSourceManagementSubtitle =>
      'Adicione, ative, remova e inspecione provedores de conteúdo. A descoberta continua focada em encontrar livros.';

  @override
  String get settingsContentSourcesTitle => 'Fontes de conteúdo';

  @override
  String get settingsContentSourcesSubtitle =>
      'Adicione, ative ou remova fontes de livros abertas';

  @override
  String get bookSourcesSubtitle =>
      'Conecte fontes abertas e pesquise conteúdo legível entre provedores';

  @override
  String get bookSourcesAdd => 'Adicionar fonte';

  @override
  String get bookSourcesSearchHint =>
      'Pesquisar nas fontes ativadas por título ou autor';

  @override
  String get bookSourcesSearch => 'Pesquisar';

  @override
  String get bookSourcesLoadMore => 'Carregar mais';

  @override
  String bookSourcesFailedCount(int count) {
    return '$count solicitação(ões) de fonte falharam';
  }

  @override
  String get bookSourcesSearchSettingsTooltip => 'Configurações de pesquisa';

  @override
  String get bookSourcesSearchSettingsTitle => 'Configurações de pesquisa';

  @override
  String get bookSourcesSearchConcurrencyLabel => 'Solicitações simultâneas';

  @override
  String get bookSourcesSearchTimeoutLabel => 'Tempo limite por fonte (s)';

  @override
  String get bookSourcesSearchSourceLimitLabel => 'Limite de fontes';

  @override
  String get bookSourcesSearchSourceLimitDescription =>
      'Quando muitas fontes estão ativadas, apenas esta quantidade (na ordem da lista) é pesquisada por vez, para limitar o uso de rede e bateria.';

  @override
  String bookSourcesSearchSourceLimitWarning(int enabledCount, int limit) {
    return '$enabledCount fontes estão ativadas, acima do limite atual de $limit. Fontes além do limite não serão pesquisadas.';
  }

  @override
  String get bookSourcesSearchResetDefaults => 'Restaurar padrões';

  @override
  String get bookSourcesSearchPrompt =>
      'Adicione e ative uma fonte para pesquisá-la aqui';

  @override
  String get bookSourcesNoResults => 'Nenhum livro correspondente encontrado';

  @override
  String get bookSourcesNoSourcesTitle => 'Ainda não há fontes';

  @override
  String get bookSourcesNoSourcesDescription =>
      'Cole o endereço de um serviço compatível com o Origo Source Protocol.';

  @override
  String get bookSourcesManageTitle => 'Fontes conectadas';

  @override
  String get bookSourcesEnabled => 'Ativada';

  @override
  String get bookSourcesDisabled => 'Desativada';

  @override
  String get bookSourcesRunnable => 'Pronta para usar';

  @override
  String get bookSourcesPendingCompatibility => 'Sem regras executáveis';

  @override
  String get bookSourcesRequiresLogin => 'Requer login';

  @override
  String get bookSourcesManagementSearchHint =>
      'Pesquisar nome, URL, notas ou grupo';

  @override
  String get bookSourcesClearSearch => 'Limpar pesquisa';

  @override
  String get bookSourcesAllGroups => 'Todos os grupos';

  @override
  String get bookSourcesChooseGroup => 'Escolha um grupo de fontes';

  @override
  String get bookSourcesSearchGroups => 'Grupos de fontes';

  @override
  String get bookSourcesNoMatchingSources =>
      'Nenhuma fonte corresponde à pesquisa e aos filtros atuais';

  @override
  String get bookSourcesResetFilters => 'Redefinir';

  @override
  String bookSourcesVisibleCount(int visible, int total) {
    return 'Exibindo $visible de $total';
  }

  @override
  String get bookSourcesRemove => 'Remover';

  @override
  String get bookSourcesRemoveTitle => 'Remover fonte';

  @override
  String get bookSourcesRemoveMessage =>
      'Isto remove apenas a configuração da fonte. Os livros locais não são afetados.';

  @override
  String get bookSourcesCancel => 'Cancelar';

  @override
  String get bookSourcesConfirm => 'Confirmar';

  @override
  String get bookSourcesAddTitle => 'Adicionar fonte';

  @override
  String get bookSourcesImportLink => 'Importar link';

  @override
  String get bookSourcesAnalyze => 'Ler fontes';

  @override
  String get bookSourcesDetectedOrsp => 'Detectado: ORSP';

  @override
  String get bookSourcesDetectedAdditional => 'Detectado: Reading Source';

  @override
  String get bookSourcesProtocolGroupOrsp => 'Fontes ORSP';

  @override
  String get bookSourcesProtocolGroupAdditional =>
      'Fontes de outros protocolos';

  @override
  String get bookSourcesAdvancedFeatureRequired =>
      'Esta fonte não está disponível para a conta ou as configurações atuais.';

  @override
  String get bookSourcesNoWorkingSources =>
      'Nenhuma fonte passou na verificação de pesquisa em tempo real. Nada foi importado.';

  @override
  String bookSourcesVerificationProgress(
    int completed,
    int total,
    int available,
  ) {
    return 'Verificadas $completed/$total; $available funcionando';
  }

  @override
  String get bookSourcesSelect => 'Selecionar fontes';

  @override
  String get bookSourcesSelectAll => 'Selecionar tudo';

  @override
  String get bookSourcesClearSelection => 'Limpar seleção';

  @override
  String get bookSourcesEnableSelected => 'Ativar selecionadas';

  @override
  String get bookSourcesDisableSelected => 'Desativar selecionadas';

  @override
  String get bookSourcesExportSelected => 'Exportar selecionadas';

  @override
  String bookSourcesExportSuccess(int count, String location) {
    return '$count fonte(s) exportada(s) para $location';
  }

  @override
  String get bookSourcesExportFailed =>
      'Não foi possível exportar as fontes selecionadas';

  @override
  String get bookSourcesExportUnsupported =>
      'A exportação de fontes ainda não é suportada nesta plataforma';

  @override
  String get bookSourcesExportReplaceTitle => 'Substituir arquivo existente?';

  @override
  String bookSourcesExportReplaceMessage(String path) {
    return 'Já existe um arquivo em $path. Substituir?';
  }

  @override
  String get bookSourcesExportReplaceAction => 'Substituir';

  @override
  String get bookSourcesDeleteSelected => 'Excluir selecionadas';

  @override
  String bookSourcesDeleteSelectedMessage(int count) {
    return 'Excluir $count fontes selecionadas? Os livros locais não são afetados.';
  }

  @override
  String get bookSourcesCheckSelected => 'Verificar selecionadas';

  @override
  String bookSourcesHealthCheckSummary(int healthy, int total) {
    return '$healthy de $total fonte(s) estão saudáveis';
  }

  @override
  String get bookSourcesCleanupMenuLabel => 'Verificar e limpar fontes';

  @override
  String get bookSourcesCleanupNoCheckableSources =>
      'Nenhuma fonte para verificar';

  @override
  String bookSourcesCleanupAllFullyAvailable(int count) {
    return 'Todas as $count fonte(s) verificadas estão totalmente disponíveis';
  }

  @override
  String get bookSourcesCleanupReviewTitle => 'Resultados de saúde';

  @override
  String bookSourcesCleanupReviewSummary(
    int fullyAvailable,
    int needsAttention,
  ) {
    return '$fullyAvailable totalmente disponíveis · $needsAttention para revisar';
  }

  @override
  String get bookSourcesCleanupReviewHint =>
      'Funcionalidades ausentes ou um tempo limite não significam que uma fonte é inutilizável. Selecione apenas as fontes que deseja desativar.';

  @override
  String bookSourcesCleanupDisableSelected(int count) {
    return 'Desativar $count selecionada(s)';
  }

  @override
  String bookSourcesCleanupDisabledSummary(int count) {
    return '$count fonte(s) desativada(s)';
  }

  @override
  String bookSourcesCleanupCancelledSummary(int count) {
    return 'Interrompido — $count fonte(s) verificada(s). Execute novamente mais tarde para continuar de onde parou.';
  }

  @override
  String get bookSourcesMaintenanceTitle => 'Manutenção de fontes';

  @override
  String get bookSourcesMaintenanceSubtitle =>
      'Encontre duplicatas e verifique a disponibilidade das fontes';

  @override
  String get bookSourcesMaintenanceHealthTitle =>
      'Verificação de saúde das fontes';

  @override
  String get bookSourcesMaintenanceHealthSubtitle =>
      'Teste pesquisa e leitura; reaproveite resultados saudáveis recentes';

  @override
  String get bookSourcesMaintenanceHealthRunning =>
      'Verificação de saúde das fontes em andamento';

  @override
  String get bookSourcesMaintenanceDedupeTitle => 'Limpeza de duplicatas';

  @override
  String get bookSourcesMaintenanceDedupeSubtitle =>
      'Compare fontes localmente, sem rede';

  @override
  String get bookSourcesMaintenanceReviewTitle =>
      'Último resultado da verificação';

  @override
  String bookSourcesMaintenanceReviewSubtitle(int count) {
    return '$count fonte(s) precisam de atenção';
  }

  @override
  String get bookSourcesMaintenanceSafetyHint =>
      'Apenas as fontes que você confirmar são desativadas. Suas configurações são mantidas.';

  @override
  String get bookSourcesMaintenanceProgressTitle => 'Verificando fontes';

  @override
  String get bookSourcesMaintenanceProgressHint =>
      'Verificando pesquisa, detalhes, catálogos e conteúdo';

  @override
  String get bookSourcesMaintenanceFinishedTitle =>
      'Verificação de saúde concluída';

  @override
  String bookSourcesMaintenanceFinishedSummary(int checked, int attention) {
    return '$checked fonte(s) verificada(s); $attention precisam de atenção';
  }

  @override
  String bookSourcesMaintenanceProgress(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String get bookSourcesMaintenanceStop => 'Interromper verificação';

  @override
  String get bookSourcesMaintenanceBackground => 'Continuar em segundo plano';

  @override
  String get bookSourcesMaintenanceBackgroundHint =>
      'Feche esta visualização de progresso e a verificação continuará silenciosamente enquanto o app estiver em execução.';

  @override
  String get bookSourcesMaintenanceBackgroundToast =>
      'A verificação de saúde das fontes continua silenciosamente em segundo plano';

  @override
  String get bookSourcesMaintenanceReviewResults => 'Revisar resultados';

  @override
  String bookSourcesMaintenanceRunningMenuLabel(int completed, int total) {
    return 'Manutenção de fontes $completed/$total';
  }

  @override
  String get bookSourcesDedupeMenuLabel => 'Encontrar fontes duplicadas';

  @override
  String get bookSourcesDedupeNone => 'Nenhuma fonte duplicada encontrada';

  @override
  String get bookSourcesDedupeReviewTitle => 'Revisar fontes duplicadas';

  @override
  String bookSourcesDedupeReviewSummary(int groups, int duplicates) {
    return '$groups grupo(s), $duplicates fonte(s) duplicada(s)';
  }

  @override
  String get bookSourcesDedupeReviewHint =>
      'A fonte recomendada é mantida. As duplicatas selecionadas serão desativadas, não excluídas.';

  @override
  String bookSourcesDedupeDisableSelected(int count) {
    return 'Desativar $count selecionada(s)';
  }

  @override
  String bookSourcesDedupeDisabledSummary(int count) {
    return '$count fonte(s) duplicada(s) desativada(s)';
  }

  @override
  String get bookSourcesDedupeModeExact => 'Exata';

  @override
  String get bookSourcesDedupeModeStandard => 'Padrão';

  @override
  String get bookSourcesDedupeModeSite => 'Mesmo site';

  @override
  String get bookSourcesDedupeExactReason => 'Mesma identidade de fonte';

  @override
  String get bookSourcesDedupeCanonicalReason =>
      'Mesmo endereço de fonte normalizado';

  @override
  String get bookSourcesDedupeSiteReason => 'Mesmo site; revisão necessária';

  @override
  String get bookSourcesDedupeRecommended => 'Recomendada';

  @override
  String get bookSourcesDedupeReviewAction => 'Revisar deduplicação';

  @override
  String bookSourcesDedupeImportSummary(int ready, int duplicates, int errors) {
    return '$ready prontas, $duplicates duplicadas, $errors inválidas';
  }

  @override
  String bookSourcesImportTypeSummary(int books, int comics, int unsupported) {
    return '$books livro · $comics quadrinho · $unsupported não executáveis no momento';
  }

  @override
  String get bookSourcesDedupeRestoreDefaults => 'Restaurar recomendações';

  @override
  String get bookSourcesUrlLabel => 'Endereço da fonte';

  @override
  String get bookSourcesUrlHint =>
      'https://example.com ou uma URL de JSON de fonte';

  @override
  String get bookSourcesNoOfficialSourcesNotice =>
      'O Origo X não inclui fontes e não opera, recomenda nem endossa serviços de fontes de terceiros. Cada endereço de fonte é adicionado por você.';

  @override
  String get bookSourcesResponsibilityAck =>
      'Confirmo que estou autorizado a acessar este conteúdo e que não usarei a fonte para burlar login, pagamento, DRM ou outros controles de acesso.';

  @override
  String get bookSourcesConnect => 'Ler e importar';

  @override
  String get bookSourcesConnecting => 'Processando fontes…';

  @override
  String get bookSourcesAdded => 'Fonte adicionada';

  @override
  String get bookSourcesRefresh => 'Atualizar fonte';

  @override
  String get bookSourcesRefreshed => 'Fonte de livros atualizada';

  @override
  String get bookSourcesRefreshFailed =>
      'Não foi possível atualizar esta fonte de livros';

  @override
  String get bookSourcesProtocolTitle => 'Origo Source Protocol';

  @override
  String get bookSourcesInformationTitle => 'Protocolo e informações';

  @override
  String get bookSourcesInformationSubtitle =>
      'Veja o protocolo, links do projeto e informações sobre direitos de conteúdo';

  @override
  String get bookSourcesInformationProtocolSubtitle =>
      'Saiba mais sobre as funcionalidades de fontes suportadas e o protocolo aberto';

  @override
  String get bookSourcesInformationRepositorySubtitle =>
      'Veja o repositório do protocolo no GitHub';

  @override
  String get bookSourcesInformationRightsSubtitle =>
      'Entenda o conteúdo de terceiros e os limites de direitos';

  @override
  String get bookSourcesProtocolDescription =>
      'Um contrato comum para descoberta, pesquisa, detalhes de livros, catálogos e conteúdo de capítulos. Desenvolvedores podem hospedar fontes nativas ou criar adaptadores para conteúdo que estão autorizados a servir.';

  @override
  String get bookSourcesProtocolDetails => 'Ver protocolo';

  @override
  String get bookSourcesProtocolRepository => 'Repositório do protocolo';

  @override
  String get bookSourcesProtocolRepositoryOpen => 'Ver no GitHub';

  @override
  String get bookSourcesProtocolRepositoryOpenFailed =>
      'Não foi possível abrir o repositório do protocolo';

  @override
  String get bookSourcesProtocolDialogTitle =>
      'Protocolo aberto de fontes v1.4';

  @override
  String get bookSourcesProtocolDialogBody =>
      'Uma fonte publica /.well-known/open-reading-source.json e implementa as funcionalidades de Leitura Principal: pesquisa, detalhes do livro, catálogos de capítulos paginados e conteúdo de capítulos. A versão 1.4 mantém a paginação completa do catálogo, exige essas funcionalidades principais e preserva os metadados de operador, contato, licença e declaração de direitos para fontes HTTP(S) públicas que não exigem login.';

  @override
  String get bookSourcesRightsDetails => 'Operador e direitos';

  @override
  String get bookSourcesOperator => 'Operador da fonte';

  @override
  String get bookSourcesContentLicense => 'Licença do conteúdo';

  @override
  String get bookSourcesRightsStatement => 'Declaração de direitos';

  @override
  String get bookSourcesRightsNotProvided => 'Não fornecido por esta fonte';

  @override
  String get bookSourcesRightsUnverifiedNotice =>
      'Estas declarações são fornecidas pelo operador independente da fonte. O Origo X as exibe por transparência, mas não as verifica nem as endossa.';

  @override
  String get bookSourcesContactOperator => 'Contatar operador';

  @override
  String get bookSourcesRightsReport => 'Denúncia de direitos';

  @override
  String get bookSourcesRightsReportOpenFailed =>
      'Não foi possível abrir o formulário de denúncia de direitos';

  @override
  String get bookSourcesClose => 'Fechar';

  @override
  String get sourceLoginTitle => 'Login na fonte';

  @override
  String get sourceLoginInfo => 'Dados de login';

  @override
  String get sourceLoginActions => 'Ações da fonte';

  @override
  String get sourceLoginExtraSettings => 'Configurações adicionais';

  @override
  String get sourceLoginSecureStorageNotice =>
      'Os dados de login ficam no armazenamento seguro do sistema neste dispositivo.';

  @override
  String get sourceLoginNoForm =>
      'Esta fonte não oferece um método de login disponível.';

  @override
  String get sourceLoginBrowserTitle => 'Entrar no site original';

  @override
  String get sourceLoginBrowserNotice =>
      'Conclua o login no navegador e toque em Concluído. Os cookies e o armazenamento local do site serão salvos neste dispositivo.';

  @override
  String get sourceLoginBrowserUnsupported =>
      'O login pelo site está disponível no Android, iPhone, iPad e Mac.';

  @override
  String get sourceLoginBrowserOpen => 'Abrir site para entrar';

  @override
  String get sourceLoginSave => 'Entrar e salvar sessão';

  @override
  String get sourceLoginClear => 'Limpar sessão de login';

  @override
  String get sourceLoginSaved => 'Sessão de login da fonte atualizada';

  @override
  String get sourceLoginCleared => 'Sessão de login da fonte limpa';

  @override
  String sourceLoginFailed(String details) {
    return 'Não foi possível atualizar a sessão de login da fonte: $details';
  }

  @override
  String sourceLoginDiscoveryNotice(String sourceName) {
    return '“$sourceName” oferece login para conteúdo exclusivo de contas.';
  }

  @override
  String get sourceDebugMenuLabel => 'Depuração';

  @override
  String get sourceDebugTitle => 'Depurador de fontes';

  @override
  String get sourceDebugInputHint =>
      'Digite uma palavra-chave de pesquisa ou cole uma URL de livro/catálogo/capítulo';

  @override
  String get sourceDebugRun => 'Executar';

  @override
  String get sourceDebugStop => 'Parar';

  @override
  String get sourceDebugClear => 'Limpar registro';

  @override
  String get sourceDebugEmpty =>
      'Digite uma palavra-chave ou URL e toque em Executar para ver cada etapa de como esta fonte a resolve.';

  @override
  String get sourceDebugCopy => 'Copiar';

  @override
  String get sourceDebugCopied => 'Copiado para a área de transferência';

  @override
  String get sourceHealthMenuLabel => 'Verificar saúde';

  @override
  String get sourceHealthHealthy => 'Saudável';

  @override
  String get sourceHealthPartial => 'Parcialmente com problema';

  @override
  String get bookSourcesFullyAvailable => 'Totalmente disponível';

  @override
  String get sourceHealthTimedOut => 'Tempo limite na verificação';

  @override
  String sourceHealthFailedCapabilities(String capabilities) {
    return 'Com problema: $capabilities';
  }

  @override
  String get sourceHealthCapabilitySearch => 'pesquisa';

  @override
  String get sourceHealthCapabilityDiscover => 'descobrir';

  @override
  String get sourceHealthCapabilityInfo => 'informações do livro';

  @override
  String get sourceHealthCapabilityCatalog => 'catálogo';

  @override
  String get sourceHealthCapabilityContent => 'conteúdo';

  @override
  String get sourceVerificationTitle => 'Verificação de fonte';

  @override
  String get sourceVerificationBrowserHint =>
      'Conclua a verificação do site no navegador seguro e escolha Verificação concluída. O endereço da página e os cookies retornam apenas para esta tarefa de fonte.';

  @override
  String get sourceVerificationCodeHint =>
      'Leia a imagem e digite o código para continuar esta tarefa de fonte.';

  @override
  String get sourceVerificationCodeLabel => 'Código da imagem';

  @override
  String get sourceVerificationSubmit => 'Continuar';

  @override
  String get sourceVerificationRetry => 'Abrir navegador novamente';

  @override
  String get sourceVerificationCancel => 'Cancelar verificação';

  @override
  String sourceVerificationFailed(String details) {
    return 'Não foi possível abrir a verificação da fonte: $details';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get reading => 'Leitura';

  @override
  String get importBooks => 'Importar livros';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get accent => 'Cor de destaque';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get notes => 'Notas';

  @override
  String get highlights => 'Destaques';

  @override
  String get ttsReading => 'Texto para fala';

  @override
  String get share => 'Compartilhar';

  @override
  String get shareContent => 'Compartilhar conteúdo';

  @override
  String get shareCurrentPage => 'Compartilhar página atual';

  @override
  String get shareSelectedText => 'Compartilhar texto selecionado';

  @override
  String get shareProgress => 'Compartilhar progresso de leitura';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Parar';

  @override
  String get speed => 'Velocidade';

  @override
  String get pitch => 'Tom';

  @override
  String get language => 'Idioma';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get readingProgress => 'Progresso de leitura';

  @override
  String get totalPages => 'Total de páginas';

  @override
  String get currentPage => 'Página atual';

  @override
  String get readingTime => 'Tempo de leitura';

  @override
  String get booksRead => 'Livros lidos';

  @override
  String get todayReading => 'Leitura de hoje';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Salvar';

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Avançar';

  @override
  String get previous => 'Anterior';

  @override
  String get search => 'Pesquisar';

  @override
  String get noResults => 'Nenhum resultado encontrado';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get initializationFailed => 'Falha na inicialização';

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get appearanceSettings => 'Aparência';

  @override
  String get readingTips => 'Dicas de leitura';

  @override
  String get readingFontSettingsMoved =>
      'Configurações de fonte de leitura movidas';

  @override
  String get readingFontSettingsHint =>
      'Abra qualquer livro, toque no centro da tela e use a barra de ferramentas inferior para ajustar tamanho da fonte, espaçamento entre linhas, espaçamento entre letras, margens e fonte de leitura.';

  @override
  String get readingSettings => 'Configurações de leitura';

  @override
  String get enableTts => 'Ativar texto para fala';

  @override
  String get enableTtsHint => 'Ativar a leitura por texto para fala';

  @override
  String get ttsSpeedLabel => 'Velocidade';

  @override
  String get ttsSpeedHint => 'Ajustar a velocidade de leitura';

  @override
  String get ttsVolumeLabel => 'Volume';

  @override
  String get ttsVolumeHint => 'Ajustar o volume de leitura';

  @override
  String get ttsPitchLabel => 'Tom';

  @override
  String get ttsPitchHint => 'Ajustar o tom de leitura';

  @override
  String get appSettings => 'Configurações do app';

  @override
  String get appFont => 'Fonte do app';

  @override
  String get appFontDescription =>
      'Usada pela navegação, botões, configurações e outros textos da interface. Não altera o conteúdo dos livros.';

  @override
  String get readerFont => 'Fonte de leitura';

  @override
  String get readerFontDescription =>
      'Para livros TXT e online. EPUB tem uma configuração de fonte separada.';

  @override
  String get readerFontSelectionDescription =>
      'Escolha a fonte de leitura. EPUB oferece a fonte do livro, a do sistema e as fontes instaladas.';

  @override
  String get readerFontBookPriorityHint =>
      'Usa a fonte incorporada do livro quando disponível; caso contrário, usa a fonte de leitura padrão da plataforma.';

  @override
  String get readerFontOverrideHint =>
      'Substitui as fontes incorporadas pelo editor.';

  @override
  String get fontBookEmbedded => 'Incorporada no livro';

  @override
  String get fontSystem => 'Padrão da plataforma';

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
      'Usa uma fonte de leitura otimizada para a plataforma, com glifos e paginação estáveis.';

  @override
  String get fontSerifDescription =>
      'Tipografia serifada com caráter calmo e editorial para leitura prolongada.';

  @override
  String get fontSansSerifDescription =>
      'Tipografia sem serifa clara, ideal para interfaces compactas e leitura cotidiana.';

  @override
  String get fontMonospaceDescription =>
      'Tipografia monoespaçada, adequada para código, material técnico e layouts focados.';

  @override
  String get fontPreviewText => 'Origo X · Read freely 开卷有益';

  @override
  String get customFonts => 'Minhas fontes';

  @override
  String get customFontsEmpty => 'Ainda não há fontes personalizadas';

  @override
  String get customFontsEmptyHint =>
      'Importe um arquivo TTF ou OTF uma vez e use-o na interface do app ou na leitura.';

  @override
  String customFontsCount(int count) {
    return '$count fontes importadas';
  }

  @override
  String get customFontsLocalOnly =>
      'As fontes importadas ficam armazenadas apenas neste dispositivo e não são sincronizadas automaticamente.';

  @override
  String get builtInFonts => 'Fontes integradas';

  @override
  String get onlineFonts => 'Fontes online';

  @override
  String get fontDownload => 'Baixar';

  @override
  String get fontDownloading => 'Baixando…';

  @override
  String get fontDownloaded => 'Baixada';

  @override
  String get fontDownloadFailed =>
      'Falha no download, toque para tentar novamente';

  @override
  String get fontDownloadHint => 'O primeiro uso exige um download online';

  @override
  String fontVariableWeightRange(int min, int max) {
    return 'Peso ajustável $min–$max';
  }

  @override
  String get fontStaticWeight => 'Peso fixo (negrito é sintetizado)';

  @override
  String get fontDeleteDownload => 'Excluir download';

  @override
  String fontDeleteDownloadTitle(String name) {
    return 'Excluir \"$name\" baixada?';
  }

  @override
  String fontDeleteDownloadMessage(String size) {
    return 'Liberará $size de armazenamento. Será baixada novamente na próxima vez que você usar.';
  }

  @override
  String get fontDownloadCancelled => 'Download cancelado';

  @override
  String get fontDownloadNetworkFailed => 'Erro de rede, falha no download';

  @override
  String get fontDownloadInvalid => 'O arquivo de fonte baixado é inválido';

  @override
  String get fontDownloadUnsupported =>
      'O download de fontes online não é suportado nesta plataforma';

  @override
  String get importFont => 'Importar fonte';

  @override
  String get importingFont => 'Importando fonte…';

  @override
  String get customFontImported => 'Fonte importada';

  @override
  String get customFontAlreadyImported =>
      'Esta fonte já foi importada e está pronta para uso';

  @override
  String get customFontApplied => 'Seleção de fonte atualizada';

  @override
  String get customFontAppliedToApp => 'Importada e definida como fonte do app';

  @override
  String get customFontAppliedToReader =>
      'Importada e definida como fonte de leitura';

  @override
  String get customFontImportUnsupported =>
      'A importação permanente de fontes ainda não é suportada nesta plataforma.';

  @override
  String get customFontUnsupportedFormat =>
      'Escolha um arquivo de fonte TTF ou OTF.';

  @override
  String get customFontInvalid =>
      'Este arquivo não é uma fonte válida ou suportada.';

  @override
  String get customFontTooLarge => 'O arquivo de fonte tem mais de 50 MB.';

  @override
  String get customFontReadFailed => 'Não foi possível ler o arquivo de fonte.';

  @override
  String get customFontLoadFailed => 'Não foi possível carregar a fonte.';

  @override
  String get customFontStorageFailed =>
      'Não foi possível salvar a fonte neste dispositivo.';

  @override
  String get customFontUnavailable =>
      'O arquivo de fonte não está disponível. Exclua-o e importe novamente.';

  @override
  String get setAsAppFont => 'Usar como fonte do app';

  @override
  String get setAsReaderFont => 'Usar como fonte de leitura';

  @override
  String get setAsBothFonts => 'Usar para ambos';

  @override
  String get renameFont => 'Renomear fonte';

  @override
  String deleteCustomFontTitle(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get deleteCustomFontMessage =>
      'O arquivo de fonte será removido deste dispositivo.';

  @override
  String get deleteCustomFontInUse =>
      'Esta fonte está em uso no momento. Excluí-la restaurará os ajustes de fonte afetados para os padrões.';

  @override
  String get deleteAndReset => 'Excluir e redefinir';

  @override
  String get settingsTelegramChannel => 'Telegram';

  @override
  String get settingsTelegramSubtitle => 'Canal oficial do Telegram';

  @override
  String get settingsTelegramOpenFailed =>
      'Não foi possível abrir o link do Telegram';

  @override
  String get settingsQqChannel => 'Canal do QQ';

  @override
  String get settingsQqChannelSubtitle => 'Origo X · Origo X';

  @override
  String get settingsQqChannelOpenFailed =>
      'Não foi possível abrir o link de convite do Canal QQ';

  @override
  String get languageSystem => 'Seguir o sistema';

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
  String get fontFamilyLabel => 'Fonte';

  @override
  String get fontSizeLabel => 'Tamanho da fonte';

  @override
  String get readerFontWeightLabel => 'Peso da fonte';

  @override
  String get readerFontWeightLight => 'Leve';

  @override
  String get readerFontWeightRegular => 'Normal';

  @override
  String get readerFontWeightMedium => 'Médio';

  @override
  String get readerFontWeightSemiBold => 'Seminegrito';

  @override
  String get readerFontWeightBold => 'Negrito';

  @override
  String readerFontWeightVariableHint(int min, int max) {
    return 'Os controles de leitura usam cinco níveis legíveis entre 300–700. O intervalo completo real desta fonte é $min–$max.';
  }

  @override
  String get readerFontWeightSyntheticHint =>
      'Os controles de leitura usam cinco níveis entre 300–700. Esta fonte não declara um eixo de peso variável, então o sistema aproxima o resultado, que pode variar por plataforma.';

  @override
  String get readerFontWeightPreview =>
      'Uma página silenciosa leva mais longe · 字里行间';

  @override
  String get lineSpacingLabel => 'Espaçamento entre linhas';

  @override
  String get letterSpacingLabel => 'Espaçamento entre letras';

  @override
  String get textAlignmentLabel => 'Alinhamento do texto';

  @override
  String get textAlignmentNatural => 'Natural';

  @override
  String get textAlignmentJustified => 'Justificado';

  @override
  String get firstLineIndentLabel => 'Recuo da primeira linha';

  @override
  String get paragraphSpacingLabel => 'Espaçamento entre parágrafos';

  @override
  String get pageMarginLabel => 'Margem da página';

  @override
  String get resetDefault => 'Redefinir';

  @override
  String get ttsPanelTitle => 'Texto para fala';

  @override
  String get ttsPreviewEffect => 'Prévia do efeito';

  @override
  String get ttsVolume => 'Volume';

  @override
  String get ttsPitch => 'Tom';

  @override
  String get ttsSpeed => 'Velocidade';

  @override
  String get ttsPreviousSentence => 'Frase anterior';

  @override
  String get ttsNextSentence => 'Próxima frase';

  @override
  String get ttsTimerStop => 'Parar temporizador';

  @override
  String get ttsTimerOff => 'Sem limite';

  @override
  String ttsTimerMinutes(Object minutes) {
    return '$minutes minutos';
  }

  @override
  String get ttsPlaying => 'Reproduzindo';

  @override
  String get ttsPaused => 'Pausado';

  @override
  String get ttsStopped => 'Parado';

  @override
  String get ttsPreviousSentenceFailed =>
      'Falha ao reproduzir a frase anterior';

  @override
  String get ttsNextSentenceFailed => 'Falha ao reproduzir a próxima frase';

  @override
  String get ttsEmptyContentError => 'O conteúdo da página atual está vazio';

  @override
  String get ttsPlaybackFailed => 'Falha na reprodução';

  @override
  String get ttsOperationFailed => 'Falha na operação';

  @override
  String get pageTurningMode => 'Modo de página';

  @override
  String get pageTurningSlide => 'Deslizar horizontal';

  @override
  String get pageTurningScroll => 'Paginação vertical';

  @override
  String get tapZoneSettings => 'Zonas de toque';

  @override
  String get tapZoneNextPage => 'Próxima página';

  @override
  String get tapZonePreviousPage => 'Página anterior';

  @override
  String get tapZoneMenu => 'Menu';

  @override
  String get tapZoneLegend => 'Legenda';

  @override
  String get tapZoneNextChapter => 'Próximo capítulo';

  @override
  String get tapZonePreviousChapter => 'Capítulo anterior';

  @override
  String get tapZoneNone => 'Nenhuma ação';

  @override
  String get tapZoneSettingsHint =>
      'Personalize o que cada uma das nove áreas de toque faz';

  @override
  String get tapZoneChooseAction => 'Escolha uma ação';

  @override
  String get tapZoneMenuRequiredHint =>
      'Toque em uma área para alterar sua ação. Pelo menos uma área deve permanecer como Menu; se todos os Menus forem removidos, a área central volta a ser Menu.';

  @override
  String get tapZoneReset => 'Restaurar padrões';

  @override
  String get highlightColor => 'Cor do destaque';

  @override
  String get highlightPreview => 'Prévia';

  @override
  String get highlightSampleText => 'Este é um texto de exemplo,';

  @override
  String get highlightSampleText2 => 'esta parte será destacada,';

  @override
  String get highlightSampleText3 => 'mostrando o efeito de destaque.';

  @override
  String get colorLightBlue => 'Azul-claro';

  @override
  String get colorRed => 'Vermelho';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorPurple => 'Roxo';

  @override
  String get colorGold => 'Dourado';

  @override
  String get colorOrange => 'Laranja';

  @override
  String get colorYellow => 'Amarelo';

  @override
  String get colorDarkGreen => 'Verde-escuro';

  @override
  String get colorCustom => 'Personalizada';

  @override
  String get noteTypeHighlight => 'Destaque';

  @override
  String get noteTypeUnderline => 'Sublinhado';

  @override
  String get noteTypeNote => 'Nota';

  @override
  String get bookFormatTXT => 'TXT';

  @override
  String get bookFormatEPUB => 'EPUB';

  @override
  String get bookFormatPDF => 'PDF';

  @override
  String get importBook => 'Importar livro';

  @override
  String get importFromFiles => 'Importar de arquivos';

  @override
  String get importNoBooks => 'Nenhum livro importado ainda';

  @override
  String get importSuccess => 'Livro importado com sucesso';

  @override
  String get importFailed => 'Falha na importação';

  @override
  String get importProcessing => 'Processando livro...';

  @override
  String get author => 'Autor';

  @override
  String get progress => 'Progresso';

  @override
  String get continueReading => 'Continuar lendo';

  @override
  String get recentBooks => 'Livros recentes';

  @override
  String get allBooks => 'Todos os livros';

  @override
  String get emptyLibrary => 'A estante está vazia';

  @override
  String get deleteBook => 'Excluir livro';

  @override
  String get deleteBookConfirm =>
      'Tem certeza de que deseja excluir este livro?';

  @override
  String get bookDeleted => 'Livro excluído';

  @override
  String get userAgreement => 'Acordo do usuário';

  @override
  String get acceptAgreement => 'Li e concordo';

  @override
  String get declineAgreement => 'Recusar';

  @override
  String get statsToday => 'Hoje';

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
    return '$count livros';
  }

  @override
  String get statsConsecutiveDays => 'Dias consecutivos';

  @override
  String get statsFocusTime => 'Tempo de foco';

  @override
  String get statsThisWeekTotal => 'Total da semana';

  @override
  String get statsKeepReading => 'Leia todos os dias';

  @override
  String get statsMaxSession => 'Maior sessão';

  @override
  String get statsWeeklyTrend => 'Tendência semanal';

  @override
  String get statsAchievements => 'Conquistas';

  @override
  String get readerToolbarMenu => 'Menu';

  @override
  String get readerToolbarTOC => 'Sumário';

  @override
  String get readerToolbarSettings => 'Configurações';

  @override
  String get readerAddBookmark => 'Adicionar marcador';

  @override
  String get readerAddNote => 'Adicionar nota';

  @override
  String get readerShare => 'Compartilhar';

  @override
  String get bookmarkAdded => 'Marcador adicionado';

  @override
  String get bookmarkRemoved => 'Marcador removido';

  @override
  String get readerNavigationTitle => 'Navegação de leitura';

  @override
  String readerNavigationPosition(int current, int total) {
    return 'Capítulo $current de $total';
  }

  @override
  String get readerSearchChapters => 'Pesquisar capítulos';

  @override
  String get readerBackToCurrentChapter => 'Voltar ao capítulo atual';

  @override
  String get readerCurrentChapter => 'Atual';

  @override
  String get readerCurrentPosition => 'Posição atual';

  @override
  String get readerNoChapterResults => 'Nenhum capítulo correspondente';

  @override
  String get readerNoChapterResultsHint =>
      'Tente outra palavra do título do capítulo.';

  @override
  String get readerNoBookmarks => 'Ainda não há marcadores';

  @override
  String get readerNoBookmarksHint =>
      'Toque no botão de marcador no canto superior direito para salvar seu ponto.';

  @override
  String get readerBookmarkRequiresShelf =>
      'Adicione este livro à estante antes de salvar marcadores';

  @override
  String get themeBlue => 'Azul oceano';

  @override
  String get themeGreen => 'Verde floresta';

  @override
  String get themeOrange => 'Laranja vibrante';

  @override
  String get themeRed => 'Vermelho intenso';

  @override
  String get themeCustom => 'Personalizado';

  @override
  String get tapZoneLeftRight => 'Esquerda/Direita';

  @override
  String get tapZoneLeftCenterRight => 'Esquerda/Centro/Direita';

  @override
  String get homeTagline => 'Leia com beleza';

  @override
  String get homeReadingStatsTitle => 'Estatísticas de leitura';

  @override
  String get homeTodayReadingMoment => 'Momento de leitura de hoje';

  @override
  String homeReadMinutesKeepGoing(int minutes) {
    return 'Leu $minutes minutos, continue assim';
  }

  @override
  String get homeTodayReadingJourneyStart =>
      'Comece sua jornada de leitura hoje';

  @override
  String get homeTodayReadingKeepRhythm =>
      'Você está no ritmo hoje, mantenha o passo';

  @override
  String get homeTodayReadingPrompt => 'Reserve um tempo para ler hoje';

  @override
  String homeTotalReadingHours(String hours) {
    return 'Total de $hours horas de leitura';
  }

  @override
  String get homeWeeklyReading => 'Esta semana';

  @override
  String get homeTotalReading => 'Leitura total';

  @override
  String get homeLibraryCount => 'Livros na estante';

  @override
  String get homeCollectionCount => 'Coleção';

  @override
  String get homeKeyMetrics => 'Métricas principais';

  @override
  String get homeReadingRhythm => 'Ritmo de leitura';

  @override
  String get homeAchievements => 'Conquistas de leitura';

  @override
  String get homeConsecutiveReading => 'Leitura consecutiva';

  @override
  String get homeConsecutiveReadingDesc =>
      'Mantenha um hábito diário de leitura';

  @override
  String get homeFocusDuration => 'Duração do foco';

  @override
  String get homeFocusDurationDesc => 'Maior sessão única de leitura';

  @override
  String get homeWeeklyTotal => 'Total semanal';

  @override
  String get homeWeeklyTotalDesc => 'Tempo de leitura nesta semana';

  @override
  String get homeRecentReading => 'Leitura recente';

  @override
  String get homeWeeklyTrend => 'Tendência de leitura semanal';

  @override
  String homeBarTooltipMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get unitMinute => 'min';

  @override
  String get unitHour => 'hora';

  @override
  String get unitBook => 'livros';

  @override
  String get unitDay => 'dias';

  @override
  String get weekdayMonShort => 'Seg';

  @override
  String get weekdayTueShort => 'Ter';

  @override
  String get weekdayWedShort => 'Qua';

  @override
  String get weekdayThuShort => 'Qui';

  @override
  String get weekdayFriShort => 'Sex';

  @override
  String get weekdaySatShort => 'Sáb';

  @override
  String get weekdaySunShort => 'Dom';

  @override
  String get agreementTagline =>
      'Leitura imersiva · Assistente de AI · Local primeiro';

  @override
  String get agreementCardTitle => 'Acordo de serviço ao usuário';

  @override
  String get agreementCardSubtitle => 'Leia com atenção o texto a seguir';

  @override
  String get agreementWelcomeTitle => 'Bem-vindo ao Origo X';

  @override
  String get agreementWelcomeBody =>
      'Para garantir uma experiência de leitura estável e previsível, leia e concorde primeiro com o acordo a seguir.';

  @override
  String get agreementFeatureFormatsTitle => 'Suporte a vários formatos';

  @override
  String get agreementFeatureFormatsBody => 'EPUB, PDF, TXT, MOBI e mais';

  @override
  String get agreementFeatureCustomizationTitle => 'Leitura personalizada';

  @override
  String get agreementFeatureCustomizationBody =>
      'Personalize fontes, cores, tipografia e mais';

  @override
  String get agreementFeatureSyncTitle => 'Local primeiro';

  @override
  String get agreementFeatureSyncBody =>
      'Livros, progresso e notas ficam no dispositivo que você controla';

  @override
  String get agreementFeatureTtsTitle => 'Texto para fala';

  @override
  String get agreementFeatureTtsBody =>
      'Narração inteligente por voz libera seus olhos para você ouvir em qualquer lugar';

  @override
  String get agreementTapToAgreeHint =>
      'Ao tocar em \"Concordar e continuar\", você confirma que leu e concorda em usar este app';

  @override
  String get agreementExitApp => 'Sair do app';

  @override
  String get agreementAgreeAndContinue => 'Concordar e continuar';

  @override
  String get agreementExitDialogContent =>
      'Se você não concordar com o acordo do usuário, não poderá usar este app. Tem certeza de que deseja sair?';

  @override
  String get agreementConfirmExit => 'Sair';

  @override
  String get readerFileMissing =>
      'Arquivo do livro não encontrado. Importe-o novamente.';

  @override
  String get readerUnsupportedFormat => 'Este formato ainda não pode ser lido.';

  @override
  String get readerKindleDrmProtected =>
      'Este livro Kindle é protegido por DRM e não pode ser lido aqui. Apenas livros sem DRM são suportados.';

  @override
  String get readerComicNoPages =>
      'Nenhuma página de imagem foi encontrada neste arquivo de quadrinhos.';

  @override
  String get readerComicCbrUnsupported =>
      'Este quadrinho CBR usa compressão RAR real e ainda não pode ser lido. Converta-o para CBZ.';

  @override
  String get readerComicArchiveUnsupported =>
      'O formato de arquivo deste quadrinho ainda não pode ser lido. Converta-o para CBZ.';

  @override
  String get readerComicChapterNoPages =>
      'Este capítulo não tem páginas de imagem.';

  @override
  String get imageReaderSettings => 'Configurações de leitura';

  @override
  String get imageReaderDirectionTitle => 'Direção de leitura';

  @override
  String get imageReaderDirectionVertical => 'Vertical contínuo';

  @override
  String get imageReaderDirectionLtr => 'Da esquerda para a direita';

  @override
  String get imageReaderDirectionRtl => 'Da direita para a esquerda (mangá)';

  @override
  String get imageReaderJumpToPage => 'Ir para a página';

  @override
  String get imageReaderBackgroundTitle => 'Fundo da página';

  @override
  String get imageReaderBackgroundBlack => 'Preto';

  @override
  String get imageReaderBackgroundGray => 'Cinza';

  @override
  String get imageReaderBackgroundWhite => 'Branco';

  @override
  String get readerPdfLinuxUnsupported =>
      'A leitura de PDF ainda não está disponível no Linux.';

  @override
  String get bootstrapImageManagerFailed =>
      'Falha ao inicializar o gerenciador de imagens';

  @override
  String homeFocusCompleted(int minutes) {
    return 'Sessão de foco de $minutes minutos concluída. Muito bem!';
  }

  @override
  String get homeDailyReadingGoal => 'Meta diária de leitura';

  @override
  String get homeAiAdviceSection => 'Conselho de leitura com AI';

  @override
  String get homeTodayGlance => 'Hoje em resumo';

  @override
  String get homeViewAll => 'Ver tudo';

  @override
  String get homeGoalDoneSuggestReview =>
      'A meta de hoje está concluída — considere um balanço da leitura';

  @override
  String homeRemainingToGoal(int minutes) {
    return 'Só mais $minutes minutos para alcançar a meta de hoje';
  }

  @override
  String get homePickBookHint =>
      'Escolha um livro da sua estante para continuar e conclua primeiro 1 sessão de foco.';

  @override
  String homeContinueBookHint(String title) {
    return 'Continue \"$title\" primeiro e depois passe para outros livros.';
  }

  @override
  String get homeTodayActionAdvice => 'Plano de ação de hoje';

  @override
  String homeProgressPercent(int percent) {
    return '$percent% de progresso';
  }

  @override
  String homeStreakDays(int days) {
    return '$days dias de sequência';
  }

  @override
  String homeWeekMinutes(int minutes) {
    return '$minutes min nesta semana';
  }

  @override
  String get homePlanLoading => 'Carregando plano';

  @override
  String homeGoalMinutesPerDay(int minutes) {
    return 'Meta: $minutes min/dia';
  }

  @override
  String get homeAiAdviceForYou => 'Conselho de leitura com AI para você';

  @override
  String homeBasedOnBook(String title) {
    return 'Com base em \"$title\"';
  }

  @override
  String get homeTodayReadingMinutesLabel => 'Leitura de hoje (min)';

  @override
  String get homeTotalReadingMinutesLabel => 'Leitura total (min)';

  @override
  String get homeGeneratingPlan => 'Gerando o plano de leitura de hoje...';

  @override
  String get homeCompletedLabel => 'Concluído';

  @override
  String get homeTodayGoalAchieved => 'Meta de hoje alcançada';

  @override
  String homeMinutesRemaining(int minutes) {
    return 'Faltam $minutes minutos';
  }

  @override
  String homeReadOfGoalMinutes(int read, int goal) {
    return '$read / $goal min lidos';
  }

  @override
  String homeSessionsToFinishGoal(int sessions) {
    return 'Cerca de $sessions sessões de foco para concluir a meta de hoje';
  }

  @override
  String get homeStreakLabel => 'Sequência';

  @override
  String get homeWeekAchievedLabel => 'Meta semanal';

  @override
  String get homeFocusLabel => 'Foco';

  @override
  String homeDaysCount(int days) {
    return '$days dias';
  }

  @override
  String homeTimesCount(int times) {
    return '$times vezes';
  }

  @override
  String homeFocusCountdown(String time) {
    return 'Contagem regressiva de foco $time';
  }

  @override
  String get homeGoLibraryRead => 'Ler da estante';

  @override
  String get homeEndFocus => 'Encerrar foco';

  @override
  String homeFocusMinutesButton(int minutes) {
    return 'Foco de $minutes min';
  }

  @override
  String homeAdjustGoalMinutes(int minutes) {
    return 'Ajustar meta: $minutes min';
  }

  @override
  String get homeNoRecentReading =>
      'Ainda não há leitura recente. Abra um livro da sua estante para começar.';

  @override
  String homeReadingProgressPercent(String percent) {
    return 'Progresso $percent%';
  }

  @override
  String get librarySearchHint => 'Pesquisar títulos ou autores';

  @override
  String libraryFilterAll(int count) {
    return 'Todos $count';
  }

  @override
  String libraryFilterReading(int count) {
    return 'Lendo $count';
  }

  @override
  String libraryFilterFinished(int count) {
    return 'Concluídos $count';
  }

  @override
  String get libraryFilterTooltip => 'Filtrar por status de leitura';

  @override
  String get libraryNoMatchingBooks => 'Nenhum livro correspondente';

  @override
  String get libraryNoReadingBooks => 'Nenhum livro em andamento';

  @override
  String get libraryNoFinishedBooks => 'Nenhum livro concluído';

  @override
  String get libraryNoBooks => 'Ainda não há livros';

  @override
  String libraryProgressContinue(int percent) {
    return '$percent% · Continuar lendo';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Página $page';
  }

  @override
  String get libraryStartFromBeginning => 'Começar do início';

  @override
  String get libraryBookInfo => 'Informações do livro';

  @override
  String libraryFormatAndPages(String format, int pages) {
    return '$format · $pages páginas';
  }

  @override
  String libraryFormatAndChapters(String format, int chapters) {
    return '$format · $chapters capítulos';
  }

  @override
  String get libraryRenameBook => 'Renomear';

  @override
  String get libraryRenameBookHint =>
      'Altera o título; o arquivo no disco também é renomeado';

  @override
  String get libraryRenameBookSuccess => 'Renomeado';

  @override
  String get libraryRenameBookFailed => 'Não foi possível renomear o livro';

  @override
  String get libraryCustomCover => 'Capa personalizada';

  @override
  String get libraryCustomCoverHint =>
      'Escolha uma imagem para usar como capa deste livro';

  @override
  String get libraryCustomCoverSuccess => 'Capa atualizada';

  @override
  String get libraryCoverUnsupportedFormat => 'Formato de imagem não suportado';

  @override
  String get libraryCoverFileTooLarge => 'A imagem excede o limite de 20 MB';

  @override
  String get libraryCoverReadFailed =>
      'Não foi possível ler a imagem selecionada';

  @override
  String get libraryCoverSaveFailed => 'Não foi possível salvar a capa';

  @override
  String get libraryResetCover => 'Restaurar capa padrão';

  @override
  String get libraryResetCoverHint =>
      'Remove a capa personalizada e restaura a original';

  @override
  String get libraryResetCoverSuccess => 'Capa padrão restaurada';

  @override
  String get libraryExportBook => 'Exportar arquivo do livro';

  @override
  String get libraryExportOriginalHint =>
      'Copiar o arquivo original para outro local';

  @override
  String get libraryExportDownloadedTxtHint =>
      'Exportar o livro baixado como um arquivo TXT gerado';

  @override
  String bookExportSuccess(String location) {
    return 'Exportado para $location';
  }

  @override
  String get bookExportSourceMissing =>
      'O arquivo do livro está ausente e não pode ser exportado';

  @override
  String get bookExportUnsupported =>
      'A exportação de livros ainda não é suportada nesta plataforma';

  @override
  String get bookExportFailed => 'Não foi possível exportar o livro';

  @override
  String get bookExportInProgress => 'Exportando livro…';

  @override
  String get incomingBooksImporting => 'Importando um livro de outro app…';

  @override
  String get incomingBooksNoBookFile =>
      'O conteúdo compartilhado não contém um arquivo de livro importável';

  @override
  String get incomingBooksPermissionExpired =>
      'O acesso ao arquivo expirou. Compartilhe ou abra o arquivo novamente';

  @override
  String get incomingBooksUnsupportedFormat =>
      'Este formato de livro não é suportado';

  @override
  String get incomingBooksFileTooLarge =>
      'O arquivo excede o limite de importação de 500 MB';

  @override
  String get incomingBooksTooManyFiles =>
      'Muitos arquivos de livros compartilhados de uma vez. Adicione em lotes menores';

  @override
  String get incomingBooksSomeFilesSkipped =>
      'Alguns arquivos não puderam ser reconhecidos; os livros restantes continuarão';

  @override
  String get incomingBooksContentMismatch =>
      'O formato do arquivo não corresponde ao seu conteúdo';

  @override
  String get incomingBooksImportFailed =>
      'Não foi possível importar o livro de outro app';

  @override
  String get libraryDeleteBookHint =>
      'Este livro será excluído permanentemente';

  @override
  String get libraryBookTitle => 'Título';

  @override
  String get libraryFormat => 'Formato';

  @override
  String libraryPagesCount(int pages) {
    return '$pages páginas';
  }

  @override
  String get totalChapters => 'Total de capítulos';

  @override
  String get currentChapter => 'Capítulo atual';

  @override
  String libraryChaptersCount(int chapters) {
    return '$chapters capítulos';
  }

  @override
  String get libraryClose => 'Fechar';

  @override
  String get libraryConfirmDeleteTitle => 'Confirmar exclusão';

  @override
  String libraryDeleteBookMessage(String title) {
    return 'Excluir \"$title\"? O arquivo será removido permanentemente do seu dispositivo.';
  }

  @override
  String libraryDeletingBook(String title) {
    return 'Excluindo \"$title\"...';
  }

  @override
  String libraryBookDeletedToast(String title) {
    return '\"$title\" excluído';
  }

  @override
  String libraryDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get libraryReadingBadge => 'Lendo';

  @override
  String get libraryDeletingBookFile => 'Excluindo arquivo do livro...';

  @override
  String get libraryDeletingCoverImage => 'Excluindo imagem de capa...';

  @override
  String get libraryCleaningDatabase =>
      'Limpando registros do banco de dados...';

  @override
  String get libraryDeleteComplete => 'Exclusão concluída';

  @override
  String get librarySelectMultiple => 'Selecionar vários';

  @override
  String get librarySelectAll => 'Selecionar tudo';

  @override
  String librarySelectedBooks(int count) {
    return '$count selecionados';
  }

  @override
  String libraryDeleteSelected(int count) {
    return 'Excluir $count';
  }

  @override
  String get libraryBatchDeleteTitle => 'Excluir os livros selecionados?';

  @override
  String libraryBatchDeleteMessage(int count) {
    return 'Isto exclui permanentemente os $count livros selecionados, notas e marcadores relacionados e arquivos locais. Não pode ser desfeito.';
  }

  @override
  String libraryDeletingSelected(int done, int total) {
    return 'Excluindo $done/$total';
  }

  @override
  String libraryBatchDeleteSuccess(int count) {
    return '$count livros excluídos';
  }

  @override
  String libraryBatchDeletePartial(int success, int failed) {
    return '$success excluídos; $failed falharam';
  }

  @override
  String get readerPrefaceTitle => 'Páginas preliminares';

  @override
  String get readerModeHorizontalPage => 'Sem animação';

  @override
  String get readerModeVerticalScrollHint =>
      'Deslize verticalmente por páginas pré-paginadas; deslize para os lados para trocar de capítulo';

  @override
  String get readerModeWholeBookScrollHint =>
      'Capítulos pré-paginados formam uma lista vertical navegável';

  @override
  String get readerScrollByChapterTitle => 'Rolar por capítulo';

  @override
  String get readerScrollByChapterOnHint =>
      'Deslize por um capítulo página a página e depois deslize para os lados para trocar de capítulo';

  @override
  String get readerScrollByChapterOffHint =>
      'Todos os capítulos se conectam página a página em uma lista vertical única';

  @override
  String get readerModeHorizontalPageHint =>
      'Toque no lado esquerdo para a página anterior e no lado direito para a próxima página';

  @override
  String get readerModeHorizontalSlideHint =>
      'As páginas seguem seu dedo horizontalmente e se encaixam no lugar';

  @override
  String get readerModeCoverSlide => 'Capa';

  @override
  String get readerModeCoverSlideHint =>
      'A página atual desliza para a esquerda, revelando a próxima página por baixo';

  @override
  String get readerModePageCurl => 'Dobra de página';

  @override
  String get readerModePageCurlHint =>
      'Arraste para os lados para dobrar a página e solte para virar ou voltar';

  @override
  String get readerTextBrightnessLabel => 'Brilho do texto';

  @override
  String get readerDimTextInDarkModeTitle => 'Escurecer texto no modo escuro';

  @override
  String get readerDimTextInDarkModeHint => 'Usar 70% de brilho no modo escuro';

  @override
  String readerFontSizeValue(int size) {
    return 'Tamanho da fonte  $size';
  }

  @override
  String readerHorizontalMarginValue(int margin) {
    return 'Margem horizontal  $margin';
  }

  @override
  String get readerHorizontalMarginLabel => 'Margem horizontal';

  @override
  String get readerTopMarginLabel => 'Margem superior';

  @override
  String get readerBottomMarginLabel => 'Margem inferior';

  @override
  String get readerTxtChapterTitlePageTitle =>
      'Título do capítulo em página própria';

  @override
  String get readerTxtChapterTitlePageHint =>
      'Quando desativado, o título do capítulo aparece acima do corpo do texto';

  @override
  String get readerVerticalMarginLabel => 'Margem vertical';

  @override
  String readerVerticalMarginValue(int margin) {
    return 'Margem vertical  $margin';
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
    return 'Falha ao abrir: $error';
  }

  @override
  String get readerNoContent => 'Este livro não tem conteúdo legível';

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
    return 'Capítulo $chapter/$chapterCount · Rolagem vertical';
  }

  @override
  String get importPreparing => 'Preparando importação...';

  @override
  String importFailedWithError(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get importLocalFile => 'Arquivos locais';

  @override
  String get settingsAiTempHintMinimax =>
      'Temperatura: a MiniMax recomenda 0.01 ~ 1.00';

  @override
  String get settingsAiCustomConfigTitle => 'Configuração personalizada de AI';

  @override
  String settingsAiCurrentProvider(String provider) {
    return 'Provedor atual: $provider';
  }

  @override
  String get settingsAiTempErrorMinimax =>
      'A temperatura da MiniMax deve estar entre 0.01 e 1.00';

  @override
  String get settingsAiTempErrorOutOfRange =>
      'A temperatura está fora do intervalo, siga a dica';

  @override
  String get settingsApply => 'Aplicar';

  @override
  String get settingsAiCustomApplied =>
      'Parâmetros personalizados aplicados, lembre-se de salvar a configuração';

  @override
  String get settingsAiApiKeyRequired => 'A API Key não pode ficar vazia';

  @override
  String get settingsAiModelRequired => 'O modelo não pode ficar vazio';

  @override
  String get settingsAiBaseUrlInvalid =>
      'A Base URL deve ser um endereço http/https válido';

  @override
  String get settingsAiSettingsSaved => 'Configurações de AI salvas';

  @override
  String settingsSaveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get settingsVolumeKeyTurnTitle => 'Virar página com botões de volume';

  @override
  String get settingsVolumeKeyTurnSubtitle =>
      'Usar botões de volume nos modos de leitura paginados';

  @override
  String get settingsAutoResumeReadingTitle => 'Retomar a leitura ao abrir';

  @override
  String get settingsAutoResumeReadingSubtitle =>
      'Se você sair do app enquanto lê, a próxima abertura retorna de onde parou';

  @override
  String get settingsShowStatusBarTitle =>
      'Mostrar barra de status do sistema durante a leitura';

  @override
  String get settingsShowStatusBarOnSubtitle =>
      'Indicadores de bateria/hora do leitor ocultos';

  @override
  String get settingsShowStatusBarOffSubtitle =>
      'Usando indicadores de bateria/hora do leitor';

  @override
  String get readerTopBarStyleTitle => 'Informações do topo';

  @override
  String get readerTopBarStyleSystem => 'Barra de status do sistema';

  @override
  String get readerTopBarStyleSystemHint =>
      'Mostrar hora, sinal e bateria do sistema';

  @override
  String get readerTopBarStyleReader => 'Barra de informações do leitor';

  @override
  String get readerTopBarStyleReaderHint =>
      'Mostrar hora, título do capítulo e bateria';

  @override
  String get readerTopBarStyleFloating => 'Barra de informações flutuante';

  @override
  String get readerTopBarStyleFloatingHint =>
      'Mostrar hora e bateria na área da barra de status sem ocupar espaço de leitura';

  @override
  String get readerTopBarStyleHidden => 'Totalmente imersivo';

  @override
  String get readerTopBarStyleHiddenHint => 'Não mostrar informações no topo';

  @override
  String get settingsAiAssistantTitle => 'Assistente de leitura com AI';

  @override
  String get settingsSystemSettingsTitle => 'Configurações do sistema';

  @override
  String get settingsSectionAppearanceFonts => 'Aparência e fontes';

  @override
  String get settingsSectionDataServices => 'Dados e serviços';

  @override
  String get settingsSectionGeneral => 'Geral';

  @override
  String get settingsSectionAdvancedFeatures => 'Recursos avançados';

  @override
  String get settingsAdditionalSourceProtocolsTitle =>
      'Mais protocolos de fontes';

  @override
  String get settingsAdditionalSourceProtocolsSubtitle =>
      'Ative o suporte a protocolos de fontes adicionais.';

  @override
  String get settingsPrivateBookSourceNetworkTitle =>
      'Permitir fontes em rede privada';

  @override
  String get settingsPrivateBookSourceNetworkSubtitle =>
      'Permite que fontes acessem este dispositivo, a rede local e outros endereços privados. Ativado por padrão com Premium; use apenas fontes confiáveis.';

  @override
  String get additionalSourcesImport => 'Importar mais protocolos de fontes';

  @override
  String get additionalSourcesImportTitle => 'Importar JSON de fontes';

  @override
  String get additionalSourcesImportNotice =>
      'A importação apenas analisa e deduplica localmente; não testa cada fonte online. Fontes com regras executáveis mantêm o estado de ativação da importação, e cada funcionalidade é verificada quando usada.';

  @override
  String get additionalSourcesChooseFile => 'Adicionar de arquivo JSON';

  @override
  String get additionalSourcesUrlLabel => 'URL do JSON de fontes';

  @override
  String get additionalSourcesLoadUrl => 'Carregar URL';

  @override
  String additionalSourcesPreview(int supported, int partial, int unsupported) {
    return '$supported disponíveis, $partial parcialmente suportadas, $unsupported não suportadas';
  }

  @override
  String additionalSourcesPreviewDetails(
    int supported,
    int partial,
    int unsupported,
    int skipped,
  ) {
    return '$supported regra padrão, $partial regra estendida, $unsupported regra avançada, $skipped ignoradas';
  }

  @override
  String additionalSourcesQuickPreview(int count, int skipped) {
    return '$count fontes prontas para importar, $skipped ignoradas';
  }

  @override
  String get additionalSourcesAvailable => 'Disponível';

  @override
  String get additionalSourcesPartial => 'Parcialmente suportado';

  @override
  String get additionalSourcesUnsupported => 'Não suportado';

  @override
  String get additionalSourcesImportConfirm => 'Importar todas';

  @override
  String additionalSourcesImported(int count) {
    return '$count fontes importadas';
  }

  @override
  String additionalSourcesImportedWithConflicts(int count, int conflicted) {
    return '$count fontes importadas; $conflicted ignoradas porque o id já está registrado de outra origem';
  }

  @override
  String get settingsSectionAboutSupport => 'Sobre e suporte';

  @override
  String get settingsKeepScreenOnTitle => 'Manter a tela ligada';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Impedir que a tela desligue durante a leitura';

  @override
  String get settingsPowerSavingModeTitle => 'Modo de economia de energia';

  @override
  String get settingsPowerSavingModeSubtitle =>
      'Limitar o app a 60 fps em vez de usar taxa de atualização alta';

  @override
  String get settingsAutoSaveTitle => 'Salvamento automático';

  @override
  String get settingsAutoSaveSubtitle =>
      'Salvar o progresso de leitura automaticamente';

  @override
  String get settingsHelpPlaceholder =>
      'As informações de ajuda podem ficar aqui';

  @override
  String get settingsAiConfigured => 'AI configurado';

  @override
  String get settingsAiNotConfigured => 'API Key ainda não configurada';

  @override
  String get settingsAiReadyToUse => 'Pronto para usar';

  @override
  String get settingsAiPendingConfig => 'Configuração pendente';

  @override
  String settingsAiCurrentPreset(String preset) {
    return 'Predefinição atual: $preset';
  }

  @override
  String settingsAiCurrentCustom(String model) {
    return 'Configuração atual: personalizado · $model';
  }

  @override
  String get settingsAiPresetIntro =>
      'Provedores e modelos comuns já vêm integrados; geralmente basta escolher uma predefinição e inserir uma API Key.';

  @override
  String get settingsAiProviderLabel => 'Provedor';

  @override
  String get settingsAiCustomProvider => 'Personalizado';

  @override
  String get settingsAiProtocolLabel => 'Protocolo da API';

  @override
  String get settingsAiProtocolOpenAi => 'Compatível com OpenAI';

  @override
  String get settingsAiProtocolAnthropic => 'Anthropic';

  @override
  String get settingsAiPresetHint => 'Selecione um modelo predefinido';

  @override
  String get settingsAiPresetLabel => 'Modelo predefinido';

  @override
  String get settingsAiCustomButton => 'Personalizado';

  @override
  String get settingsAiPresetSelectedHint =>
      'Depois de selecionar uma predefinição, basta inserir uma API Key para começar a usar.';

  @override
  String get settingsAiCustomActiveHint =>
      'Parâmetros personalizados em uso; você pode voltar para uma predefinição a qualquer momento.';

  @override
  String get settingsAiApiKeyHint => 'Digite para ativar a predefinição atual';

  @override
  String get settingsShow => 'Mostrar';

  @override
  String get settingsHide => 'Ocultar';

  @override
  String get settingsAiSaving => 'Salvando...';

  @override
  String get settingsAiSaveConfig => 'Salvar configuração de AI';

  @override
  String get settingsPageIntro =>
      'Apenas as opções que moldam sua experiência de leitura.';

  @override
  String get settingsSupportDevelopmentTitle => 'Apoiar o desenvolvimento';

  @override
  String get firstHomeSupportNow => 'Apoiar agora';

  @override
  String get firstHomeSupportLater => 'Talvez depois';

  @override
  String get firstHomeSupportPaperSemanticLabel =>
      'Uma carta do desenvolvedor do Origo X pedindo apoio voluntário';

  @override
  String get settingsSupportDevelopmentCardTitle => 'Apoiar o desenvolvimento';

  @override
  String get settingsSupportDevelopmentCardSubtitle =>
      'As doações são voluntárias e apoiam o desenvolvimento contínuo.';

  @override
  String get settingsAccountGuestTitle => 'Entrar no Origo X';

  @override
  String get settingsAccountGuestSubtitle =>
      'Sincronize seu perfil e configurações de segurança.';

  @override
  String get settingsAccountOpen => 'Central da conta';

  @override
  String get settingsAccountVerified => 'Conta verificada';

  @override
  String get accountPageTitle => 'Conta';

  @override
  String get accountIntroTitle => 'Conta';

  @override
  String get accountPageSubtitle =>
      'Entre para sincronizar seu perfil e as configurações da conta.';

  @override
  String get accountLoginTab => 'Entrar com e-mail';

  @override
  String get accountRegisterTab => 'Registrar';

  @override
  String get accountCodeTab => 'Código por e-mail';

  @override
  String get accountResetTab => 'Redefinir';

  @override
  String get accountEmail => 'E-mail';

  @override
  String get accountEmailRequired => 'Digite seu endereço de e-mail';

  @override
  String get accountEmailFirstHint =>
      'Digite seu e-mail para continuar. O login com senha é o padrão.';

  @override
  String get accountContinue => 'Continuar';

  @override
  String get accountPasswordLoginTitle => 'Entrar com senha';

  @override
  String get accountPasswordLoginHint =>
      'Digite sua senha ou use um código por e-mail.';

  @override
  String get accountUseEmailCode => 'Entrar com um código por e-mail';

  @override
  String get accountNoAccount => 'Não tem conta? Registrar';

  @override
  String get accountForgotPassword => 'Esqueci a senha';

  @override
  String get accountHaveAccount => 'Já registrado? Voltar ao login';

  @override
  String get accountBackToPassword => 'Voltar ao login com senha';

  @override
  String get accountChangeEmail => 'Alterar';

  @override
  String get accountRegisterHint =>
      'Verifique seu e-mail e crie uma conta e senha.';

  @override
  String get accountCodeLoginHint =>
      'Enviaremos um código para o e-mail selecionado.';

  @override
  String get accountResetHint =>
      'Verifique seu e-mail e escolha uma nova senha.';

  @override
  String get accountPassword => 'Senha';

  @override
  String get accountConfirmPassword => 'Confirmar senha';

  @override
  String get accountAvatarCropTitle => 'Ajustar avatar';

  @override
  String get accountAvatarCropHint =>
      'Arraste para reposicionar e use pinça para ampliar até o assunto caber no círculo.';

  @override
  String get accountUsername => 'Nome de usuário';

  @override
  String get accountDisplayName => 'Nome de exibição';

  @override
  String get accountVerificationCode => 'Código de verificação';

  @override
  String get accountSendCode => 'Enviar código';

  @override
  String get accountSignIn => 'Entrar';

  @override
  String get accountCreate => 'Criar conta';

  @override
  String get accountResetPassword => 'Redefinir senha';

  @override
  String get accountUseApple => 'Entrar com Apple';

  @override
  String get accountUseGithub => 'Entrar com GitHub';

  @override
  String get accountUseGoogle => 'Continuar com Google';

  @override
  String get accountUsePasskey => 'Continuar com Passkey';

  @override
  String get accountMoreSignInMethods => 'Mais métodos de login';

  @override
  String get accountExternalHint =>
      'Um navegador seguro será aberto. Volte aqui após aprovar.';

  @override
  String get accountProfileTitle => 'Perfil';

  @override
  String get accountEditProfile => 'Editar perfil';

  @override
  String get accountSignInMethodsTitle => 'Métodos de login';

  @override
  String get accountSaveProfile => 'Salvar perfil';

  @override
  String get accountChangeAvatar => 'Alterar avatar';

  @override
  String get accountRemoveAvatar => 'Remover avatar';

  @override
  String get accountSignOut => 'Sair';

  @override
  String get accountSupportTitle => 'Assinatura Premium';

  @override
  String get accountSupportFreeSubtitle =>
      'Os recursos básicos de leitura são gratuitos.';

  @override
  String get accountSupportAction => 'Obter Premium';

  @override
  String get accountSupporterBadge => 'Premium';

  @override
  String get accountPasswordLengthHint => 'Pelo menos 12 caracteres';

  @override
  String get accountUsernameHint =>
      '3–30 letras minúsculas, números ou sublinhados';

  @override
  String get settingsDonationAction => 'Doar com WeChat';

  @override
  String get settingsAlipayDonationAction => 'Doar com Alipay';

  @override
  String get settingsDonationDialogTitle => 'Doação por WeChat';

  @override
  String get settingsDonationDialogHint =>
      'Escaneie o código QR com o WeChat para apoiar o desenvolvimento contínuo. Obrigado.';

  @override
  String get settingsAlipayDonationDialogTitle => 'Doação por Alipay';

  @override
  String get settingsAlipayDonationDialogHint =>
      'Escaneie o código QR com o Alipay para apoiar o desenvolvimento contínuo. Obrigado.';

  @override
  String get settingsDonationVoluntaryNotice =>
      'As doações são totalmente opcionais. Elas não desbloqueiam recursos nem constituem uma compra ou contrato de serviço.';

  @override
  String get settingsDonationQrCodeLabel => 'Código QR de doação por WeChat';

  @override
  String get settingsAlipayDonationQrCodeLabel =>
      'Código QR de doação por Alipay';

  @override
  String get settingsAiSwipeHint =>
      'Deslize pelos modelos, toque para alternar, mantenha pressionado para editar ou excluir.';

  @override
  String get settingsAiLegacyIntro =>
      'Escolha um provedor e um modelo e insira sua API key.';

  @override
  String get settingsAiModelLabel => 'Modelo';

  @override
  String get settingsAiUsingCustomParams =>
      'Usando configurações de modelo personalizadas';

  @override
  String get settingsAiApiKeyStoredLocally =>
      'Armazenada apenas neste dispositivo';

  @override
  String get settingsAiSaveAndEnable => 'Salvar e ativar';

  @override
  String get settingsAboutTagline => 'Multiplataforma, focado na leitura';

  @override
  String get settingsVersionLabel => 'Versão';

  @override
  String get changelogHistoryTitle => 'Histórico de versões';

  @override
  String get changelogHistorySubtitle => 'Veja as mudanças de cada versão';

  @override
  String get openSourceLicensesTitle => 'Licenças de código aberto e fontes';

  @override
  String get openSourceLicensesSubtitle =>
      'Veja as licenças do app, das fontes incluídas e de software de terceiros';

  @override
  String get openSourceLicensesIntro =>
      'Estes textos e avisos de licença ficam disponíveis offline no app. O Origo X, as fontes sob demanda e o software de terceiros permanecem sujeitos às suas respectivas licenças.';

  @override
  String get openSourceProjectSection => 'Licenças do projeto';

  @override
  String get openSourceLegacyLicenseTitle => 'Versões anteriores';

  @override
  String get openSourceFontsSection => 'Licenças das fontes';

  @override
  String get openSourceDependenciesSection => 'Software de terceiros';

  @override
  String get openSourceDependenciesTitle => 'Dependências do Flutter e do Dart';

  @override
  String get openSourceDependenciesSubtitle =>
      'Veja licenças de terceiros coletadas automaticamente pelo Flutter';

  @override
  String get openSourceLicenseLegalese =>
      'O Origo X e os componentes de terceiros permanecem sujeitos às suas respectivas licenças.';

  @override
  String get openSourceLicenseLoadFailed =>
      'Não foi possível carregar o texto da licença.';

  @override
  String get changelogPageTitle => 'Histórico de versões';

  @override
  String get changelogCurrentVersion => 'Versão atual';

  @override
  String get changelogLoadFailed =>
      'Não foi possível carregar o histórico de versões';

  @override
  String get settingsMaintainerLabel => 'Mantenedor';

  @override
  String get settingsLicenseLabel => 'Licença';

  @override
  String get settingsViewSourceSubtitle => 'Ver projeto de código aberto';

  @override
  String get settingsJoinQqGroup => 'Entrar no grupo do QQ';

  @override
  String get settingsQqOpenFailed =>
      'Não foi possível abrir o QQ. Verifique se o QQ está instalado.';

  @override
  String get settingsDarkModeTitle => 'Modo noturno';

  @override
  String settingsCurrentValue(String value) {
    return 'Atual: $value';
  }

  @override
  String get settingsUiStyleTitle => 'Efeito vidro';

  @override
  String get settingsGlassEffectSubtitle =>
      'Usar superfícies translúcidas, desfoque de fundo e profundidade flutuante';

  @override
  String get settingsHideNavigationLabelsTitle =>
      'Ocultar rótulos da navegação inferior';

  @override
  String get settingsHideNavigationLabelsSubtitle =>
      'Mostrar apenas ícones na navegação inferior do celular';

  @override
  String get settingsFloatingNavigationTitle => 'Barra de navegação flutuante';

  @override
  String get settingsFloatingNavigationSubtitle =>
      'Ajuste tamanho, estilo de exibição e ordem dos destinos';

  @override
  String get floatingNavigationPreviewTitle => 'Prévia';

  @override
  String get floatingNavigationSizeTitle => 'Tamanho';

  @override
  String get floatingNavigationSizeAutomatic => 'Automático';

  @override
  String get floatingNavigationSizeCustom => 'Personalizado';

  @override
  String get floatingNavigationHeightLabel => 'Altura';

  @override
  String get floatingNavigationSideMarginLabel => 'Margem lateral';

  @override
  String get floatingNavigationDisplayModeTitle => 'Estilo de exibição';

  @override
  String get floatingNavigationIconsOnly => 'Apenas ícones';

  @override
  String get floatingNavigationIconsAndLabels => 'Ícones e rótulos';

  @override
  String get floatingNavigationOrderTitle => 'Ordem de navegação';

  @override
  String get floatingNavigationOrderHint =>
      'Segure a alça à direita para reordenar';

  @override
  String get floatingNavigationSyncHint =>
      'A ordem também se aplica à navegação por deslize e à barra lateral de telas largas';

  @override
  String get floatingNavigationResetOrder => 'Restaurar ordem padrão';

  @override
  String get floatingNavigationResetDone => 'Ordem padrão restaurada';

  @override
  String get settingsLibraryLayoutTitle => 'Configurações da estante';

  @override
  String get settingsLibraryLayoutSubtitle =>
      'Ajuste o layout da estante e a experiência de abertura de livros';

  @override
  String get settingsLibraryLayoutCard => 'Cartões';

  @override
  String get settingsLibraryLayoutGrid => 'Grade';

  @override
  String get settingsLibraryGridColumnsTitle => 'Capas por linha no celular';

  @override
  String get settingsLibraryGridTwoColumns => '2 colunas';

  @override
  String get settingsLibraryGridThreeColumns => '3 colunas';

  @override
  String get settingsLibraryGridShowDetailsTitle =>
      'Mostrar título e progresso';

  @override
  String get settingsLibraryGridShowDetailsSubtitle =>
      'Adiciona uma linha de título e uma barra de progresso compacta abaixo de cada capa';

  @override
  String get settingsLibraryOpenAnimationTitle =>
      'Animação de abertura do livro';

  @override
  String get settingsLibraryOpenAnimationSubtitle =>
      'Usada apenas ao abrir um livro da estante';

  @override
  String get settingsLibraryOpenAnimationClassicCover =>
      'Expansão clássica da capa';

  @override
  String get settingsLibraryOpenAnimationClassicCoverHint =>
      'Amplia a capa original para tela cheia antes de revelar o leitor';

  @override
  String get settingsLibraryOpenAnimationMinimal => 'Desvanecer mínimo';

  @override
  String get settingsLibraryOpenAnimationMinimalHint =>
      'Faz o texto surgir sem movimento direcional';

  @override
  String get settingsLibraryOpenAnimationPaperRise => 'Folha ascendente';

  @override
  String get settingsLibraryOpenAnimationPaperRiseHint =>
      'A folha de leitura se assenta suavemente vindo de baixo';

  @override
  String get settingsLibraryOpenAnimationPageSlide => 'Deslizar de página';

  @override
  String get settingsLibraryOpenAnimationPageSlideHint =>
      'A página de leitura entra com um breve movimento lateral';

  @override
  String get settingsLibraryOpenAnimationPaceTitle => 'Ritmo da animação';

  @override
  String get settingsLibraryOpenAnimationFast => 'Rápida';

  @override
  String get settingsLibraryOpenAnimationFastHint =>
      'Surgir rapidamente assim que o texto estiver pronto';

  @override
  String get settingsLibraryOpenAnimationElegant => 'Elegante';

  @override
  String get settingsLibraryOpenAnimationElegantHint =>
      'Revelar o texto mais gradualmente para uma transição mais calma';

  @override
  String get settingsAccentFollowTheme => 'Cor de destaque: seguir tema';

  @override
  String settingsAccentValue(String name) {
    return 'Cor de destaque: $name';
  }

  @override
  String get settingsAppThemeTitle => 'Tema do app';

  @override
  String settingsCurrentThemeSummary(String theme, String accent) {
    return 'Atual: $theme · $accent';
  }

  @override
  String get settingsFollowAppTheme => 'Seguir tema do app';

  @override
  String get settingsAccentColorTitle => 'Cor de destaque';

  @override
  String get settingsThemeModeSystemHint =>
      'Alternar automaticamente com a aparência do sistema';

  @override
  String get settingsThemeModeLightHint => 'Usar sempre a aparência clara';

  @override
  String get settingsThemeModeDarkHint => 'Usar sempre a aparência escura';

  @override
  String get settingsSelectAppTheme => 'Escolher tema do app';

  @override
  String get settingsDone => 'Concluído';

  @override
  String get settingsAccentColorAdvice =>
      'A cor de destaque gera os esquemas de cor Material 3 completos, claro e escuro.';

  @override
  String get settingsAccentPresetColors => 'Cores rápidas';

  @override
  String get settingsAccentCustomColor => 'Cor personalizada';

  @override
  String get settingsAccentSaturationBrightness =>
      'Campo de saturação e brilho';

  @override
  String get settingsAccentHue => 'Matiz';

  @override
  String get settingsAccentPreview => 'Prévia da paleta do tema';

  @override
  String get settingsAccentFollowThemeOption => 'Seguir tema';

  @override
  String get settingsAccentFollowThemeDesc =>
      'Usar a cor de destaque padrão do tema atual do app';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsAppName => 'Origo X';

  @override
  String get settingsAuthor => 'Mantenedor: 小元Niki';

  @override
  String get settingsGithubRepo => 'Repositório no GitHub';

  @override
  String get settingsNewYearGreeting =>
      'Um leitor multiplataforma focado, contido e livremente modificável.';

  @override
  String get settingsGithubOpenFailed =>
      'Não foi possível abrir o link do GitHub';

  @override
  String get settingsOfficialWebsite => 'Site oficial';

  @override
  String get settingsOfficialWebsiteSubtitle =>
      'Baixe e instale de open.xxread.top';

  @override
  String get settingsOfficialWebsiteOpenFailed =>
      'Não foi possível abrir o site oficial';

  @override
  String get updateCheckNow => 'Verificar atualizações';

  @override
  String get updateCheckNowSubtitle =>
      'Obtenha a versão mais recente no GitHub ou no site oficial';

  @override
  String get updateAppStoreManaged =>
      'Esta versão da Mac App Store é atualizada pela App Store';

  @override
  String get updateAvailableTitle => 'Uma nova versão está disponível';

  @override
  String updateVersionSummary(String currentVersion, String latestVersion) {
    return 'Versão atual: $currentVersion\nVersão mais recente: $latestVersion';
  }

  @override
  String get updateNotesTitle => 'Novidades';

  @override
  String get updateNotesEmpty =>
      'Nenhuma nota de versão foi fornecida para esta versão.';

  @override
  String get updateLater => 'Depois';

  @override
  String get updateSkipVersion => 'Pular esta versão';

  @override
  String get updateGoToDownload => 'Ir para a atualização';

  @override
  String get updateFromGithub => 'Atualizar pelo GitHub';

  @override
  String get updateFromWebsite => 'Abrir site oficial';

  @override
  String get updateFromWebsiteInstall => 'Baixar do site';

  @override
  String get updateWebsiteUnavailable =>
      'O pacote do site oficial ainda não está disponível para este dispositivo';

  @override
  String get updateDownloadingTitle => 'Baixando atualização';

  @override
  String updateDownloadProgress(int percent) {
    return '$percent% baixado';
  }

  @override
  String get updatePreparingInstaller =>
      'Verificando o pacote e preparando o instalador do sistema…';

  @override
  String get updateDownloadFailed =>
      'Não foi possível baixar a atualização do site oficial';

  @override
  String get updateIntegrityFailed =>
      'A atualização baixada falhou na verificação de integridade e foi excluída';

  @override
  String get updateInstallFailed =>
      'Não foi possível instalar o pacote de atualização. Verifique as permissões de instalação e tente novamente.';

  @override
  String get updateAlreadyLatest => 'Você já está usando a versão mais recente';

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar atualizações. Tente novamente mais tarde.';

  @override
  String get updateOpenFailed => 'Não foi possível abrir o link';

  @override
  String get settingsIosOnlyFeature =>
      'Este recurso está disponível apenas no iOS';

  @override
  String settingsIosSyncResult(String storage, int books, int files) {
    return 'Sincronizado com $storage\n$books livros, $files arquivos copiados';
  }

  @override
  String get settingsRestartRequiredReason =>
      'Esta mudança de configuração exige reiniciar o app para ter efeito completo.';

  @override
  String get settingsRestartRequiredTitle => 'Reinício necessário';

  @override
  String settingsRestartPrompt(String reason) {
    return '$reason\n\nReiniciar o app agora?';
  }

  @override
  String get settingsRestartLater => 'Depois';

  @override
  String get settingsRestartNow => 'Reiniciar';

  @override
  String get statsDetailedTitle => 'Estatísticas detalhadas';

  @override
  String get statsRange7Days => '7 dias';

  @override
  String get statsRange30Days => '30 dias';

  @override
  String get statsRange90Days => '90 dias';

  @override
  String get statsRange1Year => '1 ano';

  @override
  String get statsRangeAll => 'Tudo';

  @override
  String get statsTabOverview => 'Visão geral';

  @override
  String get statsTabCharts => 'Gráficos';

  @override
  String get statsTabBooks => 'Livros';

  @override
  String get statsTabAchievements => 'Conquistas';

  @override
  String get statsReadingOverview => 'Visão geral da leitura';

  @override
  String statsCumulativeHours(Object hours) {
    return 'Total de $hours horas';
  }

  @override
  String statsStreakEncouragement(Object days) {
    return 'Mantenha o ritmo — você leu $days dias seguidos';
  }

  @override
  String get statsTotalDuration => 'Tempo total';

  @override
  String get statsAvgSession => 'Sessão média';

  @override
  String statsDaysCount(Object count) {
    return '$count dias';
  }

  @override
  String get statsNoData => 'Sem dados';

  @override
  String get statsPeriodEarlyMorning => 'Madrugada 05:00-08:59';

  @override
  String get statsPeriodMorning => 'Manhã 09:00-11:59';

  @override
  String get statsPeriodAfternoon => 'Tarde 12:00-17:59';

  @override
  String get statsPeriodEvening => 'Noite 18:00-21:59';

  @override
  String get statsPeriodLateNight => 'Altas horas 22:00-04:59';

  @override
  String get statsTotalReadingTime => 'Tempo total de leitura';

  @override
  String get statsTotalPagesRead => 'Total de páginas lidas';

  @override
  String get statsBooksReadCount => 'Livros lidos';

  @override
  String get statsUnitPage => 'páginas';

  @override
  String get statsTodayProgress => 'Progresso de leitura de hoje';

  @override
  String statsMinutesOfTarget(Object current, Object target) {
    return '$current / $target min';
  }

  @override
  String get statsPagesRead => 'Páginas lidas';

  @override
  String statsPagesOfTarget(Object current, Object target) {
    return '$current / $target páginas';
  }

  @override
  String get statsReadingHabits => 'Hábitos de leitura';

  @override
  String get statsBestReadingPeriod => 'Melhor horário de leitura';

  @override
  String get statsAvgSessionReading => 'Sessão média de leitura';

  @override
  String get statsMaxStreakDays => 'Maior sequência';

  @override
  String get statsFocusScore => 'Foco de leitura';

  @override
  String get statsBookCount => 'Quantidade de livros';

  @override
  String get statsTrendAnalysis => 'Análise de tendência de leitura';

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
    return '$value liv';
  }

  @override
  String statsAxisHour(Object hour) {
    return '${hour}h';
  }

  @override
  String get statsTimeDistribution => 'Distribuição do tempo de leitura';

  @override
  String get statsFormatDistribution => 'Distribuição de formatos de livros';

  @override
  String get statsCompleted => 'Concluídos';

  @override
  String get statsInProgress => 'Em andamento';

  @override
  String get statsDurationRanking => 'Ranking de tempo de leitura';

  @override
  String get statsProgressRanking => 'Ranking de progresso de leitura';

  @override
  String statsPagesCount(Object count) {
    return '$count páginas';
  }

  @override
  String statsSessionCount(Object count) {
    return '$count sessões';
  }

  @override
  String statsAchievementsSummary(Object achieved, Object remaining) {
    return '$achieved conquistas obtidas, faltam $remaining para desbloquear';
  }

  @override
  String get statsAchievementFirstReadTitle => 'Primeira leitura';

  @override
  String get statsAchievementFirstReadDesc =>
      'Conclua sua primeira sessão de leitura';

  @override
  String get statsAchievementNoviceTitle => 'Iniciante na leitura';

  @override
  String get statsAchievementNoviceDesc => 'Leia por um total de 10 horas';

  @override
  String get statsAchievementBookwormTitle => 'Rato de biblioteca';

  @override
  String get statsAchievementBookwormDesc => 'Leia por um total de 100 horas';

  @override
  String get statsAchievementExpertTitle => 'Especialista em leitura';

  @override
  String get statsAchievementExpertDesc => 'Leia 7 dias seguidos';

  @override
  String get statsAchievementOceanTitle => 'Oceano de conhecimento';

  @override
  String get statsAchievementOceanDesc => 'Leia 10.000 páginas';

  @override
  String get statsAchievementScholarTitle => 'Polímata';

  @override
  String get statsAchievementScholarDesc => 'Leia 10 livros diferentes';

  @override
  String get statsAchievementMarathonTitle => 'Maratona de leitura';

  @override
  String get statsAchievementMarathonDesc => 'Leia 30 dias seguidos';

  @override
  String get statsAchievementFocusTitle => 'Mestre do foco';

  @override
  String get statsAchievementFocusDesc => 'Leia por um total de 500 horas';

  @override
  String statsProgressPercent(Object percent) {
    return 'Progresso: $percent%';
  }

  @override
  String get statsGoalProgress => 'Progresso da meta de leitura';

  @override
  String get statsMonthlyReadingTime => 'Tempo de leitura deste mês';

  @override
  String get statsWeeklyReadingTime => 'Tempo de leitura desta semana';

  @override
  String get statsAvgDailyPages7d => 'Média diária de páginas (últimos 7 dias)';

  @override
  String statsHoursCount(Object count) {
    return '$count horas';
  }

  @override
  String get statsSpeedTrend => 'Tendência de velocidade de leitura';

  @override
  String statsAvgSpeed(Object speed) {
    return 'Média: $speed páginas/min';
  }

  @override
  String get statsReadingContinuity => 'Continuidade de leitura';

  @override
  String statsCurrentStreak(Object days) {
    return 'Sequência atual: $days dias';
  }

  @override
  String get statsHeatmapLess => 'Menos';

  @override
  String get statsHeatmapMore => 'Mais';

  @override
  String statsWeekNumber(Object week) {
    return 'Semana $week';
  }

  @override
  String get bookSourceAddToShelf => 'Adicionar à estante';

  @override
  String get bookSourceAddOnline => 'Adicionar online';

  @override
  String get bookSourceAddOnlineHint =>
      'Leia da fonte e armazene capítulos em cache conforme avança';

  @override
  String get bookSourceDownloadLocal => 'Baixar localmente';

  @override
  String get bookSourceDownloadLocalHint =>
      'Baixa todos os capítulos e adiciona uma cópia local em TXT';

  @override
  String get bookSourceAddedOnline => 'Adicionado à estante como livro online';

  @override
  String get bookSourceAlreadyOnShelf => 'Este livro já está na sua estante';

  @override
  String get bookSourceDownloading => 'Baixando localmente';

  @override
  String get bookSourceFetchingCatalog => 'Buscando catálogo de capítulos…';

  @override
  String bookSourceDownloadProgress(int completed, int total) {
    return '$completed/$total capítulos';
  }

  @override
  String get bookSourceDownloadComplete =>
      'Download concluído e adicionado à estante local';

  @override
  String get bookSourceDownloadConverted =>
      'Download concluído. Agora é um livro local';

  @override
  String bookSourceDownloadFailed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get downloadTasksTitle => 'Downloads';

  @override
  String get downloadTasksEmpty => 'Nenhuma tarefa de download';

  @override
  String get downloadTaskQueued => 'Aguardando download';

  @override
  String get downloadTaskDownloading => 'Baixando em segundo plano';

  @override
  String get downloadTaskCompleted => 'Download concluído';

  @override
  String get downloadTaskFailed => 'Falha no download';

  @override
  String get downloadTaskCancelled => 'Cancelado';

  @override
  String get downloadTaskCancel => 'Cancelar tarefa';

  @override
  String get downloadContinueInBackground => 'Continuar em segundo plano';

  @override
  String get downloadRunningInBackground =>
      'O download continua em segundo plano';

  @override
  String get bookSourceExitAddTitle => 'Adicionar à estante?';

  @override
  String bookSourceExitAddMessage(String title) {
    return 'Adicionar “$title” à sua estante como livro online? Seu progresso de leitura será mantido.';
  }

  @override
  String get bookSourceNotNow => 'Agora não';

  @override
  String get bookSourceOnlineBadge => 'Online';

  @override
  String bookSourceOnlineDataBroken(String error) {
    return 'Os dados do livro online são inválidos: $error';
  }

  @override
  String get readerThemeTitle => 'Tema de leitura';

  @override
  String get readerThemeDescription =>
      'Altera apenas a página de leitura e seus controles';

  @override
  String get readerSettingsTabTheme => 'Tema';

  @override
  String get readerSettingsTabText => 'Texto';

  @override
  String get readerSettingsTabLayout => 'Layout';

  @override
  String get readerSettingsTabPaging => 'Paginação';

  @override
  String get readerSettingsAdvancedTypography => 'Tipografia avançada';

  @override
  String get readerAutoPageTurnTitle => 'Virar página automaticamente';

  @override
  String get readerAutoPageTurnOff => 'Não iniciado';

  @override
  String get readerAutoPageTurnShortcutTitle => 'Atalho de leitura automática';

  @override
  String get readerAutoPageTurnShortcutHint =>
      'Mostrar junto aos controles de leitura para iniciar ou pausar rapidamente';

  @override
  String get readerAutoPageTurnHint =>
      'Avança uma tela no intervalo selecionado, inclusive no modo de paginação vertical.';

  @override
  String get readerAutoPageTurnModeTimed => 'Virar página por tempo';

  @override
  String get readerAutoPageTurnModeSweep => 'Virar página por varredura';

  @override
  String get readerAutoPageTurnModeContinuous => 'Rolagem contínua';

  @override
  String get readerAutoPageTurnModeInterval => 'Rolagem por intervalo';

  @override
  String get readerAutoPageTurnTimedHint =>
      'Aguarda o intervalo selecionado e depois passa para a próxima página.';

  @override
  String get readerAutoPageTurnSweepHint =>
      'Uma linha varre de cima para baixo, revelando gradualmente a próxima página acima dela.';

  @override
  String get readerAutoPageTurnContinuousHint =>
      'Rola para baixo continuamente em um ritmo de leitura constante.';

  @override
  String get readerAutoPageTurnIntervalHint =>
      'Aguarda o intervalo selecionado e depois rola cerca de uma tela para baixo.';

  @override
  String get readerAutoPageTurnSweepDurationLabel => 'Duração da varredura';

  @override
  String get readerAutoPageTurnScrollSpeedLabel => 'Velocidade de rolagem';

  @override
  String readerAutoPageTurnSecondsPerScreen(int seconds) {
    return '$seconds segundos por tela';
  }

  @override
  String readerAutoPageTurnModeValue(String mode, int seconds) {
    return '$mode · ${seconds}s/tela';
  }

  @override
  String readerAutoPageTurnModePaused(String mode, int seconds) {
    return 'Pausado · $mode · ${seconds}s/tela';
  }

  @override
  String get readerAutoPageTurnIntervalLabel => 'Intervalo de página';

  @override
  String readerAutoPageTurnInterval(int seconds) {
    return '$seconds segundos por tela';
  }

  @override
  String get readerAutoPageTurnStart => 'Iniciar virar página automático';

  @override
  String get readerAutoPageTurnResume => 'Retomar virar página automático';

  @override
  String readerAutoPageTurnRunning(int seconds) {
    return 'Automático · ${seconds}s/tela';
  }

  @override
  String readerAutoPageTurnPaused(int seconds) {
    return 'Pausado · ${seconds}s/tela';
  }

  @override
  String get readerThemeDay => 'Dia';

  @override
  String get readerThemeFollowSystem => 'Seguir sistema';

  @override
  String get readerThemeMist => 'Névoa';

  @override
  String get readerThemeGreen => 'Conforto ocular';

  @override
  String get readerThemeRose => 'Rosa';

  @override
  String get readerThemeNavy => 'Azul profundo';

  @override
  String get readerThemeNight => 'Noite';

  @override
  String get readerThemePureBlack => 'Preto puro';

  @override
  String get readerThemeParchment => 'Pergaminho';

  @override
  String get readerThemeCustom => 'Personalizado';

  @override
  String get readerPullBookmarkTitle => 'Marcador por puxar';

  @override
  String get readerPullBookmarkHint =>
      'Puxe a partir da borda superior e solte para adicionar ou remover um marcador desta página';

  @override
  String get readerPullBookmarkAddHint => 'Puxe mais para adicionar marcador';

  @override
  String get readerPullBookmarkRemoveHint => 'Puxe mais para remover marcador';

  @override
  String get readerPullBookmarkReleaseHint => 'Solte para concluir';

  @override
  String get readerTapAnimationTitle => 'Animação de toque';

  @override
  String get readerTapAnimationHint =>
      'Usa a animação de virar página atual nos toques laterais; desative para atualizar instantaneamente';

  @override
  String get readerTabletTwoPageTitle => 'Layout de duas páginas no tablet';

  @override
  String get readerTabletTwoPageHint =>
      'Mostra páginas esquerda e direita lado a lado no modo paisagem; desative para usar sempre uma única página';

  @override
  String get readerCustomThemeTitle => 'Tema de leitura personalizado';

  @override
  String get readerCustomThemeReset => 'Redefinir';

  @override
  String get readerCustomThemeColors => 'Cores do tema';

  @override
  String get readerCustomThemeTextColor => 'Cor do texto';

  @override
  String get readerCustomThemeTextColorHint =>
      'Texto do corpo, títulos e ícones principais';

  @override
  String get readerCustomThemeBackground => 'Fundo de leitura';

  @override
  String get readerCustomThemeBackgroundHint =>
      'A cor do papel e da tela de leitura';

  @override
  String get readerCustomThemeControlBar => 'Cor da barra de controles';

  @override
  String get readerCustomThemeControlBarHint =>
      'Controles superior e inferior e superfícies de configurações';

  @override
  String get readerCustomThemeContrastGood =>
      'O texto tem contraste claro para uma leitura prolongada confortável';

  @override
  String get readerCustomThemeContrastLow =>
      'O contraste do texto está baixo e pode causar fadiga de leitura';

  @override
  String get readerCustomThemeSave => 'Salvar e usar';

  @override
  String get readerCustomThemePreview => 'Prévia ao vivo';

  @override
  String get readerCustomThemePreviewChapter =>
      'Capítulo Um · Vento entre as páginas';

  @override
  String get readerCustomThemePreviewBody =>
      'Este é o seu espaço de leitura. Ajuste as cores do texto, do papel e dos controles até cada página parecer genuinamente sua.';

  @override
  String get readerCustomThemeHexInvalid =>
      'Digite uma cor hexadecimal de 6 dígitos, como #F6F0E4';

  @override
  String get readerCustomThemeHexLabel => 'Cor hexadecimal';

  @override
  String get readerCustomThemesTitle => 'Temas de leitura personalizados';

  @override
  String get readerCustomThemeAdd => 'Adicionar tema';

  @override
  String get readerCustomThemeReorderHint =>
      'Segure a alça à direita para reordenar os temas. A mesma ordem aparece nas configurações de leitura.';

  @override
  String get readerCustomThemeUse => 'Usar tema selecionado';

  @override
  String get readerCustomThemeDeleteTitle => 'Excluir tema de leitura?';

  @override
  String readerCustomThemeDeleteMessage(String name) {
    return '“$name” será removido dos seus temas, junto com a imagem de fundo salva.';
  }

  @override
  String get readerCustomThemeEmptyTitle => 'Ainda não há temas personalizados';

  @override
  String get readerCustomThemeEmptyHint =>
      'Crie sua própria combinação de tipografia, cor de papel e imagem de fundo.';

  @override
  String get readerCustomThemeNewTitle => 'Novo tema de leitura';

  @override
  String get readerCustomThemeEditTitle => 'Editar tema de leitura';

  @override
  String get readerCustomThemeName => 'Nome do tema';

  @override
  String get readerCustomThemeNameHint =>
      'Por exemplo, Noite de chuva ou Papel da tarde';

  @override
  String get readerCustomThemeBackgroundImage => 'Imagem de fundo';

  @override
  String get readerCustomThemeBackgroundImageHint =>
      'Suporta JPG, PNG e WebP. A imagem é copiada para o armazenamento do app.';

  @override
  String get readerCustomThemeChooseImage => 'Enviar imagem';

  @override
  String get readerCustomThemeReplaceImage => 'Substituir imagem';

  @override
  String get readerCustomThemeRemoveImage => 'Remover imagem';

  @override
  String get readerCustomThemeImageStrength => 'Intensidade da imagem de fundo';

  @override
  String get readerCustomThemeImageUnsupported =>
      'A importação de imagem de fundo não é suportada nesta plataforma';

  @override
  String get readerCustomThemeImageTooLarge =>
      'A imagem deve ter no máximo 20 MB';

  @override
  String get readerCustomThemeImageFormat =>
      'Escolha uma imagem JPG, PNG ou WebP';

  @override
  String get readerCustomThemeImageFailed =>
      'Não foi possível importar a imagem de fundo. Tente novamente.';

  @override
  String get importSourceTitle => 'Adicionar livros';

  @override
  String get importSourceDescription =>
      'Escolha alguns arquivos primeiro. Revise a fila antes de iniciar a importação.';

  @override
  String get importSelectFiles => 'Escolher arquivos';

  @override
  String get importIosSharedDocuments => 'No Meu iPhone · Origo X';

  @override
  String get importICloudDrive => 'iCloud Drive · Origo X';

  @override
  String get importICloudUnavailable => 'O iCloud Drive está indisponível';

  @override
  String get importAndroidFolder => 'Autorizar uma pasta de livros';

  @override
  String get importAndroidRescan => 'Escanear pastas autorizadas';

  @override
  String get importFolderPermissionAvailable =>
      'Autorizada · toque para escanear';

  @override
  String get importFolderPermissionLost =>
      'Permissão perdida · autorize novamente para restaurar o acesso';

  @override
  String get importRemoveFolder => 'Remover pasta';

  @override
  String importQueueTitle(int count) {
    return 'Fila de importação ($count)';
  }

  @override
  String get importQueueHint =>
      'Remova arquivos selecionados por engano e importe um de cada vez.';

  @override
  String get importQueueEmptyTitle => 'Nenhum livro selecionado';

  @override
  String get importQueueEmptyBody =>
      'Escolha um arquivo EPUB, PDF, TXT, MOBI ou outro formato de livro suportado.';

  @override
  String importAction(int count) {
    return 'Importar $count livros';
  }

  @override
  String importRetryFailed(int count) {
    return 'Tentar novamente $count com falha';
  }

  @override
  String get importStatusQueued => 'Aguardando';

  @override
  String get importStatusPreparing => 'Preparando arquivo';

  @override
  String get importStatusChecking => 'Verificando';

  @override
  String get importStatusCopying => 'Copiando';

  @override
  String get importStatusAnalyzing => 'Analisando';

  @override
  String get importStatusSaving => 'Salvando';

  @override
  String get importStatusImported => 'Importado';

  @override
  String get importStatusSkipped => 'Já existe, ignorado';

  @override
  String get importStatusFailed => 'Falha na importação';

  @override
  String get importRemove => 'Remover';

  @override
  String get importRetry => 'Tentar novamente';

  @override
  String get importClearCompleted => 'Limpar concluídos';

  @override
  String get importDone => 'Concluído';

  @override
  String importSummary(int succeeded, int skipped, int failed) {
    return '$succeeded importados · $skipped ignorados · $failed com falha';
  }

  @override
  String get importNoSupportedFiles =>
      'Nenhum arquivo de livro suportado foi encontrado';

  @override
  String get importScanning => 'Escaneando arquivos…';

  @override
  String get settingsAiApiKeyConfigured => 'API Key configurada';

  @override
  String get settingsAiApiKeyTapToConfigure =>
      'Toque para concluir a configuração';

  @override
  String get settingsAiAddModel => 'Adicionar modelo';

  @override
  String settingsAiSwitchedToModel(String model) {
    return 'Alterado para $model';
  }

  @override
  String get settingsAiFillBaseUrlAndApiKey =>
      'Preencha primeiro a Base URL e a API Key';

  @override
  String get settingsAiEditModelTitle => 'Configurar modelo';

  @override
  String get settingsAiQuickCardSubtitle =>
      'Cada cartão rápido está vinculado a um modelo';

  @override
  String get settingsAiPresetModel => 'Modelo predefinido';

  @override
  String get settingsAiBaseUrlLabel => 'Base URL';

  @override
  String get settingsAiBaseUrlHintOpenAi =>
      'Compatível com OpenAI: a Base URL geralmente precisa incluir /v1 (por exemplo, https://example.com/v1). O app acrescenta /chat/completions.';

  @override
  String get settingsAiBaseUrlHintAnthropic =>
      'Anthropic: a Base URL pode incluir /v1 ou omiti-lo. O app evita duplicar /v1 e acrescenta /messages.';

  @override
  String get settingsAiApiKeyLabel => 'API Key';

  @override
  String get settingsAiModelNameLabel => 'Nome do modelo';

  @override
  String get settingsAiFetchModelsTooltip => 'Buscar modelos automaticamente';

  @override
  String get settingsAiFetchModelsList =>
      'Buscar lista de modelos automaticamente';

  @override
  String get settingsAiSelectModel => 'Selecione um modelo';

  @override
  String get settingsAiTemperatureLabel => 'Temperatura';

  @override
  String get settingsAiAddAndEnable => 'Adicionar e ativar';

  @override
  String get settingsAiModelMismatchClaude =>
      'Nomes de modelo do provedor Claude geralmente começam com \"claude\". Verifique se o provedor e o modelo correspondem.';

  @override
  String get settingsAiModelMismatchGemini =>
      'Nomes de modelo do provedor Gemini geralmente contêm \"gemini\". Verifique se o provedor e o modelo correspondem.';

  @override
  String get settingsAiModelMismatchGlm =>
      'Nomes de modelo do provedor GLM geralmente começam com \"glm\". Verifique se o provedor e o modelo correspondem.';

  @override
  String get settingsAiModelMismatchMinimax =>
      'Nomes de modelo do provedor MiniMax geralmente contêm \"MiniMax\". Verifique se o provedor e o modelo correspondem.';

  @override
  String get settingsAiModelListFormatUnrecognized =>
      'Formato de resposta da lista de modelos não reconhecido';

  @override
  String get settingsAiNoModelsReturned =>
      'O servidor não retornou uma lista de modelos disponíveis';

  @override
  String get settingsAiNoModelsAvailable => 'Nenhum modelo disponível';

  @override
  String settingsAiFetchModelsFailed(String error) {
    return 'Falha ao buscar modelos: $error';
  }

  @override
  String get settingsAiPreprocessTitle => 'Pré-processamento de livros com AI';

  @override
  String get settingsAiPreprocessSubtitle =>
      'Após importar um livro, deixe a AI lê-lo e montar automaticamente uma base de conhecimento local de resumos';

  @override
  String get settingsAiPreprocessWarning =>
      'O pré-processamento envia o livro inteiro para o modelo de AI em blocos. Consome um grande número de tokens e demora um pouco. Ativar mesmo assim?';

  @override
  String get settingsAiPreprocessNeedModel =>
      'Configure primeiro um modelo de AI funcional com uma API key';

  @override
  String get libraryAiPreprocess => 'Pré-processamento com AI';

  @override
  String libraryAiPreprocessConfirm(String title) {
    return 'Deixar a AI ler \"$title\" e montar uma base de conhecimento de resumos? Isto consome um grande número de tokens.';
  }

  @override
  String libraryAiPreprocessProgress(int done, int total) {
    return 'A AI está lendo este livro… (etapa $done/$total)';
  }

  @override
  String get libraryAiPreprocessDone => 'Base de conhecimento da AI gerada';

  @override
  String libraryAiPreprocessFailed(String error) {
    return 'Falha no pré-processamento com AI: $error';
  }

  @override
  String get libraryAiPreprocessUnsupported =>
      'Este formato de livro ainda não suporta pré-processamento com AI';

  @override
  String get libraryAiPreprocessQueued =>
      'Adicionado à fila de pré-processamento com AI. Acompanhe o progresso em Tarefas de download.';

  @override
  String get downloadTasksTabDownloads => 'Downloads';

  @override
  String get aiPreprocessTaskRunning => 'A AI está lendo…';

  @override
  String get aiPreprocessTasksEmpty =>
      'Nenhuma tarefa de pré-processamento com AI';

  @override
  String get aiPreprocessClearFinished => 'Limpar concluídas';

  @override
  String get aiChatNewChat => 'Nova conversa';

  @override
  String get aiChatSelectBook => 'Vincular um livro';

  @override
  String get aiChatNoBook => 'Nenhum livro vinculado';

  @override
  String get navAi => 'AI';

  @override
  String get aiHistoryTitle => 'Conversas com AI';

  @override
  String get aiHistoryEmpty =>
      'Ainda não há conversas com AI.\nToque em Perguntar à AI durante a leitura para iniciar sua primeira conversa.';

  @override
  String aiHistoryMessageCount(int count) {
    return '$count mensagens';
  }

  @override
  String get aiHistoryClearAll => 'Limpar tudo';

  @override
  String get aiHistoryClearAllConfirm =>
      'Excluir todo o histórico de conversas com AI? Isto não pode ser desfeito.';

  @override
  String get aiHistoryDeleteConfirm => 'Excluir esta conversa?';

  @override
  String get floatingNavigationVisibilityHint =>
      'Desative um interruptor para ocultar aquela página; Configurações não pode ser ocultada.';

  @override
  String get readerAskAi => 'Perguntar à AI';

  @override
  String get readerAiInputHint => 'Pergunte sobre este livro…';

  @override
  String get readerAiSendButton => 'Enviar';

  @override
  String get readerAiThinking => 'Pensando…';

  @override
  String get readerAiNotConfiguredHint =>
      'Nenhum modelo de AI configurado ainda. Vá em Configurações → Assistente de leitura com AI para adicionar um modelo e uma API key.';

  @override
  String get readerAiEmptyHint =>
      'Pergunte à AI sobre a página atual ou qualquer coisa neste livro.';

  @override
  String get readerAiSelectionQuestionLabel => 'Explicar esta seleção';

  @override
  String readerAiSelectionPrompt(
    String selection,
    String before,
    String after,
  ) {
    return 'Explique a passagem selecionada abaixo e dê 3 pontos-chave.\n\nTexto selecionado:\n$selection\n\nContexto anterior:\n$before\n\nContexto posterior:\n$after';
  }

  @override
  String get readerAiEnterQuestionFirst =>
      'Digite uma pergunta antes de enviar';

  @override
  String get readerAiEmptyResponse =>
      'O modelo retornou uma resposta vazia, tente novamente';

  @override
  String readerAiRequestFailed(String error) {
    return 'Falha na solicitação: $error';
  }

  @override
  String get readerAiUnknownError => 'Erro desconhecido';

  @override
  String readerAiEmptyResponseError(String endpoint) {
    return 'A resposta do servidor está vazia. Isto geralmente é causado por uma Base URL incorreta, um gateway que não encaminha ao endpoint do modelo ou o servidor encerrando a conexão cedo.\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiInvalidJsonError(
    String provider,
    String endpoint,
    String snippet,
  ) {
    return 'A resposta do servidor não é um JSON válido. O endpoint atual pode ser incompatível com a configuração do $provider.\nURL da solicitação: $endpoint\nTrecho da resposta: $snippet';
  }

  @override
  String readerAiFailedReadBody(String status, String endpoint) {
    return 'Falha na solicitação$status: não foi possível ler a resposta do servidor. Isto geralmente é causado por uma Base URL incorreta, o endpoint retornando conteúdo vazio ou a rede truncando a resposta.\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiNetworkRequestFailed(
    String status,
    String error,
    String endpoint,
  ) {
    return 'Falha na solicitação de rede$status: $error\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiRequestFailedMinimaxHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Falha na solicitação($status): $text\nSugestões: 1) a temperatura da MiniMax deve estar em (0,1]; 2) verifique se o nome do modelo corresponde ao endpoint; 3) use apenas uma única instrução de sistema.\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiRequestFailedClaudeHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Falha na solicitação($status): $text\nDica: o Claude exige o cabeçalho de solicitação anthropic-version.\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiRequestFailedProviderMismatchHint(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Falha na solicitação($status): $text\nDica: confirme que o provedor e a API Key correspondem; eles não podem ser misturados.\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiRequestFailedGeneric(
    String status,
    String text,
    String endpoint,
  ) {
    return 'Falha na solicitação($status): $text\nURL da solicitação: $endpoint';
  }

  @override
  String readerAiMockSelectionResponse(
    String selectedText,
    String before,
    String after,
  ) {
    return 'AI (simulada): O texto que você selecionou é \"$selectedText\".\n\nAntes: $before\nDepois: $after';
  }

  @override
  String readerAiMockPageAnalysis(int chars) {
    return 'AI (simulada): Esta página tem $chars caracteres. Concentre-se nos argumentos no início e no fim dos parágrafos.';
  }

  @override
  String get readerAiMockGreeting => 'Olá';

  @override
  String readerAiMockChatResponse(String question, int chars) {
    return 'AI (simulada): Você perguntou \"$question\".\n\nEu li a página atual ($chars caracteres). Você pode continuar perguntando.';
  }

  @override
  String get ttsSystemDefault => 'Padrão do sistema';

  @override
  String get ttsUnavailable => 'TTS do sistema indisponível';

  @override
  String ttsUnsupportedLanguage(String language) {
    return 'O sistema não suporta o idioma: $language';
  }

  @override
  String get ttsCallFailed => 'Falha na chamada do TTS do sistema';

  @override
  String get importErrorSourceMissing => 'O arquivo de origem não existe';

  @override
  String get importErrorHashFailed =>
      'Não é possível verificar o conteúdo do arquivo';

  @override
  String get importErrorTargetNameExhausted =>
      'Não é possível alocar um nome disponível para o arquivo de importação';

  @override
  String get importErrorSourceNotMaterialized =>
      'O arquivo de origem ainda não está no armazenamento local';

  @override
  String get importErrorCopyVerificationFailed =>
      'O arquivo copiado não corresponde à origem';

  @override
  String get importErrorFileTooLarge =>
      'O arquivo excede o limite de importação de 500 MB';

  @override
  String get importErrorSourcePrepareFailed =>
      'Não é possível preparar o arquivo de importação';

  @override
  String get importErrorFailed => 'Falha na importação do livro';

  @override
  String get importUnknownTitle => 'Título desconhecido';

  @override
  String get importUnknownAuthor => 'Autor desconhecido';

  @override
  String get bookUntitled => 'Sem título';

  @override
  String get accentPurple => 'Roxo elegante';

  @override
  String get accentPink => 'Rosa-cereja';

  @override
  String get accentCyan => 'Ciano fresco';

  @override
  String get accentBrown => 'Marrom clássico';

  @override
  String get accentGrey => 'Cinza elegante';

  @override
  String get accentDeepPurple => 'Roxo encantador';

  @override
  String get accentAmber => 'Âmbar dourado';

  @override
  String get accentLightGreen => 'Verde vívido';

  @override
  String get accentYellow => 'Amarelo ensolarado';

  @override
  String get accentNeutralGrey => 'Cinza minimalista';

  @override
  String get accentIndigo => 'Índigo profundo';

  @override
  String get accentDeepOrange => 'Laranja-chama';

  @override
  String get agreementV2HeroTitle =>
      'Continue lendo no seu próprio dispositivo.';

  @override
  String get agreementV2HeroBody =>
      'O Origo X é um leitor de e-books de código aberto, multiplataforma e local primeiro. Ele oferece ferramentas de leitura; não oferece, hospeda nem revisa os livros que você importa.';

  @override
  String get agreementV2LocalTitle => 'Local primeiro';

  @override
  String get agreementV2LocalBody =>
      'Livros, progresso e notas normalmente permanecem no seu dispositivo, para você gerenciar e fazer backup.';

  @override
  String get agreementV2OpenSourceTitle => 'Licenciado sob AGPL-3.0';

  @override
  String get agreementV2OpenSourceBody =>
      'O código-fonte é fornecido sob a GNU AGPL v3.0 e o software é entregue “no estado em que se encontra”, sem garantias.';

  @override
  String agreementV2VersionLabel(String version) {
    return 'Versão dos termos $version';
  }

  @override
  String get agreementFlowStepIntroduction => 'Introdução';

  @override
  String get agreementFlowStepTerms => 'Termos';

  @override
  String get agreementFlowStepSource => 'Fontes de livros';

  @override
  String get agreementFlowStepPrivacy => 'Privacidade';

  @override
  String get agreementFlowNext => 'Avançar';

  @override
  String get agreementFlowBack => 'Voltar';

  @override
  String get agreementFlowTermsTitle => 'Use o Origo X com limites claros';

  @override
  String get agreementFlowTermsSubtitle =>
      'Revise os termos que regem o uso do software e do conteúdo que você escolher abrir.';

  @override
  String get agreementFlowTermsConsent => 'Li e concordo com os Termos de uso.';

  @override
  String get agreementFlowSourceTitle =>
      'Acordo de fontes de livros de terceiros';

  @override
  String get agreementFlowSourceSubtitle =>
      'Confirme como endereços de fontes, conteúdo, autorização e responsabilidade são separados do projeto oficial.';

  @override
  String get agreementFlowSourceConsent =>
      'Li e concordo com o Acordo de fontes de livros de terceiros.';

  @override
  String get agreementFlowPrivacyTitle => 'Seus dados ficam sob seu controle';

  @override
  String get agreementFlowPrivacySubtitle =>
      'Revise o que permanece local, quando ocorrem solicitações de rede e como os registros de download são retidos.';

  @override
  String get agreementFlowPrivacyConsent =>
      'Li e concordo com o Aviso de privacidade.';

  @override
  String get agreementFlowEnterApp => 'Entrar no Origo X';

  @override
  String get agreementFlowPrivacyLocalTitle => 'Local por padrão';

  @override
  String get agreementFlowPrivacyLocalBody =>
      'Livros, progresso, notas e configurações normalmente permanecem neste dispositivo.';

  @override
  String get agreementFlowPrivacyNetworkTitle => 'O uso da rede é explícito';

  @override
  String get agreementFlowPrivacyNetworkBody =>
      'A leitura local não envia o texto dos livros. As verificações de atualização contatam o GitHub e o site oficial; fontes, AI e sincronização conectam-se apenas quando seus recursos são usados.';

  @override
  String get agreementFlowPrivacyRetentionTitle =>
      'Registros de download limitados';

  @override
  String get agreementFlowPrivacyRetentionBody =>
      'Registros de download do site oficial contendo um IP bruto são mantidos por no máximo 180 dias e depois excluídos.';

  @override
  String get agreementV2Title => 'Termos de uso e Aviso de privacidade';

  @override
  String get agreementV2Subtitle => 'Leia antes de usar o Origo X';

  @override
  String get agreementV2ImportantNotice =>
      'Importante: o app oficial do Origo X não pré-instala, agrupa nem recomenda nenhuma fonte de livros de terceiros, e seus desenvolvedores não operam, representam nem hospedam conteúdo de fontes. Você escolhe cada arquivo importado e cada fonte que adiciona; use somente conteúdo que você esteja autorizado a acessar.';

  @override
  String get agreementV2SourceBoundaryTitle => 'Limite das fontes de terceiros';

  @override
  String get agreementV2SourceBoundaryPoint1 =>
      'O projeto oficial fornece apenas o software de leitura de código aberto e o Origo Source Protocol. Ele não fornece endereços de fontes nem um diretório oficial de fontes.';

  @override
  String get agreementV2SourceBoundaryPoint2 =>
      'Cada endereço de fonte deve ser digitado e adicionado por você. O app conecta-se diretamente a esse serviço independente, sem rotear o conteúdo por um servidor dos desenvolvedores.';

  @override
  String get agreementV2SourceBoundaryPoint3 =>
      'Compatibilidade de protocolo significa apenas que uma interface pode conectar; não comprova legalidade ou licenciamento. Os operadores das fontes são responsáveis pelo conteúdo, e você deve revisá-lo e usá-lo de forma lícita.';

  @override
  String get agreementV2Section1Title => 'Escopo e aceitação';

  @override
  String get agreementV2Section1Body =>
      'Estes termos se aplicam ao download, à instalação e ao uso do Origo X e dos recursos incluídos. Ao selecionar “Concordar e continuar”, você confirma que leu, entendeu e os aceitou. Se não concordar, pare de usar e saia do app. Um responsável deve consentir onde exigido pela lei local.';

  @override
  String get agreementV2Section2Title => 'Licença de código aberto';

  @override
  String get agreementV2Section2Body =>
      'Versões futuras do Origo X são lançadas sob a GNU Affero General Public License v3.0. Você pode usar, copiar, modificar, distribuir ou vender o software sob essa licença. Uma versão modificada distribuída deve fornecer seu código-fonte correspondente completo sob AGPL-3.0, e uma versão modificada usada para fornecer um serviço de rede também deve oferecer o código correspondente aos usuários que interajam com ela. Os direitos MIT já concedidos para a v1.0.0 e versões anteriores permanecem válidos e não são revogados. Estes termos não restringem direitos concedidos pela licença de código aberto. Componentes de terceiros permanecem sujeitos às suas próprias licenças.';

  @override
  String get agreementV2Section3Title => 'Conteúdo do usuário e direitos';

  @override
  String get agreementV2Section3Body =>
      '“Conteúdo do usuário” inclui livros, documentos, imagens, metadados, links e outros materiais que você importa, baixa, abre, converte, armazena em cache, anota ou lê em voz alta. Você deve ter todos os direitos e permissões necessários para usá-lo. Você é o único responsável por direitos autorais, marcas, privacidade, difamação, conteúdo ilegal, malware e outras reivindicações ou perdas envolvendo conteúdo do usuário. O software e seus desenvolvedores não enviam, vendem, licenciam, endossam nem revisam esse conteúdo, e o suporte a um formato não implica permissão legal para usar um arquivo.';

  @override
  String get agreementV2Section4Title => 'Uso proibido';

  @override
  String get agreementV2Section4Body =>
      'Você não pode usar o software para infringir propriedade intelectual ou outros direitos; distribuir conteúdo ilegal, nocivo ou malicioso; burlar gerenciamento de direitos digitais, controles de acesso ou pagamentos; atacar ou perturbar sistemas de terceiros; ou praticar atividade proibida pela lei aplicável. Você é responsável por reclamações, reivindicações, penalidades e perdas resultantes da sua conduta.';

  @override
  String get agreementV2Section5Title => 'Fontes de livros e terceiros';

  @override
  String get agreementV2Section5Body =>
      'O app oficial não pré-instala, distribui nem recomenda fontes de livros e não opera um diretório oficial de fontes. Fontes, APIs de rede, links externos, conteúdo online, texto para fala do sistema, serviços de AI e outras integrações que você adiciona são fornecidos e controlados independentemente por terceiros. Eles não são operados, representados, licenciados, endossados nem revisados pelos desenvolvedores. Os operadores das fontes são legalmente responsáveis pelo conteúdo que fornecem. Antes de adicionar uma, você deve revisar sua origem, direitos de conteúdo, política de privacidade e termos, e é responsável pelo próprio acesso, downloads, cache, distribuição e outros usos. Na máxima extensão permitida pela lei aplicável, os desenvolvedores não se responsabilizam por conteúdo de terceiros, cobranças, práticas de dados, interrupções ou disputas de infração.';

  @override
  String get agreementV2Section6Title => 'Dados e privacidade';

  @override
  String get agreementV2Section6Body =>
      'O Origo X é local primeiro. Livros, progresso de leitura, notas e configurações normalmente ficam armazenados no seu dispositivo. Salvo quando você ativa uma fonte de livros em rede, AI, sincronização ou outro recurso online, o app não precisa enviar o texto dos livros aos desenvolvedores para oferecer leitura local. As verificações automáticas e manuais de atualização contatam o GitHub e o site oficial em open.xxread.top com parâmetros técnicos necessários, como plataforma, arquitetura do processador e canal de lançamento; os servidores deles processam seu endereço IP e User-Agent como parte da comunicação de rede comum. Quando você baixa um instalador do site oficial, o backend registra a versão, a arquitetura, o horário do download, o endereço IP e o User-Agent para contagens de download, proteção de segurança e diagnóstico. Registros de eventos de download contendo um IP bruto são retidos por no máximo 180 dias e depois excluídos; apenas estatísticas agregadas, sem endereços IP brutos, são mantidas por mais tempo. As solicitações de atualização não incluem texto de livros, sua estante, notas, uma conta ou um identificador único de dispositivo. As solicitações ao GitHub também são regidas pelos termos de privacidade do GitHub. Quando outro recurso online é usado, consultas, texto selecionado, informações de rede ou parâmetros necessários podem ser enviados ao provedor que você escolheu, sob as políticas desse provedor. Proteja seu dispositivo, API keys e backups; desinstalar, limpar dados, falha do dispositivo ou erro do usuário pode apagar dados permanentemente.';

  @override
  String get agreementV2Section7Title => 'AI e resultados automatizados';

  @override
  String get agreementV2Section7Body =>
      'Resumos, respostas, traduções, recomendações e outros resultados gerados por AI podem ser imprecisos, incompletos, desatualizados ou enganosos. São apenas auxílios de leitura e não constituem aconselhamento jurídico, médico, financeiro, acadêmico ou outro conselho profissional. Verifique os resultados de forma independente e não dependa deles para decisões de alto risco. O material enviado a um provedor de AI também é regido pelos termos desse provedor.';

  @override
  String get agreementV2Section8Title => 'Isenção de garantias';

  @override
  String get agreementV2Section8Body =>
      'Na máxima extensão permitida pela lei, o software e os materiais relacionados são fornecidos “no estado em que se encontram” e “conforme disponíveis”, sem garantias expressas, implícitas ou legais, incluindo comercialização, adequação a um propósito específico, titularidade, não infração, exatidão, compatibilidade, segurança, operação sem erros, disponibilidade ininterrupta ou preservação de dados. Colaboradores de código aberto não têm o dever de manter, atualizar, dar suporte ou corrigir o software.';

  @override
  String get agreementV2Section9Title => 'Limitação de responsabilidade';

  @override
  String get agreementV2Section9Body =>
      'Na máxima extensão permitida pela lei, desenvolvedores, detentores de direitos autorais e colaboradores não são responsáveis por perdas diretas, indiretas, incidentais, especiais, punitivas ou consequenciais decorrentes de instalação, uso, impossibilidade de uso, conteúdo do usuário, serviços de terceiros, perda de dados, problemas de dispositivo, interrupção de negócios ou incidentes de segurança, seja sob contrato, ato ilícito ou outra teoria. A responsabilidade que não puder ser legalmente excluída permanece limitada à extensão mínima permitida pela lei.';

  @override
  String get agreementV2Section10Title => 'Indenização';

  @override
  String get agreementV2Section10Body =>
      'Na extensão permitida pela lei aplicável, você é responsável e isentará desenvolvedores, detentores de direitos autorais e colaboradores de reivindicações de terceiros, investigações, penalidades, perdas e custos razoáveis decorrentes do seu conteúdo do usuário, conduta ilegal ou infratora, violação destes termos ou uso de serviços de terceiros.';

  @override
  String get agreementV2Section11Title => 'Mudanças, rescisão e lei';

  @override
  String get agreementV2Section11Body =>
      'Recursos, estado de manutenção e estes termos podem mudar conforme o projeto de código aberto, a lei ou os controles de risco evoluem. Atualizações significativas podem exigir novo consentimento; se você discordar, pare de usar o app. Você pode desinstalar a qualquer momento. Disputas devem primeiro ser resolvidas informalmente. Sujeito às proteções obrigatórias ao consumidor, aplicam-se a lei do local do desenvolvedor e os tribunais com jurisdição legal. Se uma disposição for inexequível, as demais permanecem em vigor.';

  @override
  String get agreementV2ConfirmLabel =>
      'Li e concordo com os Termos de uso e o Aviso de privacidade.';

  @override
  String get agreementV2SourceConfirmLabel =>
      'Entendo que o projeto oficial não fornece fontes de livros; fontes e conteúdo que eu adicionar vêm de terceiros independentes, e eu verificarei a autorização e permanecerei responsável pelo meu próprio uso.';

  @override
  String get agreementV2ExitLabel => 'Recusar';

  @override
  String get agreementV2ContinueLabel => 'Concordar e continuar';

  @override
  String get agreementV2ExitDialogTitle => 'Recusar os termos?';

  @override
  String get agreementV2ExitDialogBody =>
      'Você deve aceitar os Termos de uso para continuar usando o Origo X. Se não concordar, saia do app.';

  @override
  String get agreementV2CancelLabel => 'Voltar';

  @override
  String get agreementV2ConfirmExitLabel => 'Sair';

  @override
  String get agreementV2SaveFailed =>
      'Não foi possível salvar seu consentimento. Tente novamente.';

  @override
  String get settingsDataSyncTitle => 'Dados e sincronização';

  @override
  String get settingsCacheManagementTitle => 'Gerenciamento de cache';

  @override
  String settingsCacheManagementSubtitle(String size) {
    return 'Usando $size · Veja detalhes e limpe caches';
  }

  @override
  String get settingsCacheUsageTitle => 'Uso de cache';

  @override
  String get settingsCacheTotalUsage => 'Total usado';

  @override
  String get settingsCacheSafeHint =>
      'Apenas caches removíveis com segurança são exibidos. Livros, progresso de leitura e configurações não estão incluídos.';

  @override
  String get settingsCacheSourceCovers => 'Cache de capas de fontes';

  @override
  String settingsCacheSourceCoversSubtitle(String size) {
    return 'Capas de fontes baixadas · $size';
  }

  @override
  String get settingsCacheSourceData => 'Cache de capítulos de fontes';

  @override
  String settingsCacheSourceDataSubtitle(String size) {
    return 'Cache de capítulos online removível com segurança · $size';
  }

  @override
  String get settingsCacheReadingCache => 'Cache de leitura local';

  @override
  String settingsCacheReadingCacheSubtitle(String size) {
    return 'Cache de análise de EPUB/TXT/Kindle reconstruível · $size';
  }

  @override
  String get settingsCacheTemporaryFiles => 'Arquivos temporários';

  @override
  String settingsCacheTemporaryFilesSubtitle(String size) {
    return 'Arquivos descartáveis de atualização e temporários · $size';
  }

  @override
  String get settingsCacheClearAll => 'Limpar todos os caches seguros';

  @override
  String settingsCacheClearAllSubtitle(String size) {
    return 'Limpa apenas as categorias acima · $size';
  }

  @override
  String get settingsCacheCalculating => 'Calculando…';

  @override
  String get settingsCacheClearConfirm =>
      'Isto remove apenas dados de cache temporários. Livros, capas salvas, progresso de leitura, bancos de dados, configurações e credenciais são preservados.';

  @override
  String get settingsCacheClearAction => 'Limpar';

  @override
  String get settingsCacheCleared => 'Cache limpo';

  @override
  String get settingsCacheClearFailed => 'Não foi possível limpar o cache';

  @override
  String get settingsWebDavSyncTitle => 'Sincronização WebDAV';

  @override
  String get webDavNotConfigured => 'Não configurado';

  @override
  String get webDavConfigureSubtitle =>
      'Sincronize os dados de leitura no seu próprio armazenamento WebDAV';

  @override
  String get webDavBetaBadge => 'Beta · Pode ser instável';

  @override
  String get webDavPageTitle => 'Sincronização WebDAV';

  @override
  String get webDavConnected => 'Conectado';

  @override
  String get webDavSyncing => 'Sincronizando';

  @override
  String get webDavPartialFailure => 'Alguns itens precisam de atenção';

  @override
  String get webDavSyncFailed => 'Falha na sincronização';

  @override
  String webDavPendingChanges(int count) {
    return '$count alterações aguardando sincronização';
  }

  @override
  String webDavLastSync(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get webDavNeverSynced => 'Ainda não sincronizado';

  @override
  String get webDavSyncNow => 'Sincronizar agora';

  @override
  String get webDavSetUp => 'Configurar WebDAV';

  @override
  String get webDavConnectionTitle => 'Conexão';

  @override
  String get webDavServerUrl => 'Endereço WebDAV';

  @override
  String get webDavUsername => 'Nome de usuário';

  @override
  String get webDavPassword => 'Senha de app';

  @override
  String get webDavPasswordHint =>
      'Armazenada com segurança apenas neste dispositivo';

  @override
  String get webDavRootPath => 'Pasta remota';

  @override
  String get webDavTestConnection => 'Testar conexão';

  @override
  String get webDavTestingConnection => 'Testando conexão…';

  @override
  String get webDavConnectionSuccess =>
      'Conexão e permissão de gravação verificadas';

  @override
  String webDavConnectionFailed(String reason) {
    return 'Falha no teste de conexão: $reason';
  }

  @override
  String get webDavSaveConfiguration => 'Salvar configuração';

  @override
  String get webDavAutomaticSync => 'Sincronização automática';

  @override
  String get webDavAutomaticSyncHint =>
      'Sincroniza após iniciar ou quando o app volta ao primeiro plano';

  @override
  String get webDavSyncContent => 'Conteúdo da sincronização';

  @override
  String get webDavScopeBookSources => 'Fontes de livros';

  @override
  String get webDavScopeBookSourcesHint =>
      'Sincroniza fontes ORSP públicas e favoritas, além de todos os nomes de grupos, grupos vazios e sua ordem. Credenciais de fontes e configurações privadas ficam neste dispositivo.';

  @override
  String get webDavScopeBooks => 'Estante e livros online';

  @override
  String get webDavScopeProgress => 'Progresso de leitura';

  @override
  String get webDavScopeBookmarks => 'Marcadores';

  @override
  String get webDavScopeNotes => 'Notas e destaques';

  @override
  String get webDavScopeNotesHint =>
      'Inclui trechos citados, notas e tinta. Os dados do WebDAV não são criptografados de ponta a ponta.';

  @override
  String get webDavScopeReadingSessions => 'Estatísticas de leitura';

  @override
  String get webDavScopeReaderSettings => 'Configurações do leitor';

  @override
  String get webDavScopeReaderSettingsHint =>
      'Sincroniza tipografia, temas, virada de página, preferências de paginação automática, zonas de toque e preferências do leitor de imagens.';

  @override
  String get webDavScopeReplaceRules => 'Regras de substituição';

  @override
  String get webDavScopeReplaceRulesHint =>
      'Sincroniza padrões das regras e texto de substituição. Os dados do WebDAV não são criptografados de ponta a ponta.';

  @override
  String get webDavScopeBookFiles => 'Arquivos de livros';

  @override
  String get webDavBookFilesHint => 'Escolha quais livros enviar ou baixar';

  @override
  String get webDavBookFilesUnavailable =>
      'A transferência de arquivos de livros será ativada quando a sincronização de metadados estiver estável';

  @override
  String get webDavSecurityNotice =>
      'Os dados são enviados por HTTPS, mas seu provedor WebDAV pode ler o conteúdo remoto não criptografado.';

  @override
  String get webDavConnectionDetails => 'Configurações de conexão';

  @override
  String get webDavClearConfiguration => 'Limpar configuração';

  @override
  String get webDavClearConfigurationTitle =>
      'Limpar a configuração do WebDAV?';

  @override
  String get webDavClearConfigurationMessage =>
      'Isto remove o endereço e o login do WebDAV deste dispositivo. Os dados de leitura locais e os arquivos remotos não serão excluídos.';

  @override
  String get webDavClearConfigurationConfirm => 'Limpar deste dispositivo';

  @override
  String get webDavActivityTitle => 'Atividade de sincronização';

  @override
  String get webDavActivityEmpty => 'Ainda não há atividade de sincronização';

  @override
  String webDavSyncCompleteSummary(int uploaded, int downloaded) {
    return '$uploaded enviados, $downloaded baixados';
  }

  @override
  String get webDavErrorAuthentication =>
      'O nome de usuário, a senha ou a permissão da pasta está incorreta.';

  @override
  String get webDavErrorInvalidConfiguration =>
      'A configuração do WebDAV está incompleta ou inválida.';

  @override
  String get webDavErrorInsecureConnection =>
      'A conexão não atende aos requisitos de segurança.';

  @override
  String get webDavErrorCertificate =>
      'Não foi possível verificar o certificado do servidor.';

  @override
  String get webDavErrorPermission => 'A pasta remota não permite gravação.';

  @override
  String get webDavErrorNotFound =>
      'A pasta de sincronização remota ou um arquivo necessário não foi encontrada.';

  @override
  String get webDavErrorConflict =>
      'Os dados remotos estão em conflito. Tente sincronizar novamente.';

  @override
  String get webDavErrorStorageFull => 'O armazenamento WebDAV está cheio.';

  @override
  String get webDavErrorRateLimited =>
      'Foram feitas muitas solicitações WebDAV. Tente novamente mais tarde.';

  @override
  String get webDavErrorTimeout => 'O servidor não respondeu a tempo.';

  @override
  String get webDavErrorUnsupported =>
      'A resposta do servidor é incompatível com o protocolo de sincronização.';

  @override
  String get webDavErrorServer =>
      'O servidor WebDAV não pôde concluir a solicitação.';

  @override
  String get webDavErrorNetwork =>
      'A rede está indisponível. As alterações permanecem salvas neste dispositivo.';

  @override
  String get webDavErrorCorruptData =>
      'Alguns dados de sincronização remotos estão danificados e não foram aplicados.';

  @override
  String get webDavErrorLocalDataCorrupt =>
      'As configurações de leitura locais estão danificadas. A sincronização parou sem excluir o backup remoto.';

  @override
  String get webDavErrorClockSkew =>
      'O relógio deste dispositivo difere demais do servidor WebDAV.';

  @override
  String get webDavErrorSecureStorage =>
      'Não foi possível ler a senha do WebDAV no armazenamento seguro.';

  @override
  String get webDavErrorUnknown => 'O WebDAV não pôde concluir a operação.';

  @override
  String get webDavErrorDetails => 'Detalhes da resposta do servidor';

  @override
  String get webDavErrorMissingEtagDetail =>
      'O servidor não retornou um identificador forte de versão do arquivo (ETag). O ETag pode estar ausente ou fraco demais, então o app não consegue saber se outro dispositivo alterou o arquivo remoto.';

  @override
  String get webDavErrorIfMatchIgnoredDetail =>
      'O servidor ignorou a condição que permite gravar apenas quando a versão do arquivo corresponde (If-Match). Continuar pode sobrescrever uma alteração mais recente de outro dispositivo.';

  @override
  String get webDavErrorIfNoneMatchIgnoredDetail =>
      'O servidor ignorou a condição que permite criar apenas quando o arquivo não existe (If-None-Match). Continuar pode sobrescrever um arquivo existente.';

  @override
  String webDavErrorReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String webDavErrorHttpStatus(int status) {
    return 'Status HTTP: $status';
  }

  @override
  String webDavErrorRequestMethod(String method) {
    return 'Método da solicitação: $method';
  }

  @override
  String webDavErrorResourcePath(String path) {
    return 'Caminho do recurso: $path';
  }

  @override
  String webDavErrorPhase(String phase) {
    return 'Falha enquanto: $phase';
  }

  @override
  String get webDavPhaseConnecting => 'conectando ao servidor remoto';

  @override
  String get webDavPhaseScanningLocal => 'escaneando este dispositivo';

  @override
  String get webDavPhaseReadingRemote => 'lendo dados remotos';

  @override
  String get webDavPhaseApplyingRemote => 'mesclando dados remotos';

  @override
  String get webDavPhaseUploadingLocal => 'enviando alterações locais';

  @override
  String get webDavPhaseFinishing => 'finalizando a sincronização';

  @override
  String get webDavPhaseUnknown => 'uma etapa desconhecida';

  @override
  String get webDavBookFilesTitle => 'Arquivos de livros';

  @override
  String get webDavFilesPendingUpload => 'A enviar';

  @override
  String get webDavFilesAvailableDownload => 'Disponíveis';

  @override
  String get webDavFilesSynced => 'Sincronizados';

  @override
  String get webDavFilesUploadSelected => 'Enviar selecionados';

  @override
  String get webDavFilesDownloadSelected => 'Baixar selecionados';

  @override
  String webDavFilesSelectedSummary(int count, String size) {
    return '$count selecionados · $size';
  }

  @override
  String get webDavFilesOnlyLocal => 'Apenas neste dispositivo';

  @override
  String get webDavFilesOnlyRemote => 'Arquivo não baixado neste dispositivo';

  @override
  String get webDavFilesUploadPermission =>
      'Permitir envio de arquivos de livros';

  @override
  String get webDavFilesUploadPermissionHint =>
      'Sincronize livros e capas selecionados. O TXT transfere apenas blocos alterados após o primeiro envio; EPUB e PDF mantêm os bytes originais. Arquivos completos legíveis são exportados separadamente.';

  @override
  String get webDavNewBookPolicyTitle => 'Novos arquivos de livros';

  @override
  String get webDavNewBookPolicyAsk => 'Perguntar toda vez (recomendado)';

  @override
  String get webDavNewBookPolicyAskHint =>
      'Escolha quais livros enviar após uma importação terminar';

  @override
  String get webDavNewBookPolicyAutomatic =>
      'Enviar novos livros automaticamente';

  @override
  String get webDavNewBookPolicyAutomaticHint =>
      'Envia imediatamente após a importação e pode usar dados móveis';

  @override
  String get webDavNewBookPolicyManual => 'Escolher sempre manualmente';

  @override
  String get webDavNewBookPolicyManualHint =>
      'Inicie envios apenas pela página Arquivos de livros';

  @override
  String webDavNewBooksPromptTitle(int count) {
    return 'Sincronizar os $count livros recém-importados?';
  }

  @override
  String get webDavNewBooksPromptBody =>
      'Os dados de leitura sincronizam automaticamente. Escolha os arquivos originais dos livros para enviar ao WebDAV.';

  @override
  String get webDavNewBooksSkip => 'Agora não';

  @override
  String webDavNewBooksUploading(int count) {
    return 'Enviando $count novos livros…';
  }

  @override
  String webDavNewBooksUploadResult(int success, int failed) {
    return 'Envio de novos livros concluído: $success com êxito, $failed com falha';
  }

  @override
  String get webDavFilesTooLarge =>
      'Este arquivo excede o limite de tamanho de sincronização para o formato dele';

  @override
  String get webDavFilesEmpty => 'Nenhum livro nesta categoria';

  @override
  String get webDavFilesTransferComplete =>
      'Transferência de arquivos de livros concluída';

  @override
  String get readerAddAnnotation => 'Adicionar anotação';

  @override
  String get readerAnnotationHint =>
      'Escreva suas impressões sobre esta passagem…';

  @override
  String get readerAnnotationSaved => 'Anotação salva';

  @override
  String get readerAnnotationDeleted => 'Anotação excluída';

  @override
  String get readerAnnotationShelfRequired =>
      'Adicione este livro à estante antes de salvar anotações';

  @override
  String get readerNoAnnotations => 'Ainda não há anotações';

  @override
  String get readerNoAnnotationsHint =>
      'Selecione texto para destacar ou adicionar um comentário. Toque em um comentário sublinhado para lê-lo novamente.';

  @override
  String get replaceRulesTitle => 'Substituir e limpar';

  @override
  String get replaceRulesSettingsSubtitle =>
      'Remova anúncios, promoções e outros textos indesejados durante a leitura';

  @override
  String get replaceRulesImport => 'Importar regras';

  @override
  String get replaceRulesExport => 'Exportar regras';

  @override
  String get replaceRulesSearchHint => 'Pesquisar nomes, grupos ou padrões';

  @override
  String get replaceRulesUnnamed => 'Regra sem nome';

  @override
  String get replaceRulesDeleteValue => 'Remover';

  @override
  String get replaceRulesCreate => 'Nova regra';

  @override
  String get replaceRulesEmptyTitle => 'Nenhuma regra de substituição';

  @override
  String get replaceRulesEmptyBody =>
      'Importe um arquivo JSON de fonte de leitura ou crie uma regra de expressão regular.';

  @override
  String get replaceRulesNoSearchResults => 'Nenhuma regra correspondente';

  @override
  String get replaceRulesCreateTitle => 'Nova regra de substituição';

  @override
  String get replaceRulesEditTitle => 'Editar regra de substituição';

  @override
  String get replaceRulesNameLabel => 'Nome da regra';

  @override
  String get replaceRulesPatternLabel =>
      'Texto ou expressão regular para corresponder';

  @override
  String get replaceRulesPatternHelper =>
      'Deixe a substituição vazia para remover o texto correspondente';

  @override
  String get replaceRulesReplacementLabel => 'Substituir por';

  @override
  String get replaceRulesRegexLabel => 'Usar expressão regular';

  @override
  String get replaceRulesScopeTitleLabel => 'Aplicar aos títulos de capítulos';

  @override
  String get replaceRulesScopeContentLabel =>
      'Aplicar ao conteúdo dos capítulos';

  @override
  String get replaceRulesGroupLabel => 'Grupo (opcional)';

  @override
  String get replaceRulesScopeLabel => 'Escopo (opcional)';

  @override
  String get replaceRulesScopeHelper =>
      'Separe títulos de livros ou nomes de fontes com ponto e vírgula';

  @override
  String get replaceRulesExcludeScopeLabel => 'Escopo excluído (opcional)';

  @override
  String get replaceRulesDeleteConfirmTitle => 'Excluir esta regra?';

  @override
  String get replaceRulesDeleteConfirmBody =>
      'A regra será removida deste dispositivo.';

  @override
  String replaceRulesImported(int count) {
    return '$count regras importadas';
  }

  @override
  String replaceRulesImportFailed(String error) {
    return 'Não foi possível importar regras: $error';
  }

  @override
  String replaceRulesImportTooLarge(String max) {
    return 'O arquivo de regras excede $max';
  }

  @override
  String get replaceRulesExported => 'Regras exportadas';

  @override
  String get replaceRulesPatternRequired =>
      'Digite um texto ou expressão regular para corresponder';

  @override
  String replaceRulesPatternTooLong(int max) {
    return 'O padrão excede $max caracteres';
  }

  @override
  String replaceRulesInvalidRegex(String error) {
    return 'Expressão regular inválida: $error';
  }

  @override
  String replaceRulesTooMany(int max) {
    return 'Há suporte a no máximo $max regras';
  }

  @override
  String get accountSecurityTitle => 'Segurança';

  @override
  String get accountSecurityLoading => 'Carregando status de segurança…';

  @override
  String get accountChangeEmailTitle => 'Alterar e-mail';

  @override
  String get accountChangeEmailEnterTitle => 'Escolha um novo e-mail';

  @override
  String get accountChangeEmailEnterHint =>
      'Enviaremos um código para seu e-mail atual e outro para o novo endereço.';

  @override
  String get accountChangeEmailVerifyTitle =>
      'Verifique os dois endereços de e-mail';

  @override
  String get accountChangeEmailVerifyHint =>
      'Digite os dois códigos para concluir a alteração do seu e-mail de login.';

  @override
  String get accountCurrentEmail => 'E-mail atual';

  @override
  String get accountNewEmail => 'Novo e-mail';

  @override
  String get accountCurrentEmailCode => 'Código enviado ao e-mail atual';

  @override
  String get accountNewEmailCode => 'Código enviado ao novo e-mail';

  @override
  String get accountSendBothCodes => 'Enviar os dois códigos';

  @override
  String get accountChangeEmailEnterRelayHint =>
      'Seu endereço atual é um e-mail de reencaminhamento oculto da Apple que não pode receber códigos. Um único código será enviado ao novo endereço.';

  @override
  String get accountChangeEmailVerifyRelayHint =>
      'Seu endereço atual é um e-mail de reencaminhamento oculto da Apple, então não é preciso código para ele. Digite o código enviado ao novo endereço para concluir.';

  @override
  String get accountCurrentPasswordInstead => 'Senha atual (em vez do código)';

  @override
  String get accountRelayEmailTitle =>
      'Você está usando um e-mail oculto da Apple';

  @override
  String get accountRelayEmailBody =>
      'Seu endereço de login é um endereço de reencaminhamento privado da Apple, então e-mails de verificação podem não chegar. Considere mudar para um endereço de e-mail que você usa no dia a dia.';

  @override
  String get accountChangeEmailAction => 'Alterar e-mail';

  @override
  String get accountEmailChanged => 'E-mail alterado';

  @override
  String get accountChangePasswordTitle => 'Definir ou alterar senha';

  @override
  String get accountPasswordEmailTitle => 'Verificar por e-mail';

  @override
  String get accountPasswordEmailHint =>
      'Envie um código para seu e-mail atual antes de escolher uma nova senha.';

  @override
  String get accountPasswordNewTitle => 'Escolha uma nova senha';

  @override
  String get accountPasswordNewHint =>
      'Digite o código do e-mail e defina a senha que você usará na próxima vez.';

  @override
  String get accountNewPassword => 'Nova senha';

  @override
  String get accountChangePasswordAction => 'Alterar senha';

  @override
  String get accountPasswordChanged => 'Senha alterada';

  @override
  String get accountPasswordsMismatch => 'As senhas não coincidem';

  @override
  String get accountMfaTitle => 'Autenticação de dois fatores';

  @override
  String get accountMfaEnabled =>
      'Ativada. Um autenticador ou código de recuperação não usado é exigido no login.';

  @override
  String get accountMfaDisabledByDefault =>
      'Desativada por padrão. Ative-a para proteger logins com senha e código por e-mail.';

  @override
  String get accountMfaOnTitle => 'A autenticação de dois fatores está ativada';

  @override
  String get accountMfaEmailTitle => 'Verifique seu e-mail primeiro';

  @override
  String accountMfaEmailHint(String email) {
    return 'Enviaremos um código de configuração para $email.';
  }

  @override
  String get accountMfaEmailCodeTitle => 'Digite o código do e-mail';

  @override
  String get accountMfaEmailCodeHint =>
      'Após a verificação, o código QR e a chave secreta do autenticador abrirão na próxima página.';

  @override
  String get accountMfaAuthenticatorTitle =>
      'Adicione o Origo X ao seu autenticador';

  @override
  String get accountMfaAuthenticatorHint =>
      'Escaneie o código QR ou digite a chave manualmente e depois digite o código de seis dígitos do autenticador.';

  @override
  String get accountMfaQrCodeLabel =>
      'Código QR de configuração do autenticador';

  @override
  String get accountMfaSecretLabel => 'Chave de configuração';

  @override
  String get accountMfaSecretCopied => 'Chave de configuração copiada';

  @override
  String get accountMfaRecoveryTitle => 'Salve seus códigos de recuperação';

  @override
  String get accountMfaChallengeTitle => 'Verificação de dois fatores';

  @override
  String get accountMfaChallengeHint =>
      'Digite o código do seu autenticador ou um código de recuperação não usado para acessar sua conta.';

  @override
  String get accountMfaCode => 'Código do autenticador';

  @override
  String get accountMfaOrRecoveryCode =>
      'Código do autenticador ou de recuperação';

  @override
  String get accountMfaVerify => 'Verificar e continuar';

  @override
  String get accountMfaSendSetupCode =>
      'Enviar código de configuração por e-mail';

  @override
  String get accountMfaContinueSetup => 'Continuar configuração';

  @override
  String get accountMfaSecretWarning =>
      'Adicione esta chave ao seu autenticador. Ela é exibida apenas durante a configuração.';

  @override
  String get accountMfaOpenAuthenticator => 'Abrir autenticador';

  @override
  String get accountMfaConfirm => 'Confirmar e ativar';

  @override
  String get accountMfaDisable => 'Desativar autenticação de dois fatores';

  @override
  String get accountMfaDisabled => 'Autenticação de dois fatores desativada';

  @override
  String get accountRecoveryCodesWarning =>
      'Salve estes códigos de recuperação agora. Cada código funciona uma vez, e esta lista não será exibida novamente.';

  @override
  String get accountCopyRecoveryCodes => 'Copiar códigos de recuperação';

  @override
  String get accountRecoveryCodesCopied => 'Códigos de recuperação copiados';

  @override
  String get accountRecoveryCodesSaved => 'Salvei estes códigos';

  @override
  String get accountPremiumLifetime => 'Premium vitalício desbloqueado';

  @override
  String get accountPremiumLifetimeSubtitle =>
      'O Premium fica vinculado a esta conta e sincroniza entre plataformas suportadas.';

  @override
  String get accountRedemptionCode => 'Código de Premium vitalício';

  @override
  String get accountRedeemPremium => 'Resgatar e desbloquear para sempre';

  @override
  String get accountApplePurchase => 'Desbloquear para sempre pela App Store';

  @override
  String get accountApplePurchaseHint =>
      'Uma compra única vincula o Premium permanentemente a esta conta do Origo X e o sincroniza com as plataformas suportadas.';

  @override
  String get accountAppleProductLoading => 'Carregando informações do produto…';

  @override
  String get accountAppleProductRetry =>
      'Não foi possível carregar as informações do produto. Toque para tentar novamente.';

  @override
  String get accountAppleRestore => 'Restaurar compras';

  @override
  String get accountApplePurchasePending =>
      'A compra aguarda aprovação da App Store';

  @override
  String get accountApplePurchaseSubmitted =>
      'Compra enviada; verificando acesso ao Premium';

  @override
  String get accountAppleRestoreSubmitted => 'Restauração de compra solicitada';

  @override
  String get accountPremiumUnlocked => 'Premium vitalício desbloqueado';

  @override
  String get accountPremiumUnlockedReferral =>
      'Resgatado: você e quem o convidou desbloquearam o Premium vitalício';

  @override
  String get accountInviteTitle => 'Convidar amigos';

  @override
  String get accountInviteSubtitle =>
      'Quando um amigo vincula seu código e resgata um código de Premium vitalício, vocês dois desbloqueiam o Premium para sempre.';

  @override
  String get accountInviteMyCode => 'Meu código de convite';

  @override
  String get accountInviteCopyCode => 'Copiar código de convite';

  @override
  String get accountInviteCopyLink => 'Copiar link de convite';

  @override
  String get accountInviteShareAction =>
      'Copiar link de convite para compartilhar';

  @override
  String get accountInviteCopied => 'Detalhes do convite copiados';

  @override
  String accountInviteStats(int invited, int rewarded) {
    return '$invited convidados · $rewarded bem-sucedidos';
  }

  @override
  String get accountInviteStatsInvited => 'Códigos vinculados';

  @override
  String get accountInviteStatsRewarded => 'Recompensas desbloqueadas';

  @override
  String accountInviterBound(String name) {
    return 'Convidado por $name';
  }

  @override
  String get accountInviteRewarded => 'Convite concluído';

  @override
  String get accountInviteWaiting => 'Aguardando resgate do código';

  @override
  String get accountInviteBindLabel => 'Código de convite do amigo';

  @override
  String get accountInviteBindHint =>
      'Uma conta pode vincular uma vez e não pode alterar depois';

  @override
  String get accountInviteBindAction => 'Vincular código de convite';

  @override
  String get accountInviteBound => 'Código de convite vinculado';

  @override
  String get accountInviteHowItWorks => 'Como funciona';

  @override
  String get accountInviteStepShareTitle => 'Compartilhe o link';

  @override
  String get accountInviteStepShareBody =>
      'Envie o link ou código a um amigo. Ele abre e cria uma conta.';

  @override
  String get accountInviteStepBindTitle => 'Vincule o código';

  @override
  String get accountInviteStepBindBody =>
      'Seu amigo digita seu código em Conta. Cada conta pode vincular uma vez.';

  @override
  String get accountInviteStepRedeemTitle => 'Resgate um código';

  @override
  String get accountInviteStepRedeemBody =>
      'Quando ele resgatar um código de Premium vitalício, as duas contas desbloqueiam o Premium imediatamente.';

  @override
  String get accountInviteMyBinding => 'Meu vínculo de convite';

  @override
  String get accountInviteBindIntro =>
      'Se alguém o convidou, vincule o código aqui para manter a recompensa anexada à sua conta.';

  @override
  String get accountInviteBindingNotNeeded =>
      'Esta conta já tem Premium, então não é preciso código de convite.';

  @override
  String get readingDataExportAction => 'Exportar dados de leitura';

  @override
  String get readingDataExportSubtitle => 'Destaques, sublinhados e notas';

  @override
  String get readingDataExportWholeBook => 'Livro inteiro';

  @override
  String get readingDataExportWholeBookHint =>
      'Exporta todas as suas anotações neste livro. O texto do livro e o arquivo de origem não são incluídos.';

  @override
  String get readingDataExportPrivacySummary =>
      'Inclui trechos destacados ou sublinhados e suas notas privadas. O arquivo do livro, o texto completo, dados da conta e informações do dispositivo não são incluídos.';

  @override
  String readingDataExportCounts(int highlights, int underlines, int notes) {
    return '$highlights destaques · $underlines sublinhados · $notes notas';
  }

  @override
  String readingDataExportButton(int count) {
    return 'Exportar $count anotações';
  }

  @override
  String get readingDataExportPreparing => 'Preparando Markdown…';

  @override
  String get readingDataExportEmpty =>
      'Este livro não tem destaques, sublinhados ou notas para exportar.';

  @override
  String readingDataExportSuccess(String location) {
    return 'Dados de leitura exportados para $location';
  }

  @override
  String get readingDataExportFailed =>
      'Não foi possível exportar os dados de leitura';

  @override
  String get readingDataExportUnsupported =>
      'A exportação de dados de leitura ainda não é suportada nesta plataforma';

  @override
  String get readingDataExportReplaceTitle => 'Substituir arquivo existente?';

  @override
  String readingDataExportReplaceMessage(String path) {
    return 'Já existe um arquivo em $path. Substituí-lo não pode ser desfeito.';
  }

  @override
  String get readingDataExportReplaceAction => 'Substituir';

  @override
  String get readingDataExportExportedAt => 'Exportado';

  @override
  String get readingDataExportAuthor => 'Autor';

  @override
  String get readingDataExportContents => 'Conteúdo';

  @override
  String get readingDataExportMyNote => 'Minha nota';

  @override
  String readingDataExportPositionPage(int page) {
    return 'Página $page';
  }

  @override
  String get readingDataExportUnknownChapter => 'Anotações sem localização';

  @override
  String get cloudSyncTitle => 'Sincronização na nuvem';

  @override
  String get cloudSyncTagline => 'Continue de onde parou em outro dispositivo';

  @override
  String get cloudSyncResumeTitle => 'Continue entre dispositivos';

  @override
  String get cloudSyncAutoResume => 'Retomar ao abrir um livro';

  @override
  String get cloudSyncAutoResumeHint =>
      'Verifica a posição mais recente ao abrir; oferece atualizações durante a leitura';

  @override
  String get cloudSyncAutoHint =>
      'Salva o progresso durante a leitura e verifica atualizações ao abrir um livro';

  @override
  String get cloudSyncMoreContent => 'Mais opções de sincronização';

  @override
  String get cloudSyncBooks => 'Livros e texto';

  @override
  String get cloudSyncBooksHint =>
      'Livros participantes, atualizações e downloads de texto';

  @override
  String get cloudSyncActivity => 'Detalhes e problemas de sincronização';

  @override
  String get cloudSyncStorage => 'Conexão de armazenamento';

  @override
  String get cloudSyncNoActivity => 'Ainda não há atividade de sincronização';

  @override
  String get cloudSyncProgress => 'Posição de leitura';

  @override
  String get cloudSyncText => 'Arquivos de texto dos livros';

  @override
  String get cloudSyncMetadataComplete =>
      'Dados de leitura selecionados trocados com o WebDAV';

  @override
  String get cloudSyncPaused => 'A sincronização automática está pausada';

  @override
  String get cloudSyncLocalOnly => 'Manter neste dispositivo';

  @override
  String get cloudSyncCheckHint =>
      'Uma conexão não confirma o recebimento em outros dispositivos; verifique cada item abaixo';

  @override
  String get cloudSyncPendingFiles =>
      'Atualizações de texto precisam de atenção';

  @override
  String get cloudSyncFileIdle =>
      'Arquivos de texto vinculados serão verificados na próxima sincronização';

  @override
  String get cloudSyncManageBooks => 'Escolher livros e downloads';

  @override
  String get cloudSyncNoBooks => 'Ainda não há livros TXT vinculados';

  @override
  String get cloudSyncCompare => 'Comparar versões';

  @override
  String get cloudSyncKeepLocal => 'Usar a versão deste dispositivo';

  @override
  String get cloudSyncUseRemote => 'Usar a versão da nuvem';

  @override
  String get cloudSyncBothKept =>
      'As duas versões foram preservadas. A sincronização continua após sua escolha.';

  @override
  String get cloudSyncPreviewLimited =>
      'A prévia mostra a primeira diferença. As duas versões completas são preservadas.';

  @override
  String get cloudSyncPending => 'Aguardando sincronização';

  @override
  String get cloudSyncConflict => 'Versões precisam de revisão';

  @override
  String get cloudSyncCurrent => 'O texto atual está sincronizado com o WebDAV';

  @override
  String get cloudSyncFailed =>
      'Sincronização incompleta. Nova tentativa disponível.';

  @override
  String get cloudSyncHistory => 'Histórico de versões';

  @override
  String get cloudSyncApplyUpdate => 'Aplicar atualização de texto';

  @override
  String get cloudSyncParticipate => 'Sincronizar o texto deste livro';

  @override
  String get cloudSyncCloseReaderToUpdate =>
      'Feche o leitor ou o editor deste livro antes de aplicar a atualização de texto';

  @override
  String get cloudSyncTextLocation => 'Arquivo atual na nuvem';

  @override
  String get cloudSyncTextLocationHint =>
      'Gerencie aqui atualizações, pausas e conflitos dos livros participantes.';

  @override
  String get bookSourcesImportIntro =>
      'Detecta fontes automaticamente. Revise antes de importar.';

  @override
  String get bookSourcesImportInputStep => 'Escolher fonte';

  @override
  String get bookSourcesImportReviewStep => 'Revisar e importar';

  @override
  String get bookSourcesImportFileHint =>
      'Selecione um arquivo JSON de fontes.';

  @override
  String get bookSourcesImportDownloading => 'Baixando fonte…';

  @override
  String get bookSourcesImportAnalyzing =>
      'Lendo regras e verificando duplicatas…';

  @override
  String get bookSourcesImportSaving => 'Salvando fontes…';

  @override
  String get bookSourcesImportPicking => 'Abrindo seletor de arquivos…';

  @override
  String get bookSourcesImportWaitHint =>
      'Listas de fontes grandes podem demorar mais. Você pode cancelar e tentar novamente.';

  @override
  String get bookSourcesImportSaveHint =>
      'Mantenha esta janela aberta até o salvamento terminar.';

  @override
  String get bookSourcesImportReady => 'Pronto para importar';

  @override
  String get bookSourcesImportEmpty =>
      'Nenhuma fonte selecionada. Verifique o arquivo ou a seleção de duplicatas.';

  @override
  String get bookSourcesImportRetry => 'Tentar novamente';

  @override
  String get bookSourcesImportFailed =>
      'Não foi possível ler as fontes. Verifique o endereço ou o arquivo e tente novamente.';

  @override
  String get bookSourcesImportWebPage =>
      'Esta URL retornou um site ou página de login. Copie o link JSON de download de fontes ou de assinatura do site e importe-o. Você pode entrar depois de importar a fonte.';

  @override
  String get bookSourcesImportSaveFailed =>
      'Não foi possível salvar as fontes. Sua prévia foi mantida; tente novamente.';

  @override
  String get bookSourcesImportErrorDetails => 'Detalhes do erro';

  @override
  String get bookSourcesImportFileUnreadable =>
      'Não foi possível ler o arquivo selecionado. Escolha-o novamente.';

  @override
  String bookSourcesImportAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count fontes',
      one: 'Importar 1 fonte',
    );
    return '$_temp0';
  }

  @override
  String get bookSourcesImportFileTab => 'Arquivo JSON';

  @override
  String get bookSourcesImportTimedOut =>
      'A leitura demorou demais. Verifique sua conexão ou tente importar um arquivo JSON baixado.';

  @override
  String get bookSourcesImportUsageNotice => 'Informações de uso das fontes';

  @override
  String get bookSourcesMaintenanceScope => 'Escopo';

  @override
  String get bookSourcesMaintenanceScopeEnabled => 'Ativadas';

  @override
  String get bookSourcesMaintenanceScopeAll => 'Todas as fontes';

  @override
  String get bookSourcesMaintenanceScopeSelected => 'Selecionadas';

  @override
  String bookSourcesMaintenanceCount(int count) {
    return '$count fontes neste escopo';
  }

  @override
  String get bookSourcesMaintenanceEmptyScope => 'Nenhuma fonte neste escopo';

  @override
  String get bookSourcesMaintenanceCancelledTitle => 'Verificação interrompida';

  @override
  String get bookSourcesMaintenanceCancellingTitle =>
      'Interrompendo verificações';

  @override
  String get bookSourcesMaintenanceCancellingHint =>
      'Concluindo verificações ativas e mantendo resultados já obtidos';

  @override
  String get bookSourcesMaintenanceFailedTitle => 'Verificação interrompida';

  @override
  String get bookSourcesMaintenanceResume => 'Retomar verificações restantes';

  @override
  String get bookSourcesMaintenanceRetry =>
      'Repetir verificações não resolvidas';

  @override
  String bookSourcesMaintenanceRemaining(int count) {
    return '$count fontes ainda não verificadas';
  }

  @override
  String get bookSourcesMaintenanceResultTitle => 'Resultados de saúde';

  @override
  String get bookSourcesMaintenanceReviewAll => 'Todos os resultados';

  @override
  String get bookSourcesMaintenanceAvailable => 'Disponível';

  @override
  String get bookSourcesMaintenanceLimited => 'Parcial';

  @override
  String get bookSourcesMaintenanceFailed => 'Verificações com falha';

  @override
  String get bookSourcesMaintenanceTimedOut => 'Tempo limite';

  @override
  String get bookSourcesMaintenanceUnchecked => 'Não confirmado';

  @override
  String get bookSourcesMaintenanceReviewSearch => 'Pesquisar nome ou endereço';

  @override
  String get bookSourcesMaintenanceReviewEmpty =>
      'Nenhum resultado correspondente';

  @override
  String bookSourcesMaintenanceReviewSelection(int count) {
    return '$count selecionadas para desativar';
  }

  @override
  String get bookSourcesMaintenanceSelectFailures =>
      'Selecionar verificações com falha';

  @override
  String get bookSourcesMaintenanceTimeoutReason =>
      'Tempo limite de conexão; tente novamente mais tarde';

  @override
  String get bookSourcesMaintenanceUncheckedReason =>
      'Nenhum resultado conclusivo nesta verificação';

  @override
  String get bookSourcesMaintenanceAvailableReason =>
      'Verificações principais aprovadas';

  @override
  String get bookSourcesMaintenanceDedupeBusy => 'Localizando duplicatas…';

  @override
  String get bookSourcesMaintenanceShelfProtected =>
      'Usada pela sua estante · mantida por padrão';

  @override
  String bookSourcesMaintenanceDeleteReferencedWarning(int count) {
    return '$count fonte(s) selecionada(s) são usadas por livros da sua estante. Excluí-las pode impedir que esses livros sejam atualizados ou carreguem novos capítulos.';
  }

  @override
  String get bookSourcesMaintenanceProblemsFilter => 'Problemas';

  @override
  String bookSourcesMaintenanceSelectedCount(int count) {
    return '$count fonte(s) selecionada(s)';
  }

  @override
  String get bookSourcesMaintenanceShelfUsed => 'Usada pela sua estante';

  @override
  String get bookSourcesMaintenancePause => 'Pausar';

  @override
  String get bookSourcesMaintenancePausing => 'Pausando…';

  @override
  String get bookSourcesMaintenancePaused => 'Verificação pausada';

  @override
  String get bookSourcesMaintenanceCompleted => 'Verificação concluída';

  @override
  String get bookSourcesMaintenanceStart => 'Iniciar verificação';

  @override
  String get bookSourcesMaintenanceRestart => 'Iniciar novamente';

  @override
  String get bookSourcesMaintenanceCheckedThisRun =>
      'Verificadas nesta execução';

  @override
  String get bookSourcesMaintenancePausedHint =>
      'Selecione e gerencie os resultados concluídos agora ou continue verificando as fontes restantes.';

  @override
  String get bookSourcesMaintenanceApplyFailed =>
      'Não foi possível salvar as alterações. Tente novamente.';

  @override
  String get settingsQqGroup => 'Grupo do QQ';

  @override
  String get settingsOpenSourceTitle => 'Detalhes do código aberto';

  @override
  String get settingsOpenSourceDetails =>
      'Todos os recursos, exceto os recursos avançados, são de código aberto. O código aberto é licenciado sob AGPL-3.0; veja o escopo no repositório do GitHub.';

  @override
  String get premiumLifetimeTitle => 'Premium vitalício';

  @override
  String get premiumLifetimeCaption =>
      'Compra única · Sem renovação automática';

  @override
  String get premiumBenefitsTitle => 'Incluído no Premium';

  @override
  String get premiumProtocolsBenefit =>
      'Importe e use protocolos de fontes compatíveis adicionais.';

  @override
  String get premiumPrivateNetworkBenefit =>
      'Acesse fontes confiáveis no seu dispositivo, na rede local ou em rede privada.';

  @override
  String get premiumSourceNotice =>
      'O Premium não inclui livros nem endereços de fontes. Serviços de terceiros podem cobrar separadamente.';

  @override
  String get premiumSetupHint =>
      'Ativadas por padrão após o desbloqueio. Você pode desativá-las em Configurações → Recursos avançados.';

  @override
  String get premiumBillingTitle => 'Detalhes da compra';

  @override
  String get premiumBillingBody =>
      'Esta é uma compra única não consumível, não uma assinatura. Não é renovada automaticamente. A App Store exibe o preço real e a Apple processa o pagamento.';

  @override
  String get premiumRestoreHelp =>
      'Após reinstalar ou trocar de dispositivo, restaure usando a conta Apple da compra e a conta Origo X vinculada. Restaurar não cobra novamente.';

  @override
  String get premiumMembershipTerms => 'Termos de associação';

  @override
  String get premiumPrivacyPolicy => 'Política de privacidade';

  @override
  String get premiumAppleEula => 'EULA padrão da Apple';

  @override
  String get premiumPurchaseConsent =>
      'Antes de comprar, leia os termos de associação, a política de privacidade e o EULA padrão da Apple.';

  @override
  String get premiumAccountBindingTitle => 'Conta e acesso';

  @override
  String get premiumAccountBindingBody =>
      'Após a verificação, o Premium é vinculado à conta atual do Origo X e sincroniza entre plataformas suportadas. Configurações avançadas ficam disponíveis com a associação. Sair da conta ou a revogação desativa os recursos avançados. Verifique sua conta antes de comprar.';

  @override
  String get premiumRefundTitle => 'Solicitar reembolso';

  @override
  String get premiumRefundTerms =>
      'A Apple analisa e processa pedidos de reembolso da App Store segundo suas regras aplicáveis. Enviar um pedido não significa aprovação. Compras reembolsadas ou revogadas deixam de fornecer o acesso Premium correspondente.';

  @override
  String get premiumPrivacyPurchaseTitle => 'Dados de verificação de compra';

  @override
  String get premiumPrivacyPurchaseBody =>
      'A Apple cuida das informações de pagamento. O app envia o identificador do produto e os dados de verificação de transação assinados pela Apple ao serviço de contas do Origo X para verificar compras e vincular ou restaurar o Premium. Este fluxo de compra não fornece ao desenvolvedor seu número completo de cartão nem a senha da conta Apple.';

  @override
  String get premiumPrivacyAccountTitle => 'Serviço de contas';

  @override
  String get premiumPrivacyAccountBody =>
      'O serviço de contas do Origo X processa dados da conta e registros de associação para login, verificação de segurança e acesso entre dispositivos. Fale conosco sobre suporte ou privacidade pelas opções de contato no site oficial.';

  @override
  String get premiumPurchaseSuccess => 'Premium desbloqueado';

  @override
  String get premiumTestPurchaseVerified =>
      'Compra de teste verificada. O Premium formal não foi ativado.';

  @override
  String get premiumPurchaseRevoked =>
      'O acesso Premium desta compra foi revogado.';

  @override
  String get premiumRestoreSuccess =>
      'Compra restaurada. O Premium está sincronizado.';

  @override
  String get premiumRestoreEmpty =>
      'Nenhuma compra restaurável foi encontrada. Verifique sua conta Apple e a conta Origo X vinculada à compra.';

  @override
  String get premiumPurchaseCanceled => 'Compra cancelada';

  @override
  String get premiumPendingApproval =>
      'Aguardando aprovação da Apple. O acesso desbloqueia após a aprovação e verificação.';

  @override
  String get premiumVerifying => 'Verificando sua compra…';

  @override
  String get premiumRestoring => 'Restaurando compras…';

  @override
  String get premiumRefundSubmitted =>
      'Pedido de reembolso enviado à Apple para análise.';

  @override
  String get premiumRefundNotFound =>
      'Nenhuma compra de Premium reembolsável foi encontrada para esta conta Apple. Você também pode conferir seu histórico com o suporte de compras da Apple.';

  @override
  String get premiumApplePurchaseSupport => 'Suporte de compras da Apple';

  @override
  String get premiumLinkFailed =>
      'Não foi possível abrir este link. Tente novamente mais tarde.';

  @override
  String get premiumSignInRequired =>
      'Entre no Origo X antes de comprar ou restaurar o Premium.';

  @override
  String get premiumRefundUnavailable =>
      'A folha de reembolso da Apple está indisponível. Continue pelo suporte de compras da Apple.';

  @override
  String get premiumOperationFailed =>
      'Não foi possível concluir a operação. Tente novamente.';

  @override
  String get premiumPurchaseConsentOther =>
      'Leia os termos de associação e a política de privacidade antes de desbloquear o Premium.';

  @override
  String get premiumBillingBodyOther =>
      'Desbloqueie o Premium pelas opções de compra ou resgate disponíveis. O canal de compra exibe o preço e a forma de pagamento. A associação verificada é vinculada à sua conta atual do Origo X.';

  @override
  String get accountDeleteTitle => 'Excluir conta';

  @override
  String get accountDeleteEntrySubtitle =>
      'Apague permanentemente esta conta e todos os seus dados';

  @override
  String accountDeleteStepOf(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String get accountDeleteReviewTitle => 'O que a exclusão faz';

  @override
  String get accountDeleteReviewBody =>
      'Leia cada ponto. Assim que você confirmar, tudo abaixo é excluído imediatamente e não podemos recuperar para você.';

  @override
  String get accountDeleteCurrentAccount => 'Conta atual';

  @override
  String get accountDeleteJoined => 'Entrou em';

  @override
  String get accountDeletePremiumActive =>
      'Premium desbloqueado (será removido)';

  @override
  String get accountDeletePremiumNone => 'Premium não desbloqueado';

  @override
  String get accountDeleteHasTitle => 'Esta conta atualmente tem';

  @override
  String accountDeleteHasSessions(int count) {
    return '$count dispositivos conectados';
  }

  @override
  String accountDeleteHasPasskeys(int count) {
    return '$count passkeys';
  }

  @override
  String accountDeleteHasOauth(int count) {
    return '$count provedores de login vinculados';
  }

  @override
  String accountDeleteHasInvited(int count) {
    return '$count membros que entraram com seu código de convite';
  }

  @override
  String accountDeleteHasRedemptions(int count) {
    return '$count códigos resgatados';
  }

  @override
  String get accountDeleteTermsTitle => 'Termos da exclusão';

  @override
  String get accountDeleteTermsIrreversible =>
      'A exclusão da conta é definitiva e não pode ser revertida. Assim que você confirmar, ninguém — nem o suporte — tem como restaurar os dados excluídos.';

  @override
  String get accountDeleteTermsIdentity =>
      'A própria conta é excluída: seu endereço de e-mail, nome de usuário, nome de exibição e avatar.';

  @override
  String get accountDeleteTermsLogins =>
      'Todos os métodos de login são excluídos: sua senha, suas passkeys e seus vínculos com Google, GitHub e Apple.';

  @override
  String get accountDeleteTermsSessions =>
      'Você é desconectado de todos os lugares imediatamente, em celulares, tablets e computadores.';

  @override
  String get accountDeleteTermsMfa =>
      'Sua configuração de dois fatores e todos os códigos de recuperação são excluídos.';

  @override
  String get accountDeleteTermsPremium =>
      'O acesso ao Premium é removido, independentemente de como você o desbloqueou — código de resgate, recompensa de convite ou compra na Apple.';

  @override
  String get accountDeleteTermsReferrals =>
      'Seu código de convite para de funcionar e os registros de indicação entre você e as pessoas que convidou são excluídos. Recompensas já entregues a outros não são retiradas.';

  @override
  String get accountDeleteTermsRedemptions =>
      'Códigos de resgate que você já usou não são reembolsados e não voltam a ficar disponíveis.';

  @override
  String get accountDeleteTermsApple =>
      'Você comprou o Premium vitalício na App Store. Excluir sua conta não o reembolsa e não cancela nenhuma transação da App Store — reembolsos só podem ser pedidos à Apple. O recibo da sua compra é desvinculado desta conta e mantido, para que você possa tocar em Restaurar compras em uma nova conta com o mesmo Apple ID e recuperar o Premium.';

  @override
  String get accountDeleteTermsLocalData =>
      'Livros, estantes e progresso de leitura neste dispositivo não são excluídos — eles sempre viveram apenas no seu dispositivo. Remova-os no app se também quiser se livrar deles.';

  @override
  String get accountDeleteTermsTombstone =>
      'Retemos apenas o mínimo de dados de exclusão desidentificados necessários para prevenir abuso, junto com os registros de verificação de compra da App Store exigidos para restaurar ou verificar compras. Esses registros não são usados para recriar sua conta.';

  @override
  String get accountDeleteTermsRejoin =>
      'Após a exclusão, o mesmo endereço de e-mail pode se registrar novamente, mas será uma conta nova e vazia, sem nenhum dado ou acesso antigo.';

  @override
  String get accountDeleteBlockedTitle =>
      'Esta conta ainda não pode ser excluída';

  @override
  String get accountDeleteBlockedOwner =>
      'Você é o proprietário do console de administração. Transfira a propriedade para outra pessoa primeiro e volte — caso contrário, ninguém ficaria para administrá-lo.';

  @override
  String get accountDeleteConsent =>
      'Li os termos na íntegra, entendo que a exclusão não pode ser desfeita e concordo em excluir permanentemente minha conta e todos os seus dados.';

  @override
  String get accountDeleteConsentRequired =>
      'Aceite primeiro os termos da exclusão.';

  @override
  String get accountDeleteContinue => 'Entendi, continuar';

  @override
  String get accountDeleteVerifyTitle => 'Verifique seu e-mail';

  @override
  String accountDeleteVerifyBody(String email) {
    return 'Enviaremos um código de 6 dígitos para $email para confirmar que este pedido é realmente seu.';
  }

  @override
  String get accountDeleteSendCode => 'Enviar código de exclusão';

  @override
  String get accountDeleteResendCode => 'Enviar novamente';

  @override
  String get accountDeleteCodeSent =>
      'Código enviado. Conclua a exclusão em até 10 minutos.';

  @override
  String get accountDeleteConfirmTitle => 'Etapa final';

  @override
  String accountDeleteConfirmBody(String email) {
    return 'Digite o e-mail da sua conta $email para não restar dúvida sobre qual conta está sendo excluída.';
  }

  @override
  String get accountDeleteConfirmWarning =>
      'No momento em que você pressionar o botão abaixo, a conta é excluída permanentemente.';

  @override
  String get accountDeleteConfirmField =>
      'Digite o e-mail da sua conta para confirmar';

  @override
  String get accountDeleteMfaHint =>
      'Esta conta tem autenticação de dois fatores ativada, então é preciso mais um código.';

  @override
  String get accountDeleteConfirmMismatch =>
      'Esse e-mail não corresponde à conta atual.';

  @override
  String get accountDeleteAction => 'Excluir minha conta permanentemente';

  @override
  String get accountDeleteDoneTitle => 'Sua conta foi excluída';

  @override
  String get accountDeleteDoneBody =>
      'Sua conta e seus dados desapareceram permanentemente e todos os dispositivos foram desconectados. Obrigado por ter usado o Origo X.';

  @override
  String get accountDeleteAppleManualRevocation =>
      'Após fechar este diálogo, abra Configurações da conta Apple > Entrar e segurança > Entrar com a Apple > Origo X e escolha Parar de usar Entrar com a Apple.';

  @override
  String get accountDeleteDoneClose => 'Fechar';

  @override
  String get bookSourceDetailsTitle => 'Detalhes do livro';

  @override
  String get bookSourceDetailsDescription => 'Sobre este livro';

  @override
  String get bookSourceDetailsNoDescription =>
      'Nenhuma descrição fornecida por esta fonte.';

  @override
  String get bookSourceDetailsLatestChapter => 'Capítulo mais recente';

  @override
  String get bookSourceDetailsLoadFailed =>
      'Não foi possível carregar os detalhes completos. Você pode tentar novamente ou ler com as informações disponíveis.';

  @override
  String get bookSourceDetailsOnShelf => 'Na estante';

  @override
  String get bookSourceDetailsAddFailed =>
      'Não foi possível adicionar este livro à sua estante. Tente novamente.';

  @override
  String get bookSourceDetailsReadFailed =>
      'Não foi possível abrir este livro. Tente novamente.';

  @override
  String get appTextSize => 'Tamanho do texto da interface';

  @override
  String get appTextSizeDescription =>
      'Altera apenas menus e controles do app, não o texto de leitura.';

  @override
  String get appTextSizePreview =>
      'Menus e configurações usarão este tamanho de texto.';

  @override
  String get appTextSizeDefault => '100% (padrão)';

  @override
  String get bookSourceTrackUpdatesTitle => 'Atualizações e texto baixado';

  @override
  String get bookSourceTrackUpdatesBody =>
      'Livros baixados mantêm sua fonte. Verifique novos capítulos para acrescentar conteúdo ou atualize os capítulos baixados preservando suas edições e histórico.';

  @override
  String get bookSourceCheckNewChapters => 'Verificar novos capítulos';

  @override
  String get bookSourceRefreshDownloaded => 'Atualizar capítulos baixados';

  @override
  String get bookSourceNoNewChapters =>
      'Nenhum capítulo novo no catálogo. Atualize os capítulos baixados para verificar alterações no texto anterior.';

  @override
  String bookSourceUpdateSummary(int added, int refreshed) {
    return '$added capítulos adicionados, $refreshed atualizados';
  }

  @override
  String get bookSourceBaselineUnknown =>
      'Confirme o último capítulo já baixado antes de continuar as atualizações. Seu texto existente será preservado.';

  @override
  String get bookSourceSelectBoundary => 'Confirmar capítulos baixados';

  @override
  String get bookSourceBoundaryHelp =>
      'Selecione o último capítulo da fonte incluído no seu texto local. Apenas capítulos posteriores serão acrescentados; o texto existente fica intacto.';

  @override
  String get bookSourceTrackingEstablished =>
      'Limite de acompanhamento salvo. Agora você pode verificar novos capítulos.';

  @override
  String get bookSourceMappingChanged =>
      'A fonte alterou a ordem ou os identificadores dos capítulos. Confirme novamente seus capítulos baixados. O texto existente foi preservado.';

  @override
  String get bookSourceContentConflicts =>
      'Alterações de texto precisam de revisão';

  @override
  String get bookSourceContentConflictBody =>
      'Você e a fonte alteraram estes capítulos. Sua versão permanece ativa. Compare e escolha o que ler; as duas versões ficam no histórico.';

  @override
  String get bookSourceCompareVersions => 'Comparar texto';

  @override
  String get bookSourceLocalVersion => 'Meu texto';

  @override
  String get bookSourceRemoteVersion => 'Texto da fonte';

  @override
  String get bookSourceBaselineVersion => 'Base baixada';

  @override
  String get bookSourceKeepLocal => 'Manter meu texto';

  @override
  String get bookSourceUseRemote => 'Usar texto da fonte';

  @override
  String get bookSourceUpdateFailed =>
      'A atualização não terminou. Seu texto foi preservado. Tente novamente.';

  @override
  String get cloudSyncReadableStorage =>
      'Livros editados são enviados como arquivos completos. Livros inalterados não são transferidos novamente. O progresso de leitura sincroniza separadamente.';

  @override
  String get bookSourceBindSource => 'Vincular uma fonte de livros';

  @override
  String get bookSourceNotBound => 'Nenhuma fonte vinculada';

  @override
  String get bookSourceDownloadedUnchanged =>
      'Os capítulos baixados estão atualizados.';

  @override
  String get premiumSyncFailed =>
      'Não foi possível sincronizar o status da associação. Haverá nova tentativa automática; uma falha de conexão não revoga o acesso verificado.';

  @override
  String get premiumGrantedAccess =>
      'Você tem acesso Premium cortesia. Não é necessária nenhuma compra adicional.';

  @override
  String get premiumOtherChannelAccess =>
      'Você tem o Premium por outro canal. Não é necessária nenhuma compra adicional.';

  @override
  String get premiumAppleAccess =>
      'Você tem o Premium pela App Store. Não é necessária nenhuma compra adicional.';

  @override
  String get premiumExistingAccess =>
      'Você já tem o Premium. Não é necessária nenhuma compra adicional.';

  @override
  String get premiumSyncPending => 'Sincronizando status da associação';

  @override
  String get cloudSyncExportBook => 'Exportar arquivo completo para a nuvem';

  @override
  String get cloudSyncExportDone => 'Arquivo completo exportado';

  @override
  String get cloudSyncDiagnostics => 'Copiar diagnóstico de sincronização';

  @override
  String get cloudSyncProtocolUpgrade =>
      'Esta pasta pertence a um formato de sincronização mais antigo. Escolha uma nova pasta vazia. Seus livros locais e arquivos existentes na nuvem serão mantidos.';

  @override
  String get cloudSyncSettings => 'Configurações de sincronização';

  @override
  String get cloudSyncSettingsHint =>
      'Sincronização automática, outros dados e conexão';

  @override
  String get cloudSyncProgressOnlyHint =>
      'Sincronize posições de leitura sem enviar arquivos de livros';

  @override
  String get cloudSyncProgressExplanation =>
      'Se ambos os dispositivos têm o mesmo livro, você pode sincronizar apenas o progresso de leitura. O celular novo ainda precisa de uma cópia legível; os registros de progresso não contêm o texto do livro.';

  @override
  String get cloudSyncFilesEntryHint =>
      'Envie ou baixe livros; edições enviam o arquivo inteiro';

  @override
  String get cloudSyncOtherDataHint =>
      'Estante, fontes, marcadores, notas e configurações de leitura';

  @override
  String get cloudSyncActivityHint =>
      'Progresso, status dos arquivos e detalhes de falhas';

  @override
  String get cloudSyncNeedsAttention =>
      'Um problema de sincronização precisa de atenção';

  @override
  String get cloudSyncFileStatus => 'Atualizações e conflitos';

  @override
  String get cloudSyncTransferGuide => 'Mudar para um celular novo';

  @override
  String get cloudSyncTransferGuideHint =>
      'Restaure livros e progresso de leitura em um celular novo';

  @override
  String get cloudSyncTransferIntro =>
      'Enviar um livro é opcional para a sincronização do progresso. Você só precisa de uma cópia na nuvem se o celular novo ainda não tiver o livro e você quiser baixá-lo daqui.';

  @override
  String get cloudSyncTransferOldPhone =>
      '1. Sincronize o progresso no celular antigo';

  @override
  String get cloudSyncTransferOldPhoneBody =>
      'Saia do leitor para salvar sua posição mais recente, ative Progresso de leitura e toque em Sincronizar agora. Use a mesma conexão WebDAV e a mesma pasta de sincronização nos dois celulares.';

  @override
  String get cloudSyncTransferHasBook => '2. O celular novo já tem o livro';

  @override
  String get cloudSyncTransferHasBookBody =>
      'Importe o mesmo arquivo local ou abra o mesmo livro online da mesma fonte. Sincronize o progresso e abra o livro para continuar. Apenas títulos iguais não garantem correspondência.';

  @override
  String get cloudSyncTransferNeedsBook =>
      '3. O celular novo precisa do arquivo do livro';

  @override
  String get cloudSyncTransferNeedsBookBody =>
      'No celular antigo, abra Arquivos de livros, permita envios e selecione o livro. Após o envio, sincronize o celular novo e baixe-o em Disponíveis para download. Você também pode transferir o mesmo arquivo por conta própria.';

  @override
  String get cloudSyncTransferEditedBook =>
      'Se você editou o texto no celular antigo, envie essa versão por Arquivos de livros e baixe-a no celular novo para preservar a identidade do livro. Posições de leitura podem não mapear corretamente entre versões de texto diferentes.';

  @override
  String get cloudSyncFrequency => 'Frequência da sincronização automática';

  @override
  String get cloudSyncFrequencyOff => 'Desativada (apenas manual)';

  @override
  String get cloudSyncFrequencyOnChange => 'Após alterações';

  @override
  String get cloudSyncFrequency15Minutes => 'A cada 15 minutos';

  @override
  String get cloudSyncFrequencyHourly => 'A cada hora';

  @override
  String get cloudSyncFrequencyDaily => 'Uma vez por dia';

  @override
  String get cloudSyncFrequencyHint =>
      'Os intervalos começam após uma sincronização automática bem-sucedida. Se o app não estiver em execução, ele se atualiza na próxima vez que você abri-lo. Tentativas com falha repetem automaticamente. Sincronizar agora funciona imediatamente.';

  @override
  String cloudSyncFrequencySummary(String frequency) {
    return 'Sincronização automática: $frequency';
  }

  @override
  String get cloudSyncAutoResumeScheduledHint =>
      'O progresso é buscado na frequência escolhida. Abrir um livro retoma da última posição sincronizada. Toque em Sincronizar agora antes quando precisar do progresso mais recente.';

  @override
  String get readerChapterProgressTitle => 'Progresso do capítulo';

  @override
  String get readerChapterProgressHidden => 'Oculto';

  @override
  String readerChapterProgressFraction(int chapter, int total) {
    return '$chapter/$total capítulos';
  }

  @override
  String readerChapterProgressRemaining(int count) {
    return '$count capítulos à frente';
  }

  @override
  String premiumTrialExpiresAt(String date) {
    return 'O período de teste do Premium expira em $date.';
  }

  @override
  String get premiumTrialTitle => 'Teste do Premium';

  @override
  String get bookSourceCheckUpdates => 'Verificar atualizações';

  @override
  String get bookSourceUpdates => 'Atualizações do livro';

  @override
  String get bookSourceNotChecked => 'Ainda não verificado';

  @override
  String get bookSourceUpToDate => 'O catálogo está atualizado';

  @override
  String get bookSourceUpdatesAvailable => 'Novos capítulos disponíveis';

  @override
  String get bookSourceNeedsMapping => 'Confirme onde continuar';

  @override
  String bookSourceLastChecked(String time) {
    return 'Última verificação: $time';
  }

  @override
  String bookSourceLastUpdated(String time) {
    return 'Última atualização: $time';
  }

  @override
  String get bookSourceUpdateTimeUnknown =>
      'Horário da atualização indisponível';

  @override
  String bookSourceLatestChapterLabel(String chapter) {
    return 'Mais recente: $chapter';
  }

  @override
  String get bookSourceUpdateHelp =>
      'Enquanto a estante está aberta, os catálogos são verificados a cada 30 minutos. Verifique manualmente a qualquer momento. Livros online usam o catálogo mais recente; livros TXT locais baixam novos capítulos apenas quando você escolhe continuar. Após vincular ou alterar uma fonte, confirme o último capítulo já presente no seu arquivo local. Atualizações não substituem seu texto original. O horário da atualização é fornecido pela fonte ou registra quando um novo capítulo foi detectado pela primeira vez.';

  @override
  String get bookSourceBindHelp =>
      'Encontre este livro nas suas fontes para adicionar a capa e ativar a troca de fonte e as atualizações de capítulos. Seu texto local e posição de leitura são preservados.';

  @override
  String get bookSourceContinueUpdate => 'Baixar novos capítulos';

  @override
  String get settingsCloseReaderToLibraryTitle =>
      'Close reader to return to library';

  @override
  String get settingsCloseReaderToLibrarySubtitle =>
      'When a book is open, the window close button returns to the main window instead of quitting the app';

  @override
  String get navMe => 'Meu espaço';

  @override
  String get settingsPreferencesTitle => 'Preferências';

  @override
  String get settingsPreferencesSubtitle => 'Aparência, leitura, idioma';

  @override
  String get settingsManagementTitle => 'Configurações e gestão';

  @override
  String get settingsDataSyncSubtitle => 'Backup WebDAV, cache';

  @override
  String get settingsContentServicesTitle => 'Conteúdo e serviços';

  @override
  String get settingsContentServicesSubtitle =>
      'Fontes, IA, leitura em voz alta';

  @override
  String get settingsAboutSupportSubtitle =>
      'Versão, atualizações, código aberto';

  @override
  String get settingsPremiumSubtitle => 'Mais fontes e acesso à rede privada';

  @override
  String get settingsGuestTitle => 'Não conectado';

  @override
  String get settingsGuestSubtitle => 'A leitura local não requer uma conta';

  @override
  String get settingsWebDavConfigured => 'Backup WebDAV configurado';

  @override
  String get settingsPremiumActive => 'Premium ativo';

  @override
  String get settingsPremiumSyncFailed =>
      'Não foi possível sincronizar a assinatura';

  @override
  String get settingsWebDavWorking => 'WebDAV em andamento';

  @override
  String get storeReaderLockedTitle => 'Comprar a versão básica';

  @override
  String get storeReaderLockedBody =>
      'Para ler nesta versão da loja, é necessário um período de teste ativo ou a compra da versão básica. Seus livros e notas são mantidos. Volte à estante para exportar seus dados.';

  @override
  String get storeReaderUnlock => 'Testar, comprar ou restaurar';

  @override
  String get storeReaderBack => 'Voltar à estante';

  @override
  String get storeReaderChecking => 'Verificando o acesso à leitura…';

  @override
  String get storeReaderBenefitTitle => 'Versão básica';

  @override
  String get storeReaderBenefitBody =>
      'Leitura local para sempre. Não é necessária uma conta Origo.';

  @override
  String storeTrialStart(int days) {
    return 'Teste grátis por $days dias';
  }

  @override
  String storeTrialDetails(int days) {
    return 'Experimente a leitura local por $days dias, sem cobrança automática. Depois, é necessário comprar a versão básica uma única vez. Seus livros e notas serão mantidos.';
  }

  @override
  String get storeTrialStarted =>
      'Seu período de teste da versão da loja começou.';

  @override
  String get storeTrialExpired =>
      'Seu período de teste da versão da loja terminou. Faça uma compra única para continuar ou restaure uma compra existente.';

  @override
  String storePurchaseButton(String store) {
    return 'Comprar a versão básica pela $store';
  }

  @override
  String storePurchaseBilling(String store) {
    return 'Compra única da versão básica, sem renovação automática. A $store mostra o preço e processa o pagamento.';
  }

  @override
  String storePurchaseRestoreHelp(String store) {
    return 'Restaure com a conta da $store usada na compra. Não é necessário entrar no Origo nem pagar novamente.';
  }

  @override
  String storePurchaseAccess(String store) {
    return 'Você já comprou a versão básica pela $store. Não é necessário comprar novamente.';
  }

  @override
  String get storeRestoreEmpty =>
      'Nenhuma compra disponível para restauração foi encontrada. Verifique sua conta da loja e a conta do Origo X vinculada.';

  @override
  String get basicRestoreEmpty =>
      'Nenhuma compra da versão básica foi encontrada. Verifique sua conta da loja.';

  @override
  String get storeGoogleRefundTerms =>
      'Solicite um reembolso pelo Google Play. Um reembolso verificado remove apenas o acesso associado àquela compra; os direitos de acesso independentes continuam válidos.';

  @override
  String get storeReaderLegacyNotice =>
      'Seu acesso básico à leitura é mantido. A compatibilidade avançada com fontes continua exigindo o Premium.';

  @override
  String get storePrivacyPurchaseBody =>
      'Os dados de verificação da loja e um identificador de conta são enviados ao nosso servidor para verificar e restaurar o acesso. A verificação do Google Play inclui um token de compra e um identificador de conta transformado por uma função hash. Não recebemos dados de cartões de pagamento.';

  @override
  String storeTrialLegacyDetails(int days) {
    return 'Seu acesso existente à leitura continua válido. Você não precisa do teste de $days dias.';
  }

  @override
  String get storeReaderSupportSubtitle =>
      'Teste a leitura local ou compre a versão básica uma única vez';

  @override
  String get storeBillingUnavailable =>
      'As compras na loja ainda não estão disponíveis. Tente novamente mais tarde. Seu acesso atual permanece inalterado.';

  @override
  String get accountSignInTitle => 'Entrar no Origo X';

  @override
  String get accountSignInSubtitle => 'Gerencie sua conta e suas compras';

  @override
  String accountRegistrationStep(int step) {
    return 'Criar conta · $step / 3';
  }

  @override
  String get accountSetupTitle => 'Configure sua conta';

  @override
  String get accountSetupHint => 'Você pode adicionar nome e foto depois.';

  @override
  String get accountInvalidEmail => 'Digite um endereço de e-mail válido';

  @override
  String get accountCodeFormat => 'Digite o código de 6 dígitos do e-mail';

  @override
  String get accountPasswordRequired => 'Digite sua senha';

  @override
  String get accountShowPassword => 'Mostrar senha';

  @override
  String get accountHidePassword => 'Ocultar senha';

  @override
  String accountResendIn(int seconds) {
    return 'Reenviar em $seconds s';
  }

  @override
  String get accountBackToCode => 'Voltar ao código de e-mail';

  @override
  String get accountAuthorizationTitle => 'Continue no navegador';

  @override
  String get accountReopenAuthorization => 'Reabrir a página de login';

  @override
  String get accountSignOutHint =>
      'Seus livros locais serão mantidos. Entre novamente para verificar os direitos da conta.';

  @override
  String get accountDiscardChanges => 'Descartar alterações';

  @override
  String get accountUnsavedChanges =>
      'As alterações no perfil não foram salvas.';

  @override
  String get accountAuthorizationExpired =>
      'A solicitação expirou. Tente entrar novamente.';

  @override
  String get purchaseDetailsTitle => 'Detalhes da compra';

  @override
  String get purchaseBenefitsAction => 'Ver todos os benefícios';

  @override
  String get purchaseTermsAction => 'Termos e privacidade';

  @override
  String get purchaseAccountCaption => 'Vinculado à sua conta Origo';

  @override
  String get basicBenefitsTitle => 'A experiência de leitura completa';

  @override
  String get basicReadingTitle => 'Leitura em vários formatos';

  @override
  String get basicReadingBody =>
      'Leia TXT, EPUB, PDF e outros formatos. Importe livros com sumário e marcadores, use vários modos de virar página, leitura imersiva e páginas duplas no tablet.';

  @override
  String get basicFormatNote =>
      'O suporte a formatos varia conforme a plataforma; livros protegidos por DRM não são compatíveis.';

  @override
  String get basicAppearanceTitle => 'Temas e fontes';

  @override
  String get basicAppearanceBody =>
      'Personalize temas e fundos, importe fontes e ajuste tamanho, espaçamento, margens e parágrafos.';

  @override
  String get basicTtsTitle => 'Leitura em voz alta e áudio';

  @override
  String get basicTtsBody =>
      'Ouça com as vozes do dispositivo, ajuste a velocidade e defina um temporizador.';

  @override
  String get basicCloudTtsTitle => 'TTS na nuvem';

  @override
  String get basicCloudTtsBody =>
      'Configure serviços de voz na nuvem, escolha modelos e vozes e salve vários perfis.';

  @override
  String get basicAiTitle => 'Assistente de leitura com IA';

  @override
  String get basicAiBody =>
      'Conecte seu serviço de IA para fazer perguntas e explorar o que você lê.';

  @override
  String get basicNotesTitle => 'Notas e histórico de leitura';

  @override
  String get basicNotesBody =>
      'Pesquise no texto, salve marcadores, destaques e notas, veja estatísticas e exporte dados de leitura.';

  @override
  String get basicSourcesTitle => 'Fontes abertas de livros';

  @override
  String get basicSourcesBody =>
      'Importe fontes ORSP compatíveis para pesquisar e ler conteúdo online. O app não fornece endereços de fontes nem livros.';

  @override
  String get basicSyncTitle => 'Biblioteca e backup';

  @override
  String get basicSyncBody =>
      'Gerencie sua biblioteca local e faça backup ou restaure livros, dados de leitura e configurações com WebDAV.';

  @override
  String get basicServicesNote =>
      'IA e TTS na nuvem exigem seus próprios serviços; taxas de terceiros não estão incluídas.';

  @override
  String get basicEditionTitle => 'Versão básica';

  @override
  String get basicEditionSummary =>
      'Uma compra. A experiência de leitura completa.';

  @override
  String get basicEditionNoAccount => 'Não é necessário entrar no Origo';

  @override
  String get premiumEditionSummary =>
      'Extensões avançadas. Mais formatos de fontes.';

  @override
  String get storeReaderLicenseTitle => 'Comprar a versão básica';

  @override
  String get storeReaderLicenseSubtitle =>
      'Experimente a leitura local por 14 dias e depois compre a versão básica uma única vez.';

  @override
  String get storeReaderLifetimeTitle => 'Versão básica';

  @override
  String storeReaderOwned(String store) {
    return 'Versão básica comprada pela $store.';
  }

  @override
  String get storePremiumPrerequisiteTitle => 'Compre primeiro a versão básica';

  @override
  String get storePremiumPrerequisiteBody =>
      'O Premium é vendido separadamente após a compra da versão básica. O período de teste não é suficiente.';

  @override
  String get storePremiumPriceCaption =>
      'Premium permanente · vinculado à sua conta Origo';

  @override
  String storePremiumPurchaseButton(String store) {
    return 'Comprar Premium pela $store';
  }

  @override
  String storePremiumBilling(String store) {
    return 'O Premium é uma compra separada e única, sem renovação automática. A $store mostra o preço e processa o pagamento. O Premium fica vinculado à sua conta Origo atual.';
  }

  @override
  String storePremiumRestoreHelp(String store) {
    return 'Entre na conta Origo vinculada e restaure o Premium com a conta da $store usada na compra. Não haverá nova cobrança.';
  }

  @override
  String storeReaderTrialExpiresAt(String date) {
    return 'O teste da versão básica termina em $date.';
  }

  @override
  String get storeReaderPurchaseSuccess => 'Versão básica comprada';

  @override
  String get storeReaderRestoreSuccess => 'Compra da versão básica restaurada';

  @override
  String get storeReaderTestPurchaseVerified =>
      'Compra de teste da versão básica verificada; nenhuma licença definitiva foi concedida.';

  @override
  String get storeReaderPurchaseRevoked =>
      'A compra da versão básica foi revogada.';

  @override
  String storeReaderPendingApproval(String store) {
    return 'Aguardando aprovação da $store. A versão básica será ativada após a verificação.';
  }

  @override
  String get storeReaderVerifying => 'Verificando a compra da versão básica…';

  @override
  String get storeReaderRestoring => 'Restaurando a compra da versão básica…';
}
