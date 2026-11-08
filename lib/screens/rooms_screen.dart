import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';
import 'room_detail_screen.dart';

/// Rooms + Labs: read from the Firestore `rooms` collection.
/// `isLab: true` marks a lab. Filter chips switch between all,
/// rooms only and labs only.
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

enum _RoomFilter { all, rooms, labs }

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<DataResult<List<Room>>> _future;
  _RoomFilter _filter = _RoomFilter.all;

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchRooms();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchRooms();
    });
    await _future;
  }

  List<Room> _filtered(List<Room> rooms) {
    return switch (_filter) {
      _RoomFilter.all => rooms,
      _RoomFilter.rooms => rooms.where((r) => !r.isLab).toList(),
      _RoomFilter.labs => rooms.where((r) => r.isLab).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms & Labs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _RoomFilter.all,
                  onTap: () => setState(() => _filter = _RoomFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rooms',
                  selected: _filter == _RoomFilter.rooms,
                  onTap: () => setState(() => _filter = _RoomFilter.rooms),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Labs',
                  selected: _filter == _RoomFilter.labs,
                  onTap: () => setState(() => _filter = _RoomFilter.labs),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DataResult<List<Room>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data;
                if (result == null || result.notConfigured) {
                  return const PctEmptyState(
                    icon: Icons.cloud_off,
                    title: 'Firebase is not connected yet',
                    message: 'Add google-services.json to connect Firebase, then rooms will load here.',
                  );
                }
                if (result.error != null) {
                  return PctErrorState(message: result.error!, onRetry: _refresh);
                }
                final rooms = _filtered(result.data ?? <Room>[]);
                if (rooms.isEmpty) {
                  final emptyLabel = _filter == _RoomFilter.labs
                      ? 'No labs yet'
                      : _filter == _RoomFilter.rooms
                          ? 'No rooms yet'
                          : 'No rooms yet';
                  return PctEmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: emptyLabel,
                    message: 'Nothing is published here yet. Check back soon.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: rooms.length,
                    itemBuilder: (context, i) {
                      final room = rooms[i];
                      return Card(
                        color: PctColors.panel,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: PctColors.panelBorder),
                        ),
                        child: ListTile(
                          leading: Icon(
                            room.isLab ? Icons.science : Icons.meeting_room,
                            color: PctColors.gold,
                            size: 28,
                          ),
                          title: Text(
                            room.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (room.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  room.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: PctColors.muted),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  PctChip(
                                    label: room.isLab ? 'Lab' : 'Room',
                                    icon: room.isLab
                                        ? Icons.science
                                        : Icons.meeting_room,
                                  ),
                                  if (room.difficulty.isNotEmpty)
                                    PctChip(label: room.difficulty, icon: Icons.bar_chart),
                                  if (room.points > 0)
                                    PctChip(label: '${room.points} pts', icon: Icons.star),
                                  if (room.category.isNotEmpty)
                                    PctChip(label: room.category, icon: Icons.category),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: PctColors.muted,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => RoomDetailScreen(room: room),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PctColors.gold,
      backgroundColor: PctColors.panel,
      labelStyle: TextStyle(
        color: selected ? Colors.black : PctColors.text,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: PctColors.panelBorder),
    );
  }
}
