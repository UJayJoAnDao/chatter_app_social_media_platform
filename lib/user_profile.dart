import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_screen.dart';

class UserProfile {
  String email;
  String nickname;
  String bio;
  DateTime? createdAt;

  UserProfile({
    required this.email,
    required this.nickname,
    this.bio = '',
    this.createdAt
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? data['email'].split('@')[0],
      bio: data['bio'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'bio': bio,
      'createdAt': createdAt,
    };
  }
}

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late UserProfile _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthScreen()),
          (Route<dynamic> route) => false,
    );
  }
  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        // 這種情況應該很少發生，因為我們在註冊時就創建了文檔
        // 但為了安全起見，我們還是保留這個邏輯
        setState(() {
          _userProfile = UserProfile(
            email: user.email!,
            nickname: user.email!.split('@')[0],
            createdAt: DateTime.now(),
          );
          _isLoading = false;
        });
        // 創建用戶文檔
        await _firestore.collection('users').doc(user.uid).set(_userProfile.toFirestore());
      }
    }
  }

  Future<void> _updateProfile(String field, String value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        field: value,
      }, SetOptions(merge: true));
      setState(() {
        if (field == 'nickname') _userProfile.nickname = value;
        if (field == 'bio') _userProfile.bio = value;
      });
    }
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    String newValue = currentValue;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${field.capitalize()}'),
          content: TextField(
            onChanged: (value) {
              newValue = value;
            },
            controller: TextEditingController(text: currentValue),
            decoration: InputDecoration(hintText: "Enter new ${field.toLowerCase()}"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateProfile(field, newValue);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('User Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${_userProfile.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nickname: ${_userProfile.nickname}', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditDialog('nickname', _userProfile.nickname),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Bio: ${_userProfile.bio}', style: TextStyle(fontSize: 18)),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditDialog('bio', _userProfile.bio),
                ),
              ],
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                child: Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  onPrimary: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class UserProfileWidget extends StatelessWidget {
  final UserProfile profile;

  UserProfileWidget({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(profile.nickname[0])),
      title: Text(profile.nickname),
      subtitle: Text(profile.bio),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserProfileScreen()),
        );
      },
    );
  }
}