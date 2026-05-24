import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserTransactions(String userId) {
    return _firestore.collection('wallet_transactions').where('user_id', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDepositRequests() {
    return _firestore.collection('wallet_transactions').where('type', isEqualTo: 'deposit').snapshots();
  }

  Future<void> ensureWallet(String userId) async {
    await _firestore.collection('wallets').doc(userId).set({
      'balance': 0,
      'held_balance': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> requestDeposit({required String userId, required String userName, required int amount}) async {
    if (amount <= 0) {
      throw Exception('So tien nap khong hop le.');
    }

    await ensureWallet(userId);
    await _firestore.collection('wallet_transactions').add({
      'user_id': userId,
      'user_name': userName,
      'type': 'deposit',
      'amount': amount,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmDeposit(String transactionId) async {
    final transactionRef = _firestore.collection('wallet_transactions').doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final transactionSnapshot = await transaction.get(transactionRef);
      if (!transactionSnapshot.exists || transactionSnapshot.data() == null) {
        throw Exception('Khong tim thay yeu cau nap tien.');
      }

      final data = transactionSnapshot.data()!;
      if (data['type'] != 'deposit' || data['status'] != 'pending') {
        throw Exception('Yeu cau nap tien khong hop le.');
      }

      final userId = data['user_id']?.toString() ?? '';
      final amount = data['amount'] is int
          ? data['amount'] as int
          : int.tryParse(data['amount']?.toString() ?? '') ?? 0;
      if (userId.isEmpty || amount <= 0) {
        throw Exception('Du lieu nap tien khong hop le.');
      }

      final walletRef = _firestore.collection('wallets').doc(userId);
      transaction.set(walletRef, {
        'balance': FieldValue.increment(amount),
        'held_balance': FieldValue.increment(0),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(transactionRef, {'status': 'confirmed', 'confirmed_at': FieldValue.serverTimestamp()});
    });
  }
}
