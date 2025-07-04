import 'article_model.dart';

class Goal {
  final String id;
  String name;
  double targetAmount;
  double currentAmount;
  bool isHighlighted;
  String? paypalEmail; // Optional
  List<Article> articles; // New field

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.isHighlighted = false,
    this.paypalEmail,
    this.articles = const [], // Initialize with empty list
  });

  // Add toJson/fromJson for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'isHighlighted': isHighlighted,
    'paypalEmail': paypalEmail,
    'articles': articles.map((article) => article.toJson()).toList(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    targetAmount: (json['targetAmount'] as num).toDouble(),
    currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
    isHighlighted: json['isHighlighted'] as bool? ?? false,
    paypalEmail: json['paypalEmail'] as String?,
    articles:
        (json['articles'] as List<dynamic>?)
            ?.map((item) => Article.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    bool? isHighlighted,
    String? paypalEmail,
    List<Article>? articles,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      articles: articles ?? this.articles,
    );
  }
}
