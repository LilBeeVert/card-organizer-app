import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import 'add_edit_card_screen.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({super.key, required this.folder});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository _cardRepo = CardRepository();
  final FolderRepository _folderRepo = FolderRepository();
  List<PlayingCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await _cardRepo.getCardsByFolderId(widget.folder.id!);
    setState(() => _cards = cards);
  }

  /// Navigate to add screen and refresh if a card was saved
  Future<void> _addCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCardScreen(folder: widget.folder),
      ),
    );
    if (result == true) _loadCards();
  }

  /// Navigate to edit screen and refresh if the card was updated
  Future<void> _editCard(PlayingCard card) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCardScreen(folder: widget.folder, card: card),
      ),
    );
    if (result == true) _loadCards();
  }

  Future<void> _deleteCard(PlayingCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.cardName}"?'),
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
      await _cardRepo.deleteCard(card.id!);
      _loadCards();
    }
  }

  Future<void> _deleteFolder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
            'Deleting "${widget.folder.folderName}" will remove all ${_cards.length} cards. This cannot be undone.'),
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
      await _folderRepo.deleteFolder(widget.folder.id!);
      if (mounted) Navigator.pop(context, true); // signal FoldersScreen to refresh
    }
  }

  String _getCardImageUrl(PlayingCard card) {
    const valueMap = {
      'Ace': 'A',
      '2': '2', '3': '3', '4': '4', '5': '5',
      '6': '6', '7': '7', '8': '8', '9': '9',
      '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K',
    };
    const suitMap = {
      'Hearts': 'H', 'Diamonds': 'D', 'Clubs': 'C', 'Spades': 'S',
    };

    final rawValue = card.cardName.split(' ').first;
    final value = valueMap[rawValue];
    final suit = suitMap[card.suit];

    if (value != null && suit != null) {
      return 'https://deckofcardsapi.com/static/img/$value$suit.png';
    }
    return card.imageUrl ?? '';
  }

  Widget _buildCardImage(PlayingCard card) {
    final url = _getCardImageUrl(card);
    if (url.isEmpty) {
      return const Center(child: Icon(Icons.image, size: 40));
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image, size: 40)),
    );
  }

  Color _getSuitColor(String suit) {
    return (suit == 'Hearts' || suit == 'Diamonds') ? Colors.red : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Delete folder',
            onPressed: _deleteFolder,
          ),
        ],
      ),
      // Opens AddEditCardScreen for a new card
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        tooltip: 'Add card',
        child: const Icon(Icons.add),
      ),
      body: _cards.isEmpty
          ? const Center(
              child: Text(
                'No cards in this folder.\nTap + to add one.',
                textAlign: TextAlign.center,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // Tap anywhere on the card to edit it
                    onTap: () => _editCard(card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildCardImage(card),
                          ),
                        ),
                        SizedBox(
                          height: 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.cardName,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                card.suit,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getSuitColor(card.suit),
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteCard(card),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
