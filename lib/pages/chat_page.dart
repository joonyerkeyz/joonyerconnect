import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart'; // For formatting time

class ChatPage extends StatefulWidget {
  final String userId;
  const ChatPage({super.key, required this.userId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String _chatPartnerName = '';
  String? _chatPartnerProfileImageUrl;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _loadChatPartnerInfo();
  }

  void _loadChatPartnerInfo() async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _chatPartnerName = '${userData['name']} ${userData['surname']}';
        _chatPartnerProfileImageUrl = userData['profileImageUrl'];
      });
    }
  }

  void initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        const InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'chat',
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _firestore.collection('messages').add({
        'senderId': _auth.currentUser!.uid,
        'receiverId': widget.userId,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
      });
      _messageController.clear();
    }
  }

  void deleteMessage(DocumentSnapshot doc) async {
    await _firestore.collection('messages').doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _chatPartnerProfileImageUrl != null
                  ? NetworkImage(_chatPartnerProfileImageUrl!)
                  : null,
              child: _chatPartnerProfileImageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
            Text(_chatPartnerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: CombineLatestStream.list([
                _firestore.collection('messages')
                    .where('senderId', isEqualTo: _auth.currentUser!.uid)
                    .where('receiverId', isEqualTo: widget.userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                _firestore.collection('messages')
                    .where('receiverId', isEqualTo: _auth.currentUser!.uid)
                    .where('senderId', isEqualTo: widget.userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Combine both message lists into one
                List<QueryDocumentSnapshot> messages = [];
                for (var querySnapshot in snapshot.data!) {
                  messages.addAll(querySnapshot.docs);
                }

                // Sort combined messages by timestamp
                messages.sort((a, b) {
                  final aTimestamp = a['timestamp'];
                  final bTimestamp = b['timestamp'];
                  return (bTimestamp ?? Timestamp.now())
                      .compareTo(aTimestamp ?? Timestamp.now());
                });

                return ListView(
                  reverse: true,
                  children: messages.map((document) {
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;
                    String formattedTime = data['timestamp'] != null
                        ? DateFormat('HH:mm').format(data['timestamp'].toDate())
                        : '';

                    // Show notification for new messages
                    if (!isCurrentUser) {
                      showNotification('New Message', data['message']);
                    }

                    var alignment = isCurrentUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;

                    return GestureDetector(
                      onLongPress: () => deleteMessage(document),
                      child: Container(
                        alignment: alignment,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisAlignment: isCurrentUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              ChatBubble(message: data['message'], isCurrentUser: isCurrentUser),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.black, // Set time color to black
                                  fontSize: 12,
                                ),
                              ),
                              if (isCurrentUser)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    data['read'] ? Icons.done_all : Icons.done,
                                    color: data['read'] ? Colors.blue : Colors.grey,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const ChatBubble({super.key, required this.message, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isCurrentUser ? Colors.blue : Colors.grey[300],
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }
}
