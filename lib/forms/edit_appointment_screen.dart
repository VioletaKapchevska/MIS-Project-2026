import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mis_proekt/forms/edit_pet_screen.dart';
import 'package:mis_proekt/models/appointment_model.dart';

class EditAppointmentScreen extends StatefulWidget{
  final String petId;
  final Appointment appointment;
  const EditAppointmentScreen({super.key,
    required this.petId,
    required this.appointment});

  @override
  State<EditAppointmentScreen> createState()=>_EditAppointmentScreenState();

}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController notesCtrl;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.appointment.title);
    locationCtrl = TextEditingController(text: widget.appointment.location);
    notesCtrl = TextEditingController(text: widget.appointment.notes);

    selectedDate = DateTime(
      widget.appointment.dateTime.year,
      widget.appointment.dateTime.month,
      widget.appointment.dateTime.day,
    );
    selectedTime = TimeOfDay(
      hour: widget.appointment.dateTime.hour,
      minute: widget.appointment.dateTime.minute,
    );
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
    setState(() => selectedDate = d);
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() => selectedTime = t);
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

    if(!_formKey.currentState!.validate()){
      return;
    }

    final dt = combinedDateTime;
    if (dt == null) {
      return;
    }
    setState(() {
      loading=true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({
        "title": titleCtrl.text.trim(),
        "location": locationCtrl.text.trim(),
        "notes": notesCtrl.text.trim(),
        "dateTime": Timestamp.fromDate(dt),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted){
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Edit error: $e")),
        );
      }
    } finally {
      if (mounted){
        setState(() {
          loading=false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = (selectedDate == null)
        ? "Pick date"
        : "${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}";
    final timeText = (selectedTime == null) ? "Pick time" : selectedTime!.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit appointment"),
      backgroundColor: Colors.blue.shade50,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Title / Reason",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Enter title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: "Location (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Notes (optional)",
                  border: OutlineInputBorder(),
                ),
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
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : save,
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Save changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}