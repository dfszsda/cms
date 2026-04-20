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
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final driveFile = drive.File();
      driveFile.name = file.path.split('/').last;
      driveFile.parents = [folderId];

      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        $fields: 'id, name, mimeType, webViewLink',
      );

      return response;
    } catch (e) {
      // ignore: avoid_print
      print("Drive Upload Error: $e");
      return null;
    }
  }

  Future<List<drive.File>?> listFiles(String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final response = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, webViewLink)',
      );

      return response.files;
    } catch (e) {
      // ignore: avoid_print
      print("Drive List Error: $e");
      return null;
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
