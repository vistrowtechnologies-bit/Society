import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class PollsScreen extends StatefulWidget {
  final int societyId;

  const PollsScreen({super.key, required this.societyId});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  List<dynamic> _polls = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final polls = await ApiClient.polls(widget.societyId);
      setState(() {
        _polls = polls;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _vote(int pollId, int optionId) async {
    await ApiClient.votePoll(pollId, optionId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society polls')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : _polls.isEmpty
              ? const Center(child: Text('No polls right now', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _polls.length,
                    itemBuilder: (context, i) {
                      final poll = _polls[i];
                      final myVote = poll['my_vote_option_id'];
                      final options = poll['options'] as List<dynamic>;
                      final totalVotes = options.fold<int>(0, (sum, o) => sum + (o['vote_count'] as int));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(poll['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ...options.map((o) {
                                final pct = totalVotes > 0 ? (o['vote_count'] as int) / totalVotes : 0.0;
                                final isMine = myVote == o['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: myVote == null ? () => _vote(poll['id'], o['id']) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isMine ? AppColors.primary : AppColors.border, width: isMine ? 1.5 : 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (myVote != null)
                                            Positioned.fill(
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: pct,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(o['text'], style: TextStyle(fontWeight: isMine ? FontWeight.w600 : FontWeight.w400)),
                                              if (myVote != null) Text('${(pct * 100).round()}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              Text('$totalVotes vote${totalVotes == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
