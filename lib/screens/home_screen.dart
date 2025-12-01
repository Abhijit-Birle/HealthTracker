import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final health = context.watch<HealthProvider>();

    final tab1 = health.tab1;

    final String email = auth.email ?? auth.user?.email ?? "";
final Object? rawId = auth.user?.id;
    final int userId = rawId is int
        ? rawId as int
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Zeno — Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Welcome, ${auth.user?.name ?? 'User'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            // ------- TAB 1 CARD --------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Tab 1 — Steps (last 7 days)'),
                    const SizedBox(height: 8),

                    if (tab1 == null)
                      const Text(
                          'No data yet. Tap Sync to import from Apple Health.')
                    else
                      ...[
                        Text(
                          'Total steps: ${tab1.aggregates.totalSteps
                              .toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: tab1.daily
                                .map((d) => _buildDayTile(d))
                                .toList(),
                          ),
                        )
                      ],

                    const SizedBox(height: 12),

                    // --------- SYNC BUTTON ----------
                    ElevatedButton.icon(
                      onPressed: health.syncing
                          ? null
                          : () async {
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User email missing'),
                            ),
                          );
                          return;
                        }

                        final dummyRecords = [
                          {
                            'type': 'steps',
                            'startTime': DateTime.now()
                                .subtract(const Duration(hours: 1))
                                .toUtc()
                                .toIso8601String(),
                            'endTime': DateTime.now()
                                .toUtc()
                                .toIso8601String(),
                            'measureValue': 150.0,
                            'source': 'app',
                          }
                        ];

                        try {
                          await health.syncHealth(email, dummyRecords, userId:userId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Synced successfully'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sync failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: health.syncing
                          ? const Text('Syncing...')
                          : const Text('Sync with Apple Health (MVP)'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- DAY TILE UI ----------
  Widget _buildDayTile(dynamic dp) {
    final date = dp.date ?? '';
    final steps = dp.steps?.toInt() ?? 0;

    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(date
              .toString()
              .split('T')
              .first, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '$steps',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('steps', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
