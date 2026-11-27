enum IssueSeverity {
  low('Low - Minor inconvenience'),
  medium('Medium - Prevents some actions'),
  high('High - Completely broken');

  final String label;
  const IssueSeverity(this.label);
}
