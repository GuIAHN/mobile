enum AccountStatus {
  active,
  pendingDeletion,
  inactive,
  deleted,
  unknown;

  static AccountStatus fromString(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'ACTIVE' => AccountStatus.active,
      'PENDING_DELETION' => AccountStatus.pendingDeletion,
      'INACTIVE' => AccountStatus.inactive,
      'DELETED' => AccountStatus.deleted,
      _ => AccountStatus.unknown,
    };
  }
}
