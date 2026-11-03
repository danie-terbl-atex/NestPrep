enum HomeLayout {
  tabs,
  cards;

  HomeLayout get other => switch (this) {
    HomeLayout.tabs => HomeLayout.cards,
    HomeLayout.cards => HomeLayout.tabs,
  };

  static HomeLayout? fromName(String name) => switch (name) {
    'tabs' => HomeLayout.tabs,
    'cards' => HomeLayout.cards,
    _ => null,
  };
}
