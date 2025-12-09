import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tools/admin_reindex.dart'; // adjust relative path if you placed it elsewhere

class AdminReindexPage extends StatefulWidget {
  const AdminReindexPage({super.key});
  @override
  State<AdminReindexPage> createState() => _AdminReindexPageState();
}

class _AdminReindexPageState extends State<AdminReindexPage> {
  bool running = false;
  String log = '';

  void _append(String s) => setState(() => log = '$log\n$s');

  Future<void> _run() async {
    setState(() => running = true);
    final r = Reindexer();
    try {
      _append('Starting reindex...');
      await r.reindexAllProviders();
      _append('Completed.');
    } catch (e, st) {
      _append('Error: $e\n$st');
    } finally {
      setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Reindex Providers'),
        backgroundColor: const Color(0xFF18AEAC),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: running ? null : _run,
                  icon: running ? const SizedBox.shrink() : const Icon(Icons.refresh),
                  label: Text(running ? 'Running...' : 'Run Reindex'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18AEAC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Clear log',
                onPressed: () => setState(() => log = ''),
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  log.isEmpty ? 'No output yet.' : log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This operation updates the `keywords` field on all provider documents. Use with caution.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          if (!kReleaseMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Running in ${kDebugMode ? "debug" : "profile"} mode', style: const TextStyle(fontSize: 11)),
            ),
        ]),
      ),
    );
  }
}
