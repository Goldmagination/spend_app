class Goal {
  final String id;
  String name;
  double targetAmount;
  double currentAmount;
  bool isHighlighted;
  String? paypalEmail; // Optional

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.isHighlighted = false,
    this.paypalEmail,
  });

  // Optional: Add a copyWith method for easier updates if objects are immutable
  // For now, making fields non-final (except id) allows direct modification
  // which is simpler for this stage but less robust for state management.

  // Optional: Add toJson/fromJson for persistence later
}
