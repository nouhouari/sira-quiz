enum Difficulty {
  beginner(1),
  intermediate(2),
  advanced(3);

  final int value;
  const Difficulty(this.value);

  static Difficulty fromInt(int v) => Difficulty.values.firstWhere(
        (d) => d.value == v,
        orElse: () => Difficulty.beginner,
      );
}
