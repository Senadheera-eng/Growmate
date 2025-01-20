// add_tree_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'tree_model.dart';

class AddTreePage extends StatefulWidget {
  const AddTreePage({Key? key}) : super(key: key);

  @override
  _AddTreePageState createState() => _AddTreePageState();
}

class _AddTreePageState extends State<AddTreePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _diseaseDescController = TextEditingController();
  bool _isDiseased = false;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _diseaseDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final List<String> photoUrls = [];
    final storage = FirebaseStorage.instance;
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    for (var image in _selectedImages) {
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = storage.ref().child('trees/$userId/$fileName');

      await ref.putFile(image);
      final String downloadUrl = await ref.getDownloadURL();
      photoUrls.add(downloadUrl);
    }

    return photoUrls;
  }

  Future<void> _saveTree() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final List<String> photoUrls = await _uploadImages();
      
      final tree = TreeModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        ageInMonths: int.parse(_ageController.text),
        photoUrls: photoUrls,
        isDiseased: _isDiseased,
        diseaseDescription: _isDiseased ? _diseaseDescController.text : null,
        location: _locationController.text,
        userId: userId,
      );

      await FirebaseFirestore.instance
          .collection('trees')
          .doc(tree.id)
          .set(tree.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tree added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Tree'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker section
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: _selectedImages.length < 3 ? _pickImage : null,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: _selectedImages.length < 3
                                ? Colors.grey
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tree Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age (months)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter age';
                if (int.tryParse(value!) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Is the tree diseased?'),
              value: _isDiseased,
              onChanged: (value) {
                setState(() => _isDiseased = value);
              },
            ),
            
            if (_isDiseased) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _diseaseDescController,
                decoration: const InputDecoration(
                  labelText: 'Disease Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => _isDiseased && (value?.isEmpty ?? true)
                    ? 'Please describe the disease'
                    : null,
              ),
            ],
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTree,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Tree',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}