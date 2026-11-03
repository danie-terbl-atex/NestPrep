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
      let page = await sharedPage()
      openApp(url: page.url, title: page.title)
    }
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

  private func openApp(url: String?, title: String?) {
    let query = [("url", url), ("title", title)].compactMap { name, value in
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
