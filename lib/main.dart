import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

void main() {
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
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
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

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildScreen(currentScreen, selectedEventId),
      ),
    );
  }

  Widget _buildScreen(String screen, String? eventId) {
    switch (screen) {
      case 'login':
        return const LoginSignupScreen();
      case 'onboarding':
        return const OnboardingScreen();
      case 'map':
        return const MapScreen();
      case 'create':
        return const CreateEventScreen();
      case 'event':
        return EventDetailScreen(eventId: eventId);
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
        return GroupChatScreen(eventId: eventId);
      case 'directChat':
        return const DirectChatScreen();
      default:
        return const MapScreen(); 
    }
  }
}
