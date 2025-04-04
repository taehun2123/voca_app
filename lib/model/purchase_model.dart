// lib/model/purchase_model.dart

class PurchaseOption {
  final String id;
  final String title;
  final String description;
  final double price;
  final int creditsAmount;

  PurchaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.creditsAmount,
  });
}

class PurchaseHistory {
  final String purchaseId;
  final String productId;
  final DateTime purchaseDate;
  final int creditsAmount;

  PurchaseHistory({
    required this.purchaseId,
    required this.productId,
    required this.purchaseDate,
    required this.creditsAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'productId': productId,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'creditsAmount': creditsAmount,
    };
  }

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      purchaseId: json['purchaseId'],
      productId: json['productId'],
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(json['purchaseDate']),
      creditsAmount: json['creditsAmount'],
    );
  }
}