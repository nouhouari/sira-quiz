import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
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
        data: (categories) => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final name = locale == 'fr' ? cat.nameFr : cat.nameEn;
            return GestureDetector(
              key: Key('category_card_${cat.slug}'),
              onTap: () => context.push('/difficulty?cat=${cat.slug}'),
              child: FCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _iconForKey(cat.iconKey),
                          size: 22,
                          color: theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.typography.md.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Maps the [iconKey] stored in the DB/JSON to a Material [IconData].
  /// Adding a new category only requires adding its iconKey → icon entry here
  /// (or in the JSON); no slug-matching needed.
  IconData _iconForKey(String iconKey) => switch (iconKey) {
        'star' => Icons.star_outline,
        'book_open' => Icons.auto_stories,
        'mosque' => Icons.location_city,
        'route' => Icons.directions_walk,
        'city' => Icons.account_balance,
        'shield' => Icons.shield,
        'people' => Icons.people,
        'heart' => Icons.favorite,
        'moon' => Icons.nights_stay,
        'scroll' => Icons.menu_book,
        _ => Icons.help_outline,
      };
}
