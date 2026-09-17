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
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
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
    if (value.isEmpty) {
      // Deleting a digit moves focus to the previous box.
      if (index > 0) {
        final previousController = _controllers[index - 1];
        previousController.selection = TextSelection.collapsed(
          offset: previousController.text.length,
        );
        _focusNodes[index - 1].requestFocus();
      }
    } else if (value.length > 1) {
      // Example: "12" — keep "1" in the current box.
      _controllers[index].value = TextEditingValue(
        text: value[0],
        selection: const TextSelection.collapsed(offset: 1),
      );

      // No next box: ignore the extra digit.
      if (index == widget.length - 1) {
        return;
      }

      // Put "2" in the next box, then focus that filled box.
      _controllers[index + 1].value = TextEditingValue(
        text: value[1],
        selection: const TextSelection.collapsed(offset: 1),
      );
      _focusNodes[index + 1].requestFocus();
    }
    // Exactly one digit: keep focus where it is.

    setState(() {});

    final otp = _controllers.map((controller) => controller.text).join();
    widget.onChanged?.call(otp);

    if (value.isNotEmpty &&
        _controllers.every((controller) => controller.text.length == 1)) {
      widget.onCompleted?.call(otp);
    }
  }

  void reset() {
    if (!mounted) return;

    for (final controller in _controllers) {
      controller.clear();
    }

    setState(() {});

    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }

    widget.onChanged?.call('');
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
              //make the last input clickable only if the previous inputs have value
              final canTap =
                  index == widget.length - 1 &&
                  _controllers
                      .take(index)
                      .every((controller) => controller.text.length == 1);
              return SizedBox(
                width: boxWidth,
                height: 55,
                child: Focus(
                  child: AbsorbPointer(
                    absorbing: !canTap,
                    child: TextField(
                      showCursor: false,
                      autofocus: index == 0,
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 2,
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
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
