class RealtimeDataDrawerModel {
  List<RealtimeData>? realtimeData;

  RealtimeDataDrawerModel({this.realtimeData});

  RealtimeDataDrawerModel.fromJson(Map<String, dynamic> json) {
    if (json['realtimeData'] != null) {
      realtimeData = <RealtimeData>[];
      json['realtimeData'].forEach((v) {
        realtimeData!.add(new RealtimeData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.realtimeData != null) {
      data['realtimeData'] = this.realtimeData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RealtimeData {
  int? idAlat;
  String? namaAlat;
  String? updatedAt;

  RealtimeData({this.idAlat, this.namaAlat, this.updatedAt});

  RealtimeData.fromJson(Map<String, dynamic> json) {
    idAlat = json['idAlat'];
    namaAlat = json['namaAlat'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idAlat'] = this.idAlat;
    data['namaAlat'] = this.namaAlat;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
