# femtozip

This is a low- and high-level wrapper for the
[femtozip](https://github.com/gtoubassi/femtozip) library. This library is made
for compressing small documents using a pre-shared header built from a sampling
of data. The test case in the `tests` directory shows how you can use both
versions of the wrapper. Before doing so you need zlib installed and build and
install femtozip according to their build instructions. In order to run the
test you need to make sure that `libfzip.so` is in your `LD_LIBRARY_PATH`.

# NOTE:
In order to build I had to change line 32 of `cpp/libfz/src/IntSet.h` to have
`constexpr` on it. Whether or not this is generally needed or simply because I
use a very new GCC compiler I have no idea.
