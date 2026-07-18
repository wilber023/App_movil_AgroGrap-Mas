/// Emoji de identidad por cultivo, usado en las tarjetas de [OfflineModePage].
String offlineCropEmoji(String cropName) => switch (cropName) {
      'Tomate' => '🍅',
      'Maíz' => '🌽',
      'Papa' => '🥔',
      'Frijol' => '🫘',
      'Calabaza' => '🍈',
      _ => '🌿',
    };
