class Record {
  String? id;
  String? data;
  DateTime? date;

  Record({this.id, this.data, this.date});

  Record.fromMap(Map<String, dynamic> map) {
    id = map['_id']?.toHexString();
    data = map['data'];
    date = map['date'] != null ? DateTime.tryParse(map['date']) : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'date': date?.toIso8601String(),
    };
  }
}
