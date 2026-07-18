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
  if (parts.isEmpty) return null;
  final type = parts[0].toLowerCase();
  final id = parts.length > 1 ? parts[1].toLowerCase() : '';
  if (type == 'today') return DeepLink('today', id); // '' or 'why'
  if (parts.length < 2) return null;
  if (type == 'world' || type == 'atlas') return DeepLink('world', id);
  if (type == 'species') return DeepLink('species', id);
  if (type == 'guardian') return DeepLink('guardian', id);
  if (type == 'circle') {
    if (id == 'invite' && parts.length > 2) {
      return DeepLink('circleInvite', parts[2].toUpperCase());
    }
    return DeepLink('circle', id);
  }
  return null;
}
