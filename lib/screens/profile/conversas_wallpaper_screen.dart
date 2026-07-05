import 'package:flutter/material.dart';
import '../../core/services/wallpaper_service.dart';
import '../../core/theme/app_theme.dart';

class ConversasWallpaperScreen extends StatefulWidget {
  const ConversasWallpaperScreen({super.key});

  @override
  State<ConversasWallpaperScreen> createState() => _ConversasWallpaperScreenState();
}

class _ConversasWallpaperScreenState extends State<ConversasWallpaperScreen> {
  final _wallpaperService = WallpaperService();
  String _selected = WallpaperService.defaultWallpaper;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await _wallpaperService.getSelectedWallpaper();
    if (!mounted) return;
    setState(() {
      _selected = current;
      _loading = false;
    });
  }

  Future<void> _select(String assetPath) async {
    await _wallpaperService.setSelectedWallpaper(assetPath);
    if (!mounted) return;
    setState(() => _selected = assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Papel de parede das conversas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vale pra todas as conversas.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: WallpaperService.availableWallpapers.length,
                  itemBuilder: (context, index) {
                    final asset = WallpaperService.availableWallpapers[index];
                    final isSelected = asset == _selected;
                    return GestureDetector(
                      onTap: () => _select(asset),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.lineGreen : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.lineGreen,
                                child: Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
