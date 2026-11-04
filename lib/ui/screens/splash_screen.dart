import 'package:flutter/material.dart';
import 'package:kinetix_courier/viewmodels/splash_view_model.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SplashViewModel>();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
