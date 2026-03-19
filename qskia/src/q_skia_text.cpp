#include "q_skia.h"
#include "q_skia_core.h"

extern "C" {
EXPORT K k_skia_add_text(K k_skia, K k_x, K k_y, K k_str) {
    QSkia *qskia;
    float x, y;
    char *str;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_STRING(str, k_str);

    qskia->addText(x, y, str);
    delete[] str;
    return (K)0;
}

EXPORT K k_skia_add_text_middle_anchor(K k_skia, K k_x, K k_y, K k_str) {
    QSkia *qskia;
    float x, y;
    char *str;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_STRING(str, k_str);

    qskia->addTextMiddleAnchor(x, y, str);
    delete[] str;
    return (K)0;
}

EXPORT K k_skia_add_text_left_anchor(K k_skia, K k_x, K k_y, K k_str) {
    QSkia *qskia;
    float x, y;
    char *str;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_STRING(str, k_str);

    qskia->addTextLeftAnchor(x, y, str);
    delete[] str;
    return (K)0;
}

EXPORT K k_skia_add_text_right_anchor(K k_skia, K k_x, K k_y, K k_str) {
    QSkia *qskia;
    float x, y;
    char *str;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_STRING(str, k_str);

    qskia->addTextRightAnchor(x, y, str);
    delete[] str;
    return (K)0;
}

EXPORT K k_skia_set_font_size(K k_skia, K k_font_size) {
    QSkia *qskia;
    unsigned int size;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_UINT(size, k_font_size);

    qskia->setFontSize(size);
    return (K)0;
}

EXPORT K k_skia_set_fontface(K k_skia, K k_fontfamily, K k_bold, K k_italic) {
    QSkia *qskia;
    char *fontfamily;
    char bold, italic;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_STRING(fontfamily, k_fontfamily);

    if (k_bold->t != -KB) { krr((char *)"type"); }
    if (k_italic->t != -KB) { krr((char *)"type"); }

    qskia->setFontFace(fontfamily, k_bold->g, k_italic->g);
    delete[] fontfamily;
    return (K)0;
}

EXPORT K k_skia_measure_text(K k_skia, K k_str) {
    QSkia *qskia;
    char *str;
    float width;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_STRING(str, k_str);

    width = qskia->measureText(str, k_str->n);
    delete[] str;
    return kf(width);
}
}
