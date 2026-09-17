import 'package:flutter/material.dart';

import '../../shared/copy/app_copy.dart';
import '../nest_kit.dart';
import 'gallery_controls_section.dart';
import 'gallery_states_section.dart';
import 'gallery_surfaces_section.dart';

/// Debug-only route showing every primitive in the current theme, with a
/// toggle to preview the other one. Not reachable in release builds.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  static const path = '/design';

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  Brightness? _override;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final brightness = _override ?? Theme.of(context).brightness;
    final nest = brightness == Brightness.dark
        ? NestTheme.dark()
        : NestTheme.light();
    return Theme(
      data: nestThemeData(nest),
      child: Builder(
        builder: (context) => NestScaffold(
          title: AppCopy.galleryTitle,
          subtitle: brightness.name,
          leading: NestIconButton(
            icon: Icons.arrow_back,
            label: AppCopy.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          trailing: [
            NestIconButton(
              icon: brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              label: AppCopy.galleryToggleTheme,
              onPressed: () => setState(
                () => _override = brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
            ),
          ],
          bottomBar: NestBottomBar(
            selectedIndex: _tab,
            onSelect: (index) => setState(() => _tab = index),
            items: const [
              NestBottomBarItem(
                icon: Icons.smart_button_outlined,
                selectedIcon: Icons.smart_button,
                label: AppCopy.galleryControls,
              ),
              NestBottomBarItem(
                icon: Icons.layers_outlined,
                selectedIcon: Icons.layers,
                label: AppCopy.gallerySurfaces,
              ),
              NestBottomBarItem(
                icon: Icons.hourglass_empty,
                selectedIcon: Icons.hourglass_full,
                label: AppCopy.galleryStates,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(
              top: NestSpace.sm,
              bottom: NestSize.bottomBarHeight + NestSpace.xxxl,
            ),
            children: [
              switch (_tab) {
                0 => const GalleryControlsSection(),
                1 => const GallerySurfacesSection(),
                _ => const GalleryStatesSection(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
