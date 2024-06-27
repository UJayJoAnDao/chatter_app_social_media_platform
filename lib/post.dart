import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post {
  final String id;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      username: data['username'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
    };
  }
}

class PostWidget extends StatelessWidget {
  final Post post;

  PostWidget({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(post.username[0])),
                SizedBox(width: 8),
                Text(post.username, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(post.content),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(post.timestamp.toString(), style: TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
                    Text('${post.likes}'),
                    SizedBox(width: 16),
                    IconButton(icon: Icon(Icons.comment_outlined), onPressed: () {}),
                    Text('${post.comments}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}