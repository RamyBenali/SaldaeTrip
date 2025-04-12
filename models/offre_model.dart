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
  });

  factory Offre.fromJson(Map<String, dynamic> json) {
    return Offre(
      id: json['idoffre'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      image: json['image'] ?? '',
      tarifs: json['tarifs'] ?? '',
      adresse: json['adresse'] ?? '',
      offreInsta: json['offre_insta'] ?? '',
      offreFb: json['offre_fb'] ?? '',
    );
  }
}
