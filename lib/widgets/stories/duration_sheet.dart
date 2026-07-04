import 'dart:ui';
import 'package:flutter/material.dart';

class DurationPickerButton extends StatefulWidget {
  const DurationPickerButton({
    super.key,
    required this.duration,
    required this.onChanged,
  });

  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  State<DurationPickerButton> createState() => _DurationPickerButtonState();
}

class _DurationPickerButtonState extends State<DurationPickerButton> {
  final _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  static const _options = <String, Duration>{
    '6 horas': Duration(hours: 6),
    '12 horas': Duration(hours: 12),
    '24 horas': Duration(hours: 24),
  };

  String get _label {
    if (widget.duration.inHours == 6) return '6';
    if (widget.duration.inHours == 12) return '12';
    return '24';
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    const popupWidth = 180.0;
    const popupHeight = 190.0;

    double left = buttonPosition.dx + buttonSize.width - popupWidth;
    if (left < 8) left = 8;
    if (left + popupWidth > screenSize.width - 8) {
      left = screenSize.width - popupWidth - 8;
    }

    double top = buttonPosition.dy - popupHeight - 12;
    if (top < 40) top = 40;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(left: left, top: top, child: _buildPopup()),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildPopup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._options.entries.map((entry) {
                final selected = entry.value == widget.duration;
                return InkWell(
                  onTap: () {
                    widget.onChanged(entry.value);
                    _removeOverlay();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: selected ? const Color(0xFF3E9BFF) : Colors.white,
                            fontSize: 16,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Divider(color: Colors.white.withOpacity(0.15), height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  'Escolha por quanto tempo\no story ficará visível.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleOverlay,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black.withOpacity(0.35),
            child: Text(
              _label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
