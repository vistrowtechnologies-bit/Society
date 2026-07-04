import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // 10.0.2.2 is how the Android emulator reaches the host machine's localhost.
  // Desktop/web builds use localhost directly.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _token();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception(_errorDetail(res.body) ?? 'Request failed');
    }
    return jsonDecode(res.body);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorDetail(res.body) ?? 'Request failed');
    }
    return jsonDecode(res.body);
  }

  static Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorDetail(res.body) ?? 'Request failed');
    }
  }

  static Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorDetail(res.body) ?? 'Request failed');
    }
    return jsonDecode(res.body);
  }

  static String? _errorDetail(String body) {
    try {
      return jsonDecode(body)['detail']?.toString();
    } catch (_) {
      return null;
    }
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await _post('/auth/login', {'email': email, 'password': password}, auth: false);
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    int? societyId,
  }) async {
    return await _post('/auth/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'society_id': societyId,
    }, auth: false);
  }

  static Future<Map<String, dynamic>> me() async => await _get('/auth/me');

  // Societies
  static Future<List<dynamic>> listSocieties() async => await _get('/societies');
  static Future<List<dynamic>> listTowers(int societyId) async =>
      await _get('/societies/$societyId/towers');
  static Future<List<dynamic>> listFlats(int towerId) async =>
      await _get('/societies/towers/$towerId/flats');

  // Membership
  static Future<void> joinFlat(int userId, int flatId) async {
    await _post('/members', {'user_id': userId, 'flat_id': flatId, 'relation': 'owner', 'is_primary': true});
  }

  static Future<List<dynamic>> myFlats() async => await _get('/members/me/flats');

  // Billing
  static Future<List<dynamic>> billsForFlat(int flatId) async =>
      await _get('/billing/bills/flat/$flatId');

  static Future<void> recordPayment(int billId, double amount, String method) async {
    await _post('/billing/payments', {'bill_id': billId, 'amount': amount, 'method': method});
  }

  // Notices
  static Future<List<dynamic>> notices(int societyId) async =>
      await _get('/notices/society/$societyId');

  static Future<Map<String, dynamic>> notice(int noticeId) async =>
      await _get('/notices/$noticeId');

  // Complaints
  static Future<Map<String, dynamic>> raiseComplaint({
    required int flatId,
    required String category,
    required String title,
    String? description,
  }) async {
    return await _post('/complaints', {
      'flat_id': flatId,
      'category': category,
      'title': title,
      'description': description,
    });
  }

  static Future<List<dynamic>> myComplaints() async => await _get('/complaints/me');

  // Documents
  static Future<List<dynamic>> documents(int societyId) async =>
      await _get('/documents/society/$societyId');

  static Future<void> uploadDocument({
    required int societyId,
    required String category,
    required String title,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/documents');
    final request = http.MultipartRequest('POST', uri);
    final token = await _token();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['society_id'] = societyId.toString();
    request.fields['category'] = category;
    request.fields['title'] = title;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));
    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      throw Exception('Upload failed');
    }
  }

  // Admin: complaints
  static Future<List<dynamic>> societyComplaints(int societyId, {String? status}) async {
    final query = status != null ? '?status_filter=$status' : '';
    return await _get('/complaints/society/$societyId$query');
  }

  static Future<void> updateComplaintStatus(int complaintId, String status) async {
    await _patch('/complaints/$complaintId/status', {'status': status});
  }

  // Admin: billing
  static Future<List<dynamic>> generateBillsForSociety({
    required int societyId,
    required int month,
    required int year,
    required double amountPerFlat,
    required String dueDate,
  }) async {
    return await _post('/billing/bills/generate-for-society', {
      'society_id': societyId,
      'period_month': month,
      'period_year': year,
      'amount_per_flat': amountPerFlat,
      'due_date': dueDate,
    });
  }

  static Future<List<dynamic>> defaulters(int societyId) async =>
      await _get('/billing/defaulters/$societyId');

  static Future<void> deleteBill(int billId) async => await _delete('/billing/bills/$billId');

  // Admin: notices edit/delete
  static Future<void> editNotice(int noticeId, Map<String, dynamic> fields) async =>
      await _patch('/notices/$noticeId', fields);

  static Future<void> deleteNotice(int noticeId) async => await _delete('/notices/$noticeId');

  static Future<void> deleteDocument(int documentId) async =>
      await _delete('/documents/$documentId');

  // Admin: notices
  static Future<void> createNotice({
    required int societyId,
    required String category,
    required String title,
    required String body,
  }) async {
    await _post('/notices', {
      'society_id': societyId,
      'category': category,
      'title': title,
      'body': body,
    });
  }

  // Admin: dashboard + directory
  static Future<Map<String, dynamic>> adminDashboard(int societyId) async =>
      await _get('/admin/dashboard/$societyId');

  static Future<List<dynamic>> directory(int societyId) async =>
      await _get('/admin/directory/$societyId');

  // AI Secretary
  static Future<Map<String, dynamic>> generateNoticeDraft({
    required String prompt,
    required String societyName,
  }) async {
    return await _post('/ai/generate-notice', {'prompt': prompt, 'society_name': societyName});
  }
}
