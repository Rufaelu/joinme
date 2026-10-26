import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_signup_screen.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/create_event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/direct_chat_screen.dart';
import 'screens/rate_event_screen.dart';
import 'screens/reset_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MaterialApp(
          title: 'JoinMe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(context),
          darkTheme: AppTheme.dark(context),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AppNavigator(),
        );
      },
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentScreen = context.watch<AppState>().currentScreen;
    final selectedEventId = context.watch<AppState>().selectedEventId;
    final selectedGroupId = context.watch<AppState>().selectedGroupId;

    // The app swaps screens itself instead of pushing routes, so handle the
    // Android back button here: go to the previous screen, or close the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!context.read<AppState>().goBack()) SystemNavigator.pop();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildScreen(currentScreen, selectedEventId, selectedGroupId),
        ),
      ),
    );
  }

  Widget _buildScreen(String screen, String? eventId, String? groupId) {
    switch (screen) {
      case 'login':
        return const LoginSignupScreen();
      case 'resetPassword':
        return const ResetPasswordScreen();
      case 'onboarding':
        return const OnboardingScreen();
      case 'map':
        return const MapScreen();
      case 'create':
        return const CreateEventScreen();
      case 'event':
        return EventDetailScreen(key: ValueKey('event-$eventId'), eventId: eventId);
      case 'profile':
        return const ProfileScreen();
      case 'profileEdit':
        return const ProfileEditScreen();
      case 'friends':
        return const FriendsScreen();
      case 'notifications':
        return const NotificationsScreen();
      case 'messages':
        return const MessagesScreen();
      case 'chat':
        return GroupChatScreen(key: ValueKey('chat-$groupId'), eventId: eventId, groupId: groupId);
      case 'rate':
        return RateEventScreen(key: ValueKey('rate-$eventId'), eventId: eventId, groupId: groupId);
      case 'directChat':
        return const DirectChatScreen();
      default:
        return const MapScreen(); 
    }
  }
}
