import 'package:flutter/material.dart';

import '../../shared/copy/app_copy.dart';
import '../nest_kit.dart';
import 'gallery_controls_section.dart';
import 'gallery_states_section.dart';
import 'gallery_surfaces_section.dart';

/// Route showing every primitive in the current theme, with a toggle to preview
/// the other one.
///
/// Debug builds always carry it. A release build carries it only when it opts in
/// with `NESTPREP_CRASH_TEST`, because the one thing only a release build can
/// prove — that a crash reaches Crashlytics — needs a trigger as well as a
/// release build. `DesignGalleryAccess` is the gate; this screen renders no
/// household data and reads nothing, so carrying it exposes nobody.
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
            icon: LucideIcons.arrowLeft,
            label: AppCopy.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          trailing: [
            NestIconButton(
              icon: brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
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
                icon: LucideIcons.mousePointerClick,
                label: AppCopy.galleryControls,
              ),
              NestBottomBarItem(
                icon: LucideIcons.layers,
                label: AppCopy.gallerySurfaces,
              ),
              NestBottomBarItem(
                icon: LucideIcons.hourglass,
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
