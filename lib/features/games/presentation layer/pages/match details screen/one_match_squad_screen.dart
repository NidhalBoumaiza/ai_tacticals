import 'dart:math';
import 'package:analysis_ai/features/games/presentation%20layer/pages/match%20details%20screen/player_stats_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain%20layer/entities/manager_entity.dart';
import '../../../domain%20layer/entities/player_per_match_entity.dart';
import '../../bloc/manager%20bloc/manager_bloc.dart';
import '../../bloc/player%20per%20match%20bloc/player_per_match_bloc.dart';

enum DrawingMode { free, circle, arrow, player, none }

class FieldDrawingPainter extends CustomPainter {
  final List<Map<String, dynamic>> drawings;
  final List<Offset> currentPoints;
  final DrawingMode drawingMode;
  final Color drawingColor;

  FieldDrawingPainter(
      this.drawings,
      this.currentPoints,
      this.drawingMode,
      this.drawingColor,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = drawingColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var drawing in drawings) {
      paint.color = drawing['color'] ?? drawingColor;

      switch (drawing['type']) {
        case 'free':
          final points = drawing['points'] as List<Offset>;
          for (int i = 0; i < points.length - 1; i++) {
            if (points[i] != null && points[i + 1] != null) {
              canvas.drawLine(points[i], points[i + 1], paint);
            }
          }
          break;
        case 'circle':
          if (drawing['points'].length == 2) {
            final start = drawing['points'][0];
            final end = drawing['points'][1];
            final radius = (start - end).distance;
            canvas.drawCircle(start, radius, paint..style = PaintingStyle.stroke);
          }
          break;
        case 'arrow':
          if (drawing['points'].length == 2) {
            _drawArrow(canvas, drawing['points'][0], drawing['points'][1], paint);
          }
          break;
        case 'player':
          if (drawing['points'].isNotEmpty) {
            _drawPlayerIcon(canvas, drawing['points'][0], paint);
          }
          break;
      }
    }

    if (currentPoints.isNotEmpty) {
      paint.color = drawingColor;

      switch (drawingMode) {
        case DrawingMode.free:
          for (int i = 0; i < currentPoints.length - 1; i++) {
            canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
          }
          break;
        case DrawingMode.circle:
          if (currentPoints.length == 2) {
            final radius = (currentPoints[0] - currentPoints[1]).distance;
            canvas.drawCircle(currentPoints[0], radius, paint..style = PaintingStyle.stroke);
          }
          break;
        case DrawingMode.arrow:
          if (currentPoints.length == 2) {
            _drawArrow(canvas, currentPoints[0], currentPoints[1], paint);
          }
          break;
        case DrawingMode.player:
          if (currentPoints.isNotEmpty) {
            _drawPlayerIcon(canvas, currentPoints[0], paint);
          }
          break;
        default:
          break;
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 20.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * cos(angle - pi / 6), end.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(end.dx - arrowSize * cos(angle + pi / 6), end.dy - arrowSize * sin(angle + pi / 6))
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _drawPlayerIcon(Canvas canvas, Offset position, Paint paint) {
    const size = 30.0;
    canvas.drawCircle(position, size * 0.2, paint..style = PaintingStyle.fill);
    final bodyStart = Offset(position.dx, position.dy + size * 0.2);
    final bodyEnd = Offset(position.dx, position.dy + size * 0.8);
    canvas.drawLine(bodyStart, bodyEnd, paint);
    final leftArmStart = Offset(position.dx - size * 0.3, position.dy + size * 0.4);
    final leftArmEnd = Offset(position.dx + size * 0.3, position.dy + size * 0.4);
    canvas.drawLine(leftArmStart, leftArmEnd, paint);
    final leftLegStart = Offset(position.dx - size * 0.2, position.dy + size * 0.8);
    final leftLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(leftLegStart, leftLegEnd, paint);
    final rightLegStart = Offset(position.dx + size * 0.2, position.dy + size * 0.8);
    final rightLegEnd = Offset(position.dx, position.dy + size * 1.2);
    canvas.drawLine(rightLegStart, rightLegEnd, paint);
  }

  @override
  bool shouldRepaint(FieldDrawingPainter oldDelegate) =>
      drawings != oldDelegate.drawings ||
          currentPoints != oldDelegate.currentPoints ||
          drawingMode != oldDelegate.drawingMode ||
          drawingColor != oldDelegate.drawingColor;
}

class PlayerPosition {
  final String playerId;
  double x;
  double y;
  final bool isHomeTeam;
  final Color teamColor;
  final PlayerPerMatchEntity player;

  PlayerPosition({
    required this.playerId,
    required this.x,
    required this.y,
    required this.isHomeTeam,
    required this.teamColor,
    required this.player,
  });
}

class DrawingOverlay extends StatefulWidget {
  final bool isDrawing;
  final DrawingMode drawingMode;
  final Color drawingColor;
  final List<Map<String, dynamic>> drawings;
  final Function(Offset) onStartDrawing;
  final Function(Offset) onUpdateDrawing;
  final Function() onEndDrawing;
  final Size fieldSize;
  final Offset fieldOffset;

  const DrawingOverlay({
    super.key,
    required this.isDrawing,
    required this.drawingMode,
    required this.drawingColor,
    required this.drawings,
    required this.onStartDrawing,
    required this.onUpdateDrawing,
    required this.onEndDrawing,
    required this.fieldSize,
    required this.fieldOffset,
  });

  @override
  _DrawingOverlayState createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  List<Offset> currentPoints = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.fieldSize.width,
      height: widget.fieldSize.height,
      child: Stack(
        children: [
          CustomPaint(
            size: widget.fieldSize,
            painter: FieldDrawingPainter(
              widget.drawings,
              currentPoints,
              widget.drawingMode,
              widget.drawingColor,
            ),
          ),
          if (widget.isDrawing)
            GestureDetector(
              onPanStart: (details) {
                final localPosition = details.localPosition;
                print('Overlay: Drawing started at $localPosition');
                setState(() {
                  currentPoints = [localPosition];
                  widget.onStartDrawing(localPosition);
                });
              },
              onPanUpdate: (details) {
                final localPosition = details.localPosition;
                print('Overlay: Drawing updated to $localPosition');
                setState(() {
                  if (widget.drawingMode == DrawingMode.free) {
                    currentPoints.add(localPosition);
                  } else if (currentPoints.length < 2) {
                    currentPoints.add(localPosition);
                  } else {
                    currentPoints[1] = localPosition;
                  }
                  widget.onUpdateDrawing(localPosition);
                });
              },
              onPanEnd: (_) {
                print('Overlay: Drawing ended');
                setState(() {
                  widget.onEndDrawing();
                  currentPoints.clear();
                });
              },
              child: Container(
                width: widget.fieldSize.width,
                height: widget.fieldSize.height,
                color: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

class MatchLineupsScreen extends StatefulWidget {
  final int matchId;

  const MatchLineupsScreen({super.key, required this.matchId});

  @override
  State<MatchLineupsScreen> createState() => _MatchLineupsScreenState();
}

class _MatchLineupsScreenState extends State<MatchLineupsScreen> {
  late final PlayerPerMatchBloc _playerBloc;
  late final ManagerBloc _managerBloc;
  List<PlayerPosition> homePlayerPositions = [];
  List<PlayerPosition> awayPlayerPositions = [];
  String? currentlyDraggingPlayerId;

  // Drawing variables
  bool isDrawing = false;
  List<Offset> freeDrawPoints = [];
  Color drawingColor = Colors.black;
  DrawingMode drawingMode = DrawingMode.none;
  List<Map<String, dynamic>> drawings = [];
  List<Map<String, dynamic>> redoDrawings = [];
  OverlayEntry? drawingOverlay;
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _playerBloc = context.read<PlayerPerMatchBloc>();
    _managerBloc = context.read<ManagerBloc>();
    _initializeData();
  }

  void _initializeData() {
    if (!_playerBloc.isMatchCached(widget.matchId)) {
      _playerBloc.add(GetPlayersPerMatch(matchId: widget.matchId));
    }
    if (!_managerBloc.isMatchCached(widget.matchId)) {
      _managerBloc.add(GetManagers(matchId: widget.matchId));
    }
  }

  void _startDrawing(Offset position) {
    freeDrawPoints = [position];
    setState(() {});
  }

  void _updateDrawing(Offset position) {
    if (drawingMode == DrawingMode.free) {
      freeDrawPoints.add(position);
    } else if (freeDrawPoints.length < 2) {
      freeDrawPoints.add(position);
    } else {
      freeDrawPoints[1] = position;
    }
    setState(() {});
  }

  void _endDrawing() {
    if (freeDrawPoints.isNotEmpty) {
      final newDrawing = {
        'type': drawingMode.toString().split('.').last,
        'points': List<Offset>.from(freeDrawPoints),
        'color': drawingColor,
      };
      drawings.add(newDrawing);
      redoDrawings.clear();
    }
    freeDrawPoints.clear();
    setState(() {});
  }

  void _clearDrawings() {
    drawings.clear();
    redoDrawings.clear();
    setState(() {});
  }

  void _undoDrawing() {
    if (drawings.isNotEmpty) {
      redoDrawings.add(drawings.removeLast());
      setState(() {});
    }
  }

  void _redoDrawing() {
    if (redoDrawings.isNotEmpty) {
      drawings.add(redoDrawings.removeLast());
      setState(() {});
    }
  }

  void _changeDrawingColor(Color color) {
    drawingColor = color;
    setState(() {});
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: drawingColor,
              onColorChanged: _changeDrawingColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _toggleDrawingOverlay() {
    if (isDrawing && drawingOverlay == null) {
      final RenderBox? renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        print('Error: Field RenderBox not found');
        return;
      }
      final fieldSize = renderBox.size;
      final fieldOffset = renderBox.localToGlobal(Offset.zero);

      drawingOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: fieldOffset.dx,
          top: fieldOffset.dy,
          child: DrawingOverlay(
            isDrawing: isDrawing,
            drawingMode: drawingMode,
            drawingColor: drawingColor,
            drawings: drawings,
            onStartDrawing: _startDrawing,
            onUpdateDrawing: _updateDrawing,
            onEndDrawing: _endDrawing,
            fieldSize: fieldSize,
            fieldOffset: fieldOffset,
          ),
        ),
      );
      Overlay.of(context).insert(drawingOverlay!);
      print('Overlay inserted at $fieldOffset with size $fieldSize');
    } else if (!isDrawing && drawingOverlay != null) {
      drawingOverlay!.remove();
      drawingOverlay = null;
      print('Overlay removed');
    }
    setState(() {}); // Ensure the UI updates after toggling
  }

  void _initializePlayerPositions(
      List<PlayerPerMatchEntity> homePlayers,
      List<PlayerPerMatchEntity> awayPlayers) {
    homePlayerPositions = [];
    awayPlayerPositions = [];

    final homeGoalkeepers = homePlayers.where((p) => p.position == 'G').toList();
    final homeDefenders = homePlayers.where((p) => p.position == 'D').toList();
    final homeMidfielders = homePlayers.where((p) => p.position == 'M').toList();
    final homeForwards = homePlayers.where((p) => p.position == 'F').toList();

    final awayGoalkeepers = awayPlayers.where((p) => p.position == 'G').toList();
    final awayDefenders = awayPlayers.where((p) => p.position == 'D').toList();
    final awayMidfielders = awayPlayers.where((p) => p.position == 'M').toList();
    final awayForwards = awayPlayers.where((p) => p.position == 'F').toList();

    homeGoalkeepers.asMap().forEach((index, player) {
      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-gk-$index',
        x: MediaQuery.of(context).size.width / 2 - 50.w,
        y: 20.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeDefenders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeDefenders.length) *
              (availableWidth / (homeDefenders.length - 1).clamp(1, double.infinity));

      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-def-$index',
        x: xOffset,
        y: 250.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeMidfielders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeMidfielders.length) *
              (availableWidth / (homeMidfielders.length - 1).clamp(1, double.infinity));

      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-mid-$index',
        x: xOffset,
        y: 550.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeForwards.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeForwards.length) *
              (availableWidth / (homeForwards.length - 1).clamp(1, double.infinity));

      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-fwd-$index',
        x: xOffset,
        y: 751.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    awayGoalkeepers.asMap().forEach((index, player) {
      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-gk-$index',
        x: MediaQuery.of(context).size.width / 2 - 50.w,
        y: 1675.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayDefenders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayDefenders.length) *
              (availableWidth / (awayDefenders.length - 1).clamp(1, double.infinity));

      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-def-$index',
        x: xOffset,
        y: 1470.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayMidfielders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayMidfielders.length) *
              (availableWidth / (awayMidfielders.length - 1).clamp(1, double.infinity));

      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-mid-$index',
        x: xOffset,
        y: 1230.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayForwards.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayForwards.length) *
              (availableWidth / (awayForwards.length - 1).clamp(1, double.infinity));

      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-fwd-$index',
        x: xOffset,
        y: 1000.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });
  }

  Widget _buildDraggablePlayer(PlayerPosition position) {
    final isDragging = currentlyDraggingPlayerId == position.playerId;

    return Positioned(
      left: position.x,
      top: position.y,
      child: Draggable(
        feedback: Transform.scale(
          scale: 1.1,
          child: _buildPlayerWidget(position, true),
        ),
        childWhenDragging: Container(),
        child: GestureDetector(
          onTap: () {
            if (!isDrawing && position.player.id != null) {
              print('Player tapped: ${position.playerId}');
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerStatsModal(
                  matchId: widget.matchId,
                  playerId: position.player.id!,
                  playerName: position.player.name ?? 'Unknown Player',
                ),
              );
            }
          },
          child: _buildPlayerWidget(position, isDragging),
        ),
        onDragStarted: () {
          print('Drag attempt started for ${position.playerId}, isDrawing: $isDrawing');
          if (!isDrawing) {
            setState(() {
              currentlyDraggingPlayerId = position.playerId;
            });
          }
        },
        onDragUpdate: (details) {
          if (!isDrawing) {
            print('Dragging ${position.playerId} by dx: ${details.delta.dx}, dy: ${details.delta.dy}');
            setState(() {
              final fieldWidth = MediaQuery.of(context).size.width;
              final fieldHeight = 1900.h;

              double newX = position.x + details.delta.dx;
              double newY = position.y + details.delta.dy;

              newX = newX.clamp(0.0, fieldWidth - 110.w);
              newY = position.isHomeTeam
                  ? newY.clamp(0.0, fieldHeight / 2 - 110.h)
                  : newY.clamp(fieldHeight / 2, fieldHeight - 110.h);

              position.x = newX;
              position.y = newY;
            });
          }
        },
        onDragEnd: (details) {
          if (!isDrawing) {
            print('Drag ended for ${position.playerId} at ${details.offset}');
            setState(() {
              currentlyDraggingPlayerId = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildPlayerWidget(PlayerPosition position, bool isDragging) {
    return Transform.scale(
      scale: isDragging ? 1.1 : 1.0,
      child: Column(
        children: [
          Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border.all(
                color: position.teamColor.withOpacity(isDragging ? 1.0 : 0.7),
                width: isDragging ? 3 : 2,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: 'https://img.sofascore.com/api/v1/player/${position.player.id}/image',
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.surface,
                  highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: Container(
                    width: 110.w,
                    height: 110.w,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: 60.w,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                fit: BoxFit.cover,
                width: 110.w,
                height: 110.w,
                cacheKey: position.player.id.toString(),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: position.teamColor.withOpacity(isDragging ? 0.4 : 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            constraints: BoxConstraints(maxWidth: 150.w),
            child: ReusableText(
              text: position.player.name ?? 'N/A',
              textSize: 80.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
              textFontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldBackground() {
    return Container(
      height: 1900.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 1900.h / 2 - 1,
            child: Container(
              height: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 150.w,
            top: 1900.h / 2 - 150.h,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 2.w,
            top: 1900.h / 2 - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          _buildPenaltyArea(true),
          _buildPenaltyArea(false),
          _buildGoalArea(true),
          _buildGoalArea(false),
        ],
      ),
    );
  }

  Widget _buildFootballField(
      List<PlayerPerMatchEntity> homePlayers,
      List<PlayerPerMatchEntity> awayPlayers) {
    if (homePlayerPositions.isEmpty && awayPlayerPositions.isEmpty) {
      _initializePlayerPositions(homePlayers, awayPlayers);
    }

    return Stack(
      key: _fieldKey,
      clipBehavior: Clip.none,
      children: [
        _buildFieldBackground(),
        ...homePlayerPositions.map((position) => _buildDraggablePlayer(position)),
        ...awayPlayerPositions.map((position) => _buildDraggablePlayer(position)),
      ],
    );
  }

  Widget _buildPenaltyArea(bool isHomeTeam) {
    return Positioned(
      left: 120.w,
      right: 120.w,
      top: isHomeTeam ? -5.h : 1589.h,
      child: Container(
        height: 300.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalArea(bool isHomeTeam) {
    return Positioned(
      left: 270.w,
      right: 270.w,
      top: isHomeTeam ? -5.h : 1797.h,
      child: Container(
        height: 90.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      Map<String, List<PlayerPerMatchEntity>> players,
      Map<String, ManagerEntity?> managers) {
    final homePlayers = players['home'] ?? [];
    final awayPlayers = players['away'] ?? [];
    final homeManager = managers['homeManager'];
    final awayManager = managers['awayManager'];

    final homeStarting = homePlayers.where((p) => !p.substitute).toList();
    final homeSubs = homePlayers.where((p) => p.substitute).toList();
    final awayStarting = awayPlayers.where((p) => !p.substitute).toList();
    final awaySubs = awayPlayers.where((p) => p.substitute).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFootballField(homeStarting, awayStarting),
            SizedBox(height: 60.h),
            _buildSubstitutesSection(
              homeManager,
              homeSubs,
              awayManager,
              awaySubs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutesSection(
      ManagerEntity? homeManager,
      List<PlayerPerMatchEntity> homeSubs,
      ManagerEntity? awayManager,
      List<PlayerPerMatchEntity> awaySubs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: 'substitutes'.tr,
          textSize: 140.sp,
          textFontWeight: FontWeight.bold,
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
        SizedBox(height: 30.h),
        _buildManagerHeader('home_manager'.tr, homeManager, Colors.blue),
        SizedBox(height: 20.h),
        _buildSubsList('home_substitutes'.tr, homeSubs, Colors.blue),
        SizedBox(height: 60.h),
        _buildManagerHeader('away_manager'.tr, awayManager, Colors.red),
        SizedBox(height: 20.h),
        _buildSubsList('away_substitutes'.tr, awaySubs, Colors.red),
      ],
    );
  }

  Widget _buildManagerHeader(String title, ManagerEntity? manager, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: title,
              textSize: 120.sp,
              textColor: color,
              textFontWeight: FontWeight.bold,
            ),
            SizedBox(height: 20.h),
            if (manager == null)
              ReusableText(
                text: 'no_manager_data_available'.tr,
                textSize: 100.sp,
                textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              )
            else
              Row(
                children: [
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      border: Border.all(
                        color: color.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "https://img.sofascore.com/api/v1/manager/${manager.id}/image",
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Theme.of(context).colorScheme.surface,
                          highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                          child: Container(
                            width: 110.w,
                            height: 110.w,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 60.w,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        fit: BoxFit.cover,
                        width: 110.w,
                        height: 110.w,
                        cacheKey: manager.id.toString(),
                      ),
                    ),
                  ),
                  SizedBox(width: 30.w),
                  Expanded(
                    child: ReusableText(
                      text: manager.name,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsList(String title, List<PlayerPerMatchEntity> subs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: title,
          textSize: 120.sp,
          textFontWeight: FontWeight.bold,
          textColor: color,
        ),
        SizedBox(height: 20.h),
        if (subs.isEmpty)
          ReusableText(
            text: 'no_substitutes_available'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subs.length,
            itemBuilder: (context, index) => _buildPlayerRow(subs[index], color),
          ),
      ],
    );
  }

  Widget _buildPlayerRow(PlayerPerMatchEntity player, Color teamColor) {
    return GestureDetector(
      onTap: () {
        if (player.id != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlayerStatsModal(
              matchId: widget.matchId,
              playerId: player.id!,
              playerName: player.name ?? 'Unknown Player',
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border.all(color: teamColor.withOpacity(0.7), width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: 'https://img.sofascore.com/api/v1/player/${player.id}/image',
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surface,
                    highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: Container(
                      width: 110.w,
                      height: 110.w,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: 60.w,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  fit: BoxFit.cover,
                  width: 110.w,
                  height: 110.w,
                  cacheKey: player.id.toString(),
                ),
              ),
            ),
            SizedBox(width: 30.w),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReusableText(
                          text: player.name ?? 'N/A',
                          textSize: 100.sp,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          textFontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 10.h),
                        ReusableText(
                          text: player.jerseyNumber?.toString() ?? 'N/A',
                          textSize: 90.sp,
                          textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: SpeedDial(
        icon: isDrawing ? Icons.stop : Icons.edit,
        activeIcon: Icons.close,
        spacing: 10,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.brush),
            label: 'Draw',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.free;
                isDrawing = true;
                _toggleDrawingOverlay();
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.circle_outlined),
            label: 'Circle',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.circle;
                isDrawing = true;
                _toggleDrawingOverlay();
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person),
            label: 'Player Icon',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.player;
                isDrawing = true;
                _toggleDrawingOverlay();
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.arrow_forward),
            label: 'Arrow',
            onTap: () {
              setState(() {
                drawingMode = DrawingMode.arrow;
                isDrawing = true;
                _toggleDrawingOverlay();
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.color_lens),
            label: 'Change Color',
            onTap: () => _showColorPicker(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.undo),
            label: 'Undo',
            onTap: _undoDrawing,
          ),
          SpeedDialChild(
            child: const Icon(Icons.redo),
            label: 'Redo',
            onTap: _redoDrawing,
          ),
          SpeedDialChild(
            child: const Icon(Icons.clear),
            label: 'Clear All',
            onTap: _clearDrawings,
          ),
        ],
        onPress: () {
          setState(() {
            isDrawing = !isDrawing;
            print('SpeedDial pressed, isDrawing: $isDrawing');
            _toggleDrawingOverlay();
            if (!isDrawing) {
              drawingMode = DrawingMode.none;
              freeDrawPoints.clear();
            }
          });
        },
      ),
      body: BlocBuilder<PlayerPerMatchBloc, PlayerPerMatchState>(
        builder: (context, playerState) {
          return BlocBuilder<ManagerBloc, ManagerState>(
            builder: (context, managerState) {
              if (_playerBloc.isMatchCached(widget.matchId) &&
                  _managerBloc.isMatchCached(widget.matchId)) {
                final cachedPlayers = _playerBloc.getCachedPlayers(widget.matchId)!;
                final cachedManagers = _managerBloc.getCachedManagers(widget.matchId)!;
                return _buildContent(cachedPlayers, cachedManagers);
              }

              if (playerState is PlayerPerMatchLoading ||
                  managerState is ManagerLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              if (playerState is PlayerPerMatchError ||
                  managerState is ManagerError) {
                final errorMessage = playerState is PlayerPerMatchError
                    ? playerState.message
                    : (managerState as ManagerError).message;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.w),
                    child: ReusableText(
                      text: errorMessage.tr,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (playerState is PlayerPerMatchSuccess &&
                  managerState is ManagerSuccess) {
                return _buildContent(
                  playerState.players,
                  managerState.managers,
                );
              }

              return Center(
                child: ReusableText(
                  text: 'waiting_for_lineups'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    drawingOverlay?.remove();
    super.dispose();
  }
}