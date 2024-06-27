import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Post {
  final String id;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      username: data['username'] ?? 'Anonymous',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }
}

class PostWidget extends StatefulWidget {
  final Post post;
  final Function(String) onComment;

  PostWidget({
    required this.post,
    required this.onComment,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likedBy.contains(_auth.currentUser?.uid);
  }

  void _toggleLike() async {
    final String userId = _auth.currentUser!.uid;
    final DocumentReference postRef = _firestore.collection('posts').doc(widget.post.id);

    if (isLiked) {
      // Unlike the post
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Like the post
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

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
                CircleAvatar(child: Text(widget.post.username[0])),
                SizedBox(width: 8),
                Text(widget.post.username, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(widget.post.content),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.post.timestamp.toString(), style: TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                      onPressed: _toggleLike,
                    ),
                    Text('${widget.post.likes}'),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.comment_outlined),
                      onPressed: () => widget.onComment(widget.post.id),
                    ),
                    Text('${widget.post.comments}'),
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