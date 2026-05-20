import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/models/cast_member.dart';
import 'package:spotlight/models/movie.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/services/tmdb_service.dart';
import 'package:spotlight/widgets/ui_components.dart';

class ActorDetailView extends StatefulWidget {
  const ActorDetailView({super.key, required this.actor});

  final CastMember actor;

  @override
  State<ActorDetailView> createState() => _ActorDetailViewState();
}

class _ActorDetailViewState extends State<ActorDetailView> {
  bool _isLoading = true;
  String _biography = '';
  bool _bioExpanded = false;
  String _department = '';
  String _birthday = '';
  String _placeOfBirth = '';
  List<Movie> _filmography = [];
  List<Movie> _filteredFilmography = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final details = await TMDBService.fetchActorDetails(widget.actor.id);
    final movies = await TMDBService.fetchActorFilmography(widget.actor.id);
    
    // Ordene por data de lançamento decrescente (ano)
    movies.sort((a, b) => (b.year.isEmpty ? '0' : b.year).compareTo(a.year.isEmpty ? '0' : a.year));

    if (mounted) {
      setState(() {
        _biography = details?['biography'] as String? ?? 'Nenhuma biografia disponível.';
        _department = details?['known_for_department'] as String? ?? '-';
        _birthday = details?['birthday'] as String? ?? '-';
        _placeOfBirth = details?['place_of_birth'] as String? ?? '-';
        _filmography = movies;
        _filteredFilmography = movies;
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoColumn(String title, String value, Color textColor, Color secondaryTextColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<ThemeProvider>().darkMode;
    final textColor = darkMode ? Colors.white : Colors.black;
    final secondaryTextColor = darkMode ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final bgColor = darkMode ? const Color(0xFF09090B) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: darkMode ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: widget.actor.profileUrl.isNotEmpty
                        ? ClipOval(
                            child: SmartNetworkImage(
                              imageUrl: widget.actor.profileUrl,
                              fit: BoxFit.cover,
                              errorWidget: Icon(
                                Icons.person,
                                color: secondaryTextColor,
                                size: 80,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: secondaryTextColor,
                            size: 80,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.actor.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bioExpanded = !_bioExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _biography.isNotEmpty ? _biography : 'Nenhuma biografia disponível.',
                        maxLines: _bioExpanded ? null : 4,
                        overflow: _bioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn('Departamento', _department, textColor, secondaryTextColor),
                        _buildInfoColumn('Nascimento', _birthday, textColor, secondaryTextColor),
                        _buildInfoColumn('Local', _placeOfBirth, textColor, secondaryTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filmografia',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Buscar na filmografia...',
                          hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF71717A)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (query) {
                          setState(() {
                            if (query.isEmpty) {
                              _filteredFilmography = _filmography;
                            } else {
                              _filteredFilmography = _filmography
                                  .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_filteredFilmography.length} títulos',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredFilmography.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Nenhuma mídia encontrada.',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.67,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredFilmography.length,
                      itemBuilder: (context, index) {
                        final movie = _filteredFilmography[index];
                        return InkWell(
                          onTap: () {
                            context.read<ReviewsProvider>().openDetails(movie);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                movie.posterUrl != null
                                    ? SmartNetworkImage(
                                        imageUrl: movie.posterUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: darkMode ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                                        child: Icon(
                                          Icons.movie_creation_outlined,
                                          color: secondaryTextColor,
                                          size: 34,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
