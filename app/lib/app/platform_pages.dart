import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The route table with every page given its kind by hand.
///
/// go_router decides how to build a page by looking for a `MaterialApp` above
/// it, and since version 18 it looks for the one in `package:material_ui`,
/// not Flutter's own. It finds none here, so left to itself it builds every
/// page with no transition, and a page with no transition has no edge swipe
/// to go back on an iPhone. So: a place a person lands on, [landings], such
/// as a tab or the way in, stays a page with no transition, and so does
/// every page on Android, where nothing was missing. On an iPhone every
/// other page still arrives at once, as it always has here, and leaves the
/// way an iPhone's pages do: sliding away, by the edge swipe included. A
/// route that already builds its own page is left as it is.
List<RouteBase> withPlatformPages(
  List<RouteBase> routes, {
  required Set<String> landings,
}) => [for (final route in routes) _withPlatformPage(route, landings)];

RouteBase _withPlatformPage(RouteBase route, Set<String> landings) {
  final routes = withPlatformPages(route.routes, landings: landings);
  switch (route) {
    case GoRoute(:final builder, pageBuilder: null) when builder != null:
      final isLanding = landings.contains(route.path);
      return GoRoute(
        path: route.path,
        name: route.name,
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect,
        metadata: route.metadata,
        onExit: route.onExit,
        caseSensitive: route.caseSensitive,
        routes: routes,
        pageBuilder: (context, state) => _page(
          state,
          isLanding: isLanding,
          child: Builder(builder: (context) => builder(context, state)),
        ),
      );
    case GoRoute():
      return GoRoute(
        path: route.path,
        name: route.name,
        builder: route.builder,
        pageBuilder: route.pageBuilder,
        parentNavigatorKey: route.parentNavigatorKey,
        redirect: route.redirect,
        metadata: route.metadata,
        onExit: route.onExit,
        caseSensitive: route.caseSensitive,
        routes: routes,
      );
    case ShellRoute(:final builder, pageBuilder: null) when builder != null:
      final holdsLanding = route.routes.any(
        (inner) => inner is GoRoute && landings.contains(inner.path),
      );
      return ShellRoute(
        redirect: route.redirect,
        notifyRootObserver: route.notifyRootObserver,
        observers: route.observers,
        metadata: route.metadata,
        parentNavigatorKey: route.parentNavigatorKey,
        navigatorKey: route.navigatorKey,
        restorationScopeId: route.restorationScopeId,
        routes: routes,
        pageBuilder: (context, state, child) => _page(
          state,
          isLanding: holdsLanding,
          child: builder(context, state, child),
        ),
      );
    default:
      return route;
  }
}

Page<void> _page(
  GoRouterState state, {
  required bool isLanding,
  required Widget child,
}) {
  final name = state.name ?? state.path;
  final arguments = <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  };
  return isLanding || defaultTargetPlatform != TargetPlatform.iOS
      ? NoTransitionPage<void>(
          key: state.pageKey,
          name: name,
          arguments: arguments,
          restorationId: state.pageKey.value,
          child: child,
        )
      : _LeavablePage(
          key: state.pageKey,
          name: name,
          arguments: arguments,
          restorationId: state.pageKey.value,
          child: child,
        );
}

class _LeavablePage extends Page<void> {
  const _LeavablePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _LeavablePageRoute(this);
}

class _LeavablePageRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _LeavablePageRoute(_LeavablePage page) : super(settings: page);

  @override
  Widget buildContent(BuildContext context) =>
      (settings as _LeavablePage).child;

  @override
  bool get maintainState => true;

  // Arriving at once is what keeps a switch between two sibling pages, which
  // replaces one with the other, from sliding a whole screen in.
  @override
  Duration get transitionDuration => Duration.zero;
}
