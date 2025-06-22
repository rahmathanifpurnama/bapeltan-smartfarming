class RealtimeModel {
  List<RealtimeData>? realtimeData;

  RealtimeModel({this.realtimeData});

  RealtimeModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  int? value;
  String? unit;
  String? updatedAt;

  RealtimeData({this.name, this.value, this.unit, this.updatedAt});

  RealtimeData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    value = json['value'];
    unit = json['unit'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['value'] = this.value;
    data['unit'] = this.unit;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
