import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  final CardRepository _cardRepo = CardRepository();
  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _folderRepo.getAllFolders();
    final Map<int, int> counts = {};
    for (var f in folders) {
      counts[f.id!] = await _cardRepo.getCardCountByFolder(f.id!);
    }
    setState(() {
      _folders = folders;
      _cardCounts = counts;
    });
  }

  Future<void> _addFolder() async {
    String? selectedSuit;
    final existingNames = _folders.map((f) => f.folderName).toSet();
    final availableSuits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
        .where((s) => !existingNames.contains(s))
        .toList();

    if (availableSuits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All 4 suit folders already exist.')),
      );
      return;
    }

    selectedSuit = availableSuits.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Folder'),
          content: DropdownButtonFormField<String>(
            value: selectedSuit,
            decoration: const InputDecoration(labelText: 'Suit'),
            items: availableSuits
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setDialogState(() => selectedSuit = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedSuit != null) {
      await _folderRepo.insertFolder(Folder(
        folderName: selectedSuit!,
        timestamp: DateTime.now().toIso8601String(),
      ));
      _loadFolders();
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
            'Deleting "${folder.folderName}" will remove all ${_cardCounts[folder.id!] ?? 0} cards. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _folderRepo.deleteFolder(folder.id!);
      _loadFolders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder "${folder.folderName}" deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Organizer')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        tooltip: 'Add folder',
        child: const Icon(Icons.create_new_folder),
      ),
      body: _folders.isEmpty
          ? const Center(child: Text('No folders yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final count = _cardCounts[folder.id!] ?? 0;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardsScreen(folder: folder)),
                      );
                      _loadFolders();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getSuitSymbol(folder.folderName),
                            style: TextStyle(
                              fontSize: 48,
                              color: _getSuitColor(folder.folderName),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            folder.folderName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$count card${count == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFolder(folder),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getSuitSymbol(String suit) {
    switch (suit) {
      case 'Hearts':   return '♥';
      case 'Diamonds': return '♦';
      case 'Clubs':    return '♣';
      case 'Spades':   return '♠';
      default:         return '?';
    }
  }

  Color _getSuitColor(String suit) {
    switch (suit) {
      case 'Hearts':
      case 'Diamonds':
        return Colors.red;
      case 'Clubs':
      case 'Spades':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
