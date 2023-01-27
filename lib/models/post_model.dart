class  PostModel{
  final String id;
  final String circleId;
  final String? text;
  final List<String> picturesList;
  final List<String> videosList;
  final String authorId;
  final DateTime createdAt;
  final List<String> likedBy;

  PostModel({required this.id, required this.circleId, this.text, required this.createdAt, required this.authorId, required this.likedBy, required this.picturesList, required this.videosList});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "circleId": circleId,
      "text": text,
      "picturesList": picturesList,
      "videosList": videosList,
      "authorId": authorId,
      "createdAt": createdAt.toIso8601String(),
      "likedBy": likedBy,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json["id"],
      circleId: json["circleId"],
      text: json["text"],
      picturesList: (json["picturesList"] as List).map((e) => e.toString()).toList(),
      videosList:
      (json["videosList"] as List).map((e) => e.toString()).toList(),
      authorId: json["authorId"],
      createdAt: DateTime.parse(json["createdAt"]),
      likedBy: (json["likedBy"] as List).map((e) => e.toString()).toList(),
    );
  }

}