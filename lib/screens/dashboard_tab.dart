// lib/screens/dashboard_tab.dart
import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'login_screen.dart';

/// DashboardTab
///
/// Expected constructor (matches how MainScaffold calls it):
///   DashboardTab({
///     required int userId,
///     required String backendBase,
///     required String backendSyncUrl,
///     required String backendStatusUrl,
///     required String authToken,
///     required int energy,
///     required double mood,
///     required double stress,
///     required ValueChanged<double> onMoodChanged,
///     required ValueChanged<double> onStressChanged,
///     required VoidCallback onInteractionStart,
///     required VoidCallback onInteractionEnd,
///     required ValueChanged<int> onCharge,
///   })
class DashboardTab extends StatefulWidget {
  final int userId;
  final String backendBase;
  final String backendSyncUrl;
  final String backendStatusUrl;
  final String authToken;
  final int energy;
  final double mood;
  final double stress;
  final ValueChanged<double>? onMoodChanged;
  final ValueChanged<double>? onStressChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final ValueChanged<int>? onCharge;

  const DashboardTab({
    Key? key,
    required this.userId,
    required this.backendBase,
    required this.backendSyncUrl,
    required this.backendStatusUrl,
    required this.authToken,
    required this.energy,
    required this.mood,
    required this.stress,
    this.onMoodChanged,
    this.onStressChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.onCharge,
  }) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final HealthService _healthService = HealthService();

  bool _loading = false;
  String? _statusMessage;
  DateTime? _lastSynced;
  int _lastSyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _ensureUserAndLoadStatus();
  }

  Future<void> _ensureUserAndLoadStatus() async {
    if (widget.userId <= 0) {
      // No user available: prompt to login when the user taps the UI button
      setState(() {
        _statusMessage = 'No user found. Please sign in.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = 'Fetching server status...';
    });

    try {
      final last = await _healthService.fetchServerLastSynced(
        backendStatusUrl: widget.backendStatusUrl,
        userId: widget.userId,
        authToken: widget.authToken,
      );

      setState(() {
        _lastSynced = last;
        _statusMessage = last != null
            ? 'Server last synced: ${last.toUtc().toIso8601String()}'
            : 'No server sync found';
      });
    } catch (err) {
      // fallback to local stored timestamp if server unreachable
      final local = await _healthService.getLocalLastSynced(widget.userId);
      setState(() {
        _lastSynced = local;
        _statusMessage =
            'Failed to fetch status from server — using local: ${local?.toUtc().toIso8601String() ?? "none"}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSyncNow() async {
    if (widget.userId <= 0) {
      // navigate to login for provisioning
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LoginScreen(backendBase: widget.backendBase)));
      // After returning from login, reload userId from service and restart status
      final stored = await _healthService.getStoredUserId();
      if (stored != null && stored > 0) {
        // refresh parent (MainScaffold may have updated but we'll refresh local view)
        setState(() {
          // update userId in-place is not ideal; better to rebuild parent, but do it here for UX
        });
        await _ensureUserAndLoadStatus();
      }
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = 'Syncing with server...';
    });

    try {
      await _healthService.syncSinceLastSynced(
        userId: widget.userId,
        backendStatusUrl: widget.backendStatusUrl,
        backendSyncUrl: widget.backendSyncUrl,
        authToken: widget.authToken,
        // lookbackWindowIfNull left null—service will fall back to midnight or persisted lastSynced.
      );

      final post = await _healthService.fetchServerLastSynced(
        backendStatusUrl: widget.backendStatusUrl,
        userId: widget.userId,
        authToken: widget.authToken,
      );

      setState(() {
        _lastSynced = post;
        _statusMessage =
            'Sync completed. LastSynced: ${post?.toUtc().toIso8601String() ?? 'unknown'}';
      });
    } catch (err) {
      setState(() {
        _statusMessage = 'Sync failed: $err';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildHeader() {
    final userText =
        widget.userId > 0 ? 'User ${widget.userId}' : 'No user (not signed in)';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userText,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_statusMessage ?? '', style: const TextStyle(fontSize: 13)),
              if (_lastSynced != null)
                Text('Last synced: ${_lastSynced!.toLocal()}',
                    style: const TextStyle(fontSize: 12)),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: _loading ? null : _onSyncNow,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.userId <= 0) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('You are not signed in.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          LoginScreen(backendBase: widget.backendBase)));
            },
            child: const Text('Sign in / Create account'),
          ),
        ]),
      );
    }

    // Minimal dashboard content — replace with your real UI pieces
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Energy: ${widget.energy} EU',
            style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Mood: ${widget.mood.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Text('Stress: ${widget.stress.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text('Sync status: ${_statusMessage ?? "unknown"}'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _onSyncNow,
          child: const Text('Force Sync'),
        ),
        const SizedBox(height: 24),
        // TODO: Replace the following with your dashboard tiles / charts using backend data
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8)),
          child: const Text(
              'Dashboard content goes here (daily steps, heart rate, etc.)'),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // parent scaffold provides background
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
