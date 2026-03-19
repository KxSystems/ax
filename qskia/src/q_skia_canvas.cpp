#include "q_skia.h"
#include "q_skia_core.h"

extern "C" {
EXPORT K k_skia_rotate_canvas(K k_skia, K k_degrees, K k_x, K k_y) {
    QSkia *qskia;
    float degrees, x, y;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(degrees, k_degrees);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);

    qskia->rotate(degrees, x, y);
    return (K)0;
}

EXPORT K k_skia_restore_canvas(K k_skia) {
    QSkia *qskia;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    try {
        qskia->restore();
    } catch (...) {
        KTHROW("already-restored");
    }

    return (K)0;
}
}
