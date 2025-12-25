import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:twik/features/editor/widgets/gl_canvas.dart';
import 'package:twik/features/editor/widgets/properties_panel.dart';
import 'package:twik/features/editor/widgets/scene_tree.dart';
import 'package:twik/features/editor/widgets/toolbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Column(
        children: [
          EditorToolbar(),
          Expanded(
            child: Row(
              children: [
                SceneTree(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.border,
                      ),
                    ),
                    child: GlCanvas(),
                  ),
                ),
                PropertiesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
