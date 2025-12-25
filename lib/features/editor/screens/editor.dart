import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:twik/core/scene/scene.dart';
import 'package:twik/features/editor/widgets/gl_canvas.dart';
import 'package:twik/features/editor/widgets/properties_panel.dart';
import 'package:twik/features/editor/widgets/scene_tree.dart';
import 'package:twik/features/editor/widgets/toolbar.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final Scene _scene = Scene();
  String? _selectedNodeId;

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Column(
        children: [
          EditorToolbar(),
          Expanded(
            child: Row(
              children: [
                SceneTree(
                  scene: _scene,
                  selectedNodeId: _selectedNodeId,
                  onNodeSelected: (id) {
                    setState(() => _selectedNodeId = id);
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.border,
                      ),
                    ),
                    child: GlCanvas(scene: _scene),
                  ),
                ),
                PropertiesPanel(
                  scene: _scene,
                  selectedNodeId: _selectedNodeId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
