import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minimal/pages/chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs.where((doc) {
                var userData = doc.data() as Map<String, dynamic>;
                String fullName = '${userData['name']} ${userData['surname']}'.toLowerCase();
                return fullName.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var userData = users[index].data() as Map<String, dynamic>;
                  String userId = users[index].id;
                  String name = userData['name'] ?? '';
                  String surname = userData['surname'] ?? '';
                  String? profileImageUrl = userData['profileImageUrl'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text('$name $surname'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(userId: userId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}