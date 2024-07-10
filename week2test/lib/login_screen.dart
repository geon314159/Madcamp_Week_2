import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_screen.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/login_try'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User does not exist.')),
      );
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password.')),
      );
    } else if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      userId = responseData['user_id'];
      print('userId : $userId');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _signInWithKakao() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      User user = await UserApi.instance.me();

      List<String> scopes = [];
      if (user.kakaoAccount?.emailNeedsAgreement == true) {
        scopes.add('account_email');
      }
      if (user.kakaoAccount?.birthdayNeedsAgreement == true) {
        scopes.add("birthday");
      }
      if (user.kakaoAccount?.birthyearNeedsAgreement == true) {
        scopes.add("birthyear");
      }
      if (user.kakaoAccount?.ciNeedsAgreement == true) {
        scopes.add("account_ci");
      }
      if (user.kakaoAccount?.phoneNumberNeedsAgreement == true) {
        scopes.add("phone_number");
      }
      if (user.kakaoAccount?.profileNeedsAgreement == true) {
        scopes.add("profile");
      }
      if (user.kakaoAccount?.ageRangeNeedsAgreement == true) {
        scopes.add("age_range");
      }

      if (scopes.isEmpty) {
        print('사용자에게 추가 동의를 받아야 하는 항목이 있습니다');
        try {
          token = await UserApi.instance.loginWithNewScopes(scopes);
          print('현재 사용자가 동의한 동의 항목: ${token.scopes}');
        } catch (error) {
          print('추가 동의 요청 실패 $error');
          return;
        }

        // 사용자 정보 재요청
        try {
          user = await UserApi.instance.me();
          print('사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n이메일: ${user.kakaoAccount?.email}');
        } catch (error) {
          print('사용자 정보 요청 실패 $error');
          return;
        }
      }

      final String userId_kakao = '$user.id';
      await _checkUserAndProceed(userId_kakao);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kakao sign-in failed: $e')),
      );
    }
  }

  Future<void> _checkUserAndProceed(String userId_kakao) async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/google_login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': userId_kakao,
      }),
    );

    if (response.statusCode == 404) {
      // User does not exist, prompt to create a new account
      final String? username = await _showCreateAccountDialog(email: userId_kakao);
      if (username != null) {
        await _createUser(userId_kakao, username);
      }
    } else if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      userId = responseData['user_id'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _createUser(String userId_kakao, String username, [String? password]) async {
    final response = await http.post(
      Uri.parse('http://172.10.7.130:80/create_user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': userId_kakao, // 회원번호를 이메일 필드에 전송
        'username': username,
        'password': password ?? _passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      userId = responseData['user_id'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email already exists.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<String?> _showCreateAccountDialog({String? email}) async {
    final emailController = TextEditingController(text: email);
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == confirmPasswordController.text) {
                  Navigator.of(context).pop(usernameController.text);
                  _createUser(emailController.text, usernameController.text, passwordController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match.')),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xffa0d9d3),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.0),
              Image.asset('assets/logo.png'),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _signIn,
                    child: Text('Sign in'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _showCreateAccountDialog();
                    },
                    child: Text('Create Account'),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.1),
              ElevatedButton(
                onPressed: _signInWithKakao,
                child: Text('Log in with Kakao'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
