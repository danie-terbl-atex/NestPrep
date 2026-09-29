import '../../../shared/time/calendar_date.dart';
import 'pickup_collector.dart';

/// What the person sheet collected: an adult who may collect, as typed. The
/// controller tidies it before anything is written (`FE-10`).
typedef PickupPersonDraft = ({
  String name,
  String relationship,
  String? idNote,
  String? phone,
  Set<String> childIds,
});

/// One child's usual collection on one weekday.
typedef SchoolRunDraft = ({
  String childId,
  int weekday,
  PickupCollector collector,
  int? atMinute,
  String? place,
});

/// A change for one child on one date. [collector] may be `NobodyCollects`.
typedef PickupChangeDraft = ({
  String childId,
  CalendarDate date,
  PickupCollector collector,
  int? atMinute,
  String? note,
});
