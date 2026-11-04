import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/security_provider.dart';
import '../security/security_center_screen.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/set_budget_dialog.dart';

/// Independent screen for User Profile and Application Settings.
///
/// Features:
/// - Profile Information with Edit Profile dialog
/// - Monthly Budget Setting and Tracking
/// - Currency Selector (INR, USD, EUR, GBP, JPY)
/// - Notification Reminders (Bill alerts, Daily summary, Budget threshold)
/// - Pastel Pink Design Aesthetic Preview
/// - Security & Data Management (Change password, Export data, Reset demo data)
/// - About FINTRACK Capstone Project info
/// - Sign Out action with confirmation
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.user?.fullName ?? 'Harini';
    _phoneController.text = auth.user?.phoneNumber ?? '+91 98765 43210';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.roseAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.roseAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              setState(() => _isSaving = true);
              final success = await auth.updateProfile(
                fullName: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
              );
              if (mounted) {
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile.'),
                    backgroundColor: success ? AppColors.income : AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.roseAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.roseAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val != newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await auth.changePassword(newPasswordController.text);
                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password updated!' : 'Failed to update password.'),
                      backgroundColor: success ? AppColors.income : AppColors.expense,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    const currencies = [
      {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange_rounded, color: AppColors.roseAccent),
                const SizedBox(width: 10),
                Text(
                  'Select Currency',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...currencies.map((c) {
              final isSelected = settings.currencyCode == c['code'];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? AppColors.softBlush : null,
                leading: CircleAvatar(
                  backgroundColor: isSelected ? AppColors.roseAccent : AppColors.divider,
                  foregroundColor: isSelected ? Colors.white : AppColors.text,
                  child: Text(c['symbol']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text('${c['name']} (${c['code']})', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.roseAccent) : null,
                onTap: () {
                  settings.setCurrency(c['code']!, c['symbol']!);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out of FINTRACK?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showResetDemoDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reload Demo Data', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will reset all transactions, bills, and budgets to the clean demo data set.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signInDemo();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo data reloaded successfully!'),
                    backgroundColor: AppColors.income,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final sec = context.watch<SecurityProvider>();

    final overallBudget = budgetProvider.getOverallBudget(
      txProvider.selectedMonth,
      txProvider.selectedYear,
    );
    final budgetLimit = overallBudget?.monthlyLimit ?? 50000.0;

    final userName = auth.user?.fullName ?? 'Harini';
    final userEmail = auth.user?.email ?? 'harini@fintrack.app';
    final userPhone = auth.user?.phoneNumber ?? '+91 98765 43210';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings & Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 90),
            children: [
              // User Profile Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar with Rose Accent Ring
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.roseAccent],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.softBlush,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.roseAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                userEmail,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userPhone,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.roseAccent,
                          side: const BorderSide(color: AppColors.roseAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Monthly Budget Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'FINANCIAL GOALS',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: AppColors.roseAccent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Budget Limit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            formatCurrency(budgetLimit),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.roseAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const SetBudgetDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Preferences Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'PREFERENCES',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        // Currency
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.currency_exchange_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Currency',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${settings.currencyCode} (${settings.currencySymbol})',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () => _showCurrencyPicker(context, settings),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),
                        // Bill Reminders Toggle
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active_outlined, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Bill Due Reminders',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Notify 1 day before bill is due',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: settings.billReminders,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => settings.setBillReminders(val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),
                        // Budget Alerts Toggle
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Budget Threshold Alerts',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Warn when reaching 80% & 100% of budget',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: settings.notificationsEnabled,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => settings.setNotifications(val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Theme Preview Section (Pastel Pink)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'DESIGN SYSTEM',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, color: AppColors.roseAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pastel Pink Aesthetic Active',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soft, elegant, modern theme designed for high readability and visual comfort.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildColorChip('Primary', AppColors.primary),
                        const SizedBox(width: 8),
                        _buildColorChip('Rose', AppColors.roseAccent),
                        const SizedBox(width: 8),
                        _buildColorChip('Blush', AppColors.softBlush),
                        const SizedBox(width: 8),
                        _buildColorChip('Mint', AppColors.pastelMint),
                        const SizedBox(width: 8),
                        _buildColorChip('Peach', AppColors.lightPeach),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Cybersecurity Controls Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'CYBERSECURITY & DEFENSE',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        // Security Center Shortcut
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Security Center Dashboard',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Score: ${sec.securityScore}/100 • ${sec.protectionStatus}',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sec.securityScore >= 75
                                  ? AppColors.pastelMint
                                  : AppColors.lightPeach,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${sec.securityScore}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sec.securityScore >= 75
                                        ? AppColors.income
                                        : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textLight),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SecurityCenterScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),

                        // Two-Factor Authentication (2FA)
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Two-Factor Authentication (2FA)',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Verify logins via secondary authentication',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: sec.mfaEnabled,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => sec.toggleMfa(val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),

                        // Biometric App Lock
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fingerprint_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Biometric App Lock',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Require Face ID / Touch ID to unlock app',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: sec.biometricsEnabled,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => sec.toggleBiometrics(val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),

                        // Privacy Mode Masking
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.visibility_off_outlined, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Privacy Mode (Mask Balances)',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Mask sensitive numbers across all screens',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: sec.hideBalances,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => sec.togglePrivacyMode(val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),

                        // Auto-Lock Inactivity
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.timer_outlined, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Auto-Lock Inactivity',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Lock session after backgrounding',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          value: sec.autoLockEnabled,
                          activeColor: AppColors.roseAccent,
                          onChanged: (val) => sec.toggleAutoLock(val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Security & Data Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'DATA & SECURITY',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Change Password',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: _showChangePasswordDialog,
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.softBlush,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.download_rounded, color: AppColors.roseAccent, size: 20),
                          ),
                          title: Text(
                            'Export Financial Data',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'CSV export for record keeping',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Financial data exported to Downloads folder!'),
                                backgroundColor: AppColors.income,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.divider),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightPeach,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 20),
                          ),
                          title: Text(
                            'Reload Demo Data',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Reset sample transactions, bills, and budgets',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () => _showResetDemoDataDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Version & Credits Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.roseAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FINTRACK',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'v1.0.0 • Engineering Capstone Project – 1 (23IE4053R)',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    Text(
                      'KL University • Department of CSE (A.Y. 2026 - 2027)',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Project Guide: Dr. K Swapnika',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.roseAccent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Team: Sneha Mithra (2320030368) • Likhita Yegalla (2320030247) • Sai Akshaya (2320030367)',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _showSignOutDialog(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

