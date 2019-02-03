//
//  DecisionAlgorithm.swift
//  cARtello
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import DataIngest
import Foundation

public protocol DecisionAlgorithm {
    func networkChoice(for connectionState: ConnectionState, availableNetworks: [Network]) -> Decision
}

public enum Decision {
    case change(newNetwork: String)
    case stay
    case fail
}

public enum ConnectionState {
    case connected(currentNetwork: String)
    case disconnected
}

public class PowerLevelAlgorithm: DecisionAlgorithm {
    
    public func networkChoice(for connectionState: ConnectionState, availableNetworks: [Network]) -> Decision {
        let sorted = availableNetworks.sorted { return $0.rssi ?? 0 < $1.rssi ?? 0 }
        guard let largest = sorted.last else {
            return .fail
        }
        switch connectionState {
        case .connected(currentNetwork: let currentNetwork):
            if largest.name == currentNetwork {
                return .stay
            } else {
                return .change(newNetwork: largest.name)
            }
        case .disconnected:
            return .change(newNetwork: largest.name)
        }
        
    }
    
}

public class PowerLevelAvoidDisconnectAlgorithm: PowerLevelAlgorithm {
    
    public let minimumRSSI: Double
    
    init(minimumRSSI: Double) {
        self.minimumRSSI = minimumRSSI
    }
    
    override public func networkChoice(for connectionState: ConnectionState, availableNetworks: [Network]) -> Decision {
        switch connectionState {
        case .connected(currentNetwork: let currentNetwork):
            if let currentData = availableNetworks.first(where: { $0.name == currentNetwork
            }), let currentRSSI = currentData.rssi, currentRSSI >= minimumRSSI {
                return .stay
            } else {
                return super.networkChoice(for: connectionState, availableNetworks: availableNetworks)
            }
        case .disconnected:
            return super.networkChoice(for: connectionState, availableNetworks: availableNetworks)
        }
    }
    
}
