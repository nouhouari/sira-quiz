import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/quiz_repository.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final locale = Localizations.localeOf(context).languageCode;
    final categoriesAsync = ref.watch(categoriesProvider);

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.categories_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: categoriesAsync.when(
        loading: () => Center(
          child: Text(
            l10n.common_loading,
            style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground),
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            l10n.common_error,
            style: theme.typography.sm.copyWith(color: theme.colors.error),
          ),
        ),
        // M-1: ensure the last category card is at full visual weight.
        // No scroll fade gradient — just enough bottom padding so the last
        // card clears the safe area and doesn't appear cropped/dimmed.
        data: (categories) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final name = locale == 'fr' ? cat.nameFr : cat.nameEn;
            return _CategoryCard(
              key: Key('category_card_${cat.slug}'),
              name: name,
              iconData: _iconForKey(cat.iconKey),
              onTap: () => context.push('/difficulty?cat=${cat.slug}'),
              theme: theme,
            );
          },
        ),
      ),
    );
  }

  /// Maps the [iconKey] stored in the DB/JSON to a Material [IconData].
  /// L-4: All icons use the **filled** variant for visual consistency.
  IconData _iconForKey(String iconKey) => switch (iconKey) {
        'star' => Icons.star_rounded,
        'book_open' => Icons.auto_stories,
        'mosque' => Icons.location_city,
        'route' => Icons.directions_walk,
        'city' => Icons.account_balance,
        'shield' => Icons.shield,
        'people' => Icons.people,
        'heart' => Icons.favorite,
        'moon' => Icons.nights_stay,
        'scroll' => Icons.menu_book,
        _ => Icons.help,
      };
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData iconData;
  final VoidCallback onTap;
  final FThemeData theme;

  const _CategoryCard({
    super.key,
    required this.name,
    required this.iconData,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.colors.background.computeLuminance() < 0.2;
    // L-4: uniform chip background alpha across all rows.
    final chipBg = isDark
        ? darkEmerald.withAlpha(35)
        : emerald.withAlpha(20);
    // L-4: filled icon color (emerald — not gold) for consistency.
    final chipIcon = isDark ? darkEmerald : emerald;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 35 : 12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Emerald-tinted icon chip — filled icons, uniform bg tint (L-4).
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, size: 22, color: chipIcon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.foreground,
                ),
              ),
            ),
            // E-7: 6px gold-filled dot — distinctive "select one" accent.
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
