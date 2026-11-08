import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// CTFs: own PCT competitions first, then upcoming international CTFs.
/// Data comes only from the Firestore `ctfs` collection — never
/// hardcoded. Tap a CTF for its detail page.
class CtfsScreen extends StatefulWidget {
  const CtfsScreen({super.key});

  @override
  State<CtfsScreen> createState() => _CtfsScreenState();
}

class _CtfsScreenState extends State<CtfsScreen> {
  late Future<DataResult<List<Ctf>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchCtfs();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchCtfs();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CTFs')),
      body: FutureBuilder<DataResult<List<Ctf>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || result.notConfigured) {
            return PctEmptyState(
              icon: Icons.cloud_off,
              title: 'Firebase is not connected yet',
              message: result == null
                  ? 'Could not load CTFs.'
                  : 'Add google-services.json to connect Firebase, then CTFs will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(
              message: result.error!,
              onRetry: _refresh,
            );
          }
          final ctfs = result.data ?? <Ctf>[];
          if (ctfs.isEmpty) {
            return const PctEmptyState(
              icon: Icons.flag_outlined,
              title: 'No CTFs yet',
              message: 'No competitions are listed right now. Check back soon.',
            );
          }
          final own = ctfs.where((c) => c.isOwn).toList();
          final upcoming = ctfs.where((c) => !c.isOwn).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (own.isNotEmpty) ...[
                  const _SectionHeader(title: 'PAK Cyber Team CTFs'),
                  ...own.map((c) => _CtfCard(ctf: c)),
                  const SizedBox(height: 8),
                ],
                if (upcoming.isNotEmpty) ...[
                  const _SectionHeader(title: 'Upcoming International CTFs'),
                  ...upcoming.map((c) => _CtfCard(ctf: c)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: PctColors.gold,
        ),
      ),
    );
  }
}

class _CtfCard extends StatelessWidget {
  const _CtfCard({required this.ctf});

  final Ctf ctf;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PctColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PctColors.panelBorder),
      ),
      child: ListTile(
        leading: Icon(
          ctf.isOwn ? Icons.shield : Icons.public,
          color: PctColors.gold,
          size: 28,
        ),
        title: Text(
          ctf.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(ctf.dateRange, style: const TextStyle(color: PctColors.muted)),
            if (ctf.format.isNotEmpty) ...[
              const SizedBox(height: 6),
              PctChip(label: ctf.format, icon: Icons.category),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: PctColors.muted),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CtfDetailScreen(ctf: ctf),
            ),
          );
        },
      ),
    );
  }
}

class CtfDetailScreen extends StatelessWidget {
  const CtfDetailScreen({super.key, required this.ctf});

  final Ctf ctf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CTF Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ctf.isOwn ? Icons.shield : Icons.public,
                  color: PctColors.gold,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ctf.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ctf.isOwn) const PctChip(label: 'PAK Cyber Team', icon: Icons.verified),
            if (ctf.format.isNotEmpty) ...[
              const SizedBox(height: 8),
              PctChip(label: ctf.format, icon: Icons.category),
            ],
            const SizedBox(height: 20),
            _DetailRow(label: 'Dates', value: ctf.dateRange),
            if (ctf.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'About',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(ctf.description, style: const TextStyle(color: PctColors.text)),
            ],
            if (ctf.hasSafeUrl) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: ctf.url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Event Link'),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                ctf.url,
                style: const TextStyle(color: PctColors.muted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(color: PctColors.muted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

