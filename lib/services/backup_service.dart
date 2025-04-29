// lib/services/backup_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../model/word_entry.dart';
import '../services/db_service.dart';
import '../services/storage_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Google 로그인 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file', // 앱이 생성한 파일에만 접근
    ],
  );

  // 데이터베이스 서비스
  final DBService _dbService = DBService();
  final StorageService _storageService = StorageService();

  // 로컬 설정 저장용 키
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _lastBackupNameKey = 'last_backup_name';
  static const String _backupFolderIdKey = 'backup_folder_id';

  // 앱 백업 폴더 이름
  static const String _appFolderName = '찍어보카_백업';

  // 로그인 및 Drive API 클라이언트 얻기
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // 이미 로그인 되어 있는지 확인
      if (await _googleSignIn.isSignedIn()) {
        final currentUser = await _googleSignIn.signInSilently();
        if (currentUser != null) {
          final authClient = await _googleSignIn.authenticatedClient();
          if (authClient != null) {
            return drive.DriveApi(authClient);
          }
        }
      }

      // 로그인 되어있지 않다면 로그인 시도
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('Google 로그인 취소됨');
        return null;
      }

      // 인증 클라이언트 생성
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        print('Google 인증 실패');
        return null;
      }

      return drive.DriveApi(authClient);
    } catch (e) {
      print('Google Drive API 접근 오류: $e');
      return null;
    }
  }

  // 로그인 상태 확인
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // 로그인
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      print('Google 로그인 오류: $e');
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google 로그아웃 오류: $e');
    }
  }

  // 현재 로그인된 사용자 정보
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  // 앱 전용 백업 폴더 ID 가져오기 (없으면 생성)
  Future<String?> _getOrCreateBackupFolder() async {
    // 로컬에 저장된 폴더 ID 확인
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? folderId = prefs.getString(_backupFolderIdKey);

    // 폴더 ID가 있으면 유효한지 확인
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    if (folderId != null) {
      try {
        // 폴더가 실제로 존재하는지 확인
        await driveApi.files.get(folderId);
        return folderId;
      } catch (e) {
        print('기존 백업 폴더를 찾을 수 없음: $e');
        // 폴더를 찾을 수 없으면 새로 생성
        folderId = null;
      }
    }

    // 폴더 생성
    try {
      final folder = drive.File(
        name: _appFolderName,
        mimeType: 'application/vnd.google-apps.folder',
      );

      final createdFolder = await driveApi.files.create(folder);
      folderId = createdFolder.id;

      // 로컬에 폴더 ID 저장
      if (folderId != null) {
        await prefs.setString(_backupFolderIdKey, folderId);
      }

      print('백업 폴더 생성됨: $folderId');
      return folderId;
    } catch (e) {
      print('백업 폴더 생성 오류: $e');
      return null;
    }
  }

  // 데이터베이스 파일 경로 얻기
  Future<String> _getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return path.join(documentsDirectory.path, 'vocabulary.db');
  }

  // 마지막 백업 시간 가져오기
  Future<DateTime?> getLastBackupTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupTimeKey);
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // 마지막 백업 이름 가져오기
  Future<String?> getLastBackupName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupNameKey);
  }

  // 백업 파일 업로드
  Future<bool> createBackup({String? customName}) async {
    try {
      // 드라이브 API 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('드라이브 API 접근 실패');
        return false;
      }

      // 백업 폴더 확인/생성
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) {
        print('백업 폴더를 생성할 수 없음');
        return false;
      }

      // 데이터베이스 파일 경로
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        print('데이터베이스 파일이 존재하지 않음: $dbPath');
        return false;
      }

      // 백업 파일 이름 생성
      final timestamp = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final formattedDate = dateFormat.format(timestamp);

      final backupName = customName != null && customName.isNotEmpty
          ? '$customName ($formattedDate).db'
          : '찍어보카_백업_$formattedDate.db';

      // 백업 파일 생성 및 업로드
      final file = drive.File(
        name: backupName,
        parents: [folderId],
      );

      final mediaStream = dbFile.openRead();
      final media = drive.Media(mediaStream, await dbFile.length());

      // 업로드 실행
      final uploadedFile = await driveApi.files.create(
        file,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        print('파일 업로드 실패');
        return false;
      }

      print('백업 완료: ${uploadedFile.id}');

      // 마지막 백업 정보 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupTimeKey, timestamp.millisecondsSinceEpoch);
      await prefs.setString(_lastBackupNameKey, backupName);

      return true;
    } catch (e) {
      print('백업 생성 오류: $e');
      return false;
    }
  }

  // 백업 파일 목록 가져오기
  Future<List<Map<String, dynamic>>> getBackupsList() async {
    List<Map<String, dynamic>> backups = [];

    try {
      // 드라이브 API 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('드라이브 API 접근 실패');
        return backups;
      }

      // 백업 폴더 ID 확인
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) {
        print('백업 폴더를 찾을 수 없음');
        return backups;
      }

      // 폴더 내 파일 목록 쿼리
      String query = "'$folderId' in parents and trashed=false";
      final response = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name, modifiedTime, size)',
        orderBy: 'modifiedTime desc',
      );

      final files = response.files;
      if (files == null || files.isEmpty) {
        print('백업 파일이 없음');
        return backups;
      }

      // 백업 정보 변환
      for (var file in files) {
        if (file.name != null && file.id != null && file.modifiedTime != null) {
          backups.add({
            'id': file.id!,
            'name': file.name!,
            'date': file.modifiedTime!,
            'size': file.size ?? 0,
          });
        }
      }

      return backups;
    } catch (e) {
      print('백업 목록 가져오기 오류: $e');
      return backups;
    }
  }

  // 백업 파일 복원
  Future<bool> restoreBackup(String fileId) async {
    try {
      // 드라이브 API 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('드라이브 API 접근 실패');
        return false;
      }

      // 임시 파일 경로 생성
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'temp_restore.db');
      final tempFile = File(tempPath);

      // 기존 임시 파일 삭제
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // 파일 다운로드
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 파일 저장
      final fileStream = response.stream;
      await tempFile.openWrite().addStream(fileStream);

      // 기존 데이터베이스 닫기
      final db = await _dbService.database;
      await db.close();

      // 데이터베이스 파일 경로
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      // 기존 파일 백업 (실패 시 복원용)
      final backupDbPath = '$dbPath.bak';
      final backupDbFile = File(backupDbPath);

      if (await backupDbFile.exists()) {
        await backupDbFile.delete();
      }

      if (await dbFile.exists()) {
        await dbFile.copy(backupDbPath);
      }

      // 복원 진행
      try {
        // 기존 파일 삭제 후 복원
        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        await tempFile.copy(dbPath);

        // 백업 파일 삭제
        await tempFile.delete();

        // 성공: 임시 백업 삭제
        if (await backupDbFile.exists()) {
          await backupDbFile.delete();
        }

        return true;
      } catch (e) {
        // 오류 발생: 백업에서 복원
        print('복원 중 오류 발생, 이전 상태로 복원: $e');

        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        if (await backupDbFile.exists()) {
          await backupDbFile.copy(dbPath);
          await backupDbFile.delete();
        }

        return false;
      }
    } catch (e) {
      print('백업 복원 오류: $e');
      return false;
    }
  }

  // 백업 파일 삭제
  Future<bool> deleteBackup(String fileId) async {
    try {
      // 드라이브 API 가져오기
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('드라이브 API 접근 실패');
        return false;
      }

      // 파일 삭제
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      print('백업 삭제 오류: $e');
      return false;
    }
  }

  // 데이터베이스 상태 검증 (복원 후 필요)
  Future<bool> validateDatabase() async {
    try {
      await _dbService.validateStorage();
      return true;
    } catch (e) {
      print('데이터베이스 검증 오류: $e');
      return false;
    }
  }
}
