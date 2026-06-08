import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/vaccination_model.dart';

class EditVaccinationScreen extends StatefulWidget{

  final String petId;
  final Vaccination vaccination;

  const EditVaccinationScreen({super.key, required this.petId, required this.vaccination});

  @override
  State<EditVaccinationScreen> createState()=>_EditVaccinationScreenState();


}

class _EditVaccinationScreenState extends State<EditVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController notesCtrl;
  DateTime? selectedDate;
  bool loading = false;

  @override
  void initState(){
    super.initState();
    nameCtrl = TextEditingController(text: widget.vaccination.name);
    notesCtrl = TextEditingController(text: widget.vaccination.notes);
    selectedDate = widget.vaccination.date;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d==null){
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
    if (selectedDate == null) {
      return;
    }

    setState(() {
      loading=true;
    });

    await FirebaseFirestore.instance
        .collection('pets')
        .doc(widget.petId)
        .collection('vaccinations')
        .doc(widget.vaccination.id)
        .update({
      "name": nameCtrl.text.trim(),
      "notes": notesCtrl.text.trim(),
      "date": Timestamp.fromDate(selectedDate!),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (mounted){
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${selectedDate!.day.toString().padLeft(2, '0')}"
        ".${selectedDate!.month.toString().padLeft(2, '0')}"
        ".${selectedDate!.year}";
    return Scaffold(
      appBar: AppBar(title: const Text('Edit vaccination'),
      backgroundColor: Colors.blue.shade50,),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //edit name field
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Vaccine name',
                ),
                validator: (v)=>(v==null||v.isEmpty) ? 'Enter name':null,
              ),
              const SizedBox(height: 12,),
              //edit notes field
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Notes',
                ),
              ),
              const SizedBox(height: 12,),
              //edit Date field
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(dateText),
                ),
              ),
              const SizedBox(height: 20,),
              //save btn
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: loading ? null :
                        save,
                    child: loading ? const CircularProgressIndicator()
                        : const Text("Save changes"),
              )
              )
            ],
          ),
        ),
      ),
    );
  }

}