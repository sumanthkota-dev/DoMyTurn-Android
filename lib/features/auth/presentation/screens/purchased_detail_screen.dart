import 'package:flutter/material.dart';
import '../../data/models/shopping_item_model.dart';

class PurchasedDetailScreen extends StatelessWidget {
  final ShoppingItem item;

  const PurchasedDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boughtItems = item.boughtItems ?? [];
    final unboughtItems = item.unBoughtItems ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Details"),
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.listName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Purchased: ${boughtItems.length}   •   Unpurchased: ${unboughtItems.length}",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        thickness: 1,
                      ),
                      const SizedBox(height: 20),

                      if (boughtItems.isNotEmpty) ...[
                        Center(
                          child: Text(
                            "Bought Items",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...boughtItems.mapIndexed((i, boughtItem) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      boughtItem,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary, size: 20),
                                ],
                              ),
                            ),
                            if (i != boughtItems.length - 1)
                              Divider(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.15),
                                thickness: 0.5,
                              ),
                          ],
                        )),
                        const SizedBox(height: 28),
                      ],

                      if (unboughtItems.isNotEmpty) ...[
                        Center(
                          child: Text(
                            "Unbought Items",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...unboughtItems.mapIndexed((i, item) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.cancel_outlined,
                                      color: theme.colorScheme.error, size: 20),
                                ],
                              ),
                            ),
                            if (i != unboughtItems.length - 1)
                              Divider(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.12),
                                thickness: 0.5,
                              ),
                          ],
                        )),
                      ],

                      const SizedBox(height: 32),
                      Divider(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                        thickness: 0.7,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "--- End of Bill ---",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.outline,
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

// Extension to support mapIndexed
extension on Iterable {
  Iterable<T> mapIndexed<T>(T Function(int, dynamic) f) sync* {
    var index = 0;
    for (final value in this) {
      yield f(index++, value);
    }
  }
}
