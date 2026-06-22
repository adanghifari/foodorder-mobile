const List<String> _indonesianMonths = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

DateTime? _parseDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;

  final normalized = value.contains('T') ? value : value.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

String _dayMonthYear(DateTime value) {
  final local = value.toLocal();
  final monthIndex = local.month.clamp(1, 12) - 1;
  return '${local.day} ${_indonesianMonths[monthIndex]} ${local.year}';
}

String _timeParts(DateTime value, {bool includeSeconds = true}) {
  final local = value.toLocal();
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  if (!includeSeconds) return '$hours:$minutes';
  final seconds = local.second.toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String formatIndonesianDate(DateTime value) {
  return _dayMonthYear(value);
}

String formatIndonesianDateTime(DateTime value, {bool includeSeconds = true}) {
  return '${_dayMonthYear(value)}, ${_timeParts(value, includeSeconds: includeSeconds)}';
}

String formatIndonesianDateFromRaw(String raw) {
  final parsed = _parseDateTime(raw);
  if (parsed == null) return raw.trim().isEmpty ? '-' : raw;
  return formatIndonesianDate(parsed);
}

String formatIndonesianDateTimeFromRaw(
  String raw, {
  bool includeSeconds = true,
}) {
  final parsed = _parseDateTime(raw);
  if (parsed == null) return raw.trim().isEmpty ? '-' : raw;
  return formatIndonesianDateTime(parsed, includeSeconds: includeSeconds);
}
