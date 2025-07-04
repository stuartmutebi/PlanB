import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lostandfound/services/auth_service.dart';
import 'package:lostandfound/services/item_service.dart';
import 'package:lostandfound/models/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';
import 'package:lostandfound/screens/chat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().user?.uid;
    final itemService = ItemService();

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your profile'),
        ),
      );
    }

    // Listen for claim status changes and show a SnackBar
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('claim_requests')
          .where('claimantUserId', isEqualTo: userId)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> claimSnapshot) {
        // Keep track of last shown statuses using a static map
        // (In production, use a more robust state management solution)
        // This is a workaround for demo purposes
        final staticStatusMap = <String, String>{};
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (claimSnapshot.hasData) {
            for (final doc in claimSnapshot.data!.docs) {
              final claimId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              if (status == 'approved' || status == 'rejected') {
                if (staticStatusMap[claimId] != status) {
                  staticStatusMap[claimId] = status;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        status == 'approved'
                            ? 'Your claim for item ${data['itemId']} was approved!'
                            : 'Your claim for item ${data['itemId']} was rejected.',
                      ),
                    ),
                  );
                }
              }
            }
          }
        });
        // Render the rest of the profile screen as before
        return _ProfileScreenBody(userId: userId, itemService: itemService);
      },
    );
  }
}

// Extracted body widget to avoid rebuild issues with SnackBar logic
class _ProfileScreenBody extends StatefulWidget {
  final String userId;
  final ItemService itemService;
  const _ProfileScreenBody({required this.userId, required this.itemService});

  @override
  State<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<_ProfileScreenBody> {
  // Track shown match IDs to avoid duplicate notifications
  final Set<String> _shownMatchIds = HashSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('claim_requests')
                  .where('claimantUserId', isEqualTo: widget.userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const SizedBox();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Claim Notifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...docs.map<Widget>((doc) {
                      final data = doc.data();
                      final status = data['status'] ?? 'pending';
                      final itemId = data['itemId'] ?? '';
                      return ListTile(
                        leading: Icon(
                          status == 'approved'
                              ? Icons.check_circle
                              : status == 'rejected'
                                  ? Icons.cancel
                                  : Icons.hourglass_empty,
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        title: Text('Claim for item: $itemId'),
                        subtitle: Text('Status: $status'),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: widget.itemService.getUserItems(widget.userId),
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
                    child: Text('You haven\'t posted any items yet'),
                  );
                }
                return StreamBuilder<Map<String, List<Item>>>(
                  stream: widget.itemService.streamPotentialMatchesForUser(widget.userId),
                  builder: (context, matchSnapshot) {
                    final matchesMap = matchSnapshot.data ?? {};
                    // Show notification for new matches
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      for (final entry in matchesMap.entries) {
                        for (final match in entry.value) {
                          final matchKey = '${entry.key}_${match.id}';
                          if (!_shownMatchIds.contains(matchKey)) {
                            _shownMatchIds.add(matchKey);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('New potential match for your item: ${items.firstWhere((i) => i.id == entry.key, orElse: () => Item(id: '', title: '', description: '', category: '', location: '', date: DateTime.now(), userId: '', isLost: true)).title}'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      }
                    });
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final matches = matchesMap[item.id] ?? [];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Column(
                            children: [
                              ListTile(
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!item.isRecovered)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline),
                                        onPressed: () async {
                                          try {
                                            await widget.itemService.markAsRecovered(item.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Item marked as recovered'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString())),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        try {
                                          await widget.itemService.deleteItem(item.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Item deleted'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString())),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              // Potential Matches UI
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Potential Matches:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (matches.isEmpty)
                                      const Text('No potential matches yet.'),
                                    ...matches.map((match) => Card(
                                      color: Colors.blue[50],
                                      child: ListTile(
                                        leading: match.imageUrl != null
                                            ? CircleAvatar(backgroundImage: NetworkImage(match.imageUrl!))
                                            : const CircleAvatar(child: Icon(Icons.link)),
                                        title: Text(match.title),
                                        subtitle: Text('Category: ${match.category}\nLocation: ${match.location}'),
                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            // Optionally, navigate to a match review screen
                                          },
                                          child: const Text('Review'),
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              if (!item.isLost)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: StreamBuilder<List<ClaimRequest>>(
                                    stream: widget.itemService.getClaimRequestsForItem(item.id),
                                    builder: (context, claimSnapshot) {
                                      if (claimSnapshot.connectionState == ConnectionState.waiting) {
                                        return const LinearProgressIndicator();
                                      }
                                      final claims = claimSnapshot.data ?? [];
                                      print('Loaded ${claims.length} claims for item ${item.id}');
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Claim Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          if (claims.isEmpty)
                                            const Text('No claim requests yet'),
                                          ...claims.map((claim) => Card(
                                            color: claim.status == 'pending' ? Colors.yellow[50] : (claim.status == 'approved' ? Colors.green[50] : Colors.red[50]),
                                            child: ListTile(
                                              title: Text('By: ${claim.claimantUserId}'),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Answer: ${claim.answer != null && claim.answer!.isNotEmpty ? claim.answer : '(No answer provided)'}'),
                                                  if (claim.photoUrl != null && claim.photoUrl!.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Image.network(claim.photoUrl!, height: 80),
                                                    )
                                                  else
                                                    const Text('No photo provided'),
                                                  Text('Status: ${claim.status}'),
                                                ],
                                              ),
                                              trailing: claim.status == 'pending'
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.check, color: Colors.green),
                                                          onPressed: () async {
                                                            await widget.itemService.updateClaimRequestStatus(claim.id, 'approved');
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Claim approved!')),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.close, color: Colors.red),
                                                          onPressed: () async {
                                                            await widget.itemService.updateClaimRequestStatus(claim.id, 'rejected');
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Claim rejected.')),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    )
                                                  : Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (claim.status == 'approved')
                                                          IconButton(
                                                            icon: const Icon(Icons.chat),
                                                            tooltip: 'Chat',
                                                            onPressed: () async {
                                                              final chatId = await widget.itemService.createChatIfNotExists(
                                                                itemId: item.id,
                                                                userA: item.userId,
                                                                userB: claim.claimantUserId,
                                                              );
                                                              if (context.mounted) {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => ChatScreen(
                                                                      chatId: chatId,
                                                                      currentUserId: widget.userId,
                                                                      otherUserId: claim.claimantUserId == widget.userId ? item.userId : claim.claimantUserId,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                            ),
                                          )),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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

// Placeholder for potential matches UI
List<Widget> _buildPotentialMatchesPlaceholder(Item item) {
  // This will be replaced with real backend data
  // For now, show a static example if item.category == 'Electronics'
  if (item.category == 'Electronics') {
    return [
      Card(
        color: Colors.blue[50],
        child: ListTile(
          leading: const Icon(Icons.link),
          title: const Text('Found Phone at Main Gate'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Similarity: 0.82'),
              Text('Reason: Category, location, and date match'),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () {},
            child: const Text('Review'),
          ),
        ),
      ),
    ];
  }
  return [const Text('No potential matches yet.')];
} 