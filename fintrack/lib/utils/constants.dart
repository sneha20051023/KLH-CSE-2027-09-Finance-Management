import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized color palette for the FinTrack application.
/// Uses the specified pastel pink aesthetic.
class AppColors {
  AppColors._(); // Prevent instantiation

  // Exact Pastel Pink Theme Direction
  static const Color primary = Color(0xFFF4A6BD);       // Primary Pink
  static const Color softBlush = Color(0xFFFCE4EC);      // Soft Blush
  static const Color background = Color(0xFFFFF7F9);     // Soft Blush Background
  static const Color card = Color(0xFFFFFFFF);           // White Cards
  static const Color roseAccent = Color(0xFFE98BAA);     // Rose Accent
  static const Color lightPeach = Color(0xFFFFE5D6);     // Light Peach
  static const Color pastelMint = Color(0xFFDDF3E8);     // Pastel Mint
  static const Color softLavender = Color(0xFFF0E6FA);   // Soft Lavender
  static const Color text = Color(0xFF49343E);           // Main Text
  static const Color textLight = Color(0xFF927D87);      // Secondary Text

  // Semantic & Aliases
  static const Color secondary = Color(0xFFE98BAA);      // Rose Accent / Secondary
  static const Color accent = Color(0xFFFCE4EC);         // Soft Blush Accent
  static const Color income = Color(0xFF38A169);         // Soft Forest/Mint Green
  static const Color expense = Color(0xFFE05375);        // Soft Rose/Berry
  static const Color divider = Color(0xFFFCE8EE);        // Delicate Blush Divider
  static const Color error = Color(0xFFE05375);          // Soft Rose Error
  static const Color success = Color(0xFF38A169);        // Soft Mint Success
  static const Color warning = Color(0xFFEAA255);        // Soft Peach/Amber
  static const Color textMuted = Color(0xFFB5A4AC);      // Muted caption text

  // Dark theme colors (kept subtle plum/rose)
  static const Color darkBackground = Color(0xFF23181F);
  static const Color darkCard = Color(0xFF2F212B);
  static const Color darkSurface = Color(0xFF3B2A36);
  static const Color darkText = Color(0xFFFFF7F9);
  static const Color darkTextLight = Color(0xFFD4BCC7);
}

/// Consistent typography styles used across the application.
class AppTextStyles {
  AppTextStyles._(); // Prevent instantiation

  static TextStyle get heading1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  static TextStyle get heading2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  static TextStyle get heading3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      );

  static TextStyle get subtitle1 => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      );

  static TextStyle get subtitle2 => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get body1 => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.text,
      );

  static TextStyle get body2 => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.text,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  /// Returns the amount text style colored for income (green) or expense (rose).
  static TextStyle amount({required bool isIncome}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isIncome ? AppColors.income : AppColors.expense,
      );

  static TextStyle get currencyLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );
}

/// Application-wide constants including metadata, categories, and payment methods.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // App metadata
  static const String appName = 'FinTrack';
  static const String appTagline = 'Smart Personal Finance';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String budgetsCollection = 'budgets';
  static const String billsCollection = 'bills';

  /// The 12 expense categories with their associated icons and unique pastel colors.
  static const List<Map<String, dynamic>> expenseCategories = [
    {
      'name': 'Food & Dining',
      'icon': 'restaurant',
      'color': 0xFFF8A978, // Pastel Coral/Peach
    },
    {
      'name': 'Groceries',
      'icon': 'shopping_cart',
      'color': 0xFFA8E6CF, // Pastel Mint
    },
    {
      'name': 'Shopping',
      'icon': 'shopping_bag',
      'color': 0xFFF4A6BD, // Pastel Pink
    },
    {
      'name': 'Transportation',
      'icon': 'directions_car',
      'color': 0xFF9ED2C6, // Pastel Seafoam
    },
    {
      'name': 'Housing & Rent',
      'icon': 'home',
      'color': 0xFFC3B1E1, // Pastel Lavender
    },
    {
      'name': 'Bills & Utilities',
      'icon': 'receipt_long',
      'color': 0xFF88D49E, // Pastel Soft Green
    },
    {
      'name': 'Health & Fitness',
      'icon': 'fitness_center',
      'color': 0xFFFF8B94, // Pastel Rose
    },
    {
      'name': 'Education',
      'icon': 'school',
      'color': 0xFFFBE7A1, // Pastel Butter Yellow
    },
    {
      'name': 'Entertainment',
      'icon': 'movie',
      'color': 0xFFCDB4DB, // Pastel Lilac
    },
    {
      'name': 'Subscriptions',
      'icon': 'subscriptions',
      'color': 0xFFFFAAA6, // Pastel Salmon Pink
    },
    {
      'name': 'Travel',
      'icon': 'flight',
      'color': 0xFFA0CED9, // Pastel Soft Sky
    },
    {
      'name': 'Others',
      'icon': 'more_horiz',
      'color': 0xFFD6D2D6, // Pastel Soft Grey
    },
  ];

  /// Income categories with pastel colors
  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'name': 'Salary',
      'icon': 'account_balance_wallet',
      'color': 0xFF7BC8A4, // Pastel Mint Green
    },
    {
      'name': 'Freelance',
      'icon': 'laptop_mac',
      'color': 0xFF9ED2C6, // Pastel Seafoam
    },
    {
      'name': 'Investment',
      'icon': 'trending_up',
      'color': 0xFFC3B1E1, // Pastel Lavender
    },
    {
      'name': 'Business',
      'icon': 'business_center',
      'color': 0xFFF8A978, // Pastel Peach
    },
    {
      'name': 'Others',
      'icon': 'more_horiz',
      'color': 0xFFD6D2D6, // Pastel Soft Grey
    },
  ];

  /// Supported payment methods
  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'Wallet',
  ];

  /// Maps category icon string identifiers to Material [IconData].
  static const Map<String, IconData> categoryIcons = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'home': Icons.home_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'flight': Icons.flight_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'laptop_mac': Icons.laptop_mac_rounded,
    'trending_up': Icons.trending_up_rounded,
    'business_center': Icons.business_center_rounded,
  };

  /// Returns the list of category names for expenses.
  static List<String> get expenseCategoryNames =>
      expenseCategories.map((c) => c['name'] as String).toList();

  /// Returns the list of category names for income.
  static List<String> get incomeCategoryNames =>
      incomeCategories.map((c) => c['name'] as String).toList();
}
