class Offre {
  final int id;
  final String nom;
  final String description;
  final String categorie;
  final String image;
  final String tarifs;
  final String adresse;
  final String offreInsta;
  final String offreFb;
  final double latitude;
  final double longitude;
  final double noteMoyenne;

  Offre({
    required this.id,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.image,
    required this.tarifs,
    required this.adresse,
    required this.offreInsta,
    required this.offreFb,
    required this.latitude,
    required this.longitude,
    required this.noteMoyenne,
  });

  factory Offre.fromJson(Map<String, dynamic> json) {
    return Offre(
      id: json['idoffre'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      image: json['image'] ?? '',
      tarifs: json['tarifs'] ?? '',
      adresse: json['adresse'] ?? '',
      offreInsta: json['offre_insta'] ?? '',
      offreFb: json['offre_fb'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      noteMoyenne: json['note_moyenne']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idoffre': id,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'image': image,
      'tarifs': tarifs,
      'adresse': adresse,
      'offre_insta': offreInsta,
      'offre_fb': offreFb,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
