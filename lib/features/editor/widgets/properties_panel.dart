import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:twik/core/scene/scene.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({
    super.key,
    required this.scene,
    required this.selectedNodeId,
  });

  final Scene scene;
  final String? selectedNodeId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.border),
        ),
      ),
      child: ListenableBuilder(
        listenable: scene,
        builder: (context, _) {
          SdfNode? node = selectedNodeId != null
              ? scene.getNode(selectedNodeId!)
              : null;

          if (node == null) {
            return Center(
              child: Text(
                'No object selected',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.mutedForeground,
                ),
              ),
            );
          }

          return _NodeProperties(
            key: ValueKey(node.id),
            node: node,
            onNodeChanged: (updated) {
              scene.updateNode(node.id, updated);
            },
          );
        },
      ),
    );
  }
}

class _NodeProperties extends StatelessWidget {
  const _NodeProperties({
    super.key,
    required this.node,
    required this.onNodeChanged,
  });

  final SdfNode node;
  final ValueChanged<SdfNode> onNodeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SectionHeader(title: 'Transform'),
        _PropertySection(
          children: [
            _Vec3Property(
              label: 'Position',
              value: node.position,
              onChanged: (v) => onNodeChanged(node.copyWith(position: v)),
            ),
            SizedBox(height: 12),
            _Vec3Property(
              label: 'Rotation',
              value: node.rotation,
              onChanged: (v) => onNodeChanged(node.copyWith(rotation: v)),
            ),
            SizedBox(height: 12),
            _Vec3Property(
              label: 'Scale',
              value: node.scale,
              onChanged: (v) => onNodeChanged(node.copyWith(scale: v)),
            ),
          ],
        ),
        Divider(),
        _SectionHeader(title: 'CSG Operation'),
        _PropertySection(
          children: [
            _CsgOperationSelector(
              value: node.operation,
              onChanged: (op) => onNodeChanged(node.copyWith(operation: op)),
            ),
          ],
        ),
        Divider(),
        _SectionHeader(title: 'Material'),
        _PropertySection(
          children: [
            _ColorProperty(
              label: 'Color',
              r: node.material.r,
              g: node.material.g,
              b: node.material.b,
              onChanged: (r, g, b) => onNodeChanged(
                node.copyWith(material: SdfMaterial(r: r, g: g, b: b)),
              ),
            ),
          ],
        ),
      ],
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

class _PropertySection extends StatelessWidget {
  const _PropertySection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Vec3Property extends StatelessWidget {
  const _Vec3Property({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Vec3 value;
  final ValueChanged<Vec3> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AxisInput(
                axis: 'X',
                value: value.x,
                onChanged: (v) => onChanged(value.copyWith(x: v)),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AxisInput(
                axis: 'Y',
                value: value.y,
                onChanged: (v) => onChanged(value.copyWith(y: v)),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _AxisInput(
                axis: 'Z',
                value: value.z,
                onChanged: (v) => onChanged(value.copyWith(z: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AxisInput extends StatefulWidget {
  const _AxisInput({
    required this.axis,
    required this.value,
    required this.onChanged,
  });

  final String axis;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_AxisInput> createState() => _AxisInputState();
}

class _AxisInputState extends State<_AxisInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_AxisInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      String newText = widget.value.toStringAsFixed(2);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          widget.axis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(fontSize: 12),
            onSubmitted: (v) {
              double? parsed = double.tryParse(v);
              if (parsed != null) {
                widget.onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _CsgOperationSelector extends StatelessWidget {
  const _CsgOperationSelector({
    required this.value,
    required this.onChanged,
  });

  final CsgOperation value;
  final ValueChanged<CsgOperation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CsgButton(
          label: 'Union',
          isSelected: value == CsgOperation.union,
          onPressed: () => onChanged(CsgOperation.union),
        ),
        SizedBox(width: 8),
        _CsgButton(
          label: 'Intersect',
          isSelected: value == CsgOperation.intersect,
          onPressed: () => onChanged(CsgOperation.intersect),
        ),
        SizedBox(width: 8),
        _CsgButton(
          label: 'Subtract',
          isSelected: value == CsgOperation.subtract,
          onPressed: () => onChanged(CsgOperation.subtract),
        ),
      ],
    );
  }
}

class _CsgButton extends StatelessWidget {
  const _CsgButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: isSelected
          ? PrimaryButton(
              onPressed: onPressed,
              child: Text(label, style: TextStyle(fontSize: 11)),
            )
          : OutlineButton(
              onPressed: onPressed,
              child: Text(label, style: TextStyle(fontSize: 11)),
            ),
    );
  }
}

class _ColorProperty extends StatelessWidget {
  const _ColorProperty({
    required this.label,
    required this.r,
    required this.g,
    required this.b,
    required this.onChanged,
  });

  final String label;
  final double r;
  final double g;
  final double b;
  final void Function(double r, double g, double b) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12)),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  (r * 255).round(),
                  (g * 255).round(),
                  (b * 255).round(),
                  1,
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).colorScheme.border),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _ColorSlider(
          label: 'R',
          value: r,
          color: Colors.red,
          onChanged: (v) => onChanged(v, g, b),
        ),
        SizedBox(height: 8),
        _ColorSlider(
          label: 'G',
          value: g,
          color: Colors.green,
          onChanged: (v) => onChanged(r, v, b),
        ),
        SizedBox(height: 8),
        _ColorSlider(
          label: 'B',
          value: b,
          color: Colors.blue,
          onChanged: (v) => onChanged(r, g, v),
        ),
      ],
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: SliderValue.single(value),
            min: 0.0,
            max: 1.0,
            onChanged: (v) => onChanged(v.value),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            (value * 255).round().toString(),
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
