import 'package:flutter/material.dart';
import '../network/connectivity_service.dart';

class OfflineBanner extends StatefulWidget implements PreferredSizeWidget {
  final Widget? child;
  const OfflineBanner({Key? key, this.child}) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();

  @override
  Size get preferredSize => Size.fromHeight(0);
}

class _OfflineBannerState extends State<OfflineBanner> {
  ConnectionStatus _status = ConnectionStatus.online;
  late final Stream<ConnectionStatus> _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityService().onStatusChange;
    _sub.listen((s) {
      setState(() => _status = s);
      if (s == ConnectionStatus.online) {
        // show temporary connected banner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection restored. Refreshing latest data...'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == ConnectionStatus.online) return SizedBox.shrink();

    final message = _status == ConnectionStatus.offline
        ? "You're offline. Showing previously synced data."
        : 'Network connection is unstable.';

    return Material(
      color: Colors.amber.shade700,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
