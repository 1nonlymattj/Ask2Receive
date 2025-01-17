import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppPurchaseService {
  // Define product ID for the ad-free purchase
  static const String adFreeProductId = 'com.yourapp.ad_free';

  // Instance of InAppPurchase
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Whether the app is in a purchase process
  bool _isProcessing = false;

  // Listen to purchase updates
  void listenToPurchaseUpdated(Stream<List<PurchaseDetails>> purchaseUpdated) {
    purchaseUpdated.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    });
  }

  // Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // When purchase is successful, update the ad-free status
        await _toggleAdFree(true);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle purchase errors here
        print("Purchase failed: ${purchaseDetails.error}");
      }
      // Acknowledge the purchase
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  // Check if the user has an ad-free purchase
  Future<bool> isAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_ad_free') ??
        false; // Default is false if not found
  }

  // Toggle the ad-free status
  Future<void> _toggleAdFree(bool isAdFree) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', isAdFree);
  }

  // Initiate the purchase flow
  Future<void> initiatePurchase() async {
    if (_isProcessing) return; // Prevent multiple purchases simultaneously

    _isProcessing = true;

    // Check if the product is available for purchase
    final productDetailsResponse =
        await _inAppPurchase.queryProductDetails({adFreeProductId});
    if (productDetailsResponse.notFoundIDs.isNotEmpty) {
      print("Product not found.");
      _isProcessing = false;
      return;
    }

    // Start the purchase flow
    final productDetails = productDetailsResponse.productDetails;
    if (productDetails.isNotEmpty) {
      final purchaseParam = PurchaseParam(productDetails: productDetails.first);
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }

    _isProcessing = false;
  }

  // Retrieve available products
  Future<void> loadProducts() async {
    final productDetailsResponse =
        await _inAppPurchase.queryProductDetails({adFreeProductId});
    if (productDetailsResponse.notFoundIDs.isNotEmpty) {
      print("Product not found.");
      return;
    }
    // Product is available for purchase
    final products = productDetailsResponse.productDetails;
    if (products.isNotEmpty) {
      // You can display this to the user or save it for later use
      print("Product found: ${products.first.title}");
    }
  }
}
