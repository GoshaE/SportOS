import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/event/bib_undo_manager.dart';
import 'package:sportos_app/domain/event/event_config.dart';

void main() {
  group('BibUndoManager', () {
    late BibUndoManager manager;

    final p1 = Participant(
      id: 'p1',
      bib: '',
      name: 'John Doe',
      disciplineId: 'd1',
      disciplineName: '10km',
      registeredAt: DateTime(2025),
    );
    final p2 = Participant(
      id: 'p2',
      bib: '',
      name: 'Jane Smith',
      disciplineId: 'd1',
      disciplineName: '10km',
      registeredAt: DateTime(2025),
    );

    setUp(() {
      manager = BibUndoManager(maxHistory: 3);
    });

    test('initial state is empty', () {
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.undoCount, 0);
      expect(manager.redoCount, 0);
      expect(manager.lastUndoLabel, isNull);
      expect(manager.lastRedoLabel, isNull);
    });

    test('saveSnapshot adds to undo stack', () {
      manager.saveSnapshot('Action 1', [p1, p2]);

      expect(manager.canUndo, isTrue);
      expect(manager.undoCount, 1);
      expect(manager.lastUndoLabel, 'Action 1');
    });

    test('undo restores previous state and populates redo stack', () {
      manager.saveSnapshot('Action 1', [p1, p2]);

      // Simulate a change
      final changedParticipants = [
        p1.copyWith(bib: '10'),
        p2.copyWith(bib: '20'),
      ];

      final undoSnap = manager.undo(changedParticipants);

      expect(undoSnap, isNotNull);
      expect(undoSnap!.label, 'Action 1');
      expect(undoSnap.bibs['p1'], ''); // State BEFORE the change
      expect(undoSnap.bibs['p2'], '');

      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isTrue);
      expect(manager.redoCount, 1);
      expect(manager.lastRedoLabel, 'Action 1'); // The label follows the action
    });

    test('redo restores the undone change and populates undo stack', () {
      manager.saveSnapshot('Action 1', [p1, p2]);

      // Simulate a change
      final changedParticipants = [
        p1.copyWith(bib: '10'),
        p2.copyWith(bib: '20'),
      ];

      manager.undo(changedParticipants);

      // Now redo, passing the state we just reverted to (empty bibs)
      final revertedParticipants = [p1, p2];
      final redoSnap = manager.redo(revertedParticipants);

      expect(redoSnap, isNotNull);
      expect(redoSnap!.label, 'Action 1');
      expect(redoSnap.bibs['p1'], '10'); // State AFTER the change
      expect(redoSnap.bibs['p2'], '20');

      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
    });

    test('new action clears redo stack', () {
      manager.saveSnapshot('Action 1', [p1]);
      manager.undo([p1.copyWith(bib: '10')]);

      expect(manager.canRedo, isTrue);

      manager.saveSnapshot('Action 2', [p1]);

      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
      expect(manager.redoCount, 0);
    });

    test('respects maxHistory', () {
      manager.saveSnapshot('Action 1', [p1]);
      manager.saveSnapshot('Action 2', [p1]);
      manager.saveSnapshot('Action 3', [p1]);
      
      expect(manager.undoCount, 3);
      expect(manager.lastUndoLabel, 'Action 3');

      // 4th action should push out Action 1
      manager.saveSnapshot('Action 4', [p1]);
      
      expect(manager.undoCount, 3);
      expect(manager.lastUndoLabel, 'Action 4');
      
      final snap3 = manager.undo([p1]);
      expect(snap3?.label, 'Action 4');
      
      final snap2 = manager.undo([p1]);
      expect(snap2?.label, 'Action 3');
      
      final snap1 = manager.undo([p1]);
      expect(snap1?.label, 'Action 2');

      // Action 1 is gone
      expect(manager.undo([p1]), isNull);
    });

    test('clear resets both stacks', () {
      manager.saveSnapshot('Action 1', [p1]);
      manager.undo([p1.copyWith(bib: '10')]);

      manager.clear();

      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.undoCount, 0);
      expect(manager.redoCount, 0);
    });
  });
}
