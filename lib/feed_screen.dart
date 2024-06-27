import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'explore_screen.dart';
import 'user_profile.dart';
import 'post_widget.dart';
import 'create_post_screen.dart';
import 'users_list_screen.dart';
import 'comment_screen.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userNickname = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _updateOldPosts();
  }

  Future<void> _loadUserNickname() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userNickname = (doc.data() as Map<String, dynamic>)['nickname'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  void _commentOnPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: postId),
      ),
    );
  }

  Future<void> _updateOldPosts() async {
    QuerySnapshot oldPosts = await _firestore
        .collection('posts')
        .where('timestamp', isNull: true)
        .get();

    WriteBatch batch = _firestore.batch();

    for (QueryDocumentSnapshot doc in oldPosts.docs) {
      batch.update(doc.reference, {
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatter'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
            child: CircleAvatar(
              child: Text(_userNickname.isNotEmpty ? _userNickname[0].toUpperCase() : 'U'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var posts = snapshot.data!.docs.map((doc) {
            try {
              return Post.fromFirestore(doc);
            } catch (e) {
              print('Error parsing post: $e');
              return null;
            }
          }).where((post) => post != null).toList();

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostWidget(
                post: posts[index]!,
                onComment: _commentOnPost,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExploreScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UsersListScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}