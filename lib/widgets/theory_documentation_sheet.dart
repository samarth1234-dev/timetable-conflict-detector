import 'package:flutter/material.dart';

class TheoryDocumentationView extends StatelessWidget {
  const TheoryDocumentationView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Interval Comparison Logic
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.indigo.shade200),
            ),
            color: Colors.indigo.shade50.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calculate, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '1. Clash Detection: Interval Comparison Logic',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mathematical Formulation:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: const Text(
                      'Let interval A = [start_A, end_A) and interval B = [start_B, end_B) on day D.\n\n'
                      'Overlap condition:\n'
                      '  Overlap(A, B) ⇔ (day_A == day_B) ∧ (max(start_A, start_B) < min(end_A, end_B))\n\n'
                      'Overlap duration:\n'
                      '  Duration = min(end_A, end_B) - max(start_A, start_B)',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Key Boundary Cases Handled:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildBullet(
                    'Contiguous / Abutting Classes (end_A == start_B):',
                    'A class ending at 11:30 followed immediately by a class starting at 11:30 yields max(start_A, start_B) == min(end_A, end_B) → Overlap Duration = 0. This is safely recognized as contiguous, NOT a clash.',
                  ),
                  _buildBullet(
                    'Full Interval Containment (A ⊆ B):',
                    'When a 60-minute seminar takes place completely inside a 2-hour lab workshop, max/min logic returns the exact inner duration without false negatives.',
                  ),
                  _buildBullet(
                    'Partial Intersecting Clashes (start_A < start_B < end_A < end_B):',
                    'The overlap sub-interval [start_B, end_A) is isolated, and the exact colliding minutes are rendered on the UI.',
                  ),
                  _buildBullet(
                    'Asymptotic Complexity:',
                    'Grouped by day (D ≤ 7) and sorted by start time. Traversal evaluates candidate collisions in O(N log N + K) time, where K is the number of actual collisions.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Offline Data Structure & Reconciliation
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.teal.shade200),
            ),
            color: Colors.teal.shade50.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cloud_sync, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '2. Offline Data Structure & Reconciliation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Local Data Architecture:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: const Text(
                      '1. Active Entity Store (TimeSlot[]):\n'
                      '   - UUID primary key, subject, day, start/end minutes, color, version, updatedAt, isDeleted.\n\n'
                      '2. Write-Ahead Mutation Log (MutationLogEntry[]):\n'
                      '   - Immutable append-only log persisted to SharedPreferences disk backing.\n'
                      '   - Schema: { logId, timestamp, action: CREATE|UPDATE|DELETE, entityId, payload, syncStatus }.\n'
                      '   - Survives complete device reboot or app kills with no active network.',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reconciliation Protocol (Sync-on-Reconnect):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildBullet(
                    'Optimistic Local Commits:',
                    'Any user action immediately appends to the persistent MutationLog and updates local slot state, giving 0ms latency even when fully offline.',
                  ),
                  _buildBullet(
                    'FIFO Log Replay upon Reconnection:',
                    'When connectivity transitions to Online (or on manual trigger), pending mutations are dispatched chronologically to the sync endpoint.',
                  ),
                  _buildBullet(
                    'Last-Write-Wins (LWW) with Version Vector:',
                    'If a remote slot was modified concurrently during disconnection, the system compares updatedAt ISO timestamps and incremental version numbers. The latest timestamp wins, and server-side tombstones propagate deletions cleanly.',
                  ),
                  _buildBullet(
                    'Deterministic Re-Clash Check:',
                    'Immediately following reconciliation, ClashDetector re-evaluates the merged dataset so any newly introduced multi-device conflicts are instantly highlighted in red on the grid.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.35),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
