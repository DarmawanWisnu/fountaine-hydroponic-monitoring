class MonitorArgs {
  final String kitId;
  final bool simulated; // untuk toggle Simulated Mode cepat
  const MonitorArgs({required this.kitId, this.simulated = false});
}

class HistoryArgs {
  final String kitId;
  const HistoryArgs({required this.kitId});
}
