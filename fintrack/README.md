# FINTRACK — Personal Finance Management & Expense Tracking System

<div align="center">
  <h3>Full-Stack Personal Finance & Expense Tracking Application</h3>
  <p>Built with Flutter, Dart, Material Design 3, Firebase Authentication & Cloud Firestore</p>
</div>

---

## 📌 1. Project Overview

**FINTRACK** is a modern, fintech-inspired personal finance management application designed to give users real-time control and visibility over their personal finances through an intuitive, single-page dashboard.

### Core Value Proposition
- **Unified Single-Page Dashboard**: Immediate access to monthly overview, category spending, recent transactions, interactive calendar, bill reminders, and analytics without disjointed navigation.
- **Dynamic Real-Time Calculations**: All balances, totals, remaining budgets, and percentages update dynamically from transaction data.
- **Interactive Calendar & Bill Management**: Full calendar visualization of daily transactions with proactive bill due-date tracking and one-click payment processing.
- **Intelligent Budget Management**: Real-time spending progress with 80% threshold alerts and over-budget warnings.
- **Visual Analytics**: Interactive bar charts, donut charts, weekly spending trend curves, and key KPI metrics powered by `fl_chart`.
- **Hybrid Persistence & Demo Mode**: Fully integrated with Firebase/Cloud Firestore for production, with an instant built-in local Demo Mode for project demonstrations without requiring Firebase credentials.

---

## 🎨 2. Fintech Design System

FINTRACK uses a modern lavender, deep purple, and fintech semantic color palette:

| Element | Hex Code | Color Preview / Purpose |
| :--- | :--- | :--- |
| **Primary** | `#7954C8` | Deep Purple — Brand & Primary Buttons |
| **Secondary** | `#B9A4ED` | Soft Lavender — Accents & Borders |
| **Background** | `#F8F7FC` | Off-White Lavender — App Canvas |
| **Cards / Surface** | `#FFFFFF` | Pure White — Rounded 24px Elevation Cards |
| **Text Primary** | `#252238` | Deep Midnight Slate — High Contrast Readability |
| **Text Light** | `#6E6B7B` | Muted Purple Grey — Secondary Info |
| **Income** | `#27AE75` | Emerald Green — Cash Inflows |
| **Expense** | `#E35D6A` | Coral Crimson — Cash Outflows |
| **Accent / Pill** | `#E9E1FA` | Light Lavender Tint — Chips & Badges |

---

## 🏗️ 3. Architecture & Directory Structure

FINTRACK follows a clean, modular Flutter architecture separating Models, Services, State Providers, Screens, and Reusable Widgets.

```
fintrack/
├── assets/
│   └── images/
├── lib/
│   ├── main.dart                       # Entry point, MultiProvider setup, AuthWrapper & Routes
│   ├── models/
│   │   ├── user_model.dart             # User profile model & serialization
│   │   ├── transaction_model.dart      # Transaction entity with TransactionType enum
│   │   ├── bill_model.dart             # Bill reminder entity with Recurrence & Status
│   │   ├── budget_model.dart           # Monthly spending limits & helper logic
│   │   └── category_model.dart         # 12 Expense categories with icons and colors
│   ├── services/
│   │   ├── auth_service.dart           # Firebase Auth + Mock Demo Auth
│   │   ├── database_service.dart       # Cloud Firestore CRUD + In-Memory Reactive Demo DB
│   │   ├── demo_data_service.dart      # Realistic seed data relative to current date
│   │   └── notification_service.dart   # Flutter Local Notifications for bill reminders
│   ├── providers/
│   │   ├── auth_provider.dart          # Authentication state management
│   │   ├── transaction_provider.dart   # Reactive transaction filtering, calculations & CRUD
│   │   ├── bill_provider.dart          # Bill management, status updates & auto-payment
│   │   ├── budget_provider.dart        # Budget tracking, progress & threshold alerts
│   │   └── settings_provider.dart      # Theme, currency (₹), notification preferences
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart       # Email/password login + 1-click Demo mode
│   │   │   ├── register_screen.dart    # Registration with validation
│   │   │   └── forgot_password_screen.dart # Password reset flow
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart   # Single-page dashboard coordinating all sections
│   │   └── profile/
│   │       └── profile_screen.dart     # User profile, currency, dark mode, logout
│   ├── widgets/
│   │   ├── header_section.dart         # Greeting, brand, notification bell & avatar
│   │   ├── monthly_overview_card.dart  # Balance, Income, Expense, Month selector & % utilized
│   │   ├── expense_categories_section.dart # Interactive Donut Chart & category filter chips
│   │   ├── transaction_list_tile.dart  # Reusable transaction tile with category icon & amount
│   │   ├── transaction_detail_sheet.dart # Bottom sheet with full details, edit & delete
│   │   ├── add_transaction_dialog.dart # Bottom sheet form for adding/editing transactions
│   │   ├── recent_transactions_section.dart # Search bar, type filter, sort & View All
│   │   ├── calendar_section.dart       # TableCalendar with colored day dots & detail panel
│   │   ├── upcoming_bills_section.dart # Bills list, overdue warnings & one-click Pay
│   │   ├── add_bill_dialog.dart        # Bottom sheet for bill scheduling & recurrence
│   │   ├── budget_section.dart         # Overall & category budget progress bars & alerts
│   │   ├── set_budget_dialog.dart      # Dialog to configure monthly limits
│   │   └── analytics_section.dart      # Income vs Expense BarChart, Weekly LineChart & KPIs
│   └── utils/
│       ├── constants.dart              # AppColors, AppTextStyles, 12 Categories, Payment methods
│       ├── helpers.dart                # Indian numbering currency formatting, date helpers
│       └── theme.dart                  # Material Design 3 light & dark themes
├── firestore.rules                     # Production Firestore security rules
├── pubspec.yaml                        # Dependencies and configuration
└── test/
    └── financial_calculations_test.dart# Unit tests for balances, budgets & helpers
```

---

## 📊 4. Main Application Dashboard Sections

The dashboard is structured in the exact required order:

1. **Header Section**
   - FINTRACK logo & title
   - Dynamic greeting: `Good Morning / Afternoon / Evening, [Name]`
   - Notification bell with unread badge counter for pending/overdue bills
   - Profile avatar with direct navigation to Settings
   - Current Month & Year indicator

2. **Monthly Financial Overview**
   - Total Balance = `Total Income - Total Expenses`
   - Monthly Income (Green) & Monthly Expenses (Red)
   - Remaining Budget card
   - Budget utilization progress bar with dynamic color transitions
   - Month navigation controls (Previous / Next / Month Picker)
   - Month-over-month percentage change comparison

3. **Expense Categories**
   - Interactive Donut Chart (`PieChart` from `fl_chart`)
   - 12 predefined categories:
     1. Food & Dining
     2. Groceries
     3. Transportation
     4. Shopping
     5. Housing & Rent
     6. Bills & Utilities
     7. Health & Fitness
     8. Education
     9. Entertainment
     10. Travel
     11. Subscriptions
     12. Others
   - Category spending totals & percentage of total expenses
   - Tapping any category filters the transactions list dynamically

4. **Daily Transactions**
   - Real-time search by title and description
   - Type filter: `All`, `Income`, `Expense`
   - Sort by Date or Amount (ascending / descending)
   - Reusable `TransactionListTile` with category icon, payment method, formatted date
   - Modal bottom sheet detail view
   - Add, Edit, Delete operations with confirmation dialogs
   - "View All" toggle

5. **Financial Calendar & Bill Management**
   - `TableCalendar` with custom day markers:
     - 🟢 Green dot for Income transactions
     - 🔴 Red dot for Expense transactions
     - 🔵 Blue dot for Bills due
   - Day selection panel displaying total day income, expenses, transactions on that date, and bills due
   - Quick "Add on Date" action
   - Dedicated Upcoming Bills section:
     - Overdue bills warning banner
     - Status badges: `Upcoming` (Blue), `Pending` (Orange), `Paid` (Green), `Overdue` (Red)
     - Recurrence: `One-time`, `Weekly`, `Monthly`, `Yearly`
     - **One-Click Pay**: Marking a bill as paid creates the corresponding expense transaction automatically and prevents duplicate entries

6. **Budget Management**
   - Overall monthly spending budget progress
   - Individual category budgets with limit tracking
   - Progress bars with color thresholds:
     - 🟢 Green: < 60%
     - 🟡 Orange: 60% - 80%
     - 🟠 Warning: ≥ 80% (Warning alert displayed)
     - 🔴 Red: > 100% (Over-budget alert displayed)
   - Set/edit budget modal dialog

7. **Financial Analytics**
   - Income vs Expenses Bar Chart (`BarChart`) comparing current and previous months
   - Weekly Spending Trend Line Chart (`LineChart`) with smooth cubic bezier curve and gradient fill
   - Net Monthly Savings card
   - Highest Spending Category badge
   - Total Monthly Transactions count
   - Savings Rate percentage
   - Time period selector: `Weekly`, `Monthly`, `Yearly`

8. **Profile & Settings**
   - Profile photo with initial avatar
   - Inline profile editor (Full Name, Phone Number)
   - Password update dialog
   - Currency selector (Default: `₹ INR`, `\$ USD`, `€ EUR`, `£ GBP`)
   - Dark Mode / Light Mode toggle
   - Notifications and Bill Reminders toggles
   - Secure Logout with state clearing

---

## 🗄️ 5. Cloud Firestore Database Structure

```
users/
  └── {userId}/
        ├── profile: { uid, fullName, email, phoneNumber, currencySymbol, createdAt }
        ├── transactions/
        │     └── {transactionId}: { title, amount, type, category, date, paymentMethod, description, createdAt }
        ├── bills/
        │     └── {billId}: { name, amount, category, dueDate, recurrence, status, linkedTransactionId, description, createdAt }
        ├── budgets/
        │     └── {budgetId}: { category, monthlyLimit, month, year, createdAt }
        └── settings/
              └── preferences: { currency, currencySymbol, theme, notifications, billReminders, reminderDaysBefore }
```

### Security Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{allSubcollections=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## 🚀 6. How to Run the Application

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Android Studio / Xcode / VS Code
- Dart SDK (>=3.0.0 <4.0.0)

### Step 1: Clone or navigate to the directory
```bash
cd fintrack
```

### Step 2: Install dependencies
```bash
flutter pub get
```

### Step 3: Run the application
```bash
flutter run
```

### Step 4: Demo Mode (Instant Demonstration)
On the Login screen, click **"Continue as Demo"** to immediately explore FINTRACK with pre-populated, realistic sample financial data (Salary, Rent, Groceries, Electricity, Netflix, Dining, etc.) and complete real-time interactivity without requiring Firebase configuration.

