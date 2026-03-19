#include "q_skia.h"
#include "q_skia_core.h"

extern "C" {
EXPORT K k_skia_set_background_colour(K k_skia, K k_argb) {
    QSkia *qskia;
    int32_t argb;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_INT(argb, k_argb);

    qskia->setBackgroundColour((uint32_t)argb);
    return (K)0;
}

EXPORT K k_skia_set_fill_colour(K k_skia, K k_argb) {
    QSkia *qskia;
    int32_t argb;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_INT(argb, k_argb);

    qskia->setFillColour((uint32_t)argb);
    return (K)0;
}

EXPORT K k_skia_set_stroke_colour(K k_skia, K k_argb) {
    QSkia *qskia;
    int32_t argb;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_INT(argb, k_argb);

    qskia->setStrokeColour((uint32_t)argb);
    return (K)0;
}

EXPORT K k_skia_set_stroke_width(K k_skia, K k_width) {
    QSkia *qskia;
    float width;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_UFLOAT(width, k_width);

    qskia->setStrokeWidth(width);
    return (K)0;
}
}
