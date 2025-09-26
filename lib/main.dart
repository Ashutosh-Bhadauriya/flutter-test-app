import 'package:flutter/material.dart';
import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AuthsignalTestApp());
}

class AuthsignalTestApp extends StatelessWidget {
  const AuthsignalTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authsignal Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  late Authsignal authsignal;
  final TextEditingController _tenantIdController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  String _output = '';
  bool _isInitialized = false;
  String? _currentChallengeId;

  @override
  void initState() {
    super.initState();
    print('DEBUG: App initState called');
    _tenantIdController.text = '87902a54-1902-47a6-b492-43acb0dca6d2';
    _baseUrlController.text = 'https://api.authsignal.com/v1';
    _userIdController.text = 'test_user_flutter_${DateTime.now().millisecondsSinceEpoch}';
    _phoneController.text = '+1234567890';
    
    _addOutput('App started successfully!');
  }

  void _initializeAuthsignal() {
    try {
      authsignal = Authsignal(
        tenantID: _tenantIdController.text,
        baseURL: _baseUrlController.text,
      );
      setState(() {
        _isInitialized = true;
        _output = 'Authsignal initialized successfully!';
      });
    } catch (e) {
      _addOutput('Error initializing Authsignal: $e');
    }
  }

  void _addOutput(String message) {
    print('DEBUG: _addOutput called with: $message');
    setState(() {
      _output += '\n${DateTime.now().toIso8601String()}: $message';
    });
    print('DEBUG: _output is now: $_output');
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }

  Future<String?> _getRegistrationToken() async {
    try {
      _addOutput('Requesting registration token from test server...');
      final response = await http.post(
        Uri.parse('http://localhost:3000/test/registration-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userIdController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addOutput('Registration token received: ${data['state']}');
        return data['token'];
      } else {
        _addOutput('Failed to get registration token: ${response.statusCode}');
      }
    } catch (e) {
      _addOutput('Backend connection error: $e');
      _addOutput('Make sure the test server is running: npm start');
    }
    
    return null;
  }

  Future<String?> _getChallengeToken() async {
    try {
      _addOutput('Requesting challenge token from test server...');
      final response = await http.post(
        Uri.parse('http://localhost:3000/test/challenge-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userIdController.text,
          'phoneNumber': _phoneController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addOutput('Challenge token received: ${data['state']}');
        if (data['challengeId'] != null) {
          _addOutput('Challenge ID: ${data['challengeId']}');
        }
        return data['token'];
      } else {
        _addOutput('Failed to get challenge token: ${response.statusCode}');
      }
    } catch (e) {
      _addOutput('Backend connection error: $e');
      _addOutput('Make sure the test server is running: npm start');
    }
    
    return null;
  }

  Future<void> _setChallengeToken() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Getting challenge token from test server...');
      final token = await _getChallengeToken();
      
      if (token != null) {
        await authsignal.setToken(token);
        _addOutput('Challenge token set successfully!');
      } else {
        _addOutput('Failed to get challenge token');
      }
    } catch (e) {
      _addOutput('Error setting challenge token: $e');
    }
  }

  Future<void> _testGetDeviceCredential() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Getting device credential...');
      final result = await authsignal.device.getCredential();
      
      if (result.data != null) {
        _addOutput('Device credential found: ${result.data!.credentialId}');
        _addOutput('Created: ${result.data!.createdAt}');
        _addOutput('User ID: ${result.data!.userId}');
      } else {
        _addOutput('No device credential found');
      }
    } catch (e) {
      _addOutput('Error getting credential: $e');
    }
  }

  Future<void> _testAddDeviceCredential() async {
    print('DEBUG: _testAddDeviceCredential called');
    if (!_isInitialized) {
      print('DEBUG: Not initialized, returning');
      return;
    }
    
    try {
      print('DEBUG: About to call _addOutput');
      _addOutput('Getting registration token...');
      final token = await _getRegistrationToken();
      
      if (token != null) {
        await authsignal.setToken(token);
        _addOutput('Adding device credential...');
        
        final result = await authsignal.device.addCredential(
          token: token,
          deviceName: 'Test Flutter Device',
          userAuthenticationRequired: false,
        );
        
        if (result.data != null) {
          _addOutput('Device credential added successfully!');
          _addOutput('Credential ID: ${result.data!.credentialId}');
        } else {
          _addOutput('Failed to add device credential: ${result.error}');
        }
      }
    } catch (e) {
      _addOutput('Error adding credential: $e');
    }
  }

  Future<void> _testRemoveDeviceCredential() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Removing device credential...');
      final result = await authsignal.device.removeCredential();
      
      if (result.data == true) {
        _addOutput('Device credential removed successfully!');
      } else {
        _addOutput('Failed to remove credential: ${result.error}');
      }
    } catch (e) {
      _addOutput('Error removing credential: $e');
    }
  }

  Future<void> _testGetDeviceChallenge() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Checking for device challenges...');
      final result = await authsignal.device.getChallenge();
      
      if (result.data != null) {
        final challenge = result.data!;
        _addOutput('Device challenge found!');
        _addOutput('Challenge ID: ${challenge.challengeId}');
        _addOutput('Action: ${challenge.actionCode}');
        _addOutput('User Agent: ${challenge.userAgent}');
        _addOutput('IP Address: ${challenge.ipAddress}');
        
        setState(() {
          _currentChallengeId = challenge.challengeId;
        });
      } else {
        _addOutput('No pending device challenges');
      }
    } catch (e) {
      _addOutput('Error getting challenge: $e');
    }
  }

  Future<void> _testVerifyDevice() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Starting trusted device verification...');
      
      final token = await _getChallengeToken();
      if (token != null) {
        await authsignal.setToken(token);
        _addOutput('Challenge token set, starting device verification...');
        
        final result = await authsignal.device.verify();
        
        if (result.data != null) {
          _addOutput('Device verification successful!');
          _addOutput('Token: ${result.data!.token}');
          _addOutput('User ID: ${result.data!.userId}');
          _addOutput('User Authenticator ID: ${result.data!.userAuthenticatorId}');
          _addOutput('✅ Trusted device authentication completed!');
        } else {
          _addOutput('Device verification failed: ${result.error}');
        }
      } else {
        _addOutput('Failed to get challenge token');
      }
    } catch (e) {
      _addOutput('Error in device verification: $e');
    }
  }

  Future<void> _testApproveChallenge() async {
    if (!_isInitialized || _currentChallengeId == null) return;
    
    try {
      _addOutput('Claiming challenge...');
      final claimResult = await authsignal.device.claimChallenge(_currentChallengeId!);
      
      if (claimResult.data?.success == true) {
        _addOutput('Challenge claimed successfully!');
        
        _addOutput('Approving challenge...');
        final updateResult = await authsignal.device.updateChallenge(
          _currentChallengeId!,
          true,
        );
        
        if (updateResult.data == true) {
          _addOutput('Challenge approved successfully!');
          
          _addOutput('Verifying device...');
          final verifyResult = await authsignal.device.verify();
          
          if (verifyResult.data != null) {
            _addOutput('Device verification successful!');
            _addOutput('Token: ${verifyResult.data!.token}');
            _addOutput('User ID: ${verifyResult.data!.userId}');
          }
        }
      } else {
        _addOutput('Failed to claim challenge: ${claimResult.error}');
      }
    } catch (e) {
      _addOutput('Error approving challenge: $e');
    }
  }

  Future<void> _testRejectChallenge() async {
    if (!_isInitialized || _currentChallengeId == null) return;
    
    try {
      _addOutput('Rejecting challenge...');
      final result = await authsignal.device.updateChallenge(
        _currentChallengeId!,
        false,
      );
      
      if (result.data == true) {
        _addOutput('Challenge rejected successfully!');
      } else {
        _addOutput('Failed to reject challenge: ${result.error}');
      }
    } catch (e) {
      _addOutput('Error rejecting challenge: $e');
    }
  }

  Future<void> _testWhatsAppChallenge() async {
    if (!_isInitialized) return;
    
    try {
      _addOutput('Getting challenge token...');
      final token = await _getChallengeToken();
      
      if (token != null) {
        await authsignal.setToken(token);
        _addOutput('Starting WhatsApp challenge...');
        
        final result = await authsignal.whatsapp.challenge();
        
        if (result.data != null) {
          _addOutput('WhatsApp challenge created!');
          _addOutput('Challenge ID: ${result.data!.challengeId}');
          _addOutput('Check your WhatsApp for the OTP code');
          
          setState(() {
            _currentChallengeId = result.data!.challengeId;
          });
        } else {
          _addOutput('Failed to create WhatsApp challenge: ${result.error}');
        }
      }
    } catch (e) {
      _addOutput('Error creating WhatsApp challenge: $e');
    }
  }

  Future<void> _testWhatsAppVerify() async {
    if (!_isInitialized || _otpController.text.isEmpty) return;
    
    try {
      _addOutput('Verifying WhatsApp OTP...');
      final result = await authsignal.whatsapp.verify(_otpController.text);
      
      if (result.data != null) {
        if (result.data!.isVerified) {
          _addOutput('WhatsApp OTP verified successfully!');
          _addOutput('Token: ${result.data!.token}');
        } else {
          _addOutput('WhatsApp OTP verification failed');
          _addOutput('Reason: ${result.data!.failureReason}');
        }
      } else {
        _addOutput('WhatsApp verification error: ${result.error}');
      }
    } catch (e) {
      _addOutput('Error verifying WhatsApp OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Authsignal Test App'),
        actions: [
          IconButton(
            onPressed: _clearOutput,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Output',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tenantIdController,
                      decoration: const InputDecoration(labelText: 'Tenant ID'),
                    ),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(labelText: 'Base URL'),
                    ),
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(labelText: 'User ID'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isInitialized ? null : () {
                        print('DEBUG: Initialize button pressed');
                        _initializeAuthsignal();
                      },
                      child: Text(_isInitialized ? 'Initialized' : 'Initialize'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isInitialized ? _testGetDeviceCredential : null,
                          child: const Text('Get Credential'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? () {
                            print('DEBUG: Set Challenge Token button pressed');
                            _setChallengeToken();
                          } : null,
                          child: const Text('Set Challenge Token'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? () {
                            print('DEBUG: Add Credential button pressed');
                            _testAddDeviceCredential();
                          } : null,
                          child: const Text('Add Credential'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? _testRemoveDeviceCredential : null,
                          child: const Text('Remove Credential'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? _testGetDeviceChallenge : null,
                          child: const Text('Get Challenge'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? _testVerifyDevice : null,
                          child: const Text('Verify Device'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized && _currentChallengeId != null ? _testApproveChallenge : null,
                          child: const Text('Approve Challenge'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized && _currentChallengeId != null ? _testRejectChallenge : null,
                          child: const Text('Reject Challenge'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(labelText: 'OTP Code'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isInitialized ? _testWhatsAppChallenge : null,
                          child: const Text('Send OTP'),
                        ),
                        ElevatedButton(
                          onPressed: _isInitialized ? _testWhatsAppVerify : null,
                          child: const Text('Verify OTP'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔍 OUTPUT LOGS:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _output.isEmpty ? '⏳ Waiting for output...' : _output,
                        style: const TextStyle(
                          fontFamily: 'monospace', 
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tenantIdController.dispose();
    _baseUrlController.dispose();
    _userIdController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
