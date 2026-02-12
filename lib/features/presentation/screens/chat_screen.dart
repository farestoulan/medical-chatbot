import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
import '../widgets/background_logo.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';

/// Main chat screen widget
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    const threshold = 120.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = maxScroll - currentScroll <= threshold;

    if (_showScrollToBottom == isAtBottom) return;

    setState(() {
      _showScrollToBottom = !isAtBottom;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatCubit cubit, [String? customMessage]) {
    final message = customMessage ?? _messageController.text;
    if (message.trim().isEmpty) return;

    if (customMessage == null) {
      _messageController.clear();
    }
    cubit.sendMessage(message);
    _scrollToBottom();
  }

  void _handleSuggestionTap(String suggestion) {
    final cubit = context.read<ChatCubit>();
    _sendMessage(cubit, suggestion);
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: AppConstants.scrollDelayMs), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(
            milliseconds: AppConstants.scrollAnimationDurationMs,
          ),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildResponsiveChatContent(
    ChatLoaded state, {
    bool isLoading = false,
  }) {
    final isEmpty = state.messages.isEmpty;

    return Stack(
      children: [
        // Background logo - more visible when empty, subtle when has messages
        BackgroundLogo(isEmptyState: isEmpty),
        // Chat content + scroll-to-bottom button
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  ResponsiveHelper.getMaxChatWidth(context) ?? double.infinity,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child:
                          isEmpty
                              ? EmptyChatState(
                                onSuggestionTap: _handleSuggestionTap,
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                ),
                                itemCount:
                                    state.messages.length + (isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (isLoading && index == state.messages.length) {
                                    return const TypingIndicator();
                                  }
                                  return MessageBubble(
                                    message: state.messages[index],
                                  );
                                },
                              ),
                    ),
                    MessageInputField(
                      controller: _messageController,
                      onSend: () => _sendMessage(context.read<ChatCubit>()),
                      isLoading: isLoading,
                    ),
                  ],
                ),
                if (_showScrollToBottom && !isEmpty)
                  Positioned(
                    right: 16,
                    bottom: 90,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_to_bottom_fab',
                      elevation: 2,
                      onPressed: _scrollToBottom,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ChatAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withOpacity(0.3),
            ],
          ),
        ),
        child: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded || state is ChatLoading) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            if (state is ChatInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChatError) {
              // Show error as snackbar and display messages if available
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              });

              // If there are messages, show them; otherwise show error screen
              if (state.messages.isNotEmpty) {
                return _buildResponsiveChatContent(ChatLoaded(state.messages));
              }

              return Center(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: ResponsiveHelper.isMobile(context) ? 64 : 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize:
                              ResponsiveHelper.isMobile(context) ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ChatLoading) {
              return _buildResponsiveChatContent(
                ChatLoaded(state.messages),
                isLoading: true,
              );
            }

            if (state is ChatLoaded) {
              return _buildResponsiveChatContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
