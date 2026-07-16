///|
let legacy_stream_buffer_size : Int = 64 * 1024

///|
priv struct LegacyStreamComparator {
  file : @fs.File
  mut expected : Bytes
  mut expected_index : Int
  mut offset : Int
  mut failure : String?
  mut closed : Bool
}

///|
async fn LegacyStreamComparator::open(path : String) -> LegacyStreamComparator {
  LegacyStreamComparator::{
    file: @fs.open(path, mode=ReadOnly),
    expected: b"",
    expected_index: 0,
    offset: 0,
    failure: None,
    closed: false,
  }
}

///|
async fn LegacyStreamComparator::refill(self : LegacyStreamComparator) -> Bool {
  if self.expected_index < self.expected.length() {
    return true
  }
  match self.file.read_some(max_len=legacy_stream_buffer_size) {
    Some(expected) => {
      self.expected = expected
      self.expected_index = 0
      true
    }
    None => false
  }
}

///|
async fn LegacyStreamComparator::compare_bytes(
  self : LegacyStreamComparator,
  actual : Bytes,
) -> Unit {
  if self.failure is Some(_) {
    return
  }
  let mut actual_index = 0
  while actual_index < actual.length() {
    guard self.refill() else {
      self.failure = Some(
        "byte mismatch at \{self.offset}: expected=-1 actual=\{actual[actual_index].to_int()}",
      )
      return
    }
    let shared = Int::min(
      self.expected.length() - self.expected_index,
      actual.length() - actual_index,
    )
    let expected_view = self.expected.view(
      start=self.expected_index,
      end=self.expected_index + shared,
    )
    let actual_view = actual.view(start=actual_index, end=actual_index + shared)
    if expected_view != actual_view {
      for relative in 0..<shared {
        let expected_byte = self.expected[self.expected_index + relative]
        let actual_byte = actual[actual_index + relative]
        if expected_byte != actual_byte {
          self.failure = Some(
            "byte mismatch at \{self.offset + relative}: expected=\{expected_byte.to_int()} actual=\{actual_byte.to_int()}",
          )
          return
        }
      }
    }
    self.expected_index += shared
    self.offset += shared
    actual_index += shared
  }
}

///|
async fn LegacyStreamComparator::write(
  self : LegacyStreamComparator,
  chunk : String,
) -> Unit {
  self.compare_bytes(@utf8.encode(chunk))
}

///|
async fn LegacyStreamComparator::spaces(
  self : LegacyStreamComparator,
  length : Int,
) -> Unit {
  let mut remaining = length
  while remaining > 0 && self.failure is None {
    let chunk_length = Int::min(remaining, 4096)
    self.compare_bytes(Bytes::make(chunk_length, b' '))
    remaining -= chunk_length
  }
}

///|
fn LegacyStreamComparator::close(self : LegacyStreamComparator) -> Unit {
  if !self.closed {
    self.closed = true
    self.file.close()
  }
}

///|
async fn LegacyStreamComparator::finish(
  self : LegacyStreamComparator,
) -> String? {
  if self.failure is None && self.refill() {
    self.failure = Some(
      "byte mismatch at \{self.offset}: expected=\{self.expected[self.expected_index].to_int()} actual=-1",
    )
  }
  self.close()
  self.failure
}
