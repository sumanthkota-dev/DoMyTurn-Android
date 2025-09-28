import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/logout_util.dart';
import '../../data/repositories/home_repository.dart';
import 'package:dio/dio.dart';

class CreateJoinHomeScreen extends StatefulWidget {
  const CreateJoinHomeScreen({super.key});

  @override
  State<CreateJoinHomeScreen> createState() => _CreateJoinHomeScreenState();
}

class _CreateJoinHomeScreenState extends State<CreateJoinHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _joinCodeController = TextEditingController();
  final _homeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  final HomeRepository _homeRepo = HomeRepository();
  final Dio _dio = Dio();

  bool _loading = false;
  bool _showCreateForm = false;
  bool _fetchingCountries = true;
  List<String> _countries = [];
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = "India";
    // _detectCountryFromLocation();
  }

  // Future<void> _detectCountryFromLocation() async {
  //   try {
  //     final permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
  //
  //     final position = await Geolocator.getCurrentPosition();
  //     final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  //
  //     if (placemarks.isNotEmpty) {
  //       final country = placemarks.first.country;
  //       if (country != null && _countries.contains(country)) {
  //         setState(() => _selectedCountry = country);
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Location error: $e");
  //   }
  // }

  Future<void> _createHome() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await _homeRepo.createHome(
      _homeNameController.text.trim(),
      country: _selectedCountry ?? '',
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    final msg = success ? "Home created successfully" : "Failed to create home";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (success) GoRouter.of(context).go('/dashboard');
  }

  Future<void> _joinHome() async {
    if (_joinCodeController.text.isEmpty) return;
    setState(() => _loading = true);

    final success = await _homeRepo.joinHome(_joinCodeController.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    final msg = success ? "Joined home successfully" : "Failed to join home";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (success) GoRouter.of(context).go('/dashboard');
  }

  // Place this inside your `CreateJoinHomeScreen` class

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create / Join Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => LogoutUtil.confirmAndLogout(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _showCreateForm ? _buildCreateForm(theme) : _buildJoinCard(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinCard(ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      shadowColor: theme.cardTheme.shadowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Join Home",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _joinCodeController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    decoration: InputDecoration(
                      labelText: "Enter Code",
                      counterText: "",
                      border: const OutlineInputBorder(),
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _joinHome,
                    style: _buttonStyle(theme),
                    child: const Text("Join"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text("or", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).push('/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Join with QR"),
              style: _buttonStyle(theme),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
              label: const Text("Create New Home"),
              style: _buttonStyle(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 600, // ✅ prevents stretching too much on wide screens
        minWidth: screenWidth * 0.95, // ✅ ensures 95% width on small screens
      ),
      child: Card(
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        color: theme.cardTheme.color,
        shadowColor: theme.cardTheme.shadowColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _showCreateForm = false),
                    ),
                    Text(
                      "Create Home",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(_homeNameController, "Home Name"),
                _buildTextField(_addressController, "Address"),
                _buildTextField(_cityController, "City"),
                _buildTextField(_districtController, "District"),
                _buildTextField(_stateController, "State"),
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Pincode",
                    border: OutlineInputBorder(),
                    filled: false,
                  ),
                ),
                const SizedBox(height: 16),

                // Fixed Country Field
                TextFormField(
                  readOnly: true,
                  initialValue: "India",
                  decoration: const InputDecoration(
                    labelText: "Country",
                    border: OutlineInputBorder(),
                    filled: false,
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _createHome,
                  icon: const Icon(Icons.add_home_work),
                  label: const Text("Create Home"),
                  style: _buttonStyle(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: false,
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
