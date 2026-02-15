import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';

/// Widget for displaying a chat message bubble
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final avatarSize = ResponsiveHelper.getAvatarSize(context);
    final spacing = isMobile ? 10.0 : 14.0;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 18 : 22),
          child: Row(
            mainAxisAlignment:
                widget.message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.message.isUser) ...[
                _buildBotAvatar(context, avatarSize),
                SizedBox(width: spacing),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        ResponsiveHelper.isDesktop(context)
                            ? MediaQuery.of(context).size.width * 0.65
                            : double.infinity,
                  ),
                  child: _AnimatedBubble(
                    child: _buildBubble(context),
                    onCopy: () => _copyMessage(context),
                  ),
                ),
              ),
              if (widget.message.isUser) ...[
                SizedBox(width: spacing),
                _buildUserAvatar(context, avatarSize),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final padding = ResponsiveHelper.getMessagePadding(context);
    final fontSize = ResponsiveHelper.getMessageFontSize(context);
    final borderRadius = ResponsiveHelper.isMobile(context) ? 24.0 : 28.0;

    if (widget.message.isUser) {
      // User message with gradient
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: const Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                AppConstants.primaryColorValue,
              ).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: SelectableText(
                widget.message.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatTime(widget.message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: ResponsiveHelper.isMobile(context) ? 10 : 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Bot message with glassmorphism effect
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(AppConstants.botMessageColorValue),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: const Radius.circular(8),
            bottomRight: Radius.circular(borderRadius),
          ),
          border: Border.all(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: _buildBotMessageContent(context, fontSize),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormatter.formatTime(widget.message.timestamp),
              style: TextStyle(
                color: const Color(
                  AppConstants.textColorDarkValue,
                ).withOpacity(0.6),
                fontSize: ResponsiveHelper.isMobile(context) ? 10 : 11,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBotAvatar(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(
              AppConstants.secondaryColorValue,
            ).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.6),
    );
  }

  Widget _buildBotMessageContent(BuildContext context, double fontSize) {
    final messageText = widget.message.text;
    
    // Check if message contains HTML references section
    final referencesMatch = RegExp(
      r'<div class="references">.*?</div>',
      dotAll: true,
    ).firstMatch(messageText);
    
    String mainContent = messageText;
    List<Map<String, String>> references = [];
    
    if (referencesMatch != null) {
      // Extract main content without references
      mainContent = messageText.substring(0, referencesMatch.start).trim();
      
      // Extract references
      final referencesHtml = referencesMatch.group(0) ?? '';
      final linkMatches = RegExp(
        r'<a href="([^"]+)"[^>]*>([^<]+)</a>',
      ).allMatches(referencesHtml);
      
      for (final match in linkMatches) {
        references.add({
          'url': match.group(1) ?? '',
          'title': match.group(2) ?? '',
        });
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content with markdown
        MarkdownBody(
          data: mainContent,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: const Color(AppConstants.textColorDarkValue),
              fontSize: fontSize,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            strong: TextStyle(
              color: const Color(AppConstants.textColorDarkValue),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            listBullet: TextStyle(
              color: const Color(AppConstants.primaryColorValue),
              fontSize: fontSize,
            ),
            listIndent: 20,
            a: TextStyle(
              color: const Color(AppConstants.primaryColorValue),
              fontSize: fontSize,
              decoration: TextDecoration.underline,
            ),
          ),
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchUrl(href);
            }
          },
        ),
        
        // References section
        if (references.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildReferencesSection(context, references, fontSize),
        ],
      ],
    );
  }

  Widget _buildReferencesSection(
    BuildContext context,
    List<Map<String, String>> references,
    double fontSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColorValue).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.library_books_rounded,
                size: 16,
                color: Color(AppConstants.primaryColorValue),
              ),
              const SizedBox(width: 6),
              Text(
                'المراجع',
                style: TextStyle(
                  color: const Color(AppConstants.textColorDarkValue),
                  fontSize: fontSize - 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...references.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => _launchUrl(ref['url']!),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ref['title']!,
                          style: TextStyle(
                            color: const Color(AppConstants.primaryColorValue),
                            fontSize: fontSize - 2,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AnimatedBubble extends StatefulWidget {
  const _AnimatedBubble({
    required this.child,
    required this.onCopy,
  });

  final Widget child;
  final VoidCallback onCopy;

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final bubble = AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            widget.child,
            if (isDesktop)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Material(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onCopy,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isDesktop) {
      return bubble;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: bubble,
    );
  }
}
