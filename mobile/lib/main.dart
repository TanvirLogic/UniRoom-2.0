import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/room_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniRoomMobileApp());
  // Asynchronously initialize push notifications without blocking initial splash render
  NotificationService().initialize();
}

/// Root Application Widget
/// MultiProvider exposes AuthProvider, ScheduleProvider, and RoomProvider across the app.
class UniRoomMobileApp extends StatelessWidget {
  const UniRoomMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoomProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'UniRoom-Live',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
