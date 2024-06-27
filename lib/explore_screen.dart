import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_widget.dart';
import 'user_profile.dart';
import 'comment_screen.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // 搜索用户
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThan: query + 'z')
          .get();

      List<UserProfile> users = userSnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();

      // 搜索帖子
      QuerySnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: query + 'z')
          .get();

      List<Post> posts = postSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      setState(() {
        _searchResults = [...users, ...posts];
        _isLoading = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users or posts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                if (result is UserProfile) {
                  return UserProfileWidget(profile: result);
                } else if (result is Post) {
                  return PostWidget(
                    post: result,
                    onComment: _commentOnPost,
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}