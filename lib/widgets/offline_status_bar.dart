import 'package:flutter/material.dart';
import '../state/timetable_controller.dart';

class OfflineStatusBar extends StatelessWidget {
  final TimetableController controller;

  const OfflineStatusBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = controller.isOnline;
    final isSyncing = controller.isSyncing;
    final pendingCount = controller.pendingMutationCount;

    final bgColor = isOnline
        ? (pendingCount > 0 ? Colors.amber.shade100 : Colors.blue.shade50)
        : Colors.red.shade50;
    final borderColor = isOnline
        ? (pendingCount > 0 ? Colors.amber.shade400 : Colors.blue.shade200)
        : Colors.red.shade300;
    final textColor = isOnline
        ? (pendingCount > 0 ? Colors.amber.shade900 : Colors.blue.shade900)
        : Colors.red.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 20,
            color: isOnline ? (pendingCount > 0 ? Colors.amber.shade800 : Colors.green.shade700) : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isOnline ? 'Online Mode' : 'Offline Mode (Local Storage Only)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount queued',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isSyncing
                      ? 'Synchronizing pending mutations with remote server...'
                      : (isOnline
                          ? (pendingCount > 0
                              ? 'All mutations persist locally; syncing queue...'
                              : 'All changes saved locally & synced to server')
                          : 'Mutations survive app restart. Will sync on reconnect.'),
                  style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.85)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Online / Offline toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simulate:',
                style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              FilterChip(
                label: Text(
                  isOnline ? 'Go Offline' : 'Go Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
                selected: !isOnline,
                selectedColor: Colors.red.shade200,
                backgroundColor: Colors.white,
                onSelected: (val) {
                  controller.setOnline(!val);
                },
              ),
              const SizedBox(width: 6),
              if (isOnline && pendingCount > 0)
                IconButton(
                  tooltip: 'Force Sync Now',
                  icon: isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 20),
                  onPressed: isSyncing ? null : () => controller.sync(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
