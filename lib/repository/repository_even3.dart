import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:sqlite3/sqlite3.dart';

import '../models/attendee.dart';
import 'database_sqlite.dart';
import 'http_client_factory.dart'
    if (dart.library.js_interop) 'http_client_factory_web.dart' as http_factory;

final database = DatabaseSqlite.instance.db;

final class RepositoryEven3 {
  static final _instance = RepositoryEven3._();
  RepositoryEven3._();
  factory RepositoryEven3() => _instance;

  final _client = http_factory.httpClient();
  final _auth = {'Authorization-Token': 'Colocar sua chave aqui'};

  void close() async => _client.close();

  Future<List<Attendee>> getAttendees() async {
    final url = Uri.parse('https://www.even3.com.br/api/v1/attendees');
    final timer = Stopwatch()..start();
    try {
      final res = await _client
          .get(url, headers: _auth)
          .timeout(const Duration(seconds: 5));
      log('Tempo da requisição: ${timer.elapsedMilliseconds}');
      if (res.statusCode == 200) {
        return switch (jsonDecode(res.body)) {
          {'data': List data} => data.map((e) => Attendee.fromJson(e)).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
          _ => throw const FormatException(
              'Falha ao carregar os dados dos participantes!'),
        };
      }
    } on TimeoutException catch (e) {
      log('Conexão instável!', error: e);
    } catch (e, s) {
      log('Erro ao carregar os dados dos participantes',
          error: e, stackTrace: s);
    } finally {
      timer.stop();
      log('Tempo Total: ${timer.elapsedMilliseconds}');
    }
    return [];
  }

  Future<bool> checkin(Attendee attendee) async {
    final url = Uri.parse('https://www.even3.com.br/api/v1/checkin/attendees');
    final timer = Stopwatch()..start();
    save(attendee);
    try {
      final res = await _client
          .post(url,
              headers: _auth
                ..addAll({
                  'Content-Type': 'application/json; charset=UTF-8',
                }),
              body: jsonEncode({
                'attendees': [
                  {
                    'checkin_code': attendee.checkinCode.toString(),
                    'checkin': 1,
                    'checkin_date': DateTime.now().toIso8601String(),
                  }
                ]
              }))
          .timeout(const Duration(seconds: 5));
      log('Tempo do Checkin: ${timer.elapsedMilliseconds}');
      if (res.statusCode == 200) {
        return true;
      }
    } on TimeoutException catch (e) {
      log('Conexão instável!', error: e);
    } catch (e, s) {
      log('Erro ao fazer Checkin!', error: e, stackTrace: s);
    } finally {
      timer.stop();
      log('Tempo Total: ${timer.elapsedMilliseconds}');
    }
    return false;
  }

  Future<void> save(Attendee entity) async {
    try {
      database.execute(
          'INSERT INTO checkin (code, nome, data) VALUES (?, ?, ?)',
          [entity.checkinCode, entity.name, DateTime.now().toIso8601String()]);
    } on SqliteException catch (e) {
      log('${e.extendedResultCode}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Future<List<Attendees>> getAttendeeId(int id) async {
  //   final url = Uri.parse('https://www.even3.com.br/api/v1/attendees');
  //   final timer = Stopwatch()..start();
  //   try {
  //     final res = await _client.get(url, headers: _auth);
  //     log('Tempo de requisição: ${timer.elapsedMilliseconds}');
  //     if (res.statusCode == 200) {
  //       return switch (jsonDecode(res.body)) {
  //         {'data': List data} => data.map((e) => Attendees.fromJson(e)).toList()
  //           ..sort(
  //             (a, b) => a.name.compareTo(b.name),
  //           ),
  //         _ => throw const FormatException('Failed to load album.'),
  //       };
  //     }
  //   } catch (e) {
  //     print(e);
  //   } finally {
  //     timer.stop();
  //     print('Tempo Total: ${timer.elapsedMilliseconds}');
  //   }
  //   return [];
  // }
}
