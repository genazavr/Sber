class ShelfModel {
  final String id;
  final String owner;
  final int soilHumidity; // 0/1
  final int airHumidity; // 0/1
  final List<int> lights; // length 3, 0/1
  final List<int> pumps;  // length 3, 0/1
  final bool auto;
  final Map<String, dynamic> shelvesMeta; // per-pallet metadata

  ShelfModel({
    required this.id,
    required this.owner,
    required this.soilHumidity,
    required this.airHumidity,
    required this.lights,
    required this.pumps,
    required this.auto,
    required this.shelvesMeta,
  });

  factory ShelfModel.fromMap(String id, Map<dynamic, dynamic> m) {
    return ShelfModel(
      id: id,
      owner: m['owner'] ?? '',
      soilHumidity: m['soilHumidity'] ?? 0,
      airHumidity: m['airHumidity'] ?? 0,
      lights: m['lights'] != null ? List<int>.from(List.from(m['lights'])) : [0,0,0],
      pumps: m['pumps'] != null ? List<int>.from(List.from(m['pumps'])) : [0,0,0],
      auto: m['auto'] ?? false,
      shelvesMeta: m['shelvesMeta'] != null ? Map<String,dynamic>.from(m['shelvesMeta']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner': owner,
      'soilHumidity': soilHumidity,
      'airHumidity': airHumidity,
      'lights': lights,
      'pumps': pumps,
      'auto': auto,
      'shelvesMeta': shelvesMeta,
    };
  }

  static ShelfModel improvised(String id, String owner) {
    return ShelfModel(
        id: id,
        owner: owner,
        soilHumidity: (DateTime.now().second % 2), // 0/1 demo
        airHumidity: (DateTime.now().millisecond % 2),
        lights: [0,0,0],
        pumps: [0,0,0],
        auto: false,
        shelvesMeta: {
          'p1': {'name':'Unset','imagePath':''},
          'p2': {'name':'Unset','imagePath':''},
          'p3': {'name':'Unset','imagePath':''},
        }
    );
  }
}
