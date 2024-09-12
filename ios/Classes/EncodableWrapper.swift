struct EncodableWrapper: Encodable {
  private let wrapped: Encodable

  init(_ wrapped: Encodable) {
    self.wrapped = wrapped
  }

  func encode(to encoder: Encoder) throws {
    try? self.wrapped.encode(to: encoder)
  }
}

extension [Encodable] {
  func wrap() -> [EncodableWrapper] {
    map(EncodableWrapper.init)
  }
}
