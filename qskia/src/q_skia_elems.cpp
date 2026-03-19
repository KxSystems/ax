#include "q_skia.h"
#include "q_skia_core.h"

extern "C" {
EXPORT K k_skia_add_circle(K k_skia, K k_x, K k_y, K k_radius) {
    QSkia *qskia;
    float x;
    float y;
    float radius;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_FLOAT(radius, k_radius);

    qskia->addCircle(x, y, radius);
    return (K)0;
}

EXPORT K k_skia_multi_stroke_circle(K k_skia, K k_xs, K k_ys, K k_rs, K k_cs, K k_ws) {
    QSkia* qskia;

    bool single[3];
    single[0] = k_rs->n == 1;
    single[1] = k_cs->n == 1;
    single[2] = k_ws->n == 1;

    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_rs->n && k_rs->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiStrokeCircle(k_xs->n, kE(k_xs), kE(k_ys), kE(k_rs), (uint32_t*)kI(k_cs), kE(k_ws),
        single);
    return (K)0;
}

EXPORT K k_skia_multi_fill_circle(K k_skia, K k_xs, K k_ys, K k_rs, K k_ffs) {
    QSkia* qskia;

    bool single[2];
    single[0] = k_rs->n == 1;
    single[1] = k_ffs->n == 1;

    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_rs->n && k_rs->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiFillCircle(k_xs->n, kE(k_xs), kE(k_ys), kE(k_rs), (uint32_t*)kI(k_ffs), single);
    return (K)0;
}

EXPORT K k_skia_multi_fill_rect(K k_skia, K k_xs, K k_ys, K k_ws, K k_hs, K k_ffs) {
    QSkia* qskia;

    bool single[3];
    single[0] = k_ws->n == 1;
    single[1] = k_hs->n == 1;
    single[2] = k_ffs->n == 1;

    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ws->n && k_ws->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_hs->n && k_hs->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ffs->n && k_ffs->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiFillRect(
            k_xs->n, kE(k_xs), kE(k_ys), kE(k_ws), kE(k_hs), (uint32_t*)kI(k_ffs), single);
    return (K)0;
}

EXPORT K k_skia_multi_stroke_rect(K k_skia, K k_xs, K k_ys, K k_ws, K k_hs, K k_ffs, K k_sws) {
    QSkia* qskia;

    bool single[4];
    single[0] = k_ws->n == 1;
    single[1] = k_hs->n == 1;
    single[2] = k_ffs->n == 1;
    single[3] = k_sws->n == 1;

    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ws->n && k_ws->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_hs->n && k_hs->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ffs->n && k_ffs->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_sws->n && k_sws->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiStrokeRect(k_xs->n, kE(k_xs), kE(k_ys), kE(k_ws), kE(k_hs),
        (uint32_t*)kI(k_ffs), kE(k_sws), single);
    return (K)0;
}

EXPORT K k_skia_add_rect(K k_skia, K k_x, K k_y, K k_width, K k_height) {
    QSkia *qskia;
    float x;
    float y;
    float width;
    float height;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x, k_x);
    UNPACK_K_FLOAT(y, k_y);
    UNPACK_K_FLOAT(width,  k_width);
    UNPACK_K_FLOAT(height, k_height);

    qskia->addRect(x, y, width, height);
    return (K)0;
}

EXPORT K k_skia_add_dashed_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2, K k_on, K k_off) {
    QSkia *qskia;
    float x1;
    float y1;
    float x2;
    float y2;
    float on;
    float off;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x1, k_x1);
    UNPACK_K_FLOAT(y1, k_y1);
    UNPACK_K_FLOAT(x2, k_x2);
    UNPACK_K_FLOAT(y2, k_y2);
    UNPACK_K_FLOAT(on, k_on);
    UNPACK_K_FLOAT(off, k_off);

    qskia->addDashedLine(x1, y1, x2, y2, on, off);
    return (K)0;
}

EXPORT K k_skia_add_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2) {
    QSkia *qskia;
    float x1;
    float y1;
    float x2;
    float y2;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_FLOAT(x1, k_x1);
    UNPACK_K_FLOAT(y1, k_y1);
    UNPACK_K_FLOAT(x2, k_x2);
    UNPACK_K_FLOAT(y2, k_y2);

    qskia->addLine(x1, y1, x2, y2);
    return (K)0;
}

EXPORT K k_skia_multi_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2, K k_ffs, K k_ws) {
    QSkia *qskia;

    bool single[2];
    single[0] = k_ffs->n == 1;
    single[1] = k_ws->n == 1;

    if (k_x1->n != k_y1->n) {
        krr((char *)"length");
    }
    if (k_x1->n != k_x2->n) {
        krr((char *)"length");
    }
    if (k_x1->n != k_y2->n) {
        krr((char *)"length");
    }
    if (k_x1->n != k_ffs->n && k_ffs->n != 1) {
        krr((char *)"length");
    }
    if (k_x1->n != k_ws->n && k_ws->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiLine(k_x1->n, kE(k_x1), kE(k_y1), kE(k_x2),
            kE(k_y2), (uint32_t*)kI(k_ffs), kE(k_ws), single);
    return (K)0;
}

EXPORT K k_skia_add_path(K k_skia, K k_close, K k_xs, K k_ys) {
    QSkia* qskia;

    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->addPath(k_close->g, k_xs->n, kE(k_xs), kE(k_ys));
    return (K)0;
}

EXPORT K k_skia_multi_fill_path(K k_skia, K k_close, K k_xs, K k_ys, K k_fs) {
    QSkia* qskia;

    bool single[2];
    single[0] = k_close->n == 1;
    single[1] = k_fs->n == 1;

    if (k_xs->n != k_close->n && k_close->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_fs->n && k_fs->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiFillPath(k_xs->n, kG(k_close), kK(k_xs), kK(k_ys), (uint32_t*)kI(k_fs), single);
    return (K)0;
}

EXPORT K k_skia_multi_stroke_path(K k_skia, K k_close, K k_xs, K k_ys, K k_fs, K k_ws) {
    QSkia* qskia;

    bool single[3];
    single[0] = k_close->n == 1;
    single[1] = k_fs->n == 1;
    single[2] = k_ws->n == 1;

    if (k_xs->n != k_close->n && k_close->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ys->n) {
        krr((char *)"length");
    }
    if (k_xs->n != k_fs->n && k_fs->n != 1) {
        krr((char *)"length");
    }
    if (k_xs->n != k_ws->n && k_ws->n != 1) {
        krr((char *)"length");
    }

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);

    qskia->multiStrokePath(k_xs->n, kG(k_close), kK(k_xs), kK(k_ys), (uint32_t*)kI(k_fs), kE(k_ws),
        single);
    return (K)0;
}

EXPORT K k_skia_add_pixels(K k_skia, K k_width, K k_height, K k_px, K k_py, K k_pixels) {
    QSkia* qskia;
    int px, py, width, height;

    ASSERT_INITIALIZED();
    UNPACK_K_QSKIA(qskia, k_skia);
    UNPACK_K_INT(px, k_px);
    UNPACK_K_INT(py, k_py);
    UNPACK_K_INT(width, k_width);
    UNPACK_K_INT(height, k_height);

    qskia->addPixels(width, height, px, py, (unsigned int*)kI(k_pixels));
    return (K)0;
}

}
