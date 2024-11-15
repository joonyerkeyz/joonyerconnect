import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimal/pages/widgets/comment_section.dart';


class PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String postId;

  const PostCard({super.key, required this.data, required this.postId});

  Future<void> _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  Future<void> _toggleLike(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        final likedBy = List<String>.from(snapshot['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': likedBy,
          });
        } else {
          likedBy.add(userId);
          transaction.update(postRef, {
            'likes': FieldValue.increment(1),
            'likedBy': likedBy,
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like')),
      );
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) =>
            CommentSection(postId: postId, scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked =
        (data['likedBy'] as List<dynamic>?)?.contains(currentUserId) ?? false;
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: data['profileImageUrl'] != null &&
                          data['profileImageUrl'].isNotEmpty
                      ? NetworkImage(data['profileImageUrl'])
                      : null,
                  child: data['profileImageUrl'] == null ||
                          data['profileImageUrl'].isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data['timestamp'] != null
                            ? data['timestamp'].toDate().toString()
                            : 'No timestamp',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(data['text'] ?? ''),
            if (data['imageUrl'] != null) ...[
              const SizedBox(height: 8.0),
              Image.network(data['imageUrl']),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  label: Text('${data['likes'] ?? 0} Likes'),
                  onPressed: () => _toggleLike(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: Text('${data['commentCount'] ?? 0} Comments'),
                  onPressed: () => _showComments(context),
                ),
                if (data['userId'] == currentUserId)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    onPressed: () => _deletePost(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}