final class Attendee {
  int id;
  int idEvent;
  int checkinCode;
  String name;
  String? badgeName;
  String? email;
  String gender;
  String? photo;
  String? document;
  bool confirmed;
  Attendee({
    required this.id,
    required this.idEvent,
    required this.checkinCode,
    required this.name,
    this.badgeName,
    required this.email,
    required this.gender,
    this.photo,
    this.document,
    required this.confirmed,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id_attendee': int id,
        'id_event': int idEvent,
        'checkin_code': int checkinCode,
        'name': String name,
        'badge_name': String? bagdeName,
        'email': String email,
        'gender': String gender,
        'photo': String? photo,
        'document': String? document,
        'confirmed': bool confirmed,
      } =>
        Attendee(
          id: id,
          idEvent: idEvent,
          checkinCode: checkinCode,
          name: name,
          badgeName:
              bagdeName != null && bagdeName.isNotEmpty ? bagdeName : name,
          email: email,
          gender: gender,
          photo: photo,
          document: document,
          confirmed: confirmed,
        ),
      _ => throw const FormatException('Falha ao carregar o objeto Attendees'),
    };
  }

  @override
  bool operator ==(covariant Attendee other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
