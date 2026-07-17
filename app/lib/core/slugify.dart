// One slug rule across website, PWA and app, so deep links agree.
String slugify(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"['’.]"), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');
