import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/main_layout.dart';
import '../../theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? selectedConversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MainLayout(
      title: 'Messages',
      subtitle: 'Communicate with your team',
      child: Row(
        children: [
          // Conversations List
          Container(
            width: 320,
            child: _ConversationsList(
              onConversationSelected: (id) {
                setState(() {
                  selectedConversation = id;
                });
              },
              selectedId: selectedConversation,
            ),
          ),
          // Chat Area
          Expanded(
            child: selectedConversation != null
                ? _ChatArea(conversationId: selectedConversation!)
                : Center(
                    child: Text(
                      'Select a conversation',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationsList extends StatelessWidget {
  final Function(String) onConversationSelected;
  final String? selectedId;

  const _ConversationsList({
    required this.onConversationSelected,
    this.selectedId,
  });

  static final List<Map<String, dynamic>> conversations = [
    {'id': '1', 'name': 'John Doe', 'lastMessage': 'Hey, can we discuss the project?', 'time': '10:30 AM', 'unread': 2},
    {'id': '2', 'name': 'Factory Team', 'lastMessage': 'QC report is ready', 'time': '9:15 AM', 'unread': 0},
    {'id': '3', 'name': 'Site Engineers', 'lastMessage': 'Material delivery scheduled', 'time': 'Yesterday', 'unread': 5},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversations',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final isSelected = selectedId == conv['id']!;
                
                return _ConversationTile(
                  conversation: conv,
                  isSelected: isSelected,
                  onTap: () => onConversationSelected(conv['id'] as String),
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (index * 50).ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppTheme.accentPurple.withOpacity(0.2),
                  AppTheme.accentBlue.withOpacity(0.2),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: AppTheme.accentPurple.withOpacity(0.5),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      conversation['name']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((conversation['unread'] as int) > 0)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${conversation['unread']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conversation['lastMessage']!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  conversation['time']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  final String conversationId;

  const _ChatArea({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> messages = [
      {'sender': 'John Doe', 'message': 'Hey, can we discuss the project details?', 'time': '10:25 AM', 'sent': false},
      {'sender': 'You', 'message': 'Sure, what do you need?', 'time': '10:27 AM', 'sent': true},
      {'sender': 'John Doe', 'message': 'I need the installation timeline', 'time': '10:30 AM', 'sent': false},
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentPurple,
                  child: const Text('JD'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Online',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isSent = msg['sent'] == true;
                return _MessageBubble(
                  message: msg['message'] as String,
                  time: msg['time'] as String,
                  isSent: isSent,
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (index * 50).ms)
                    .slideX(
                      begin: isSent ? 0.1 : -0.1,
                      end: 0,
                      duration: 200.ms,
                      delay: (index * 50).ms,
                    );
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {},
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSent;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSent
              ? LinearGradient(
                  colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                )
              : null,
          color: isSent ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSent
              ? null
              : Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isSent ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isSent
                    ? Colors.white.withOpacity(0.7)
                    : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
