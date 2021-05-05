#{.passL: "-lfzip -lz".}
#type
#  GetCallback = proc (decIndex: cint, docLen: ptr cint, userData: pointer): cstring {.cdecl.}
#  ReleaseCallback = proc (buf: cstring, userData: pointer) {.cdecl.}
#  DestWriter = proc (buf: cstring, length: csizet, arg: pointer): cint {.cdecl.}
#{.push cdecl, header: "<femtozip.h>".}
#proc fzLoadModel*(path: cstring): pointer {.importc: "fz_load_model".}
#proc fzSaveModel*(model: pointer, path: cstring): cint {.importc: "fz_save_model".}
#proc fzBuildModel*(numDocs: cint, getCallback: GetCallback, releaseCallback: ReleaseCallback, callbackUserData: pointer): pointer {.importc: "fz_build_model".}
#proc fzReleaseModel*(model: pointer) {.importc: "fz_release_model".}
#proc fzCompress*(model: pointer, source: cstring, sourceLen: cint, dest: cstring, destCapacity: cint): cint {.importc: "fz_compress".}
#proc fzCompressWriter*(model: pointer, source: cstring, sourceLen: csizet, destWriter: DestWriter, arg: pointer): cint {.importc: "fz_compress_writer".}
#proc fzDecompress*(model: pointer, source: cstring, sourceLen: cint, dest: cstring, destCapacity: cint): cint {.importc: "fz_decompress".}
#proc fzDecompressWriter*(model: pointer, source: cstring, sourceLen: csizet, destWriter: DestWriter, arg: pointer): cint {.importc: "fz_decompress_writer".}
#{.pop.}

{.passL: "-lfzip -lz".}
type
  GetCallback[T] = proc (docIndex: cint, docLen: ptr cint, userData: ptr T): cstring {.cdecl.}
  ReleaseCallback[T] = proc (buf: cstring, userData: ptr T) {.cdecl.}
  DestWriter[T] = proc (buf: cstring, length: csizet, arg: ptr T): cint {.cdecl.}
  Model = distinct pointer
{.push cdecl, header: "<femtozip.h>".}
proc fzLoadModel*(path: cstring): Model {.importc: "fz_load_model".}
proc fzSaveModel*(model: Model, path: cstring): cint {.importc: "fz_save_model".}
proc fzBuildModel*[T](numDocs: cint, getCallback: GetCallback[T], releaseCallback: ReleaseCallback[T], callbackUserData: ptr T): Model {.importc: "fz_build_model".}
proc fzReleaseModel*(model: Model) {.importc: "fz_release_model".}
proc fzCompress*(model: Model, source: cstring, sourceLen: cint, dest: cstring, destCapacity: cint): cint {.importc: "fz_compress".}
proc fzCompressWriter*[T](model: Model, source: cstring, sourceLen: csizet, destWriter: DestWriter[T], arg: ptr T): cint {.importc: "fz_compress_writer".}
proc fzDecompress*(model: Model, source: cstring, sourceLen: cint, dest: cstring, destCapacity: cint): cint {.importc: "fz_decompress".}
proc fzDecompressWriter*[T](model: Model, source: cstring, sourceLen: csizet, destWriter: DestWriter[T], arg: ptr T): cint {.importc: "fz_decompress_writer".}
{.pop.}

type
  FZipException = object of CatchableError
  Modelable = concept m
    get(cint, ptr cint, ptr m) is cstring
    release(cstring, ptr m)
    m.len is int

proc loadModel*(path: string): Model =
  ## Load a model from a path
  fzLoadModel(path.cstring)

proc save*(model: Model, path: string) =
  ## Save a generated model to a file
  if fzSaveModel(model, path.cstring) != 0: raise new FZipException

proc buildModel*(documents: openarray[string]): Model =
  ## Build a model based on a set of documents
  {.push checks: off.}
  result = fzBuildModel(documents.len.cint,
    (proc (docIndex: cint, docLen: ptr cint,
           userData: ptr typeof(documents)): cstring {.cdecl.} =
      result = userData[docIndex]
      docLen[] = result.len.cint),
    (proc (buf: cstring, userData: ptr typeof(documents)) {.cdecl.} = discard),
    documents.unsafeAddr)
  {.pop.}

proc buildModel*(documents: Modelable): Model =
  ## This doesn't work
  fzBuildModel(documents.len.cint,
    get[typeof(documents)],
    release[typeof(documents)],
    documents.unsafeAddr)

proc release*(model: Model) =
  ## Release the model (TODO: Implement this as a destructor)
  fzReleaseModel(model)

proc compress*(source: string, model: Model, startSize = source.len): string =
  ## Compress the source string by using the model, returns the compressed data
  ## as a string. This uses an internal buffer that might have to be resized
  ## during compression, you can use startSize to change the initial size of
  ## this buffer.
  result = newString(startSize)
  while true:
    let size = fzCompress(model, source.cstring, source.len.cint,
                                 result.cstring, result.len.cint)
    if size > 0:
      result.setLen(size)
      break
    result.setLen(-size)

proc decompress*(source: string, model: Model, startSize = source.len*3): string =
  ## Decompresses the source string by using the model. Similar to how compress
  ## has an internal buffer this procedure does as well. If you know the size
  ## of the initial data you can use that to ensure the buffer won't resize.
  result = newString(startSize)
  while true:
    let size = fzDecompress(model, source.cstring, source.len.cint, result.cstring, result.len.cint)
    if size > 0:
      result.setLen(size)
      break
    result.setLen(-size)
