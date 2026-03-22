/// User roles for the dashboard
enum UserRole {
  hospital,  // Hospital staff (doctors, nurses) - basic control
  admin,     // Admin users - full control including provisioning
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.hospital:
        return 'Hospital User';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.hospital:
        return 'Monitor and control AHU units';
      case UserRole.admin:
        return 'Full system access and configuration';
    }
  }
}


