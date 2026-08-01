// The Nature & Animal Hub - where caring gets an address. Phase
// one: pick your place (typed, private, rounded), then the hero
// card for injured wildlife, wild places to visit, and shelters to
// help. Adult surface only - never appears in kids mode.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/hub.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  HubArea? area;
  List<HubPlace> places = [];
  DateTime? asOf;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Hub.area().then((a) {
      if (!mounted) return;
      setState(() => area = a);
      if (a != null) _load(a);
    });
  }

  Future<void> _load(HubArea a) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final (p, t) = await Hub.nearby(a);
      if (!mounted) return;
      setState(() {
        places = p;
        asOf = t;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'The map is out of reach right now - the free '
            'map servers get busy sometimes. It usually works on '
            'the next try.';
      });
    }
  }

  Future<void> _pickPlace() async {
    Haptics.tick();
    final picked = await showModalBottomSheet<HubArea>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => const _PlaceSheet(),
    );
    if (picked != null) {
      await Hub.setArea(picked);
      if (!mounted) return;
      setState(() => area = picked);
      _load(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wild = places.where((p) => !p.isShelter).toList();
    final shelters = places.where((p) => p.isShelter).toList();
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('Near you', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // the place, chosen by typing - never by tracking
            Semantics(
              button: true,
              label: area == null
                  ? 'Choose your area'
                  : 'Your area: ${area!.name}. Tap to change.',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickPlace,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ExcludeSemantics(
                      child: Row(children: [
                        const Text('📍',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              area?.name ??
                                  'Choose your area to begin',
                              style: serif(15)),
                        ),
                        Text(area == null ? 'set' : 'change',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: fern)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You type the place; nothing is tracked. Your area is '
              'rounded to about 2 km and stays on this device.',
              style: TextStyle(fontSize: 11.5, color: tx2),
            ),
            const SizedBox(height: 14),
            // THE HERO: this card can save a life today
            Semantics(
              button: true,
              label: 'Help a wild animal. What to do right now, '
                  'and whom to call.',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFFFFE3C2),
                      gold.withValues(alpha: 0.25)
                    ]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Haptics.tick();
                      Sfx.play('tick', volume: 0.3);
                      Navigator.of(context).push(risePush(
                          HelpWildScreen(
                              countryCode: area?.countryCode ?? '')));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: ExcludeSemantics(
                        child: Row(children: [
                          const Text('🆘',
                              style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Help a wild animal',
                                    style: serif(16)),
                                const SizedBox(height: 2),
                                const Text(
                                    'found an injured bird, a '
                                    'hedgehog in daylight? what to '
                                    'do, whom to call - works '
                                    'offline',
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
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
            ),
            const SizedBox(height: 18),
            if (area == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pick your area above and this page fills with '
                  'the wild places and shelters around you - from '
                  'OpenStreetMap, the map the world keeps together.',
                  style:
                      TextStyle(fontSize: 13, height: 1.6, color: tx2),
                ),
              )
            else if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                    child: Text('walking the map...',
                        style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: tx2))),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(error!,
                        style: const TextStyle(
                            fontSize: 13, height: 1.6, color: tx2)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Haptics.tick();
                        if (area != null) _load(area!);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Look again'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: fern),
                    ),
                  ],
                ),
              )
            else ...[
              if (asOf != null &&
                  DateTime.now().difference(asOf!).inHours > 24)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                      'showing the map as of '
                      '${asOf!.day}.${asOf!.month} - offline is '
                      'fine, the hills have not moved',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: tx2)),
                ),
              Text('🌿 Wild places near you', style: serif(16)),
              const SizedBox(height: 8),
              if (wild.isEmpty)
                const Text(
                  'OpenStreetMap does not know wild places around '
                  'here yet. That is a gap in the map, not in your '
                  'landscape - and mapping your area on '
                  'openstreetmap.org is itself a real gift to '
                  'everyone after you.',
                  style:
                      TextStyle(fontSize: 12.5, height: 1.6, color: tx2),
                )
              else
                for (final pl in wild.take(12))
                  _placeTile(pl),
              const SizedBox(height: 18),
              Text('🐾 Shelters & rescues', style: serif(16)),
              const SizedBox(height: 8),
              if (shelters.isEmpty)
                const Text(
                  'No shelters on the map here yet. The wildlife '
                  'card above works everywhere - and your '
                  'municipality can point you to local shelters '
                  'for dogs and cats.',
                  style:
                      TextStyle(fontSize: 12.5, height: 1.6, color: tx2),
                )
              else
                for (final pl in shelters.take(8)) _placeTile(pl),
              const SizedBox(height: 14),
              const Text(
                'Places come from OpenStreetMap, the map millions '
                'of people keep together.',
                style: TextStyle(fontSize: 11, color: tx2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeTile(HubPlace pl) {
    final a = area!;
    final km = distanceKm(a.lat, a.lon, pl.lat, pl.lon);
    final dist = km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '${pl.name}, $dist away',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Haptics.tick();
              _placeSheet(pl, dist);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              child: ExcludeSemantics(
                child: Row(children: [
                  Text(pl.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(pl.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: ink))),
                  Text(dist,
                      style:
                          const TextStyle(fontSize: 12, color: tx2)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _placeSheet(HubPlace pl, String dist) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${pl.emoji} ${pl.name}', style: serif(18)),
              const SizedBox(height: 4),
              Text('$dist from your area',
                  style: const TextStyle(fontSize: 12.5, color: tx2)),
              const SizedBox(height: 16),
              _linkRow(ctx, Icons.map_outlined, 'Open in maps', () {
                launchUrl(
                    Uri.parse('geo:${pl.lat},${pl.lon}'
                        '?q=${pl.lat},${pl.lon}'
                        '(${Uri.encodeComponent(pl.name)})'),
                    mode: LaunchMode.externalApplication);
              }),
              if (pl.website != null)
                _linkRow(ctx, Icons.public, 'Website', () {
                  launchUrl(Uri.parse(pl.website!),
                      mode: LaunchMode.externalApplication);
                }),
              if (pl.phone != null)
                _linkRow(ctx, Icons.call_outlined, pl.phone!, () {
                  launchUrl(Uri.parse(
                      'tel:${pl.phone!.replaceAll(' ', '')}'));
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkRow(BuildContext ctx, IconData icon, String label,
      VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
                            fontSize: 13.5, color: ink))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Type a place; pick a match. Nothing else.
class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet();

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final c = TextEditingController();
  List<HubArea> results = [];
  bool searching = false;
  String? note;

  Future<void> _search() async {
    final q = c.text.trim();
    if (q.isEmpty) return;
    setState(() {
      searching = true;
      note = null;
    });
    try {
      final r = await Hub.geocode(q);
      if (!mounted) return;
      setState(() {
        results = r;
        searching = false;
        note = r.isEmpty ? 'No places found by that name.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        searching = false;
        note = 'Could not reach the map service. Try again in a '
            'moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            26, 22, 26, 22 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where is home?', style: serif(18)),
            const SizedBox(height: 4),
            const Text(
                'A town or neighborhood is plenty - it is rounded '
                'to ~2 km anyway.',
                style: TextStyle(fontSize: 12, color: tx2)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'e.g. Haifa',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: _search,
                    icon: const Icon(Icons.search, color: fern)),
              ),
            ),
            const SizedBox(height: 10),
            if (searching)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text('looking...',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: tx2)),
              ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(note!,
                    style:
                        const TextStyle(fontSize: 12.5, color: tx2)),
              ),
            for (final r in results)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Haptics.tick();
                      Navigator.of(context).pop(r);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(r.name,
                          style: const TextStyle(
                              fontSize: 13.5, color: ink)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
                'Powered by OpenStreetMap Nominatim.',
                style: TextStyle(fontSize: 10.5, color: tx2)),
          ],
        ),
      ),
    );
  }
}

/// What to do right now, and whom to call. Works offline; the
/// guidance is universal, the hotline is per country.
class HelpWildScreen extends StatelessWidget {
  final String countryCode;
  const HelpWildScreen({super.key, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    final line = rescueLines[countryCode];
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('🆘 Help a wild animal', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // whom to call - first, because minutes matter
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFE3C2),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Whom to call', style: serif(16)),
                  const SizedBox(height: 8),
                  if (line != null) ...[
                    Text(line.org,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 6),
                    if (line.phone != null)
                      Semantics(
                        button: true,
                        label: 'Call ${line.phone}',
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Haptics.tick();
                              launchUrl(Uri.parse(
                                  'tel:${line.phone!.replaceAll(' ', '')}'));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: ExcludeSemantics(
                                child: Row(children: [
                                  const Icon(Icons.call,
                                      size: 18, color: fern),
                                  const SizedBox(width: 10),
                                  Text(line.phone!,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: ink)),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (line.url != null) ...[
                      if (line.phone != null)
                        const SizedBox(height: 6),
                      Semantics(
                        button: true,
                        label: 'Open ${line.org}: find the '
                            'nearest wildlife help',
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Haptics.tick();
                              launchUrl(Uri.parse(line.url!),
                                  mode: LaunchMode
                                      .externalApplication);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: ExcludeSemantics(
                                child: Row(children: [
                                  const Icon(Icons.public,
                                      size: 18, color: fern),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                        'Find the nearest help '
                                        'now',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: ink)),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(line.note,
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: tx2)),
                  ] else
                    const Text(rescueFallback,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.6, color: ink)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Until help comes', style: serif(15)),
                  const SizedBox(height: 8),
                  for (final d in WildRescue.doList)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('•  $d',
                          style: const TextStyle(
                              fontSize: 13, height: 1.55, color: ink)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: const Color(0xFFF6E9E4),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Please do not', style: serif(15)),
                  const SizedBox(height: 8),
                  for (final d in WildRescue.dontList)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('•  $d',
                          style: const TextStyle(
                              fontSize: 13, height: 1.55, color: ink)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This page is guidance for the first minutes only - '
              'the people on the line are the experts. When in '
              'doubt, call.',
              style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: tx2),
            ),
          ],
        ),
      ),
    );
  }
}
