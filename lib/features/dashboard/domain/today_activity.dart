import '../../../core/database/database.dart' as db;

/// Lifecycle + display status of an activity.
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
}

/// A planable activity for the Today dashboard and timeline.
class TodayActivity {
  final String id;
  final String? scheduleId;
  final String title;
  final String category;
  final DateTime startTime;
  final DateTime? endTime;
  final ActivityStatus status;
  final String? referenceId;
  final String? referenceType;
  final String? notes;

  const TodayActivity({
    required this.id,
    this.scheduleId,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.status = ActivityStatus.scheduled,
    this.referenceId,
    this.referenceType,
    this.notes,
  });

  factory TodayActivity.fromDrift(db.Activity row) {
    return TodayActivity(
      id: row.id,
      scheduleId: row.scheduleId,
      title: row.title,
      category: row.category,
      startTime: row.startTime,
      endTime: row.endTime,
      status: ActivityStatus.fromString(row.status),
      referenceId: row.referenceId,
      referenceType: row.referenceType,
      notes: row.notes,
    );
  }

  /// Whether this activity is happening right now at [now].
  bool isCurrentAt(DateTime now) {
    if (status == ActivityStatus.skipped ||
        status == ActivityStatus.completed) {
      return false;
    }
    if (now.isBefore(startTime)) {
      return false;
    }
    final end = endTime;
    return end == null || now.isBefore(end);
  }

  /// Whether this activity is scheduled to begin strictly after [now].
  bool isUpcomingAfter(DateTime now) {
    if (status == ActivityStatus.skipped ||
        status == ActivityStatus.completed) {
      return false;
    }
    return startTime.isAfter(now);
  }
}

/// Comparator that orders activities by start time (then by title as a stable
/// tie-breaker).
int compareByStart(TodayActivity a, TodayActivity b) {
  final byStart = a.startTime.compareTo(b.startTime);
  if (byStart != 0) {
    return byStart;
  }
  return a.title.compareTo(b.title);
}
