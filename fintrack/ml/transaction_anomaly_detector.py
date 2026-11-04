#!/usr/bin/env python3
"""
FINTRACK: A Cybersecurity-Driven Financial Management Framework
Machine Learning Transaction Anomaly & Fraud Detection Pipeline

Module: ml/transaction_anomaly_detector.py
Academic Project: KL University – Department of Computer Science and Engineering
Course: Engineering Capstone Project – 1 (23IE4053R / 23IE4053A)
Guide: Dr. K Swapnika
Team:
  - Sneha Mithra (2320030368)
  - Likhita Yegalla (2320030247)
  - Sai Akshaya (2320030367)

Description:
  This script implements an unsupervised Anomaly Detection pipeline based on
  Isolation Forest and statistical profiling for financial transaction streams.
  It generates synthetic normal and adversarial transaction vectors, trains
  an Isolation Forest ensemble, and computes classification metrics (Precision,
  Recall, F1-Score, ROC-AUC).
"""

import sys
import os
import math
import random
import json
import csv
from datetime import datetime, timedelta

# Check if third-party ML packages are available; provide built-in fallbacks if not
try:
    import numpy as np
    import pandas as pd
    from sklearn.ensemble import IsolationForest
    from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, f1_score
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False


# ==============================================================================
# 1. STANDALONE ISOLATION FOREST IMPLEMENTATION (Zero External Dependencies)
# ==============================================================================

class IsolationTreeNode:
    """A single decision node in an Isolation Tree."""
    def __init__(self, left=None, right=None, split_feature=None, split_value=None, size=0):
        self.left = left
        self.right = right
        self.split_feature = split_feature
        self.split_value = split_value
        self.size = size
        self.is_leaf = (left is None and right is None)


class StandaloneIsolationTree:
    """Single Isolation Tree (iTree) partitioner."""
    def __init__(self, max_depth):
        self.max_depth = max_depth
        self.root = None

    def fit(self, X, depth=0):
        n_samples = len(X)
        if depth >= self.max_depth or n_samples <= 1:
            return IsolationTreeNode(size=n_samples)

        n_features = len(X[0])
        feature_idx = random.randint(0, n_features - 1)
        feat_vals = [row[feature_idx] for row in X]
        min_v, max_v = min(feat_vals), max(feat_vals)

        if min_v == max_v:
            return IsolationTreeNode(size=n_samples)

        split_val = random.uniform(min_v, max_v)
        left_X = [row for row in X if row[feature_idx] < split_val]
        right_X = [row for row in X if row[feature_idx] >= split_val]

        left_node = self.fit(left_X, depth + 1)
        right_node = self.fit(right_X, depth + 1)
        return IsolationTreeNode(
            left=left_node,
            right=right_node,
            split_feature=feature_idx,
            split_value=split_val,
            size=n_samples,
        )

    def path_length(self, x, node, current_depth=0):
        if node.is_leaf:
            return current_depth + self._c(node.size)
        if x[node.split_feature] < node.split_value:
            return self.path_length(x, node.left, current_depth + 1)
        else:
            return self.path_length(x, node.right, current_depth + 1)

    @staticmethod
    def _c(n):
        """Average path length of unsuccessful search in Binary Search Tree."""
        if n <= 1:
            return 0.0
        if n == 2:
            return 1.0
        euler_mascheroni = 0.5772156649
        return 2.0 * (math.log(n - 1) + euler_mascheroni) - (2.0 * (n - 1) / n)


class StandaloneIsolationForest:
    """Ensemble of Isolation Trees with path-length anomaly scoring."""
    def __init__(self, n_estimators=100, max_samples=256, contamination=0.05, random_state=42):
        self.n_estimators = n_estimators
        self.max_samples = max_samples
        self.contamination = contamination
        self.trees = []
        random.seed(random_state)

    def fit(self, X):
        n_samples = len(X)
        subsample_size = min(self.max_samples, n_samples)
        max_depth = math.ceil(math.log2(max(subsample_size, 2)))

        self.trees = []
        for _ in range(self.n_estimators):
            subsample = random.sample(X, subsample_size)
            tree = StandaloneIsolationTree(max_depth)
            tree.root = tree.fit(subsample)
            self.trees.append(tree)

        # Compute threshold based on contamination (top contamination% scores are anomalies)
        scores = self.decision_function(X)
        sorted_scores = sorted(scores)
        cutoff_idx = int(len(sorted_scores) * (1.0 - self.contamination))
        self.threshold_ = sorted_scores[min(cutoff_idx, len(sorted_scores) - 1)]
        return self

    def decision_function(self, X):
        """Returns anomaly score: values close to 1 indicate strong anomaly."""
        subsample_size = min(self.max_samples, len(X))
        c_factor = StandaloneIsolationTree._c(subsample_size)
        if c_factor == 0:
            c_factor = 1.0

        scores = []
        for x in X:
            avg_path = sum(t.path_length(x, t.root) for t in self.trees) / len(self.trees)
            # Anomaly score formula: s(x, n) = 2^(- avg_path / c(n))
            s = math.pow(2.0, - (avg_path / c_factor))
            scores.append(s)
        return scores

    def predict(self, X):
        """Returns -1 for anomalies (fraud), 1 for normal transactions."""
        scores = self.decision_function(X)
        return [-1 if s >= self.threshold_ else 1 for s in scores]


# ==============================================================================
# 2. SYNTHETIC FINANCIAL TRANSACTION DATA GENERATION
# ==============================================================================

CATEGORIES = [
    'Food & Dining', 'Groceries', 'Shopping', 'Transportation',
    'Housing & Rent', 'Bills & Utilities', 'Health & Fitness',
    'Education', 'Entertainment', 'Subscriptions', 'Travel', 'Others'
]

CATEGORY_BASELINES = {
    'Food & Dining': (450.0, 180.0),
    'Groceries': (1800.0, 600.0),
    'Shopping': (2200.0, 950.0),
    'Transportation': (250.0, 90.0),
    'Housing & Rent': (15000.0, 2000.0),
    'Bills & Utilities': (2400.0, 700.0),
    'Health & Fitness': (1200.0, 400.0),
    'Education': (4500.0, 1200.0),
    'Entertainment': (850.0, 300.0),
    'Subscriptions': (499.0, 150.0),
    'Travel': (3500.0, 1400.0),
    'Others': (600.0, 250.0)
}

def generate_synthetic_dataset(num_records=1200, anomaly_ratio=0.05, seed=42):
    """Generates realistic synthetic financial transactions with tagged anomalies."""
    random.seed(seed)
    records = []
    base_time = datetime(2026, 10, 1, 9, 0, 0)

    num_anomalies = int(num_records * anomaly_ratio)
    num_normal = num_records - num_anomalies

    # 1. Normal Transactions
    for i in range(num_normal):
        cat = random.choice(CATEGORIES)
        mean, std = CATEGORY_BASELINES[cat]
        # Normal Gaussian distribution bounded positively
        amount = max(50.0, round(random.gauss(mean, std), 2))

        # Normal hours: 8:00 AM to 10:30 PM
        hour = random.randint(8, 22)
        minute = random.randint(0, 59)
        delta_days = random.randint(0, 29)
        tx_time = base_time + timedelta(days=delta_days, hours=hour - 9, minutes=minute)

        velocity_1h = random.randint(1, 3)
        amount_z_score = round(abs(amount - mean) / (std if std > 0 else 1.0), 2)
        is_weekend = 1 if tx_time.weekday() in (5, 6) else 0

        records.append({
            'tx_id': f'TXN_NORM_{i+1:05d}',
            'timestamp': tx_time.strftime('%Y-%m-%d %H:%M:%S'),
            'category': cat,
            'category_code': CATEGORIES.index(cat),
            'amount': amount,
            'hour': hour,
            'velocity_1h': velocity_1h,
            'amount_z_score': amount_z_score,
            'is_weekend': is_weekend,
            'is_anomaly': 0,  # Legitimate
            'threat_type': 'None'
        })

    # 2. Injected Anomalous Transactions (Adversarial Fraud Scenarios)
    fraud_scenarios = [
        ('Extreme Spike Shopping', 'Shopping', 48500.0, 3, 1, 14.5, 'Amount 20x historical mean'),
        ('Midnight Card Drain', 'Others', 35000.0, 2, 6, 8.2, 'High velocity off-hours burst'),
        ('Rapid Multi-Probing', 'Subscriptions', 120.0, 4, 12, 0.4, 'Card testing micro-velocity surge'),
        ('Abnormal Grocery Outlier', 'Groceries', 28000.0, 14, 2, 9.8, 'Grocery spike exceeding 15x avg'),
        ('Untrusted Offshore Wire', 'Others', 65000.0, 1, 1, 18.0, 'Critical high-risk wire transfer'),
        ('Late Night Travel Spurt', 'Travel', 42000.0, 3, 4, 7.6, 'Unusual travel booking at 3 AM'),
    ]

    for j in range(num_anomalies):
        scenario = fraud_scenarios[j % len(fraud_scenarios)]
        name, cat, base_amt, hour, vel, z_sc, reason = scenario
        # Jitter values slightly
        amount = round(base_amt * random.uniform(0.9, 1.25), 2)
        delta_days = random.randint(0, 29)
        tx_time = base_time + timedelta(days=delta_days, hours=hour - 9, minutes=random.randint(0, 59))

        records.append({
            'tx_id': f'TXN_FRAUD_{j+1:04d}',
            'timestamp': tx_time.strftime('%Y-%m-%d %H:%M:%S'),
            'category': cat,
            'category_code': CATEGORIES.index(cat),
            'amount': amount,
            'hour': hour,
            'velocity_1h': vel,
            'amount_z_score': round(z_sc * random.uniform(0.95, 1.1), 2),
            'is_weekend': 1 if tx_time.weekday() in (5, 6) else 0,
            'is_anomaly': 1,  # Ground Truth Anomaly
            'threat_type': reason
        })

    # Shuffle records
    random.shuffle(records)
    return records


# ==============================================================================
# 3. METRICS EVALUATION HELPERS
# ==============================================================================

def compute_metrics(y_true, y_pred, y_scores):
    """Calculates confusion matrix, precision, recall, F1, and ROC-AUC."""
    tp = sum(1 for yt, yp in zip(y_true, y_pred) if yt == 1 and yp == 1)
    fp = sum(1 for yt, yp in zip(y_true, y_pred) if yt == 0 and yp == 1)
    tn = sum(1 for yt, yp in zip(y_true, y_pred) if yt == 0 and yp == 0)
    fn = sum(1 for yt, yp in zip(y_true, y_pred) if yt == 1 and yp == 0)

    accuracy = (tp + tn) / len(y_true) if len(y_true) > 0 else 0.0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0

    # Trapezoidal ROC-AUC calculation
    paired = sorted(zip(y_scores, y_true), key=lambda x: x[0], reverse=True)
    positives = sum(y_true)
    negatives = len(y_true) - positives

    if positives > 0 and negatives > 0:
        roc_auc = 0.0
        cur_tp = 0
        cur_fp = 0
        prev_fpr = 0.0
        prev_tpr = 0.0
        for score, label in paired:
            if label == 1:
                cur_tp += 1
            else:
                cur_fp += 1
            tpr = cur_tp / positives
            fpr = cur_fp / negatives
            roc_auc += (fpr - prev_fpr) * (tpr + prev_tpr) / 2.0
            prev_fpr = fpr
            prev_tpr = tpr
    else:
        roc_auc = 1.0

    return {
        'total_samples': len(y_true),
        'true_positives': tp,
        'false_positives': fp,
        'true_negatives': tn,
        'false_negatives': fn,
        'accuracy': round(accuracy, 4),
        'precision': round(precision, 4),
        'recall': round(recall, 4),
        'specificity': round(specificity, 4),
        'f1_score': round(f1, 4),
        'roc_auc': round(roc_auc, 4),
    }


# ==============================================================================
# 4. MAIN PIPELINE EXECUTION
# ==============================================================================

def run_pipeline():
    print("=" * 76)
    print(" FINTRACK: CYBERSECURITY TRANSACTION ANOMALY DETECTION PIPELINE")
    print(" Department of Computer Science & Engineering – KL University")
    print(" Capstone Project – 1 (Academic Year 2026-2027)")
    print("=" * 76)

    output_dir = os.path.dirname(os.path.abspath(__file__))
    os.makedirs(output_dir, exist_ok=True)

    # 1. Dataset Generation
    print("\n[+] 1. Synthesizing Financial Transaction Dataset...")
    records = generate_synthetic_dataset(num_records=1200, anomaly_ratio=0.05, seed=42)
    print(f"    - Total records generated: {len(records)}")
    normal_count = sum(1 for r in records if r['is_anomaly'] == 0)
    anomaly_count = sum(1 for r in records if r['is_anomaly'] == 1)
    print(f"    - Legitimate transactions: {normal_count} ({(normal_count/len(records))*100:.1f}%)")
    print(f"    - Tagged anomaly threats:  {anomaly_count} ({(anomaly_count/len(records))*100:.1f}%)")

    # Save to CSV
    csv_path = os.path.join(output_dir, "synthetic_transactions.csv")
    with open(csv_path, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(records[0].keys()))
        writer.writeheader()
        writer.writerows(records)
    print(f"    - Saved raw dataset to: {csv_path}")

    # 2. Feature Extraction & Vectorization
    feature_keys = ['amount', 'hour', 'velocity_1h', 'amount_z_score', 'category_code', 'is_weekend']
    X = [[r[k] for k in feature_keys] for r in records]
    y_true = [r['is_anomaly'] for r in records]

    print("\n[+] 2. Training Isolation Forest Anomaly Detection Model...")
    print(f"    - Features: {', '.join(feature_keys)}")
    print(f"    - Target Contamination Rate: 0.05")

    if SKLEARN_AVAILABLE:
        print("    - Backend: scikit-learn IsolationForest")
        model = IsolationForest(
            n_estimators=120,
            contamination=0.05,
            random_state=42,
            n_jobs=-1
        )
        model.fit(X)
        raw_preds = model.predict(X)
        # sklearn outputs -1 for anomaly, 1 for inlier
        y_pred = [1 if p == -1 else 0 for p in raw_preds]
        # Invert decision function so higher means more anomalous
        raw_scores = model.decision_function(X)
        y_scores = [(-s + 1.0) / 2.0 for s in raw_scores]
    else:
        print("    - Backend: Built-in Standalone Isolation Forest (Zero-Dependency)")
        model = StandaloneIsolationForest(
            n_estimators=100,
            max_samples=256,
            contamination=0.05,
            random_state=42
        )
        model.fit(X)
        y_scores = model.decision_function(X)
        raw_preds = model.predict(X)
        y_pred = [1 if p == -1 else 0 for p in raw_preds]

    # 3. Model Evaluation
    print("\n[+] 3. Evaluating Anomaly Detection Performance...")
    metrics = compute_metrics(y_true, y_pred, y_scores)

    print("\n" + "-" * 50)
    print(" MODEL PERFORMANCE EVALUATION MATRIX")
    print("-" * 50)
    print(f"  Accuracy:     {metrics['accuracy'] * 100:.2f}%")
    print(f"  Precision:    {metrics['precision'] * 100:.2f}%")
    print(f"  Recall (TPR): {metrics['recall'] * 100:.2f}%")
    print(f"  Specificity:  {metrics['specificity'] * 100:.2f}%")
    print(f"  F1-Score:     {metrics['f1_score'] * 100:.2f}%")
    print(f"  ROC-AUC:      {metrics['roc_auc']:.4f}")
    print("-" * 50)
    print(f"  Confusion Matrix: TP={metrics['true_positives']}, FP={metrics['false_positives']}, "
          f"TN={metrics['true_negatives']}, FN={metrics['false_negatives']}")
    print("-" * 50)

    # 4. Generate Reports
    timestamp_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    report_data = {
        'project': 'FINTRACK – Cybersecurity-Driven Financial Management System',
        'institution': 'KL University, Department of CSE',
        'course': 'Engineering Capstone Project – 1 (23IE4053R/23IE4053A)',
        'guide': 'Dr. K Swapnika',
        'team_members': [
            {'name': 'Sneha Mithra', 'id': '2320030368'},
            {'name': 'Likhita Yegalla', 'id': '2320030247'},
            {'name': 'Sai Akshaya', 'id': '2320030367'}
        ],
        'execution_timestamp': timestamp_str,
        'algorithm': 'Isolation Forest (Ensemble Partitioning)',
        'features_used': feature_keys,
        'metrics': metrics,
        'parameters': {
            'n_estimators': 120 if SKLEARN_AVAILABLE else 100,
            'contamination': 0.05,
            'random_state': 42
        }
    }

    # JSON report
    json_path = os.path.join(output_dir, "anomaly_detection_report.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report_data, f, indent=2)
    print(f"\n[+] Saved Structured JSON Report: {json_path}")

    # Plain-text audit report
    txt_path = os.path.join(output_dir, "anomaly_detection_report.txt")
    with open(txt_path, "w", encoding="utf-8") as f:
        f.write("=" * 76 + "\n")
        f.write(" FINTRACK: CYBERSECURITY TRANSACTION ANOMALY DETECTION REPORT\n")
        f.write(f" Timestamp: {timestamp_str}\n")
        f.write(" Guide: Dr. K Swapnika | Department of CSE, KL University\n")
        f.write("=" * 76 + "\n\n")
        f.write("1. EXECUTIVE SUMMARY\n")
        f.write("--------------------\n")
        f.write("An unsupervised Isolation Forest algorithm was deployed to profile normal\n")
        f.write("financial spending distributions across 12 pastel categories, detecting multi-variate\n")
        f.write("adversarial vectors including extreme spike outliers, nocturnal velocity spikes,\n")
        f.write("and micro-transaction card harvesting probes.\n\n")
        f.write("2. QUANTITATIVE METRICS\n")
        f.write("-----------------------\n")
        f.write(f"  • Total Evaluation Samples: {metrics['total_samples']}\n")
        f.write(f"  • True Positives (Detected Fraud):   {metrics['true_positives']}\n")
        f.write(f"  • False Positives (False Alarms):    {metrics['false_positives']}\n")
        f.write(f"  • True Negatives (Legitimate Safe):  {metrics['true_negatives']}\n")
        f.write(f"  • False Negatives (Missed Threats):  {metrics['false_negatives']}\n\n")
        f.write(f"  • Classification Accuracy:  {metrics['accuracy'] * 100:.2f}%\n")
        f.write(f"  • Precision:                {metrics['precision'] * 100:.2f}%\n")
        f.write(f"  • Recall (Sensitivity):     {metrics['recall'] * 100:.2f}%\n")
        f.write(f"  • Specificity:              {metrics['specificity'] * 100:.2f}%\n")
        f.write(f"  • F1-Score:                 {metrics['f1_score'] * 100:.2f}%\n")
        f.write(f"  • ROC Area Under Curve:     {metrics['roc_auc']:.4f}\n\n")
        f.write("3. ALIGNMENT WITH FLUTTER APPLICATION INTEGRATION\n")
        f.write("------------------------------------------------\n")
        f.write("The learned decision boundaries and statistical Z-score velocity heuristics\n")
        f.write("are natively replicated inside lib/services/anomaly_detection_service.dart\n")
        f.write("for real-time, low-latency, client-side threat interception on iOS/Android.\n")
        f.write("=" * 76 + "\n")
    print(f"[+] Saved Text Audit Report: {txt_path}")
    print("\n[✓] Machine Learning Pipeline Execution Completed Successfully!\n")

if __name__ == "__main__":
    run_pipeline()
