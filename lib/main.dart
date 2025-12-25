import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:twik/features/editor/screens/editor.dart';

void main() {
  runApp(const Twik());
}

class Twik extends StatefulWidget {
  const Twik({super.key});

  @override
  State<Twik> createState() => _TwikState();
}

class _TwikState extends State<Twik> {
  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Twik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorSchemes.lightGreen,
        radius: 0.0,
        surfaceBlur: 2.0,
      ),
      scaling: const AdaptiveScaling(0.9),
      home: const Editor(),
    );
  }
}
