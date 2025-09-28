import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:domyturn/features/auth/data/models/chore_model.dart';
import 'package:domyturn/features/auth/data/models/user_model.dart';
import 'package:domyturn/features/auth/data/repositories/chores_repository.dart';
import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:logger/logger.dart';

final logger = Logger(printer: PrettyPrinter());

class EditChoreScreen extends StatefulWidget {
  final int choreId;

  const EditChoreScreen({super.key, required this.choreId});

  @override
  State<EditChoreScreen> createState() => _EditChoreScreenState();
}

class _EditChoreScreenState extends State<EditChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _choresRepository = ChoresRepository();
  final _userRepository = UserRepository();

  List<User> _users = [];
  final List<User> _selectedAssignees = [];

  TaskType? _selectedTaskType;
  int? _selectedFrequency;
  DateTime? _startDate;
  bool _repeatIfAbsent = false;
  bool _isPaymentChore = false;
  bool _isLoading = true;
  bool _updateAssigneeOrder = false;

  int? _homeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chore = await _choresRepository.fetchTaskById(widget.choreId);
    final users = await _userRepository.fetchUsers();

    _isPaymentChore = chore.paymentTask ?? false;

    setState(() {
      _users = users;
      _homeId = chore.homeId;
      _titleController.text = chore.title;
      _descController.text = chore.description ?? '';
      _selectedTaskType = chore.taskType;
      _selectedFrequency = chore.frequency;
      _repeatIfAbsent = chore.repeatIfAbsent;
      _startDate = chore.startDate;
      _selectedAssignees.addAll(users.where((u) => chore.assignees.contains(u.id)));
      _isLoading = false;
    });
  }

  void _toggleAssignee(User user) {
    setState(() {
      _selectedAssignees.contains(user)
          ? _selectedAssignees.remove(user)
          : _selectedAssignees.add(user);
    });
  }

  String _getAssigneeLabel(User user) {
    final index = _selectedAssignees.indexOf(user);
    return index != -1 ? '#${index + 1}' : '';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormatter = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Chore')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
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

                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<TaskType>(
                            value: _selectedTaskType,
                            items: TaskType.values
                                .map((type) =>
                                DropdownMenuItem(value: type, child: Text(type.name)))
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Update Assignee Order', style: textTheme.titleMedium),
                              Checkbox(
                                value: _updateAssigneeOrder,
                                onChanged: (val) =>
                                    setState(() => _updateAssigneeOrder = val ?? false),
                              ),
                            ],
                          ),

                          if (_updateAssigneeOrder) ...[
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
                                      label: Text(
                                        user.name.length > 10
                                            ? "${user.name.substring(0, 10)}…"
                                            : user.name,
                                      ),
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
                          ],

                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _startDate == null
                                  ? 'Select Start Date'
                                  : 'Start: ${dateFormatter.format(_startDate!)}',
                              style: textTheme.bodyLarge,
                            ),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () => _pickDate(context),
                          ),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Repeat if Absent'),
                            value: _repeatIfAbsent,
                            onChanged: (val) => setState(() => _repeatIfAbsent = val),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Is Payment Chore'),
                                Row(
                                  children: [
                                    if (_isPaymentChore)
                                      Icon(Icons.currency_rupee, color: Theme.of(context).colorScheme.primary),
                                    Switch(
                                      value: _isPaymentChore,
                                      onChanged: (val) => setState(() => _isPaymentChore = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (_selectedTaskType == TaskType.GAP)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: DropdownButtonFormField<int>(
                                value: (_selectedFrequency != null &&
                                    _selectedFrequency! >= 1 &&
                                    _selectedFrequency! <= 10)
                                    ? _selectedFrequency
                                    : null,
                                items: List.generate(
                                  10,
                                      (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text('${index + 1} day${index == 0 ? '' : 's'}'),
                                  ),
                                ),
                                onChanged: (val) =>
                                    setState(() => _selectedFrequency = val),
                                decoration: const InputDecoration(
                                  labelText: 'Frequency (in days)',
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

                          Center(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Update Chore'),
                              onPressed: () async {

                                final titleText = _titleController.text.trim();
                                final descText = _descController.text.trim();

                                if (titleText.length > 50) {
                                  GlobalScaffold.showSnackbar('Title cannot exceed 50 characters',type: SnackbarType.error);
                                  return;
                                }

                                if (descText.length > 1000) {
                                  GlobalScaffold.showSnackbar('Description cannot exceed 1000 characters',type: SnackbarType.error);
                                  return;
                                }
                                if (_formKey.currentState!.validate()) {
                                  if (_startDate == null) {
                                    GlobalScaffold.showSnackbar('Start date is required',type: SnackbarType.error);
                                    return;
                                  }
                                  if (_selectedAssignees.isEmpty) {
                                    GlobalScaffold.showSnackbar('Please select at least one assignee',type: SnackbarType.error);
                                    return;
                                  }

                                  final chore = {
                                    "id": widget.choreId,
                                    "title": _titleController.text.trim(),
                                    "description": _descController.text.trim(),
                                    "taskType": _selectedTaskType!.name,
                                    "assignees": _selectedAssignees.map((u) => u.id).toList(),
                                    "frequency": _selectedTaskType == TaskType.GAP
                                        ? _selectedFrequency
                                        : null,
                                    "startDate": _startDate!.toIso8601String(),
                                    "repeatIfAbsent": _repeatIfAbsent,
                                    "homeId": _homeId,
                                    "updateAssigneeOrder": _updateAssigneeOrder,
                                    "paymentTask": _isPaymentChore,
                                  };

                                  await _choresRepository.updateTask(chore);
                                  if (context.mounted)
                                  {
                                    GlobalScaffold.showSnackbar('Chore updated successfully',type: SnackbarType.success);
                                    Navigator.pop(context, true);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete Chore"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Chore"),
        content: const Text("Are you sure you want to delete this chore?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await _choresRepository.deleteTask(widget.choreId);
      if (context.mounted)
      {
        GlobalScaffold.showSnackbar('Chore deleted successfully',type: SnackbarType.success);
        Navigator.pop(context, true);
      }
    }
  }
}
