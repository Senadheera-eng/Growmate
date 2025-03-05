// add_tree_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grow_mate_version2/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'tree_model.dart';
import 'disease_model.dart';
import 'location_picker.dart';

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
  String? _selectedDiseaseId;
  List<DiseaseModel> _diseases = [];
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _selectedLocation;

  Future<void> _selectLocation() async {
  final selectedLocation = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LocationPicker()),
  );
  
  if (selectedLocation != null) {
    setState(() {
      // Update with the full address
      _locationController.text = selectedLocation['address'];
      
      // Optionally store latitude and longitude if needed
      _selectedLocation = selectedLocation['address'];
    });
  }
}

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('diseases').get();

    setState(() {
      _diseases = snapshot.docs
          .map((doc) => DiseaseModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

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
        diseaseId: _isDiseased ? _selectedDiseaseId : null,
        location: _locationController.text,
        userId: userId,
        diseaseIdentifiedDate: _isDiseased ? DateTime.now() : null,
      );

      await FirebaseFirestore.instance
          .collection('trees')
          .doc(tree.id)
          .set(tree.toMap());

      // Add this notification scheduling code
      try {
        final notificationService = NotificationService();

        // Schedule appropriate notifications
        await notificationService.scheduleWateringReminder(tree);
        await notificationService.scheduleFertilizationReminder(tree);
        await notificationService.scheduleCareTipReminders(tree);

        // If tree is diseased, schedule treatment notifications
        if (tree.isDiseased && tree.diseaseId != null) {
          await notificationService.scheduleTreatmentReminder(tree);
        }
      } catch (e) {
        print('Error scheduling notifications: $e');
        // Don't show error to user, notifications are a background feature
      }

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

  Widget _buildDiseaseSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.healing,
                color: Color(0xFF00C853),
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Tree Health Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const Spacer(),
              Switch(
                value: _isDiseased,
                onChanged: (value) {
                  setState(() {
                    _isDiseased = value;
                    if (!value) {
                      _selectedDiseaseId = null;
                      _diseaseDescController.clear();
                    }
                  });
                },
                activeColor: const Color(0xFF00C853),
              ),
            ],
          ),
          _isDiseased
              ? const Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'Tree is diseased',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'Tree is healthy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
          if (_isDiseased) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Disease',
                prefixIcon:
                    const Icon(Icons.bug_report, color: Colors.redAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C853)),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              value: _selectedDiseaseId,
              items: _diseases.map((disease) {
                return DropdownMenuItem(
                  value: disease.id,
                  child: Text(disease.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDiseaseId = value;
                  if (value != null) {
                    final disease = _diseases.firstWhere((d) => d.id == value);
                    _diseaseDescController.text = disease.description;
                  }
                });
              },
              validator: (value) => _isDiseased && value == null
                  ? 'Please select a disease'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diseaseDescController,
              decoration: InputDecoration(
                labelText: 'Additional Disease Notes',
                prefixIcon: const Icon(Icons.note_add, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C853)),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
              validator: (value) => _isDiseased && (value?.isEmpty ?? true)
                  ? 'Please add disease notes'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.photo_library,
                color: Color(0xFF00C853),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Tree Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 34),
            child: Text(
              'Add up to 3 photos of your tree',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: _selectedImages.length < 3 ? _pickImage : null,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00C853).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: _selectedImages.length < 3
                                  ? const Color(0xFF00C853)
                                  : Colors.grey.withOpacity(0.5),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedImages.length}/3',
                              style: TextStyle(
                                color: _selectedImages.length < 3
                                    ? const Color(0xFF00C853)
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00C853).withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            height: 120,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Add New Tree',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Adding a Tree'),
                  content: const Text(
                    'Add details about your coconut tree. Be sure to include at least one photo and accurate information about its age and health status.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildImagePickerSection(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildDiseaseSection(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTree,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.eco),
                        SizedBox(width: 8),
                        Text(
                          'Save Tree',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 22,
            child: Icon(
              Icons.eco,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'New Coconut Tree',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add a new tree to your collection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.info,
                color: Color(0xFF00C853),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tree Name',
              prefixIcon: const Icon(Icons.label, color: Color(0xFF00C853)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Age (months)',
              prefixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF00C853)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
              helperText: 'Enter age between 1-6 months',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter age';
              final age = int.tryParse(value!);
              if (age == null) return 'Please enter a valid number';
              if (age < 1 || age > 6)
                return 'Age must be between 1 and 6 months';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon:
                  const Icon(Icons.location_on, color: Color(0xFF00C853)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map, color: Colors.blue),
                onPressed: _selectLocation,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a location';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
