import 'dart:convert';
import 'dart:typed_data';

/// Extracts the text runs of an *uncompressed* PDF written by the `pdf`
/// package with embedded TrueType fonts (Type0/Identity-H).
///
/// Each text run is `[<cid cid …>]TJ`; the CIDs map to Unicode through the
/// font's ToUnicode CMap. With several fonts the CID spaces overlap, so every
/// run is decoded with every CMap and all decodings are returned — enough to
/// assert that a word is present.
List<String> pdfTextRuns(Uint8List bytes) {
  final raw = latin1.decode(bytes);
  final cmaps = <Map<int, int>>[];
  final cmapPattern = RegExp(r'\d+ beginbfchar\n([\s\S]*?)endbfchar');
  final entryPattern = RegExp(r'<([0-9A-F]{4})> <([0-9A-F]{4})>');
  for (final match in cmapPattern.allMatches(raw)) {
    final map = <int, int>{};
    for (final entry in entryPattern.allMatches(match.group(1)!)) {
      map[int.parse(entry.group(1)!, radix: 16)] = int.parse(
        entry.group(2)!,
        radix: 16,
      );
    }
    cmaps.add(map);
  }
  final runs = <String>[];
  for (final match in RegExp(r'\[<([0-9a-fA-F]*)>\]TJ').allMatches(raw)) {
    final hex = match.group(1)!;
    final cids = [
      for (var i = 0; i + 4 <= hex.length; i += 4)
        int.parse(hex.substring(i, i + 4), radix: 16),
    ];
    for (final cmap in cmaps) {
      if (cids.every(cmap.containsKey)) {
        runs.add(String.fromCharCodes([for (final c in cids) cmap[c]!]));
      }
    }
  }
  return runs;
}

/// Number of pages of a PDF.
int pdfPageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;
