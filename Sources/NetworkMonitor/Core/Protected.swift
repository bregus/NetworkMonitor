//
//  File.swift
//  
//
//  Created by Рома Сумороков on 31.10.2023.
//

import Foundation

private protocol Lock {
  func lock()
  func unlock()
}

extension Lock {
  func around<T>(_ closure: () throws -> T) rethrows -> T {
    lock(); defer { unlock() }
    return try closure()
  }

  func around(_ closure: () throws -> Void) rethrows {
    lock(); defer { unlock() }
    try closure()
  }
}

final class UnfairLock: Lock {
  private let unfairLock: os_unfair_lock_t

  init() {
    unfairLock = .allocate(capacity: 1)
    unfairLock.initialize(to: os_unfair_lock())
  }

  deinit {
    unfairLock.deinitialize(count: 1)
    unfairLock.deallocate()
  }

  fileprivate func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  fileprivate func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }
}

@dynamicMemberLookup
final class Protected<T> {
  private let lock = UnfairLock()
  private var value: T

  init(_ value: T) {
    self.value = value
  }

  /// The contained value. Unsafe for anything more than direct read or write.
  var wrappedValue: T {
    get { lock.around { value } }
    set { lock.around { value = newValue } }
  }

  var projectedValue: Protected<T> { self }

  init(wrappedValue: T) {
    value = wrappedValue
  }

  func read<U>(_ closure: (T) throws -> U) rethrows -> U {
    try lock.around { try closure(self.value) }
  }

  @discardableResult
  func write<U>(_ closure: (inout T) throws -> U) rethrows -> U {
    try lock.around { try closure(&self.value) }
  }

  subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
    get { lock.around { value[keyPath: keyPath] } }
    set { lock.around { value[keyPath: keyPath] = newValue } }
  }

  subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
    lock.around { value[keyPath: keyPath] }
  }
}
