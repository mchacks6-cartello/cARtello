//
//  DataIngest.swift
//  RTCar
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

public class DataIngest {
    
    public struct Metadata {
        public let minTime: Int
        public let maxTime: Int
        public let minLatitude: Double
        public let maxLatitude: Double
        public let minLongitude: Double
        public let maxLongitude: Double
    }
    
    public let dataPoints: [DataPoint]
    
    public private(set) lazy var metadata: Metadata = {
        return DataIngest.extractMetadata(from: dataPoints)
    }()
    
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
            dataPoints = points.sorted(by: <)
        } catch {
            return nil
        }
    }
    
    private static func extractMetadata(from dataPoints: [DataPoint]) -> Metadata {
        var minTime: Int
        var maxTime: Int
        var minLatitude: Double
        var maxLatitude: Double
        var minLongitude: Double
        var maxLongitude: Double
        
        let first = dataPoints.first!
        minTime = first.timestamp
        maxTime = first.timestamp
        minLatitude = first.latitude
        maxLatitude = first.latitude
        minLongitude = first.longitude
        maxLongitude = first.longitude
        
        for i in 1..<dataPoints.count {
            let current = dataPoints[i]
            if current.timestamp < minTime {
                minTime = current.timestamp
            } else if current.timestamp > maxTime {
                maxTime = current.timestamp
            }
            if current.latitude < minLatitude {
                minLatitude = current.latitude
            } else if current.latitude > maxLatitude {
                maxLatitude = current.latitude
            }
            if current.longitude < minLongitude {
                minLongitude = current.longitude
            } else  if current.longitude > maxLongitude {
                maxLongitude = current.longitude
            }
        }
        
        return Metadata(minTime: minTime, maxTime: maxTime, minLatitude: minLatitude, maxLatitude: maxLatitude, minLongitude: minLongitude, maxLongitude: maxLongitude)
    }
    
}

public struct DataPoint: Comparable {
    
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
                guard let network = Network(named: key, from: networkJson) else {
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
    
    public static func ==(lhs: DataPoint, rhs: DataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
    
    public static func <(lhs: DataPoint, rhs: DataPoint) -> Bool {
        return lhs.timestamp < rhs.timestamp
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
    
    public let name: String
    public let rssi: Double?
    public let bandwidth: Double?
    public let jitter: Double?
    public let loss: Double?
    public let rtt: Double?
    
    init?(named name: String, from json: [String: String]) {
        self.name = name
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
    
    init(name: String, rssi: Double?, bandwidth: Double? = nil, jitter: Double? = nil, loss: Double? = nil, rtt: Double? = nil) {
        self.name = name
        self.rssi = rssi
        self.bandwidth = bandwidth
        self.jitter = jitter
        self.loss = loss
        self.rtt = rtt
    }
    
}
