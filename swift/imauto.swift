import Carbon
import Foundation

// imauto: tiny Carbon TIS wrapper used by imauto.nvim.
//
// Usage:
//   imauto                       -> prints the current input source id
//   imauto <inputSourceId>       -> selects the given input source
//   imauto --swap <inputSourceId> -> prints current id, then selects the given
//                                    one (single-process read-then-set)
//
// Exit codes: 0 on success, non-zero on failure.

func currentSourceID() -> String? {
  guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
    return nil
  }
  guard let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else {
    return nil
  }
  return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
}

func findSource(id: String, includeAll: Bool) -> TISInputSource? {
  let filter: [CFString: Any] = [kTISPropertyInputSourceID: id]
  guard
    let list = TISCreateInputSourceList(filter as CFDictionary, includeAll)?
      .takeRetainedValue() as? [TISInputSource]
  else {
    return nil
  }
  return list.first
}

func selectSource(id: String) -> Bool {
  // Prefer enabled sources first; fall back to all sources for keyboard layouts
  // that exist on the system but aren't currently in the input menu.
  let candidate = findSource(id: id, includeAll: false) ?? findSource(id: id, includeAll: true)
  guard let src = candidate else { return false }

  // CJK IMEs on macOS occasionally update the menu bar but fail to activate
  // the actual input mode (a long-standing TIS quirk). Verify-and-retry once
  // with a short delay to mitigate; cheap on the happy path.
  for attempt in 0..<2 {
    if TISSelectInputSource(src) != noErr {
      return false
    }
    if attempt == 0 {
      usleep(15_000)  // 15 ms
    }
    if currentSourceID() == id {
      return true
    }
  }
  return false
}

let args = CommandLine.arguments
if args.count == 1 {
  if let id = currentSourceID() {
    print(id)
    exit(0)
  }
  FileHandle.standardError.write(Data("imauto: failed to read current input source\n".utf8))
  exit(1)
}

if args.count == 2 {
  exit(selectSource(id: args[1]) ? 0 : 2)
}

if args.count == 3 && args[1] == "--swap" {
  if let id = currentSourceID() {
    print(id)
  }
  exit(selectSource(id: args[2]) ? 0 : 2)
}

FileHandle.standardError.write(Data("usage: imauto [<inputSourceId> | --swap <inputSourceId>]\n".utf8))
exit(64)
