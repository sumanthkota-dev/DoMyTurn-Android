import 'package:domyturn/features/auth/data/models/chore_model.dart';
import 'package:domyturn/features/auth/data/models/user_model.dart';
import 'package:domyturn/features/auth/data/repositories/chores_repository.dart';
import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/utils/global_scaffold.dart';

class CreateChoreScreen extends StatefulWidget {
  const CreateChoreScreen({super.key});

  @override
  State<CreateChoreScreen> createState() => _CreateChoreScreenState();
}

class _CreateChoreScreenState extends State<CreateChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final SecureStorageService _storageService = SecureStorageService();
  final ChoresRepository choresRepository = ChoresRepository();
  final UserRepository _userRepository = UserRepository();

  TaskType? _selectedTaskType;
  int? _selectedFrequency;
  DateTime? _startDate;
  bool _repeatIfAbsent = false;
  bool _isPaymentTask = false;


  List<User> _users = [];
  final List<User> _selectedAssignees = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await _userRepository.fetchUsers();
      setState(() => _users = fetchedUsers);
    } catch (e) {
      debugPrint("Failed to fetch users: $e");
    }
  }

  void _toggleAssignee(User user) {
    setState(() {
      if (_selectedAssignees.contains(user)) {
        _selectedAssignees.remove(user);
      } else {
        _selectedAssignees.add(user);
      }
    });
  }

  String _getAssigneeLabel(User user) {
    final index = _selectedAssignees.indexOf(user);
    return index != -1 ? '#${index + 1}' : '';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormatter = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Create Chore'),
            if (_isPaymentTask) ...[
              const SizedBox(width: 8),
              const Icon(Icons.currency_rupee),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chore Details', style: textTheme.titleLarge),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description (optional)
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Task Type Dropdown
                      DropdownButtonFormField<TaskType>(
                        value: _selectedTaskType,
                        items: TaskType.values
                            .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedTaskType = value),
                        decoration: const InputDecoration(
                          labelText: 'Task Type',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                        value == null ? 'Please select a task type' : null,
                      ),
                      const SizedBox(height: 24),

                      // Assignees
                      Text('Assignees (in order)', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _users.map((user) {
                          final isSelected = _selectedAssignees.contains(user);
                          final orderLabel = _getAssigneeLabel(user);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              FilterChip(
                                label: Text(user.name.length > 10
                                    ? "${user.name.substring(0, 10)}…"
                                    : user.name),
                                selected: isSelected,
                                onSelected: (_) => _toggleAssignee(user),
                                selectedColor: colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : null,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: -12,
                                  right: -12,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: colorScheme.primary,
                                    child: Text(
                                      orderLabel.replaceAll('#', ''),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Start Date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _startDate == null
                              ? 'Select Start Date'
                              : 'Start: ${dateFormatter.format(_startDate!)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _pickDate(context),
                      ),

                      // Repeat if Absent
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Repeat if Absent'),
                        value: _repeatIfAbsent,
                        onChanged: (val) => setState(() => _repeatIfAbsent = val),
                      ),

                      // Is Payment Task
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Is Payment Task'),
                            Row(
                              children: [
                                if (_isPaymentTask)
                                  Icon(Icons.currency_rupee, color: colorScheme.primary),
                                Switch(
                                  value: _isPaymentTask,
                                  onChanged: (val) => setState(() => _isPaymentTask = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Frequency Dropdown for GAP task
                      if (_selectedTaskType == TaskType.GAP)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: DropdownButtonFormField<int>(
                            value: _selectedFrequency,
                            items: [
                              const DropdownMenuItem(
                                value: 1,
                                child: Text('Every day'),
                              ),
                              const DropdownMenuItem(
                                value: 2,
                                child: Text('Every other day'),
                              ),
                              ...List.generate(
                                8,
                                    (index) => DropdownMenuItem(
                                  value: index + 3,
                                  child: Text('${index + 3} days'),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedFrequency = val),
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (_selectedTaskType == TaskType.GAP && val == null) {
                                return 'Please select frequency';
                              }
                              return null;
                            },
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Submit Button
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Create Chore'),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final title = _titleController.text.trim();
                            final description = _descController.text.trim();

                            if (title.length > 50) {
                              GlobalScaffold.showSnackbar(
                                'Title can\'t be more than 50 characters',
                                type: SnackbarType.error,
                              );
                              return;
                            }

                            if (description.length > 1000) {
                              GlobalScaffold.showSnackbar(
                                'Description can\'t be more than 1000 characters',
                                type: SnackbarType.error,
                              );
                              return;
                            }
                            if (_startDate == null) {
                              GlobalScaffold.showSnackbar(
                                'Please select a start date',
                                type: SnackbarType.error,
                              );

                              return;
                            }
                            if (_selectedAssignees.isEmpty) {
                              GlobalScaffold.showSnackbar(
                                'Please select at least one assignee',
                                type: SnackbarType.error,
                              );

                              return;
                            }

                            final homeIdStr = await _storageService.readValue('homeId');
                            if (homeIdStr == null) return;

                            final chore = Chore(
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              homeId: int.parse(homeIdStr),
                              taskType: _selectedTaskType!,
                              assignees: _selectedAssignees.map((u) => u.id).toList(),
                              completedUsers: {},
                              lastCompletedBy: null,
                              performer: null,
                              startDate: _startDate,
                              dueDate: null, // Removed due date logic
                              repeatIfAbsent: _repeatIfAbsent,
                              isOverDue: false,
                              frequency: _selectedTaskType == TaskType.GAP
                                  ? _selectedFrequency
                                  : null,
                              paymentTask: _isPaymentTask, // Add this if your model supports it
                            );

                            final success = await choresRepository.createTask(chore);
                            if (success) {
                              GlobalScaffold.showSnackbar("Chore created successfully",type: SnackbarType.success);
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
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
