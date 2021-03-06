import Foundation

public struct Period {
    public enum Resolution {
        case monthly
        case monthlyAdjusted
    }

    public let dateInterval: DateInterval
    public let name: String
    public let resolution: Resolution

    public init(dateInterval: DateInterval, name: String, resolution: Period.Resolution) {
        self.dateInterval = dateInterval
        self.name = name
        self.resolution = resolution
    }
}

public extension Period.Resolution {
    var statisticResolution: Statistic.Resolution {
        switch self {
        case .monthly:
            return .monthly
        case .monthlyAdjusted:
            return .monthlyAdjusted
        }
    }
}
