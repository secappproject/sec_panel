
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  
  final GlobalKey<NavigatorState> navigatorKey;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.timeoutDuration = const Duration(minutes: 15),
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  
  void _startTimer() {
    _timer = Timer(widget.timeoutDuration, _logout);
  }

  
  void _resetTimer() {
    _timer?.cancel(); 
    _startTimer(); 
  }

  
  Future<void> _logout() async {
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('companyId');
    await prefs.remove('loggedInUsername');
    

    
    
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);

      
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(
          content: Text("Sesi Anda telah berakhir karena tidak ada aktivitas."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
