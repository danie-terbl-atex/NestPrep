import '../../features/assistants/model/assistant_scope.dart';
import '../../features/assistants/model/assistant_via.dart';

/// Every word *Connected assistants* says, and the mark an assistant's change
/// carries on the week and the list (assistants ADR-0003, ADR-0005) — beside
/// `AppCopy` rather than inside it, because it is one feature's vocabulary.
abstract final class AssistantsCopy {
  static const title = 'Connected assistants';
  static const subtitle = 'nestprep in Claude and ChatGPT';
  static const openFromMoreBody = 'Use nestprep from Claude or ChatGPT.';
  static const sectionMore = 'Elsewhere';

  static const sectionHousehold = 'This household';
  static const allowTitle = 'Let assistants work in this household';
  static const allowOnBody =
      'Connected assistants can add to the calendar and the grocery list.';
  static const allowOffBody =
      'Paused. Connected assistants can’t do anything here until this is '
      'back on.';

  static const sectionConnected = 'Connected';
  static const emptyTitle = 'Nothing connected yet';
  static const emptyBody =
      'Connect Claude or ChatGPT, then ask it to add to the calendar or the '
      'grocery list. It works as you.';
  static const emptyBodyForOthers =
      'For now, parents connect assistants. Anything connected as you shows '
      'up here.';

  static const sectionConnect = 'Connect an assistant';
  static const connectInClaude =
      'In Claude: Settings → Connectors → Add custom connector';
  static const connectAddress = 'https://mcp.nestprep.io/mcp';
  static const connectInChatGpt = 'ChatGPT takes the same address.';
  static const copyAddress = 'Copy address';
  static const addressCopied = 'Address copied';

  static const connectedByYou = 'Connected by you';
  static String connectedBy(String name) => 'Connected by $name';
  static const formerMember = 'someone who has left';
  static String inHousehold(String name) => 'In $name';
  static String connectedOn(String date) => 'Connected $date';
  static const usedJustNow = 'Used just now';
  static String lastUsed(String when) => 'Last used $when';
  static const notUsedYet = 'Not used yet';

  static const mayDo = 'It may';
  static const recently = 'Lately';
  static const nothingYet = 'Nothing changed yet.';

  static const disconnect = 'Disconnect';
  static const disconnectConfirm = 'Disconnect this assistant?';
  static String disconnectBody(String name) =>
      '$name stops working in nestprep straight away. Anything it added stays.';

  static String assistantName(AssistantVia via) => switch (via) {
    AssistantVia.claude => 'Claude',
    AssistantVia.chatgpt => 'ChatGPT',
    AssistantVia.assistant => 'An assistant',
  };

  static String scope(AssistantScope scope) => switch (scope) {
    AssistantScope.householdRead => 'See who’s in the household',
    AssistantScope.calendarRead => 'See the calendar',
    AssistantScope.calendarWrite => 'Add and change events',
    AssistantScope.listsRead => 'See the grocery list',
    AssistantScope.listsWrite => 'Add to and tick off groceries',
  };

  /// What a write tool did, in words. A tool this build has never heard of
  /// still reads as a change.
  static String activity(String tool) => switch (tool) {
    'create_event' => 'Added an event',
    'update_event' => 'Changed an event',
    'delete_event' => 'Removed an event',
    'add_grocery_items' => 'Added groceries',
    'update_grocery_item' => 'Changed a grocery item',
    'tick_grocery_items' => 'Ticked off groceries',
    'remove_grocery_items' => 'Removed groceries',
    _ => 'Made a change',
  };

  /// The mark on an event or a grocery item an assistant added.
  static String via(AssistantVia via) => switch (via) {
    AssistantVia.claude => 'via Claude',
    AssistantVia.chatgpt => 'via ChatGPT',
    AssistantVia.assistant => 'via an assistant',
  };

  /// The same mark, as a screen reader says it.
  static String viaSpoken(AssistantVia via) => switch (via) {
    AssistantVia.claude => 'Added with Claude',
    AssistantVia.chatgpt => 'Added with ChatGPT',
    AssistantVia.assistant => 'Added with an assistant',
  };
}
