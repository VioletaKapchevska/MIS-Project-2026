import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final String petId;
  final String? initialTitle;
  final String? initialNotes;

  const AddAppointmentScreen({
    super.key,
    required this.petId,
    this.initialTitle,
    this.initialNotes,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl.text = widget.initialTitle ?? '';
    notesCtrl.text = widget.initialNotes ?? '';
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    locationCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (d == null) return;

    setState(() {
      selectedDate = d;
    });
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (t == null) return;

    setState(() {
      selectedTime = t;
    });
  }

  DateTime? get combinedDateTime {
    if (selectedDate == null || selectedTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dt = combinedDateTime;

    if (dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pick date and time")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final notificationKey = DateTime.now().millisecondsSinceEpoch.toString();

      await NotificationService.instance.scheduleAppointmentReminder(
        appointmentId: notificationKey,
        title: titleCtrl.text.trim(),
        appointmentDateTime: dt,
        minutesBefore: 3,
        location: locationCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .collection('appointments')
          .add({
        "title": titleCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "notes": notesCtrl.text.trim(),
        "dateTime": Timestamp.fromDate(dt),
        "createdAt": FieldValue.serverTimestamp(),
        "minutesBefore": 3,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Add error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = (selectedDate == null)
        ? "Pick date"
        : "${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}";

    final timeText = (selectedTime == null)
        ? "Pick time"
        : selectedTime!.format(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Add appointment 📅'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Title',
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter title' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Location',
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Notes(optional)',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(dateText),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(timeText),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : save,
                    child: loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}