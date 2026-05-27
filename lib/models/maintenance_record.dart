class MaintenanceRecord {
  final int? id;
  final int bikeId;
  final String type;
  final DateTime date;
  final String description;
  final DateTime? nextServiceDate;

  MaintenanceRecord({
    this.id,
    required this.bikeId,
    required this.type,
    required this.date,
    required this.description,
    this.nextServiceDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bikeId': bikeId,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'nextServiceDate': nextServiceDate?.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'],
      bikeId: map['bikeId'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      nextServiceDate: map['nextServiceDate'] != null
          ? DateTime.parse(map['nextServiceDate'])
          : null,
    );
  }
}
