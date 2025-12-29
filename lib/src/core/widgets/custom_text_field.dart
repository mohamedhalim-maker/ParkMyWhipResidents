import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';

class CustomTextField extends StatefulWidget {
  CustomTextField({
    super.key,
    required this.title,
    required this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.showError = true,
    BorderRadius? borderRadius,
    this.showTitle = true,
  }) : borderRadius = borderRadius ?? BorderRadius.circular(10);

  final String title;
  final String hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final void Function(String)? onChanged;

  /// Maximum number of lines for the text field (default: 1)
  final int maxLines;

  /// Maximum number of characters allowed (optional, no limit if null)
  final int? maxLength;

  /// Whether to show error message below field (default: true)
  final bool showError;

  /// Custom border radius for all corners (optional, defaults to BorderRadius.circular(10))
  final BorderRadius borderRadius;

  /// Whether to show title label above field (default: true)
  final bool showTitle;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Handles focus state changes to show/hide character counter
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  /// Returns current character count from the text field
  int get _currentLength => widget.controller?.text.length ?? 0;

  @override
  Widget build(BuildContext context) {
    // Get error from validator prop (from cubit state)
    final errorMessage = widget.validator?.call(widget.controller?.text);
    final hasError = errorMessage != null && errorMessage.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (conditionally shown)
        if (widget.showTitle) ...[
          Text(
            widget.title,
            style: AppTextStyles.urbanistFont14Grey700Regular1_28,
          ),
          verticalSpace(4),
        ],

        // Text Field
        TextFormField(
          obscuringCharacter: '⦁',
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.isPassword && _obscureText,
          style: AppTextStyles.urbanistFont16Grey800Regular1_3,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.isPassword ? 1 : null,
          inputFormatters: widget.maxLength != null
              ? [LengthLimitingTextInputFormatter(widget.maxLength)]
              : null,
          onChanged: (value) {
            widget.onChanged?.call(value);
            // Trigger rebuild to update character counter
            if (widget.maxLength != null && _isFocused) {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.urbanistFont16Grey800Opacity40Regular1_3,
            contentPadding: EdgeInsets.all(12.w),
            border: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: AppColor.grey300, width: 1.w),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(
                color: hasError && widget.showError ? AppColor.red500 : AppColor.grey300,
                width: 1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(
                color: hasError && widget.showError ? AppColor.red500 : AppColor.grey800,
                width: 1.w,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: AppColor.red500, width: 1.w),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius,
              borderSide: BorderSide(color: AppColor.red500, width: 1.w),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: hasError ? AppColor.red500 : AppColor.grey400,
                      size: 20.w,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),

        // Character Counter (shown when focused and maxLength is set)
        if (_isFocused && widget.maxLength != null&&widget.showError) ...[
          verticalSpace(4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_currentLength/${widget.maxLength}',
              style: AppTextStyles.urbanistFont12Grey800Regular1_64,
            ),
          ),
        ],

        // Error Message (only shown if showError is true)
        if (hasError && widget.showError) ...[
          verticalSpace(4),
          Text(
            errorMessage,
            style: AppTextStyles.urbanistFont12Red500Regular1_5,
          ),
        ],
      ],
    );
  }
}
