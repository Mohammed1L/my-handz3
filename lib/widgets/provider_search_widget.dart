// lib/widgets/provider_search_widget.dart
import 'dart:async';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderSearchWidget extends StatefulWidget {
  final void Function(QueryDocumentSnapshot)? onTap;
  const ProviderSearchWidget({super.key, this.onTap});

  @override
  State<ProviderSearchWidget> createState() => _ProviderSearchWidgetState();
}

class _ProviderSearchWidgetState extends State<ProviderSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<QueryDocumentSnapshot> _results = [];

  // Overlay control
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();

  // small map for category synonyms; extend as needed
  final Map<String, String> _categoryMap = {
    'cleaning': 'cleaning',
    'clean': 'cleaning',
    'handyman': 'handyman',
    'plumbing': 'plumbing',
    'delivery': 'delivery',
    'assembly': 'assembly',
    'moving': 'moving',
    // Arabic examples (add more)
    'تنظيف': 'cleaning',
    'سباكة': 'plumbing',
    'توصيل': 'delivery',
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _controller.removeListener(_onChange);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _controller.text.trim();
      await _doSearch(q);
      _updateOverlay();
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else {
      _updateOverlay();
    }
  }

  // normalization (same logic as search_utils)
  String _normalize(String s) {
    s = s.toLowerCase();
    s = s.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]', multiLine: true), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    const arabicDiacritics = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652';
    final buffer = StringBuffer();
    for (final ch in s.characters) {
      if (!arabicDiacritics.contains(ch)) buffer.write(ch);
    }
    return buffer.toString();
  }

  Future<void> _doSearch(String q) async {
    if (!mounted) return;
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final token = _normalize(q);
    if (token.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    try {
      // Primary: keywords arrayContains
      final keywordSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('keywords', arrayContains: token)
          .limit(30)
          .get();

      if (keywordSnap.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _results = keywordSnap.docs;
          _loading = false;
        });
        return;
      }

      // Fallback: category
      final catKey = _categoryMap[token];
      if (catKey != null) {
        final catSnap = await FirebaseFirestore.instance
            .collection('providers')
            .where('category', isEqualTo: catKey)
            .limit(60)
            .get();
        if (catSnap.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _results = catSnap.docs;
            _loading = false;
          });
          return;
        }
      }

      // Fallback: name prefix - (works better when names are stored consistently)
      final start = token;
      final end = '$token\uf8ff';
      final nameSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('name', isGreaterThanOrEqualTo: start)
          .where('name', isLessThanOrEqualTo: end)
          .limit(40)
          .get();

      if (nameSnap.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _results = nameSnap.docs;
          _loading = false;
        });
        return;
      }

      // nothing found
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
      // optional: show message or log
      // print('Search error: $e');
    }
  }

  // Overlay creation / update / remove. This version sizes the overlay
  // to the field width and ensures it fits the available space (opens above if needed).
  void _updateOverlay() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      return;
    }

    final shouldShow = _loading || _results.isNotEmpty || _controller.text.isNotEmpty;
    if (!shouldShow) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(builder: (context) {
      // We'll measure the field size via the _fieldKey and use that width for the overlay.
      // The CompositedTransformFollower keeps it positioned; we manage size and max height here.
      final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
      final fieldSize = renderBox?.size ?? Size(300, 44);

      // available screen space
      final mq = MediaQuery.of(context);
      final availableHeightBelow = mq.size.height - (renderBox?.localToGlobal(Offset.zero).dy ?? 0) - fieldSize.height - mq.viewInsets.bottom - 8;
      final availableHeightAbove = (renderBox?.localToGlobal(Offset.zero).dy ?? 0) - mq.padding.top - 8;

      // choose open direction based on available space
      final openAbove = availableHeightBelow < 160 && availableHeightAbove > availableHeightBelow;

      final maxHeight = openAbove ? (availableHeightAbove.clamp(120.0, 420.0)) : (availableHeightBelow.clamp(120.0, 420.0));

      return Positioned(
        // Positioned.fill allows CompositedTransformFollower to locate the child correctly
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: openAbove ? Offset(0, -8 - maxHeight) : Offset(0, fieldSize.height + 8),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: fieldSize.width,
              // constrained height to available space
              child: _buildDropdownCard(maxHeight),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDropdownCard(double maxHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header with tiny drag handle look
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _controller.text.isEmpty ? 'Type to search' : 'Results for "${_controller.text}"',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                  if (_loading) const SizedBox(width: 10),
                  if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const Divider(height: 0),
            Expanded(
              child: _results.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(_loading ? 'Searching...' : 'No results found', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 0, color: Colors.grey.shade100),
                itemBuilder: (context, i) => _resultTile(_results[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final image = (data['image'] ?? '').toString();

    final bool looksLikeUrl = image.startsWith('http://') || image.startsWith('https://');

    return InkWell(
      onTap: () {
        widget.onTap?.call(doc);
        _removeOverlay();
        _focusNode.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // safe image: only use network when it looks like a URL
            if (looksLikeUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.store, color: Colors.black54),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.black54),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CompositedTransformTarget with GlobalKey to measure size
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _fieldKey,
        // the container inherits parent's width; ensure it doesn't expand unexpectedly
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search services or providers',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _results = []);
                _removeOverlay();
                FocusScope.of(context).requestFocus(_focusNode);
              },
            )
                : null,
          ),
          onSubmitted: (v) async {
            await _doSearch(v);
            _updateOverlay();
          },
          onTap: _updateOverlay,
        ),
      ),
    );
  }
}
