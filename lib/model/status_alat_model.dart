class StatusAlatModel {
  int? id;
  int? idUser;
  int? idAlat;
  int? status;

  StatusAlatModel({this.id, this.idUser, this.idAlat, this.status});

  StatusAlatModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idUser = json['idUser'];
    idAlat = json['idAlat'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['idUser'] = this.idUser;
    data['idAlat'] = this.idAlat;
    data['status'] = this.status;
    return data;
  }
}
