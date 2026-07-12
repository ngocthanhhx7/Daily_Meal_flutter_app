class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.properties = const {}});

  final String name;
  final Map<String, Object?> properties;

  @override
  String toString() => 'AnalyticsEvent(name: $name, properties: $properties)';
}
