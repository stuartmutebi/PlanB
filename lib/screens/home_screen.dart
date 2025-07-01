import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lostandfound/services/auth_service.dart';
import 'package:lostandfound/screens/add_item_screen.dart';
import 'package:lostandfound/screens/profile_screen.dart';
import 'package:lostandfound/models/item.dart';
import 'package:lostandfound/services/item_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ItemService _itemService = ItemService();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost and Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Electronics'),
                _buildCategoryChip('Documents'),
                _buildCategoryChip('Keys'),
                _buildCategoryChip('Jewelry'),
                _buildCategoryChip('Other'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _itemService.getItems(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
                searchQuery: _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items found'),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: item.imageUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(item.imageUrl!),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.image),
                              ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.category} - ${item.location}\n${item.description}',
                        ),
                        trailing: Text(
                          item.date.toLocal().toString().split(' ')[0],
                        ),
                        onTap: () {
                          // TODO: Navigate to item details screen
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddItemScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(category),
        selected: _selectedCategory == category,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }
} 