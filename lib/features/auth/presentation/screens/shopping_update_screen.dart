import 'package:flutter/material.dart';
import '../../../../core/session/app_session.dart';
import '../../data/models/shopping_list_update.dart';
import '../../data/repositories/shopping_repository.dart';
import '../../data/models/shopping_item_model.dart';

class ShoppingUpdateScreen extends StatefulWidget {
  final ShoppingItem item;

  const ShoppingUpdateScreen({super.key, required this.item});

  @override
  State<ShoppingUpdateScreen> createState() => _ShoppingUpdateScreenState();
}

class _ShoppingUpdateScreenState extends State<ShoppingUpdateScreen>
    with SingleTickerProviderStateMixin {
  late List<bool> _isItemChecked;
  final ShoppingRepository _repository = ShoppingRepository();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    assert(widget.item.id != null, 'Item id cannot be null');
    _isItemChecked = List<bool>.filled(widget.item.items.length, false);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _getSelectedItems() {
    final selected = <String>[];
    for (int i = 0; i < _isItemChecked.length; i++) {
      if (_isItemChecked[i]) selected.add(widget.item.items[i]);
    }
    return selected;
  }

  Future<void> _markAsBought() async {
    setState(() => _isSubmitting = true);
    try {
      final boughtItems = <String>[];
      final unboughtItems = <String>[];

      for (int i = 0; i < _isItemChecked.length; i++) {
        final itemName = widget.item.items[i];
        if (_isItemChecked[i]) {
          boughtItems.add(itemName);
        } else {
          unboughtItems.add(itemName);
        }
      }
      final homeId = await AppSession.instance.homeId;
      final update = ShoppingListUpdate(
        id: widget.item.id!,
        boughtItems: boughtItems,
        unBoughtItems: unboughtItems,
        homeId: homeId!,
      );
      await _repository.markAsBought(update);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updated shopping list")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to update items"),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _markAsBought,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final selectedCount = _isItemChecked.where((v) => v).length;
    final total = _isItemChecked.length;
    final progress = total == 0 ? 0.0 : selectedCount / total;

    return Scaffold(
      appBar: AppBar(title: Text("Shopping Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _animation,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Text(
                    item.listName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Shopping progress',
                    value: '${(progress * 100).round()} percent completed',
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: item.items.length,
                      itemBuilder: (context, index) {
                        return CheckboxListTile(
                          key: Key('checkbox_item_$index'),
                          value: _isItemChecked[index],
                          title: Text(
                            item.items[index],
                            style: theme.textTheme.bodyLarge,
                          ),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() => _isItemChecked[index] = val ?? false);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$selectedCount of $total selected",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Mark as Bought"),
                        onPressed: selectedCount > 0 && !_isSubmitting
                            ? _markAsBought
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
