import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private static let webLink = try! NSRegularExpression(
    pattern: "https?://\\S+",
    options: .caseInsensitive
  )
  private static let queryValue = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { @MainActor in
      if let token = await sharedPdf() {
        return openApp(query: [("pdf", token)])
      }
      let page = await sharedPage()
      openApp(query: [("url", page.url), ("title", page.title)])
    }
  }

  /// The app takes the file from the group and deletes it; only one share
  /// waits there at a time (recipes ADR-0009).
  private func sharedPdf() async -> String? {
    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    guard
      let provider = items.flatMap({ $0.attachments ?? [] })
        .first(where: { $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) }),
      let inbox = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)?
        .appendingPathComponent("SharedPDFs", isDirectory: true)
    else { return nil }
    let token = UUID().uuidString
    let name = Self.fileName(provider.suggestedName)
    return await withCheckedContinuation { done in
      _ = provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { file, _ in
        guard let file else { return done.resume(returning: nil) }
        let folder = inbox.appendingPathComponent(token, isDirectory: true)
        do {
          try? FileManager.default.removeItem(at: inbox)
          try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
          try FileManager.default.copyItem(at: file, to: folder.appendingPathComponent(name))
          done.resume(returning: token)
        } catch {
          try? FileManager.default.removeItem(at: inbox)
          done.resume(returning: nil)
        }
      }
    }
  }

  private static let appGroup = "group.io.nullstate.nestprep.app"

  private static func fileName(_ suggested: String?) -> String {
    let bare = (suggested ?? "")
      .components(separatedBy: CharacterSet(charactersIn: "/:\\").union(.controlCharacters))
      .joined()
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let name = bare.isEmpty || bare.hasPrefix(".") ? "PDF" : bare
    return name.lowercased().hasSuffix(".pdf") ? name : name + ".pdf"
  }

  private func sharedPage() async -> (url: String?, title: String?) {
    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    var url: String?
    var texts = items.compactMap { ($0.attributedTitle ?? $0.attributedContentText)?.string }
    for provider in items.flatMap({ $0.attachments ?? [] }) {
      if url == nil,
        provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
        let link = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
        ["http", "https"].contains(link.scheme?.lowercased())
      {
        url = link.absoluteString
      } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
        let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier)
          as? String
      {
        texts.append(text)
      }
    }
    let lines = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    return (
      url ?? lines.lazy.compactMap(Self.firstWebLink).first,
      lines.first { !$0.isEmpty && Self.firstWebLink(in: $0) == nil }
    )
  }

  private static func firstWebLink(in text: String) -> String? {
    let range = NSRange(text.startIndex..., in: text)
    guard let match = webLink.firstMatch(in: text, range: range),
      let found = Range(match.range, in: text)
    else { return nil }
    return String(text[found])
  }

  private func openApp(query fields: [(String, String?)]) {
    let query = fields.compactMap { name, value in
      value?.addingPercentEncoding(withAllowedCharacters: Self.queryValue).map { "\(name)=\($0)" }
    }
    var responder: UIResponder? = self
    while let current = responder, !(current is UIApplication) {
      responder = current.next
    }
    guard let application = responder as? UIApplication,
      let link = URL(string: "nestprep://share?" + query.joined(separator: "&"))
    else {
      extensionContext?.completeRequest(returningItems: nil)
      return
    }
    application.open(link, options: [:]) { [weak self] _ in
      self?.extensionContext?.completeRequest(returningItems: nil)
    }
  }
}
