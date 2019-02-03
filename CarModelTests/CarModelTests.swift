//
//  CarModelTests.swift
//  CarModelTests
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import XCTest
@testable import DataIngest
@testable import CarModel

class CarModelTests: XCTestCase {
    
    var model: CarModel!
    
    func testPowerLevelAlg() {
        model = CarModel(decisionAlgorithm: PowerLevelAlgorithm())
        switch model.connectionState {
        case .disconnected:
            break
        default:
            XCTFail("Model should start in the disconnected state")
        }
        var networks = [Network(name: "Rogers", rssi: -10), Network(name: "Bell", rssi: -30)]
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Rogers", "Current network should be Rogers")
        default:
            XCTFail("Network should be connected")
        }
        networks = [Network(name: "Rogers", rssi: -30), Network(name: "Bell", rssi: -10)]
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Bell", "Current network should be Bell")
        default:
            XCTFail("Network should be connected")
        }
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Bell", "Current network should be Bell")
        default:
            XCTFail("Network should be connected")
        }
        model.process(networks: [])
        switch model.connectionState {
        case .disconnected:
            break
        default:
            XCTFail("Network should be disconnected")
        }
    }

    func testAvoidDisconnect() {
        model = CarModel(decisionAlgorithm: PowerLevelAvoidDisconnectAlgorithm(minimumRSSI: -50))
        switch model.connectionState {
        case .disconnected:
            break
        default:
            XCTFail("Model should start in the disconnected state")
        }
        var networks = [Network(name: "Rogers", rssi: -10), Network(name: "Bell", rssi: -30)]
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Rogers", "Current network should be Rogers")
        default:
            XCTFail("Network should be connected")
        }
        networks = [Network(name: "Rogers", rssi: -30), Network(name: "Bell", rssi: -10)]
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Rogers", "Current network should be Rogers")
        default:
            XCTFail("Network should be connected")
        }
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Rogers", "Current network should be Rogers")
        default:
            XCTFail("Network should be connected")
        }
        networks = [Network(name: "Rogers", rssi: -60), Network(name: "Bell", rssi: -10)]
        model.process(networks: networks)
        switch model.connectionState {
        case .connected(currentNetwork: let current):
            XCTAssertEqual(current, "Bell", "Current network should be Bell")
        default:
            XCTFail("Network should be connected")
        }
        model.process(networks: [])
        switch model.connectionState {
        case .disconnected:
            break
        default:
            XCTFail("Network should be disconnected")
        }
    }

}
