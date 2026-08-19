import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/agency_screen/agency_home_controller.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Get.put(DashboardScreenController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandWashBg(vivid: false),
          IndexedStack(
            index: _tab,
            children: const [
              AgencyHomeScreen(),
              _AgencyAccountTab(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: ColorRes.whitePure,
        selectedItemColor: ColorRes.crimson,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

class AgencyHomeScreen extends StatelessWidget {
  const AgencyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AgencyHomeController());
    return Column(
      children: [
        CustomAppBar(
          title: 'Agencia',
          showBack: false,
          subTitle: 'Tus streamers afiliados',
          rowWidget: IconButton(
            onPressed: () => _openCreate(context, c),
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (c.isLoading.value && c.workers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: ColorRes.crimson),
              );
            }
            if (c.workers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_outlined,
                          size: 48, color: Colors.white54),
                      const SizedBox(height: 12),
                      Text(
                        'Aún no tienes streamers',
                        style: TextStyleCustom.outFitSemiBold600(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea una cuenta Streamer afiliada a tu agencia.',
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButtonCustom(
                        title: 'Crear streamer',
                        onTap: () => _openCreate(context, c),
                        gradient: true,
                        btnWidth: 200,
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: c.loadWorkers,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: c.workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _WorkerTile(user: c.workers[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _openCreate(
      BuildContext context, AgencyHomeController c) async {
    final fullname = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final username = TextEditingController();
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ColorRes.carbon,
        title: Text(
          'Nuevo streamer',
          style: TextStyleCustom.outFitSemiBold600(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(fullname, 'Nombre completo'),
              const SizedBox(height: 10),
              _field(email, 'Email de acceso',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(password, 'Contraseña', obscure: true),
              const SizedBox(height: 10),
              _field(username, 'Username (opcional)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          Obx(() => TextButton(
                onPressed: c.creating.value
                    ? null
                    : () async {
                        final created = await c.createWorker(
                          fullname: fullname.text,
                          identity: email.text,
                          password: password.text,
                          username: username.text,
                        );
                        if (created) Get.back(result: true);
                      },
                child: c.creating.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear'),
              )),
        ],
      ),
    );
    fullname.dispose();
    email.dispose();
    password.dispose();
    username.dispose();
    if (ok == true) {
      // lista ya actualizada
    }
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final User user;

  const _WorkerTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = (user.profilePhoto ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ColorRes.mlPurple.withValues(alpha: 0.4),
            backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
            child: photo.isEmpty
                ? Text(
                    _initial(user),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullname ?? user.username ?? 'Streamer',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username ?? ''} · ${user.identity ?? user.userEmail ?? ''}',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorRes.crimson.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'worker',
              style: TextStyleCustom.outFitSemiBold600(
                color: ColorRes.accentPeach,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initial(User user) {
  final name = (user.fullname ?? user.username ?? 'S').trim();
  if (name.isEmpty) return 'S';
  return name.substring(0, 1).toUpperCase();
}

class _AgencyAccountTab extends StatelessWidget {
  const _AgencyAccountTab();

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUser();
    return Column(
      children: [
        const CustomAppBar(
          title: 'Agencia',
          showBack: false,
          subTitle: 'Cuenta',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: ColorRes.mlPurple.withValues(alpha: 0.4),
                backgroundImage: ((me?.profilePhoto ?? '').trim().isEmpty)
                    ? null
                    : NetworkImage(me!.profilePhoto!),
                child: (me?.profilePhoto ?? '').trim().isEmpty
                    ? Text(
                        _initial(me ?? User()),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                me?.fullname ?? 'Agencia',
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                me?.identity ?? me?.userEmail ?? '',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(me?.coinWallet ?? 0).toInt()} coins',
                style: TextStyleCustom.outFitSemiBold600(
                  color: ColorRes.accentPeach,
                  fontSize: 16,
                ),
              ),
              Text(
                '10% del margen App de tus streamers',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              TextButtonCustom(
                title: 'Ajustes',
                onTap: () => Get.to(() => const SettingsScreen()),
                gradient: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
