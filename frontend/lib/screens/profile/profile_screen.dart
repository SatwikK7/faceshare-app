import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: () async {
                  await AuthService.signInWithGoogle();
                  setState(() {}); // Refresh UI
                },
                child: const Text('Sign in with Google'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.photoURL ?? ''),
                    radius: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(user.displayName ?? 'No Name'),
                  Text(user.email ?? 'No Email'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      setState(() {});
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
      ),
    );
  }
}
