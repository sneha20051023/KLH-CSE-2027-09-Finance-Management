import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Formats [amount] as Indian currency with proper grouping.
///
/// Example: 1234567.50 → ₹12,34,567.50
String formatCurrency(double amount, {String symbol = '₹'}) {
  // Use Indian numbering system: last 3 digits, then groups of 2
  final bool isNegative = amount < 0;
  final double absAmount = amount.abs();

  final String integerPart = absAmount.truncate().toString();
  final String decimalPart = (absAmount - absAmount.truncate())
      .toStringAsFixed(2)
      .substring(2); // Gets the 2 digits after "0."

  String formatted;
  if (integerPart.length <= 3) {
    formatted = integerPart;
  } else {
    // Last 3 digits
    final String lastThree = integerPart.substring(integerPart.length - 3);
    String remaining = integerPart.substring(0, integerPart.length - 3);

    // Group remaining digits in pairs from right to left
    final StringBuffer buffer = StringBuffer();
    while (remaining.length > 2) {
      buffer.write(remaining.substring(0, remaining.length - 2));
      buffer.write(',');
      remaining = remaining.substring(remaining.length - 2);
    }
    // Handle any remaining digits
    if (remaining.isNotEmpty) {
      // Re-build: the above logic was incorrect. Let's use a simpler approach.
    }

    // Simpler Indian grouping approach
    formatted = _formatIndianNumber(integerPart);
  }

  final String sign = isNegative ? '-' : '';
  return '$sign$symbol$formatted.$decimalPart';
}

/// Internal helper that applies Indian numbering to an integer string.
String _formatIndianNumber(String number) {
  if (number.length <= 3) return number;

  final String lastThree = number.substring(number.length - 3);
  String remaining = number.substring(0, number.length - 3);

  // Insert commas every 2 digits from the right in the remaining part
  final StringBuffer result = StringBuffer();
  int count = 0;
  for (int i = remaining.length - 1; i >= 0; i--) {
    if (count > 0 && count % 2 == 0) {
      result.write(',');
    }
    result.write(remaining[i]);
    count++;
  }

  // Reverse the result since we built it backwards
  final String formattedRemaining =
      result.toString().split('').reversed.join('');

  return '$formattedRemaining,$lastThree';
}

/// Formats [date] as "dd MMM yyyy" (e.g., "15 Oct 2024").
String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

/// Formats [date] time component as "hh:mm a" (e.g., "02:30 PM").
String formatTime(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}

/// Formats [date] as "dd MMM yyyy, hh:mm a" (e.g., "15 Oct 2024, 02:30 PM").
String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}

/// Returns a time-based greeting string.
///
/// - Before 12:00 → "Good Morning"
/// - 12:00–16:59 → "Good Afternoon"
/// - 17:00 onwards → "Good Evening"
String getGreeting() {
  final int hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

/// Returns the [IconData] associated with a given [category] name.
///
/// Searches both expense and income categories defined in [AppConstants].
/// Falls back to [Icons.category] if no match is found.
IconData getCategoryIcon(String category) {
  // Search expense categories
  for (final cat in AppConstants.expenseCategories) {
    if (cat['name'] == category) {
      final String iconKey = cat['icon'] as String;
      return AppConstants.categoryIcons[iconKey] ?? Icons.category;
    }
  }
  // Search income categories
  for (final cat in AppConstants.incomeCategories) {
    if (cat['name'] == category) {
      final String iconKey = cat['icon'] as String;
      return AppConstants.categoryIcons[iconKey] ?? Icons.category;
    }
  }
  return Icons.category;
}

/// Returns the [Color] associated with a given [category] name.
///
/// Searches both expense and income categories defined in [AppConstants].
/// Falls back to [AppColors.textMuted] if no match is found.
Color getCategoryColor(String category) {
  // Search expense categories
  for (final cat in AppConstants.expenseCategories) {
    if (cat['name'] == category) {
      return Color(cat['color'] as int);
    }
  }
  // Search income categories
  for (final cat in AppConstants.incomeCategories) {
    if (cat['name'] == category) {
      return Color(cat['color'] as int);
    }
  }
  return AppColors.textMuted;
}

/// Returns the full month name for the given 1-indexed [month].
String getMonthName(int month) {
  const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

/// Returns the number of days in the given [month] of [year].
int getDaysInMonth(int year, int month) {
  // DateTime(year, month + 1, 0) gives the last day of the target month
  return DateTime(year, month + 1, 0).day;
}

/// Calculates the percentage change between [current] and [previous] values.
///
/// Returns 0.0 when [previous] is zero to avoid division-by-zero.
/// A positive result indicates growth; negative indicates decline.
double percentageChange(double current, double previous) {
  if (previous == 0) return 0.0;
  return ((current - previous) / previous) * 100;
}

/// Formats a compact version of the amount (e.g., 1.2K, 5.4L).
String formatCompactCurrency(double amount, {String symbol = '₹'}) {
  final double absAmount = amount.abs();
  final String sign = amount < 0 ? '-' : '';

  if (absAmount >= 10000000) {
    return '$sign$symbol${(absAmount / 10000000).toStringAsFixed(1)}Cr';
  } else if (absAmount >= 100000) {
    return '$sign$symbol${(absAmount / 100000).toStringAsFixed(1)}L';
  } else if (absAmount >= 1000) {
    return '$sign$symbol${(absAmount / 1000).toStringAsFixed(1)}K';
  }
  return '$sign$symbol${absAmount.toStringAsFixed(0)}';
}

/// Returns relative time description (e.g., "Today", "Yesterday", "3 days ago").
String getRelativeDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(date.year, date.month, date.day);
  final int difference = today.difference(target).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (difference < 7) return '$difference days ago';
  if (difference < 30) return '${(difference / 7).floor()} weeks ago';
  return formatDate(date);
}
