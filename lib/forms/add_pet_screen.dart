import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  String? type;

  bool loading = false;
  File? _imageFile;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if(picked==null){
      return;
    }
    setState(() => _imageFile = File(picked.path));
  }

  Future<String?> uploadImage(String uid, String petId) async {
    if(_imageFile==null){
      return null;
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child("pets")
        .child(uid)
        .child("$petId.jpg");

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> savePet() async {

    if(!_formKey.currentState!.validate()){
      return;
    }
    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance.collection('pets').doc();
    final petId = docRef.id;

    final imageUrl = await uploadImage(uid, petId);

    await docRef.set({
      "name": nameController.text.trim(),
      "breed": breedController.text.trim(),
      "age": int.tryParse(ageController.text) ?? 0,
      "weight": int.tryParse(weightController.text) ?? 0,
      "type": type,
      "ownerId": uid,
      "imageUrl": imageUrl ?? "",
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Pet 🐾"),backgroundColor: Colors.blue.shade50,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // IMAGE PICK
            GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _imageFile == null
                    ? const LinearGradient(
                  colors: [
                    Color(0xFF4FACFE),
                    Color(0xFF43E97B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
              ),
              child: _imageFile == null
                  ? const Center(
                child: Text(
                  "Tap to add pet photo",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Pet Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter pet name" : null,
              ),

              const SizedBox(height: 12),

              // ✅ USER MUST CHOOSE TYPE
              DropdownButtonFormField<String>(
                value: type,
                hint: const Text("Select pet type"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Dog", child: Text("Dog")),
                  DropdownMenuItem(value: "Cat", child: Text("Cat")),
                ],
                onChanged: (v) => setState(() => type = v),
                validator: (v) => v == null ? "Select pet type" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(
                  labelText: "Breed",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Weight",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : savePet,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}