class UserLocationAndImage{
  final double lat;
  final double lng;
  final String imgUrl;

  UserLocationAndImage({required this.lat, required this.lng, required this.imgUrl});

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'imgUrl': imgUrl
    };
  }

  factory UserLocationAndImage.fromMap(Map<String, dynamic> map) {
    return UserLocationAndImage(
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      imgUrl: map['imgUrl'] as String
    );
  }

}