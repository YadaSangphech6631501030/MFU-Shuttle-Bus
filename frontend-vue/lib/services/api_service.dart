import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://172.25.57.12:5001";

  // ===== COMMON FUNCTION =====
  static dynamic _handleResponse(http.Response res) {
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    try {
      return jsonDecode(res.body);
    } catch (e) {
      return {"error": "Server error (not JSON)"};
    }
  }

  // ================= AUTH =================

  static Future<String?> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
        }),
      );

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        return null;
      } else {
        return data["error"] ?? "Register failed";
      }
    } catch (e) {
      return "Network error";
    }
  }

  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setString("role", data["role"]);
        await prefs.setString("userId", data["userId"]);
        return data;
      } else {
        return data;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<String?> updateProfile(
    String username,
    String email,
    String password,
    String newPassword,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.put(
        Uri.parse("$baseUrl/auth/update"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "new_password": newPassword,
        }),
      );

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        return null;
      } else {
        return data["error"] ?? "Update failed";
      }
    } catch (e) {
      return "Network error";
    }
  }

  static Future<Map<String, dynamic>> getLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/auth/user"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = _handleResponse(res);

    if (res.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to load user");
    }
  }

  // ================= STATION =================

  static Future<List<dynamic>> getStations(String line) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/station/$line"));

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        return data;
      } else {
        throw Exception("Failed to load stations");
      }
    } catch (e) {
      throw Exception("Network error");
    }
  }

  // ================= BUS =================

  static Future<List<dynamic>> getBuses() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/buses"));

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        return data;
      } else {
        throw Exception("Failed to load buses");
      }
    } catch (e) {
      throw Exception("Network error");
    }
  }

  // ================= REPORT =================
static Future<String?> sendReport(
  String type,
  String detail,
  String location,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    final res = await http.post(
      Uri.parse("$baseUrl/api/report"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "type": type,
        "detail": detail,
        "location": location,
        "UserId": userId,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return null;
    }

    return "Send failed";
  } catch (e) {
    return "Network error";
  }
}

  // get report
  static Future<List<dynamic>> getReports() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/report"),
      );

      final data = _handleResponse(res);

      if (res.statusCode == 200) {
        return data;
      } else {
        throw Exception("Failed to load reports");
      }
    } catch (e) {
      throw Exception("Network error");
    }
  }

  // confirm report 
  static Future<void> confirmReport(String id) async {
    final url = Uri.parse("$baseUrl/api/report/$id");

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": "done",
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed to update");
    }
  }

}
