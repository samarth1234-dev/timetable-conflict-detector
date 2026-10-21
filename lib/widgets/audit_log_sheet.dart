import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/mutation_log.dart';
import '../state/timetable_controller.dart';

class AuditLogView extends StatelessWidget {
  final TimetableController controller;

  const AuditLogView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final logs = controller.mutationLogs;
    final pendingCount = controller.pendingMutationCount;
    final isOnline = controller.isOnline;

    return Column(
      children: [
        // Top Overview Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            border: Border(bottom: BorderSide(color: Colors.blueGrey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_edu_rounded, color: Colors.blueGrey.shade800, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offline Write-Ahead Audit Log',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Every mutation is committed to disk before UI update. Survives app restart without network.',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pendingCount > 0 ? Colors.amber.shade700 : Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Simulation / Demo Controls Bar
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.blueGrey.shade400),
                    ),
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Simulate App Restart (Disk Persistence)'),
                    onPressed: () async {
                      await controller.simulateAppRestart();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App restarted! All slots and mutation logs reloaded directly from disk.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.deepPurple.shade300),
                      foregroundColor: Colors.deepPurple,
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Inject Server Slot (Test Reconciliation)'),
                    onPressed: () async {
                      await controller.injectRemoteServerConflict();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Injected external slot on server! Reconnect to trigger reconciliation.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  if (pendingCount > 0 && isOnline)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.green.shade700,
                      ),
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Sync Queue Now'),
                      onPressed: () => controller.sync(),
                    ),
                ],
              ),

              if (controller.lastSyncStatusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last Sync Message: ${controller.lastSyncStatusMessage}',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Log List
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No mutation log entries yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return _buildLogCard(context, entry);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, MutationLogEntry entry) {
    Color actionColor;
    IconData actionIcon;

    switch (entry.action) {
      case MutationAction.create:
        actionColor = Colors.green.shade700;
        actionIcon = Icons.add_circle_outline;
        break;
      case MutationAction.update:
        actionColor = Colors.blue.shade700;
        actionIcon = Icons.edit_note;
        break;
      case MutationAction.delete:
        actionColor = Colors.red.shade700;
        actionIcon = Icons.delete_forever;
        break;
    }

    final isPending = entry.syncStatus == SyncStatus.pending;
    final isSynced = entry.syncStatus == SyncStatus.synced;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isPending ? Colors.amber.shade400 : Colors.grey.shade300,
          width: isPending ? 1.5 : 1,
        ),
      ),
      color: isPending ? Colors.amber.shade50.withValues(alpha: 0.4) : Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.actionName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.description,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Text('• ID: ${entry.entityId.substring(0, entry.entityId.length > 8 ? 8 : entry.entityId.length)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPending
                ? Colors.amber.shade100
                : (isSynced ? Colors.green.shade100 : Colors.red.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPending
                    ? Icons.access_time
                    : (isSynced ? Icons.cloud_done : Icons.error_outline),
                size: 14,
                color: isPending
                    ? Colors.amber.shade900
                    : (isSynced ? Colors.green.shade900 : Colors.red.shade900),
              ),
              const SizedBox(width: 4),
              Text(
                isPending ? 'Pending' : (isSynced ? 'Synced' : 'Failed'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPending
                      ? Colors.amber.shade900
                      : (isSynced ? Colors.green.shade900 : Colors.red.shade900),
                ),
              ),
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Disk Snapshot (JSON):',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(entry.toJson()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
