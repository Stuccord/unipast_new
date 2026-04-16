import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unipast/features/viewer/ai_explanation_service.dart';

// ─────────────────────────────────────────────
//  Color palette for the God Mind screen
// ─────────────────────────────────────────────
class _GM {
  static const bg         = Color(0xFF070B14);
  static const surface    = Color(0xFF0D1526);
  static const card       = Color(0xFF111D35);
  static const divider    = Color(0xFF1E2F50);
  static const primary    = Color(0xFF00E5CC);   // electric teal
  static const secondary  = Color(0xFF7C3AED);   // vivid purple
  static const accent     = Color(0xFFFFB800);   // gold
  static const danger     = Color(0xFFFF4560);
  static const text       = Color(0xFFE2EAF4);
  static const textMuted  = Color(0xFF7B8BAA);
}

// ─────────────────────────────────────────────
//  Provider: mind map futures
// ─────────────────────────────────────────────
final mindMapProvider = FutureProvider.family<List<MindNode>, String>((ref, text) {
  return ref.read(aiExplanationServiceProvider).generateMindMap(text);
});

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────
class GodMindScreen extends ConsumerStatefulWidget {
  final String documentText;
  final String documentTitle;

  const GodMindScreen({
    super.key,
    required this.documentText,
    required this.documentTitle,
  });

  @override
  ConsumerState<GodMindScreen> createState() => _GodMindScreenState();
}

class _GodMindScreenState extends ConsumerState<GodMindScreen>
    with TickerProviderStateMixin {

  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _nodeCtrl;
  late final Animation<double> _pulseAnim;

  int _activeTab = 0; // 0=MindMap  1=Chat  2=Study
  bool _chatLoading = false;
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  MindNode? _expandedNode;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _nodeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _nodeCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final q = _chatCtrl.text.trim();
    if (q.isEmpty || _chatLoading) return;
    _chatCtrl.clear();

    setState(() {
      _messages.add(_ChatMsg(text: q, isUser: true));
      _chatLoading = true;
    });
    _scrollToBottom();

    try {
      final answer = await ref
          .read(aiExplanationServiceProvider)
          .askCustomQuestion(widget.documentText, q);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(text: answer, isUser: false));
        _chatLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(text: '❌ Connection error. Try again.', isUser: false));
        _chatLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _GM.bg,
      body: Stack(children: [
        // Animated background
        _AnimatedNeuralBg(rotateCtrl: _rotateCtrl, pulseAnim: _pulseAnim),

        // Main content
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ]),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _GM.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _GM.divider),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _GM.text, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'UNIPAST AI',
              style: GoogleFonts.orbitron(
                color: _GM.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            Text(
              widget.documentTitle,
              style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        // Glowing orb
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [_GM.primary, Color(0xFF004D45)]),
                boxShadow: [BoxShadow(color: _GM.primary.withAlpha(80), blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.psychology_rounded, color: _GM.bg, size: 22),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Tab Bar ───────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      (Icons.hub_rounded,   'Mind Map'),
      (Icons.chat_rounded,  'AI Chat'),
      (Icons.bolt_rounded,  'Study Mode'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _GM.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _GM.divider),
        ),
        child: Row(children: List.generate(tabs.length, (i) {
          final isActive = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isActive ? _GM.primary.withAlpha(20) : Colors.transparent,
                  border: isActive ? Border.all(color: _GM.primary.withAlpha(80)) : null,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(tabs[i].$1, size: 16,
                      color: isActive ? _GM.primary : _GM.textMuted),
                  const SizedBox(width: 6),
                  Text(tabs[i].$2,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? _GM.primary : _GM.textMuted,
                    ),
                  ),
                ]),
              ),
            ),
          );
        })),
      ),
    );
  }

  // ── Body ──────────────────────────────────
  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: switch (_activeTab) {
        0 => _MindMapTab(key: const ValueKey('mind'), docText: widget.documentText, expandedNode: _expandedNode, onExpand: (n) => setState(() => _expandedNode = n)),
        1 => _ChatTab(key: const ValueKey('chat'), messages: _messages, isLoading: _chatLoading, controller: _chatCtrl, scrollCtrl: _scrollCtrl, onSend: _sendMessage),
        _ => _StudyTab(key: const ValueKey('study'), docText: widget.documentText),
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 1 — MIND MAP
// ═══════════════════════════════════════════════
class _MindMapTab extends ConsumerWidget {
  final String docText;
  final MindNode? expandedNode;
  final ValueChanged<MindNode?> onExpand;

  const _MindMapTab({super.key, required this.docText, required this.expandedNode, required this.onExpand});

  static final List<Color> _nodeColors = [
    _GM.primary,
    _GM.secondary,
    _GM.accent,
    const Color(0xFF00B4D8),
    const Color(0xFFFF6B35),
    const Color(0xFF06D6A0),
    const Color(0xFFFF006E),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mindMapProvider(docText));

    return async.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (nodes) => _buildNodes(context, nodes),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _GlowPulse(child: Icon(Icons.hub_rounded, color: _GM.primary, size: 56)),
        const SizedBox(height: 24),
        Text('Mapping your knowledge...', style: GoogleFonts.orbitron(color: _GM.primary, fontSize: 14, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('Gemini AI is building your mind map', style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12)),
        const SizedBox(height: 32),
        // shimmer cards
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Shimmer.fromColors(
            baseColor: _GM.card,
            highlightColor: _GM.divider,
            child: Container(height: 72, decoration: BoxDecoration(color: _GM.card, borderRadius: BorderRadius.circular(20))),
          ),
        )),
      ]),
    );
  }

  Widget _buildError(String e) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, color: _GM.danger, size: 56),
        const SizedBox(height: 16),
        Text('Mind Map Error', style: GoogleFonts.inter(color: _GM.text, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(e, textAlign: TextAlign.center, style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12)),
      ]),
    ));
  }

  Widget _buildNodes(BuildContext context, List<MindNode> nodes) {
    if (expandedNode != null) {
      return _buildExpandedNode(context, expandedNode!);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Title banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_GM.primary.withAlpha(20), _GM.secondary.withAlpha(10)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _GM.primary.withAlpha(50)),
          ),
          child: Row(children: [
            const Icon(Icons.hub_rounded, color: _GM.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('${nodes.length} Core Concepts Mapped',
                style: GoogleFonts.inter(color: _GM.primary, fontWeight: FontWeight.bold, fontSize: 13))),
            Text('TAP TO EXPLORE', style: GoogleFonts.orbitron(color: _GM.textMuted, fontSize: 9, letterSpacing: 2)),
          ]),
        ),
        ...List.generate(nodes.length, (i) {
          final node = nodes[i];
          final color = _nodeColors[i % _nodeColors.length];
          return _NodeCard(node: node, color: color, index: i, onTap: () => onExpand(node));
        }),
      ],
    );
  }

  Widget _buildExpandedNode(BuildContext context, MindNode node) {
    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(children: [
          // Hero node
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [_GM.primary.withAlpha(30), _GM.card],
                center: Alignment.topLeft,
                radius: 1.5,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _GM.primary.withAlpha(100), width: 2),
              boxShadow: [BoxShadow(color: _GM.primary.withAlpha(40), blurRadius: 30)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(node.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(node.topic, style: GoogleFonts.orbitron(color: _GM.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(node.summary, style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 13, height: 1.4)),
                ])),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          // Subtopics
          ...node.subtopics.asMap().entries.map((e) {
            final idx = e.key;
            final sub = e.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + idx * 100),
              curve: Curves.easeOut,
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 20), child: child)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _GM.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _GM.divider),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _GM.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${idx + 1}',
                        style: GoogleFonts.orbitron(color: _GM.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(sub, style: GoogleFonts.inter(color: _GM.text, fontSize: 14, fontWeight: FontWeight.w500))),
                  const Icon(Icons.arrow_forward_ios_rounded, color: _GM.textMuted, size: 14),
                ]),
              ),
            );
          }),
        ]),
      ),
      // Back to map button
      Positioned(
        bottom: 20, left: 20, right: 20,
        child: GestureDetector(
          onTap: () => onExpand(null),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_GM.primary, Color(0xFF00B4A0)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _GM.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.hub_rounded, color: _GM.bg, size: 18),
              const SizedBox(width: 8),
              Text('Back to Mind Map', style: GoogleFonts.inter(color: _GM.bg, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ─── Node card ────────────────────────────────
class _NodeCard extends StatefulWidget {
  final MindNode node;
  final Color color;
  final int index;
  final VoidCallback onTap;
  const _NodeCard({required this.node, required this.color, required this.index, required this.onTap});

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: widget.index * 80), _ctrl.forward);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _ctrl.value,
        child: Transform.translate(offset: Offset(0, (1 - _ctrl.value) * 30), child: child),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _GM.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: widget.color.withAlpha(60)),
              boxShadow: [BoxShadow(color: widget.color.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              // Icon bubble
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withAlpha(50)),
                ),
                child: Center(child: Text(widget.node.icon, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.node.topic,
                    style: GoogleFonts.inter(color: _GM.text, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.node.summary,
                    style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (widget.node.subtopics.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 4,
                    children: widget.node.subtopics.take(3).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.color.withAlpha(40)),
                      ),
                      child: Text(s, style: GoogleFonts.inter(color: widget.color, fontSize: 10, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ])),
              Icon(Icons.chevron_right_rounded, color: widget.color.withAlpha(150), size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 2 — AI CHAT
// ═══════════════════════════════════════════════
class _ChatTab extends StatelessWidget {
  final List<_ChatMsg> messages;
  final bool isLoading;
  final TextEditingController controller;
  final ScrollController scrollCtrl;
  final VoidCallback onSend;

  const _ChatTab({super.key, required this.messages, required this.isLoading, required this.controller, required this.scrollCtrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(children: [
      // Chat messages
      Expanded(
        child: messages.isEmpty
            ? _buildEmptyChat()
            : ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == messages.length) return _TypingIndicator();
                  return _buildBubble(messages[i]);
                },
              ),
      ),

      // Input bar
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: _GM.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _GM.primary.withAlpha(60)),
            boxShadow: [BoxShadow(color: _GM.primary.withAlpha(20), blurRadius: 20)],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.inter(color: _GM.text, fontSize: 14),
                maxLines: null,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask anything about this document...',
                  hintStyle: GoogleFonts.inter(color: _GM.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_GM.primary, Color(0xFF00B4A0)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _GM.primary.withAlpha(80), blurRadius: 12)],
                  ),
                  child: const Icon(Icons.send_rounded, color: _GM.bg, size: 20),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _GlowPulse(child: Icon(Icons.psychology_alt_rounded, color: _GM.primary, size: 56)),
          const SizedBox(height: 24),
          Text('What would you like to understand?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _GM.text, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Ask any question about this document\nand Gemini AI will answer instantly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 32),
          // Suggestion chips
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: ['Summarise this', 'Key concepts', 'Exam tips', 'Explain derivations'].map((s) =>
              _SuggestionChip(label: s),
            ).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _GM.primary.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: _GM.primary.withAlpha(80)),
              ),
              child: const Icon(Icons.auto_awesome, color: _GM.primary, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: msg.isUser ? _GM.primary.withAlpha(30) : _GM.card,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: msg.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !msg.isUser ? const Radius.circular(4) : null,
                ),
                border: Border.all(
                  color: msg.isUser ? _GM.primary.withAlpha(80) : _GM.divider,
                ),
              ),
              child: MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.inter(color: _GM.text, fontSize: 14, height: 1.5),
                  strong: GoogleFonts.inter(color: _GM.primary, fontWeight: FontWeight.bold),
                  code: GoogleFonts.firaCode(color: _GM.accent, fontSize: 13,
                      backgroundColor: _GM.bg),
                  blockquote: GoogleFonts.inter(color: _GM.textMuted, fontSize: 13),
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _GM.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _GM.divider),
              ),
              child: const Icon(Icons.person_rounded, color: _GM.textMuted, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 3 — STUDY MODE
// ═══════════════════════════════════════════════
class _StudyTab extends ConsumerStatefulWidget {
  final String docText;
  const _StudyTab({super.key, required this.docText});

  @override
  ConsumerState<_StudyTab> createState() => _StudyTabState();
}

class _StudyTabState extends ConsumerState<_StudyTab> {
  String? _summary;
  bool _loading = false;
  bool _loaded = false;

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    final s = await ref.read(aiExplanationServiceProvider).summarizeDocument(widget.docText);
    if (!mounted) return;
    setState(() { _summary = s; _loading = false; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─ Headline card ─
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_GM.secondary.withAlpha(40), _GM.card],
              begin: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _GM.secondary.withAlpha(60)),
            boxShadow: [BoxShadow(color: _GM.secondary.withAlpha(30), blurRadius: 24)],
          ),
          child: Row(children: [
            const Text('⚡', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Smart Study Mode', style: GoogleFonts.orbitron(color: _GM.secondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('AI-powered focus tools to ace your exam.', style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12, height: 1.4)),
            ])),
          ]),
        ),

        const SizedBox(height: 24),

        // ─ AI Summary ─
        Text('AI Document Summary', style: GoogleFonts.inter(color: _GM.text, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (!_loaded) ...[
          if (_loading)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _GM.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _GM.divider)),
              child: Column(children: [
                Shimmer.fromColors(
                  baseColor: _GM.divider, highlightColor: _GM.surface,
                  child: Column(children: List.generate(4, (i) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(color: _GM.divider, borderRadius: BorderRadius.circular(8)),
                  ))),
                ),
                const SizedBox(height: 8),
                Text('Gemini AI is reading...', style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 12)),
              ]),
            )
          else
            GestureDetector(
              onTap: _loadSummary,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _GM.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _GM.primary.withAlpha(60)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.auto_awesome, color: _GM.primary, size: 22),
                  const SizedBox(width: 12),
                  Text('Generate AI Summary', style: GoogleFonts.inter(color: _GM.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
            ),
        ],

        if (_summary != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _GM.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _GM.divider),
            ),
            child: MarkdownBody(
              data: _summary!,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(color: _GM.text, fontSize: 13, height: 1.6),
                h2: GoogleFonts.inter(color: _GM.primary, fontWeight: FontWeight.bold, fontSize: 14),
                listBullet: GoogleFonts.inter(color: _GM.primary),
                strong: GoogleFonts.inter(color: _GM.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        // ─ Study Tools Grid ─
        Text('Study Tools', style: GoogleFonts.inter(color: _GM.text, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            _StudyToolCard(icon: '🎯', label: 'Practice Quiz', color: _GM.primary, subtitle: 'Test yourself', onTap: () {}),
            _StudyToolCard(icon: '📖', label: 'Flash Cards', color: _GM.secondary, subtitle: 'Quick recall', onTap: () {}),
            _StudyToolCard(icon: '🔥', label: 'Focus Timer', color: _GM.accent, subtitle: 'Pomodoro mode', onTap: () {}),
            _StudyToolCard(icon: '📊', label: 'Topic Map', color: const Color(0xFF00B4D8), subtitle: 'Visual overview', onTap: () {}),
          ],
        ),

        const SizedBox(height: 24),

        // ─ Exam Tips card ─
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_GM.accent.withAlpha(20), _GM.card]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _GM.accent.withAlpha(60)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Pro Exam Strategy', style: GoogleFonts.inter(color: _GM.accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 16),
            ...['Spend 2 minutes scanning all questions first', 'Tackle high-mark questions early', 'Leave 10 minutes to review answers', 'Bold keywords in theory answers'].map((tip) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 12),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _GM.accent)),
                  Expanded(child: Text(tip, style: GoogleFonts.inter(color: _GM.text, fontSize: 13, height: 1.4))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StudyToolCard extends StatefulWidget {
  final String icon, label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _StudyToolCard({required this.icon, required this.label, required this.color, required this.subtitle, required this.onTap});

  @override
  State<_StudyToolCard> createState() => _StudyToolCardState();
}

class _StudyToolCardState extends State<_StudyToolCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _GM.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withAlpha(60)),
            boxShadow: [BoxShadow(color: widget.color.withAlpha(20), blurRadius: 16)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.icon, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(widget.label, style: GoogleFonts.inter(color: _GM.text, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: GoogleFonts.inter(color: _GM.textMuted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  SHARED COMPONENTS
// ═══════════════════════════════════════════════

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _GM.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _GM.primary.withAlpha(50)),
      ),
      child: Text(label, style: GoogleFonts.inter(color: _GM.primary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _GM.primary.withAlpha(20),
            shape: BoxShape.circle,
            border: Border.all(color: _GM.primary.withAlpha(80)),
          ),
          child: const Icon(Icons.auto_awesome, color: _GM.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _GM.card,
            borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(4)),
            border: Border.all(color: _GM.divider),
          ),
          child: Row(children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final offset = math.sin((_ctrl.value * 2 * math.pi) + i * 1.2);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _GM.primary.withAlpha((128 + (offset * 127)).toInt().clamp(0, 255)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          })),
        ),
      ]),
    );
  }
}

class _GlowPulse extends StatefulWidget {
  final Widget child;
  const _GlowPulse({required this.child});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.scale(scale: _anim.value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _GM.primary.withAlpha(15),
            boxShadow: [BoxShadow(color: _GM.primary.withAlpha((40 * _anim.value).toInt()), blurRadius: 30 * _anim.value, spreadRadius: 4)],
          ),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ── Animated neural background ────────────────
class _AnimatedNeuralBg extends StatelessWidget {
  final AnimationController rotateCtrl;
  final Animation<double> pulseAnim;
  const _AnimatedNeuralBg({required this.rotateCtrl, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotateCtrl,
      builder: (_, __) => CustomPaint(
        painter: _NeuralPainter(rotateCtrl.value, pulseAnim.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NeuralPainter extends CustomPainter {
  final double t;
  final double pulse;
  _NeuralPainter(this.t, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final nodes = List.generate(16, (i) {
      final angle = (i / 16) * 2 * math.pi + t * 2 * math.pi;
      final r = size.width * 0.3 + math.sin(i * 1.5 + t * math.pi) * size.width * 0.15;
      return Offset(
        size.width / 2 + math.cos(angle) * r,
        size.height / 2 + math.sin(angle) * r * 0.6,
      );
    });

    // Draw connections
    final linePaint = Paint()
      ..color = const Color(0xFF00E5CC).withAlpha(12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if (rng.nextDouble() > 0.55) continue;
        canvas.drawLine(nodes[i], nodes[j], linePaint);
      }
    }

    // Draw nodes
    for (final n in nodes) {
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = const Color(0xFF00E5CC).withAlpha(18);
      canvas.drawCircle(n, 6 * pulse, glow);
      canvas.drawCircle(n, 2.5, Paint()..color = const Color(0xFF00E5CC).withAlpha(40));
    }

    // Central glow
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center, 120 * pulse,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
        ..color = const Color(0xFF00E5CC).withAlpha(8),
    );
  }

  @override
  bool shouldRepaint(_NeuralPainter old) => old.t != t || old.pulse != pulse;
}
