import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/study_session.dart';
import 'study_providers.dart';

import '../dashboard/dashboard_providers.dart';

class AddStudySessionScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const AddStudySessionScreen({super.key, this.sessionId});

  @override
  ConsumerState<AddStudySessionScreen> createState() =>
      _AddStudySessionScreenState();
}

class _AddStudySessionScreenState extends ConsumerState<AddStudySessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _start = TimeOfDay.now();
  TimeOfDay _end = TimeOfDay.now();
  int? _understanding;
  bool _saving = false;
  String? _loadedSessionId;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider);
    _start = TimeOfDay.fromDateTime(now);
    _end = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay time) =>
      DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _combine(_start);
    final end = _combine(_end);
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final session = StudySession(
      id: widget.sessionId ?? 'study_${DateTime.now().microsecondsSinceEpoch}',
      subject: _subjectController.text.trim(),
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: start,
      endTime: end,
      durationSeconds: end.difference(start).inSeconds,
      understanding: _understanding,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    try {
      final repository = ref.read(studySessionRepositoryProvider);
      if (widget.sessionId == null) {
        await repository.insert(session);
      } else {
        await repository.update(session);
      }
      ref.invalidate(studySessionsProvider);
      ref.invalidate(studySessionByIdProvider);
      if (mounted) context.pop();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan sesi belajar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.sessionId == null
        ? null
        : ref.watch(studySessionByIdProvider(widget.sessionId!));
    if (existing != null) {
      return existing.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => const Scaffold(
          body: Center(child: Text('Gagal memuat sesi belajar.')),
        ),
        data: (session) {
          if (session == null) {
            return const Scaffold(
              body: Center(child: Text('Sesi belajar tidak ditemukan.')),
            );
          }
          _populate(session);
          return _form(context);
        },
      );
    }
    return _form(context);
  }

  void _populate(StudySession session) {
    if (_loadedSessionId == session.id) return;
    _loadedSessionId = session.id;
    _subjectController.text = session.subject;
    _notesController.text = session.notes ?? '';
    _date = session.date;
    _start = TimeOfDay.fromDateTime(session.startTime);
    _end = TimeOfDay.fromDateTime(session.endTime ?? session.startTime);
    _understanding = session.understanding;
  }

  Widget _form(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sessionId == null
              ? 'Tambah Sesi Belajar'
              : 'Edit Sesi Belajar',
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan Sesi'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Mata Pelajaran',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Masukkan mata pelajaran.'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal'),
              subtitle: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Waktu mulai'),
              subtitle: Text(_formatTimeOfDay(_start)),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Waktu selesai'),
              subtitle: Text(_formatTimeOfDay(_end)),
              onTap: () => _pickTime(false),
            ),
            DropdownButtonFormField<int>(
              initialValue: _understanding,
              decoration: const InputDecoration(
                labelText: 'Pemahaman (opsional)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var value = 1; value <= 5; value++)
                  DropdownMenuItem(value: value, child: Text('$value / 5')),
              ],
              onChanged: (value) => setState(() => _understanding = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime(bool start) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (selected != null) {
      setState(() => start ? _start = selected : _end = selected);
    }
  }
}

String _formatTimeOfDay(TimeOfDay t) {
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
