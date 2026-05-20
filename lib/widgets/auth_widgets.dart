import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotlight/widgets/ui_components.dart';

class LoginModal extends StatefulWidget {
  const LoginModal({
    super.key,
    required this.isOpen,
    required this.darkMode,
    required this.onClose,
    required this.onLogin,
    required this.onRegister,
    required this.onGoogleLogin,
  });

  final bool isOpen;
  final bool darkMode;
  final VoidCallback onClose;
  final Future<void> Function(String email, String senha) onLogin;
  final Future<void> Function({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    required String dataNascimento,
  })
  onRegister;
  final Future<void> Function() onGoogleLogin;

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  String mode = 'login';
  bool _submitting = false;
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();

  static const String _googleLogoSvg =
      '''<svg width="20" height="20" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M47.532 24.5528C47.532 22.9214 47.3997 21.2811 47.1175 19.6761H24.48V28.9181H37.4434C36.9055 31.8988 35.177 34.5356 32.6461 36.2111V42.2078H40.3801C44.9217 38.0278 47.532 31.8547 47.532 24.5528Z" fill="#4285F4"/>
  <path d="M24.48 48.0016C30.9529 48.0016 36.4116 45.8764 40.3888 42.2078L32.6549 36.2111C30.5031 37.675 27.7252 38.5039 24.4888 38.5039C18.2275 38.5039 12.9187 34.2798 11.0139 28.6006H3.03296V34.7825C7.10718 42.8868 15.4056 48.0016 24.48 48.0016Z" fill="#34A853"/>
  <path d="M11.0051 28.6006C9.99973 25.6199 9.99973 22.3922 11.0051 19.4115V13.2296H3.03296C-0.371021 20.0012 -0.371021 28.0021 3.03296 34.7737L11.0051 28.6006Z" fill="#FBBC05"/>
  <path d="M24.48 9.49932C27.9016 9.44641 31.2086 10.7339 33.6866 13.0973L40.5387 6.24523C36.2058 2.17001 30.4466 -0.068932 24.48 0.00161733C15.4056 0.00161733 7.10718 5.11644 3.03296 13.2296L11.0051 19.4115C12.901 13.7235 18.2187 9.49932 24.48 9.49932Z" fill="#EA4335"/>
</svg>''';

  @override
  void didUpdateWidget(covariant LoginModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen && !widget.isOpen) {
      setState(() => mode = 'login');
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _registerEmailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _setMode(String newMode) {
    setState(() => mode = newMode);
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter> inputFormatters = const [],
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final backgroundColor = widget.darkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF4F4F5);
    final borderColor = widget.darkMode
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);
    final textColor = widget.darkMode ? Colors.white : Colors.black;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: TextStyle(color: textColor, fontSize: 16),
      cursorColor: const Color(0xFF3B82F6),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 16),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(13)),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label) {
    return FilledButton(
      onPressed: _submitting
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _submitting = true);
              try {
                if (mode == 'login') {
                  await widget.onLogin(
                    _loginEmailController.text,
                    _loginPasswordController.text,
                  );
                } else {
                  await widget.onRegister(
                    nome: _fullNameController.text,
                    email: _registerEmailController.text,
                    senha: _registerPasswordController.text,
                    telefone: _phoneController.text,
                    dataNascimento: _birthDateController.text,
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro de autenticação: $e')),
                );
              } finally {
                if (context.mounted) setState(() => _submitting = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: _submitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }

  Widget _buildGoogleButton() {
    final backgroundColor = widget.darkMode
        ? Colors.white
        : const Color(0xFFF4F4F5);

    return FilledButton(
      onPressed: _submitting
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _submitting = true);
              try {
                await widget.onGoogleLogin();
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro no login Google: $e')),
                );
              } finally {
                if (context.mounted) setState(() => _submitting = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(_googleLogoSvg, width: 20, height: 20),
          const SizedBox(width: 12),
          const Text('Continuar com o Google'),
        ],
      ),
    );
  }

  Widget _buildModeLink() {
    final linkColor = widget.darkMode
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final prefix = mode == 'login'
        ? 'Não possui uma conta? '
        : 'Já possui uma conta? ';
    final action = mode == 'login' ? 'Cadastre-se' : 'Acesse aqui';

    return TextButton(
      onPressed: () => _setMode(mode == 'login' ? 'register' : 'login'),
      style: TextButton.styleFrom(
        foregroundColor: linkColor,
        textStyle: const TextStyle(fontSize: 15),
      ),
      child: Text.rich(
        TextSpan(
          text: prefix,
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 15),
          children: [
            TextSpan(
              text: action,
              style: TextStyle(color: linkColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? Colors.white : Colors.black;
    final subtitleColor = const Color(0xFFA1A1AA);
    final modalBackgroundColor = widget.darkMode
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    final fields = mode == 'login'
        ? <Widget>[
            _buildInput(
              controller: _loginEmailController,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                _LowerCaseTextInputFormatter(),
              ],
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _loginPasswordController,
              hintText: 'Senha',
              obscureText: true,
            ),
          ]
        : <Widget>[
            _buildInput(
              controller: _fullNameController,
              hintText: 'Nome completo',
              textCapitalization: TextCapitalization.words,
              inputFormatters: [_SingleSpaceInputFormatter()],
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _registerEmailController,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                _LowerCaseTextInputFormatter(),
              ],
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _phoneController,
              hintText: 'Telefone',
              keyboardType: TextInputType.phone,
              inputFormatters: [_PhoneInputFormatter()],
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _birthDateController,
              hintText: 'Data de nascimento',
              keyboardType: TextInputType.datetime,
              inputFormatters: [_DateInputFormatter()],
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _registerPasswordController,
              hintText: 'Senha',
              obscureText: true,
            ),
          ];

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !widget.isOpen,
        child: AnimatedSlide(
          offset: widget.isOpen ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          child: Container(
            color: modalBackgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF27272A),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: widget.onClose,
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFFA1A1AA),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Center(
                              child: SpotlightLogo(darkMode: true, size: 52),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              mode == 'login'
                                  ? 'Acesse sua conta'
                                  : 'Criar Conta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              mode == 'login'
                                  ? 'Entre para continuar salvando e descobrindo títulos.'
                                  : 'Crie sua conta para salvar títulos e continuar depois.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ...fields,
                            const SizedBox(height: 18),
                            _buildPrimaryButton(
                              mode == 'login'
                                  ? 'Continuar'
                                  : 'Concluir Cadastro',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: const [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFF27272A),
                                    height: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'ou',
                                    style: TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFF27272A),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildGoogleButton(),
                            const SizedBox(height: 16),
                            _buildModeLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFF27272A))),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 30,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text:
                                  'As informações da sua Conta Spotlight são usadas para ativar serviços do Spotlight quando você inicia a sessão, incluindo sincronização de histórico, listas e favoritos nos seus dispositivos. ',
                              style: const TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 10,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Veja como os seus dados são gerenciados...',
                                  style: TextStyle(
                                    color: widget.darkMode
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class EditCommentSheet extends StatefulWidget {
  const EditCommentSheet({
    super.key,
    required this.darkMode,
    required this.movieTitle,
    required this.initialStars,
    required this.initialComment,
    required this.onSubmit,
  });

  final bool darkMode;
  final String movieTitle;
  final int initialStars;
  final String initialComment;
  final Future<bool> Function(int stars, String comment) onSubmit;

  @override
  State<EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<EditCommentSheet> {
  late int selectedStars;
  final TextEditingController commentController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    selectedStars = widget.initialStars.clamp(1, 5);
    commentController.text = widget.initialComment;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = widget.darkMode;
    final textColor = darkMode ? Colors.white : Colors.black;
    final bgColor = darkMode ? const Color(0xFF111113) : Colors.white;
    final borderColor = darkMode
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF71717A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Editar comentário',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  widget.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => selectedStars = star),
                    icon: Icon(
                      star <= selectedStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 34,
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Comentário (opcional)',
                    hintStyle: const TextStyle(color: Color(0xFF71717A)),
                    filled: true,
                    fillColor: darkMode
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFF4F4F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          final shouldClose = await widget.onSubmit(
                            selectedStars,
                            commentController.text.trim(),
                          );
                          if (!context.mounted) return;
                          setState(() => _loading = false);
                          if (shouldClose) Navigator.of(context).pop();
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Atualizar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowerCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toLowerCase();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _SingleSpaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), ' ').trimLeft();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    if (digits.length <= 2) {
      buffer.write('(');
      buffer.write(digits);
    } else if (digits.length <= 6) {
      buffer.write('(');
      buffer.write(digits.substring(0, 2));
      buffer.write(') ');
      buffer.write(digits.substring(2));
    } else if (digits.length <= 10) {
      buffer.write('(');
      buffer.write(digits.substring(0, 2));
      buffer.write(') ');
      buffer.write(digits.substring(2, 6));
      buffer.write('-');
      buffer.write(digits.substring(6));
    } else {
      final truncated = digits.substring(0, 11);
      buffer.write('(');
      buffer.write(truncated.substring(0, 2));
      buffer.write(') ');
      buffer.write(truncated.substring(2, 7));
      buffer.write('-');
      buffer.write(truncated.substring(7));
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    if (truncated.isEmpty) {
      return const TextEditingValue();
    }

    if (truncated.length <= 2) {
      buffer.write(truncated);
    } else if (truncated.length <= 4) {
      buffer.write(truncated.substring(0, 2));
      buffer.write('/');
      buffer.write(truncated.substring(2));
    } else {
      buffer.write(truncated.substring(0, 2));
      buffer.write('/');
      buffer.write(truncated.substring(2, 4));
      buffer.write('/');
      buffer.write(truncated.substring(4));
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
