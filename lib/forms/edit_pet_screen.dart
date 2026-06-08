import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet_model.dart';

class EditPetScreen extends StatefulWidget {
  final Pet pet;
  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameCtrl;
  late final TextEditingController breedCtrl;
  late final TextEditingController ageCtrl;
  late final TextEditingController weightCtrl;

  String? type;
  bool loading = false;

  File? _newImgFile;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.pet.name);
    breedCtrl = TextEditingController(text: widget.pet.breed);
    ageCtrl = TextEditingController(text: widget.pet.age.toString());
    weightCtrl = TextEditingController(text: widget.pet.weight.toString());
    type = widget.pet.type.isNotEmpty ? widget.pet.type : null;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    ageCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  Future<void> pickNewImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (picked == null) return;
    setState(() => _newImgFile = File(picked.path));
  }

  // ✅ Upload with unique filename (fix caching) + safe folder path
  Future<String?> _uploadNewImage({
    required String uid,
    required String petId,
  }) async {
    if (_newImgFile == null) return null;

    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance
        .ref()
        .child("pets")
        .child(uid)
        .child(petId)
        .child(fileName);

    await ref.putFile(_newImgFile!).timeout(const Duration(seconds: 60));
    return await ref.getDownloadURL().timeout(const Duration(seconds: 20));
  }

  // ✅ delete old image by URL (ignore failures)
  Future<void> _deleteOldImgIfExists(String oldUrl) async {
    if (oldUrl.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(oldUrl);
      await ref.delete();
    } catch (_) {}
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final petId = widget.pet.id;

      // NOTE: Pet model uses imgUrl, but Firestore field is "imageUrl"
      String imageUrl = widget.pet.imgUrl;

      // If user picked a new image → upload it and replace URL
      if (_newImgFile != null) {
        final newUrl = await _uploadNewImage(uid: uid, petId: petId);
        if (newUrl != null && newUrl.isNotEmpty) {
          await _deleteOldImgIfExists(imageUrl); // delete old after successful upload
          imageUrl = newUrl;
        }
      }

      // ✅ IMPORTANT: update Firestore field "imageUrl" (not "imgUrl")
      await FirebaseFirestore.instance.collection('pets').doc(petId).update({
        "name": nameCtrl.text.trim(),
        "type": type,
        "breed": breedCtrl.text.trim(),
        "age": int.tryParse(ageCtrl.text) ?? 0,
        "weight": int.tryParse(weightCtrl.text) ?? 0,
        "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Edit error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit pet'),
      backgroundColor: Colors.blue.shade50,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: loading ? null : pickNewImage,
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _newImgFile != null
                        ? Image.file(_newImgFile!, fit: BoxFit.cover)
                        : (pet.imgUrl.isNotEmpty
                        ? Image.network(
                      pet.imgUrl,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                        : const Center(
                      child: Icon(Icons.add_a_photo_outlined, size: 36),
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Pet name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Enter pet name" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: type,
                hint: const Text('Select pet type'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Dog", child: Text("Dog")),
                  DropdownMenuItem(value: "Cat", child: Text("Cat")),
                ],
                onChanged: loading ? null : (v) => setState(() => type = v),
                validator: (v) => v == null ? 'Select pet type' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: breedCtrl,
                decoration: const InputDecoration(
                  labelText: "Breed",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? "");
                  if (n == null || n < 0) return "Enter valid age";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? "");
                  if (n == null || n < 0) return "Enter valid weight";
                  return null;
                },
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : saveChanges,
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}