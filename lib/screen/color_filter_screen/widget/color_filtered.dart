class Filters {
  final String name;
  final List<double> colorFilter;

  const Filters({required this.name, required this.colorFilter});
}

/// Identity color matrix (no filter).
const List<double> defaultFilter = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

final List<Filters> filters = <Filters>[
  const Filters(name: 'None', colorFilter: defaultFilter),
];
