import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  test('fake firestore funciona', () async {
    final firestore = FakeFirebaseFirestore();

    await firestore.collection('test').add({
      'nombre': 'Kevin',
    });

    final snapshot = await firestore.collection('test').get();

    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first['nombre'], 'Kevin');
  });
}