import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class AddCaregiverScreen extends StatefulWidget {
  const AddCaregiverScreen({super.key});

  @override
  State<AddCaregiverScreen> createState() => _AddCaregiverScreenState();
}

class _AddCaregiverScreenState extends State<AddCaregiverScreen> {
  final TextEditingController _emailController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  bool loading = false;

  Future<void> add() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    setState(() => loading = true);

    final result = await _db.linkCaregiverByEmail(
      personId: auth.currentUser!.uid,
      email: _emailController.text.trim(),
    );

    setState(() => loading = false);

    if (!mounted) return;

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caregiver added')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Caregiver')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Caregiver Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: add,
                    child: const Text('Add'),
                  )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
