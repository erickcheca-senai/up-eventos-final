import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';

class UpLogo extends StatelessWidget {
  const UpLogo({super.key, this.height = 42, this.horizontal = true});
  final double height;
  final bool horizontal;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: upDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: upGold.withValues(alpha: .22))),
      child: Image.asset(horizontal ? 'assets/logo-up-horizontal.jpg' : 'assets/logo-up-eventos.png', height: height, fit: BoxFit.contain),
    );
  }
}

class RemotePhoto extends StatefulWidget {
  const RemotePhoto({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Accepts either a bundled path such as assets/event_photos/salao_evento.jpg
  /// or a remote HTTPS URL. Local assets are preferred for reliable display.
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<RemotePhoto> createState() => _RemotePhotoState();
}

class _RemotePhotoState extends State<RemotePhoto> {
  int _attempt = 0;

  Widget _errorPlaceholder(BuildContext context, Object error, StackTrace? stack) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: widget.height,
      width: widget.width,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined, size: 38, color: colors.primary),
          const SizedBox(height: 8),
          Text('Imagem indisponível', textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('Confira o arquivo em assets/event_photos.', textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
          if (!widget.url.startsWith('assets/'))
            TextButton(
              onPressed: () => setState(() => _attempt++),
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLocalAsset = widget.url.startsWith('assets/');
    final image = isLocalAsset
        ? Image.asset(
            widget.url,
            key: ValueKey('${widget.url}-asset-$_attempt'),
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: _errorPlaceholder,
          )
        : Image.network(
            widget.url,
            key: ValueKey('${widget.url}-network-$_attempt'),
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              final value = total == null || total == 0 ? null : progress.cumulativeBytesLoaded / total;
              return Container(
                height: widget.height,
                width: widget.width,
                color: colors.surfaceContainerHighest,
                alignment: Alignment.center,
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(value: value, strokeWidth: 2)),
              );
            },
            errorBuilder: _errorPlaceholder,
          );
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      child: image,
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary));
}

class UpSectionTitle extends StatelessWidget {
  const UpSectionTitle({super.key, required this.eyebrow, required this.title, this.subtitle});
  final String eyebrow;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final parts = title.split('|');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 8),
      Text.rich(TextSpan(children: [TextSpan(text: parts.first, style: const TextStyle(fontFamily: 'Georgia', fontSize: 28, height: 1.2)), if (parts.length > 1) TextSpan(text: parts.skip(1).join('|'), style: TextStyle(fontFamily: 'Georgia', fontSize: 28, height: 1.2, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.primary))])),
      if (subtitle != null) ...[const SizedBox(height: 10), Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5))],
    ]);
  }
}

Future<void> openWhatsApp(BuildContext context) async {
  final uri = Uri.parse('https://wa.me/5511969663554');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp neste dispositivo.')));
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: padding, child: child));
}
