import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/application.dart';
import '../app/theme.dart';

/// Company and Platform Logo Widget
/// Dynamically renders official company branding, platform logos, or
/// high-fidelity liquid-glass brand monograms with authentic brand colors.
class CompanyLogoWidget extends StatelessWidget {
  final String company;
  final String? logoUrl;
  final OpportunityCategory? category;
  final double size;
  final double borderRadius;
  final bool showCategoryBadge;

  const CompanyLogoWidget({
    super.key,
    required this.company,
    this.logoUrl,
    this.category,
    this.size = 44,
    this.borderRadius = 12,
    this.showCategoryBadge = false,
  });

  static const Map<String, String> _knownDomains = {
    'amazon': 'amazon.com',
    'aws': 'amazon.com',
    'google': 'google.com',
    'google cloud': 'google.com',
    'microsoft': 'microsoft.com',
    'meta': 'meta.com',
    'facebook': 'meta.com',
    'apple': 'apple.com',
    'netflix': 'netflix.com',
    'uber': 'uber.com',
    'spotify': 'spotify.com',
    'stripe': 'stripe.com',
    'github': 'github.com',
    'linkedin': 'linkedin.com',
    'salesforce': 'salesforce.com',
    'atlassian': 'atlassian.com',
    'airbnb': 'airbnb.com',
    'ethglobal': 'ethglobal.com',
    'codeforces': 'codeforces.com',
    'devpost': 'devpost.com',
    'leetcode': 'leetcode.com',
    'hackerrank': 'hackerrank.com',
    'unstop': 'unstop.com',
    'mlh': 'mlh.io',
    'major league hacking': 'mlh.io',
    'flutter': 'flutter.dev',
    'intel': 'intel.com',
    'nvidia': 'nvidia.com',
    'adobe': 'adobe.com',
    'oracle': 'oracle.com',
    'cisco': 'cisco.com',
    'goldman sachs': 'goldmansachs.com',
    'jpmorgan': 'jpmorganchase.com',
    'jp morgan': 'jpmorganchase.com',
    'coinbase': 'coinbase.com',
    'openai': 'openai.com',
    'anthropic': 'anthropic.com',
    'dropbox': 'dropbox.com',
    'slack': 'slack.com',
    'figma': 'figma.com',
    'notion': 'notion.so',
    'vercel': 'vercel.com',
    'supabase': 'supabase.com',
    'polygon': 'polygon.technology',
    'solana': 'solana.com',
    'ethereum': 'ethereum.org',
  };

  static const Map<String, Color> _brandColors = {
    'google': Color(0xFF4285F4),
    'microsoft': Color(0xFF00A4EF),
    'amazon': Color(0xFFFF9900),
    'aws': Color(0xFFFF9900),
    'apple': Color(0xFF8E8E93),
    'meta': Color(0xFF0668E1),
    'facebook': Color(0xFF0668E1),
    'netflix': Color(0xFFE50914),
    'uber': Color(0xFF1E293B),
    'spotify': Color(0xFF1DB954),
    'stripe': Color(0xFF635BFF),
    'github': Color(0xFF24292E),
    'linkedin': Color(0xFF0A66C2),
    'salesforce': Color(0xFF00A1E0),
    'nvidia': Color(0xFF76B900),
    'adobe': Color(0xFFFF0000),
    'goldman sachs': Color(0xFF7399C6),
    'jpmorgan': Color(0xFF005C94),
    'openai': Color(0xFF10A37F),
    'anthropic': Color(0xFFD97757),
    'figma': Color(0xFFF24E1E),
    'solana': Color(0xFF14F195),
    'ethereum': Color(0xFF627EEA),
    'polygon': Color(0xFF8247E5),
    'unstop': Color(0xFF1C4980),
    'leetcode': Color(0xFFFFA116),
  };

  String? _resolveDomain(String name) {
    final lower = name.toLowerCase().trim();
    for (final entry in _knownDomains.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    // Clean company suffix
    var cleaned = lower
        .replaceAll(RegExp(r'\b(inc|corp|corporation|llc|ltd|co|technologies|tech|labs|group|summit|conference|hackathon|contest|round)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();

    if (cleaned.length >= 2) {
      return '$cleaned.com';
    }
    return null;
  }

  String _getPrimaryLogoUrl() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return logoUrl!;
    }
    // On Flutter Web, browser XMLHttpRequest blocks cross-origin favicon calls with CORS.
    // On native platforms (Android/iOS), Google Favicon resolves seamlessly.
    if (!kIsWeb) {
      final domain = _resolveDomain(company);
      if (domain != null) {
        return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
      }
    }
    return '';
  }

  String _getMonogram(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'CO';
    final parts = trimmed.split(RegExp(r'[\s\-_]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Color _resolveBrandColor(Color fallbackColor) {
    final lower = company.toLowerCase().trim();
    for (final entry in _brandColors.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return fallbackColor;
  }

  static bool debugDisableNetwork = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryUrl = debugDisableNetwork ? '' : _getPrimaryLogoUrl();
    final accentColor = _resolveBrandColor(category?.color ?? AppTheme.orange);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isDark ? const Color(0xFF1E2638) : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: primaryUrl.isNotEmpty
              ? Image.network(
                  primaryUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildMonogramFallback(accentColor, isDark),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return Padding(
                        padding: EdgeInsets.all(size * 0.14),
                        child: child,
                      );
                    }
                    return _buildMonogramFallback(accentColor, isDark);
                  },
                )
              : _buildMonogramFallback(accentColor, isDark),
        ),

        // Optional Micro-badge for Category
        if (showCategoryBadge && category != null)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2638) : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Icon(
                category!.icon,
                size: size * 0.24,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonogramFallback(Color accentColor, bool isDark) {
    final monogram = _getMonogram(company);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.28 : 0.16),
            accentColor.withValues(alpha: isDark ? 0.12 : 0.05),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: TextStyle(
          color: accentColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
