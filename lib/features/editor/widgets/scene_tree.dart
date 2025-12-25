import 'package:shadcn_flutter/shadcn_flutter.dart';

class SceneTree extends StatefulWidget {
  const SceneTree({super.key});

  @override
  State<SceneTree> createState() => _SceneTreeState();
}

class _SceneTreeState extends State<SceneTree> {
  int _selectedIndex = 0;

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
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 4),
              children: [
                _SceneItem(
                  icon: RadixIcons.component1,
                  label: 'Triangle Prism',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ],
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
                  onPressed: () {},
                ),
                _PrimitiveButton(
                  icon: RadixIcons.box,
                  tooltip: 'Box',
                  onPressed: () {},
                ),
                _PrimitiveButton(
                  icon: RadixIcons.component1,
                  tooltip: 'Triangle',
                  onPressed: () {},
                ),
                _PrimitiveButton(
                  icon: RadixIcons.circle,
                  tooltip: 'Cylinder',
                  onPressed: () {},
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

class _SceneItem extends StatelessWidget {
  const _SceneItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected
            ? Theme.of(context).colorScheme.accent
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
        // size: ButtonSize.sm,
        child: Icon(icon, size: 16),
      ),
    );
  }
}
