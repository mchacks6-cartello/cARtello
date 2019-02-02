//
//  DataIngest.swift
//  RTCar
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

public class DataIngest {
    
    public let dataPoints: [DataPoint]
    
    public init?(jsonName: String) {
        guard let path = Bundle.main.url(forResource: jsonName, withExtension: ".json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: path)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: [String: Any]]
            var points = [DataPoint]()
            for dict in json.values {
                if let dataPoint = DataPoint(fromJson: dict) {
                    points.append(dataPoint)
                }
            }
            dataPoints = points
        } catch {
            return nil
        }
    }
    
    
    
}

public struct DataPoint {
    
    enum Keys {
        static let latitudeKey = "latitude_deg"
        static let longitudeKey = "longitude_deg"
        static let timestampKey = "timestamp"
    }
    
    public let timestamp: Int
    
    public let longitude: Double
    public let latitude: Double
    
    public let networks: [Network]
    
    init?(fromJson json: [String: Any]) {
        var oTimestamp: Int?
        var oLongitude: Double?
        var oLatitude: Double?
        var oNetworks = [Network]()
        for (key, value) in json {
            switch key {
            case Keys.latitudeKey:
                oLatitude = value as? Double
            case Keys.longitudeKey:
                oLongitude = value as? Double
            case Keys.timestampKey:
                oTimestamp = value as? Int
            default:
                guard let networkJson = value as? [String: String] else {
                    continue
                }
                guard let network = Network(from: networkJson) else {
                    continue
                }
                oNetworks.append(network)
            }
        }
        guard let timestamp = oTimestamp, let longitude = oLongitude, let latitude = oLatitude else {
            return nil
        }
        self.timestamp = timestamp
        self.longitude = longitude
        self.latitude = latitude
        self.networks = oNetworks
    }
    
}

public struct Network {
    
    enum Keys {
        static let rssiKey = "rssi_dbm"
        static let bandwidthKey = "bandwidth_kbps"
        static let jitterKey = "jitter_ms"
        static let lossKey = "loss_percent"
        static let rtt = "rtt_ms"
    }
    
    public let rssi: Double?
    public let bandwidth: Double?
    public let jitter: Double?
    public let loss: Double?
    public let rtt: Double?
    
    init?(from json: [String: String]) {
        if let oRssi = json[Keys.rssiKey] {
            rssi = Double(oRssi)
        } else {
            rssi = nil
        }
        if let oBandwidth = json[Keys.bandwidthKey] {
            bandwidth = Double(oBandwidth)
        } else {
            bandwidth = nil
        }
        if let oJitter = json[Keys.jitterKey] {
            jitter = Double(oJitter)
        } else {
            jitter = nil
        }
        if let oLoss = json[Keys.lossKey] {
            loss = Double(oLoss)
        } else {
            loss = nil
        }
        if let oRtt = json[Keys.rtt] {
            rtt = Double(oRtt)
        } else {
            rtt = nil
        }
        guard rssi != nil || bandwidth != nil || jitter != nil || loss != nil || rtt != nil else {
            return nil
        }
    }
    
}
