class AppEnvironment {
  final String name;
  final String apiUrl;
  final bool useMock;

  const AppEnvironment({
    required this.name,
    required this.apiUrl,
    this.useMock = false,
  });
}
