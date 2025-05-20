import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';
import 'package:invent_app_redesign/providers/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invent_app_redesign/services/auth_service.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: user == null
          ? _buildUnauthenticatedUI(context, colorScheme)
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildUserInfo(context, user),
                const SizedBox(height: 24),
                _buildSectionTitle('Preferences', colorScheme),
                _buildThemeSelector(themeProvider, context),
                const SizedBox(height: 12),
                _buildLanguageSelector(localeProvider, context),
                const SizedBox(height: 24),
                _buildLogoutButton(context, colorScheme),
              ],
            ),
    );
  }

  Widget _buildUnauthenticatedUI(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(height: 24),
          Text(
            'Sign In Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Sign in to access personalized settings and manage your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                child: const Text('Sign In'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          radius: 24,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          user.displayName ?? user.email ?? 'No email found',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text(
          'Tap to edit profile',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Theme'),
        trailing: DropdownButton<String>(
          value: themeProvider.themeName,
          items: const [
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
            DropdownMenuItem(value: 'system', child: Text('System')),
          ],
          onChanged: (value) => themeProvider.setTheme(value!),
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(LocaleProvider localeProvider, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Language'),
        trailing: DropdownButton<String>(
          value: localeProvider.locale.languageCode,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ru', child: Text('Русский')),
            DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
          ],
          onChanged: (value) => localeProvider.setLanguage(value!),
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ColorScheme colorScheme) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        await _authService.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
      },
    );
  }
}