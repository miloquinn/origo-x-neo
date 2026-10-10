# Book-source architecture

Current module guide. Start at [the maintenance index](../../docs/README.md);
online startup, shared cache identities, invalidation and troubleshooting are
maintained in [Reading cache](../../docs/reading-cache.md). Dated plans and
diagnoses are historical evidence, not instructions to repeat completed work.
Shelf update counts, unknown-count markers and loaded-catalog confirmation are
maintained in [Library source updates](../../docs/library-source-updates.md).

The book-source feature follows a one-way dependency flow:

1. Pages compose dependencies and own navigation, localization, dialogs, and
   widget lifecycle.
2. Controllers own immutable workflow state, request generations, pagination,
   filtering, and stale-result suppression. Controllers never receive a
   `BuildContext`.
3. `BookSourceClient` is the stable application facade. It routes calls through
   `BookSourceGateway` to the ORSP or reading-source backend.
4. Protocol backends translate protocol-specific data. ORSP owns HTTP/cache
   behavior; the reading-source backend adapts `SourceRuntime`.
5. Shared chapter/response/cover caches live in `caching/`. SSRF and pinned
   HTTP policy live in `networking/`. `services/` stays the application
   facade and composition root.
6. `SourceRuntime` is the composition root for request, login, catalog,
   reading, rule, script, interaction, cookie, and transport capabilities.

## Ownership

Injected clients, services, transports, and runtimes are borrowed. Dependencies
created by a page, service, or composition root are owned by that creator and
closed once, in child-before-parent order. Closing a runtime transport cancels
pending network work; disposal must not wait indefinitely for that work first.
Reader pages own cancellation tokens for catalog/content/prefetch requests even
when borrowing a client. Cache network flights are scoped by that owner; disk
and memory entries remain shared. ReadingSource catalog initialization retains
independent waiters and stops only after its last waiter leaves. Source-invariant
script preparation is bounded and keyed by complete library content; dynamic
book, chapter and session data never enters that preparation cache.

## Compatibility boundaries

`source_engine/source_request.dart` and
`pages/book_sources/widgets/sourced_book_widgets.dart` are compatibility export
barrels for existing callers. Production modules import leaf files directly so
their dependencies remain explicit.

Root `source_engine/source_rule_*.dart` and `source_engine/source_script_*.dart`
files are export shims that preserve old package URIs for tests and tools.
Production modules must import the implementations under `rules/` and
`scripting/`.

## Architecture map

- `source_engine/rules/` — CSS, XPath, JSONPath, regex, and put/script-rule
  orchestration (`SourceRuleEngine` and selector modules).
- `source_engine/scripting/` — script contract, QuickJS host/bootstrap/APIs,
  and the native/web platform export (`source_script_engine_platform.dart`).
- Remaining `source_engine/*.dart` files stay at the package root until later
  transport/runtime splits.

## Extension points

- Add protocol behavior behind a `BookSourceGateway` backend.
- Add runtime behavior through a narrow capability/port and compose it in
  `SourceRuntime`.
- Add extraction syntax in the selector-specific rule modules; script/put
  orchestration belongs to `SourceRuleScript`.
- Add page workflows to controllers and keep widgets render-only.

## Verification

Focused tests cover facade routing, owned/borrowed resources, runtime ports,
request/response handling, rule/script parity, immutable controllers, page
ownership, and the HTTP end-to-end reading flow. The architecture guard in
`test/book_source_architecture_test.dart` prevents production files from
reaching 800 lines, importing compatibility barrels or root rule/script
shims internally, or keeping cache/network-policy files on the old
`services/` paths.

## Reading-source compatibility contracts

Regression fixtures cover the reading-source compatibility contracts around
`AnalyzeUrl`, `RuleAnalyzer`, `AnalyzeByJSoup`, and `webBook/BookContent`.

- Split HTML rule chains with the shared balanced rule parser. Quoted attribute
  values and predicates can contain `@` without introducing another rule stage.
- Metadata URL extraction keeps the first nonblank attribute. Content evaluation
  with a nonempty `joinSeparator` collects distinct attribute values in source
  order. Keep the string path through script, put, and replacement stages so
  collecting multiple images never requires running a source script twice.
- Request options start at the first `,{` delimiter; nested JSON body arrays
  and quoted values may contain later delimiters. POST bodies may be JSON
  objects/arrays or strings. Preserve explicit content types and form encoding;
  structured JSON defaults to the JSON media type. GET/HEAD ignore body options.

- A single `nextContentUrl` follows a chain; multiple first-page URLs form a
  fixed list. Fetch fixed pages with at most four concurrent requests, consume
  content rules in page order, deduplicate redirects, stop before the next
  chapter, and retain the twenty-page limit. Capture prefetch errors immediately
  and surface them when consuming that page.
- `nextTocUrl` uses the same chain-versus-fixed-list distinction, including
  current-page entries when deciding the first-page mode. Merge directory
  pages before applying the leading `+`/`-` order marker and deduplication.
  Ordinary chapters without a URL may use the final directory URL; an
  explicitly invalid URL is not equivalent to a missing one.
- `subContent` and `title` use the first response context after content pages.
  Text sources append local or fetched subcontent before chapter-wide regex
  replacement. Optional title errors preserve the original title and content,
  matching the reference; content and pagination errors still propagate.
- `html` returns outer tags with descendant script/style nodes removed from a
  clone. `all` preserves raw outer tags. A later rule sees the unchanged DOM.
- Synchronous script DOM helpers share string evaluation and replacement
  semantics with asynchronous rules. `java.htmlFormat` preserves paragraph
  indentation, image options, and entities; `Jsoup.text()` returns plain text.

The scripting bridge is split into encoding, Java-class adapters, DOM, text,
and crypto modules. `scripting/source_script_bootstrap.dart` prepares source
libraries and composes the invocation program in
`source_script_bootstrap_program.dart`; the existing `source_script_state.dart`
owns the embedded invocation-state adapters for source values, login/cache
aliases and origin-scoped browser localStorage. The fragment remains in its
original lexical position, sharing the invocation payload and host bridge;
its generated JavaScript and compatibility behavior must remain unchanged.
Regression entry points are `test/source_script_bootstrap_preparation_test.dart`,
`test/source_browser_storage_test.dart`, and
`test/source_script_session_cache_contract_test.dart`.

Character conversion covers UTF-8, GBK/GB2312, GB18030, UTF-16,
ASCII, and Latin-1; unsupported charset names fail explicitly. Supported Java
adapters include String, Base64, URL form encoding, ArrayList/Map convenience
methods, MessageDigest, and the existing cipher/HMAC operations. Class/package
imports are restored after each invocation, including failures and network
replay. The adapters implement tested method shapes, not a full JVM or Rhino.
Android UI, arbitrary Java reflection/bytecode, unrestricted filesystem APIs,
full Jsoup APIs, and all Java charset/collection overloads are not supplied.
Existing traditional/simplified conversion remains a limited character table.
Do not infer complete source compatibility from these individual fixtures or
compensate for unsupported APIs with broad raw-page scraping.

Script variables belong to their actual chapter/book/rule/source context.
Pass the same entity maps through request scripts and content rules so a token
saved in book initialization remains available to later chapter requests.
Do not emulate this by storing every book's variables in global source state.
Content-page writes must also reach the next page request. Stateful scripted
fixed pages run sequentially; plain selector-based fixed pages retain prefetch.

## Declarative login forms and local payloads

`source_engine/source_json.dart` decodes legacy declaration data without running
JavaScript. Strict JSON stays on the fast path; mixed single/double quotes,
unquoted keys, comments and trailing commas use limited lexical normalization.
Expressions in a declaration still fail. Only explicitly marked `@js:`/`<js>`
forms enter the existing script runtime. `source_login_ui.dart` preserves exact
nonblank field names because button scripts access those names through `result`.
`source_runtime_login.dart` restores old values saved under trimmed names, reports
invalid forms without their contents, and flushes generated-form session writes.

`pages/book_sources/source_login_page.dart` respects the order of forms that
declare layout fractions or section headings. Buttons without an action are
headings; consecutive actions wrap at narrower widths. Plain legacy forms retain
their additional-settings section. Each action reloads persisted login values
into the existing controllers before showing its response, so a generated Token
is not overwritten by stale inputs on the next action. Explicit clear resets
inputs and choices to their declaration defaults. Source scripts, not the app,
define required values, account services and Token expiry; no source-specific
credentials or endpoint branches are supplied.

`source_request_template.dart` treats data payloads with a nonblank `type`, or
payloads that are not absolute HTTP(S) URLs, as local hex-encoded bytes. An empty
`type` therefore still supports book/chapter IDs. Untyped HTTP(S) wrappers retain
their legacy network behavior. The shared options boundary skips the data URI's
payload comma and nested/quoted JSON commas before locating trailing options;
request parsing and wrapper decoding use the same boundary.
`SourceResponse.scriptBaseUrl` preserves the
original request options for subsequent rules. Reading-source cache revision 7
includes this payload behavior; older persistent results are not reused.

Regression entry points: `test/source_login_ui_test.dart`,
`test/source_runtime_login_form_test.dart`, `test/source_login_page_test.dart`,
`test/source_runtime_virtual_data_url_test.dart`, and the session/browser tests
listed above. Stateful Flutter files run in independent processes. The opt-in
`tool/source_sample_smoke_test.dart` reads external samples without modifying
them; account-required responses and unavailable upstream services remain
separate from offline compatibility. `tool/benchmark_real_source_import.dart`
recursively reads organized corpora, excluding replacement-rule directories;
its import metrics do not establish online source availability.

On structured responses, a CSS attribute predicate containing `:` or `,` stays
an unmatched HTML alternative, so mixed `CSS||JSON` metadata rules can fall back
to the JSON field. It must not be inferred as a JSONPath slice. Explicit JSONPath
syntax keeps its parser errors. This boundary is covered by
`test/source_rule_format_contract_test.dart` alongside slice/filter regressions.

Dated evidence for the four-source user submission and resource-directory
migration is in [2026-10-10 validation](../../docs/reviews/2026-10-10-source-login-compatibility.md).

Image extraction lives in `source_content_images.dart`; shared cover/chapter
asset URL and request-option parsing lives in `source_remote_asset.dart`.
Neither helper depends on runtime orchestration. `source_text_replacement.dart`
retains page origins through chapter-wide text regex replacements, then reuses
the same image extractor. Literal replacement text belongs to the page where
the match starts; captured text moved across page boundaries uses that base
too. Evaluate chapter rules once and resolve assets against response URLs. Keep image
order while merging repeated URLs through one accumulator. Attach current
source/login headers and cookies after content scripts have finished.

Raw-page recovery is a bounded compatibility path for missing comic rules.
It must not replace a successful explicit selection or revive images removed
by `replaceRegex`. Normal successful extraction should not scan the raw page.

Full-rule `replaceRegex` scripts run once after pages and subcontent merge.
Their surviving image references reuse the shared extractor to recover the
original response base. Newly generated relative references use the first
page base; plain regex replacements continue to retain per-span provenance.

Pinned HTTPS must upgrade the validated socket with TLS using the original
hostname for SNI and certificate checks. A custom `HttpClient.connectionFactory`
owns that handshake. Do not restore HTTP 400 retries to mask missing TLS.
Both source transport and image caches accept the explicit VPN FakeDNS range;
the ordinary private-network restrictions remain in force.
