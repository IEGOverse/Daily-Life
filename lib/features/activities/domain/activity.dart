import '../../../core/database/database.dart' as db;
import 'activity_status.dart';

/// Domain model for the central [Activity] entity (PRD §6, ARCHITECTURE §6).
///
/// An activity is the bridge between the schedule (via [scheduleId]) and
/// specialized modules (via [referenceId]/[referenceType] — workout, study,
/// finance, nutrition, habits).
class Activity {
  final String id;
  final String? scheduleId;
  final String title;
  final String category;

  /// Start of the activity, in the user's local time.
  final DateTime startTime;

  /// Optional end time; null means the activity is open-ended.
  final DateTime? endTime;

  final ActivityStatus status;
  final String? referenceId;
  final String? referenceType;
  final String? notes;

  const Activity({
    required this.id,
    this.scheduleId,
    required this.title,
    required this.category,
    required this.startTime,
    this.endTime,
    this.status = ActivityStatus.scheduled,
    this.referenceId,
    this.referenceType,
    this.notes,
  });

  factory Activity.fromRow(db.Activity row) {
    return Activity(
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
    if (!status.isActionable) {
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
    if (!status.isActionable) {
      return false;
    }
    return startTime.isAfter(now);
  }
}

/// Comparator that orders activities by start time (then by title as a stable
/// tie-breaker).
int compareByStart(Activity a, Activity b) {
  final byStart = a.startTime.compareTo(b.startTime);
  if (byStart != 0) {
    return byStart;
  }
  return a.title.compareTo(b.title);
}
