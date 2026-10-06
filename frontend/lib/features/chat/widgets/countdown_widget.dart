import 'dart:async';
import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  final DateTime expiresAt;
  final TextStyle style;

  const CountdownWidget({Key? key, required this.expiresAt, required this.style}) : super(key: key);

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final diff = widget.expiresAt.difference(DateTime.now().toUtc()).inSeconds;
    if (diff != _secondsLeft) {
      if (mounted) {
        setState(() {
          _secondsLeft = diff > 0 ? diff : 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) return const SizedBox.shrink();
    return Text('\u23F1 ${_secondsLeft}s', style: widget.style);
  }
}
