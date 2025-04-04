// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'bigquery_chart_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/sign_in_error_message.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../constants/auth_constants.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

const String googleAuthUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
const String googleTokenUrl = 'https://oauth2.googleapis.com/token';
const String scopes = 'openid profile email';

final String redirectUri = kIsWeb
    ? webRedirectUri
    : (Platform.isAndroid ? androidRedirectUri : iosRedirectUri);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  late final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    print('SignInScreen initState: Checking for pre-obtained token.');
    _authenticateWithPreObtainedToken();

    if (!kIsWeb) {
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        print('SignInScreen: Received URI via app_links stream: $uri');
        if (uri != null && uri.toString().startsWith(redirectUri)) {
          _handleOAuthRedirect(uri);
        }
      }, onError: (err) {
        print('SignInScreen: Error receiving URI via app_links: $err');
        setState(() => _errorMessage = 'Failed to receive authentication response.');
      });

      _appLinks.getInitialLink().then((uri) {
        print('SignInScreen: Initial link received via app_links: $uri');
        if (uri != null && uri.toString().startsWith(redirectUri)) {
          _handleOAuthRedirect(uri);
        }
      });
    }
  }

  Future<void> _authenticateWithPreObtainedToken() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    print('SignInScreen: _authenticateWithPreObtainedToken started.');
    try {
      final accessToken = await _storage.read(key: 'gcp_oauth_token');
      if (accessToken != null && accessToken.isNotEmpty) {
        print('SignInScreen: Found existing access token: $accessToken (truncated)');
        Provider.of<AuthState>(context, listen: false).setAuthToken(accessToken);
        print('SignInScreen: Navigating to BigQueryChartScreen.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BigQueryChartScreen(
              columnNames: const [
                'TW_HOTBOXLOOP',
                'TW_LEFT_RET',
                'TW_RIGHT_RET',
                'TW_GH_RET',
                'TW_SHOP_RET',
                'QW_HOTBOXLOOP',
                'PANEL_TEMP',
                'PANEL_RH',
              ],
            ),
          ),
        );
      } else {
        print('SignInScreen: No existing access token found.');
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'No GCP OAuth 2.0 token found. Please authenticate.';
        });
      }
    } catch (error) {
      print('SignInScreen: Error authenticating with stored token: $error');
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'An error occurred during authentication.';
      });
    } finally {
      print('SignInScreen: _authenticateWithPreObtainedToken finished. _isAuthenticating: $_isAuthenticating, _errorMessage: $_errorMessage');
    }
  }

  Future<void> _startOAuthFlow() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    print('SignInScreen: _startOAuthFlow started.');

    String clientId;
    String redirectUriPlatform;

    if (kIsWeb) {
      clientId = webClientId;
      redirectUriPlatform = webRedirectUri;
      print('SignInScreen: Running on Web. Client ID: $clientId, Redirect URI: $redirectUriPlatform');
    } else if (Platform.isAndroid) {
      clientId = androidClientId;
      redirectUriPlatform = androidRedirectUri;
      print('SignInScreen: Running on Android. Client ID: $clientId, Redirect URI: $redirectUriPlatform');
    } else if (Platform.isIOS) {
      clientId = iosClientId;
      redirectUriPlatform = iosRedirectUri;
      print('SignInScreen: Running on iOS. Client ID: $clientId, Redirect URI: $redirectUriPlatform');
    } else {
      setState(() {
        _errorMessage = 'Unsupported platform for OAuth 2.0 flow.';
        _isAuthenticating = false;
      });
      print('SignInScreen: Unsupported platform.');
      return;
    }

    final authorizationUrl = Uri.parse('$googleAuthUrl?'
        'client_id=$clientId&'
        'redirect_uri=$redirectUriPlatform&'
        'response_type=code&'
        'response_type=code&' // Corrected: Should only be once
        'scope=$scopes&'
        'access_type=offline&'
        'prompt=select_account');

    print('SignInScreen: Authorization URL: $authorizationUrl');

    if (await canLaunchUrl(authorizationUrl)) {
      print('SignInScreen: Launching authorization URL.');
      await launchUrl(authorizationUrl, mode: LaunchMode.externalApplication);
      print('SignInScreen: Authorization URL launched.');
      // Note: _isAuthenticating remains true here until the redirect is handled.
    } else {
      setState(() {
        _errorMessage = 'Could not launch the authorization URL.';
        _isAuthenticating = false;
      });
      print('SignInScreen: Could not launch authorization URL.');
    }
    print('SignInScreen: _startOAuthFlow finished. _isAuthenticating: $_isAuthenticating, _errorMessage: $_errorMessage');
  }

  void _handleOAuthRedirect(Uri uri) async { // Added async
    print('SignInScreen: _handleOAuthRedirect called with URI: $uri');
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (code != null) {
      print('SignInScreen: Authorization Code received: $code (truncated)');
      setState(() {
        _isAuthenticating = true; // Keep loading indicator active
      });
      print('SignInScreen: Exchanging code for tokens...');
      try {
        //  TODO: Implement your code exchange logic here.  This is CRUCIAL.
        // 1.  Exchange code for tokens (access_token, refresh_token)
        // 2.  Store the tokens securely (using _storage)
        // 3.  Update the AuthState
        // 4.  Navigate to the next screen

        // Simulate a successful token exchange (replace with your actual logic)
        // For example, if you have a backend API:
        // final response = await http.post(
        //   Uri.parse('YOUR_BACKEND_TOKEN_ENDPOINT'),
        //   body: {'code': code, 'redirect_uri': redirectUriPlatform, /* other params */},
        // );
        //
        // if (response.statusCode == 200) {
        //   final data = json.decode(response.body);
        //   final accessToken = data['access_token'];
        //   final refreshToken = data['refresh_token']; // If you get one
        //
        //   await _storage.write(key: 'gcp_oauth_token', value: accessToken);
        //   if (refreshToken != null) {
        //     await _storage.write(key: 'gcp_refresh_token', value: refreshToken);
        //   }
        //
        //   Provider.of<AuthState>(context, listen: false).setAuthToken(accessToken);
        //
        //   print('SignInScreen: Token exchange successful.  Navigating...');
        //    Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => BigQueryChartScreen(
        //         columnNames: const [
        //           'TW_HOTBOXLOOP',
        //           'TW_LEFT_RET',
        //           'TW_RIGHT_RET',
        //           'TW_GH_RET',
        //           'TW_SHOP_RET',
        //           'QW_HOTBOXLOOP',
        //           'PANEL_TEMP',
        //           'PANEL_RH',
        //         ],
        //       ),
        //     ),
        //   );
        //
        //
        // } else {
        //   throw Exception('Failed to exchange code: ${response.body}');
        // }

        //Simulate
        await Future.delayed(const Duration(seconds: 2));
        const accessToken = 'simulated_access_token';
        await _storage.write(key: 'gcp_oauth_token', value: accessToken);
        Provider.of<AuthState>(context, listen: false).setAuthToken(accessToken);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BigQueryChartScreen(
              columnNames: const [
                'TW_HOTBOXLOOP',
                'TW_LEFT_RET',
                'TW_RIGHT_RET',
                'TW_GH_RET',
                'TW_SHOP_RET',
                'QW_HOTBOXLOOP',
                'PANEL_TEMP',
                'PANEL_RH',
              ],
            ),
          ),
        );
        print('SignInScreen: _handleOAuthRedirect: Code exchange complete, navigating');
      } catch (e) {
        print('SignInScreen: Error during token exchange or navigation: $e');
        setState(() {
          _errorMessage = 'Authentication failed: $e';
          _isAuthenticating = false;
        });
        return; // Important:  Exit the function on error!
      } finally {
        setState(() {
          _isAuthenticating = false; // VERY IMPORTANT:  Stop loading no matter what
        });
        print('SignInScreen: _handleOAuthRedirect: FINALLY, _isAuthenticating set to false');
      }
    } else if (error != null) {
      print('SignInScreen: OAuth Error received: $error');
      setState(() {
        _errorMessage = 'OAuth Error: $error';
        _isAuthenticating = false;
      });
    } else {
      print('SignInScreen: No code or error received in redirect URI.');
      setState(() {
        _errorMessage = 'Invalid authentication response.';
        _isAuthenticating = false;
      });
    }
    print('SignInScreen: _handleOAuthRedirect finished. _isAuthenticating: $_isAuthenticating, _errorMessage: $_errorMessage');
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SignInErrorMessage(errorMessage: _errorMessage),
              if (!_isAuthenticating && _errorMessage != null && _errorMessage!.contains('No GCP OAuth 2.0 token found'))
                ElevatedButton(
                  onPressed: _startOAuthFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'lib/assets/google_logo.png',
                        height: 24,
                      ),
                      const SizedBox(width: 16),
                      const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else if (_errorMessage != null && !_errorMessage!.contains('No GCP OAuth 2.0 token found'))
                ElevatedButton(
                  onPressed: _authenticateWithPreObtainedToken,
                  child: const Text('Retry Authentication'),
                )
              else if (_errorMessage == null && !_isAuthenticating && !Provider.of<AuthState>(context).isAuthenticated)
                const Text('Checking for existing authentication...')
              else if (Provider.of<AuthState>(context).isAuthenticated)
                const Text('Authenticated. Navigating...')
            ],
          ),
        ),
      ),
    );
  }
}

