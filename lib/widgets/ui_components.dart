import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/services/tmdb_service.dart';

class SpotlightLogo extends StatelessWidget {
  const SpotlightLogo({super.key, required this.darkMode, this.size = 24});

  final bool darkMode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        darkMode
            ? 'assets/images/logo_dark.svg'
            : 'assets/images/logo_light.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class PlatformLogo extends StatelessWidget {
  const PlatformLogo({
    super.key,
    required this.platform,
    required this.darkMode,
  });

  final String platform;
  final bool darkMode;

  // PNG via TMDB official provider logos + Wikimedia fallbacks confiáveis.
  // Formato PNG evita problemas de rendering de SVG em alguns dispositivos.
  static const Map<String, _PlatformAsset> _assets = {
    'netflix': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/t2yyOv40HZeVlLjYsCsPHnWLk4W.jpg',
      hasDarkBg: true,
    ),
    'prime': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/emthp39XA2YScoYL1p0sdbAH2WA.jpg',
      hasDarkBg: true,
    ),
    'disney': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/7rwgEs15tFwyR9NPQ5vpzxTj19Q.jpg',
      hasDarkBg: true,
    ),
    'hbo': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/Ajqyt5aNxNGjmF9uOfxArGrdf3X.jpg',
      hasDarkBg: true,
    ),
    'apple': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/6uhKBfmtzFqOcLousHwZuzcrScK.jpg',
      hasDarkBg: true,
    ),
    'globoplay': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/t7xWlDzqJoqLEhHoJZQlLQPPGNK.jpg',
      hasDarkBg: true,
    ),
    'star': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/6mS9UvYO7WkAtzKId4qIbk40GZp.jpg',
      hasDarkBg: true,
    ),
    'paramount': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/xbhHHa1YgtpwhC8lb1NQ3ACVcLd.jpg',
      hasDarkBg: true,
    ),
    'crunchyroll': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/8Gt1iClBlzTeQs8WQm8UrCoIxnQ.jpg',
      hasDarkBg: false,
    ),
    'mubi': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/9FzZ3O9W5W8XzYpU7W1Ym9Z1X.jpg',
      hasDarkBg: true,
    ),
    'cinemark': _PlatformAsset(
      url: 'https://image.tmdb.org/t/p/original/7rwgEs15tFwyR9NPQ5vpzxTj19Q.jpg',
      hasDarkBg: true,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final key = platform.toLowerCase();
    
    // Mapeamento de Fallback para URLs que costumam quebrar ou mudaram
    final fallbackUrls = {
      'hbo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Max_logo.svg/300px-Max_logo.svg.png',
      'globoplay': 'https://image.tmdb.org/t/p/original/5m1tL9p4pS6YmXlPjP5W5Wn2L2T.jpg',
      'star': 'https://image.tmdb.org/t/p/original/6oRIcCmMFAEDijRWEXg2QUkBLkq.jpg',
    };

    final asset = _assets[key];
    if (asset == null) return const SizedBox.shrink();

    final imageUrl = (key == 'hbo' || key == 'globoplay' || key == 'star') 
        ? fallbackUrls[key]! 
        : asset.url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 32,
        height: 32,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          cacheManager: DefaultCacheManager(),
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => Container(
            color: const Color(0xFF27272A),
            child: Center(
              child: Text(
                (key.substring(0, 1)).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF27272A),
            child: Center(
              child: Text(
                (key.substring(0, 1)).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Metadados internos de um provedor de streaming.
class _PlatformAsset {
  const _PlatformAsset({
    required this.url,
    required this.hasDarkBg,
  });
  final String url;
  final bool hasDarkBg;
}

class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      cacheManager: DefaultCacheManager(),
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: const Color(0xFF18181B),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: const Color(0xFF18181B),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Color(0xFF71717A),
                size: 28,
              ),
            ),
          ),
    );
  }
}

class TitleLogo extends StatefulWidget {
  const TitleLogo({
    super.key,
    required this.movie,
    required this.height,
    required this.darkMode,
    this.fontSize = 36,
  });

  final Movie movie;
  final double height;
  final double fontSize;
  final bool darkMode;

  @override
  State<TitleLogo> createState() => _TitleLogoState();
}

class _TitleLogoState extends State<TitleLogo> {
  String? logoPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void didUpdateWidget(covariant TitleLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id) {
      _loadLogo();
    }
  }

  Future<void> _loadLogo() async {
    setState(() {
      loading = true;
      logoPath = null;
    });

    final images = await TMDBService.fetchImages(
      widget.movie.id,
      widget.movie.type,
    );
    if (!mounted) {
      return;
    }

    if (images == null) {
      setState(() => loading = false);
      return;
    }

    final logos = (images['logos'] as List?) ?? [];
    Map<String, dynamic>? pick;

    Map<String, dynamic>? find(String lang) {
      for (final entry in logos) {
        if (entry is Map<String, dynamic> && entry['iso_639_1'] == lang) {
          return entry;
        }
      }
      return null;
    }

    pick = find('pt-BR') ?? find('pt') ?? find('en');

    if (pick == null) {
      for (final entry in logos) {
        if (entry is Map<String, dynamic> && entry['iso_639_1'] == null) {
          pick = entry;
          break;
        }
      }
    }

    if (pick == null &&
        logos.isNotEmpty &&
        logos.first is Map<String, dynamic>) {
      pick = logos.first as Map<String, dynamic>;
    }

    setState(() {
      loading = false;
      if (pick != null && pick['file_path'] != null) {
        logoPath = 'https://image.tmdb.org/t/p/w500${pick['file_path']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: widget.height,
        width: widget.height * 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.13),
        ),
      );
    }

    if (logoPath != null) {
      return SmartNetworkImage(
        imageUrl: logoPath,
        height: widget.height,
        fit: BoxFit.contain,
        errorWidget: _fallbackTitle(),
        placeholder: Container(
          height: widget.height,
          width: widget.height * 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.13),
          ),
        ),
      );
    }

    return _fallbackTitle();
  }

  Widget _fallbackTitle() {
    return Text(
      widget.movie.title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: widget.darkMode ? Colors.white : Colors.black,
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}
