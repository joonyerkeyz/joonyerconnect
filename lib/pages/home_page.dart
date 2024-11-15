import 'package:flutter/material.dart';
import 'package:minimal/componets/drawer.dart';
import 'package:minimal/pages/chat_list.page.dart';
import 'package:minimal/pages/my_content_page.dart';
import 'package:minimal/pages/review_page.dart';
import 'package:minimal/pages/widgets/post_list.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import 'upload_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('JM Connect+')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.chat, 'Chats', 1),
                  _buildNavItem(Icons.podcasts, 'Posts', 2),
                  _buildNavItem(Icons.reviews, 'Reviews', 3),
                ],
              ),
            ),
          ),
          Expanded(
            child: _getPage(_currentIndex),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadPostPage()),
          );
        },
        tooltip: 'Add Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const PostList();
      case 1:
        return ChatListPage(); // Use ChatListPage instead of ChatPage directly
      case 2:
        return const MyContentPage();
      case 3:
        return const ReviewsPage();
   
      default:
        return const PostList();
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: 80,
        color: _currentIndex == index ? Colors.blue.withOpacity(0.1) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _currentIndex == index ? Colors.blue : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                color: _currentIndex == index ? Colors.blue : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
