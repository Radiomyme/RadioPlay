import Foundation

struct Station: Identifiable, Decodable {
    let id: String
    let name: String
    let subtitle: String
    let streamURL: String
    let imageURL: String?
    let logoURL: String?
    let categories: [String]?
    let useStreamMetadata: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name = "radioName"
        case subtitle = "radioSubtitle"
        case streamURL = "radioStreamURL"
        case imageURL = "backgroundImage"
        case logoURL = "radioLogo"
        case categories
        case useStreamMetadata
    }

    init(id: String, name: String, subtitle: String, streamURL: String, imageURL: String?, logoURL: String?, categories: [String]? = nil, useStreamMetadata: Bool = true) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.logoURL = logoURL
        self.categories = categories
        self.useStreamMetadata = useStreamMetadata
    }
}

extension Station: Equatable {
    static func == (lhs: Station, rhs: Station) -> Bool {
        return lhs.id == rhs.id
    }
}
