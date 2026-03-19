#pragma once

#include <set>
#include <cstring>

#include "k.h"

extern bool initialized;

extern char errbuf[512];

class QSkia;
extern std::set<QSkia*> skiaSet;

/* macro for measuring time taken by blocks of code */
#define BENCH(msg, block)                               \
    time_t t = clock();                                 \
    block;                                              \
    t = clock() - t;                                    \
    double time_taken = ((double)t)/CLOCKS_PER_SEC;     \
    fprintf(stderr, "Time to %s: %f\n", msg, time_taken);

/* handy macro for throwing K errors
 * the cast is to prevent const char warnings (kx's header prototype
 * doesn't necessarily specify that krr takes a "const" char *) */
#define KTHROW(ERR) do {krr((char*)(ERR)); return (K)0;} while (0)

/* handy macro for ensuring the library is initialized */
#define ASSERT_INITIALIZED() {if (!initialized) {KTHROW("not-initialized");}}

/* macro to extract and verify an Skia pointer from a byte-list */
#define UNPACK_K_QSKIA(TO, FROM)                        \
    if (FROM->t != 112) {                               \
        KTHROW("type");                                 \
    }                                                   \
    TO = (QSkia*)kK(FROM)[1]->j;                        \
    if (skiaSet.find(TO) == skiaSet.end()) {            \
        KTHROW("type");                                 \
    }

/* macro to extract and verify an RGB colour from a byte-list
 * and pack it into the type that Skia expects */
#define UNPACK_K_COLOUR(TO, FROM)          \
    if (FROM->t != KG || FROM->n != 3) {   \
        KTHROW("type");                    \
    }                                      \
                                           \
    TO = 0xFF000000;                       \
    TO |= kG(FROM)[0] << 16;               \
    TO |= kG(FROM)[1] << 8;                \
    TO |= kG(FROM)[2];

/* macro to extract and verify an ARGB colour from a byte-list
 * and pack it into the type that Skia expects */
#define UNPACK_K_ARGB(TO, FROM)          \
    if (FROM->t != KG || FROM->n != 4) {   \
        KTHROW("type");                    \
    }                                      \
                                           \
    TO = 0x00000000;                       \
    TO |= kG(FROM)[0] << 24;               \
    TO |= kG(FROM)[1] << 16;               \
    TO |= kG(FROM)[2] << 8;                \
    TO |= kG(FROM)[3];

/* macro to extract a K integer atom of any type (byte/short/int/long)
 * into a single long value for later use */
#define UNPACK_K_INT(TO, FROM)   \
    switch (FROM->t) {           \
        case -KG:                \
            TO = FROM->g;        \
            break;               \
        case -KH:                \
            TO = FROM->h;        \
            break;               \
        case -KI:                \
            TO = FROM->i;        \
            break;               \
        case -KJ:                \
            TO = FROM->j;        \
            break;               \
        default:                 \
            KTHROW("type");      \
    }

#define UNPACK_K_UINT(TO, FROM)  \
    switch (FROM->t) {           \
        case -KG:                \
            TO = (unsigned int)FROM->g;        \
            break;               \
        case -KH:                \
            if (FROM->h < 0) {   \
                KTHROW("sign");  \
            }                    \
            TO = (unsigned int)FROM->h;        \
            break;               \
        case -KI:                \
            if (FROM->i < 0) {   \
                KTHROW("sign");  \
            }                    \
            TO = (unsigned int)FROM->i;        \
            break;               \
        case -KJ:                \
            if (FROM->j < 0) {   \
                KTHROW("sign");  \
            }                    \
            TO = (unsigned int)FROM->j;        \
            break;               \
        default:                 \
            KTHROW("type");      \
    }

/* macro to extract a K float atom of any type (byte/short/int/long/real/float)
 * into a single double value for later use */
#define UNPACK_K_FLOAT(TO, FROM)    \
    switch (FROM->t) {              \
        case -KE:                   \
            TO = FROM->e;           \
            break;                  \
        case -KF:                   \
            TO = FROM->f;           \
            break;                  \
        default:                    \
            UNPACK_K_INT(TO, FROM); \
    }

#define UNPACK_K_UFLOAT(TO, FROM)    \
    switch (FROM->t) {               \
        case -KE:                    \
            if (FROM->e < 0) {       \
                KTHROW("sign");      \
            }                        \
            TO = FROM->e;            \
            break;                   \
        case -KF:                    \
            if (FROM->f < 0) {       \
                KTHROW("sign");      \
            }                        \
            TO = FROM->f;            \
            break;                   \
        default:                     \
            UNPACK_K_UINT(TO, FROM); \
    }

/* Macro to extract a null-terminated string from either a symbol,
 * char or char-list. TO must be delete[]ed by the caller to avoid leaks. */
#define UNPACK_K_STRING(TO, FROM)                  \
    if (FROM->t == -KS) {                          \
        TO = new char[strlen(FROM->s) + 1];        \
        strncpy(TO, FROM->s, strlen(FROM->s)+1);   \
    } else if (FROM->t == KC) {                    \
        TO = new char[FROM->n + 1];                \
        strncpy(TO, (char*)kC(FROM), FROM->n);     \
        TO[FROM->n] = '\0';                        \
    } else if (FROM->t == -KC) {                   \
        TO = new char[2];                          \
        TO[0] = FROM->g;                           \
        TO[1] = '\0';                              \
    } else {                                       \
        KTHROW("type");                            \
    }

#define BUILD_FOREIGN_OBJ(cleanup_fn, ptr, obj)             \
    obj = knk(2, cleanup_fn, kj((std::int64_t)ptr));        \
    obj->t = 112;                                           \

#define RETURN_FOREIGN(cleanup_fn, ptr)                     \
    K ret;                                                  \
    BUILD_FOREIGN_OBJ(cleanup_fn, ptr, ret)                 \
    return ret;                                             \

/* Macro to define __declspec(dllexport) if compiling on windows */
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif
