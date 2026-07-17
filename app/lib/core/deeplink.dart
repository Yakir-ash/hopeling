// hopeling://species/vaquita · hopeling://world/oceans
// Also tolerates path-style routes (/species/vaquita) from the engine.

class DeepLink {
  final String type; // 'world' | 'species'
  final String id;
  DeepLink(this.type, this.id);
}

DeepLink? parseDeepLink(String? route) {
  if (route == null || route.isEmpty) return null;
  var r = route;
  final schemeIdx = r.indexOf('://');
  if (schemeIdx >= 0) r = r.substring(schemeIdx + 3);
  final parts = r.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return null;
  final type = parts[0].toLowerCase();
  final id = parts[1].toLowerCase();
  if (type == 'world' || type == 'atlas') return DeepLink('world', id);
  if (type == 'species') return DeepLink('species', id);
  return null;
}
