import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import 'package:domyturn/features/auth/data/models/user_model.dart';
import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:domyturn/features/auth/data/repositories/auth_repository.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/utils/logout_util.dart';
import '../../data/models/home_model.dart';
import '../../data/repositories/home_repository.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBack;
  const ProfileScreen({super.key, this.showBack = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();

  bool isEditing = false;
  bool editingName = false;
  bool editingEmail = false;
  bool isSaving = false;
  String avatarSvg = '';
  DateTime? selectedDob;
  String selectedGender = 'Male';
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  User? currentUser;
  Home? home;
  bool isHomeLoading = true;

  final HomeRepository _homeRepository = HomeRepository();


  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadHome();
  }

  Future<void> _loadHome() async {
    try {
      final fetchedHome = await _homeRepository.fetchHomeDetails();
      setState(() {
        home = fetchedHome;
        isHomeLoading = false;
      });
    } catch (e) {
      setState(() => isHomeLoading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.fetchUserDetails();
    setState(() {
      currentUser = user;
      avatarSvg = user.avatarSvg?.isNotEmpty == true ? user.avatarSvg! : multiavatar(user.name);
    });
  }

  void _generateNewAvatar(String seed) {
    if (!isEditing) return;
    final newSvg = multiavatar(seed + Random().nextInt(999).toString());
    setState(() {
      avatarSvg = newSvg;
    });
  }

  void _enableEdit(User user) {
    setState(() {
      isEditing = true;
      editingName = false;
      editingEmail = false;
      nameCtrl.text = user.name;
      emailCtrl.text = user.email;
      mobileCtrl.text = user.mobile;
      selectedDob = user.dateOfBirth;
      selectedGender = genderOptions.contains(user.gender) ? user.gender : genderOptions[0];
    });
  }

  Future<void> _updateName() async {
    if (nameCtrl.text.trim() == currentUser?.name) {
      setState(() => editingName = false);
      return;
    }
    await _authRepository.updateUserName(nameCtrl.text.trim());
    if (!mounted) return;
   GlobalScaffold.showSnackbar("Name updated successfully",type: SnackbarType.success);
    _loadUser();
    setState(() => editingName = false);
  }

  Future<void> _updateEmail() async {
    final newEmail = emailCtrl.text.trim();

    if (newEmail == currentUser?.email) {
      setState(() => editingEmail = false);
      return;
    }

    final sendOtpResult = await _authRepository.sendOtp(newEmail);
    print(sendOtpResult.toString());

    if (sendOtpResult == 'MAX_ATTEMPTS_REACHED') {
      if (!mounted) return;
      GlobalScaffold.showSnackbar("Maximum OTP attempts reached. Please try later.",type: SnackbarType.error);
      return;
    }

    if (sendOtpResult != 'SUCCESS') {
      if (!mounted) return;
      GlobalScaffold.showSnackbar("Failed to send OTP. Please try again.",type: SnackbarType.error);
      return;
    }

    if (!mounted) return;
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final otpCtrl = TextEditingController(); // 👈 Now declared here

        return AlertDialog(
          title: const Text("Enter OTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the 6-digit OTP sent to your email."),
              const SizedBox(height: 16),
              PinCodeTextField(
                appContext: dialogContext,
                length: 6,
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                autoDismissKeyboard: true,
                animationType: AnimationType.scale,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 48,
                  fieldWidth: 40,
                  activeColor: theme.colorScheme.primary,
                  selectedColor: theme.colorScheme.primary.withOpacity(0.8),
                  inactiveColor: theme.colorScheme.outlineVariant,
                ),
                onChanged: (value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            FilledButton.icon(
              onPressed: () async {
                final otp = otpCtrl.text.trim();
                if (otp.length != 6) {
                  GlobalScaffold.showSnackbar("Enter complete 6-digit OTP",type: SnackbarType.error);
                  return;
                }
                await _authRepository.updateEmail(newEmail, otp);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                GlobalScaffold.showSnackbar("Email updated and token refreshed",type: SnackbarType.success);
                _loadUser();
                setState(() => editingEmail = false);
              },
              icon: const Icon(Icons.check),
              label: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }



  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    final updatedUser = currentUser!.copyWith(
      mobile: mobileCtrl.text.trim(),
      gender: selectedGender,
      dateOfBirth: selectedDob,
      avatarSvg: avatarSvg,
    );

    if (updatedUser == currentUser) {
      GlobalScaffold.showSnackbar("No changes detected",type: SnackbarType.success);
      return;
    }

    await _userRepository.updateUser(updatedUser);

    setState(() {
      currentUser = updatedUser;
      isEditing = false;
    });

    if (!mounted) return;
    GlobalScaffold.showSnackbar("Profile updated",type: SnackbarType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        title: const Text("Profile"),
        actions: [
          Tooltip(
            message: "Logout",
            child: IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => LogoutUtil.confirmAndLogout(context),
            ),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            adaptiveCardWrapper(_buildProfileCard(currentUser!)),
            const SizedBox(height: 16),
            if (isHomeLoading)
              const Center(child: CircularProgressIndicator())
            else if (home != null && home!.id != 0)
              adaptiveCardWrapper(_buildHomeCard(home!)),
            const SizedBox(height: 20),
            adaptiveCardWrapper(_buildConnectWithTeamCard()),
            const SizedBox(height: 20),
            _centeredDeleteButton(), // 👈 Add this here
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget adaptiveCardWrapper(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmall = screenWidth < 380;
        final horizontalPadding = isSmall ? 8.0 : 12.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyTile({required IconData icon, required String label, required String value}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildProfileCard(User user) {
    final theme = Theme.of(context);

    return Card(
      elevation: theme.cardTheme.elevation ?? 3,
      shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      shadowColor: theme.cardTheme.shadowColor ?? theme.shadowColor.withOpacity(0.15),
      margin: EdgeInsets.zero, // important
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _generateNewAvatar(user.name),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: SvgPicture.string(
                  avatarSvg,
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 👤 Name
            AnimatedCrossFade(
              firstChild: ListTile(
                leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                title: Text("Name", style: theme.textTheme.labelLarge),
                subtitle: Text(user.name, style: theme.textTheme.bodyLarge),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    nameCtrl.text = user.name;
                    setState(() => editingName = true);
                  },
                ),
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Edit Name", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      hintText: "Enter new name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => editingName = false),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _updateName,
                        icon: const Icon(Icons.check),
                        label: const Text("Update"),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: editingName ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 12),

            // 📧 Email
            AnimatedCrossFade(
              firstChild: ListTile(
                leading: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                title: Text("Email", style: theme.textTheme.labelLarge),
                subtitle: Text(user.email, style: theme.textTheme.bodyLarge),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    emailCtrl.text = user.email;
                    setState(() => editingEmail = true);
                  },
                ),
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Edit Email", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      hintText: "Enter new email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => editingEmail = false),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _updateEmail,
                        icon: const Icon(Icons.send),
                        label: const Text("Send OTP"),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: editingEmail ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const Divider(height: 32, thickness: 1.2),

            // 📝 Profile Form or read-only
            isEditing
                ? Form(
              key: _formKey,
              child: UserProfileForm(
                mobileCtrl: mobileCtrl,
                selectedDob: selectedDob,
                selectedGender: selectedGender,
                genderOptions: genderOptions,
                onDobChanged: (date) => setState(() => selectedDob = date),
                onGenderChanged: (val) => setState(() => selectedGender = val),
              ),
            )
                : Column(
              children: [
                _buildReadOnlyTile(icon: Icons.phone, label: "Mobile", value: user.mobile),
                _buildReadOnlyTile(icon: Icons.transgender, label: "Gender", value: user.gender),
                _buildReadOnlyTile(
                  icon: Icons.cake,
                  label: "Date of Birth",
                  value: user.dateOfBirth?.toIso8601String().split('T').first ?? "N/A",
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔘 Action Buttons (Responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: isEditing
                          ? TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                        label: const Text("Cancel", overflow: TextOverflow.ellipsis),
                        onPressed: () => setState(() => isEditing = false),
                      )
                          : FilledButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit Profile", overflow: TextOverflow.ellipsis),
                        onPressed: () => _enableEdit(user),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isEditing
                          ? FilledButton.icon(
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text("Save", overflow: TextOverflow.ellipsis),
                        onPressed: _saveChanges,
                      )
                          : OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset, size: 18),
                        label: const Text("Change Password", overflow: TextOverflow.ellipsis),
                        onPressed: _showChangePasswordBottomSheet,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(Home home) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => context.push('/home'),
      child: Card(
        elevation: theme.cardTheme.elevation ?? 2,
        shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        shadowColor: theme.cardTheme.shadowColor ?? theme.shadowColor.withOpacity(0.1),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          height: screenHeight * 0.11,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  'assets/images/transparent_home.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Icon(Icons.home_filled, size: 32, color: theme.colorScheme.outline),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        home.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              home.city ?? 'Unknown City',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "View Home →",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordBottomSheet() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final viewInsets = MediaQuery.of(context).viewInsets;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Change Password", style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 24),

                    // Old password
                    TextField(
                      controller: oldPwdCtrl,
                      obscureText: obscureOldPassword,
                      decoration: InputDecoration(
                        labelText: "Old Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureOldPassword = !obscureOldPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New password
                    TextField(
                      controller: newPwdCtrl,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextField(
                      controller: confirmPwdCtrl,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text("Change"),
                          onPressed: () async {
                            final oldPwd = oldPwdCtrl.text.trim();
                            final newPwd = newPwdCtrl.text.trim();
                            final confirmPwd = confirmPwdCtrl.text.trim();

                            if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                              GlobalScaffold.showSnackbar("All fields are required",type: SnackbarType.error);
                              return;
                            }

                            if (newPwd != confirmPwd) {
                              GlobalScaffold.showSnackbar("New passwords do not match",type: SnackbarType.error);
                              return;
                            }

                            try {
                              final result = await _authRepository.changePasswordSecure(oldPwd, newPwd);
                              if (!context.mounted) return;

                              switch (result) {
                                case 'SUCCESS':
                                  Navigator.pop(context);
                                  GlobalScaffold.showSnackbar("Password changed successfully",type: SnackbarType.success);
                                  break;

                                case 'INVALID_OLD_PASSWORD':
                                  GlobalScaffold.showSnackbar("Old password is incorrect",type: SnackbarType.error);
                                  break;

                                default:
                                  GlobalScaffold.showSnackbar("Something went wrong. Please try again.",type: SnackbarType.error);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              GlobalScaffold.showSnackbar("Unexpected error",type: SnackbarType.error);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConnectWithTeamCard() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      margin: EdgeInsets.zero, // 👈 important
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Connect with Us",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 12,
              children: [
                _buildSocialButton(Icons.language, "Website", "https://domyturn.app", isNarrow),
                _buildSocialButton(Icons.facebook, "Facebook", "https://facebook.com/domyturn", isNarrow),
                _buildSocialButton(Icons.camera_alt_outlined, "Instagram", "https://instagram.com/domyturn", isNarrow),
                _buildSocialButton(Icons.reviews_outlined, "Review Us", "https://play.google.com/store/apps/details?id=com.domyturn", isNarrow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, String url, bool isNarrow) {
    return SizedBox(
      width: isNarrow ? double.infinity : 160,
      child: FilledButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: () => _launchUrl(url),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }


  void _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      GlobalScaffold.showSnackbar("Could not open $urlString",type: SnackbarType.error);
    }
  }

  void _confirmDeleteAccount() {
    if (home != null) {
      // ❌ User is still in a home, prevent deletion
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cannot Delete Account"),
          content: const Text("Please leave your home before deleting your account."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This will permanently delete your account. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete"),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _authRepository.deleteUser();
                if (!mounted) return;
                await LogoutUtil.forceLogout(context);
              } catch (e) {
                if (!mounted) return;
                GlobalScaffold.showSnackbar("Error Logging Out",type: SnackbarType.error);
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _centeredDeleteButton() {
    return Center(
      child: SizedBox(
        width: 300,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            "Delete Account",
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _confirmDeleteAccount,
        ),
      ),
    );
  }


}

class UserProfileForm extends StatelessWidget {
  final TextEditingController mobileCtrl;
  final DateTime? selectedDob;
  final String selectedGender;
  final List<String> genderOptions;
  final ValueChanged<DateTime> onDobChanged;
  final ValueChanged<String> onGenderChanged;

  const UserProfileForm({
    super.key,
    required this.mobileCtrl,
    required this.selectedDob,
    required this.selectedGender,
    required this.genderOptions,
    required this.onDobChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: mobileCtrl,
          keyboardType: TextInputType.phone,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedGender,
          items: genderOptions
              .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
              .toList(),
          onChanged: (value) {
            if (value != null) onGenderChanged(value);
          },
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.transgender),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 20),
        InputDecorator(
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake_outlined),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          child: InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDob ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(data: theme, child: child!),
              );
              if (pickedDate != null) onDobChanged(pickedDate);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                selectedDob != null
                    ? selectedDob!.toLocal().toIso8601String().split('T').first
                    : "Tap to select date",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: selectedDob != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
