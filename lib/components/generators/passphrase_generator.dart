import 'dart:convert' show jsonDecode;
import 'dart:io' show sleep;
import 'dart:math' show Random;

import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:http/http.dart' as http;

class PassphraseGenerator {
  PassphraseGenerator(
    this.wordCount, {
    this.includeNumbers = false,
    this.shouldCapitalize = false,
    this.separator = "-",
    this.wordList = const [],
  });

  int cachedWords = 10;
  int wordCount;
  bool includeNumbers;
  bool shouldCapitalize;
  String separator;
  List<String> wordList;
  int _currentIndex = 0;

  Future<bool> fetchWordList() async {
    final response = await http.get(
        Uri.parse(
            "https://byepass-random-words-api.herokuapp.com/words?limit=$cachedWords"),
        headers: {
          "X-API-KEY": dotenv.env["X-API-KEY"]!,
        });

    if (response.statusCode != 200) return false;

    wordList = List<String>.from(
        (jsonDecode(response.body) as Map<String, dynamic>)["words"]);
    return true;
  }

  Future<void> keepFetchingWordList() async {
    for (int i = 0; i < 3; ++i) {
      if (await fetchWordList()) break;
      sleep(const Duration(seconds: 1));
    }
  }

  Future<String> generate() async {
    final passphrase =
        includeNumbers ? _generateWithNumber() : _generateWithoutNumber();

    // If list has more words
    if (_currentIndex + 2 * wordCount < wordList.length) {
      _currentIndex += wordCount;
      return passphrase;
    }

    // Fetch new words
    _currentIndex = 0;
    final fetchSuccess = await fetchWordList();
    if (fetchSuccess) return passphrase;

    // Shuffle and keep fetching
    wordList.shuffle();
    keepFetchingWordList();
    return passphrase;
  }

  String _generateWithoutNumber() {
    return wordList
        .sublist(_currentIndex, _currentIndex + wordCount)
        .map((word) =>
            shouldCapitalize ? word[0].toUpperCase() + word.substring(1) : word)
        .join(separator);
  }

  String _generateWithNumber() {
    final random = Random();
    final position = random.nextInt(wordCount);
    final randomNumber = random.nextInt(10);

    late final List<String> sublist;
    if ((_currentIndex + wordCount) < wordList.length) {
      sublist = wordList.sublist(_currentIndex, _currentIndex + wordCount);
    } else {
      sublist = wordList.sublist(_currentIndex, wordList.length);
      sublist.addAll(wordList.sublist(0, wordCount - sublist.length));
    }
    final words = sublist
        .map((word) =>
            shouldCapitalize ? word[0].toUpperCase() + word.substring(1) : word)
        .toList();

    words[position] += randomNumber.toString();

    return words.join(separator);
  }
}
