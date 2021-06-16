extension StringExtension on String {
  String toScreamingSnakeCase() {
    return this
        .replaceAllMapped(
            RegExp(
              r'[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+',
            ),
            (Match m) => "${m[0]?.toUpperCase()}")
        .replaceAll(RegExp(r'(-|\s)+'), '_');
  }
}
