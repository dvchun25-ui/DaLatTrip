import 'package:flutter/material.dart';

import '../../trip/screens/ai_trip_input_screen.dart';

/// Compatibility entry point used by the existing Home screen.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) => const AiTripInputScreen();
}
