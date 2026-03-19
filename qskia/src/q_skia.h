#ifndef QSKIA_defined
#define QSKIA_defined

#include <stdint.h>
#include <vector>

#include "SkBitmap.h"
#include "SkCanvas.h"
#include "SkFont.h"
#include "SkImageInfo.h"
#include "SkPaint.h"
#include "SkScalar.h"
#include "SkTypeface.h"
#include "k.h"

class QSkia {
 public:
        enum FontAlign { AlignLeft, AlignMiddle, AlignRight };
        enum FontStyle { StyleRegular, StyleItalic, StyleBold, StyleBoldItalic };
        enum FontFamily { FamilyRegular, FamilyMonospace };

        QSkia(unsigned int width, unsigned int height);
        ~QSkia();

        static int initialize(char *fontpath);

        void addCircle(float x, float y, float radius);
        void addRect(float x, float y, float width, float height);
        void addLine(float x1, float y1, float x2, float y2);
        void addDashedLine(float x1, float y1, float x2, float y2, float on, float off);
        void setBackgroundColour(uint32_t);
        void setFillColour(uint32_t);
        void setStrokeColour(uint32_t);
        void setStrokeWidth(float width);
        void setFontSize(int size);
        void setFontFace(const char *fontfamily, char bold, char italic);
        void addText(float x, float y, const char* str);
        void addTextMiddleAnchor(float x, float y, const char* str);
        void addTextLeftAnchor(float x, float y, const char* str);
        void addTextRightAnchor(float x, float y, const char* str);
        void addPath(char close, unsigned int n, float * xxs, float * yys);
        void rotate(float degrees, float x, float y);
        float measureText(const char *str, const uint64_t len);
        void restore();

        void multiFillCircle(unsigned int n, float * xxs, float * yys, float * rs, uint32_t * ffs,
                bool * single);
        void multiStrokeCircle(unsigned int n, float * xxs, float * yys, float * rs, uint32_t * ffs,
                float * ws, bool * single);
        void multiFillRect(unsigned int n, float * xxs, float * yys, float * ws, float * hs,
                uint32_t * ffs, bool * single);
        void multiStrokeRect(unsigned int n, float * xxs, float * yys, float * ws, float * hs,
                uint32_t * ffs, float * sws, bool * single);
        void multiLine(unsigned int n, float * x1, float * y1, float * x2, float * y2,
                uint32_t *ffs, float * ws, bool * single);
        void multiFillPath(unsigned int n, unsigned char * close, K * xxs, K * yys, uint32_t *ffs,
                bool * single);
        void multiStrokePath(unsigned int n, unsigned char * close, K * xxs, K * yys,
                uint32_t *ffs, float * ws, bool * single);
        void addPixels(unsigned int width, unsigned int height, float px, float py,
                unsigned int * pixels);

        FontStyle fontStyle;
        FontFamily fontFamily;
        FontAlign fontAlign;

        SkBitmap       *bitmap;
        SkCanvas       *canvas;
        SkPaint        *paint;
        SkImageInfo    *imageInfo;

 private:
        void setupTextPaint();
        void addTextWithAnchor(float x, float y, FontAlign align, const char* str);
        void drawText(const float x, const float y, const char* text);
        sk_sp<SkTypeface> getFont(const unsigned int index);

        float traverseText(const char *, unsigned int, float, float, unsigned char,
                std::vector<unsigned int>,
                std::vector<unsigned int>,
                SkFont&);

        unsigned int height;
        unsigned int width;
        SkScalar fontSize;
};

#endif  // QSKIA_defined
