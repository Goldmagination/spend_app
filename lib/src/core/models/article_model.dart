import 'package:hive/hive.dart';

part 'article_model.g.dart';

@HiveType(typeId: 0)
class Article {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
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
