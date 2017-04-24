//
//  MyIValueFormatter.swift
//  Project Loca
//
//  Created by Jake Cronin on 4/23/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import Charts

class MyIValueFormatter: NSObject, IValueFormatter{
	/// Called when a value (from labels inside the chart) is formatted before being drawn.
	///
	/// For performance reasons, avoid excessive calculations and memory allocations inside this method.
	///
	/// - returns: The formatted label ready for being drawn
	///
	/// - parameter value:           The value to be formatted
	///
	/// - parameter axis:            The entry the value belongs to - in e.g. BarChart, this is of class BarEntry
	///
	/// - parameter dataSetIndex:    The index of the DataSet the entry in focus belongs to
	///
	/// - parameter viewPortHandler: provides information about the current chart state (scale, translation, ...)
	///
	func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
		return "\(Int(value))"
	}

	
	
	
	
}
