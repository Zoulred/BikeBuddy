import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'viewmodels/bike_viewmodel.dart';
import 'viewmodels/ride_viewmodel.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BikeViewModel()),
        ChangeNotifierProvider(create: (_) => RideViewModel()),
      ],
      child: const BikeBuddyApp(),
    ),
  );
}

class BikeBuddyApp extends StatelessWidget {
  const BikeBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeBuddy PH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
