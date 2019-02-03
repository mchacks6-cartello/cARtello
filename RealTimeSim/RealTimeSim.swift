//
//  RealTimeSim.swift
//  RealTimeSim
//
//  Created by Russell Pecka on 2/2/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation
import DataIngest

public protocol RealTimeSimDelegate: class {
    func realTimeSim(_ realTimeSim: RealTimeSim, didPingDataPoint dataPoint: DataPoint)
    func realTimeSimDidFinishSimulation(_ realTimeSim: RealTimeSim)
}

public class RealTimeSim {
    
    public let dataIngest: DataIngest
    
    public private(set) lazy var minTime: Int = dataIngest.metadata.minTime
    
    public private(set) lazy var maxTime: Int = dataIngest.metadata.maxTime
    
    public let frequency: Double
    
    public let timeFactor: Double
    
    public var simTime: Int!
    
    private var simTimer: Timer!
    
    private var upcoming: ArraySlice<DataPoint>
    
    public weak var delegate: RealTimeSimDelegate?
    
    public init(dataIngest: DataIngest, frequency: Double, timeFactor: Double = 1) {
        self.dataIngest = dataIngest
        self.frequency = frequency
        self.timeFactor = timeFactor
        self.upcoming = dataIngest.dataPoints[dataIngest.dataPoints.startIndex..<dataIngest.dataPoints.endIndex]
    }
    
    deinit {
        reset()
    }
    
    public func start() {
        guard simTime == nil else {
            return
        }
        simTime = minTime
        let period = 1/frequency
        simTimer = Timer.init(timeInterval: period, repeats: true, block: { (_) in
            self.simTime += Int(((period * self.timeFactor) * 100).rounded(.toNearestOrAwayFromZero))
            guard self.simTime < self.maxTime else {
                self.reset()
                self.delegate?.realTimeSimDidFinishSimulation(self)
                return
            }
            let dataPoint = self.getPoint(closestTo: self.simTime)
            self.delegate?.realTimeSim(self, didPingDataPoint: dataPoint)
        })
        RunLoop.main.add(simTimer, forMode: .default)
    }
    
    public func reset() {
        simTime = nil
        simTimer.invalidate()
        simTimer = nil
    }
    
    private func getPoint(closestTo time: Int) -> DataPoint {
        for i in upcoming.startIndex..<upcoming.endIndex {
            if upcoming[i].timestamp > time {
                let point = upcoming[i]
                upcoming = upcoming[i..<upcoming.endIndex]
                simTime = point.timestamp
                return point
            }
        }
        return upcoming.last!
    }
    
}
