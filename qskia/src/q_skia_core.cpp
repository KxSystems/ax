#include "q_skia.h"
#include "q_skia_core.h"

bool initialized = false;

std::set<QSkia*> skiaSet;

extern "C" {
EXPORT K k_skia_delete(K k_skia) {
    QSkia *qskia;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    if (skiaSet.find(qskia) != skiaSet.end()) {
        skiaSet.erase(qskia);
        delete qskia;
    }

    return (K)0;
}

EXPORT K k_skia_new(K k_width, K k_height) {
    QSkia *qskia;
    unsigned int width;
    unsigned int height;

    ASSERT_INITIALIZED();
    UNPACK_K_UINT(width, k_width);
    UNPACK_K_UINT(height, k_height);

    qskia = new QSkia(width, height);
    skiaSet.insert(qskia);

    RETURN_FOREIGN(k_skia_delete, qskia);
}

EXPORT K k_skia_init(K k_fontpath) {
    if (initialized) {
        KTHROW("already-initialized");
    }

    char *fontpath;
    UNPACK_K_STRING(fontpath, k_fontpath);

    initialized = true;
    QSkia::initialize(fontpath);

    delete[] fontpath;
    return (K)0;
}

EXPORT K k_skia_supports_integers() { return (K)0; }
EXPORT K k_skia_supports_pixmap()   { return (K)0; }
}
