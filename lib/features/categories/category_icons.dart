import 'package:flutter/material.dart';

/// Maps the [iconKey] stored in the DB/JSON to a Material [IconData].
/// L-4: All icons use the **filled** variant for visual consistency.
///
/// Extracted from [CategoriesScreen] so [DifficultyScreen] can reuse the same
/// mapping without duplication.
IconData iconForCategoryKey(String iconKey) => switch (iconKey) {
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
