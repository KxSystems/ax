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

EXPORT K k_skia_render_to_rgb(K k_skia) {
    QSkia *qskia;
    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    const SkBitmap* bmp = qskia->bitmap;
    const int width    = bmp->width();
    const int height   = bmp->height();
    const int channels = SkColorTypeBytesPerPixel(bmp->colorType());
    const size_t rowBytes  = (size_t)width * channels;
    const size_t totalBytes = (size_t)height * rowBytes;

    K kBytes = ktn(KG, totalBytes);

    const uint8_t* src = reinterpret_cast<const uint8_t*>(bmp->getPixels());
    if (bmp->rowBytes() == rowBytes) {
        memcpy(kG(kBytes), src, totalBytes);
    } else {
        uint8_t* dst = kG(kBytes);
        for (int y = 0; y < height; y++) {
            memcpy(dst, src, rowBytes);
            dst += rowBytes;
            src += bmp->rowBytes();
        }
    }

    K ret = knk(4,
        ki(width),
        ki(height),
        ki(channels),
        kBytes
    );

    return ret;
}
}
