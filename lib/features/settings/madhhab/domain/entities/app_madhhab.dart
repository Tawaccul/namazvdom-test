class AppMadhhab {
  const AppMadhhab({
    required this.id,
    required this.label,
    this.recommended = false,
  });

  final String id; // hanafi | shafii | maliki | hanbali
  final String label;
  final bool recommended;
}

