import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(builder: (context, vm, _) {
      final w = vm.weather;
      return GlassBox(
        borderRadius: BorderRadius.circular(20),
        opacity: 0.18,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (w != null && w.icon.isNotEmpty)
                Image.network(
                  'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              const SizedBox(width: 8),
              Text(
                w != null
                    ? '${w.tempC.toStringAsFixed(0)}°C'
                    : vm.isLoading
                        ? '...' : 'No API',
                style: const TextStyle(color: AppColors.white),
              ),
            ],
          ),
        ),
      );
    });
  }
}
