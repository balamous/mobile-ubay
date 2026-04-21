import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime date;
  bool isRead;
  final String type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.date,
    this.isRead = false,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Dépôt reçu',
      body: 'Vous avez reçu 5 000 000 GNF sur votre compte principal.',
      icon: Icons.arrow_downward_rounded,
      color: AppColors.depositColor,
      date: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      type: 'transaction',
    ),
    NotificationModel(
      id: 'n2',
      title: 'Transfert effectué',
      body: 'Votre transfert de 2 000 000 GNF vers Mamadou Bah a été traité.',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.transferColor,
      date: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      type: 'transaction',
    ),
    NotificationModel(
      id: 'n3',
      title: 'Alerte sécurité',
      body: 'Connexion détectée depuis un nouvel appareil. Si ce n\'est pas vous, sécurisez votre compte.',
      icon: Icons.security_rounded,
      color: AppColors.warning,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      type: 'security',
    ),
    NotificationModel(
      id: 'n4',
      title: 'Paiement confirmé',
      body: 'Votre facture EDG de 450 000 GNF a été réglée avec succès.',
      icon: Icons.receipt_rounded,
      color: AppColors.paymentColor,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      type: 'transaction',
    ),
    NotificationModel(
      id: 'n5',
      title: 'Limite de carte',
      body: 'Vous avez atteint 80% de la limite mensuelle de votre carte VISA.',
      icon: Icons.credit_card_rounded,
      color: AppColors.error,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: 'card',
    ),
    NotificationModel(
      id: 'n6',
      title: 'Offre exclusive',
      body: 'Profitez de 0% de frais sur vos transferts ce weekend. Offre limitée !',
      icon: Icons.local_offer_rounded,
      color: AppColors.success,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      isRead: true,
      type: 'promo',
    ),
    NotificationModel(
      id: 'n7',
      title: 'Virement bancaire',
      body: '10 000 000 GNF reçus depuis Ecobank Guinée sur votre compte.',
      icon: Icons.account_balance_rounded,
      color: AppColors.depositColor,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: 'transaction',
    ),
    NotificationModel(
      id: 'n8',
      title: 'Mise à jour disponible',
      body: 'Une nouvelle version de l\'application est disponible avec de nouvelles fonctionnalités.',
      icon: Icons.system_update_rounded,
      color: AppColors.info,
      date: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: 'system',
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifications.firstWhere((n) => n.id == id).isRead = true;
    });
  }

  void _delete(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _notifications.where((n) => !n.isRead).toList();
    final read = _notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: _backButton(isDark),
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmpty(isDark)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                if (unread.isNotEmpty) ...[
                  _sectionHeader('Nouvelles', isDark),
                  const SizedBox(height: 10),
                  ...unread.asMap().entries.map((e) => _NotifTile(
                        notif: e.value,
                        isDark: isDark,
                        onTap: () => _markRead(e.value.id),
                        onDelete: () => _delete(e.value.id),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: e.key * 60),
                            duration: 300.ms,
                          )),
                  const SizedBox(height: 20),
                ],
                if (read.isNotEmpty) ...[
                  _sectionHeader('Précédentes', isDark),
                  const SizedBox(height: 10),
                  ...read.asMap().entries.map((e) => _NotifTile(
                        notif: e.value,
                        isDark: isDark,
                        onTap: () {},
                        onDelete: () => _delete(e.value.id),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: (unread.length + e.key) * 60),
                            duration: 300.ms,
                          )),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(bool isDark) => GestureDetector(
        onTap: Get.back,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      );
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifTile({
    required this.notif,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? (isDark ? AppColors.cardDark : AppColors.white)
                : (isDark
                    ? notif.color.withOpacity(0.06)
                    : notif.color.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: notif.isRead
                  ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                  : notif.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notif.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                child: Icon(notif.icon, color: notif.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notif.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.formatRelativeDate(notif.date) +
                          ' · ' +
                          AppFormatters.formatTime(notif.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.grey500
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
