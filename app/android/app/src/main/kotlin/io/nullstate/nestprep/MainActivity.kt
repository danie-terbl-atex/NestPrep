package io.nullstate.nestprep

import io.flutter.embedding.android.FlutterFragmentActivity

// A FragmentActivity because the phone's biometric prompt is a fragment: the
// vault opens behind it (documents ADR-0003, `local_auth`).
class MainActivity : FlutterFragmentActivity()
