/// Model representing a parking permit plan option.
/// 
/// Contains the period (e.g., "Weekly", "Monthly", "Yearly"),
/// the price in dollars, and the value for backend storage.
class PermitPlanModel {
  final String period;
  final int price;
  final String value;

  const PermitPlanModel({
    required this.period,
    required this.price,
    required this.value,
  });

  /// Static list of available permit plans
  static const List<PermitPlanModel> availablePlans = [
    PermitPlanModel(
      period: 'Weekly',
      price: 60,
      value: 'weekly',
    ),
    PermitPlanModel(
      period: 'Monthly',
      price: 80,
      value: 'monthly',
    ),
    PermitPlanModel(
      period: 'Yearly',
      price: 150,
      value: 'yearly',
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermitPlanModel &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
