/// [text] no longer than [longest], cut at the limit and trimmed — for a
/// name from somewhere else that has to fit a field the rules bound.
String cutText(String text, int longest) =>
    text.length <= longest ? text : text.substring(0, longest).trim();
