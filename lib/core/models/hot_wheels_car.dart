import 'package:uuid/uuid.dart';

class HotWheelsCar {
  final String id;
  final String name;
  final String? series;
  final int? year;
  final String? imagePath;
  final String? notes;
  final String? condition;
  final DateTime? acquiredDate;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  HotWheelsCar({
    String? id,
    required this.name,
    this.series,
    this.year,
    this.imagePath,
    this.notes,
    this.condition,
    this.acquiredDate,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  HotWheelsCar copyWith({
    String? id,
    String? name,
    String? series,
    int? year,
    String? imagePath,
    String? notes,
    String? condition,
    DateTime? acquiredDate,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HotWheelsCar(
      id: id ?? this.id,
      name: name ?? this.name,
      series: series ?? this.series,
      year: year ?? this.year,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      condition: condition ?? this.condition,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'series': series,
      'year': year,
      'imagePath': imagePath,
      'notes': notes,
      'condition': condition,
      'acquiredDate': acquiredDate?.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory HotWheelsCar.fromMap(Map<String, dynamic> map) {
    return HotWheelsCar(
      id: map['id'] as String,
      name: map['name'] as String,
      series: map['series'] as String?,
      year: map['year'] as int?,
      imagePath: map['imagePath'] as String?,
      notes: map['notes'] as String?,
      condition: map['condition'] as String?,
      acquiredDate: map['acquiredDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['acquiredDate'] as int)
          : null,
      isFavorite: (map['isFavorite'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toString() {
    return 'HotWheelsCar(id: $id, name: $name, series: $series, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotWheelsCar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
