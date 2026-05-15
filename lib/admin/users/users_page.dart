import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/admin_service.dart';
import 'package:women_safety/admin/common/search_field.dart';
import 'package:women_safety/admin/common/empty_state.dart';
import 'package:women_safety/admin/users/widgets/user_card.dart';
import 'package:women_safety/admin/users/widgets/edit_user_dialog.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = _adminService.getAllUsers();
  }

  Future<void> _editUser(UserModel user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result != null) {
      try {
        await _adminService.updateUser(user.id, result);
        setState(() {
          _loadUsers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users
        .where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdminSearchField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              hintText: 'Search users...',
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading users',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const AdminEmptyState(
                    message: 'No users found',
                    icon: Icons.people_outline,
                  );
                }

                final filteredUsers = _filterUsers(snapshot.data!);

                if (filteredUsers.isEmpty) {
                  return const AdminEmptyState(
                    message: 'No users match your search',
                    icon: Icons.search,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return UserCard(
                      user: user,
                      onEdit: () => _editUser(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
