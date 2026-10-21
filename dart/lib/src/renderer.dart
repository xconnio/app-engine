import 'package:flutter/material.dart';

import 'runtime.dart';

/// Renders a manifest app's [screen]: its layout, and a block for each visible child.
class ManifestScreenView extends StatelessWidget {
  const ManifestScreenView({
    super.key,
    required this.app,
    required this.screen,
    required this.context,
    required this.caller,
    this.errorUri,
  });

  final ManifestApp app;
  final Map<String, dynamic> screen;

  /// What `context.*` bindings read, e.g. `capabilities`.
  final Map<String, dynamic> context;
  final ManifestCaller caller;
  final ErrorUri? errorUri;

  @override
  Widget build(BuildContext buildContext) {
    final layout = (screen['layout'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (layout['type'] != 'grid') return _Unsupported('layout ${layout['type']}');

    final children = [
      for (final child in (layout['children'] as List? ?? const []).whereType<Map>())
        if (isVisible(child['visible'], context)) child.cast<String, dynamic>(),
    ];
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: (layout['columns'] as num?)?.toInt().clamp(1, 6) ?? 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final child in children)
          ManifestBlockView(
            // Keyed by id so a block keeps its state while others show or hide.
            key: ValueKey(child['id']),
            block: (child['block'] as Map?)?.cast<String, dynamic>() ?? const {},
            context: context,
            caller: caller,
            errorUri: errorUri,
          ),
      ],
    );
  }
}

/// A mounted block. It mounts when built and unmounts when removed.
class ManifestBlockView extends StatefulWidget {
  const ManifestBlockView({super.key, required this.block, required this.context, required this.caller, this.errorUri});

  final Map<String, dynamic> block;
  final Map<String, dynamic> context;
  final ManifestCaller caller;
  final ErrorUri? errorUri;

  @override
  State<ManifestBlockView> createState() => _ManifestBlockViewState();
}

class _ManifestBlockViewState extends State<ManifestBlockView> {
  late final BlockController _controller = BlockController(
    block: widget.block,
    context: widget.context,
    caller: widget.caller,
    errorUri: widget.errorUri ?? (error) => error.toString(),
  );

  @override
  void initState() {
    super.initState();
    _controller.mount();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final component = _controller.component;
        return switch (component['type']) {
          'button' => _ManifestButton(controller: _controller, component: component),
          'text' => _ManifestText(controller: _controller, component: component),
          final type => _Unsupported('component $type'),
        };
      },
    );
  }
}

class _ManifestButton extends StatelessWidget {
  const _ManifestButton({required this.controller, required this.component});

  final BlockController controller;
  final Map<String, dynamic> component;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = controller.eval(component['label'])?.toString() ?? '';
    final icon = controller.eval(component['icon'])?.toString();
    final error = controller.error;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.busy ? null : controller.activate,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 40,
                child: controller.busy
                    ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 3))
                    : _ManifestIcon(url: icon),
              ),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManifestText extends StatelessWidget {
  const _ManifestText({required this.controller, required this.component});

  final BlockController controller;
  final Map<String, dynamic> component;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = controller.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: controller.busy
              ? const CircularProgressIndicator(strokeWidth: 3)
              : Text(
                  error?.toString() ?? controller.eval(component['label'])?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: error == null
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
        ),
      ),
    );
  }
}

class _ManifestIcon extends StatelessWidget {
  const _ManifestIcon({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.widgets_outlined, size: 32);
    final url = this.url;
    if (url == null || !url.startsWith('https://')) return fallback;
    return Image.network(url, errorBuilder: (_, _, _) => fallback);
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported(this.what);

  final String what;

  @override
  Widget build(BuildContext context) => Center(child: Text('Unsupported $what'));
}
