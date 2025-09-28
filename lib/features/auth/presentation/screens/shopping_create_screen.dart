import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/repositories/shopping_repository.dart';

class ShoppingCreateScreen extends StatefulWidget {
  final ShoppingItem? item;

  const ShoppingCreateScreen({super.key, this.item});

  @override
  State<ShoppingCreateScreen> createState() => _ShoppingCreateScreenState();
}

class _ShoppingCreateScreenState extends State<ShoppingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listNameController = TextEditingController();
  final _itemController = TextEditingController();
  final _listNameFocus = FocusNode();
  final _itemFocus = FocusNode();

  final _items = <String>[];
  final _repository = ShoppingRepository();
  final _storage = SecureStorageService();

  bool _isEditingListName = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _listNameController.text = widget.item!.listName;
      _items.addAll(widget.item!.items);
      _isEditingListName = false;
    }
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty)
    {
      GlobalScaffold.showSnackbar("Item cannot be empty",type: SnackbarType.error);
    } else if (text.length > 50) {
      GlobalScaffold.showSnackbar("Item cannot exceed 50 characters",type: SnackbarType.error);
    } else if (_items.contains(text)) {
      GlobalScaffold.showSnackbar("Item already exists",type: SnackbarType.error);
    } else {
      setState(() {
        _items.add(text);
        _itemController.clear();
        HapticFeedback.mediumImpact();
      });
    }
  }


  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    final listName = _listNameController.text.trim();
    final homeIdStr = await _storage.readValue('homeId');

    if (_items.isEmpty) {
      if (widget.item != null && widget.item!.items.length == 1) {
        await _repository.deleteItem(widget.item!.id!);
        GlobalScaffold.showSnackbar("Shopping list deleted",type: SnackbarType.success);
        if (mounted) Navigator.pop(context, true);
      } else {
        GlobalScaffold.showSnackbar("Please add at least one item",type: SnackbarType.error);
      }
      return;
    }

    if (homeIdStr == null || homeIdStr.isEmpty) {
      GlobalScaffold.showSnackbar("Home ID is missing",type: SnackbarType.error);
      return;
    }

    try {
      final shoppingItem = ShoppingItem(
        id: widget.item?.id,
        listName: listName,
        items: _items,
        bought: widget.item?.bought ?? false,
        homeId: widget.item?.homeId ?? int.parse(homeIdStr),
      );

      if (widget.item == null) {
        await _repository.createItem(shoppingItem);
        GlobalScaffold.showSnackbar("Shopping list created",type: SnackbarType.success);
      } else {
        await _repository.updateItem(shoppingItem);
        GlobalScaffold.showSnackbar("Shopping list updated",type: SnackbarType.success);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      GlobalScaffold.showSnackbar("Error",type: SnackbarType.error);
    }
  }

  Widget _buildListNameTile(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      child: ListTile(
        title: _isEditingListName
            ? TextFormField(
          controller: _listNameController,
          focusNode: _listNameFocus,
          maxLength: 50,
          buildCounter: (
              BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) => null,
          decoration: const InputDecoration(
            hintText: "Enter list name",
            border: InputBorder.none,
          ),
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'List name is required' : null,
        )
            : Text(
          _listNameController.text,
          style: theme.textTheme.titleLarge,
        ),
        trailing: IconButton(
          icon: Icon(
            _isEditingListName ? Icons.check : Icons.edit,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            if (_isEditingListName) {
              if (_listNameController.text.trim().isEmpty) {
                GlobalScaffold.showSnackbar("List name cannot be empty",type: SnackbarType.error);
              } else {
                setState(() => _isEditingListName = false);
              }
            } else {
              setState(() {
                _isEditingListName = true;
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                _listNameFocus.requestFocus();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildItemTile(String item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      child: ListTile(
        title: Text(item),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _items.remove(item);
              HapticFeedback.mediumImpact();
            });
          },
        ),
      ),
    );
  }

  Widget _buildAddItemTile(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      child: ListTile(
        title: TextField(
          controller: _itemController,
          focusNode: _itemFocus,
          decoration: const InputDecoration(
            hintText: "Add Item",
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _addItem(),
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
          onPressed: _addItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEditMode ? "Edit Shopping List" : "Create Shopping List",
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildListNameTile(theme),
                      const Divider(height: 1),
                      if (_items.isNotEmpty)
                        ..._items.map((item) => _buildItemTile(item, theme)),
                      const Divider(height: 1),
                      _buildAddItemTile(theme),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FilledButton.icon(
                          icon: Icon(isEditMode ? Icons.save_as : Icons.save),
                          label: Text(isEditMode ? "Update List" : "Save List"),
                          onPressed: _saveList,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
