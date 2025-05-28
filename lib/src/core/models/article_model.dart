import 'package:flutter/foundation.dart'; // For @required if using older Dart versions, or for general utility.

class Article {
  final String id;
  final String name;
  final double price;

  Article({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(), // Ensure price is parsed as double
  );

  // Optional: copyWith if needed for immutability patterns
  Article copyWith({
    String? id,
    String? name,
    double? price,
  }) {
    return Article(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  // Optional: Override == and hashCode for value equality if articles are compared
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ price.hashCode;
}
