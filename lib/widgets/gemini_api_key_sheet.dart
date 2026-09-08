import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../controllers/ai_controller.dart';

/// Shows an ultra-polished bottom sheet to configure, test, and save the user's Gemini API key.
/// Can be invoked directly from the Chat header, profile screen, or activation banners.
Future<void> showGeminiApiKeySheet(BuildContext context) async {
  final aiCtrl = context.read<AIController>();
  final currentKey = aiCtrl.currentApiKey;
  final textController = TextEditingController(text: currentKey);
  bool obscure = true;
  bool isTesting = false;
  String? testResult;
  bool testSuccess = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppTheme.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Gemini AI Key',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enables live reasoning, deep chat coaching & smart extraction',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: aiCtrl.currentApiKey.isNotEmpty
                          ? (aiCtrl.isDefaultKey ? AppTheme.orange.withValues(alpha: 0.12) : AppTheme.vibrantGreen.withValues(alpha: 0.12))
                          : (isDark ? AppTheme.darkSurface : AppTheme.lightBg),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: aiCtrl.currentApiKey.isNotEmpty
                            ? (aiCtrl.isDefaultKey ? AppTheme.orange.withValues(alpha: 0.3) : AppTheme.vibrantGreen.withValues(alpha: 0.3))
                            : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          aiCtrl.currentApiKey.isNotEmpty
                              ? (aiCtrl.isDefaultKey ? Icons.auto_awesome_rounded : Icons.verified_user_rounded)
                              : Icons.cloud_off_rounded,
                          size: 13,
                          color: aiCtrl.currentApiKey.isNotEmpty
                              ? (aiCtrl.isDefaultKey ? AppTheme.orange : AppTheme.vibrantGreen)
                              : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          aiCtrl.currentApiKey.isNotEmpty
                              ? (aiCtrl.isDefaultKey ? 'Environment Key Active' : 'Gemini Key Active')
                              : 'Offline Mode (Local AI Engine)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: aiCtrl.currentApiKey.isNotEmpty
                                ? (aiCtrl.isDefaultKey ? AppTheme.orange : AppTheme.vibrantGreen)
                                : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  obscureText: obscure,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter API key (AIzaSy...)',
                    hintStyle: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.orange, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                      onPressed: () => setSheetState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your Gemini API key from Google AI Studio (aistudio.google.com). Keys can also be configured securely in secrets/api_keys.json.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (testSuccess ? AppTheme.vibrantGreen : AppTheme.vibrantRed).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (testSuccess ? AppTheme.vibrantGreen : AppTheme.vibrantRed).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          size: 16,
                          color: testSuccess ? AppTheme.vibrantGreen : AppTheme.vibrantRed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: testSuccess ? AppTheme.vibrantGreen : AppTheme.vibrantRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isTesting
                            ? null
                            : () async {
                                setSheetState(() {
                                  isTesting = true;
                                  testResult = null;
                                });
                                final err = await aiCtrl.testApiKey(textController.text.trim());
                                setSheetState(() {
                                  isTesting = false;
                                  testSuccess = (err == null);
                                  testResult = (err == null)
                                      ? 'API key verified successfully with Gemini 2.5!'
                                      : err;
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        child: isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                              )
                            : const Text('Test Key', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final key = textController.text.trim();
                          await aiCtrl.updateApiKey(key);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(key.isNotEmpty
                                    ? 'Gemini API key saved & activated!'
                                    : 'Gemini API key cleared (using local offline AI).'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                if (aiCtrl.hasEnvironmentKey && !aiCtrl.isDefaultKey) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 16, color: AppTheme.orange),
                    label: const Text(
                      'Reset to Environment Key',
                      style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    onPressed: () async {
                      await aiCtrl.restoreDefaultKey();
                      textController.text = aiCtrl.currentApiKey;
                      setSheetState(() {
                        testResult = 'Restored environment API key!';
                        testSuccess = true;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Environment Gemini key restored & activated!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                  ),
                ],
                if (aiCtrl.currentApiKey.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      await aiCtrl.clearApiKey();
                      textController.text = '';
                      setSheetState(() {
                        testResult = null;
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Gemini API key cleared. Reverted to Local AI Engine.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Clear Key (Use Local Engine)',
                      style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      },
    ),
  );
}
