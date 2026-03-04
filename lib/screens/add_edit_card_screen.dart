import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/playing_card.dart';
import '../repositories/card_repository.dart';

class AddEditCardScreen extends StatefulWidget {
  final Folder folder;
  final PlayingCard? card;
  const AddEditCardScreen({super.key, required this.folder, this.card});

  @override
  _AddEditCardScreenState createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final CardRepository _cardRepo = CardRepository();

  // Valid card values in a standard deck
  static const List<String> _validCardValues = [
    'Ace', '2', '3', '4', '5', '6', '7',
    '8', '9', '10', 'Jack', 'Queen', 'King',
  ];

  static const List<String> _validSuits = [
    'Hearts', 'Diamonds', 'Clubs', 'Spades',
  ];

  static const Map<String, String> _valueToApiCode = {
    'Ace': 'A',
    '2': '2', '3': '3', '4': '4', '5': '5',
    '6': '6', '7': '7', '8': '8', '9': '9',
    '10': '0',
    'Jack': 'J', 'Queen': 'Q', 'King': 'K',
  };

  static const Map<String, String> _suitToApiCode = {
    'Hearts': 'H',
    'Diamonds': 'D',
    'Clubs': 'C',
    'Spades': 'S',
  };

  late String _selectedValue;
  late String _suit;
  bool _isSaving = false;
  List<PlayingCard> _existingCards = [];

  @override
  void initState() {
    super.initState();
    _suit = widget.folder.folderName;

    if (widget.card != null) {
      final nameParts = widget.card!.cardName.split(' ');
      _selectedValue = _validCardValues.contains(nameParts.first)
          ? nameParts.first
          : _validCardValues.first;
    } else {
      _selectedValue = _validCardValues.first;
    }

    _loadExistingCards();
  }

  Future<void> _loadExistingCards() async {
    final cards = await _cardRepo.getCardsByFolderId(widget.folder.id!);
    setState(() => _existingCards = cards);
  }

  String get _cardName => '$_selectedValue of $_suit';

  /// Builds the Deck of Cards API image URL
  String get _imageUrl {
    final v = _valueToApiCode[_selectedValue];
    final s = _suitToApiCode[_suit];
    if (v != null && s != null) {
      return 'https://deckofcardsapi.com/static/img/$v$s.png';
    }
    return '';
  }

  /// Returns true if this value already exists in the folder
  /// (ignores current card when editing)
  bool _isDuplicate() {
    return _existingCards.any((c) =>
        c.cardName == _cardName && c.id != widget.card?.id);
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isDuplicate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_cardName already exists in ${widget.folder.folderName}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newCard = PlayingCard(
        id: widget.card?.id,
        cardName: _cardName,
        suit: _suit,
        imageUrl: _imageUrl,
        folderId: widget.folder.id!,
      );

      if (widget.card == null) {
        await _cardRepo.insertCard(newCard);
      } else {
        await _cardRepo.updateCard(newCard);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getSuitColor(String suit) {
    return (suit == 'Hearts' || suit == 'Diamonds') ? Colors.red : Colors.black;
  }

  IconData _getSuitIcon(String suit) {
    switch (suit) {
      case 'Hearts':   return Icons.favorite;
      case 'Diamonds': return Icons.change_history;
      case 'Clubs':    return Icons.filter_vintage;
      case 'Spades':   return Icons.eco;
      default:         return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Card' : 'Add Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card image preview
              Center(
                child: Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl.isNotEmpty
                      ? Image.network(
                          _imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) => progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (ctx, _, __) =>
                              const Center(child: Icon(Icons.broken_image, size: 48)),
                        )
                      : const Center(child: Icon(Icons.image, size: 48)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _cardName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getSuitColor(_suit),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card value dropdown
              DropdownButtonFormField<String>(
                value: _selectedValue,
                decoration: const InputDecoration(
                  labelText: 'Card Value',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style),
                ),
                items: _validCardValues
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedValue = v);
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select a card value' : null,
              ),
              const SizedBox(height: 16),

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Suit',
                  border: OutlineInputBorder(),
                  helperText: 'Suit is determined by the folder',
                ),
                child: Row(
                  children: [
                    Icon(_getSuitIcon(_suit),
                        color: _getSuitColor(_suit), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _suit,
                      style: TextStyle(
                          fontSize: 16,
                          color: _getSuitColor(_suit),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCard,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Update Card' : 'Add Card'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
