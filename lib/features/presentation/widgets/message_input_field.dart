import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/theme/app_theme.dart';

/// Widget for the message input field at the bottom of the chat
class MessageInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getInputPadding(context);
    final maxWidth = ResponsiveHelper.getMaxChatWidth(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: Row(
              children: [
                Expanded(child: _buildTextField(context)),
                SizedBox(width: isMobile ? 12 : 16),
                _buildSendButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final borderRadius = ResponsiveHelper.getBorderRadius(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: _hasText
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.primary.withOpacity(0.2),
          width: _hasText ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _hasText
                ? theme.colorScheme.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.2),
            blurRadius: _hasText ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(
          color: theme.colorScheme.onBackground,
          fontSize: isMobile ? 15 : 16,
        ),
        decoration: InputDecoration(
          hintText: 'Type a message...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onBackground.withOpacity(0.4),
            fontSize: isMobile ? 15 : 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 22 : 26,
            vertical: isMobile ? 14 : 16,
          ),
          suffixIcon: _hasText
              ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: theme.colorScheme.onBackground.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: () {
                  widget.controller.clear();
                },
              )
              : null,
        ),
        maxLines: null,
        maxLength: 500,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          if (!isFocused || currentLength == 0) return null;
          return Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Text(
              '$currentLength/$maxLength',
              style: TextStyle(
                fontSize: 11,
                color: currentLength > 450
                    ? theme.colorScheme.error
                    : theme.colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          );
        },
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => widget.onSend(),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final buttonSize =
        isMobile
            ? AppConstants.sendButtonSize
            : AppConstants.sendButtonSize + 4;

    // Button is enabled only if there's text AND not loading
    final isEnabled = _hasText && !widget.isLoading;

    return AnimatedScale(
      scale: isEnabled ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? AppTheme.primaryGradient
                : LinearGradient(
                  colors: [
                    const Color(AppConstants.primaryColorValue)
                        .withOpacity(0.4),
                    const Color(AppConstants.secondaryColorValue)
                        .withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(AppConstants.primaryColorValue)
                    .withOpacity(isEnabled ? 0.5 : 0.15),
                blurRadius: isEnabled ? 15 : 8,
                offset: const Offset(0, 4),
                spreadRadius: isEnabled ? 2 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(buttonSize / 2),
              onTap: isEnabled ? widget.onSend : null,
              child: AnimatedRotation(
                turns: isEnabled ? 0 : -0.1,
                duration: const Duration(milliseconds: 200),
                child: widget.isLoading
                    ? SizedBox(
                      width: isMobile ? 20 : 22,
                      height: isMobile ? 20 : 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    )
                    : Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: isMobile ? 20 : 22,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
