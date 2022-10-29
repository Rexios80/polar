/// Convenience class for storing xyz values
class Xyz {
  /// x value
  final double x;

  /// y value
  final double y;

  /// z value
  final double z;

  /// Create an [Xyz] from json
  Xyz.fromJson(Map<String, dynamic> json)
      // Divide by 1 to convert to double
      : x = json['x'] / 1,
        y = json['y'] / 1,
        z = json['z'] / 1;
  
  @override
  String toString() => 'Xyz(x: $x, y: $y, z: $z)';
}
