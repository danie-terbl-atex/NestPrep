import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import '../model/job_details.dart';
import 'job_details_form.dart';

/// Changes what a job still with its helper says — never its photo, its
/// ticks or its status. Comes back with the new details, or null.
Future<JobDetails?> showJobEditSheet({
  required BuildContext context,
  required CleaningJob job,
  required HomeCareBoard board,
  required List<Member> helpers,
}) {
  final today = context.read<HouseholdClock>().today;
  return showNestSheet<JobDetails>(
    context: context,
    title: HomeCareCopy.editJob,
    builder: (context) => _EditBody(
      initial: JobDetails.of(job),
      board: board,
      helpers: helpers,
      today: today,
    ),
  );
}

class _EditBody extends StatefulWidget {
  const _EditBody({
    required this.initial,
    required this.board,
    required this.helpers,
    required this.today,
  });

  final JobDetails initial;
  final HomeCareBoard board;
  final List<Member> helpers;
  final CalendarDate today;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late JobDetails _details = widget.initial;
  var _hasTried = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobDetailsForm(
            details: _details,
            onChanged: (change) => setState(() => _details = change(_details)),
            rooms: widget.board.roomsByName,
            products: widget.board.productsByName,
            helpers: widget.helpers,
            problems: _hasTried ? _details.problems : const [],
            today: widget.today,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: () {
              if (!_details.isComplete) {
                setState(() => _hasTried = true);
                return;
              }
              Navigator.of(context).pop(_details);
            },
          ),
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}
