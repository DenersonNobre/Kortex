/// Barrel of the widgets layer (`lib/src/widgets/`).
///
/// SRP: re-export the page, the reactive fragments and (at `UC-04.02`) the
/// listener, the resource builder and the `Listenable` bridges from a single
/// import. It does NOT expose internal coordinators.
///
/// Usage: `import 'package:kortex/src/widgets/widgets.dart';`
library;

export 'kortex_app.dart';
export 'kortex_listenable_adapter.dart';
export 'kortex_listener.dart';
export 'kortex_page.dart';
export 'kortex_resource_builder.dart';
export 'kortex_selector.dart';
export 'kortex_watch.dart';
