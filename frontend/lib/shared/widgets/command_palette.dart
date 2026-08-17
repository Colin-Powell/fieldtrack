import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommandItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onSelect;

  CommandItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onSelect,
  });
}

class CommandPalette extends ConsumerStatefulWidget {
  final List<CommandItem> commands;

  const CommandPalette({super.key, required this.commands});

  static Future<void> show(BuildContext context, {required List<CommandItem> commands}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: CommandPalette(commands: commands),
      ),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<CommandItem> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCommands = widget.commands;
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCommands = widget.commands.where((cmd) {
        return cmd.title.toLowerCase().contains(query) ||
            (cmd.subtitle != null && cmd.subtitle!.toLowerCase().contains(query));
      }).toList();
      _selectedIndex = 0;
    });
  }

  void _executeSelected() {
    if (_filteredCommands.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < _filteredCommands.length) {
      Navigator.of(context).pop();
      _filteredCommands[_selectedIndex].onSelect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    setState(() {
                      if (_selectedIndex < _filteredCommands.length - 1) _selectedIndex++;
                    });
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    setState(() {
                      if (_selectedIndex > 0) _selectedIndex--;
                    });
                  },
                  const SingleActivator(LogicalKeyboardKey.enter): _executeSelected,
                  const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
                },
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type a command or search...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Results
            Flexible(
              child: _filteredCommands.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No commands found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCommands.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (ctx, index) {
                        final cmd = _filteredCommands[index];
                        final isSelected = index == _selectedIndex;
                        
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            cmd.onSelect();
                          },
                          onHover: (hovering) {
                            if (hovering) {
                              setState(() => _selectedIndex = index);
                            }
                          },
                          child: Container(
                            color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Icon(cmd.icon, color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF6B7280), size: 20),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cmd.title,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF111827) : const Color(0xFF374151),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (cmd.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          cmd.subtitle!,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Color(0xFF6B7280),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
