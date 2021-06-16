class Xyz {
  final double x;
  final double y;
  final double z;


  Xyz.fromJson(Map<String, dynamic> json)
      // Divide by 1 to convert to double
      : x = json['x'] / 1,
        y = json['y'] / 1,
        z = json['z'] / 1;
}
