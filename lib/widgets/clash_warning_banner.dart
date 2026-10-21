import 'package:flutter/material.dart';
import '../models/clash_result.dart';
import '../models/time_slot.dart';
import '../state/timetable_controller.dart';
import 'slot_editor_dialog.dart';

class ClashWarningBanner extends StatelessWidget {
  final TimetableController controller;

  const ClashWarningBanner({
    super.key,
    required this.controller,
  });

  void _showConflictDetailsModal(BuildContext context) {
    final report = controller.clashReport;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduling Conflicts Detected',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${report.totalConflictPairs} overlapping pair(s) across ${report.clashingSlotIds.length} classes',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: report.clashPairs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pair = report.clashPairs[index];
                        return _buildConflictPairCard(context, pair);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConflictPairCard(BuildContext context, ClashPair pair) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.red.shade50.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pair.slotA.dayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '⚔️ Overlap: ${pair.overlapMinutes} mins (${pair.overlapTimeRangeFormatted})',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Slot A
            _buildSlotRow(context, pair.slotA, isFirst: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Text(
                  '⚡ CLASHES WITH ⚡',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            // Slot B
            _buildSlotRow(context, pair.slotB, isFirst: false),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotRow(BuildContext context, TimeSlot slot, {required bool isFirst}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: slot.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.subject,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${slot.timeRangeFormatted} • ${slot.room.isNotEmpty ? slot.room : "No room"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 32),
            ),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => SlotEditorDialog(
                  controller: controller,
                  slotToEdit: slot,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = controller.clashReport;
    if (report.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(bottom: BorderSide(color: Colors.green.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zero scheduling conflicts detected. All ${controller.activeSlots.length} classes are clash-free!',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade300, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${report.totalConflictPairs} SCHEDULING CONFLICT(S) DETECTED',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${report.clashingSlotIds.length} classes have overlapping time slots. Tap to review.',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
            ),
            icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
            label: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _showConflictDetailsModal(context),
          ),
        ],
      ),
    );
  }
}
