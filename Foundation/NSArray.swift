// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension Array : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSArray.self
    }
    
    public func _bridgeToObjectiveC() -> NSArray {
        return NSArray(array: map {
            return _NSObjectRepresentableBridge($0)
        })
    }
    
    public static func _forceBridgeFromObjectiveC(x: NSArray, inout result: Array?) {
        var array = [Element]()
        for value in x.allObjects {
            if let v = value as? Element {
                array.append(v)
            } else {
                return
            }
        }
        result = array
    }
    
    public static func _conditionallyBridgeFromObjectiveC(x: NSArray, inout result: Array?) -> Bool {
        _forceBridgeFromObjectiveC(x, result: &result)
        return true
    }
}

public class NSArray : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFArrayGetTypeID())
    internal var _storage = [AnyObject]()
    
    public var count: Int {
        get {
            if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
                return _storage.count
            } else {
                NSRequiresConcreteImplementation()
            }
        }
    }
    
    public func objectAtIndex(index: Int) -> AnyObject {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
           return _storage[index]
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience override init() {
        self.init(objects: nil, count:0)
    }
    
    public required init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _storage.reserveCapacity(cnt)
        for idx in 0..<cnt {
            _storage.append(objects[idx]!)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(objects: nil, count: 0)
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        return NSMutableArray(array: _swiftObject)
    }

    public convenience init(object anObject: AnyObject) {
        self.init(array: [anObject])
    }
    
    public convenience init(array: [AnyObject]) {
        self.init(array: array, copyItems: false)
    }
    
    public convenience init(array: [AnyObject], copyItems: Bool) {
        let optionalArray : [AnyObject?] =
            copyItems ?
                array.map { return Optional<AnyObject>(($0 as! NSObject).copy()) } :
                array.map { return Optional<AnyObject>($0) }
        
        // This would have been nice, but "initializer delegation cannot be nested in another expression"
//        optionalArray.withUnsafeBufferPointer { ptr in
//            self.init(objects: ptr.baseAddress, count: array.count)
//        }
        let cnt = array.count
        let buffer = UnsafeMutablePointer<AnyObject?>.alloc(cnt)
        buffer.initializeFrom(optionalArray)
        self.init(objects: buffer, count: cnt)
        buffer.destroy(cnt)
        buffer.dealloc(cnt)
    }

    internal var allObjects: [AnyObject] {
        get {
            if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
                return _storage
            } else {
                return (0..<count).map { idx in
                    return self[idx]
                }
            }
        }
    }
    
    public func arrayByAddingObject(anObject: AnyObject) -> [AnyObject] {
        return allObjects + [anObject]
    }
    
    public func arrayByAddingObjectsFromArray(otherArray: [AnyObject]) -> [AnyObject] {
        return allObjects + otherArray
    }
    
    public func componentsJoinedByString(separator: String) -> String {
        // make certain to call NSObject's description rather than asking the string interpolator for the swift description
        return bridge().map() { ($0 as! NSObject).description }.joinWithSeparator(separator)
    }

    public func containsObject(anObject: AnyObject) -> Bool {
        let other = anObject as! NSObject

        for idx in 0..<count {
            let obj = self[idx] as! NSObject

            if obj === other || obj.isEqual(other) {
                return true
            }
        }
        return false
    }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String { NSUnimplemented() }
    public func descriptionWithLocale(locale: AnyObject?, indent level: Int) -> String { NSUnimplemented() }
    
    public func firstObjectCommonWithArray(otherArray: [AnyObject]) -> AnyObject? {
        let set = NSSet(array: otherArray)

        for idx in 0..<count {
            let item = self[idx]
            if set.containsObject(item) {
                return item
            }
        }
        return nil
    }

    /// Alternative pseudo funnel method for fastpath fetches from arrays
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func getObjects(inout objects: [AnyObject], range: NSRange) {
        if self.dynamicType === NSArray.self || self.dynamicType === NSMutableArray.self {
            if range.location == 0 && range.length == count {
                objects = _storage
                return
            }
        }
        for idx in 0..<range.length {
            objects[idx] = self[idx]
        }
    }
    
    public func indexOfObject(anObject: AnyObject) -> Int {
        for var idx = 0; idx < count; idx++ {
            let obj = objectAtIndex(idx) as! NSObject
            if anObject === obj || obj.isEqual(anObject) {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObject(anObject: AnyObject, inRange range: NSRange) -> Int {
        for var idx = 0; idx < range.length; idx++ {
            let obj = objectAtIndex(idx + range.location) as! NSObject
            if anObject === obj || obj.isEqual(anObject) {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObjectIdenticalTo(anObject: AnyObject) -> Int {
        for var idx = 0; idx < count; idx++ {
            let obj = objectAtIndex(idx) as! NSObject
            if anObject === obj {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func indexOfObjectIdenticalTo(anObject: AnyObject, inRange range: NSRange) -> Int {
        for var idx = 0; idx < range.length; idx++ {
            let obj = objectAtIndex(idx + range.location) as! NSObject
            if anObject === obj {
                return idx
            }
        }
        return NSNotFound
    }
    
    public func isEqualToArray(otherArray: [AnyObject]) -> Bool {
        if count != otherArray.count {
            return false
        }
        
        for var idx = 0; idx < count; idx++ {
            let obj1 = objectAtIndex(idx) as! NSObject
            let obj2 = otherArray[idx] as! NSObject
            if obj1 === obj2 {
                continue
            }
            if !obj1.isEqual(obj2) {
                return false
            }
        }
        
        return true
    }

    public var firstObject: AnyObject? {
        get {
            if count > 0 {
                return objectAtIndex(0)
            } else {
                return nil
            }
        }
    }
    
    public var lastObject: AnyObject? {
        get {
            if count > 0 {
                return objectAtIndex(count - 1)
            } else {
                return nil
            }
        }
    }
    
    public struct Generator : GeneratorType {
        // TODO: Detect mutations
        // TODO: Use IndexingGenerator instead?
        let array : NSArray
        let sentinel : Int
        let reverse : Bool
        var idx : Int
        public mutating func next() -> AnyObject? {
            guard idx != sentinel else {
                return nil
            }
            let result = array.objectAtIndex(reverse ? idx - 1 : idx)
            idx += reverse ? -1 : 1
            return result
        }
        init(_ array : NSArray, reverse : Bool = false) {
            self.array = array
            self.sentinel = reverse ? 0 : array.count
            self.idx = reverse ? array.count : 0
            self.reverse = reverse
        }
    }
    public func objectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Generator(self))
    }
    
    public func reverseObjectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(Generator(self, reverse: true))
    }
    
    /*@NSCopying*/ public var sortedArrayHint: NSData {
        get {
            let buffer = UnsafeMutablePointer<Int32>.alloc(count)
            for var idx = 0; idx < count; idx++ {
                let item = objectAtIndex(idx) as! NSObject
                let hash = item.hash
                buffer.advancedBy(idx).memory = Int32(hash).littleEndian
            }
            return NSData(bytesNoCopy: unsafeBitCast(buffer, UnsafeMutablePointer<Void>.self), length: count * sizeof(Int), freeWhenDone: true)
        }
    }
    
    public func sortedArrayUsingFunction(comparator: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>) -> [AnyObject] {
        return sortedArrayWithOptions([]) { lhs, rhs in
            return NSComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }
    
    public func sortedArrayUsingFunction(comparator: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>, hint: NSData?) -> [AnyObject] {
        return sortedArrayWithOptions([]) { lhs, rhs in
            return NSComparisonResult(rawValue: comparator(lhs, rhs, context))!
        }
    }

    public func subarrayWithRange(range: NSRange) -> [AnyObject] {
        if range.length == 0 {
            return []
        }
        var objects = [AnyObject]()
        getObjects(&objects, range: range)
        return objects
    }
    
    public func writeToFile(path: String, atomically useAuxiliaryFile: Bool) -> Bool { NSUnimplemented() }
    public func writeToURL(url: NSURL, atomically: Bool) -> Bool { NSUnimplemented() }
    
    public func objectsAtIndexes(indexes: NSIndexSet) -> [AnyObject] {
        var objs = [AnyObject]()
        indexes.enumerateRangesUsingBlock { (range, _) in
            objs.appendContentsOf(self.subarrayWithRange(range))
        }
        return objs
    }
    
    public subscript (idx: Int) -> AnyObject {
        get {
            // TODO: Bounds checking
            return objectAtIndex(idx)
        }
    }
    
    public func enumerateObjectsUsingBlock(block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateObjectsWithOptions([], usingBlock: block)
    }
    public func enumerateObjectsWithOptions(opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.enumerateObjectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, usingBlock: block)
    }
    public func enumerateObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard !opts.contains(.Concurrent) else {
            NSUnimplemented()
        }
        
        s.enumerateIndexesWithOptions(opts) { (idx, stop) in
            block(self.objectAtIndex(idx), idx, stop)
        }
    }
    
    public func indexOfObjectPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObjectWithOptions([], passingTest: predicate)
    }
    public func indexOfObjectWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return indexOfObjectAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, passingTest: predicate)
    }
    public func indexOfObjectAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        var result = NSNotFound
        enumerateObjectsAtIndexes(s, options: opts) { (obj, idx, stop) -> Void in
            if predicate(obj, idx, stop) {
                result = idx
                stop.memory = true
            }
        }
        return result
    }
    
    public func indexesOfObjectsPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return indexesOfObjectsWithOptions([], passingTest: predicate)
    }
    public func indexesOfObjectsWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return indexesOfObjectsAtIndexes(NSIndexSet(indexesInRange: NSMakeRange(0, count)), options: opts, passingTest: predicate)
    }
    public func indexesOfObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        let result = NSMutableIndexSet()
        enumerateObjectsAtIndexes(s, options: opts) { (obj, idx, stop) in
            if predicate(obj, idx, stop) {
                result.addIndex(idx)
            }
        }
        return result
    }

    internal func sortedArrayFromRange(range: NSRange, options: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        let count = self.count
        if range.length == 0 || count == 0 {
            return []
        }

        return allObjects.sort { lhs, rhs in
            return cmptr(lhs, rhs) == .OrderedSame
        }
    }
    
    public func sortedArrayUsingComparator(cmptr: NSComparator) -> [AnyObject] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    public func sortedArrayWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        return sortedArrayFromRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    public func indexOfObject(obj: AnyObject, inSortedRange r: NSRange, options opts: NSBinarySearchingOptions, usingComparator cmp: NSComparator) -> Int { NSUnimplemented() } // binary search
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }
    
    override internal var _cfTypeID: CFTypeID {
        return CFArrayGetTypeID()
    }
}

extension NSArray : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFArrayRef { return unsafeBitCast(self, CFArrayRef.self) }
    internal var _swiftObject: [AnyObject] {
        var array: [AnyObject]?
        Array._forceBridgeFromObjectiveC(self, result: &array)
        return array!
    }
}

extension NSMutableArray {
    internal var _cfMutableObject: CFMutableArrayRef { return unsafeBitCast(self, CFMutableArrayRef.self) }
}

extension CFArrayRef : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSArray { return unsafeBitCast(self, NSArray.self) }
    internal var _swiftObject: Array<AnyObject> { return _nsObject._swiftObject }
}

extension Array : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSArray { return _bridgeToObjectiveC() }
    internal var _cfObject: CFArrayRef { return _nsObject._cfObject }
}

public struct NSBinarySearchingOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let FirstEqual = NSBinarySearchingOptions(rawValue: 1 << 8)
    public static let LastEqual = NSBinarySearchingOptions(rawValue: 1 << 9)
    public static let InsertionIndex = NSBinarySearchingOptions(rawValue: 1 << 10)
}

public class NSMutableArray : NSArray {
    
    public func addObject(anObject: AnyObject) {
        insertObject(anObject, atIndex: count)
    }
    
    public func insertObject(anObject: AnyObject, atIndex index: Int) {
        if self.dynamicType === NSMutableArray.self {
            _storage.insert(anObject, atIndex: index)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func removeLastObject() {
        if count > 0 {
            removeObjectAtIndex(count - 1)
        }
    }
    
    public func removeObjectAtIndex(index: Int) {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeAtIndex(index)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func replaceObjectAtIndex(index: Int, withObject anObject: AnyObject) {
        if self.dynamicType === NSMutableArray.self {
            _storage.replaceRange(Range<Int>(start: index, end: index), with: [anObject])
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init() {
        self.init(capacity: 0)
    }
    
    public init(capacity numItems: Int) {
        super.init(objects: nil, count: 0)

        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(numItems)
        }
    }
    
    public required convenience init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        self.init(capacity: cnt)
        for var idx = 0; idx < cnt; idx++ {
            _storage.append(objects[idx]!)
        }
    }
    
    public required convenience init(coder: NSCoder) {
        self.init()
    }
    
    public override subscript (idx: Int) -> AnyObject {
        get {
            return objectAtIndex(idx)
        }
        set(newObject) {
            self.replaceObjectAtIndex(idx, withObject: newObject)
        }
    }
    
    public func addObjectsFromArray(otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage += otherArray
        } else {
            for obj in otherArray {
                addObject(obj)
            }
        }
    }
    
    public func exchangeObjectAtIndex(idx1: Int, withObjectAtIndex idx2: Int) {
        if self.dynamicType === NSMutableArray.self {
            swap(&_storage[idx1], &_storage[idx2])
        } else {
            NSUnimplemented()
        }
    }
    
    public func removeAllObjects() {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeAll()
        } else {
            while count > 0 {
                removeObjectAtIndex(0)
            }
        }
    }
    
    public func removeObject(anObject: AnyObject, inRange range: NSRange) {
        let idx = indexOfObject(anObject, inRange: range)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObject(anObject: AnyObject) {
        let idx = indexOfObject(anObject)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectIdenticalTo(anObject: AnyObject, inRange range: NSRange) {
        let idx = indexOfObjectIdenticalTo(anObject, inRange: range)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectIdenticalTo(anObject: AnyObject) {
        let idx = indexOfObjectIdenticalTo(anObject)
        if idx != NSNotFound {
            removeObjectAtIndex(idx)
        }
    }
    
    public func removeObjectsInArray(otherArray: [AnyObject]) {
        let set = NSSet(array : _swiftObject)
        for idx in (0..<count).reverse() {
            if set.containsObject(objectAtIndex(idx)) {
                removeObjectAtIndex(idx)
            }
        }
    }
    
    public func removeObjectsInRange(range: NSRange) {
        if self.dynamicType === NSMutableArray.self {
            _storage.removeRange(range.toRange()!)
        } else {
            for idx in range.toRange()!.reverse() {
                removeObjectAtIndex(idx)
            }
        }
    }
    public func replaceObjectsInRange(range: NSRange, withObjectsFromArray otherArray: [AnyObject], range otherRange: NSRange) { NSUnimplemented() }
    public func replaceObjectsInRange(range: NSRange, withObjectsFromArray otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(count - range.length + otherArray.count)
            for var idx = 0; idx < range.length; idx++ {
                _storage[idx + range.location] = otherArray[idx]
            }
            for var idx = range.length; idx < otherArray.count; idx++ {
                _storage.insert(otherArray[idx], atIndex: idx + range.location)
            }
        } else {
            NSUnimplemented()
        }
    }
    
    public func setArray(otherArray: [AnyObject]) {
        if self.dynamicType === NSMutableArray.self {
            _storage = otherArray
        } else {
            replaceObjectsInRange(NSMakeRange(0, count), withObjectsFromArray: otherArray)
        }
    }
    public func sortUsingFunction(compare: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Int, context: UnsafeMutablePointer<Void>) { NSUnimplemented() }
    
    public func insertObjects(objects: [AnyObject], atIndexes indexes: NSIndexSet) {
        precondition(objects.count == indexes.count)
        
        if self.dynamicType === NSMutableArray.self {
            _storage.reserveCapacity(count + indexes.count)
        }

        var objectIdx = 0
        indexes.enumerateIndexesUsingBlock() { (insertionIndex, _) in
            self.insertObject(objects[objectIdx++], atIndex: insertionIndex)
        }
    }
    
    public func removeObjectsAtIndexes(indexes: NSIndexSet) {
        indexes.enumerateRangesWithOptions(.Reverse) { (range, _) in
            self.removeObjectsInRange(range)
        }
    }
    
    public func replaceObjectsAtIndexes(indexes: NSIndexSet, withObjects objects: [AnyObject]) {
        var objectIndex = 0
        indexes.enumerateRangesUsingBlock { (range, _) in
            let subObjects = objects[objectIndex..<objectIndex + range.length]
            self.replaceObjectsInRange(range, withObjectsFromArray: Array(subObjects))
            objectIndex += range.length
        }
    }
    
    public func sortUsingComparator(cmptr: NSComparator) { NSUnimplemented() }
    public func sortWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) { NSUnimplemented() }
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }
}

extension NSArray : SequenceType {
    final public func generate() -> Generator {
        return Generator(self)
    }
}

extension Array : Bridgeable {
    public func bridge() -> NSArray { return _nsObject }
}

extension NSArray : Bridgeable {
    public func bridge() -> Array<AnyObject> { return _swiftObject }
}
