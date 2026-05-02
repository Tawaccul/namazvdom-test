class SupportPlan {
  const SupportPlan({
    required this.months,
    required this.discountLabel,
    required this.priceLabel,
    required this.productId,
  });

  final int months;
  final String? discountLabel;
  final String priceLabel;
  final String productId;
}
