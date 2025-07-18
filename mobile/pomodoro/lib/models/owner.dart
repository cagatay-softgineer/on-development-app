class Owner {
  final String id;
  final String name;
  final String pic;

  Owner({
    required this.id,
    required this.name,
    required this.pic,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
        id: json['id'] as String,
        name: json['name'] as String,
        pic: json['pic'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pic': pic,
      };
}