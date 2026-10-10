import 'package:flutter/material.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';

class BookSourceDiscoverySourceButton extends StatelessWidget {
  const BookSourceDiscoverySourceButton({
    super.key,
    required this.name,
    required this.onPressed,
  });

  final String name;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => GlassControlSurface(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    enabled: onPressed != null,
    child: TextButton(
      key: const Key('bookSourceDiscoverySourceSelector'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.expand_more_rounded, size: 20),
        ],
      ),
    ),
  );
}

/// Local source lookup; opening and request ownership stay with discovery.
class BookSourceDiscoverySourcePicker extends StatefulWidget {
  const BookSourceDiscoverySourcePicker({
    super.key,
    required this.sources,
    required this.selectedSourceId,
    required this.matchesQuery,
  });

  final List<RegisteredBookSource> sources;
  final String? selectedSourceId;
  final bool Function(RegisteredBookSource source, String query) matchesQuery;

  @override
  State<BookSourceDiscoverySourcePicker> createState() =>
      _BookSourceDiscoverySourcePickerState();
}

class _BookSourceDiscoverySourcePickerState
    extends State<BookSourceDiscoverySourcePicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sources = widget.sources
        .where((source) => widget.matchesQuery(source, _query))
        .toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.bookSources,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: PillSearchField(
            textFieldKey: const Key('bookSourceDiscoverySourceSearch'),
            controller: _searchController,
            hintText: context.l10n.bookSourcesManagementSearchHint,
            clearTooltip: context.l10n.bookSourcesClearSearch,
            blurBackground: false,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ),
        Expanded(
          child: sources.isEmpty
              ? Center(child: Text(context.l10n.bookSourcesNoMatchingSources))
              : ListView.builder(
                  key: const Key('bookSourceDiscoverySourceList'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    12 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    final selected = source.id == widget.selectedSourceId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: GlassSurface(
                        role: GlassSurfaceRole.selection,
                        enabled: selected,
                        visibility: selected ? 1 : 0,
                        filterBackground: false,
                        shape: const StadiumBorder(),
                        child: ListTile(
                          key: Key('bookSourceDiscoveryPick-${source.id}'),
                          selected: selected,
                          selectedColor: scheme.primary,
                          shape: const StadiumBorder(),
                          minTileHeight: 52,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          title: Text(
                            source.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.of(context).pop(source),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
