import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../utils/ui_helper.dart';
import 'package:native_exif/native_exif.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportViolationScreen extends StatefulWidget {
  const ReportViolationScreen({Key? key}) : super(key: key);



  @override
  _ReportViolationScreenState createState() => _ReportViolationScreenState();
}

class _ReportViolationScreenState extends State<ReportViolationScreen> with SingleTickerProviderStateMixin {
  String? _selectedViolationType;

  String get selectedViolationText {
    final selectedViolations = [
      for (int i = 0; i < _violationTypes.length; i++)
        if (_selectedTypes[i]) _violationTypes[i]
    ];
    return selectedViolations.join(', ');
  }

  String get violationText {
    List<String> selectedViolations = [
      for (int i = 0; i < _violationTypes.length; i++)
        if (_selectedTypes[i]) _violationTypes[i]
    ];
    // 아무것도 선택하지 않았고 기타 입력이 있다면 그 값 사용
    if (selectedViolations.isEmpty && _violationController.text.trim().isNotEmpty) {
      selectedViolations.add(_violationController.text.trim());
    }
    return selectedViolations.join(', ');
  }

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _violationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  bool _hasGpsData = false;
  String _gpsInfo = '';
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final List<String> _violationTypes = [
    '헬멧 미착용',
    '2인탑승',
    '인도주행',
  ];
  List<bool> _selectedTypes = [false, false, false];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _violationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Android 버전에 따른 권한 처리
      if (Platform.isAndroid) {
        // 필요한 권한 목록
        List<Permission> permissions = [
          Permission.storage,
          Permission.photos,
        ];

        // Android 10 이상에서만 필요한 ACCESS_MEDIA_LOCATION 권한 추가
        try {
          permissions.add(Permission.accessMediaLocation);
        } catch (e) {
          print("ACCESS_MEDIA_LOCATION 권한은 이 Android 버전에서 사용할 수 없습니다: $e");
        }

        // 권한 요청 및 확인
        bool allGranted = true;

        // 스토리지 권한 요청
        PermissionStatus storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          print("스토리지 권한 거부됨: $storageStatus");
          allGranted = false;
        }

        // 사진 권한 요청
        PermissionStatus photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          print("사진 권한 거부됨: $photosStatus");
          allGranted = false;
        }

        // ACCESS_MEDIA_LOCATION 권한 요청 (Android 10 이상)
        try {
          PermissionStatus mediaLocationStatus = await Permission.accessMediaLocation.request();
          if (!mediaLocationStatus.isGranted) {
            print("미디어 위치 권한 거부됨: $mediaLocationStatus");
            print("경고: ACCESS_MEDIA_LOCATION 권한이 없으면 Android 10 이상에서 GPS 정보가 제한될 수 있습니다.");
          }
        } catch (e) {
          print("ACCESS_MEDIA_LOCATION 권한 요청 오류: $e");
        }

        return allGranted;
      } else if (Platform.isIOS) {
        // iOS 권한 처리
        PermissionStatus photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      }

      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // EXIF 데이터에서 GPS 정보 체크하는 메서드 (native_exif 패키지 사용)
  Future<bool> _checkGpsExifData(File imageFile) async {
    try {
      // Exif 인스턴스 생성
      final exif = await Exif.fromPath(imageFile.path);

      // GPS 좌표 가져오기
      final coordinates = await exif.getLatLong();

      // 모든 EXIF 속성 가져오기 (디버깅용)
      final attributes = await exif.getAttributes();

      // GPS 정보 저장
      if (coordinates != null) {
        _gpsInfo = '${coordinates.latitude} ${coordinates.longitude}';

        // 경도/위도가 실제 존재하고 유효한지 확인
        final hasValidCoordinates = coordinates.latitude != 0 && coordinates.longitude != 0;

        // 위치 정보 자동 설정 (선택적)
        if (hasValidCoordinates) {
          // GPS 정보만 저장
        }

        // Exif 인터페이스 닫기
        await exif.close();

        return hasValidCoordinates;
      } else {
        // GPS 정보가 없는 경우 상세 정보 저장
        if (attributes != null) {
          bool hasGpsData = attributes.keys.any((key) => key.contains('GPS'));
          if (hasGpsData) {
            _gpsInfo = '이미지에 GPS 태그가 있지만 유효한 좌표를 추출할 수 없습니다.';
          } else {
            _gpsInfo = '이미지에 GPS 정보가 없습니다';
          }
        } else {
          _gpsInfo = '이미지에 EXIF 데이터가 없거나 추출할 수 없습니다';
        }

        // Exif 인터페이스 닫기
        await exif.close();

        return false;
      }
    } catch (e) {
      _gpsInfo = 'EXIF 데이터 읽기 오류: $e';
      return false;
    }
  }

  // 이미지 선택 메서드
  Future<void> _pickImage(ImageSource source) async {
    try {
      // 권한 요청
      bool permissionsGranted = await _requestPermissions();

      if (!permissionsGranted) {
        UIHelper.showWarningSnackBar(
          context,
          message: '일부 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.',
        );
        // 권한이 일부 없어도 계속 진행 (일부 기기에서는 작동할 수 있음)
      }

      // 이미지 선택기 호출
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        requestFullMetadata: true, // Android 10 이상에서는 이 옵션이 중요
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        // 로딩 상태 업데이트
        setState(() {
          _isLoading = true;
        });

        // GPS 정보 확인
        final hasGpsData = await _checkGpsExifData(imageFile);

        setState(() {
          _imageFile = imageFile;
          _hasGpsData = hasGpsData;
          _isLoading = false;
        });

        // GPS 정보가 없으면 경고 메시지 표시
        if (!hasGpsData) {
          UIHelper.showWarningSnackBar(
            context,
            message: 'GPS 정보가 없는 이미지입니다. GPS 정보가 포함된 이미지를 사용해주세요.',
          );
        } else {
          UIHelper.showSuccessSnackBar(
            context,
            message: 'GPS 정보가 확인되었습니다: $_gpsInfo',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      UIHelper.showErrorSnackBar(
        context,
        message: '이미지 선택 중 오류가 발생했습니다: $e',
      );
    }
  }

  // // 날짜 선택 메서드
  // Future<void> _selectDate() async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime.now(),
  //     builder: (context, child) {
  //       return Theme(
  //         data: ThemeData.light().copyWith(
  //           colorScheme: const ColorScheme.light(
  //             primary: Colors.orange,
  //             onPrimary: Colors.white,
  //             surface: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //           dialogBackgroundColor: Colors.white,
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null) {
  //     setState(() {
  //       _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
  //     });
  //   }
  // }

  // 위치 정보 문자열에서 좌표 추출
  GeoPoint? _extractCoordinates(String locationText) {
    try {
      // "위도: 37.123456, 경도: 127.123456" 형식에서 숫자만 추출
      RegExp latRegex = RegExp(r'위도:\s*([-+]?\d*\.\d+)');
      RegExp lngRegex = RegExp(r'경도:\s*([-+]?\d*\.\d+)');

      Match? latMatch = latRegex.firstMatch(locationText);
      Match? lngMatch = lngRegex.firstMatch(locationText);

      if (latMatch != null && lngMatch != null) {
        double latitude = double.parse(latMatch.group(1)!);
        double longitude = double.parse(lngMatch.group(1)!);
        return GeoPoint(latitude, longitude);
      }

      return null;
    } catch (e) {
      print('좌표 추출 오류: $e');
      return null;
    }
  }

  // 카메라 설정 가이드 대화상자
  void _showCameraSettingsGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('카메라 GPS 설정 방법'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '카메라로 찍은 사진에 GPS 정보가 포함되지 않는 경우:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildGuideStep('1', '기기의 기본 카메라 앱을 엽니다.'),
                _buildGuideStep('2', '카메라 설정 메뉴로 이동합니다 (일반적으로 화면의 상단이나 설정 아이콘을 탭하세요).'),
                _buildGuideStep('3', '"위치 태그" 또는 "위치 정보 저장" 옵션을 찾아 활성화합니다.'),
                _buildGuideStep('4', '기기 설정에서 위치 서비스가 켜져 있는지 확인하세요.'),
                const SizedBox(height: 12),
                const Text(
                  '주요 제조사별 설정 방법:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildManufacturerGuide('삼성', '카메라 앱 → 설정 → 위치 태그'),
                _buildManufacturerGuide('LG', '카메라 앱 → 설정 → 위치 정보 저장'),
                _buildManufacturerGuide('픽셀/구글', '카메라 앱 → 설정 → 위치 저장'),
                _buildManufacturerGuide('아이폰', '설정 → 개인 정보 보호 → 위치 서비스 → 카메라 → "앱을 사용하는 동안"으로 설정'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '실내에서는 GPS 신호가 약해 위치 정보가 저장되지 않을 수 있습니다. 가능하면 실외에서 촬영하세요.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 가이드 단계 위젯
  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // 제조사별 가이드 위젯
  Widget _buildManufacturerGuide(String manufacturer, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              manufacturer,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(instruction)),
        ],
      ),
    );
  }

  // 앱 설정으로 이동하는 함수
  void _openAppSettings() {
    openAppSettings();
  }

  // 신고 제출 메서드
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      // 폼 검증 성공
      if (_imageFile == null) {
        UIHelper.showWarningSnackBar(
          context,
          message: '이미지를 첨부해주세요',
        );
        return;
      }

      // GPS 정보 확인
      if (!_hasGpsData) {
        UIHelper.showErrorSnackBar(
          context,
          message: 'GPS 정보가 없는 이미지입니다. GPS 정보가 포함된 이미지를 사용해주세요.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 현재 사용자 가져오기
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          UIHelper.showErrorSnackBar(
            context,
            message: '로그인이 필요합니다',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        String? imageUrl;

        // 이미지 업로드
        if (_imageFile != null) {
          // 파일 이름 생성 (타임스탬프 사용)
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imageName = 'violation_reports/${user.uid}_$timestamp.jpg';

          // Firebase Storage에 이미지 업로드
          final storageRef = FirebaseStorage.instance.ref().child(imageName);
          final uploadTask = storageRef.putFile(_imageFile!);

          // 업로드 진행 상황을 사용자에게 보여줄 수 있음
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: $progress');
            // 여기서 진행 막대를 업데이트할 수 있음
          });

          final snapshot = await uploadTask;

          // 업로드된 이미지의 URL 가져오기
          imageUrl = await snapshot.ref.getDownloadURL();
        }

        // 위반 사항 텍스트 준비
        // 여러 개 선택된 위반 유형 추출
        final selectedViolations = [
          for (int i = 0; i < _violationTypes.length; i++)
            if (_selectedTypes[i]) _violationTypes[i]
        ];


        // 유저별 컬렉션에 데이터 저장
        // 먼저 users 컬렉션 아래에 유저 ID로 문서 생성 (없으면)
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // 리포트 데이터 생성
        final reportData = {
          'userId': user.uid,
          'userEmail': user.email,
          'date': Timestamp.now(),
          'violation': selectedViolations,
          'imageUrl': imageUrl,
          'hasGpsData': _hasGpsData, // GPS 정보 유무 저장
          'gpsInfo': _gpsInfo,       // 구체적인 GPS 정보 저장
          'status': 'submitted',     // 처리 상태
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 1. 새 문서 참조 생성 (ID 미리 확보)
        final reportDocRef = FirebaseFirestore.instance.collection('Report').doc();
        final reportId = reportDocRef.id;

        // 2. 기존 reportData 사용
        final reportDataWithId = {
          ...reportData,
          'reportId': reportId, // (선택) reportId 필드로도 저장
        };

        // 3. Report 컬렉션에 저장
        await reportDocRef.set(reportDataWithId);

        // 4. users/{uid}/reports/{reportId}에도 같은 데이터로 저장
        await userDocRef.collection('reports').doc(reportId).set(reportDataWithId);

        // 성공 메시지 표시
        if (mounted) {
          UIHelper.showSuccessSnackBar(
            context,
            message: '신고가 성공적으로 제출되었습니다',
          );

          // 폼 초기화 및 이미지 리셋 (성공 애니메이션과 함께)
          _resetForm();
        }
      } catch (e) {
        // 오류 처리
        if (mounted) {
          UIHelper.showErrorSnackBar(
            context,
            message: '신고 제출 중 오류가 발생했습니다: $e',
          );
        }
      } finally {
        // 로딩 상태 해제
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 폼 초기화 메서드
  void _resetForm() {
    _violationController.clear();
    setState(() {
      _selectedViolationType = null;
      _imageFile = null;
      _hasGpsData = false;
      _gpsInfo = '';
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });

    // 애니메이션 효과 재생
    _animationController.reset();
    _animationController.forward();
  }

  // 미리보기 대화상자 표시
  void _showPreviewDialog() {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      // GPS 정보 확인
      if (!_hasGpsData) {
        UIHelper.showErrorSnackBar(
          context,
          message: 'GPS 정보가 없는 이미지입니다. GPS 정보가 포함된 이미지를 사용해주세요.',
        );
        return;
      }

      final violationText = _selectedViolationType == '기타'
          ? _violationController.text.trim()
          : _selectedViolationType ?? _violationController.text.trim();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '신고 내용 확인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewItem('날짜', _dateController.text),
                      _buildPreviewItem('위반 사항', selectedViolationText),
                      _buildPreviewItem('GPS 정보', _hasGpsData ? _gpsInfo : '없음'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('수정하기'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _submitReport();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('신고하기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      UIHelper.showWarningSnackBar(
        context,
        message: '모든 필드를 입력하고 이미지를 첨부해주세요',
      );
    }
  }

  // 미리보기 항목 위젯
  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위반 사항 신고하기', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오늘 날짜', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.orange, width: 2),
                        ),
                        // suffixIcon: IconButton(
                        //   icon: const Icon(Icons.calendar_today, color: Colors.orange),
                        //   onPressed: _selectDate,
                        // ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '날짜를 선택해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('이미지 첨부', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _imageFile != null ?
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hasGpsData ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasGpsData ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasGpsData ? Icons.check_circle : Icons.error,
                              size: 16,
                              color: _hasGpsData ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _hasGpsData ? 'GPS 정보 포함' : 'GPS 정보 없음',
                              style: TextStyle(
                                fontSize: 12,
                                color: _hasGpsData ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ) : const SizedBox(),
                      const SizedBox(width: 8),
                      if (!_hasGpsData && _imageFile != null)
                        TextButton.icon(
                          onPressed: _openAppSettings,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('권한 설정'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                '이미지 선택',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                                ),
                                title: const Text('카메라로 촬영'),
                                subtitle: const Text('GPS 정보가 포함된 이미지를 촬영해 주세요'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.photo_library, color: Colors.green),
                                ),
                                title: const Text('갤러리에서 선택'),
                                subtitle: const Text('GPS 정보가 포함된 이미지를 선택해 주세요'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '* 위치 정보 권한을 허용해야 정확한 GPS 정보를 얻을 수 있습니다.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showCameraSettingsGuide();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepOrange,
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '카메라 GPS 설정 방법 알아보기 >',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _imageFile != null
                              ? (_hasGpsData ? Colors.green : Colors.red)
                              : Colors.grey,
                          width: _imageFile != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _imageFile != null
                            ? [
                                BoxShadow(
                                  color: _hasGpsData
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: _imageFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    _imageFile!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageFile = null;
                                        _hasGpsData = false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!_hasGpsData)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                      ),
                                      child: const Text(
                                        'GPS 정보가 없습니다. 다른 이미지를 선택해주세요.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : const Center(
                         child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'GPS 정보가 포함된 이미지를 선택해주세요',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '카메라 앱의 위치 정보 저장 기능을 켜고 촬영하세요',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('위반 사항', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // 위반 사항 선택 드롭다운
                  // 토글 버튼 UI
                  // ToggleButtons(
                  //   borderRadius: BorderRadius.circular(10),
                  //   fillColor: Colors.amber,
                  //   selectedColor: Colors.white,
                  //   color: Colors.black,
                  //   borderColor: Colors.amber,
                  //   selectedBorderColor: Colors.amber,
                  //   children: _violationTypes.map((type) => Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  //     child: Text(type),
                  //   )).toList(),
                  //   isSelected: _selectedTypes,
                  //   onPressed: (int index) {
                  //     setState(() {
                  //       _selectedTypes[index] = !_selectedTypes[index];
                  //     });
                  //   },
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTypes[0] = !_selectedTypes[0];
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTypes[0] ? Colors.orange : Colors.grey[200],
                          foregroundColor: _selectedTypes[0] ? Colors.white : Colors.black,
                        ),
                        child: Text(_violationTypes[0]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTypes[1] = !_selectedTypes[1];
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTypes[1] ? Colors.orange : Colors.grey[200],
                          foregroundColor: _selectedTypes[1] ? Colors.white : Colors.black,
                        ),
                        child: Text(_violationTypes[1]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTypes[2] = !_selectedTypes[2];
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTypes[2] ? Colors.orange : Colors.grey[200],
                          foregroundColor: _selectedTypes[2] ? Colors.white : Colors.black,
                        ),
                        child: Text(_violationTypes[2]),
                      ),
                    ),
                  ],
                ),


                  const SizedBox(height: 16),

                  // 기타 위반 사항일 경우 상세 설명 필드 표시
                  if (_selectedViolationType == '기타' || _selectedViolationType == null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _violationController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange, width: 2),
                          ),
                          hintText: _selectedViolationType == '기타'
                              ? '위반사항을 상세히 입력해주세요'
                              : '위반사항을 입력해주세요',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          // if (_selectedViolationType == '기타' && (value == null || value.isEmpty)) {
                          //   return '위반 사항을 입력해주세요';
                          // }
                          // if (_selectedViolationType == null && (value == null || value.isEmpty)) {
                          //   return '위반 사항을 선택하거나 입력해주세요';
                          // },
                          return null;
                         
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // GPS 정보 관련 안내 메시지
                  if (_imageFile != null && !_hasGpsData)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GPS 정보가 포함된 이미지가 필요합니다.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '다음을 확인해보세요:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('• 카메라 앱에서 위치 정보 저장 기능이 켜져 있는지 확인하세요.'),
                          const Text('• 앱 설정에서 위치 접근 권한이 허용되어 있는지 확인하세요.'),
                          const Text('• 직접 촬영한 사진을 사용하면 GPS 정보가 더 정확합니다.'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _openAppSettings,
                                icon: const Icon(Icons.settings, size: 16),
                                label: const Text('권한 설정'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // 신고하기 전 미리보기 버튼
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || (_imageFile != null && !_hasGpsData))
                            ? null
                            : _showPreviewDialog,
                        icon: const Icon(Icons.preview),
                        label: const Text('미리보기 및 신고하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          // 버튼 비활성화 스타일
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 도움말 대화상자
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '신고 방법 안내',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. 날짜 입력: 위반 사항을 목격한 날짜를 선택하세요.',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
        Text(
                          '2. 이미지 첨부: 위반 사항을 확인할 수 있는 사진을 첨부하세요. GPS 정보가 포함된 이미지만 사용 가능합니다. 위치 정보 저장 기능이 켜진 상태에서 촬영된 사진을 사용하세요.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '   * 카메라로 촬영 시: 기기의 카메라 앱 설정에서 "위치 태그" 또는 "위치 정보 저장" 기능이 켜져 있어야 합니다.',
                          style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '   * 갤러리에서 선택 시: 촬영 당시 위치 정보가 저장된 사진을 선택하세요.',
                          style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '3. 위반 사항 선택: 위반 사항의 유형을 선택하거나, \'기타\'를 선택한 경우 상세 내용을 입력하세요.',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '4. 미리보기 및 신고: 입력한 내용을 미리보기로 확인한 후 신고하세요.',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '※ GPS 정보가 없는 이미지는 신고가 불가능합니다. 꼭 GPS 정보가 포함된 이미지를 사용해 주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '※ 허위 신고나 악의적인 신고는 법적 책임이 따를 수 있습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}