import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lostandfound/services/auth_service.dart';
import 'package:lostandfound/screens/add_item_screen.dart';
import 'package:lostandfound/screens/profile_screen.dart';
import 'package:lostandfound/models/item.dart';
import 'package:lostandfound/services/item_service.dart';
import 'package:lostandfound/screens/report_lost_item_screen.dart';
import 'package:lostandfound/screens/report_found_item_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportLostItemScreen(),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.red.shade50,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                            child: Column(
                              children: const [
                                Icon(Icons.report_gmailerrorred, color: Colors.red, size: 40),
                                SizedBox(height: 8),
                                Text('Report Lost Item', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportFoundItemScreen(),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.green.shade50,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                            child: Column(
                              children: const [
                                Icon(Icons.volunteer_activism, color: Colors.green, size: 40),
                                SizedBox(height: 8),
                                Text('Report Found Item', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                child: Container(
                  color: Colors.transparent,
                  child: StreamBuilder<List<Item>>(
                    stream: _itemService.getItems(
                      category: _selectedCategory == 'All' ? null : _selectedCategory,
                      searchQuery: _searchQuery,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: \\${snapshot.error}'),
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
                                '\\${item.category} - \\${item.location}\n\\${item.description}',
                              ),
                              trailing: Text(
                                item.date.toLocal().toString().split(' ')[0],
                              ),
                              onTap: () {
                                if (!item.isLost) {
                                  _showClaimDialog(context, item);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
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

  void _showClaimDialog(BuildContext context, Item item) {
    final TextEditingController _answerController = TextEditingController();
    File? _claimPhotoFile;
    bool _isSubmitting = false;
    String? _errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Claim Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.validationQuestion != null && item.validationQuestion!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Validation Question:'),
                          Text(item.validationQuestion!, style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: _answerController,
                            decoration: InputDecoration(hintText: 'Your answer'),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    Text('Upload a photo as proof (optional):'),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.single.path != null) {
                          setState(() {
                            _claimPhotoFile = File(result.files.single.path!);
                          });
                        }
                      },
                      icon: Icon(Icons.image),
                      label: Text(_claimPhotoFile == null ? 'Pick Image' : 'Change Image'),
                    ),
                    if (_claimPhotoFile != null) ...[
                      SizedBox(height: 8),
                      Image.file(_claimPhotoFile!, height: 100),
                    ],
                    if (_errorText != null) ...[
                      SizedBox(height: 8),
                      Text(_errorText!, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          String? photoUrl;
                          if (_claimPhotoFile != null) {
                            try {
                              photoUrl = await _itemService.uploadClaimProofPhoto(_claimPhotoFile!);
                            } catch (e) {
                              setState(() {
                                _errorText = 'Photo upload failed: \\${e.toString()}';
                                _isSubmitting = false;
                              });
                              print('Photo upload error: \\${e.toString()}');
                              return;
                            }
                          }
                          final userId = context.read<AuthService>().user?.uid;
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('You must be logged in to claim an item.')),
                            );
                            setState(() => _isSubmitting = false);
                            return;
                          }
                          final alreadyClaimed = await _itemService.hasUserClaimedItem(item.id, userId);
                          if (alreadyClaimed) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('You have already submitted a claim for this item.')),
                            );
                            setState(() => _isSubmitting = false);
                            return;
                          }
                          print('Submitting claim: itemId=\\${item.id}, userId=\\$userId, answer=\\${_answerController.text}, photoUrl=\\$photoUrl');
                          await _itemService.submitClaimRequest(
                            itemId: item.id,
                            claimantUserId: userId,
                            answer: _answerController.text.trim(),
                            photoUrl: photoUrl,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Claim request submitted!')),
                          );
                        },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 