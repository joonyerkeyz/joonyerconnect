import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  const CommentSection(
      {super.key, required this.postId, required this.scrollController});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  bool _isPosting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPosting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userName = '${userDoc['name']} ${userDoc['surname']}';

      final commentData = {
        'userId': userId,
        'userName': userName,
        'text': _commentController.text,
        'timestamp': Timestamp
            .now(), // Use Timestamp.now() instead of FieldValue.serverTimestamp()
        'reactions': {},
      };

      await _retryTransaction(() async {
        final postRef =
            FirebaseFirestore.instance.collection('posts').doc(widget.postId);
        final postSnapshot = await postRef.get();

        if (!postSnapshot.exists) {
          throw Exception("Post does not exist!");
        }

        List<dynamic> currentComments = postSnapshot.get('comments') ?? [];
        currentComments.add(commentData);

        await postRef.update({
          'comments': currentComments,
          'commentCount': FieldValue.increment(1),
        });
      });

      if (!mounted) return;
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted successfully')),
      );
    } catch (e) {
      print('Error adding comment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _retryTransaction(Future<void> Function() transaction) async {
    int retries = 3;
    while (retries > 0) {
      try {
        await transaction();
        return;
      // ignore: unused_catch_clause
      } on TimeoutException catch (e) {
        retries--;
        if (retries == 0) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _deleteComment(int index) async {
    try {
      await _retryTransaction(() async {
        final postRef =
            FirebaseFirestore.instance.collection('posts').doc(widget.postId);
        final postSnapshot = await postRef.get();

        if (!postSnapshot.exists) {
          throw Exception("Post does not exist!");
        }

        List<dynamic> currentComments =
            List.from(postSnapshot.get('comments') ?? []);
        currentComments.removeAt(index);

        await postRef.update({
          'comments': currentComments,
          'commentCount': FieldValue.increment(-1),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully')),
      );
    } catch (e) {
      print('Error deleting comment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleReaction(int index) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _retryTransaction(() async {
        final postRef =
            FirebaseFirestore.instance.collection('posts').doc(widget.postId);
        final postSnapshot = await postRef.get();

        if (!postSnapshot.exists) {
          throw Exception("Post does not exist!");
        }

        List<dynamic> currentComments =
            List.from(postSnapshot.get('comments') ?? []);
        Map<String, dynamic> comment = Map.from(currentComments[index]);
        Map<String, dynamic> reactions = Map.from(comment['reactions'] ?? {});

        if (reactions.containsKey(userId)) {
          reactions.remove(userId);
        } else {
          reactions[userId] = true;
        }

        comment['reactions'] = reactions;
        currentComments[index] = comment;

        await postRef.update({
          'comments': currentComments,
        });
      });
    } catch (e) {
      print('Error toggling reaction: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reaction: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final comments = List<Map<String, dynamic>>.from(
                    snapshot.data!['comments'] ?? []);

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    final isCurrentUserComment =
                        comment['userId'] == currentUserId;
                    final reactionCount =
                        (comment['reactions'] as Map<String, dynamic>?)
                                ?.length ??
                            0;
                    final hasReacted =
                        (comment['reactions'] as Map<String, dynamic>?)
                                ?.containsKey(currentUserId) ??
                            false;

                    return ListTile(
                      title: Text(comment['userName']),
                      subtitle: Text(comment['text']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: hasReacted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleReaction(index),
                          ),
                          Text('$reactionCount'),
                          if (isCurrentUserComment)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteComment(index),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration:
                      const InputDecoration(hintText: 'Add a comment...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isPosting ? null : _addComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}