import 'dart:convert';
import 'dart:io';

import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:widgets_to_image/widgets_to_image.dart';

class SolutionPage extends StatefulWidget {
  final String question;
  const SolutionPage({super.key, required this.question});

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer API_KEY',
  };

  String hint = "";
  String answer = "";
  String similarQuestions = "";
  String questionResponse = "";
  bool isAnswerDisplayed = false;

  final WidgetsToImageController _controller = WidgetsToImageController();
  TextEditingController _fileNameController = TextEditingController();

  final _systemPrompt = '''
      You are a helpful high school teacher. The user will ask you a question which will probably be a high school level problem and you need to explain it to a high school student.
      The question asked by the user might contain some unrelated text which is not a part of the question. You need to filter out and identify the question correctly.
      Please write all math equations, formulas, units and symbols using Latex. Make sure to wrap all math equations, formulas, units and symbols using Inline math modes(\\( and \\)) and Display math mode(\\[ and \\]) This is a must for all math related questions.
      Do not use any markup language in your response. Do not use double asterisks for bold text or triple hashes for headers. Use plain text for everything.
      Make sure that your response is in the same language as the language used in the question asked by the user.
      If the prompt provided by user is not a question, you should respond with "The provided image does not contain a question!".
      ''';
  final _hintSystemPrompt = '''
      If the user asks for a hint, you should provide a hint. The hint should be no more than 2 lines in length.
      ''';
  final _answerSystemPrompt = '''
      If the user asks for the solution, you should provide a step-wise solution. Be sure to explain each step in a concise way.
      Make sure that your answer is complete and easy to understand for a high school student while being concise.
      Use the least amount of words possible.
      Get straight to the point and dont use any unnecessary words. Dont waste words at the start and end of the response. Your response should contain only the solution and nothing else.
      Your response should be in the following format:
      Start your answer by mentioning the given variables and formulas that we will need. List out each variable and formula in a separate line.
      Then start explaining the solution step by step. For each step, first give a brief summary of what is being done in the step.
      For each step, explain how it is being done in detail. Make sure to explain each step in a concise way. This should not be more than 2 lines.
      Each equation should be written in a separate line.
      Each step of solving an equation should be written in a separate line. This means that any line should not conatin more than 1 '=' sign.
      Dont write anything after writing the final answer. The final answer should be the last thing in your response.
      If the prompt provided by user is not a question, you should respond with "The provided image does not contain a question!".
      ''';

  final _similarQuestionsSystemPrompt = '''
      If the user asks for similar questions, you should provide 5 similar questions. The questions should be similar to the question asked by the user.
      The questions should be high school level problems and should be related to the question asked by the user.
      The questions should be different from the question asked by the user but should be similar in nature.
      The questions should be related to the same topic as the question asked by the user.
      Your response should only contain the 5 questions and nothing else numbered from 1 to 5.
      ''';

  // Function to parse text with LaTeX
  List<InlineSpan> parseTextWithLatex(String text) {
    final regex = RegExp(r'(\\\(.+?\\\))|(\\\[.+?\\\])', dotAll: true);
    final matches = regex.allMatches(text);

    int currentIndex = 0;
    List<InlineSpan> spans = [];

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        );
      }
      final latex = text.substring(match.start + 2, match.end - 2);
      spans.add(
        WidgetSpan(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Math.tex(
              latex,
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      );
    }

    return spans;
  }

  // Function to get hint
  void getHint() async {
    final body = json.encode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'system', 'content': _hintSystemPrompt},
        {
          'role': 'user',
          'content':
              'Can you give me a hint for this question? ${widget.question}'
        }
      ]
    });
    if (hint == "") {
      // Make a POST request to the OpenAI API
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // If the request is successful, update the hint text
        print("response received");
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          hint = data['choices'][0]['message']['content'];
          questionResponse = hint;
        });
        print(questionResponse);
      } else {
        // Show an alert dialog if the request fails
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to get hint'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        questionResponse = hint;
      });
    }
  }

  // Get the answer for the question
  void getAnswer() async {
    final body = json.encode({
      'model': 'gpt-4o',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'system', 'content': _answerSystemPrompt},
        {
          'role': 'user',
          'content':
              'Can you give me the solution for this question? ${widget.question}'
        }
      ]
    });

    if (answer == "") {
      // Make a POST request to the OpenAI API
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // If the request is successful, update the answer text
        print("response received");
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          answer = data['choices'][0]['message']['content'];
          questionResponse = answer;
        });
        print(questionResponse);
      } else {
        // Show an alert dialog if the request fails
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to get hint'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        questionResponse = answer;
      });
    }
  }

  void getSimilarQuestions() async {
    final body = json.encode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'system', 'content': _similarQuestionsSystemPrompt},
        {
          'role': 'user',
          'content':
              'Can you give me 5 similar questions to this question? ${widget.question}'
        }
      ]
    });

    if (similarQuestions == "") {
      // Make a POST request to the OpenAI API
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // If the request is successful, update the similar questions text
        print("response received");
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          similarQuestions = data['choices'][0]['message']['content'];
          questionResponse = similarQuestions;
        });
        print(questionResponse);
      } else {
        // Show an alert dialog if the request fails
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to get hint'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        questionResponse = similarQuestions;
      });
    }
  }

  // Function to export the question and answer as a PDF
  Future<void> _exportPDF(String fileName) async {
    // Capture the image of the answer
    final bytes = await _controller.capture();
    if (bytes == null) {
      print('Error capturing the image.');
      return;
    }

    final pdf = pw.Document(); // Create a new PDF document

    final image = pw.MemoryImage(bytes);

    // Add a new page to the PDF document
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Question:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(widget.question, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Answer:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Image(
                image,
                width: 600,
                height: 600,
              ),
            ],
          );
        },
      ),
    );

    // Replace spaces with underscores of the file name
    fileName = fileName.replaceAll(' ', '_');

    // Get the document directory
    Directory? documentsDirectory = await getApplicationDocumentsDirectory();
    String documentsDirectoryPath = documentsDirectory.path;

    // Save the PDF file to the documents directory
    final file = File('$documentsDirectoryPath/$fileName.pdf');
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes.toList());
    DocumentFileSavePlus().saveFile(pdfBytes, "$fileName.pdf", "$fileName.pdf");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to Documents folder!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Solution'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.question,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        questionResponse = "Generating Response...";
                        isAnswerDisplayed = false;
                      });
                      getHint();
                    },
                    child: const Text("Hint"),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        questionResponse = "Generating Response...";
                        isAnswerDisplayed = true;
                      });
                      getAnswer();
                    },
                    child: const Text("Explain Answer"),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    questionResponse = "Generating Response...";
                    isAnswerDisplayed = false;
                  });
                  getSimilarQuestions();
                },
                child: const Text("Generate Similar Questions"),
              ),
              const SizedBox(
                height: 10,
              ),
              answer != "" && isAnswerDisplayed == true
                  ? ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Enter file name'),
                              content: TextField(
                                controller: _fileNameController,
                                decoration:
                                    InputDecoration(hintText: "File name"),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Save'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _exportPDF(_fileNameController.text);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text("Download Answer as PDF"),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(
                height: 20,
              ),
              WidgetsToImage(
                controller: _controller,
                child: RichText(
                  text: TextSpan(
                    children: parseTextWithLatex(questionResponse),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
