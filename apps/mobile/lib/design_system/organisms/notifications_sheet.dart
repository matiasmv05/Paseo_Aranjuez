import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de centro de notificaciones interactivo de Paseo Points (HU-23).
class NotificationsSheet extends StatefulWidget {
  /// Crea el centro de notificaciones.
  const new({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  late List<MockNotification> _list;

  @override
  void initState() {
    super.initState();
    _list = List.of(MockData.notifications);
  }

  void _markAllAsRead() {
    setState(() {
      _list = [
        for (final n in _list)
          MockNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            time: n.time,
            isRead: true,
            icon: n.icon,
          ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de arrastre superior
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaseoColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cabecera con título y acción "Marcar como leídas"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: PaseoColors.textDarkPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text(
                      'Marcar leídas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8C6527),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de notificaciones
              if (_list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No tienes notificaciones en este momento.',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._list.map((n) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.white : const Color(0xFFFBF9F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: n.isRead
                            ? PaseoColors.borderLight
                            : const Color(0xFFE8DFD0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? const Color(0xFFF0EFEA)
                                : const Color(0xFFF9F3EA),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            n.icon == 'trophy'
                                ? Icons.emoji_events_rounded
                                : n.icon == 'tag'
                                ? Icons.local_offer_rounded
                                : Icons.star_rounded,
                            size: 18,
                            color: const Color(0xFF8C6527),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: PaseoColors.textDarkPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD4AF37),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PaseoColors.textDarkSecondary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: PaseoColors.textPlaceholder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
