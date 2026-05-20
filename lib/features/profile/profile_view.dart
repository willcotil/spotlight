import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/providers/auth_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/widgets/ui_components.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool analytics = true;

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final auth = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      'Ajustes',
                      style: TextStyle(
                        color: darkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajustes',
                      style: TextStyle(
                        color: darkMode ? Colors.white : Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              if (auth.isLoggedIn && auth.currentUser != null)
                _SettingsCard(
                  darkMode: darkMode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: darkMode
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE4E4E7),
                          child:
                              auth.currentUser!.userMetadata?['avatar_url'] !=
                                  null
                              ? ClipOval(
                                  child: SmartNetworkImage(
                                    imageUrl: auth
                                        .currentUser!
                                        .userMetadata!['avatar_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: Icon(
                                      Icons.person,
                                      color: darkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUser!.userMetadata?['full_name'] ??
                                    'Usuário',
                                style: TextStyle(
                                  color: darkMode ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                auth.currentUser!.email ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => auth.signOut(),
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _SettingsCard(
                  darkMode: darkMode,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    onTap: () => context.read<AuthProvider>().openLoginModal(),
                    title: Text(
                      'Iniciar Sessão',
                      style: TextStyle(
                        color: darkMode
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              _SettingsGroup(
                darkMode: darkMode,
                title: 'Aparência',
                children: [
                  _SettingsItem(
                    darkMode: darkMode,
                    label: 'Aparência',
                    value: darkMode ? 'Escura' : 'Clara',
                    onTap: () =>
                        context.read<ThemeProvider>().toggleTheme(),
                  ),
                ],
              ),
              _SettingsGroup(
                darkMode: darkMode,
                title: 'Idioma',
                children: [
                  _SettingsItem(
                    darkMode: darkMode,
                    label: 'Idioma',
                    value: 'Automático',
                  ),
                ],
              ),
              _SettingsGroup(
                darkMode: darkMode,
                title: 'Restrições',
                children: [
                  _SettingsItem(
                    darkMode: darkMode,
                    label: 'Restrições de Conteúdo',
                    value: 'Desativado',
                  ),
                ],
              ),
              _SettingsGroup(
                darkMode: darkMode,
                title: 'Sobre',
                children: const [
                  _SettingsItem(
                    label: 'App Spotlight e Privacidade',
                    blue: true,
                  ),
                  _SettingsItem(label: 'Termos e Condições', blue: true),
                  _SettingsItem(label: 'Agradecimentos', blue: true),
                  _SettingsItem(label: 'Enviar Feedback', blue: true),
                  _SettingsItem(
                    label: 'Manual de Uso do App Spotlight',
                    blue: true,
                  ),
                  _SettingsItem(label: 'Obter Suporte', blue: true),
                ],
              ),
              _SettingsGroup(
                darkMode: darkMode,
                title: 'Privacidade',
                children: [
                  _SettingsItem(
                    darkMode: darkMode,
                    label: 'Compartilhar Análise do App Spotlight',
                    hasToggle: true,
                    toggleValue: analytics,
                    onToggle: (value) => setState(() => analytics = value),
                  ),
                  const _SettingsItem(
                    label: 'Sobre o Diagnóstico e Privacidade',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Versão 2.4.1 (2041079) (13E79)\nCopyright © 2026. Spotlight Inc. Todos os direitos reservados.',
                  style: TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.darkMode,
    required this.title,
    required this.children,
  });

  final bool darkMode;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _SettingsCard(
            darkMode: darkMode,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.darkMode, required this.child});

  final bool darkMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: darkMode ? null : Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: child,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    this.darkMode = true,
    required this.label,
    this.value,
    this.onTap,
    this.blue = false,
    this.hasToggle = false,
    this.toggleValue = false,
    this.onToggle,
  });

  final bool darkMode;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool blue;
  final bool hasToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: blue
                              ? (darkMode
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB))
                              : (darkMode ? Colors.white : Colors.black),
                          fontSize: 16,
                        ),
                      ),
                      if (value != null)
                        Text(
                          value!,
                          style: const TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasToggle)
                  Switch(
                    value: toggleValue,
                    onChanged: onToggle,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF3B82F6),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0x3327272A)),
      ],
    );
  }
}
