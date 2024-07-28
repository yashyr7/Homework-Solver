import 'package:flutter/material.dart';
import 'package:slayschool_assesment/commons.dart';
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
          title: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: parseTextWithLatex(widget.questionHistory[index]),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
