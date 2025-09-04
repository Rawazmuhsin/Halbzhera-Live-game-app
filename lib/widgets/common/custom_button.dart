// File: lib/widgets/common/custom_button.dart
// Description: Reusable custom button widget with different styles and animations

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

enum ButtonType { primary, secondary, outline, text, social }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final Widget? leadingIcon;
  final Color? customColor;
  final double? width;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.leadingIcon,
    this.customColor,
    this.width,
    this.isFullWidth = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDisabled || widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isDisabled || widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isDisabled || widget.isLoading ? null : _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final buttonStyle = _getButtonStyle();
    final buttonHeight = _getButtonHeight();
    final textStyle = _getTextStyle();

    return Container(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: buttonHeight,
      decoration: buttonStyle.decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          onTap:
              widget.isDisabled || widget.isLoading ? null : widget.onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getHorizontalPadding(),
              vertical: _getVerticalPadding(),
            ),
            child: _buildButtonContent(textStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _getLoadingSize(),
          height: _getLoadingSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
          ),
        ),
      );
    }

    List<Widget> children = [];

    if (widget.leadingIcon != null) {
      children.add(widget.leadingIcon!);
      children.add(SizedBox(width: AppDimensions.paddingS));
    }

    children.add(
      Flexible(
        child: Text(
          widget.text,
          style: textStyle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (widget.icon != null) {
      children.add(SizedBox(width: AppDimensions.paddingS));
      children.add(widget.icon!);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  _ButtonStyle _getButtonStyle() {
    switch (widget.type) {
      case ButtonType.primary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            gradient:
                widget.customColor != null
                    ? LinearGradient(
                      colors: [widget.customColor!, widget.customColor!],
                    )
                    : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            boxShadow: [
              BoxShadow(
                color: (widget.customColor ?? AppColors.primaryRed).withOpacity(
                  0.4,
                ),
                blurRadius: AppDimensions.elevation3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );

      case ButtonType.secondary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            border: Border.all(
              color: AppColors.border1,
              width: AppDimensions.borderNormal,
            ),
          ),
        );

      case ButtonType.outline:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            border: Border.all(
              color: widget.customColor ?? AppColors.primaryRed,
              width: AppDimensions.borderNormal,
            ),
          ),
        );

      case ButtonType.text:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
        );

      case ButtonType.social:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.8),
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            border: Border.all(
              color: AppColors.border1,
              width: AppDimensions.borderNormal,
            ),
          ),
        );
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = _getFontSize();

    Color textColor;
    switch (widget.type) {
      case ButtonType.primary:
        textColor = AppColors.white;
        break;
      case ButtonType.secondary:
        textColor = AppColors.lightText;
        break;
      case ButtonType.outline:
        textColor = widget.customColor ?? AppColors.primaryRed;
        break;
      case ButtonType.text:
        textColor = widget.customColor ?? AppColors.lightText;
        break;
      case ButtonType.social:
        textColor = AppColors.lightText;
        break;
    }

    if (widget.isDisabled) {
      textColor = textColor.withOpacity(0.5);
    }

    return TextStyle(
      fontSize: fontSize,
      color: textColor,
      fontWeight: FontWeight.w600,
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppDimensions.radiusM;
      case ButtonSize.medium:
        return AppDimensions.radiusL;
      case ButtonSize.large:
        return AppDimensions.radiusL;
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppDimensions.paddingM;
      case ButtonSize.medium:
        return AppDimensions.paddingL;
      case ButtonSize.large:
        return AppDimensions.paddingXL;
    }
  }

  double _getVerticalPadding() {
    return AppDimensions.paddingS;
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  Color _getLoadingColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return AppColors.white;
      case ButtonType.secondary:
      case ButtonType.social:
        return AppColors.lightText;
      case ButtonType.outline:
        return widget.customColor ?? AppColors.primaryRed;
      case ButtonType.text:
        return widget.customColor ?? AppColors.lightText;
    }
  }
}

class _ButtonStyle {
  final BoxDecoration decoration;

  _ButtonStyle({required this.decoration});
}
