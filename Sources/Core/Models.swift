import Foundation

struct DisplayDescriptor: Equatable, Sendable {
    let index: Int
    let name: String
    let uuid: String

    var isPreferredEvnia: Bool {
        let value = name.lowercased()
        return value.contains("27m2n5901a")
            || value.contains("evnia")
            || value.contains("philips")
    }
}

struct MonitorSnapshot: Sendable {
    let display: DisplayDescriptor
    let brightness: Int?
    let volume: Int?
}
