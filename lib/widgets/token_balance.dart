import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/chat_service.dart';
import '../screens/token_purchase_screen.dart';

class TokenBalance extends StatefulWidget {
  final bool showLabel;
  final bool isCompact;
  final bool showAddButton;

  const TokenBalance({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
    this.showAddButton = true,
  });

  @override
  State<TokenBalance> createState() => _TokenBalanceState();
}

class _TokenBalanceState extends State<TokenBalance>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  int _tokenBalance = 0;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadTokenBalance();

    // Setup animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

  Future<void> _loadTokenBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _chatService.getUserTokenBalance();
      setState(() {
        _tokenBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToTokenPurchase(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TokenPurchaseScreen()),
    ).then((_) {
      // Refresh token balance when returning from purchase screen
      _loadTokenBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 8 : 12,
            vertical: widget.isCompact ? 4 : 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withOpacity(0.2 * pulseValue),
                AppColors.primaryPurple.withOpacity(0.3 * pulseValue),
              ],
            ),
            borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3 * pulseValue),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.2 * pulseValue),
                blurRadius: 8 * pulseValue,
                spreadRadius: 1 * pulseValue,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.token,
                color: AppColors.primaryBlue,
                size: widget.isCompact ? 18 : 22,
              ),
              SizedBox(width: widget.isCompact ? 4 : 8),
              if (_isLoading)
                SizedBox(
                  width: widget.isCompact ? 14 : 18,
                  height: widget.isCompact ? 14 : 18,
                  child: CircularProgressIndicator(
                    strokeWidth: widget.isCompact ? 2 : 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                )
              else
                Text(
                  _tokenBalance.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isCompact ? 14 : 16,
                  ),
                ),
              if (widget.showLabel && !widget.isCompact) ...[
                const SizedBox(width: 4),
                Text(
                  'Tokens',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                ),
              ],
              if (widget.showAddButton) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _navigateToTokenPurchase(context),
                  child: Container(
                    width: widget.isCompact ? 20 : 24,
                    height: widget.isCompact ? 20 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen.withOpacity(
                        0.3 * pulseValue,
                      ),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(
                          0.6 * pulseValue,
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(
                            0.2 * pulseValue,
                          ),
                          blurRadius: 4 * pulseValue,
                          spreadRadius: 1 * pulseValue,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: widget.isCompact ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
