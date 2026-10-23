/// Which welcome tour this build shows (welcome-tour ADR-0001). An account
/// that has finished or skipped this version, or a later one, is not shown it
/// again by itself; raising it shows the new tour to everybody once.
abstract final class TourVersion {
  static const current = 2;
}
