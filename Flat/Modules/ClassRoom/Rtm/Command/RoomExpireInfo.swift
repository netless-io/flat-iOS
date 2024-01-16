import Foundation

enum PaidLevel: Int, Codable {
    case free = 0
    case paidLevel1
    
    var localizedString: String {
        switch self {
        case .free:
            return localizeStrings("FreeVersion")
        case .paidLevel1:
            return localizeStrings("PaidVersion")
        }
    }
}

struct RoomExpireInfo: Codable {
    let roomLevel: PaidLevel
    let expireAt: Date
}
