import 'package:chess_game/config/custom_route.dart';
import 'package:chess_game/screens/game/game_screen.dart';
import 'package:flutter/material.dart';


class OptionScreen extends StatefulWidget {
  static const String routeName = '/option';

  static Route route({required Map<String, bool> options}) {
    return CustomRoute(
      settings: const RouteSettings(name: routeName),
      fullscreenDialog: true,
      builder: (_) =>
          OptionScreen(isSinglePlayer: options['isSinglePlayer'] ?? true),
    );
  }

  const OptionScreen({Key? key, required this.isSinglePlayer})
      : super(key: key);

  final bool isSinglePlayer;

  @override
  State<OptionScreen> createState() => _OptionScreenState();
}

class _OptionScreenState extends State<OptionScreen> {
  // Device screen information.
  late final double deviceWidth = MediaQuery.of(context).size.width;
  late final double deviceHeight = MediaQuery.of(context).size.height;
  late final double aspectRatio = deviceWidth / deviceHeight;

  // Board size.
  late final double boardSize =
      aspectRatio < 0.64 ? deviceWidth / 1.08 : (6 * deviceHeight / 11);

  // Spacing valus.
  final double labelSpacing = 100;

  // Text field properties.
  final maxTextFieldLines = 1;
  final maxTextFieldLength = 20;
  late final TextEditingController _player1NameTextFieldController =
      TextEditingController(text: widget.isSinglePlayer ? 'Human' : 'Player 1');
  late final TextEditingController _player2NameTextFieldController =
      TextEditingController(
          text: widget.isSinglePlayer ? 'Computer' : 'Player 2');

  // Slider widget properties.
  final double _difficultySliderMinValue = 1;
  final double _difficultySliderMaxValue = 10;
  double _difficultySliderCurrentValue = 5;

  // Move clock settings.
  bool _moveClockEnabled = true;
  int _time = 5;

  // Undo settings.
  int undoAttempts = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: deviceWidth < 700
                    ? 12.0
                    : deviceWidth < 1200
                        ? deviceWidth / 8
                        : deviceWidth < 1800
                            ? deviceWidth / 4
                            : deviceWidth / 3),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'title',
                      child: Text(
                        'CHESS',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            splashFactory: NoSplash.splashFactory,
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              size: 32,
                            ),
                          ),
                          Text(
                            widget.isSinglePlayer
                                ? 'SinglePlayer'
                                : 'MultiPlayer',
                            style: Theme.of(context).appBarTheme.titleTextStyle,
                          ),
                          InkWell(
                            splashFactory: NoSplash.splashFactory,
                            onTap: () => Navigator.of(context)
                                .pushNamed(GameScreen.routeName, arguments: {
                              'player1Name':
                                  _player1NameTextFieldController.text,
                              'player2Name':
                                  _player2NameTextFieldController.text,
                              'moveClockEnabled': _moveClockEnabled,
                              'time': _time,
                              'undoAttempts': undoAttempts,
                              'isSinglePlayer': widget.isSinglePlayer,
                            }),
                            child: Transform(
                              transform: Matrix4.rotationY(22 / 7),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_ios,
                                size: 32,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: labelSpacing,
                            child: Text(
                              'Player 1',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                          Flexible(
                            child: TextField(
                              controller: _player1NameTextFieldController,
                              decoration: const InputDecoration(
                                hintText: "Enter first player's name.",
                                counterText: "",
                              ),
                              maxLines: 1,
                              maxLength: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          SizedBox(
                            width: labelSpacing,
                            child: Text(
                              'Player 2',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                          Flexible(
                            child: TextField(
                              controller: _player2NameTextFieldController,
                              decoration: const InputDecoration(
                                hintText: "Enter second player's name.",
                                counterText: "",
                              ),
                              maxLines: 1,
                              maxLength: 24,
                            ),
                          ),
                        ],
                      ),
                      if (widget.isSinglePlayer)
                        Row(
                          children: [
                            SizedBox(
                              width: labelSpacing,
                              child: Text(
                                'Difficulty',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                            Flexible(
                              child: Slider(
                                min: _difficultySliderMinValue,
                                max: _difficultySliderMaxValue,
                                value: _difficultySliderCurrentValue,
                                onChanged: (double nextValue) => setState(() {
                                  _difficultySliderCurrentValue = nextValue;
                                }),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          SizedBox(
                            width: labelSpacing,
                            child: Text(
                              'Move Clock',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                          Center(
                            child: Switch(
                                value: _moveClockEnabled,
                                onChanged: (_) => setState(() =>
                                    _moveClockEnabled = !_moveClockEnabled)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: labelSpacing,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _moveClockEnabled
                                      ? 'Initial Time'
                                      : 'Think Time',
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                                Text(
                                  '(Minutes)',
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 8.0,
                          ),
                          Column(
                            children: [
                              const Text('5'),
                              Radio<int>(
                                  value: 5,
                                  groupValue: _time,
                                  onChanged: (val) =>
                                      setState(() => _time = val!)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('10'),
                              Radio<int>(
                                  value: 10,
                                  groupValue: _time,
                                  onChanged: (val) =>
                                      setState(() => _time = val!)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('15'),
                              Radio<int>(
                                  value: 15,
                                  groupValue: _time,
                                  onChanged: (val) =>
                                      setState(() => _time = val!)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('30'),
                              Radio<int>(
                                  value: 30,
                                  groupValue: _time,
                                  onChanged: (val) =>
                                      setState(() => _time = val!)),
                            ],
                          ),
                        ],
                      ),
                      // Row(
                      //   children: [
                      //     SizedBox(
                      //       width: labelSpacing,
                      //       child: Text(
                      //         'Undo Attempts',
                      //         style: Theme.of(context).textTheme.displaySmall,
                      //       ),
                      //     ),
                      //     const SizedBox(
                      //       width: 8.0,
                      //     ),
                      //     Column(
                      //       children: [
                      //         const Text('0'),
                      //         Radio<int>(
                      //             value: 0,
                      //             groupValue: undoAttempts,
                      //             onChanged: (val) =>
                      //                 setState(() => undoAttempts = val!)),
                      //       ],
                      //     ),
                      //     Column(
                      //       children: [
                      //         const Text('1'),
                      //         Radio<int>(
                      //             value: 1,
                      //             groupValue: undoAttempts,
                      //             onChanged: (val) =>
                      //                 setState(() => undoAttempts = val!)),
                      //       ],
                      //     ),
                      //     Column(
                      //       children: [
                      //         const Text('3'),
                      //         Radio<int>(
                      //             value: 3,
                      //             groupValue: undoAttempts,
                      //             onChanged: (val) =>
                      //                 setState(() => undoAttempts = val!)),
                      //       ],
                      //     ),
                      //     Column(
                      //       children: [
                      //         const Text('∞'),
                      //         Radio<int>(
                      //             value: -1,
                      //             groupValue: undoAttempts,
                      //             onChanged: (val) =>
                      //                 setState(() => undoAttempts = val!)),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Hero(
                      tag: 'chess-pieces-image',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                        ),
                        child: Image.asset(
                          'assets/images/chess-pieces.png',
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
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
