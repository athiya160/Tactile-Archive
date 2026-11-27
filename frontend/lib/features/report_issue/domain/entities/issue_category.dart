enum IssueCategory {
  appBug('App Bug'),
  metadata('Incorrect Metadata'),
  physical('Broken Binding (Physical)'),
  other('Other');

  final String label;
  const IssueCategory(this.label);
}
