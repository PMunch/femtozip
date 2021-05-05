# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import femtozip

let
  trainDocs = ["http://espn.de", "http://popsugar.de", "http://google.de",
               "http://yahoo.de", "http://www.linkedin.com",
               "http://www.facebook.com", "http://www.stanford.edu"]
  testDoc = "check out http://www.facebook.com/someone"

test "low level":
  proc exampleGetDocCallback(docIndex: cint, docLen: ptr cint, userData: ptr array[7, string]): cstring {.cdecl.} =
    result = userData[docIndex]
    docLen[] = result.len.cint

  proc exampleReleaseDocCallback(buf: cstring, userData: ptr array[7, string]) {.cdecl.} = discard

  let model = fzBuildModel(trainDocs.len.cint, exampleGetDocCallback, exampleReleaseDocCallback, trainDocs.unsafeAddr)
  var compressed = newString(1024)
  let compressedLen = fzCompress(model, testDoc.cstring, testDoc.len.cint, compressed.cstring, compressed.len.cint)
  check compressedLen > 0
  compressed.setLen(compressedLen)

  var decompressed = newString(1024)
  let decompressedLen = fzDecompress(model, compressed.cstring, compressed.len.cint, decompressed.cstring, decompressed.len.cint)
  check decompressedLen > 0 and decompressedLen == testDoc.len
  decompressed.setLen(decompressedLen)
  check decompressed == testDoc
  fzReleaseModel(model)

test "high level":
  let
    model = buildModel(trainDocs)
    compressed = testDoc.compress(model)
    decompressed = compressed.decompress(model)
  model.release()
  check decompressed == testDoc

#test "custom":
#  type MyArray = distinct array[7, string]
#  proc get(idx: cint, length: ptr cint, data: ptr MyArray): cstring {.cdecl.} =
#    result = cast[ptr array[7, string]](data)[idx]
#    length[] = result.len.cint
#  proc release(buf: cstring, userData: ptr MyArray) {.cdecl.} = discard
#  var data = MyArray(trainDocs)
#  let
#    model = buildModel(data)
#    compressed = testDoc.compress(model)
#    decompressed = compressed.decompress(model)
#  model.release()
#  check decompressed == testDoc
