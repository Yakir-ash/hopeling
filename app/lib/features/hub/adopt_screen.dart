// Animals waiting for a home, live from RescueGroups.org through
// our own worker (North America). This screen ships dormant: it
// appears only when adoptProxy is set, so deploying the worker is the
// single switch that brings it to life. Adoption itself happens on
// the animal's own page - we are the window, not the paperwork.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/hub.dart';

class AdoptScreen extends StatefulWidget {
  final HubArea area;
  const AdoptScreen({super.key, required this.area});

  @override
  State<AdoptScreen> createState() => _AdoptScreenState();
}

class _AdoptScreenState extends State<AdoptScreen> {
  static const filters = [
    ('', 'All'),
    ('dog', 'Dogs'),
    ('cat', 'Cats'),
    ('rabbit', 'Rabbits'),
    ('bird', 'Birds'),
  ];

  String type = '';
  List<AdoptablePet> pets = [];
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final p = await Hub.adoptablePets(widget.area, type: type);
      if (!mounted) return;
      setState(() {
        pets = p;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('Waiting for a home', style: serif(19))),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final (v, label) in filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: type == v,
                        onSelected: (_) {
                          Haptics.tick();
                          setState(() => type = v);
                          _load();
                        },
                        selectedColor: fern.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: type == v ? fern : tx2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(
          child: Text('asking around...',
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: tx2)));
    }
    if (failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Could not reach the adoption service right now. '
                  'It usually works on the next try.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: tx2)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Haptics.tick();
                  _load();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Look again'),
                style:
                    OutlinedButton.styleFrom(foregroundColor: fern),
              ),
            ],
          ),
        ),
      );
    }
    if (pets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
              'No animals of this kind are listed near you right '
              'now - that is good news for them. Try another kind, '
              'or look again tomorrow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        for (final p in pets) _petCard(p),
        const SizedBox(height: 6),
        const Text(
          'Live from RescueGroups.org. Tapping an animal opens their page '
          'at the shelter that knows them.',
          style: TextStyle(fontSize: 11, color: tx2),
        ),
      ],
    );
  }

  Widget _petCard(AdoptablePet p) {
    final sub = [
      if (p.breed != null && p.breed!.isNotEmpty) p.breed!,
      if (p.age != null && p.age!.isNotEmpty) p.age!.toLowerCase(),
      if (p.city != null && p.city!.isNotEmpty) p.city!,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '${p.name}. $sub. Opens their page.',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.tick();
              launchUrl(Uri.parse(p.url),
                  mode: LaunchMode.externalApplication);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ExcludeSemantics(
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: p.photo != null
                          ? CachedNetworkImage(
                              imageUrl: p.photo!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _noPhoto(p.type),
                            )
                          : _noPhoto(p.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: serif(15)),
                        const SizedBox(height: 3),
                        Text(sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: tx2)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: tx2, size: 20),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPhoto(String type) => Container(
        color: const Color(0xFFEFEAE2),
        alignment: Alignment.center,
        child: Text(
            switch (type.toLowerCase()) {
              'dog' => '🐶',
              'cat' => '🐱',
              'rabbit' => '🐰',
              'bird' => '🐦',
              _ => '🐾',
            },
            style: const TextStyle(fontSize: 26)),
      );
}
