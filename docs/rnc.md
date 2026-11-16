# RNC extraction

`tools/extract-originals.sh` builds the Meh decoder and extracts the supplied
RNC1 resources into ignored `build/extracted/`. It never writes to `reference/`.
Run `MEH_BACKEND=llvm mehc test rnc_test.meh` for the synthetic regression suite.
The current native Darwin backend rejects an interface-valued return used by
this decoder, so these commands explicitly select the compiler's LLVM backend.

The supplied Captive files use the original twelve-byte RNC1 header and
backward bitstream. This format has no stored checksums. The decoder also
supports the later eighteen-byte RNC1 format with packed and unpacked CRC-16,
canonical Huffman tables and forward references. It bounds input access,
output size (16 MiB), literal runs, back references and chunk count. Failed
input returns an error without returning partially decoded bytes.

The decoder was written with Teemu Suutari's Ancient implementation as the
algorithmic reference:
https://github.com/temisu/ancient/blob/master/src/RNCDecompressor.cpp
and its VariableLengthCodeDecoder.hpp and InputStream.hpp helpers.
Applicable BSD-2-Clause copyright, conditions and disclaimer are retained in
`notices/ancient-BSD-2-Clause.txt`. No Pinball decoder code was copied.

Old/new format detection is structurally ambiguous because both have the
same signature. Complete old streams must consume their packed payload;
modern streams verify both CRCs. Original output remains original game data,
not newly licensed project code.

Verification: all thirty supplied RNC1 resources decoded successfully and
matched byte-for-byte against independently built upstream Ancient commit
`1491a35a2c49a97e77757e744e7ed6e4fe5e6bab` (`ancient decompress`, followed by
`cmp`). The synthetic suite passes 52 checks, including old/new overlapping
back references, known CRC vector, corrupted CRC fields, truncation of every
fixture prefix, invalid references and excessive allocation bounds.
