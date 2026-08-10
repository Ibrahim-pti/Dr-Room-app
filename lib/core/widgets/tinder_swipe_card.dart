import 'package:flutter/material.dart';

class TinderSwipeCard extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onSwiped;
  
  const TinderSwipeCard({
    Key? key,
    required this.child,
    required this.onSwiped,
  }) : super(key: key);

  @override
  State<TinderSwipeCard> createState() => _TinderSwipeCardState();
}

class _TinderSwipeCardState extends State<TinderSwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _angle = 0;
  bool _isDragging = false;
  bool _isDismissed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _controller.stop();
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _angle = (_dragOffset.dx / MediaQuery.of(context).size.width) * 0.4;
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_dragOffset.dx.abs() > screenWidth * 0.3) {
      final direction = _dragOffset.dx.sign;
      final targetX = direction * screenWidth * 1.5;
      _animateOut(targetX);
    } else {
      _animateBack();
    }
  }
  
  void _animateBack() {
    final startOffset = _dragOffset;
    final startAngle = _angle;
    
    final anim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _angle = 0;
        });
      }
    });
    
    anim.addListener(() {
      if (mounted && !_isDragging) {
        setState(() {
          _dragOffset = startOffset * anim.value;
          _angle = startAngle * anim.value;
        });
      }
    });
  }
  
  void _animateOut(double targetX) {
    final startOffset = _dragOffset;
    final startAngle = _angle;
    
    final anim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward(from: 0).then((_) async {
      final success = await widget.onSwiped();
      if (mounted) {
        if (success) {
          setState(() {
            _isDismissed = true;
          });
        } else {
          _animateBack();
        }
      }
    });
    
    anim.addListener(() {
      if (mounted && !_isDragging) {
        setState(() {
          _dragOffset = Offset(
            startOffset.dx + (targetX - startOffset.dx) * anim.value,
            startOffset.dy,
          );
          _angle = startAngle + (startAngle.sign * 0.1) * anim.value; 
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _isDismissed
          ? const SizedBox(width: double.infinity, height: 0)
          : GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: _angle,
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ),
            ),
    );
  }
}
