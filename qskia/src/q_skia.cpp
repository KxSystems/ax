#include "SkColor.h"
#include "SkDashPathEffect.h"
#include "SkFont.h"
#include "SkFontMgr.h"
#include "SkFontMgr_empty.h"
#include "SkImage.h"
#include "SkPath.h"
#include "q_skia.h"
#include "q_skia_core.h"

#ifdef _WIN32
#include <io.h>
#include <string.h>
#else
#include <unistd.h>
#include <string>
#endif

#define printList(list, n) {\
    for(int i = 0; i < n; ++i) {\
        fprintf(stderr, #list "[%d] = %d\n", i, list[i]);\
    }\
}

static bool isGlyph(unsigned char c) {
    // The byte that represents a new glyph will have 10xxxx.. as the most significant digits
    return 0x80 != (c & 0xc0);
}

static std::vector<sk_sp<SkTypeface>> fontsRegular;
static std::vector<sk_sp<SkTypeface>> fontsItalic;
static std::vector<sk_sp<SkTypeface>> fontsBold;
static std::vector<sk_sp<SkTypeface>> fontsBoldItalic;
static std::vector<sk_sp<SkTypeface>> fontsMonoRegular;
static std::vector<sk_sp<SkTypeface>> fontsMonoItalic;
static std::vector<sk_sp<SkTypeface>> fontsMonoBold;
static std::vector<sk_sp<SkTypeface>> fontsMonoBoldItalic;

static sk_sp<SkFontMgr> fontMgr;

void addFont(std::vector<sk_sp<SkTypeface>> *vec, std::string path) {
    vec->push_back(fontMgr->makeFromFile(path.c_str(), 0));
}

void addFont(std::vector<sk_sp<SkTypeface>> *vec, sk_sp<SkTypeface> face) {
    vec->push_back(face);
}

/**
 * Initialize all static resources. This is done here to avoid penalties on each render.
 */
int init(char *fontpath) {
    // If the env var is not defined, skip adding fonts
    if (!fontpath) {
        return 0;
    }

    fontMgr = SkFontMgr_New_Custom_Empty();

    std::string path(fontpath);

    const char s =
#ifdef _WIN32
            '\\';
#else
            '/';
#endif

    std::string notopath(path + s + "fonts" + s + "ivyfonts" + s + "Noto" + s);

    addFont(&fontsRegular,        notopath + "NotoSans-Regular.ttf");
    addFont(&fontsItalic,         notopath + "NotoSans-Italic.ttf");
    addFont(&fontsBold,           notopath + "NotoSans-Bold.ttf");
    addFont(&fontsBoldItalic,     notopath + "NotoSans-BoldItalic.ttf");
    addFont(&fontsMonoRegular,    notopath + "NotoMono-Regular.ttf");
    addFont(&fontsMonoItalic,     notopath + "NotoMono-Regular.ttf");
    addFont(&fontsMonoBold,       notopath + "NotoMono-Regular.ttf");
    addFont(&fontsMonoBoldItalic, notopath + "NotoMono-Regular.ttf");

    std::string cjk = path + s + "fonts" + s + "ivyfonts" + s +
        "NotoCJK" + s + "NotoSansCJK-Regular.otf";
    sk_sp<SkTypeface> cjkFace = fontMgr->makeFromFile(cjk.c_str(), 0);

    addFont(&fontsRegular,        cjkFace);
    addFont(&fontsItalic,         cjkFace);
    addFont(&fontsBold,           cjkFace);
    addFont(&fontsBoldItalic,     cjkFace);
    addFont(&fontsMonoRegular,    cjkFace);
    addFont(&fontsMonoItalic,     cjkFace);
    addFont(&fontsMonoBold,       cjkFace);
    addFont(&fontsMonoBoldItalic, cjkFace);

    return 0;
}

int QSkia::initialize(char *fontpath) {
    return init(fontpath);
}

QSkia::QSkia(unsigned int width, unsigned int height) {
    this->width  = width;
    this->height = height;

    this->fontFamily = FamilyRegular;
    this->fontStyle = StyleRegular;

    this->paint = new SkPaint();
    this->paint->setAntiAlias(true);

    this->bitmap = new SkBitmap();
    this->imageInfo = new SkImageInfo();
    this->bitmap->setInfo(imageInfo->MakeN32Premul(width, height), 0);
    // this->bitmap->setConfig(SkBitmap::kARGB_8888_Config, width, height);
    this->bitmap->allocPixels();
    this->bitmap->eraseARGB(0, 0, 0, 0);

    this->canvas = new SkCanvas(*this->bitmap);
}

QSkia::~QSkia() {
    delete imageInfo;
    delete paint;
    delete bitmap;
    delete canvas;
}


void QSkia::setBackgroundColour(uint32_t color) { }

void QSkia::setFillColour(uint32_t color) {
    this->paint->setStyle(SkPaint::kFill_Style);
    this->paint->setColor(color);
}

void QSkia::setStrokeColour(uint32_t color) {
    this->paint->setStyle(SkPaint::kStroke_Style);
    this->paint->setColor(color);
}

void QSkia::setStrokeWidth(float width) {
    this->paint->setStrokeWidth(width);
}

void QSkia::addCircle(float x, float y, float radius) {
    this->canvas->drawCircle(x, y, radius, *this->paint);
}

void QSkia::addRect(float x, float y, float width, float height) {
    this->canvas->drawRect(
            SkRect::MakeXYWH(x, y, width, height), *this->paint);
}

void QSkia::addLine(float x1, float y1, float x2, float y2) {
    this->canvas->drawLine(x1, y1, x2, y2, *this->paint);
}

void QSkia::addDashedLine(float x1, float y1, float x2, float y2, float on, float off) {
    SkPaint p(*this->paint);
    p.setPathEffect(SkDashPathEffect::Make({ on, off }, 0.0));
    this->canvas->drawLine(x1, y1, x2, y2, p);
}

void QSkia::rotate(float degrees, float x, float y) {
    this->canvas->save();
    this->canvas->translate(x, y);
    this->canvas->rotate(degrees);
}

void QSkia::restore() {
    this->canvas->restore();
}

void QSkia::setFontSize(int size) {
    this->fontSize = SkIntToScalar(size);
}

void QSkia::setFontFace(const char *fontfamily, char bold, char italic) {
    if (bold && italic) {
        this->fontStyle = StyleBoldItalic;
    } else if (bold) {
        this->fontStyle = StyleBold;
    } else if (italic) {
        this->fontStyle = StyleItalic;
    } else {
        this->fontStyle = StyleRegular;
    }

    if (0 == strcmp(fontfamily, "monospace")) {
        this->fontFamily = FamilyMonospace;
    } else {
        this->fontFamily = FamilyRegular;
    }
}

void QSkia::setupTextPaint() {
}

void QSkia::drawText(float x, const float y, const char* text) {
    std::vector<SkGlyphID> ids(strlen(text));
    // Glyph starting location in source text
    std::vector<unsigned int> positions(strlen(text));
    // Font used for glyph i
    std::vector<unsigned int> glyphFonts(strlen(text));
    // Resolved Glyph IDs (for priority)
    std::vector<SkGlyphID>    glyphIds(strlen(text));

    // Clear the vector of resolved glyphsglyph
    for (unsigned int i = 0; i < glyphIds.size(); ++i) { glyphIds[i] = 0; }

    unsigned int num = 0, charindex;
    bool valid;
    SkFont font;
    font.setSize(fontSize);

    // For each font, resolve the glyphs in the text
    for (unsigned int i = 0; i < fontsRegular.size(); ++i) {
        font.setTypeface(this->getFont(i));
        num = font.textToGlyphs(text, strlen(text),SkTextEncoding::kUTF8, ids);

        charindex = -1;

        // For each character in the text, if the character represets
        // the start of a glyph, incement and check whether the glyph
        // was resolved in the font, and whether the glyph has not yet
        // been resolved by a prior font
        for (unsigned int j = 0; j < strlen(text); ++j) {
            valid = isGlyph(text[j]);
            if (valid)  {
                // Mark the glyph position in the text
                charindex++;
                positions[charindex]  = j;

                // Add the glyph to the resolved list if necessary
                if (ids[charindex] != 0 && glyphIds[charindex] == 0) {
                    glyphFonts[charindex] = i;
                    glyphIds[charindex]   = ids[charindex];
                }
            }
        }
    }

    if (num == 0) {
        return;
    }

    // If not left-aligned, need to offset the text, so measure first, then offest
    if (this->fontAlign == AlignMiddle) {
        unsigned int width = traverseText(text, num, x, y, false, positions, glyphFonts, font);
        x -= width / 2;
    } else if (this->fontAlign == AlignRight) {
        unsigned int width = traverseText(text, num, x, y, false, positions, glyphFonts, font);
        x -= width;
    }

    // Set the alignment to left since we've done manual alignment and draw the text
    traverseText(text, num, x, y, true, positions, glyphFonts, font);
}

float QSkia::traverseText(
        const char *text,
        unsigned int num,
        float x,
        float y,
        unsigned char drawText,
        std::vector<unsigned int> positions,
        std::vector<unsigned int>glyphFonts,
        SkFont& font) {
    // Text is manually offset, so always use left-aligned drawing
    // this->paint->setTextEncoding(SkPaint::kUTF8_TextEncoding);
    char *buff = (char *) malloc(sizeof(char) * (1 + num) * 4);

    // Measure and optionally draw each run of glyphs from the same font
    for (unsigned int i = 0; i < num; ) {
        unsigned int j = i + 1;
        // Determine the end of the run and the number of characters in the run
        for (; j < num; ++j) if (glyphFonts[j] != glyphFonts[i]) { break; }
        int numchars = j-i;
        // Set the font for the run
        font.setTypeface(this->getFont(glyphFonts[i]));
        // Determine the text position of the start of the run
        int start = positions[i];
        int end;
        if (i + numchars < num) {  // mid text
            end = positions[i+numchars];
        } else {  // reached the end of the text/last run
            end = strlen(text);
        }
        // Store the run for measuring/printing
        memcpy(buff, text+start, end-start);
        buff[end-start] = '\0';
        if (drawText) {
            this->canvas->drawSimpleText(buff, strlen(buff), SkTextEncoding::kUTF8, x, y, font, *this->paint);
        }
        // Set the position for the start of the next run
        x += font.measureText(buff, strlen(buff), SkTextEncoding::kUTF8);
        // Advance to the start of the next run
        i += numchars;
    }

    free(buff);
    return x;
}

sk_sp<SkTypeface> QSkia::getFont(unsigned int index) {
    if (this->fontFamily == FamilyRegular) {
        if (this->fontStyle == StyleRegular) {
            return fontsRegular[index];
        } else if (this->fontStyle == StyleBold) {
            return fontsBold[index];
        } else if (this->fontStyle == StyleItalic) {
            return fontsItalic[index];
        } else if (this->fontStyle == StyleBoldItalic) {
            return fontsBoldItalic[index];
        }
    } else {
        if (this->fontStyle == StyleRegular) {
            return fontsMonoRegular[index];
        } else if (this->fontStyle == StyleBold) {
            return fontsMonoBold[index];
        } else if (this->fontStyle == StyleItalic) {
            return fontsMonoItalic[index];
        } else if (this->fontStyle == StyleBoldItalic) {
            return fontsMonoBoldItalic[index];
        }
    }
    return fontsRegular[index];
}

void QSkia::addTextWithAnchor(float x, float y, FontAlign align, const char* str) {
    this->setupTextPaint();
    this->fontAlign = align;
    drawText(x, y, str);
}

void QSkia::addTextMiddleAnchor(float x, float y, const char* str) {
    this->addTextWithAnchor(x, y, AlignMiddle, str);
}

void QSkia::addTextRightAnchor(float x, float y, const char* str) {
    this->addTextWithAnchor(x, y, AlignRight, str);
}

void QSkia::addTextLeftAnchor(float x, float y, const char* str) {
    this->addTextWithAnchor(x, y, AlignLeft, str);
}

void QSkia::addText(float x, float y, const char* str) {
    this->addTextLeftAnchor(x, y, str);
}

void QSkia::addPath(char close, unsigned int n, float * xxs, float * yys) {
    SkPath path;
    if (n == 0) {
        return;
    }

    path.moveTo(xxs[0], yys[0]);
    for (unsigned int i = 1; i < n; ++i) {
        path.lineTo(xxs[i], yys[i]);
    }

    if (close == 1) {
        path.close();
    }

    this->canvas->drawPath(path, *this->paint);
}

void QSkia::multiFillCircle(unsigned int n, float * xxs, float * yys, float * rs, uint32_t *ffs,
        bool * single) {
    for (unsigned int i = 0; i < n; ++i) {
        this->setFillColour(ffs[single[1] ? 0 : i]);
        this->canvas->drawCircle(
            xxs[i],
            yys[i],
            rs[single[0] ? 0 : i],
            *this->paint);
    }
}

void QSkia::multiStrokeCircle(unsigned int n, float * xxs, float * yys, float * rs,
        uint32_t *ffs, float * ws, bool * single) {
    unsigned int i;

    for (i = 0; i < n; ++i) {
        this->setStrokeColour(ffs[single[1] ? 0 : i]);
        this->setStrokeWidth(ws[single[2] ? 0 : i]);
        this->canvas->drawCircle(xxs[i], yys[i], rs[single[0] ? 0 : i], *this->paint);
    }
}

void QSkia::multiLine(unsigned int n, float * x1, float * y1, float * x2, float * y2,
        uint32_t * ffs, float * ws, bool * single) {
    unsigned int i;

    for (i = 0; i < n; ++i) {
        this->setFillColour(ffs[single[0] ? 0 : i]);
        this->setStrokeWidth(ws[single[1] ? 0 : i]);
        this->canvas->drawLine(x1[i], y1[i], x2[i], y2[i], *this->paint);
    }
}

void QSkia::multiFillRect(unsigned int n, float * xxs, float * yys, float * ws, float * hs,
        uint32_t *ffs, bool * single) {
    unsigned int i;

    for (i = 0; i < n; ++i) {
        this->setFillColour(ffs[single[2] ? 0 : i]);
        this->canvas->drawRect(SkRect::MakeXYWH(
            xxs[i],
            yys[i],
            ws[single[0] ? 0 : i],
            hs[single[1] ? 0 : i]),
            *this->paint);
    }
}

void QSkia::multiStrokeRect(unsigned int n, float * xxs, float * yys, float * ws,
        float * hs, uint32_t *ffs, float * sws, bool * single) {
    unsigned int i;

    for (i = 0; i < n; ++i) {
        this->setStrokeColour(ffs[single[2] ? 0 : i]);
        this->setStrokeWidth(sws[single[3] ? 0 : i]);
        this->canvas->drawRect(SkRect::MakeXYWH(
            xxs[i],
            yys[i],
            ws[single[0] ? 0 : i],
            hs[single[1] ? 0 : i]),
            *this->paint);
    }
}

void QSkia::multiFillPath(unsigned int n, unsigned char * close, K * xxs, K * yys, uint32_t *ffs,
        bool * single) {
    unsigned int i;
    for (i = 0; i < n; ++i) {
        this->setFillColour(ffs[single[1] ? 0 : i]);
        this->addPath(close[single[0] ? 0 : i], xxs[i]->n, kE(xxs[i]), kE(yys[i]));
    }
}

void QSkia::multiStrokePath(unsigned int n, unsigned char * close, K * xxs, K * yys, uint32_t *ffs,
        float * ws, bool * single) {
    unsigned int i;
    for (i = 0; i < n; ++i) {
        this->setStrokeColour(ffs[single[1] ? 0 : i]);
        this->setStrokeWidth(ws[single[2] ? 0 : i]);
        this->addPath(close[single[0] ? 0 : i], xxs[i]->n, kE(xxs[i]), kE(yys[i]));
    }
}

float QSkia::measureText(const char *str, const uint64_t len) {
    SkFont font;
    font.setTypeface(this->getFont(0));
    return font.measureText(str, len, SkTextEncoding::kUTF8);
}

void QSkia::addPixels(unsigned int width, unsigned int height, float px, float py,
        unsigned int * pixels) {
    SkPixmap pixmap(SkImageInfo::Make(width, height, kN32_SkColorType, kPremul_SkAlphaType),
                    pixels, sizeof(uint32_t) * width);
    sk_sp<SkImage> img = SkImages::RasterFromPixmapCopy(pixmap);
    this->canvas->drawImage(img, px, py);
}

