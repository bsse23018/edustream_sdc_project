import 'package:shared_preferences/shared_preferences.dart';
import 'package:minio/minio.dart';

// --- CONSTANTS ---
// Update this if you switch buckets, otherwise keep as is
const String BUCKET_NAME = 'edustream-bsse23018';

// Update this if you redeploy the Lambda
const String API_URL = 'https://pshzvxt3yotmxluqntuqh7thye0xngpg.lambda-url.us-east-1.on.aws/';
// -----------------

class AWSConfig {
  static Future<String> getPresignedUrl(String objectKey) async {
    final minio = await getMinio();
    // objectKey example: "course123/video.mp4"
    return await minio.presignedGetObject(BUCKET_NAME, objectKey, expires: 3600);
  }
  /// Establish connection to S3
  static Future<Minio> getMinio() async {
    final prefs = await SharedPreferences.getInstance();

    return Minio(
      endPoint: 's3.amazonaws.com',
      accessKey: prefs.getString('access_key')!,
      secretKey: prefs.getString('secret_key')!,
      sessionToken: prefs.getString('session_token')!,
      region: 'us-east-1',
      // enableTrace: false, // Debugging removed for production
    );
  }

  /// Helper to check if user is logged in
  static Future<bool> hasCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('session_token') != null && prefs.getString('session_token')!.isNotEmpty);
  }

  /// Clear keys on full reset (Optional)
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}