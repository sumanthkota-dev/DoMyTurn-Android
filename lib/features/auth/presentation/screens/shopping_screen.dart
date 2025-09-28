import 'package:domyturn/features/auth/presentation/screens/purchased_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:domyturn/features/auth/presentation/screens/shopping_update_screen.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_repository.dart';
import 'shopping_create_screen.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with TickerProviderStateMixin {
  final ShoppingRepository _repository = ShoppingRepository();
  late Future<List<ShoppingItem>> _unboughtFuture = Future.value([]);
  late Future<List<ShoppingItem>> _boughtFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _unboughtFuture = _repository.fetchUnboughtItems();
      _boughtFuture = _repository.fetchBoughtItems();
    });
  }

  Future<void> _navigateToCreateList({ShoppingItem? initialItem}) async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingCreateScreen(item: initialItem),
      ),
    );
    if (created == true) _loadItems();
  }

  Future<void> _deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shopping list deleted")),
      );
      _loadItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  Widget _buildSwipeBackground({
    required IconData icon,
    required Color color,
    required Alignment alignment,
  }) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item, ThemeData theme) {
    return Card(
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      margin: EdgeInsets.zero,
      shadowColor: theme.cardTheme.shadowColor,
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.15,
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth - 40,
                      child: Text(
                        item.listName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: item.items.length,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, i) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: const VisualDensity(vertical: -1),
                      leading: Icon(Icons.shopping_bag_outlined, size: 20, color: theme.colorScheme.primary),
                      title: Text(
                        item.items[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.6,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 16,
              child: Icon(Icons.shopping_cart, color: theme.colorScheme.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Shopping"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Shopping Lists"),
              Tab(text: "Purchased"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToCreateList(),
          icon: const Icon(Icons.add),
          label: const Text("New List"),
        ),
        body: TabBarView(
          children: [
            _ShoppingListsWidget(
              future: _unboughtFuture,
              theme: theme,
              onEdit: (item) => _navigateToCreateList(initialItem: item),
              onDelete: (id) => _deleteItem(id),
              onUpdated: _loadItems,
            ),
            _PurchasedItemsWidget(
              future: _boughtFuture,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ShoppingListsWidget({
    required Future<List<ShoppingItem>> future,
    required ThemeData theme,
    required Future<void> Function(int) onDelete,
    required void Function(ShoppingItem) onEdit,
    required VoidCallback onUpdated,
  }) {
    return FutureBuilder<List<ShoppingItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Failed to load items"));

        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyPlaceholder(theme);

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            final card = GestureDetector(
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingUpdateScreen(item: item)),
                );
                if (updated == true) onUpdated();
              },
              child: _buildItemCard(item, theme),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                child: Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.horizontal,
                  background: _buildSwipeBackground(
                    icon: Icons.edit,
                    color: Colors.orange,
                    alignment: Alignment.centerLeft,
                  ),
                  secondaryBackground: _buildSwipeBackground(
                    icon: Icons.delete,
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      onEdit(item);
                      return false;
                    } else if (direction == DismissDirection.endToStart) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Confirmation"),
                          content: const Text("Are you sure you want to delete this shopping list?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Delete", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && item.id != null) {
                        await onDelete(item.id!);
                        return true;
                      }
                    }
                    return false;
                  },
                  child: card,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _PurchasedItemsWidget({
    required Future<List<ShoppingItem>> future,
    required ThemeData theme,
  }) {
    return FutureBuilder<List<ShoppingItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Failed to load items"));

        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyPlaceholder(theme);

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchasedDetailScreen(item: item),
                  ),
                );
              },
              child: _buildPurchasedCard(item, theme),
            );
          },
        );
      },
    );
  }

  Widget _buildPurchasedCard(ShoppingItem item, ThemeData theme) {
    final boughtItems = item.boughtItems ?? [];
    final visibleItems = boughtItems.take(2).toList();

    return Card(
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: theme.cardTheme.shadowColor,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded( // or Flexible
                  child: Text(
                    item.listName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...visibleItems.map(
                  (bought) => ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.shopping_bag, size: 20, color: theme.colorScheme.primary),
                title: Text(
                  bought,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (boughtItems.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "+${boughtItems.length - 2} more...",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            "Got shopping plans today?",
            style: TextStyle(fontSize: 16, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
