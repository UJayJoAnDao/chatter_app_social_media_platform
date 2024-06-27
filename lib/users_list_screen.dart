import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String userId = doc.id;
              String nickname = data['nickname'] ?? 'Anonymous';

              // Don't show the current user in the list
              if (userId != FirebaseAuth.instance.currentUser?.uid) {
                return ListTile(
                  leading: CircleAvatar(child: Text(nickname[0])),
                  title: Text(nickname),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: userId,
                          otherUserNickname: nickname,
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Container(); // Return an empty container for the current user
              }
            }).toList(),
          );
        },
      ),
    );
  }
}