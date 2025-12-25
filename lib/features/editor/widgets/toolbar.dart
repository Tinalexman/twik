import 'package:shadcn_flutter/shadcn_flutter.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Twik',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 24),
          _ToolbarButton(
            icon: RadixIcons.plus,
            tooltip: 'Add Shape',
            onPressed: () {},
          ),
          SizedBox(width: 8),
          _ToolbarButton(
            icon: RadixIcons.cursorArrow,
            tooltip: 'Select',
            onPressed: () {},
          ),
          SizedBox(width: 8),
          _ToolbarButton(
            icon: RadixIcons.move,
            tooltip: 'Move',
            onPressed: () {},
          ),
          Spacer(),
          _ToolbarButton(
            icon: RadixIcons.gear,
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
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
      child: IconButton.ghost(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
