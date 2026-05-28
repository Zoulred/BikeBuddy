class Weather {
  final double tempC;
  final String description;
  final String icon;

  Weather({required this.tempC, required this.description, required this.icon});

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final w = weatherList.isNotEmpty
        ? weatherList[0] as Map<String, dynamic>
        : {};
    return Weather(
      tempC: (main['temp'] ?? 0).toDouble(),
      description: (w['description'] ?? '').toString(),
      icon: (w['icon'] ?? '').toString(),
    );
  }
}
