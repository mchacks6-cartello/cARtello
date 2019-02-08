//
//  CarModel.swift
//  cARtello
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import DataIngest
import Foundation

public protocol CarModelDelegate: class {
    func carModel(_ carModel: CarModel, didUpdateConnectionState connectionState: ConnectionState)
}

public class CarModel {
    
    public private(set) var connectionState: ConnectionState = .disconnected
    
    public var currNetwork: String!
    public var availableNetworks: [String] = []
    
    private let decisionAlgorithm: DecisionAlgorithm
    
    public weak var delegate: CarModelDelegate?
    
    public init(decisionAlgorithm: DecisionAlgorithm) {
        self.decisionAlgorithm = decisionAlgorithm
        self.currNetwork = "Not connected"
    }
    
    public func process(networks: [Network]) {
        availableNetworks = networks.map { $0.name }
        switch decisionAlgorithm.networkChoice(for: connectionState, availableNetworks: networks) {
        case .stay:
            break
        case .fail:
            connectionState = .disconnected
            delegate?.carModel(self, didUpdateConnectionState: connectionState)
            self.currNetwork = "Not connected"
        case .change(let newNetwork):
            connectionState = .connected(currentNetwork: newNetwork)
            delegate?.carModel(self, didUpdateConnectionState: connectionState)
            self.currNetwork = newNetwork

        }
    }
}
