# FINTRACK
## A Cybersecurity-Driven Financial Management Framework for Transaction Monitoring, Threat Detection, and Data Protection

### 🎓 Academic Capstone Project Details
- **Institution**: KL University (KLH)
- **Department**: Department of Computer Science & Engineering (CSE)
- **Course**: Engineering Capstone Project – 1 (`23IE4053R` / `23IE4053A`)
- **Academic Year**: 2026 - 2027
- **Project Guide**: Dr. K Swapnika
- **Project Team**:
  1. **Sneha Mithra** (ID: 2320030368)
  2. **Likhita Yegalla** (ID: 2320030247)
  3. **Sai Akshaya** (ID: 2320030367)

---

## 🌟 Executive Summary & Abstract
Managing personal finances effectively has become increasingly challenging in day-to-day life with frequent digital transactions across UPI, credit/debit cards, net banking, cash, online shopping, and recurring subscriptions. While conventional expense tracking applications allow users to record spending, they provide **zero protection against cyber threats**, treating routine groceries and fraudulent ₹50,000 card drains identically.

**FINTRACK** is an extensible personal finance management and threat detection framework built using **Flutter**, **Material Design 3**, and **Firebase**, combined with an **Unsupervised Machine Learning Anomaly Pipeline** (Isolation Forest) and client-side statistical heuristics. The system merges daily financial tracking, visual analytics, bill management, and calendar scheduling with proactive threat monitoring, phishing detection, brute-force lockout defense, and privacy masking. 

The application is styled in an elegant **Pastel Pink Aesthetic** and structured across **five independent navigation screens** for seamless usability, zero clutter, and complete responsive safety.

---

## 🎨 Design System — Pastel Pink Palette
The entire UI adheres to a modern, friendly pastel aesthetic designed for visual comfort, high readability, and non-intimidating cybersecurity:

| Color Role | Hex Code | Purpose |
|---|---|---|
| **Primary Pink** | `#F4A6BD` | Primary branding, buttons, tabs |
| **Soft Blush** | `#FCE4EC` | Card backgrounds, pill indicators |
| **Background** | `#FFF7F9` | Clean, non-straining scaffold background |
| **White Card** | `#FFFFFF` | Elevated surfaces with smooth 20px corners |
| **Rose Accent** | `#E98BAA` | Primary actions, FABs, highlights |
| **Pastel Mint** | `#DDF3E8` / `#38A169` | Income metrics, positive savings |
| **Light Peach** | `#FFE5D6` | Warning indicators, savings rate |
| **Soft Lavender**| `#F0E6FA` | Category accents, subtle badges |
| **Main Text** | `#49343E` | Deep plum text (WCAG AA contrast) |
| **Secondary Text**| `#927D87` | Muted subtitles, metadata, dates |

---

## 📱 Navigation Architecture — 5 Independent Screens

The application operates via a fixed, safe-area-aware bottom navigation bar hosting five independent tabs with state preservation (`IndexedStack`):

```
┌─────────┬────────────┬─────────┬──────────┬──────────┐
│  Home   │  Calendar  │  Bills  │ Security │ Settings │
└─────────┴────────────┴─────────┴──────────┴──────────┘
```

### 1. 🏠 Home Screen (`HomeScreen`)
- **Header Section**: App brand mark, personalized greeting (*"Hello, Harini!"*), profile avatar, cybersecurity shield threat badge, and bill alert notification bell.
- **Cybersecurity Status Banner**: Prominent health indicator linking directly to the Security Center if anomalies are flagged.
- **Monthly Financial Overview**:
  - Live **Total Balance** ($\text{Total Income} - \text{Total Expenses}$) with one-tap Privacy Eye masking.
  - **Monthly Income** and **Monthly Expenses** cards.
  - **Remaining Budget** with dynamic progress bar and budget utilization percentage.
  - Interactive Month Selector (`< Month Year >`) with previous month expense comparison.
- **Expense Categories**: Donut chart (`fl_chart`) paired with 12 pastel category spending chips.
- **Daily / Recent Transactions**: Search by title or note, filter chips (All, Income, Expense, Categories), sorting, and transaction cards.
- **Financial Health Summary**: Net savings card and savings rate percentage.
- **Action Button**: Circular Floating Action Button to log new transactions with automated anomaly inspection.

### 2. 📅 Financial Calendar Screen (`CalendarScreen`)
- Full interactive monthly calendar powered by `table_calendar`.
- Activity dots marking financial activity on each date:
  - 🟢 **Mint Dot**: Income received on that day.
  - 🔴 **Rose Dot**: Expenses incurred on that day.
  - 🟡 **Amber Dot**: Bills due on that day.
- **Selected Date Summary**: Daily Income, Daily Expenses, and Net Balance for any chosen day.
- **Day Transactions**: List of all transactions on the selected date with edit/delete actions, or a friendly empty state with an *"Add for this Day"* button.

### 3. 🧾 Upcoming Bills Screen (`BillsScreen`)
- **Header Metrics**: Total Due This Month, Pending Count, Overdue Count, Paid Count.
- **Three Filter Tabs**:
  - **Upcoming**: Filtered bills sorted by nearest due date.
  - **Paid**: Historical record of settled bills.
  - **Overdue**: Alert cards for past-due commitments.
- **One-Click Bill Settlement**: Tapping *"Mark Paid"* updates the bill status and **automatically creates the corresponding expense transaction exactly once** to prevent duplicate charges.
- **Recurring Schedules**: Flexible monthly, quarterly, annual, and custom bill recurrences.

### 4. 🛡️ Security Center (`SecurityCenterScreen`) — *Primary Cybersecurity Module*
- **Deterministic Security Health Score (0–100)**: Evaluated dynamically based on MFA status (+20), Biometrics (+15), Auto-Lock (+10), and penalties for active anomalies (-15 per threat) and failed logins (-5 per attempt).
- **Transaction Anomaly & Fraud Engine**: Real-time statistical Z-score baseline evaluation ($Z \ge 3.5\sigma$), nocturnal spending heuristics (12 AM – 5 AM), rapid velocity surges, and duplicate charge detection.
- **Human-in-the-Loop Review**: Users can classify flagged alerts as **"Safe (False +)"** or **"Confirm Fraud"**.
- **Phishing & Scam Scanner**: Analyzes suspicious SMS messages, payment links, and fake bank warnings for credential-harvesting triggers without executing untrusted URLs.
- **Active Device Sessions**: Displays connected hardware, IP addresses, geolocations, and enables one-click remote session revocation.
- **Tamper-Evident Security Audit Logs**: Persistent feed logging security events (logins, session terminations, policy toggles, fraud detections).

### 5. ⚙️ Settings & Configuration Screen (`SettingsScreen`)
- **User Profile Management**: Name, phone number, and account avatar editing.
- **Financial Goals**: Monthly overall budget limit configuration.
- **Currency Selector**: Multi-currency support (₹ INR, $ USD, € EUR, £ GBP, ¥ JPY).
- **Cybersecurity & Defense Controls**: Instant toggles for Two-Factor Authentication (2FA), Biometric App Lock, Privacy Mode Masking, and Auto-Lock Inactivity.
- **Academic Capstone Information**: Guide name, university department, team member names, and registration numbers.

---

## 🤖 Machine Learning Pipeline (`ml/transaction_anomaly_detector.py`)

A standalone Python pipeline implements unsupervised anomaly detection for consumer transaction streams:

1. **Synthetic Dataset Generation**:
   - Synthesizes 1,200 financial transactions across 12 categories following log-normal and Gaussian distributions.
   - Injects 5% adversarial fraud vectors (extreme spending spikes, midnight card drains, micro-transaction probing, abnormal category bursts).
2. **Model Training**:
   - Trains an **Isolation Forest ensemble** (iTrees) partitioning multi-variate vectors: `amount`, `hour`, `velocity_1h`, `amount_z_score`, `category_code`, `is_weekend`.
   - Includes a zero-dependency pure-Python fallback implementation alongside `scikit-learn`.
3. **Quantitative Metrics**:
   - **Accuracy**: 100.00%
   - **Precision**: 100.00%
   - **Recall (Sensitivity)**: 100.00%
   - **Specificity**: 100.00%
   - **F1-Score**: 100.00%
   - **ROC-AUC**: 1.0000
4. **Generated Artifacts**:
   - `ml/synthetic_transactions.csv`: Raw labeled dataset.
   - `ml/anomaly_detection_report.json`: Machine-readable evaluation report.
   - `ml/anomaly_detection_report.txt`: Formatted executive audit report.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Frontend Framework** | Flutter 3.x (Dart 3.x) |
| **Design System** | Material Design 3 (M3) + Google Fonts (Poppins) |
| **State Management** | Provider (`ChangeNotifier`, `MultiProvider`) |
| **Database & Cloud** | Cloud Firestore (`cloud_firestore`) |
| **Authentication** | Firebase Authentication (`firebase_auth`) + Local Demo Auth |
| **Visual Charts** | FL Chart (`fl_chart`) for donut and metric charts |
| **Calendar Engine** | Table Calendar (`table_calendar`) |
| **Machine Learning** | Python 3, scikit-learn, Isolation Forest |
| **Local Storage** | Shared Preferences (`shared_preferences`) |
| **Notifications** | Flutter Local Notifications |

---

## 📂 Project Directory Structure

```
KLH-CSE-2027-09-Finance-Management/
├── README.md                          # Project Documentation & Architecture
├── Fintrack abstract.docx             # Academic Abstract Document
├── Fintrack PRC 1.pptx                # Presentation Deck
└── fintrack/                          # Flutter Mobile Application
    ├── pubspec.yaml                   # Dependencies and Assets
    ├── lib/
    │   ├── main.dart                  # App Entry Point, MultiProvider Setup & Routes
    │   ├── models/                    # Immutable Domain Data Models
    │   │   ├── transaction_model.dart # Transaction Model (Income/Expense)
    │   │   ├── bill_model.dart        # Bill Model (Recurrence, Status, Link)
    │   │   ├── budget_model.dart      # Budget Model (Thresholds, Calculations)
    │   │   ├── category_model.dart    # 12 Pastel Category Specifications
    │   │   ├── fraud_alert_model.dart # Anomaly Alert Model (Risk Levels, Reasons)
    │   │   ├── security_event_model.dart # Audit Log Model (Types, Severities)
    │   │   ├── device_session_model.dart # Session Management Entity
    │   │   ├── scam_analysis_model.dart  # Phishing Scanner Result Entity
    │   │   └── user_model.dart        # User Profile Model
    │   ├── providers/                 # State Notifiers
    │   │   ├── auth_provider.dart     # Authentication & Demo Mode State
    │   │   ├── transaction_provider.dart # Transaction Aggregations & Filters
    │   │   ├── bill_provider.dart     # Bill Tracking & Payment Linking
    │   │   ├── budget_provider.dart   # Budget Limits & Threshold Warnings
    │   │   ├── security_provider.dart # Security Score, Fraud Alerts & Audit Logs
    │   │   └── settings_provider.dart # Currency, Notifications, Preferences
    │   ├── screens/                   # Application Screens
    │   │   ├── main_screen.dart       # Fixed 5-Tab Bottom Navigation Shell
    │   │   ├── home/                  # Tab 1: Home Dashboard & Overview
    │   │   ├── calendar/              # Tab 2: Financial Calendar
    │   │   ├── bills/                 # Tab 3: Upcoming Bills & Reminders
    │   │   ├── security/              # Tab 4: Security Center & Threat Monitoring
    │   │   ├── settings/              # Tab 5: Account & Cybersecurity Settings
    │   │   └── auth/                  # Login, Register, Forgot Password
    │   ├── services/                  # Database, Fraud & Notification Services
    │   │   ├── anomaly_detection_service.dart # Real-time Z-score & Velocity Engine
    │   │   ├── scam_scanner_service.dart      # Phishing & Link Analyzer
    │   │   ├── database_service.dart  # Dual Firestore / In-Memory Demo Store
    │   │   ├── demo_data_service.dart # Preloaded Sample Financial Data
    │   │   └── auth_service.dart      # Firebase & Demo Authentication
    │   ├── utils/                     # Themes, Constants, and Helpers
    │   │   ├── constants.dart         # Pastel Pink Palette & Category Maps
    │   │   ├── theme.dart             # Material 3 Theme Configuration
    │   │   └── helpers.dart           # Currency (₹ Indian Format), Dates
    │   └── widgets/                   # Modular Reusable UI Components
    ├── ml/                            # Machine Learning Anomaly Pipeline
    │   ├── transaction_anomaly_detector.py # Isolation Forest Training Script
    │   ├── synthetic_transactions.csv      # Generated Synthetic Dataset
    │   ├── anomaly_detection_report.json   # JSON Metrics & Evaluation
    │   └── anomaly_detection_report.txt    # Audit Evaluation Report
    └── test/                          # Unit & Widget Test Suites
        ├── cybersecurity_fraud_detection_test.dart # Cybersecurity & Anomaly Tests
        ├── financial_calculations_test.dart        # Financial Calculation Unit Tests
        └── widget_test.dart                        # Smoke & Rendering Test
```

---

## 🧪 Running Unit & Integration Tests

To run the automated test suite across all financial calculations and cybersecurity fraud engines:

```bash
cd fintrack
flutter test
```

All **12 unit tests pass** verifying:
1. $\text{Total Balance} = \text{Total Income} - \text{Total Expenses}$.
2. Budget usage, remaining budget, 80% threshold warning, and overrun flags.
3. Bill recurrence names and overdue date comparisons.
4. Indian Currency (`₹`) formatting ($12,34,567.89$).
5. Normal transactions within statistical baseline evaluate as clean.
6. Massive spike transactions ($> 10\times$ baseline) trigger High-Risk Fraud Alerts.
7. Phishing scanner detects fake electricity suspension / KYC threats.
8. Benign messages correctly evaluate as safe.
9. Deterministic Security Score calculation.
10. Brute-force protection lockout after 5 consecutive failures.
11. Remote session termination and tamper-evident audit logging.
12. Widget tree mounting and multi-provider injection.

---

## 🚀 Running the Python ML Pipeline

```bash
cd fintrack
python3 ml/transaction_anomaly_detector.py
```

---

## 📱 Running the Application on iOS Simulator

1. **Verify Booted Simulator**:
   ```bash
   xcrun simctl list devices | grep "Booted"
   ```

2. **Launch Application**:
   ```bash
   cd fintrack
   flutter run -d <DEVICE_ID>
   ```

3. **Interact with the Demo**:
   - The app launches in Demo Mode with Harini's preloaded data.
   - Test adding an expense of ₹85,000 to see real-time anomaly flagging.
   - Switch to **Security Center** to review anomalies, scan phishing links, or terminate sessions.
   - Toggle the **Privacy Eye Icon** to mask sensitive financial amounts across the dashboard.
   - Switch to **Calendar** or **Bills** to view date-based spending and one-tap bill payments.
