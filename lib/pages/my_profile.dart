import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  User? _user;
  String? _profileImageUrl;
  bool _isLoading = false;
  String _name = '';
  String _surname = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_user != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _profileImageUrl = userData['profileImageUrl'] as String?;
            _name = userData['name'] as String? ?? '';
            _surname = userData['surname'] as String? ?? '';
            _email = _user!.email ?? '';
          });
          print('Profile Image URL: $_profileImageUrl'); // Debug print
        } else {
          print('User document does not exist');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found')),
          );
        }
      } catch (e) {
        print('Error loading profile data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile data')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
    });

    final ImagePicker picker = ImagePicker();
    XFile? image;

    try {
      // Handle image picking for both web and mobile
      if (kIsWeb) {
        image = await picker.pickImage(source: ImageSource.gallery);
      } else {
        image = await picker.pickImage(source: ImageSource.gallery);
      }

      if (image != null) {
        // Upload image to Firebase Storage
        Reference ref = _storage.ref().child('profile_images/${_user!.uid}');
        UploadTask uploadTask;

        if (kIsWeb) {
          // For web, we need to use putData with the image bytes
          uploadTask = ref.putData(await image.readAsBytes());
        } else {
          // For mobile, we can use putFile
          uploadTask = ref.putFile(File(image.path));
        }

        // Get the download URL once the upload is complete
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Update the user's profile in Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        print('Updated Profile Image URL: $_profileImageUrl'); // Debug print

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeProfilePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Remove the image from Firebase Storage
      if (_profileImageUrl != null) {
        await _storage.refFromURL(_profileImageUrl!).delete();
      }

      // Update the user's profile in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'profileImageUrl': FieldValue.delete(),
      });

      setState(() {
        _profileImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed successfully')),
      );
    } catch (e) {
      print('Error removing profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove profile picture')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_name $_surname',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadImage,
                      child: const Text('Upload Profile Picture'),
                    ),
                    const SizedBox(height: 5),
                    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ElevatedButton(
                        onPressed: _removeProfilePicture,
                        child: const Text('Remove Profile Picture'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}