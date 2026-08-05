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
          'Live from RescueGroups.org. Tap an animal to meet '
          'her - her story, and the rescue that knows her.',
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
        label: '${p.name}. $sub. Tap to meet her.',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.tick();
              _petSheet(p);
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

  /// Her page, inside the app: the big photo, her story as the
  /// rescue wrote it, and the doors onward - her exact page when
  /// one exists, otherwise her rescue's site, phone, and email.
  void _petSheet(AdoptablePet p) {
    final facts = [
      if (p.breed != null && p.breed!.isNotEmpty) p.breed!,
      if (p.sex != null && p.sex!.isNotEmpty) p.sex!.toLowerCase(),
      if (p.age != null && p.age!.isNotEmpty) p.age!.toLowerCase(),
      if (p.size != null && p.size!.isNotEmpty)
        '${p.size!.toLowerCase()} size',
      if (p.city != null && p.city!.isNotEmpty) p.city!,
    ].join(' · ');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            if (p.photoLarge != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: p.photoLarge!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _noPhoto(p.type),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(p.name, style: serif(21)),
            const SizedBox(height: 4),
            Text(facts,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.5, color: tx2)),
            if (p.desc.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(p.desc,
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.65, color: ink)),
            ],
            const SizedBox(height: 16),
            _door(ctx, Icons.public,
                'Meet ${p.name} at the rescue', () {
              launchUrl(Uri.parse(p.url),
                  mode: LaunchMode.externalApplication);
            }),
            if (p.orgPhone != null && p.orgPhone!.isNotEmpty)
              _door(ctx, Icons.call_outlined, p.orgPhone!, () {
                launchUrl(Uri.parse(
                    'tel:${p.orgPhone!.replaceAll(' ', '')}'));
              }),
            if (p.orgEmail != null && p.orgEmail!.isNotEmpty)
              _door(ctx, Icons.mail_outline,
                  'Write to her rescue', () {
                launchUrl(Uri.parse('mailto:${p.orgEmail}'
                    '?subject=${Uri.encodeComponent('About ${p.name}')}'));
              }),
            const SizedBox(height: 10),
            const Text(
              'Live from RescueGroups.org. Adoption happens with '
              'the rescue that knows her.',
              style: TextStyle(fontSize: 11, color: tx2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _door(BuildContext ctx, IconData icon, String label,
      VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Haptics.tick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ExcludeSemantics(
                child: Row(children: [
                  Icon(icon, size: 18, color: fern),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: ink)),
                  ),
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
