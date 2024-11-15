import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String formattedTime;
  final bool isRead;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.formattedTime,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isCurrentUser ? Colors.blue : Colors.grey[300],
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formattedTime,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black,
              fontSize: 12,
            ),
          ),
          if (isCurrentUser)
            Icon(
              isRead ? Icons.done_all : Icons.done,
              color: isRead ? Colors.blue : Colors.grey,
              size: 16,
            ),
        ],
      ),
    );
  }
}
