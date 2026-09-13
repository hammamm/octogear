import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahala/core/theme/app_colors.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 4,
    this.onChanged,
    this.onCompleted,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _onChanged(int index, String value) {
    setState(() {});
    final otp = _controllers.map((controller) => controller.text).join();

    widget.onChanged?.call(otp);
    debugPrint(value);
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (otp.length == widget.length) {
          widget.onCompleted?.call(otp);
        }
      }
    } else if (index > 0) {
      // _focusNodes[index - 1].requestFocus();
    }
  }

  KeyEventResult _onKeyEvent(int index, node, event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final totalSpacing = spacing * (widget.length - 1);
        final boxWidth = (constraints.maxWidth - totalSpacing) / widget.length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...List.generate(widget.length, (index) {
              return SizedBox(
                width: boxWidth,
                height: 55,
                child: Focus(
                  onKeyEvent: (node, event) {
                    return _onKeyEvent(index, node, event);
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: _controllers[index].text.isNotEmpty,
                      fillColor: AppColors.primary.withValues(alpha: 0.1),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _controllers[index].text.isNotEmpty
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _onChanged(index, value);
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
