// Search - instant, local, grouped. Opens focused, results as you type.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content.dart';
import '../../data/search.dart' as srch;
import '../learn/reader_screen.dart';
import 'species_screen.dart';
import 'world_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppContent content;
  const SearchScreen({super.key, required this.content});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final c = TextEditingController();
  List<srch.Hit> hits = [];

  void _run(String q) => setState(() => hits = srch.search(widget.content, q));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: TextField(
          controller: c,
          autofocus: true,
          onChanged: _run,
          decoration: const InputDecoration(
            hintText: 'vaquita, oceans, plastic...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 17, color: ink),
        ),
      ),
      body: SafeArea(
        child: hits.isEmpty
            ? Center(
                child: Text(
                    c.text.trim().length < 2
                        ? 'The whole atlas, two letters away.'
                        : 'Nothing answers to that name yet.',
                    style: const TextStyle(color: tx2, fontSize: 14)),
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 24 + MediaQuery.of(context).padding.bottom),
                itemCount: hits.length,
                itemBuilder: (context, i) {
                  final h = hits[i];
                  const icons = {
                    'species': '🐾',
                    'world': '🗺',
                    'fact': '💡',
                    'action': '🌱',
                    'journey': '📖'
                  };
                  return ListTile(
                    leading: Text(icons[h.kind] ?? '🌿',
                        style: const TextStyle(fontSize: 20)),
                    title: Text(h.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(h.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: tx2)),
                    onTap: () {
                      Haptics.tick();
                      if (h.kind == 'journey' && h.journey != null) {
                        Navigator.of(context).push(risePush(ReaderScreen(
                            journey: h.journey!, content: widget.content)));
                      } else if (h.kind == 'species' && h.world != null) {
                        Navigator.of(context).push(risePush(SpeciesPager(
                            world: h.world!,
                            content: widget.content,
                            initial: h.speciesIndex)));
                      } else if (h.world != null) {
                        Navigator.of(context).push(risePush(WorldScreen(
                            world: h.world!, content: widget.content)));
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
