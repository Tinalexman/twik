import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:twik/features/home/screens/home.dart';

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
    return ShadcnApp(title: 'Twik', home: const Home());
  }
}
