class Review {
  const Review({
    required this.id,
    required this.usuarioId,
    required this.midiaId,
    required this.nota,
    this.comentario,
    required this.criadoEm,
    this.atualizadoEm,
    this.autorNome,
    this.autorAvatarUrl,
  });

  final String id;
  final String usuarioId;
  final int midiaId;
  final int nota;
  final String? comentario;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? autorNome;
  final String? autorAvatarUrl;

  factory Review.fromSupabaseJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Review(
      id: json['id'].toString(),
      usuarioId: json['usuario_id'].toString(),
      midiaId: json['midia_id'] as int,
      nota: json['nota'] as int,
      comentario: json['comentario'] as String?,
      criadoEm: DateTime.parse(json['criado_em'].toString()),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'].toString())
          : null,
      autorNome: profile?['nome'] as String?,
      autorAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
