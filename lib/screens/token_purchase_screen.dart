import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/user_service.dart';

class TokenPurchaseScreen extends StatefulWidget {
  const TokenPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<TokenPurchaseScreen> createState() => _TokenPurchaseScreenState();
}

class _TokenPurchaseScreenState extends State<TokenPurchaseScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  bool _isProcessing = false;
  int? _selectedPackage;

  // Token package options
  final List<Map<String, dynamic>> _tokenPackages = [
    {
      'tokens': 100,
      'price': 50,
      'label': 'Basic',
      'description': 'Good for casual chatting',
      'color': AppColors.primaryBlue,
      'bestValue': false,
    },
    {
      'tokens': 300,
      'price': 150,
      'label': 'Standard',
      'description': 'Most popular option',
      'color': AppColors.primaryPurple,
      'bestValue': true,
    },
    {
      'tokens': 500,
      'price': 200,
      'label': 'Premium',
      'description': 'Best value for money',
      'color': AppColors.primaryGreen,
      'bestValue': false,
    },
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _purchaseTokens(int tokenAmount, double price) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // In a real app, this would process payment
      // For now, we'll just simulate a purchase and add tokens
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate network delay

      // Add tokens to user's account
      final userId = _userService.currentUserId;
      if (userId != null) {
        await _userService.addTokens(userId, tokenAmount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully purchased $tokenAmount tokens!'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );

          // Return to previous screen
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error purchasing tokens: ${e.toString()}'),
            backgroundColor: AppColors.offlineRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PURCHASE TOKENS",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.primaryBlue.withOpacity(0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              AppColors.primaryBlue.withOpacity(0.8),
              const Color(0xFF0A0A18),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.token, color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "Power Up Your Conversations",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Purchase tokens to create chat rooms and send messages.",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Token packages
                Expanded(
                  child: ListView.builder(
                    itemCount: _tokenPackages.length,
                    itemBuilder: (context, index) {
                      final package = _tokenPackages[index];
                      final isSelected = _selectedPackage == index;

                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseValue = _pulseAnimation.value;
                          final highlightValue = isSelected ? 1.2 : 1.0;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPackage = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    package['color'].withOpacity(
                                      0.3 * highlightValue * pulseValue,
                                    ),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? package['color'].withOpacity(
                                            0.8 * pulseValue,
                                          )
                                          : Colors.white.withOpacity(
                                            0.1 * pulseValue,
                                          ),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: package['color'].withOpacity(
                                        0.3 * pulseValue,
                                      ),
                                      blurRadius: 10 * pulseValue,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Token count with icon
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.4),
                                      border: Border.all(
                                        color: package['color'].withOpacity(
                                          0.6 * pulseValue,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.token,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        Text(
                                          package['tokens'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Package details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              package['label'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (package['bestValue'])
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: package['color']
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'BEST VALUE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          package['description'],
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'R${package['price']}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            shadows: [
                                              Shadow(
                                                color: package['color']
                                                    .withOpacity(
                                                      0.7 * pulseValue,
                                                    ),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Check mark for selected package
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: package['color'],
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Purchase button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _selectedPackage != null && !_isProcessing
                            ? () => _purchaseTokens(
                              _tokenPackages[_selectedPackage!]['tokens'],
                              _tokenPackages[_selectedPackage!]['price']
                                  .toDouble(),
                            )
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedPackage != null
                              ? _tokenPackages[_selectedPackage!]['color']
                              : Colors.grey,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isProcessing
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _selectedPackage != null
                                  ? 'BUY ${_tokenPackages[_selectedPackage!]['tokens']} TOKENS FOR R${_tokenPackages[_selectedPackage!]['price']}'
                                  : 'SELECT A PACKAGE',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 16),

                // Disclaimer
                Text(
                  'This is a simulated purchase for demo purposes. No real money will be charged.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
