import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mis_proekt/forms/edit_pet_screen.dart';
import 'package:mis_proekt/screens/pet_details_screen.dart';
import '../models/pet_model.dart';

class PetCardWidget extends StatelessWidget {
  final Pet pet;

  const PetCardWidget({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>PetDetailsScreen(pet: pet)));
      },
      child: Card(
        color: Colors.blue.shade50,
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.blue.shade400,
              width: 2,
            )
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              //leva strana-slika
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: pet.imgUrl.isNotEmpty
                    ? Image.network(
                  pet.imgUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, size: 40),
                ),
              ),

              const SizedBox(width: 16),

              //desna strana
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // TYPE
                    Text("${pet.type}"),

                    // YEARS
                    Text("Age: ${pet.age} years"),

                    // BREED
                    if (pet.breed.isNotEmpty)
                      Text("Breed: ${pet.breed}"),

                    // WEIGHT
                    if (pet.weight > 0)
                      Text("Weight: ${pet.weight} kg"),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: (){
                   Navigator.push(context, MaterialPageRoute(builder: (_)=>EditPetScreen(pet: pet)));
                  }, icon: Icon(Icons.edit)),
                  IconButton(onPressed: (){
                    _deletePet(context);
                  }, icon: const Icon(Icons.delete)),
                  const Icon(Icons.chevron_right),
                ],

              )
            ],
          ),
        ),
      )
    );
  }

  Future<void> _deletePet(BuildContext context)async {
    final confirm_dialog = await showDialog<bool>(
      context: context,
      builder: (_)=>AlertDialog(
       title: const Text('Delete a pet'),
        content: Text("Are you sure you want to delete ${pet.name}?"),
        actions: [
          TextButton(onPressed: (){
                Navigator.pop(context,false);
          }, child: const Text('Cancel')),
          ElevatedButton(onPressed: (){
               Navigator.pop(context,true);
          }, child: const Text('Delete'))
        ],
      ),
    );
    if(confirm_dialog!=true){
      return;
    }
    //ako ima slika delete ja
    if(pet.imgUrl.isNotEmpty){
      try{
         final img_ref = FirebaseStorage.instance.refFromURL(pet.imgUrl);
         await img_ref.delete();
      }catch(_){}
    }
    //delete document from firestore
    await FirebaseFirestore.instance.collection('pets').doc(pet.id).delete();
    if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pet deleted")));
    }
  }
}