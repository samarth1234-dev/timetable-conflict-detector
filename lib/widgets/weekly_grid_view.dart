import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/time_slot.dart';
import '../models/clash_result.dart';
import '../state/timetable_controller.dart';
import 'slot_editor_dialog.dart';

class PositionedSlot {
  final TimeSlot slot;
  final int columnIndex;
  final int totalColumns;
  final bool hasClash;
  final List<ClashDetail> clashes;

  PositionedSlot({
    required this.slot,
    required this.columnIndex,
    required this.totalColumns,
    required this.hasClash,
    required this.clashes,
  });
}

class WeeklyGridView extends StatefulWidget {
  final TimetableController controller;

  const WeeklyGridView({
    super.key,
    required this.controller,
  });

  @override
  State<WeeklyGridView> createState() => _WeeklyGridViewState();
}

class _WeeklyGridViewState extends State<WeeklyGridView> {
  bool _showWeekends = true;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  static const int gridStartHour = 8;  // 08:00 AM
  static const int gridEndHour = 20;   // 08:00 PM
  static const double hourRowHeight = 65.0;
  static const double timeColumnWidth = 65.0;
  static const double minDayColumnWidth = 140.0;

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  int get totalDays => _showWeekends ? 7 : 5;

  List<PositionedSlot> _layoutSlotsForDay(int day, List<TimeSlot> activeSlots) {
    final daySlots = activeSlots.where((s) => s.day == day).toList();
    if (daySlots.isEmpty) return [];

    // Sort primarily by startMinutes ascending, then endMinutes descending
    daySlots.sort((a, b) {
      final startComp = a.startMinutes.compareTo(b.startMinutes);
      if (startComp != 0) return startComp;
      return b.endMinutes.compareTo(a.endMinutes);
    });

    // Partition daySlots into overlapping clusters (connected components)
    final List<List<TimeSlot>> clusters = [];
    List<TimeSlot> currentCluster = [];
    int clusterMaxEnd = -1;

    for (final slot in daySlots) {
      if (currentCluster.isEmpty) {
        currentCluster.add(slot);
        clusterMaxEnd = slot.endMinutes;
      } else {
        if (slot.startMinutes < clusterMaxEnd) {
          // Overlaps with current cluster
          currentCluster.add(slot);
          clusterMaxEnd = math.max(clusterMaxEnd, slot.endMinutes);
        } else {
          // Closes current cluster, start new
          clusters.add(currentCluster);
          currentCluster = [slot];
          clusterMaxEnd = slot.endMinutes;
        }
      }
    }
    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    final List<PositionedSlot> result = [];
    final report = widget.controller.clashReport;

    for (final cluster in clusters) {
      // Greedily assign columns within the cluster
      final List<int> columnEndTimes = [];
      final Map<String, int> slotToColumn = {};

      for (final slot in cluster) {
        int assignedCol = -1;
        for (int c = 0; c < columnEndTimes.length; c++) {
          if (columnEndTimes[c] <= slot.startMinutes) {
            assignedCol = c;
            columnEndTimes[c] = slot.endMinutes;
            break;
          }
        }
        if (assignedCol == -1) {
          assignedCol = columnEndTimes.length;
          columnEndTimes.add(slot.endMinutes);
        }
        slotToColumn[slot.id] = assignedCol;
      }

      final totalCols = math.max(1, columnEndTimes.length);
      for (final slot in cluster) {
        final hasClash = report.hasClash(slot.id);
        final clashes = report.getClashesFor(slot.id);
        result.add(
          PositionedSlot(
            slot: slot,
            columnIndex: slotToColumn[slot.id] ?? 0,
            totalColumns: totalCols,
            hasClash: hasClash,
            clashes: clashes,
          ),
        );
      }
    }

    return result;
  }

  void _showSlotDetailsModal(BuildContext context, PositionedSlot pSlot) {
    final slot = pSlot.slot;
    final hasClash = pSlot.hasClash;
    final clashes = pSlot.clashes;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: slot.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      slot.subject,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (hasClash)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'CLASH DETECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailItem(Icons.calendar_today, 'Day', slot.dayName),
              _buildDetailItem(Icons.access_time, 'Time', '${slot.timeRangeFormatted} (${slot.durationMinutes} mins)'),
              if (slot.room.isNotEmpty)
                _buildDetailItem(Icons.room, 'Room', slot.room),
              if (slot.instructor.isNotEmpty)
                _buildDetailItem(Icons.person, 'Instructor', slot.instructor),

              if (hasClash) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduling Conflict Summary:',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...clashes.map(
                        (c) => Text(
                          '• Clashes with "${c.conflictingSlot.subject}" (${c.conflictingSlot.timeRangeFormatted}) for ${c.overlapMinutes} mins [${c.overlapTimeRangeFormatted}].',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.controller.deleteSlot(slot.id);
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Slot'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => SlotEditorDialog(
                          controller: widget.controller,
                          slotToEdit: slot,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSlots = widget.controller.activeSlots;
    final totalHours = gridEndHour - gridStartHour;
    final totalGridHeight = totalHours * hourRowHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - timeColumnWidth;
        final dayColumnWidth = math.max(
          minDayColumnWidth,
          availableWidth / totalDays,
        );
        final totalGridWidth = timeColumnWidth + (dayColumnWidth * totalDays);

        return Column(
          children: [
            // Toolbar (Toggle 5/7 days, Add button, Clash legend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  // Legend
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Standard Slot', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 12),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Clashing Slot ⚠️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const Spacer(),
                  // Days toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Mon-Fri')),
                      ButtonSegment(value: true, label: Text('Mon-Sun')),
                    ],
                    selected: {_showWeekends},
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (set) {
                      setState(() => _showWeekends = set.first);
                    },
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Slot'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => SlotEditorDialog(
                          controller: widget.controller,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Grid
            Expanded(
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalGridWidth,
                    child: Column(
                      children: [
                        // Day Headers
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: timeColumnWidth,
                                child: const Center(
                                  child: Text(
                                    'TIME',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(totalDays, (index) {
                                final dayNum = index + 1;
                                final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final daySlots = activeSlots.where((s) => s.day == dayNum).toList();
                                final dayClashes = daySlots.where((s) => widget.controller.clashReport.hasClash(s.id)).length;

                                return Container(
                                  width: dayColumnWidth,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        names[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (dayClashes > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '⚠️ $dayClashes clashes',
                                            style: TextStyle(
                                              color: Colors.red.shade900,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          '${daySlots.length} classes',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Grid Body (Hours + Slot cards)
                        Expanded(
                          child: Scrollbar(
                            controller: _verticalScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _verticalScrollController,
                              child: SizedBox(
                                height: totalGridHeight,
                                width: totalGridWidth,
                                child: Stack(
                                  children: [
                                    // Background Hour Lines and Time labels
                                    ...List.generate(totalHours, (hIndex) {
                                      final hour = gridStartHour + hIndex;
                                      final top = hIndex * hourRowHeight;
                                      final timeString = TimeSlot.minutesTo12HourString(hour * 60);

                                      return Positioned(
                                        top: top,
                                        left: 0,
                                        right: 0,
                                        height: hourRowHeight,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: timeColumnWidth,
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Text(
                                                  timeString,
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: Colors.grey.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    // Vertical Day Divider Lines
                                    ...List.generate(totalDays + 1, (dIndex) {
                                      final left = timeColumnWidth + (dIndex * dayColumnWidth);
                                      return Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: left,
                                        child: Container(
                                          width: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                      );
                                    }),

                                    // Render Time Slots for each Day
                                    ...List.generate(totalDays, (dIndex) {
                                      final dayNum = dIndex + 1;
                                      final positionedSlots = _layoutSlotsForDay(dayNum, activeSlots);
                                      final dayLeft = timeColumnWidth + (dIndex * dayColumnWidth);

                                      return Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: dayLeft,
                                        width: dayColumnWidth,
                                        child: Stack(
                                          children: positionedSlots.map((pSlot) {
                                            return _buildRenderedSlotCard(pSlot, dayColumnWidth);
                                          }).toList(),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRenderedSlotCard(PositionedSlot pSlot, double dayColumnWidth) {
    final slot = pSlot.slot;
    final hasClash = pSlot.hasClash;
    final totalCols = pSlot.totalColumns;
    final colIndex = pSlot.columnIndex;

    // Calculate Y coordinates
    final startMinutesClamped = math.max(gridStartHour * 60, slot.startMinutes);
    final endMinutesClamped = math.min(gridEndHour * 60, slot.endMinutes);
    final top = (startMinutesClamped - (gridStartHour * 60)) * (hourRowHeight / 60.0);
    final duration = math.max(20, endMinutesClamped - startMinutesClamped);
    final height = duration * (hourRowHeight / 60.0);

    // Calculate X coordinates (side-by-side splitting if overlapping)
    final colWidth = (dayColumnWidth - 6) / totalCols;
    final left = 3.0 + (colIndex * colWidth);

    return Positioned(
      top: top + 2,
      left: left,
      width: colWidth - 2,
      height: height - 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSlotDetailsModal(context, pSlot),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              // If clashing: red-accented background with bold red clash border
              color: hasClash
                  ? Colors.red.shade50
                  : slot.color.withValues(alpha: 0.15),
              border: Border.all(
                color: hasClash ? Colors.red.shade700 : slot.color,
                width: hasClash ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                if (hasClash)
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: totalCols > 1 ? 11 : 12,
                              color: hasClash ? Colors.red.shade900 : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Time Range
                    Text(
                      slot.militaryTimeRange,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasClash ? Colors.red.shade800 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Room & Instructor (if space permits)
                    if (height > 45 && (slot.room.isNotEmpty || slot.instructor.isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [slot.room, slot.instructor].where((s) => s.isNotEmpty).join(' • '),
                        style: TextStyle(
                          fontSize: 9,
                          color: hasClash ? Colors.red.shade700 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),

                // Prominent Visual Flag Badge for Clashing Slots
                if (hasClash)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 9),
                          SizedBox(width: 2),
                          Text(
                            'CLASH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
