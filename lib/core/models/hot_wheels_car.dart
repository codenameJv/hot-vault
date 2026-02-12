import 'package:uuid/uuid.dart';

/// Hunt type for Hot Wheels cars
enum HuntType {
  normal,
  rth, // Regular Treasure Hunt
  sth, // Super Treasure Hunt
}

class HotWheelsCar {
  final String id;
  final String name;
  final String? series;
  final String? segment;
  final int? year;
  final String? imagePath;
  final String? notes;
  final String? condition;
  final DateTime? acquiredDate;
  final double? purchasePrice;
  final double? sellingPrice;
  final HuntType huntType;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  HotWheelsCar({
    String? id,
    required this.name,
    this.series,
    this.segment,
    this.year,
    this.imagePath,
    this.notes,
    this.condition,
    this.acquiredDate,
    this.purchasePrice,
    this.sellingPrice,
    this.huntType = HuntType.normal,
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
    String? segment,
    int? year,
    String? imagePath,
    String? notes,
    String? condition,
    DateTime? acquiredDate,
    double? purchasePrice,
    double? sellingPrice,
    HuntType? huntType,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearNotes = false,
    bool clearSeries = false,
    bool clearSegment = false,
    bool clearYear = false,
    bool clearAcquiredDate = false,
    bool clearPurchasePrice = false,
    bool clearSellingPrice = false,
  }) {
    return HotWheelsCar(
      id: id ?? this.id,
      name: name ?? this.name,
      series: clearSeries ? null : (series ?? this.series),
      segment: clearSegment ? null : (segment ?? this.segment),
      year: clearYear ? null : (year ?? this.year),
      imagePath: imagePath ?? this.imagePath,
      notes: clearNotes ? null : (notes ?? this.notes),
      condition: condition ?? this.condition,
      acquiredDate: clearAcquiredDate ? null : (acquiredDate ?? this.acquiredDate),
      purchasePrice: clearPurchasePrice ? null : (purchasePrice ?? this.purchasePrice),
      sellingPrice: clearSellingPrice ? null : (sellingPrice ?? this.sellingPrice),
      huntType: huntType ?? this.huntType,
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
      'segment': segment,
      'year': year,
      'imagePath': imagePath,
      'notes': notes,
      'condition': condition,
      'acquiredDate': acquiredDate?.millisecondsSinceEpoch,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'huntType': huntType.name,
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
      segment: map['segment'] as String?,
      year: map['year'] as int?,
      imagePath: map['imagePath'] as String?,
      notes: map['notes'] as String?,
      condition: map['condition'] as String?,
      acquiredDate: map['acquiredDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['acquiredDate'] as int)
          : null,
      purchasePrice: map['purchasePrice'] as double?,
      sellingPrice: map['sellingPrice'] as double?,
      huntType: HuntType.values.firstWhere(
        (e) => e.name == map['huntType'],
        orElse: () => HuntType.normal,
      ),
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
