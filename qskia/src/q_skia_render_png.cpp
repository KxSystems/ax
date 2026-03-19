#include "SkStream.h"
#include "SkPngEncoder.h"
#include "q_skia.h"
#include "q_skia_core.h"

extern "C" {
EXPORT K k_skia_render_to_memory(K k_skia) {
    QSkia *qskia;
    K ret = (K)0;
    SkDynamicMemoryWStream srgbBuf;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    try {
        SkPngEncoder::Encode(&srgbBuf, qskia->bitmap->pixmap(), SkPngEncoder::Options());
        ret = ktn(KG, srgbBuf.bytesWritten());
        srgbBuf.copyTo(kG(ret));
    } catch (...) {
        KTHROW("png");
    }

    return ret;
}
}
