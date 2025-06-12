import 'package:flutter/material.dart';
import '../constants.dart';
import '../screens/token_purchase_screen.dart';

class NotEnoughTokensDialog extends StatelessWidget {
  final int requiredTokens;
  final int currentTokens;
  final VoidCallback? onBuyTokens;

  const NotEnoughTokensDialog({
    super.key,
    required this.requiredTokens,
    required this.currentTokens,
    this.onBuyTokens,
  });

  @override
  Widget build(BuildContext context) {
    final shortfall = requiredTokens - currentTokens;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.offlineRed.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.offlineRed.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token icon with glowing effect
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
                border: Border.all(
                  color: AppColors.offlineRed.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.offlineRed.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.token, color: AppColors.offlineRed, size: 40),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Not Enough Tokens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              'You need $requiredTokens tokens for this action, but you only have $currentTokens tokens. You need $shortfall more tokens.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Token info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Creating a room costs 100 tokens and sending a message costs 1 token.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to token purchase screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TokenPurchaseScreen(),
                      ),
                    );

                    // Call the optional callback if provided
                    if (onBuyTokens != null) {
                      onBuyTokens!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Get More Tokens',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show this dialog
  static Future<void> show({
    required BuildContext context,
    required int requiredTokens,
    required int currentTokens,
    VoidCallback? onBuyTokens,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => NotEnoughTokensDialog(
        requiredTokens: requiredTokens,
        currentTokens: currentTokens,
        onBuyTokens: onBuyTokens,
      ),
    );
  }
}
