import 'package:flutter/material.dart';

/// Represents an expense category with its visual properties
/// and dynamically calculated spending data.
class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;

  /// Total amount spent in this category — calculated at runtime, not stored.
  final double totalSpent;

  /// Percentage of total expenses for this category — calculated at runtime, not stored.
  final double percentage;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    this.totalSpent = 0.0,
    this.percentage = 0.0,
  });

  /// Returns a copy of this [CategoryModel] with the given fields replaced.
  /// Primarily used to attach calculated spending data to a category.
  CategoryModel copyWith({
    String? name,
    IconData? icon,
    Color? color,
    double? totalSpent,
    double? percentage,
  }) {
    return CategoryModel(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      totalSpent: totalSpent ?? this.totalSpent,
      percentage: percentage ?? this.percentage,
    );
  }

  /// The 12 predefined expense categories with pastel aesthetic colors.
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF8A978), // Pastel Coral/Peach
    ),
    CategoryModel(
      name: 'Groceries',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFFA8E6CF), // Pastel Mint
    ),
    CategoryModel(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFF4A6BD), // Pastel Pink
    ),
    CategoryModel(
      name: 'Transportation',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF9ED2C6), // Pastel Seafoam
    ),
    CategoryModel(
      name: 'Housing & Rent',
      icon: Icons.home_rounded,
      color: Color(0xFFC3B1E1), // Pastel Lavender
    ),
    CategoryModel(
      name: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF88D49E), // Pastel Soft Green
    ),
    CategoryModel(
      name: 'Health & Fitness',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF8B94), // Pastel Rose
    ),
    CategoryModel(
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFFFBE7A1), // Pastel Butter Yellow
    ),
    CategoryModel(
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFFCDB4DB), // Pastel Lilac
    ),
    CategoryModel(
      name: 'Subscriptions',
      icon: Icons.subscriptions_rounded,
      color: Color(0xFFFFAAA6), // Pastel Salmon Pink
    ),
    CategoryModel(
      name: 'Travel',
      icon: Icons.flight_rounded,
      color: Color(0xFFA0CED9), // Pastel Soft Sky
    ),
    CategoryModel(
      name: 'Others',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFFD6D2D6), // Pastel Soft Grey
    ),
  ];

  /// Finds a [CategoryModel] by name from the default categories.
  /// Returns the 'Others' category if no match is found.
  static CategoryModel findByName(String name) {
    return defaultCategories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => defaultCategories.last, // 'Others'
    );
  }

  @override
  String toString() {
    return 'CategoryModel(name: $name, totalSpent: $totalSpent, percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}
