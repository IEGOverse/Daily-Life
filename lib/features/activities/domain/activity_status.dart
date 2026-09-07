/// Lifecycle status of an activity (PRD §6).
enum ActivityStatus {
  scheduled,
  upcoming,
  inProgress,
  completed,
  skipped;

  /// Parses a status from its persisted (drift) string representation.
  static ActivityStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return ActivityStatus.completed;
      case 'skipped':
        return ActivityStatus.skipped;
      case 'in_progress':
        return ActivityStatus.inProgress;
      case 'upcoming':
        return ActivityStatus.upcoming;
      case 'scheduled':
      default:
        return ActivityStatus.scheduled;
    }
  }

  /// Persisted string representation.
  String get storageValue {
    switch (this) {
      case ActivityStatus.completed:
        return 'completed';
      case ActivityStatus.skipped:
        return 'skipped';
      case ActivityStatus.inProgress:
        return 'in_progress';
      case ActivityStatus.upcoming:
        return 'upcoming';
      case ActivityStatus.scheduled:
        return 'scheduled';
    }
  }

  /// Short human display label.
  String get label {
    switch (this) {
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.skipped:
        return 'Skipped';
      case ActivityStatus.inProgress:
        return 'In Progress';
      case ActivityStatus.upcoming:
        return 'Upcoming';
      case ActivityStatus.scheduled:
        return 'Scheduled';
    }
  }

  /// Whether the activity is still "actionable" (not completed or skipped).
  bool get isActionable =>
      this == ActivityStatus.scheduled ||
      this == ActivityStatus.upcoming ||
      this == ActivityStatus.inProgress;
}
