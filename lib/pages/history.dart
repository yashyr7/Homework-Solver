import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slayschool_assesment/pages/solution.dart';

class History extends StatefulWidget {
  final List<String> questionHistory;

  const History({super.key, required this.questionHistory});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.questionHistory.length,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            // Navigate to the solution page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SolutionPage(
                  question: widget.questionHistory[index],
                ),
              ),
            );
          },
          title: Text(widget.questionHistory[index]),
        );
      },
    );
  }
}
