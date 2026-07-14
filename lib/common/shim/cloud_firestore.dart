/// Shim local: API mínima compatible con el uso de Firestore del proyecto.
/// Sustituye `package:cloud_firestore` sin SDK de Firebase.
library;

typedef FromFirestore<T> = T Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  SnapshotOptions? options,
);
typedef ToFirestore<T> = Map<String, dynamic> Function(
  T value,
  SetOptions? options,
);

class SnapshotOptions {}

class SetOptions {
  final bool? merge;
  const SetOptions({this.merge});
}

class FirebaseFirestore {
  FirebaseFirestore._();
  static final FirebaseFirestore instance = FirebaseFirestore._();
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      CollectionReference<Map<String, dynamic>>(this, path);

  WriteBatch batch() => WriteBatch(this);
}

class FieldValue {
  final String op;
  final dynamic value;
  FieldValue._(this.op, this.value);
  static FieldValue increment(num value) => FieldValue._('inc', value);
  static FieldValue arrayRemove(List elements) => FieldValue._('arrRem', elements);
  static FieldValue arrayUnion(List elements) => FieldValue._('arrUni', elements);
  static FieldValue delete() => FieldValue._('del', null);
  static FieldValue serverTimestamp() => FieldValue._('ts', null);
}

class WriteBatch {
  WriteBatch(this.db);
  final FirebaseFirestore db;
  final List<void Function()> ops = [];

  void delete(DocumentReference ref) {
    ops.add(() => ref._deleteRaw());
  }

  void set(DocumentReference ref, Map<String, dynamic> data) {
    ops.add(() => ref._setRaw(data));
  }

  void update(DocumentReference ref, Map<Object, Object?> data) {
    ops.add(() => ref._updateRaw(Map<String, dynamic>.from(data)));
  }

  Future<void> commit() async {
    for (final op in ops) {
      op();
    }
    ops.clear();
  }
}

class _Clause {
  _Clause(this.field,
      {this.isEqualTo, this.isGreaterThan, this.arrayContains, this.whereIn});
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic arrayContains;
  final List? whereIn;
}

enum DocumentChangeType { added, modified, removed }

class Query<T extends Object?> {
  Query(this.db, this.path,
      {this.fromFirestore,
      this.toFirestore,
      List<_Clause>? clauses,
      this.orderField,
      this.descending = false,
      this.limitCount})
      : clauses = clauses ?? [];

  final FirebaseFirestore db;
  final String path;
  final FromFirestore<T>? fromFirestore;
  final ToFirestore<T>? toFirestore;
  final List<_Clause> clauses;
  final String? orderField;
  final bool descending;
  final int? limitCount;

  Query<T> where(String field,
      {dynamic isEqualTo,
      dynamic isGreaterThan,
      dynamic arrayContains,
      List? whereIn}) {
    return Query<T>(db, path,
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
        clauses: [
          ...clauses,
          _Clause(field,
              isEqualTo: isEqualTo,
              isGreaterThan: isGreaterThan,
              arrayContains: arrayContains,
              whereIn: whereIn)
        ],
        orderField: orderField,
        descending: descending,
        limitCount: limitCount);
  }

  Query<T> orderBy(String field, {bool descending = false}) {
    return Query<T>(db, path,
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
        clauses: clauses,
        orderField: field,
        descending: descending,
        limitCount: limitCount);
  }

  Query<T> limit(int count) {
    return Query<T>(db, path,
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
        clauses: clauses,
        orderField: orderField,
        descending: descending,
        limitCount: count);
  }

  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) {
    // Pagination stub — returns the same query.
    return this;
  }

  Query<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return Query<R>(db, path,
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
        clauses: clauses,
        orderField: orderField,
        descending: descending,
        limitCount: limitCount);
  }

  List<MapEntry<String, Map<String, dynamic>>> _entries() {
    final col = db._store.putIfAbsent(path.split('/').first, () => {});
    // For nested paths like users/1/usersList we only support top-level collections.
    // Controllers that use nested paths via DocumentReference.collection still work.
    final top = path.contains('/') ? path : path;
    final map = db._store.putIfAbsent(top, () => {});
    var list = map.entries.toList();
    for (final c in clauses) {
      list = list.where((e) {
        final v = e.value[c.field];
        if (c.isEqualTo != null && v != c.isEqualTo) return false;
        if (c.isGreaterThan != null) {
          if (v is! Comparable || c.isGreaterThan is! Comparable) return false;
          return (v).compareTo(c.isGreaterThan) > 0;
        }
        if (c.arrayContains != null) {
          return v is List && v.contains(c.arrayContains);
        }
        if (c.whereIn != null) return c.whereIn!.contains(v);
        return true;
      }).toList();
    }
    if (orderField != null) {
      list.sort((a, b) {
        final av = a.value[orderField];
        final bv = b.value[orderField];
        if (av is Comparable && bv is Comparable) {
          final r = av.compareTo(bv);
          return descending ? -r : r;
        }
        return 0;
      });
    }
    if (limitCount != null && list.length > limitCount!) {
      list = list.take(limitCount!).toList();
    }
    return list;
  }

  Future<QuerySnapshot<T>> get() async {
    final docs = <QueryDocumentSnapshot<T>>[];
    for (final e in _entries()) {
      final fullPath = '$path/${e.key}';
      final mapSnap =
          DocumentSnapshot<Map<String, dynamic>>(fullPath, e.value, true);
      if (fromFirestore != null) {
        docs.add(QueryDocumentSnapshot<T>(
            fullPath, fromFirestore!(mapSnap, null), true));
      } else {
        docs.add(QueryDocumentSnapshot<T>(fullPath, e.value as T, true));
      }
    }
    return QuerySnapshot<T>(docs);
  }

  Stream<QuerySnapshot<T>> snapshots() async* {
    yield await get();
  }
}

class CollectionReference<T extends Object?> extends Query<T> {
  CollectionReference(super.db, super.path,
      {super.fromFirestore, super.toFirestore});

  DocumentReference<T> doc([String? id]) {
    final docId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return DocumentReference<T>(db, '$path/$docId',
        fromFirestore: fromFirestore, toFirestore: toFirestore);
  }

  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return CollectionReference<R>(db, path,
        fromFirestore: fromFirestore, toFirestore: toFirestore);
  }
}

class DocumentReference<T extends Object?> {
  DocumentReference(this.db, this.path, {this.fromFirestore, this.toFirestore});

  final FirebaseFirestore db;
  final String path;
  final FromFirestore<T>? fromFirestore;
  final ToFirestore<T>? toFirestore;

  String get id => path.split('/').last;

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      CollectionReference<Map<String, dynamic>>(db, '$path/$name');

  DocumentReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return DocumentReference<R>(db, path,
        fromFirestore: fromFirestore, toFirestore: toFirestore);
  }

  String get _colKey {
    final parts = path.split('/');
    // Support nested: users/1/usersList/2 -> key "users/1/usersList"
    return parts.sublist(0, parts.length - 1).join('/');
  }

  Map<String, dynamic>? _raw() {
    return db._store[_colKey]?[id];
  }

  void _setRaw(Map<String, dynamic> data) {
    db._store.putIfAbsent(_colKey, () => {})[id] =
        Map<String, dynamic>.from(data);
  }

  void _updateRaw(Map<String, dynamic> data) {
    final current = Map<String, dynamic>.from(_raw() ?? {});
    data.forEach((key, value) {
      if (value is FieldValue) {
        switch (value.op) {
          case 'inc':
            current[key] = ((current[key] as num?) ?? 0) + (value.value as num);
          case 'arrRem':
            final list = List.from(current[key] as List? ?? []);
            list.removeWhere((e) => (value.value as List).contains(e));
            current[key] = list;
          case 'arrUni':
            final list = List.from(current[key] as List? ?? []);
            for (final e in value.value as List) {
              if (!list.contains(e)) list.add(e);
            }
            current[key] = list;
          case 'del':
            current.remove(key);
        }
      } else {
        current[key] = value;
      }
    });
    _setRaw(current);
  }

  void _deleteRaw() {
    db._store[_colKey]?.remove(id);
  }

  Future<DocumentSnapshot<T>> get() async {
    final data = _raw();
    if (fromFirestore != null) {
      final mapSnap =
          DocumentSnapshot<Map<String, dynamic>>(path, data, data != null);
      final converted = data == null ? null : fromFirestore!(mapSnap, null);
      return DocumentSnapshot<T>(path, converted, data != null);
    }
    return DocumentSnapshot<T>(path, data as T?, data != null);
  }

  Future<void> set(Object? data, [SetOptions? options]) async {
    if (toFirestore != null) {
      _setRaw(toFirestore!(data as T, options));
    } else {
      _setRaw(Map<String, dynamic>.from(data as Map));
    }
  }

  Future<void> update(Map<Object, Object?> data) async {
    _updateRaw(Map<String, dynamic>.from(data));
  }

  Future<void> delete() async => _deleteRaw();

  Stream<DocumentSnapshot<T>> snapshots() async* {
    yield await get();
  }
}

class DocumentSnapshot<T extends Object?> {
  DocumentSnapshot(this.path, this._data, this.exists);
  final String path;
  final T? _data;
  final bool exists;
  String get id => path.split('/').last;
  T? data() => _data;
}

class QueryDocumentSnapshot<T extends Object?> extends DocumentSnapshot<T> {
  QueryDocumentSnapshot(String path, T data, bool exists)
      : super(path, data, exists);

  @override
  T data() => _data as T;
}

class DocumentChange<T extends Object?> {
  DocumentChange({
    required this.doc,
    this.type = DocumentChangeType.added,
  });
  final QueryDocumentSnapshot<T> doc;
  final DocumentChangeType type;
}

class QuerySnapshot<T extends Object?> {
  QuerySnapshot(this.docs);
  final List<QueryDocumentSnapshot<T>> docs;
  List<DocumentChange<T>> get docChanges =>
      docs.map((d) => DocumentChange<T>(doc: d)).toList();
}
