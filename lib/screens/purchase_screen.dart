// lib/screens/purchase_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocabulary_app/services/ad_service.dart';
import 'package:vocabulary_app/services/purchase_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  int _remainingUsages = 0;
  bool _isLoading = true;
  String _statusMessage = '';
  bool _hasError = false;
  StreamSubscription<PurchaseState>? _purchaseStateSubscription;
  // 광고 서비스 추가
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToPurchaseUpdates();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usages = await _purchaseService.getRemainingUsages();

      setState(() {
        _remainingUsages = usages;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = '데이터를 불러오는 중 오류가 발생했습니다';
      });
    }
  }

  void _subscribeToPurchaseUpdates() {
    _purchaseStateSubscription =
        _purchaseService.purchaseStateStream.listen((state) {
      switch (state) {
        case PurchaseState.notAvailable:
          setState(() {
            _statusMessage = '인앱 결제를 사용할 수 없습니다';
            _hasError = true;
          });
          break;
        case PurchaseState.loading:
          setState(() {
            _isLoading = true;
            _statusMessage = '로드 중...';
          });
          break;
        case PurchaseState.loaded:
          setState(() {
            _isLoading = false;
            _statusMessage = '';
          });
          break;
        case PurchaseState.pending:
          setState(() {
            _statusMessage = '결제 처리 중...';
          });
          break;
        case PurchaseState.purchased:
          _loadData(); // 구매 후 잔액 리로드
          _showSuccessDialog();
          break;
        case PurchaseState.canceled:
          setState(() {
            _statusMessage = '결제가 취소되었습니다';
          });
          break;
        case PurchaseState.error:
          setState(() {
            _statusMessage = '결제 중 오류가 발생했습니다';
            _hasError = true;
          });
          break;
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            SizedBox(height: 16),
            Text('구매 완료!'),
          ],
        ),
        content: Text(
          '구매가 완료되었습니다. 충전된 횟수로 단어장을 계속 생성하세요!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _purchaseStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final products = _purchaseService.getProducts();

    return Scaffold(
      appBar: AppBar(
        title: Text('사용권 구매'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 현재 사용량 정보
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.shade900.withOpacity(0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: isDarkMode
                                      ? Colors.blue.shade300
                                      : Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '현재 남은 사용 횟수',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '$_remainingUsages회',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_remainingUsages <= 0) ...[
                        const SizedBox(height: 24),
                        Text(
                          '무료로 충전하기',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWatchAdCard(),
                      ],
                      const SizedBox(height: 24),
                      // 구매 옵션 설명
                      Text(
                        '사용권 구매',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '단어장 자동 생성 기능을 이용하기 위한 사용권을 구매하세요. 각 결제는 해당 횟수만큼 단어장을 생성할 수 있는 권한을 제공합니다.',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      SizedBox(height: 24),

                      // 상품 목록
                      if (products.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('구매 가능한 상품이 없습니다'),
                            ],
                          ),
                        )
                      else
                        ...products
                            .map((product) => _buildProductCard(product)),

                      SizedBox(height: 24),

                      // 설명
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '사용 안내',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildInfoItem(
                              '단어장 1회 생성 = 1회 차감',
                              '단어장을 생성할 때마다 1회씩 차감됩니다.',
                            ),
                            _buildInfoItem(
                              '구매한 횟수는 누적됩니다',
                              '새로 구매한 횟수는 기존 잔여 횟수에 추가됩니다.',
                            ),
                            _buildInfoItem(
                              '환불 정책',
                              '앱스토어의 표준 환불 정책을 따릅니다. 이미 사용한 횟수는 환불되지 않습니다.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // lib/screens/purchase_screen.dart의 _buildWatchAdCard 메서드 수정

  Widget _buildWatchAdCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.amber.shade700 : Colors.amber.shade300,
        ),
      ),
      child: InkWell(
        onTap: _watchAdForCredits,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.amber.shade900.withOpacity(0.3)
                      : Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '🐹', // 햄스터 이모지 사용
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '광고 시청으로 무료 충전',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.white
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '30초 광고를 시청하고 1회 무료 충전받기',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: isDarkMode
                              ? Colors.amber.shade300
                              : Colors.amber.shade700,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+1회',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.amber.shade300
                                : Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.amber.shade900.withOpacity(0.5)
                      : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '무료',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 광고 시청으로 크레딧 획득 메서드
  Future<void> _watchAdForCredits() async {
    // 로딩 표시
    setState(() {
      _isLoading = true;
      _statusMessage = '광고 준비 중...';
    });

    try {
      final result = await _purchaseService.addCreditByWatchingAd();

      // 광고 시청 완료 후
      if (result) {
        // 사용량 다시 로드
        await _loadData();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('광고 시청 완료! 1회 충전되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = '광고를 불러올 수 없습니다. 나중에 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '광고 처리 중 오류가 발생했습니다: $e';
      });
    }
  }

  Widget _buildProductCard(ProductDetails product) {
    // 상품 ID에 따라 정보 설정
    String title = '알 수 없는 상품';
    String description = '';
    int usageCount = 0;
    IconData productIcon = Icons.credit_card;

    if (product.id.contains('10')) {
      title = '10회 추가 이용권';
      description = '단어장 생성 10회 이용권';
      usageCount = 10;
      productIcon = Icons.book;
    } else if (product.id.contains('30')) {
      title = '30회 추가 이용권';
      description = '단어장 생성 30회 이용권';
      usageCount = 30;
      productIcon = Icons.auto_stories;
    } else if (product.id.contains('60')) {
      title = '60회 추가 이용권';
      description = '단어장 생성 60회 이용권';
      usageCount = 60;
      productIcon = Icons.auto_stories;
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: () => _purchaseService.buyProduct(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade900.withOpacity(0.3)
                      : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  productIcon,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.white
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color:
                              isDarkMode ? Colors.green.shade300 : Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+$usageCount회',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.green.shade300
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade900.withOpacity(0.5)
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.blue.shade300
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.textTheme.bodyMedium?.color,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
