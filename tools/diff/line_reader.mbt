///|
priv struct LineReader {
  file : @fs.File
  mut closed : Bool
}

///|
priv enum StreamItem {
  Line(String)
  End
  ReadError(String)
}

///|
async fn LineReader::open(path : String) -> LineReader {
  LineReader::{ file: @fs.open(path, mode=ReadOnly), closed: false }
}

///|
async fn LineReader::next(self : LineReader) -> StreamItem {
  if self.closed {
    return ReadError("line reader is closed")
  }
  try self.file.read_until("\n") catch {
    error => ReadError("\{error}")
  } noraise {
    Some(line) =>
      match line.strip_suffix("\r") {
        Some(without_cr) => Line(without_cr.to_owned())
        None => Line(line)
      }
    None => End
  }
}

///|
fn LineReader::close(self : LineReader) -> Bool {
  if self.closed {
    return true
  }
  self.closed = true
  self.file.close()
  true
}
