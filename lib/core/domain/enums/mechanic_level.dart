/// Professional credential assigned by an administrator, independent of reviews.
enum MechanicLevel {
  certified(1, 'Certificado'),
  technician(2, 'TSU'),
  engineer(3, 'Ingeniero');

  const MechanicLevel(this.value, this.label);
  final int value;
  final String label;

  static MechanicLevel? fromApi(Object? value) {
    final number = int.tryParse(value?.toString() ?? '');
    for (final level in values) {
      if (level.value == number) return level;
    }
    return null;
  }
}
