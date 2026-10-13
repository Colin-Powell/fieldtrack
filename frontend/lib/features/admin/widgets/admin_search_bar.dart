import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/search_provider.dart';

class AdminSearchBar extends ConsumerStatefulWidget {
  const AdminSearchBar({super.key});

  @override
  ConsumerState<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends ConsumerState<AdminSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        // Delay hiding so taps on overlay can register
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _hideOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Consumer(
              builder: (context, overlayRef, child) {
                return _buildDropdownContent(overlayRef);
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSearchChanged(String value) {
    setState(() {});
    if (value.isNotEmpty) {
      if (_overlayEntry == null) _showOverlay();
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _onResultTapped(String query, String path) {
    ref.read(recentSearchesProvider.notifier).addSearch(query);
    _controller.clear();
    _focusNode.unfocus();
    context.push(path);
  }

  Widget _buildDropdownContent(WidgetRef overlayRef) {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      final recent = overlayRef.watch(recentSearchesProvider);
      if (recent.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Type to search for users, departments, and projects...', style: TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter')),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        itemCount: recent.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Recent Searches', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
            );
          }
          final q = recent[index - 1];
          return ListTile(
            leading: Icon(PhosphorIcons.clock(), color: const Color(0xFF9CA3AF), size: 20),
            title: Text(q, style: const TextStyle(fontFamily: 'Inter')),
            onTap: () {
              _controller.text = q;
              _onSearchChanged(q);
            },
          );
        },
      );
    }

    final searchAsync = overlayRef.watch(globalSearchProvider(query));
    
    return searchAsync.when(
      data: (data) {
        final users = data['users'] as List<dynamic>;
        final depts = data['departments'] as List<dynamic>;
        final projects = data['projects'] as List<dynamic>;

        if (users.isEmpty && depts.isEmpty && projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No results found.', style: TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter')),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (depts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('DEPARTMENTS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ),
                ...depts.map((d) => ListTile(
                  leading: Icon(PhosphorIcons.buildings(), color: const Color(0xFF1BA654)),
                  title: Text(d['name'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  onTap: () => _onResultTapped(d['name'], '/admin/departments/${Uri.encodeComponent(d['name'])}'),
                )),
              ],
              if (users.isNotEmpty) ...[
                if (depts.isNotEmpty) const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('USERS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ),
                ...users.map((u) => ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1BA654).withValues(alpha: 0.1),
                    child: Text(u['name']?.substring(0,1) ?? 'U', style: const TextStyle(color: Color(0xFF1BA654), fontSize: 12)),
                  ),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  subtitle: Text(u['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  trailing: Text(u['role'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF9CA3AF))),
                  onTap: () => _onResultTapped(u['name'], '/admin/users'), // Ideally to user details
                )),
              ],
              if (projects.isNotEmpty) ...[
                if (users.isNotEmpty || depts.isNotEmpty) const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('PROJECTS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ),
                ...projects.map((p) => ListTile(
                  leading: Icon(PhosphorIcons.folder(), color: const Color(0xFF3B82F6)),
                  title: Text(p['title'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p['studentName'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  onTap: () => _onResultTapped(p['title'], '/admin/projects'),
                )),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1BA654))),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('Error loading results', style: TextStyle(color: Colors.red[400])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search across system...',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(
              PhosphorIcons.magnifyingGlass(),
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            suffixIcon: _controller.text.isNotEmpty ? IconButton(
              icon: Icon(PhosphorIcons.x(), color: const Color(0xFF9CA3AF), size: 16),
              onPressed: () {
                _controller.clear();
                _onSearchChanged('');
              },
            ) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
