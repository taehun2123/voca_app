import 'package:flutter/material.dart';

class ApiGuideScreen extends StatelessWidget {
  const ApiGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API 설정 가이드'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OpenAI API 설정 가이드',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              
              // 섹션 1: 계정 생성
              _buildSection(
                title: '1. OpenAI 계정 로그인/회원가입',
                imagePath: 'assets/images/guide/Login.png',
                steps: [
                  'OpenAI 웹사이트(https://openai.com)에 접속합니다.',
                  '우측 상단에 아이콘 버튼을 클릭합니다.',
                  'Login버튼을 누르고 API Platform을 누릅니다.',
                  '이메일과 비밀번호를 입력하여 계정을 생성/로그인 합니다.',
                ],
              ),
              
              // 섹션 2: API 키 발급
              _buildSection(
                title: '2. API 키를 발급받기(1)',
                imagePath: 'assets/images/guide/Setting.png',
                steps: [
                  '로그인 후, 우측 상단의 메뉴 아이콘을 클릭합니다.',
                  '우측하단의 톱니바퀴 아이콘 메뉴를 선택합니다.',
                  '메뉴 중, API Keys 메뉴를 찾아 선택합니다.'
                ],
              ),
              _buildSection(
                title: '2-2. API 키를 발급받기(2)',
                imagePath: 'assets/images/guide/KeyGenerate.png',
                steps: [
                  '"Create New Secret" 버튼을 클릭합니다.',
                  'Name 및 Project, All을 선택한 후 "Create New Secret" 버튼을 선택합니다'
                  '중요: 생성된 API 키는 한 번만 표시되므로 안전한 곳에 복사해 두세요.',
                ],
              ),
              
              // 섹션 3: 결제 정보
              _buildSection(
                title: '3. 결제 정보 설정하기',
                imagePath: 'assets/images/guide/Billing.png',
                steps: [
                  '우측 메뉴바 아이콘을 클릭 후 메뉴에서 "Billing" 선택합니다.',
                  '"Add payment method" 버튼을 클릭합니다.',
                  '신용카드 정보를 입력하고 저장합니다.',
                ],
              ),
              
              // 섹션 4: 앱에 API 키 입력
              _buildSection(
                title: '4. 앱에 API 키 입력하기',
                imagePath: 'assets/images/guide/InsertKey.png',
                steps: [
                  '앱의 설정 메뉴로 이동합니다.',
                  '"OpenAI API 설정" 섹션에서 API 키 입력 필드에 복사한 키를 붙여넣습니다.',
                  '"저장" 버튼을 클릭합니다.',
                ],
              ),
              
              // 섹션 5: 요금 관리
              _buildSection(
                title: '5. 요금 관리하기',
                imagePath: 'assets/images/guide/Usage.png',
                steps: [
                  '메뉴의 "Billing" 탭에서 현재 남은 크레딧량을 확인할 수 있습니다.',
                  '자동으로 결제되지 않게 disable auto charge를 설정하여 예상치 못한 요금 발생을 방지할 수 있습니다.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required String imagePath,
    required List<String> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SizedBox(height: 12),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(step)),
            ],
          ),
        )),
        SizedBox(height: 24),
      ],
    );
  }
}