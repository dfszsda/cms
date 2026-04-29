import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> _initialize() async {
    await _googleSignIn.initialize(
      // Add clientId or serverClientId if needed for your platform
    );
  }

  GoogleSignInAccount? _user;

  Future<drive.DriveApi?> _getDriveApi() async {
    await _initialize();
    
    // Check if we need to authenticate
    _user = await _googleSignIn.attemptLightweightAuthentication();
    
    if (_user == null) {
      if (_googleSignIn.supportsAuthenticate()) {
        try {
          _user = await _googleSignIn.authenticate(
            scopeHint: [drive.DriveApi.driveFileScope],
          );
        } catch (e) {
          // ignore: avoid_print
          print("Authentication failed: $e");
          return null;
        }
      } else {
        // ignore: avoid_print
        print("Platform does not support interactive authentication.");
        return null;
      }
    }

    if (_user == null) return null;

    final authHeaders = await _user!.authorizationClient.authorizationHeaders([drive.DriveApi.driveFileScope]);
    if (authHeaders == null) return null;

    final authenticateClient = GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
  }

  Future<drive.File?> uploadFile(File file, String folderId) async {
    try {
      if (!file.existsSync()) {
        throw "File does not exist on device.";
      }
      
      final driveApi = await _getDriveApi();
      if (driveApi == null) throw "Could not connect to Google Drive. Please check your account.";

      final driveFile = drive.File();
      driveFile.name = file.path.split('/').last;
      driveFile.parents = [folderId];

      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        $fields: 'id, name, mimeType, webViewLink',
      ).timeout(const Duration(minutes: 5), onTimeout: () {
        throw "Upload timed out. Please try again with a better connection.";
      });

      return response;
    } catch (e) {
      throw "Drive Upload Error: $e";
    }
  }

  Future<List<drive.File>?> listFiles(String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) throw "Could not connect to Google Drive.";

      final response = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, webViewLink)',
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw "Failed to fetch files from Drive. Request timed out.";
      });

      return response.files;
    } catch (e) {
      throw "Drive List Error: $e";
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
