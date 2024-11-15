import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  _UploadPostPageState createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _uploadPost() async {
  if (_textController.text.isEmpty && _image == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter some text or choose an image')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    String? imageUrl;
    if (_image != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('post_images/$fileName');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(await _image!.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(_image!.path));
      }

      imageUrl = await (await uploadTask).ref.getDownloadURL();
    }

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    String userName = '${userDoc['name']} ${userDoc['surname']}';
    
    // Check if profileImageUrl exists in the user document
    String? profileImageUrl;
    if (userDoc.data() is Map<String, dynamic>) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      profileImageUrl = userData['profileImageUrl'] as String?;
    }

    DocumentReference postRef = await _firestore.collection('posts').add({
      'userId': _auth.currentUser!.uid,
      'userName': userName,
      'profileImageUrl': profileImageUrl,  // This will be null if it doesn't exist
      'text': _textController.text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
      'comments': [],
    });

    // Update the post with the server timestamp separately
    await postRef.update({
      'timestamp': FieldValue.serverTimestamp(),
    });

    _textController.clear();
    setState(() {
      _image = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post uploaded successfully')),
    );

    Navigator.pop(context);
  } catch (e) {
    print('Error uploading post: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload post: $e')),
    );
  }

  setState(() {
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                  ),
                  if (_image != null) ...[
                    const SizedBox(height: 16.0),
                    kIsWeb
                        ? Image.network(_image!.path)
                        : Image.file(File(_image!.path)),
                  ],
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _uploadPost,
                    child: const Text('Post'),
                  ),
                ],
              ),
            ),
    );
  }
}