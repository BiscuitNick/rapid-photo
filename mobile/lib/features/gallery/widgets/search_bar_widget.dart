import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';

/// Search bar widget for tag-based search
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isEmpty) return;

    final trimmedTag = tag.trim().toLowerCase();
    if (!_selectedTags.contains(trimmedTag)) {
      setState(() {
        _selectedTags.add(trimmedTag);
      });
      _controller.clear();
      _search();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    _search();
  }

  void _search() {
    if (_selectedTags.isEmpty) {
      ref.read(galleryProvider.notifier).clearFilters();
    } else {
      ref.read(galleryProvider.notifier).searchByTags(_selectedTags);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search by tag...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_controller.text),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onSubmitted: _addTag,
          onChanged: (value) {
            setState(() {}); // Trigger rebuild to show/hide add button
          },
        ),

        // Selected tags chips
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
