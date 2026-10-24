class AvatarPreset {
  final String id;
  final String name;
  final String url;
  final String description;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
  });
}

abstract final class AvatarPresets {
  static const List<AvatarPreset> list = [
    AvatarPreset(
      id: 'neon-architect',
      name: 'Neon Architect',
      url: 'https://api.dicebear.com/7.x/bottts/png?seed=KakuArchitect&backgroundColor=0d111a',
      description: 'Futuristic bot crafted for blueprint drafting',
    ),
    AvatarPreset(
      id: 'cyber-stylus',
      name: 'Cyber Stylus',
      url: 'https://api.dicebear.com/7.x/identicon/png?seed=CyberKaku&backgroundColor=131824',
      description: 'Abstract geometric matrix for digital thinkers',
    ),
    AvatarPreset(
      id: 'aurora-creator',
      name: 'Aurora Creator',
      url: 'https://api.dicebear.com/7.x/micah/png?seed=AuroraPilot&backgroundColor=00f2a9',
      description: 'Vibrant modern creative persona',
    ),
    AvatarPreset(
      id: 'zen-artist',
      name: 'Zen Artist',
      url: 'https://api.dicebear.com/7.x/personas/png?seed=ZenCreator&backgroundColor=161d2b',
      description: 'Calm and focused freeform illustrator',
    ),
    AvatarPreset(
      id: 'obsidian-bot',
      name: 'Obsidian Bot',
      url: 'https://api.dicebear.com/7.x/bottts/png?seed=ObsidianDraft&backgroundColor=1a2232',
      description: 'Tactical whiteboard engineer',
    ),
    AvatarPreset(
      id: 'neon-shapes',
      name: 'Neon Geometry',
      url: 'https://api.dicebear.com/7.x/shapes/png?seed=NeonArtist&backgroundColor=090b10',
      description: 'Algorithmic color compositions',
    ),
    AvatarPreset(
      id: 'indigo-sketch',
      name: 'Electric Indigo',
      url: 'https://api.dicebear.com/7.x/shapes/png?seed=IndigoSketch&backgroundColor=6366f1',
      description: 'Deep indigo vector dynamics',
    ),
    AvatarPreset(
      id: 'minimal-bot',
      name: 'Kaku Companion',
      url: 'https://api.dicebear.com/7.x/bottts/png?seed=KakuFox&backgroundColor=131824',
      description: 'Friendly robotic studio assistant',
    ),
  ];
}
