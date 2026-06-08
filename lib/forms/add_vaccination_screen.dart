import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddVaccinationScreen extends StatefulWidget{
  final String petId;

  const AddVaccinationScreen({super.key, required this.petId});
  
  @override
  State<AddVaccinationScreen> createState()=>_AddVaccinationScreenState();
  

}

class _AddVaccinationScreenState  extends State<AddVaccinationScreen>{
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime? selectedDate;
  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async{
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? now,
        firstDate: DateTime(now.year - 10),
        lastDate: DateTime(now.year + 10));
    if(d == null){
      return;
    }
    setState(() {
      selectedDate=d;
    });
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()){
      return;

    }
    if (selectedDate==null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a date")),
      );
      return;
    }
    setState(() {
      loading=true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .collection('vaccinations')
          .add({
        "name": nameCtrl.text.trim(),
        "notes": notesCtrl.text.trim(),
        "date": Timestamp.fromDate(selectedDate!),
        "createdAt": FieldValue.serverTimestamp(),
      });
      if(mounted){
        Navigator.pop(context);
      }
    }catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }finally {
      if (mounted) {
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
        : "${selectedDate!.day.toString().padLeft(2, '0')}"
        ".${selectedDate!.month.toString().padLeft(2, '0')}"
        ".${selectedDate!.year}";

    return Scaffold(
      appBar: AppBar(title: const Text('Add vaccination 💉')
      ,backgroundColor: Colors.blue.shade50,),

      //form
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // vaccine name
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vaccine name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter vaccine name' : null,
              ),

              const SizedBox(height: 12),

              // notes
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes(optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 12),

              // date picker
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : pickDate,
                  icon: const Icon(Icons.calendar_month_sharp),
                  label: Text(dateText),
                ),
              ),
            ],
          ),
        ),
      ),

      // SAVE BUTTON FIXED BOTTOM
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
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
        ),
      ),
    );
  }
  
}