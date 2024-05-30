import 'package:mongo_dart/mongo_dart.dart' as mongo;

class MongoService {
  static final MongoService _instance = MongoService._internal();
  late mongo.Db _db;

  factory MongoService() {
    return _instance;
  }

  MongoService._internal();

  Future<void> init() async {
    var uri =
        'mongodb+srv://admin:1234@flutter-revision.vpnokco.mongodb.net/?retryWrites=true&w=majority&appName=flutter-revision';

    int maxRetries = 3;
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        _db = await mongo.Db.create(uri);
        await _db.open();
        print('Connected to MongoDB');
        break;
      } catch (e) {
        retryCount++;
        print('Failed to connect to MongoDB. Retry $retryCount/$maxRetries');
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  mongo.Db get db => _db;

  Future<void> close() async {
    await _db.close();
  }
}
