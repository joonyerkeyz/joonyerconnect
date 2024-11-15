import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 0;

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
        
        if (!userDoc.exists) {
          print('User document does not exist.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
          return;
        }

        Map<String, dynamic>? userData = userDoc.data();
        if (userData == null) {
          print('User data is null.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch user data')),
          );
          return;
        }

        print('User data: $userData');
        
        await FirebaseFirestore.instance.collection('reviews').add({
          'userId': user?.uid,
          'userName': '${userData['name']} ${userData['surname']}',
          'profileImageUrl': userData['profileImageUrl'] ?? '',
          'review': _reviewController.text,
          'rating': _rating,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        _reviewController.clear();
        setState(() {
          _rating = 0;
        });
      } catch (e) {
        print('Error submitting review: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review')),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final isOwner = data['userId'] == currentUserId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['profileImageUrl'] != ''
                              ? NetworkImage(data['profileImageUrl'])
                              : null,
                          child: data['profileImageUrl'] == ''
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(data['userName'] ?? 'Anonymous'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['review']),
                            const SizedBox(height: 4),
                            Text('Rating: ${data['rating']}'),
                            Text(
                              'Date: ${data['timestamp'] != null ? DateFormat.yMMMd().format((data['timestamp'] as Timestamp).toDate()) : 'No date'}',
                            ),
                          ],
                        ),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteReview(document.id),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },),),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _reviewController,
                    decoration: const InputDecoration(labelText: 'Write your review'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your review';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rating:'),
                      Expanded(
                        child: Slider(
                          value: _rating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _rating.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                      ),
                      Text(_rating.round().toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitReview,
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
