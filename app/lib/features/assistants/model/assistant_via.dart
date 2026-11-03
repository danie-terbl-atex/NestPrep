/// Which assistant a connection belongs to, or made a change, as the server
/// read it from the connection's verified client host (assistants ADR-0003,
/// ADR-0005). Mirrors the Functions' `ASSISTANT_VIAS`; a value this build has
/// never heard of reads as [assistant].
enum AssistantVia { claude, chatgpt, assistant }
