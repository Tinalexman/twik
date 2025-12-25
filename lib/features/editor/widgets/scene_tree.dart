import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:twik/core/scene/scene.dart';

class SceneTree extends StatelessWidget {
  const SceneTree({
    super.key,
    required this.scene,
    required this.selectedNodeId,
    required this.onNodeSelected,
  });

  final Scene scene;
  final String? selectedNodeId;
  final ValueChanged<String?> onNodeSelected;

  IconData _getIconForPrimitive(SdfPrimitive primitive) {
    switch (primitive) {
      case SdfPrimitive.sphere:
        return RadixIcons.boxModel;
      case SdfPrimitive.box:
        return RadixIcons.box;
      case SdfPrimitive.cylinder:
        return RadixIcons.circle;
      case SdfPrimitive.triPrism:
        return RadixIcons.component1;
      case SdfPrimitive.torus:
        return RadixIcons.borderDotted;
      case SdfPrimitive.capsule:
        return RadixIcons.button;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: 'Scene'),
          Expanded(
            child: ListenableBuilder(
              listenable: scene,
              builder: (context, _) {
                if (scene.nodes.isEmpty) {
                  return Center(
                    child: Text(
                      'No objects',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.mutedForeground,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  itemCount: scene.nodes.length,
                  itemBuilder: (context, index) {
                    SdfNode node = scene.nodes[index];
                    return _SceneItem(
                      icon: _getIconForPrimitive(node.primitive),
                      label: node.name,
                      isSelected: node.id == selectedNodeId,
                      onTap: () => onNodeSelected(node.id),
                      onDelete: () {
                        scene.removeNode(node.id);
                        if (selectedNodeId == node.id) {
                          onNodeSelected(null);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          _SectionHeader(title: 'Primitives'),
          Padding(
            padding: EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PrimitiveButton(
                  icon: RadixIcons.boxModel,
                  tooltip: 'Sphere',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.sphere);
                    onNodeSelected(node.id);
                  },
                ),
                _PrimitiveButton(
                  icon: RadixIcons.box,
                  tooltip: 'Box',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.box);
                    onNodeSelected(node.id);
                  },
                ),
                _PrimitiveButton(
                  icon: RadixIcons.component1,
                  tooltip: 'Triangle Prism',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.triPrism);
                    onNodeSelected(node.id);
                  },
                ),
                _PrimitiveButton(
                  icon: RadixIcons.circle,
                  tooltip: 'Cylinder',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.cylinder);
                    onNodeSelected(node.id);
                  },
                ),
                _PrimitiveButton(
                  icon: RadixIcons.borderDotted,
                  tooltip: 'Torus',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.torus);
                    onNodeSelected(node.id);
                  },
                ),
                _PrimitiveButton(
                  icon: RadixIcons.button,
                  tooltip: 'Capsule',
                  onPressed: () {
                    SdfNode node = scene.addNode(SdfPrimitive.capsule);
                    onNodeSelected(node.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

class _SceneItem extends StatefulWidget {
  const _SceneItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_SceneItem> createState() => _SceneItemState();
}

class _SceneItemState extends State<_SceneItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: widget.isSelected
              ? Theme.of(context).colorScheme.accent
              : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered || widget.isSelected)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    RadixIcons.cross1,
                    size: 14,
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimitiveButton extends StatelessWidget {
  const _PrimitiveButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      tooltip: TooltipContainer(child: Text(tooltip)),
      child: OutlineButton(
        onPressed: onPressed,
        child: Icon(icon, size: 16),
      ),
    );
  }
}
