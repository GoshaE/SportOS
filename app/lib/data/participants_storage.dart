import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/event/event_config.dart';

class ParticipantsStorage {
  static const String _fileName = 'participants.json';

  Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> save(List<Participant> participants) async {
    try {
      final file = await _getFile();
      final listDynamic = participants.map((p) => p.toJson()).toList();
      final jsonStr = jsonEncode(listDynamic);
      await file.writeAsString(jsonStr);
      debugPrint('Participants saved: ${participants.length}');
    } catch (e) {
      debugPrint('Failed to save participants: $e');
    }
  }

  Future<List<Participant>?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return null; // Return null if file not found
      }
      final jsonStr = await file.readAsString();
      final listDynamic = jsonDecode(jsonStr) as List<dynamic>;
      final participants = listDynamic
          .map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('Participants loaded: ${participants.length}');
      return participants;
    } catch (e) {
      debugPrint('Failed to load participants: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
      debugPrint('Participants storage cleared.');
    } catch (e) {
      debugPrint('Failed to clear participants storage: $e');
    }
  }
}
