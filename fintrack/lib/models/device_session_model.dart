import 'package:flutter/material.dart';

/// Represents an active device session logged into the FINTRACK account.
class DeviceSessionModel {
  final String id;
  final String deviceName;
  final String deviceType; // 'Mobile', 'Tablet', 'Desktop', 'Web'
  final String ipAddress;
  final String location;
  final DateTime lastActive;
  final bool isCurrentDevice;

  const DeviceSessionModel({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.location,
    required this.lastActive,
    this.isCurrentDevice = false,
  });

  IconData get icon {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone_rounded;
      case 'tablet':
        return Icons.tablet_mac_rounded;
      case 'desktop':
      case 'laptop':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'location': location,
      'lastActive': lastActive.toIso8601String(),
      'isCurrentDevice': isCurrentDevice,
    };
  }

  factory DeviceSessionModel.fromMap(Map<String, dynamic> map) {
    return DeviceSessionModel(
      id: map['id'] as String,
      deviceName: map['deviceName'] as String,
      deviceType: map['deviceType'] as String,
      ipAddress: map['ipAddress'] as String,
      location: map['location'] as String,
      lastActive: DateTime.parse(map['lastActive'] as String),
      isCurrentDevice: map['isCurrentDevice'] as bool? ?? false,
    );
  }
}

