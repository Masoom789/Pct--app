import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// The signed-in user's own certificates, from the Firestore
/// `certificates` collection (where userId == current uid).
/// Tap one for its detail page: verify-by-code display, and a
/// Download button that saves the certificate image to Photos when
/// the certificate has an image URL. No fake certificates are ever
/// shown — an empty list is an honest empty state.
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key, required this.userId});

  final String? userId;

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<DataResult<List<PctCertificate>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DataResult<List<PctCertificate>>> _load() {
    final uid = widget.userId;
    if (uid == null || uid.isEmpty) {
      return Future.value(
        const DataResult<List<PctCertificate>>(
          error: 'Please sign in again to see your certificates.',
        ),
      );
    }
    return DataService.instance.fetchMyCertificates(uid);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: FutureBuilder<DataResult<List<PctCertificate>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || result.notConfigured) {
            return const PctEmptyState(
              icon: Icons.cloud_off,
              title: 'Firebase is not connected yet',
              message:
                  'Add google-services.json to connect Firebase, then your certificates will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(message: result.error!, onRetry: _refresh);
          }
          final certs = result.data ?? <PctCertificate>[];
          if (certs.isEmpty) {
            return const PctEmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No certificates yet',
              message: 'No certificates yet — complete a course to earn one.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: certs.length,
              itemBuilder: (context, i) {
                final cert = certs[i];
                return Card(
                  color: PctColors.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: PctColors.panelBorder),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: PctColors.gold,
                      size: 28,
                    ),
                    title: Text(
                      cert.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        SelectableText(
                          cert.code.isEmpty ? 'No code' : cert.code,
                          style: const TextStyle(
                            color: PctColors.muted,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PctChip(
                              label: cert.issueDateLabel,
                              icon: Icons.calendar_today,
                            ),
                            if (cert.category.isNotEmpty)
                              PctChip(label: cert.category, icon: Icons.category),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: PctColors.muted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CertificateDetailScreen(cert: cert),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Detail view: the certificate as a shareable card, its unique code
/// (verify-by-code), and Download when an image URL exists.
class CertificateDetailScreen extends StatefulWidget {
  const CertificateDetailScreen({super.key, required this.cert});

  final PctCertificate cert;

  @override
  State<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  bool _downloading = false;

  /// File name for the gallery save: letters, digits, _ and - only,
  /// max 40 chars (gal takes the name without an extension).
  String _downloadName() {
    final code = widget.cert.code.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');
    final safe = code.isEmpty ? 'certificate' : code.substring(0, code.length > 32 ? 32 : code.length);
    return 'pct-certificate-$safe';
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      var access = await Gal.hasAccess();
      if (!access) access = await Gal.requestAccess();
      if (!access) {
        _snack('Photos permission is needed to save the certificate.');
        return;
      }
      final client = HttpClient();
      try {
        final request =
            await client.getUrl(Uri.parse(widget.cert.imageUrl));
        final response = await request.close();
        if (response.statusCode != 200) {
          _snack('Could not download the certificate image. Try again.');
          return;
        }
        final bytes = await consolidateHttpClientResponseBytes(response);
        await Gal.putImageBytes(
          bytes,
          album: 'PAK Cyber Team',
          name: _downloadName(),
        );
        _snack('Certificate saved to Photos.');
      } finally {
        client.close();
      }
    } catch (_) {
      _snack('Could not download the certificate. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.cert.code));
    _snack('Certificate code copied.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cert = widget.cert;
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The certificate card.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PctColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PctColors.gold, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: PctColors.gold,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PAK Cyber Team',
                    style: TextStyle(
                      color: PctColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cert.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cert.category.isNotEmpty)
                    PctChip(label: cert.category, icon: Icons.category),
                  const SizedBox(height: 16),
                  const Text(
                    'Certificate Code',
                    style: TextStyle(color: PctColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    cert.code.isEmpty ? 'No code' : cert.code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Issued: ${cert.issueDateLabel}',
                    style: const TextStyle(color: PctColors.muted),
                  ),
                ],
              ),
            ),
            if (cert.hasSafeImageUrl) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  cert.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, _, __) => const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Certificate image could not be loaded.',
                        style: TextStyle(color: PctColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              const Text(
                'No certificate image was uploaded for this certificate.',
                style: TextStyle(color: PctColors.muted),
              ),
            ],
            const SizedBox(height: 28),
            if (cert.hasSafeImageUrl)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _downloading ? 'Saving…' : 'Download Certificate',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Certificate Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
