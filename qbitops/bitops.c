#include "k.h"
#include <stdint.h>

#if defined(_WIN32) || defined(_WIN64)
  #define EXP __declspec(dllexport)
#else
  #define EXP __attribute__((visibility("default")))
#endif

EXP K2(k_bit_and) {
    P(xt  != -KI, krr("type"));
    P(y->t != -KI, krr("type"));
    I result = (I)((int64_t)x->i & (int64_t)y->i);
    R ki(result);
}

EXP K2(k_bit_or) {
    P(xt  != -KI, krr("type"));
    P(y->t != -KI, krr("type"));
    I result = (I)((int64_t)x->i | (int64_t)y->i);
    R ki(result);
}

EXP K2(k_bit_ls) {
    P(xt  != -KI, krr("type"));
    P(y->t != -KI, krr("type"));
    P(y->i < 0 || y->i >= 32, krr("domain"));
    I result = (I)((uint32_t)x->i << (unsigned)y->i);
    R ki(result);
}


EXP K1(kexport){
K n=ktn(KS,0),f=ktn(0,0);
#define _(c,a) js(&n,ss(#c));jk(&f,dl((V*)c,a));
_(k_bit_and,2)_(k_bit_or,2)_(k_bit_ls,2)
  R xD(n,f);
}
