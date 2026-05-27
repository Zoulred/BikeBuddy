enum GoalType { daily, weekly, monthly }

class Goal {
  final int? id;
  final GoalType type;
  final double target;
  final double current;
  final DateTime startDate;
  final DateTime endDate;

  Goal({
    this.id,
    required this.type,
    required this.target,
    this.current = 0.0,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'target': target,
      'current': current,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      type: GoalType.values[map['type']],
      target: map['target']?.toDouble() ?? 0.0,
      current: map['current']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
