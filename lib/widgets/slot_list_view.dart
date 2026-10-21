import 'package:flutter/material.dart';
import '../state/timetable_controller.dart';
import 'slot_editor_dialog.dart';

class SlotListView extends StatefulWidget {
  final TimetableController controller;

  const SlotListView({
    super.key,
    required this.controller,
  });

  @override
  State<SlotListView> createState() => _SlotListViewState();
}

class _SlotListViewState extends State<SlotListView> {
  String _searchQuery = '';
  bool _filterOnlyClashes = false;
  int? _filterDay;

  @override
  Widget build(BuildContext context) {
    final activeSlots = widget.controller.activeSlots;
    final report = widget.controller.clashReport;

    final filtered = activeSlots.where((slot) {
      if (_filterOnlyClashes && !report.hasClash(slot.id)) {
        return false;
      }
      if (_filterDay != null && slot.day != _filterDay) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchSubject = slot.subject.toLowerCase().contains(query);
        final matchRoom = slot.room.toLowerCase().contains(query);
        final matchInstructor = slot.instructor.toLowerCase().contains(query);
        return matchSubject || matchRoom || matchInstructor;
      }
      return true;
    }).toList();

    // Sort by day, then startMinutes
    filtered.sort((a, b) {
      final dayComp = a.day.compareTo(b.day);
      if (dayComp != 0) return dayComp;
      return a.startMinutes.compareTo(b.startMinutes);
    });

    return Column(
      children: [
        // Search & Filters bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by subject, room, or instructor...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      avatar: Icon(
                        Icons.warning,
                        size: 14,
                        color: _filterOnlyClashes ? Colors.white : Colors.red,
                      ),
                      label: Text(
                        'Only Clashes (${report.clashingSlotIds.length})',
                        style: TextStyle(
                          color: _filterOnlyClashes ? Colors.white : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: _filterOnlyClashes,
                      selectedColor: Colors.red.shade700,
                      onSelected: (val) => setState(() => _filterOnlyClashes = val),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int?>(
                      value: _filterDay,
                      hint: const Text('All Days', style: TextStyle(fontSize: 13)),
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Days (Mon-Sun)')),
                        ...List.generate(7, (i) {
                          final names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                          return DropdownMenuItem(value: i + 1, child: Text(names[i]));
                        }),
                      ],
                      onChanged: (val) => setState(() => _filterDay = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No class slots match your filter.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final slot = filtered[index];
                    final hasClash = report.hasClash(slot.id);
                    final clashes = report.getClashesFor(slot.id);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: hasClash ? Colors.red.shade600 : Colors.grey.shade300,
                          width: hasClash ? 2 : 1,
                        ),
                      ),
                      color: hasClash ? Colors.red.shade50.withValues(alpha: 0.4) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(top: 3),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: hasClash ? Colors.red.shade900 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              slot.dayName,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            slot.timeRangeFormatted,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasClash)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'CLASH',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            if (slot.room.isNotEmpty || slot.instructor.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (slot.room.isNotEmpty) ...[
                                    Icon(Icons.room, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(slot.room, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                    const SizedBox(width: 14),
                                  ],
                                  if (slot.instructor.isNotEmpty) ...[
                                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(slot.instructor, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ],

                            // If clash, show details box
                            if (hasClash) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: clashes.map((c) {
                                    return Text(
                                      '⚔️ Overlaps with ${c.conflictingSlot.subject} (${c.conflictingSlot.timeRangeFormatted}) by ${c.overlapMinutes} mins [${c.overlapTimeRangeFormatted}]',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            // Action Buttons (Edit / Delete)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                  onPressed: () => widget.controller.deleteSlot(slot.id),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
