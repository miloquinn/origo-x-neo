import 'source_html_contract.dart';
import 'source_json.dart';

/// Both supported source formats expose their login entry declaratively.
bool sourceDeclaresLogin(Map<String, dynamic>? config) =>
    config != null &&
    ('${config['loginUrl'] ?? ''}'.trim().isNotEmpty ||
        SourceHtmlContract.parse(config['html']).supports('getloginurl'));

class SourceLoginField {
  const SourceLoginField({
    required this.name,
    required this.type,
    this.viewName,
    this.defaultValue,
    this.chars = const [],
    this.action,
    this.flexBasisPercent,
  });

  final String name;
  final String type;
  final String? viewName;
  final String? defaultValue;
  final List<String> chars;
  final String? action;
  final double? flexBasisPercent;

  bool get isInput => type == 'text' || type == 'password';
  bool get isButton => type == 'button';
  bool get isSectionHeading => isButton && (action?.trim().isEmpty ?? true);

  factory SourceLoginField.fromJson(Object? value) {
    final map = value is Map ? value : const {};
    final chars = map['chars'];
    final style = map['style'];
    final basis = style is Map ? style['layout_flexBasisPercent'] : null;
    final percent = basis is num ? basis.toDouble() : null;
    return SourceLoginField(
      name: '${map['name'] ?? ''}',
      type: '${map['type'] ?? 'text'}'.trim().toLowerCase(),
      viewName: _optionalText(map['viewName']),
      defaultValue: _optionalText(map['default']),
      chars: chars is List
          ? [for (final item in chars) '${item ?? ''}']
          : const [],
      action: _optionalText(map['action']),
      flexBasisPercent: percent != null && percent > 0 && percent <= 1
          ? percent
          : null,
    );
  }
}

List<SourceLoginField> parseSourceLoginFields(Object? value) {
  Object? decoded = value;
  if (value is String) {
    if (value.trim().isEmpty) return const [];
    decoded = decodeSourceJson(value);
  }
  if (decoded is! List) return const [];
  return [
    for (final item in decoded)
      if (item is Map && '${item['name'] ?? ''}'.trim().isNotEmpty)
        SourceLoginField.fromJson(item),
  ];
}

String? _optionalText(Object? value) {
  final text = '$value'.trim();
  return value == null || text.isEmpty ? null : text;
}
