import 'package:shadcn_flutter/shadcn_flutter.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  double _positionX = 0.0;
  double _positionY = 0.0;
  double _positionZ = 0.0;
  double _scaleX = 1.0;
  double _scaleY = 0.5;
  double _rotationSpeed = 0.5;

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SectionHeader(title: 'Transform'),
          _PropertySection(
            children: [
              _Vec3Property(
                label: 'Position',
                x: _positionX,
                y: _positionY,
                z: _positionZ,
                onXChanged: (v) => setState(() => _positionX = v),
                onYChanged: (v) => setState(() => _positionY = v),
                onZChanged: (v) => setState(() => _positionZ = v),
              ),
            ],
          ),
          Divider(),
          _SectionHeader(title: 'Shape Parameters'),
          _PropertySection(
            children: [
              _SliderProperty(
                label: 'Width',
                value: _scaleX,
                min: 0.1,
                max: 3.0,
                onChanged: (v) => setState(() => _scaleX = v),
              ),
              SizedBox(height: 12),
              _SliderProperty(
                label: 'Height',
                value: _scaleY,
                min: 0.1,
                max: 3.0,
                onChanged: (v) => setState(() => _scaleY = v),
              ),
            ],
          ),
          Divider(),
          _SectionHeader(title: 'Animation'),
          _PropertySection(
            children: [
              _SliderProperty(
                label: 'Rotation Speed',
                value: _rotationSpeed,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => setState(() => _rotationSpeed = v),
              ),
            ],
          ),
          Divider(),
          _SectionHeader(title: 'Material'),
          _PropertySection(
            children: [
              _ColorProperty(
                label: 'Color',
                color: Color(0xFFCC6633),
                onChanged: (c) {},
              ),
            ],
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
    required this.x,
    required this.y,
    required this.z,
    required this.onXChanged,
    required this.onYChanged,
    required this.onZChanged,
  });

  final String label;
  final double x;
  final double y;
  final double z;
  final ValueChanged<double> onXChanged;
  final ValueChanged<double> onYChanged;
  final ValueChanged<double> onZChanged;

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
            Expanded(child: _AxisInput(axis: 'X', value: x, onChanged: onXChanged)),
            SizedBox(width: 8),
            Expanded(child: _AxisInput(axis: 'Y', value: y, onChanged: onYChanged)),
            SizedBox(width: 8),
            Expanded(child: _AxisInput(axis: 'Z', value: z, onChanged: onZChanged)),
          ],
        ),
      ],
    );
  }
}

class _AxisInput extends StatelessWidget {
  const _AxisInput({
    required this.axis,
    required this.value,
    required this.onChanged,
  });

  final String axis;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          axis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: TextField(
            initialValue: value.toStringAsFixed(1),
            style: TextStyle(fontSize: 12),
            onChanged: (v) {
              double? parsed = double.tryParse(v);
              if (parsed != null) {
                onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _SliderProperty extends StatelessWidget {
  const _SliderProperty({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12)),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Slider(
          value: SliderValue.single(value),
          min: min,
          max: max,
          onChanged: (v) => onChanged(v.value),
        ),
      ],
    );
  }
}

class _ColorProperty extends StatelessWidget {
  const _ColorProperty({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.border),
          ),
        ),
      ],
    );
  }
}
