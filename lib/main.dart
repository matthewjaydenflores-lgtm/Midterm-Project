import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

const _forest = Color(0xFF243E35);
const _cream = Color(0xFFF5F2EB);
const _mutedGreen = Color(0xFF769656);
const _lightSquare = Color(0xFFEEEED2);
const _darkSquare = Color(0xFF769656);

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _forest,
          surface: _cream,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _forest,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _hasOpenedGame = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _openGame);
  }

  void _openGame() {
    if (!mounted || _hasOpenedGame) return;
    _hasOpenedGame = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ChessHome()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_forest, Color(0xFF162B24)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '♔',
                      style: TextStyle(
                        color: Color(0xFFF0E8D8),
                        fontSize: 74,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'CHESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'One board. Two players.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 52),
                  FilledButton.icon(
                    key: const Key('start-game'),
                    onPressed: _openGame,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF0E8D8),
                      foregroundColor: _forest,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Start a game',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PASS AND PLAY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChessHome extends StatefulWidget {
  const ChessHome({super.key});

  @override
  State<ChessHome> createState() => _ChessHomeState();
}

class _ChessHomeState extends State<ChessHome> {
  chess.Chess _game = chess.Chess();
  String? _selectedSquare;
  List<Map<String, dynamic>> _legalMoves = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;

  bool get _whiteToMove => _game.turn == chess.Color.WHITE;

  String get _status {
    if (_game.in_checkmate) {
      return '${_whiteToMove ? 'Black' : 'White'} wins by checkmate';
    }
    if (_game.in_stalemate) return 'Draw by stalemate';
    if (_game.in_draw) return 'Game drawn';
    if (_game.in_check) {
      return '${_whiteToMove ? 'White' : 'Black'} is in check';
    }
    return '${_whiteToMove ? 'White' : 'Black'} to move';
  }

  void _resetGame() {
    setState(() {
      _game = chess.Chess();
      _selectedSquare = null;
      _legalMoves = [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
    });
  }

  Future<void> _tapSquare(String square) async {
    if (_game.game_over) return;

    if (_selectedSquare != null) {
      Map<String, dynamic>? move;
      for (final candidate in _legalMoves) {
        if (candidate['to'] == square) {
          move = candidate;
          break;
        }
      }

      if (move != null) {
        var promotion = 'q';
        if ((move['flags'] as String).contains('p')) {
          final choice = await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Promote your pawn'),
              children: [
                for (final option in const [
                  ('q', 'Queen'),
                  ('r', 'Rook'),
                  ('b', 'Bishop'),
                  ('n', 'Knight'),
                ])
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, option.$1),
                    child: Text(option.$2),
                  ),
              ],
            ),
          );
          if (choice == null) return;
          promotion = choice;
        }

        final from = _selectedSquare!;
        final moved = _game.move({
          'from': from,
          'to': square,
          if ((move['flags'] as String).contains('p')) 'promotion': promotion,
        });
        if (moved) {
          setState(() {
            _lastMoveFrom = from;
            _lastMoveTo = square;
            _selectedSquare = null;
            _legalMoves = [];
          });
        }
        return;
      }
    }

    final piece = _game.get(square);
    if (piece != null &&
        piece.color == (_whiteToMove ? chess.Color.WHITE : chess.Color.BLACK)) {
      final moves = _game.moves({'square': square, 'verbose': true});
      setState(() {
        _selectedSquare = square;
        _legalMoves = moves.cast<Map<String, dynamic>>();
      });
    } else {
      setState(() {
        _selectedSquare = null;
        _legalMoves = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _game.getHistory().cast<String>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _forest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '♞',
                          style: TextStyle(color: Colors.white, fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chess',
                              style: TextStyle(
                                color: _forest,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'LOCAL TWO-PLAYER',
                              style: TextStyle(
                                color: Color(0xFF7C817A),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const Key('reset-game'),
                        tooltip: 'New game',
                        onPressed: _resetGame,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _forest,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _PlayerCard(
                    name: 'Black',
                    piece: '♚',
                    isActive: !_whiteToMove && !_game.game_over,
                    isTop: true,
                  ),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _ChessBoard(
                      game: _game,
                      selectedSquare: _selectedSquare,
                      legalMoves: _legalMoves,
                      lastMoveFrom: _lastMoveFrom,
                      lastMoveTo: _lastMoveTo,
                      onSquareTap: _tapSquare,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PlayerCard(
                    name: 'White',
                    piece: '♔',
                    isActive: _whiteToMove && !_game.game_over,
                    isTop: false,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: _game.game_over
                                ? const Color(0xFFC28A52)
                                : _mutedGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _status,
                            key: const Key('game-status'),
                            style: const TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${(history.length + 1) ~/ 2} moves',
                          style: const TextStyle(
                            color: Color(0xFF7C817A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'MOVE HISTORY',
                        style: TextStyle(
                          color: Color(0xFF7C817A),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (history.isEmpty)
                        const Text(
                          'Your game starts here',
                          style: TextStyle(
                            color: Color(0xFF9A9D96),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < history.length; index++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${index ~/ 2 + 1}${index.isEven ? '.' : '...'} ${history[index]}',
                              style: const TextStyle(
                                color: _forest,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.piece,
    required this.isActive,
    required this.isTop,
  });

  final String name;
  final String piece;
  final bool isActive;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE7EBDD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFD4DFC9) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isTop ? const Color(0xFFF2F0E9) : _forest,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              piece,
              style: TextStyle(
                color: isTop ? _forest : const Color(0xFFF0E8D8),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              color: _forest,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'TO MOVE',
                style: TextStyle(
                  color: _mutedGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            isTop ? 'BLACK' : 'WHITE',
            style: const TextStyle(
              color: Color(0xFF9A9D96),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChessBoard extends StatelessWidget {
  const _ChessBoard({
    required this.game,
    required this.selectedSquare,
    required this.legalMoves,
    required this.lastMoveFrom,
    required this.lastMoveTo,
    required this.onSquareTap,
  });

  final chess.Chess game;
  final String? selectedSquare;
  final List<Map<String, dynamic>> legalMoves;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final ValueChanged<String> onSquareTap;

  static const _files = 'abcdefgh';
  static const _pieceSymbols = {
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  @override
  Widget build(BuildContext context) {
    final targets = legalMoves.map((move) => move['to'] as String).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDFDCCF), width: 4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final column = index % 8;
            final square = '${_files[column]}${8 - row}';
            final piece = game.get(square);
            final selected = square == selectedSquare;
            final lastMove = square == lastMoveFrom || square == lastMoveTo;
            final isTarget = targets.contains(square);
            final isCapture = isTarget && piece != null;
            final isLight = (row + column).isEven;

            var background = isLight ? _lightSquare : _darkSquare;
            if (lastMove) background = const Color(0xFFBACA44);
            if (selected) background = const Color(0xFFF6F669);

            final pieceCode = piece == null
                ? null
                : piece.color == chess.Color.WHITE
                ? piece.type.toUpperCase()
                : piece.type.toLowerCase();

            return Semantics(
              key: Key('square-$square'),
              button: true,
              selected: selected,
              label: '$square${pieceCode == null ? '' : ' ${_pieceName(pieceCode)}'}',
              child: GestureDetector(
                onTap: () => onSquareTap(square),
                child: ColoredBox(
                  color: background,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isTarget && !isCapture)
                            Center(
                              child: Container(
                                width: constraints.maxWidth * 0.27,
                                height: constraints.maxWidth * 0.27,
                                decoration: BoxDecoration(
                                  color: _forest.withValues(alpha: 0.28),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (isCapture)
                            Center(
                              child: Container(
                                width: constraints.maxWidth * 0.9,
                                height: constraints.maxWidth * 0.9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _forest.withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          if (pieceCode != null)
                            Center(
                              child: FittedBox(
                                child: Text(
                                  _pieceSymbols[pieceCode]!,
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth * 0.82,
                                    height: 1,
                                    color: piece!.color == chess.Color.WHITE
                                        ? const Color(0xFFFFFEF7)
                                        : const Color(0xFF26312A),
                                    shadows: [
                                      Shadow(
                                        color:
                                            piece.color == chess.Color.WHITE
                                            ? const Color(0xFF596653)
                                            : Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (row == 7)
                            Positioned(
                              left: 3,
                              bottom: 1,
                              child: Text(
                                _files[column],
                                style: TextStyle(
                                  color: isLight
                                      ? _darkSquare
                                      : _lightSquare,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          if (column == 0)
                            Positioned(
                              left: 3,
                              top: 2,
                              child: Text(
                                '${8 - row}',
                                style: TextStyle(
                                  color: isLight
                                      ? _darkSquare
                                      : _lightSquare,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _pieceName(String code) {
    const names = {
      'K': 'white king',
      'Q': 'white queen',
      'R': 'white rook',
      'B': 'white bishop',
      'N': 'white knight',
      'P': 'white pawn',
      'k': 'black king',
      'q': 'black queen',
      'r': 'black rook',
      'b': 'black bishop',
      'n': 'black knight',
      'p': 'black pawn',
    };
    return names[code]!;
  }
}
