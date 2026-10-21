import 'package:flutter/material.dart';
import '../models/time_slot.dart';
import '../models/clash_result.dart';
import '../state/timetable_controller.dart';

class SlotEditorDialog extends StatefulWidget {
  final TimetableController controller;
  final TimeSlot? slotToEdit;
  final int? initialDay;
  final int? initialStartMinutes;

  const SlotEditorDialog({
    super.key,
    required this.controller,
    this.slotToEdit,
    this.initialDay,
    this.initialStartMinutes,
  });

  @override
  State<SlotEditorDialog> createState() => _SlotEditorDialogState();
}

class _SlotEditorDialogState extends State<SlotEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late TextEditingController _instructorController;

  late int _selectedDay;
  late int _startMinutes;
  late int _endMinutes;
  late int _selectedColorValue;

  final List<int> _colorPalette = const [
    0xFF1E88E5, // Blue
    0xFFFB8C00, // Orange
    0xFF43A047, // Green
    0xFF8E24AA, // Purple
    0xFFE53935, // Red
    0xFF00ACC1, // Cyan
    0xFF5E35B1, // Deep Purple
    0xFFD81B60, // Pink
    0xFF3949AB, // Indigo
    0xFF00897B, // Teal
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.slotToEdit;

    _subjectController = TextEditingController(text: edit?.subject ?? '');
    _roomController = TextEditingController(text: edit?.room ?? '');
    _instructorController = TextEditingController(text: edit?.instructor ?? '');

    _selectedDay = edit?.day ?? widget.initialDay ?? 1;
    _startMinutes = edit?.startMinutes ?? widget.initialStartMinutes ?? (9 * 60); // 09:00 AM
    _endMinutes = edit?.endMinutes ?? (_startMinutes + 90); // 90 min default
    _selectedColorValue = edit?.colorValue ?? _colorPalette.first;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  TimeSlot _buildCandidate() {
    return TimeSlot(
      id: widget.slotToEdit?.id ?? 'preview-candidate',
      subject: _subjectController.text.trim().isEmpty
          ? 'New Slot'
          : _subjectController.text.trim(),
      day: _selectedDay,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      room: _roomController.text.trim(),
      instructor: _instructorController.text.trim(),
      colorValue: _selectedColorValue,
      updatedAt: DateTime.now(),
      version: widget.slotToEdit?.version ?? 1,
    );
  }

  List<ClashDetail> _getLiveClashes() {
    if (_startMinutes >= _endMinutes) return [];
    final candidate = _buildCandidate();
    return widget.controller.previewClashes(
      candidate,
      excludeSlotId: widget.slotToEdit?.id,
    );
  }

  Future<void> _pickStartTime() async {
    final initial = TimeOfDay(
      hour: _startMinutes ~/ 60,
      minute: _startMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final newStart = picked.hour * 60 + picked.minute;
      setState(() {
        final duration = _endMinutes - _startMinutes;
        _startMinutes = newStart;
        if (_endMinutes <= _startMinutes) {
          _endMinutes = _startMinutes + (duration > 0 ? duration : 60);
          if (_endMinutes > 1439) _endMinutes = 1439;
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initial = TimeOfDay(
      hour: _endMinutes ~/ 60,
      minute: _endMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      if (!mounted) return;
      final newEnd = picked.hour * 60 + picked.minute;
      if (newEnd <= _startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _endMinutes = newEnd;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startMinutes >= _endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start time must be strictly before end time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.slotToEdit == null) {
      widget.controller.addSlot(
        subject: _subjectController.text.trim(),
        day: _selectedDay,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        room: _roomController.text.trim(),
        instructor: _instructorController.text.trim(),
        colorValue: _selectedColorValue,
      );
    } else {
      widget.controller.updateSlot(
        widget.slotToEdit!.copyWith(
          subject: _subjectController.text.trim(),
          day: _selectedDay,
          startMinutes: _startMinutes,
          endMinutes: _endMinutes,
          room: _roomController.text.trim(),
          instructor: _instructorController.text.trim(),
          colorValue: _selectedColorValue,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.slotToEdit != null;
    final liveClashes = _getLiveClashes();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(_selectedColorValue).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_calendar : Icons.add_alarm,
                          color: Color(_selectedColorValue),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Class Slot' : 'Add New Class Slot',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Live clash detection evaluates schedule collisions in real-time.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

                  // Subject Name
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name *',
                      hintText: 'e.g. Advanced Operating Systems',
                      prefixIcon: Icon(Icons.book_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Subject name is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Day of Week
                  const Text(
                    'Day of Week',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final isSelected = _selectedDay == dayNum;
                      return ChoiceChip(
                        label: Text(names[i]),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedDay = dayNum);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Time Selectors
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              TimeSlot.minutesTo12HourString(_startMinutes),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              prefixIcon: Icon(Icons.schedule),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              TimeSlot.minutesTo12HourString(_endMinutes),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Duration: ${_endMinutes - _startMinutes} minutes (${TimeSlot.minutesToTimeString(_startMinutes)} - ${TimeSlot.minutesToTimeString(_endMinutes)})',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Room & Instructor
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                            labelText: 'Room / Hall',
                            hintText: 'e.g. Lab CS-202',
                            prefixIcon: Icon(Icons.room_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _instructorController,
                          decoration: const InputDecoration(
                            labelText: 'Instructor',
                            hintText: 'e.g. Dr. Knuth',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Color Picker
                  const Text(
                    'Color Accent',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colorPalette.map((cVal) {
                      final isSelected = _selectedColorValue == cVal;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorValue = cVal),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(cVal),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // LIVE CLASH DETECTION WARNING CONTAINER
                  // ==========================================
                  if (liveClashes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade400, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'LIVE CLASH DETECTED (${liveClashes.length} Overlap)',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This time slot conflicts with existing timetable entries. Conflicting entries are visually flagged, not silently allowed:',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          ...liveClashes.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                                        children: [
                                          TextSpan(
                                            text: c.conflictingSlot.subject,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: ' (${c.conflictingSlot.timeRangeFormatted}) — overlaps by ',
                                          ),
                                          TextSpan(
                                            text: '${c.overlapMinutes} mins [${c.overlapTimeRangeFormatted}]',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: liveClashes.isNotEmpty
                              ? Colors.red.shade700
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: Icon(liveClashes.isNotEmpty ? Icons.warning : Icons.save),
                        label: Text(
                          liveClashes.isNotEmpty
                              ? (isEditing ? 'Save with Flagged Clash' : 'Add with Flagged Clash')
                              : (isEditing ? 'Save Changes' : 'Add Class Slot'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
