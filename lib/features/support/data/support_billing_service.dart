import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../domain/entities/support_plan.dart';

class SupportProduct {
  const SupportProduct({
    required this.id,
    required this.price,
    required ProductDetails details,
  }) : _details = details;

  final String id;
  final String price;
  final ProductDetails _details;
}

class SupportBillingService {
  SupportBillingService({InAppPurchase? inAppPurchase})
    : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<Map<String, SupportProduct>> loadProducts(
    List<SupportPlan> plans,
  ) async {
    final available = await _iap.isAvailable();
    if (!available) return const {};

    final ids = plans.map((plan) => plan.productId).toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.productDetails.isEmpty) return const {};

    final products = <String, SupportProduct>{};
    for (final details in response.productDetails) {
      products[details.id] = SupportProduct(
        id: details.id,
        price: details.price,
        details: details,
      );
    }
    return products;
  }

  Future<bool> buy(SupportProduct product) {
    return _iap.buyNonConsumable(
      purchaseParam: _purchaseParamFor(product._details),
    );
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }

  PurchaseParam _purchaseParamFor(ProductDetails product) {
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      return GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    }

    return PurchaseParam(productDetails: product);
  }
}
