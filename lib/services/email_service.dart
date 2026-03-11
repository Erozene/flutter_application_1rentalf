import 'dart:convert';
import 'package:http/http.dart' as http;

const String _backendUrl = 'https://baserent.onrender.com';

class EmailService {
  Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      // Email errors are non-fatal — log and continue
      print('Email error ($path): $e');
    }
  }

  Future<void> bookingConfirmed({
    required String userEmail,
    required String equipmentTitle,
    required int days,
    required double total,
    required double depositAmount,
    required DateTime startDate,
    required DateTime endDate,
    required String bookingId,
  }) =>
      _post('/email/booking-confirmed', {
        'userEmail': userEmail,
        'equipmentTitle': equipmentTitle,
        'days': days,
        'total': total,
        'depositAmount': depositAmount,
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'bookingId': bookingId,
      });

  Future<void> bookingCancelled({
    required String userEmail,
    required String equipmentTitle,
    required String bookingId,
  }) =>
      _post('/email/booking-cancelled', {
        'userEmail': userEmail,
        'equipmentTitle': equipmentTitle,
        'bookingId': bookingId,
      });

  Future<void> depositReleased({
    required String userEmail,
    required String equipmentTitle,
    required double depositAmount,
    required String bookingId,
  }) =>
      _post('/email/deposit-released', {
        'userEmail': userEmail,
        'equipmentTitle': equipmentTitle,
        'depositAmount': depositAmount,
        'bookingId': bookingId,
      });

  Future<void> newMessage({
    required String recipientEmail,
    required String senderEmail,
    required String equipmentTitle,
    required String messagePreview,
  }) =>
      _post('/email/new-message', {
        'recipientEmail': recipientEmail,
        'senderEmail': senderEmail,
        'equipmentTitle': equipmentTitle,
        'messagePreview': messagePreview,
      });

  String _fmt(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
