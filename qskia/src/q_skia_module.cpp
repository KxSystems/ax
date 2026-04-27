#include "k.h"

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

extern "C" 
{

K k_skia_init(K k_fontpath);
K k_skia_new(K k_width, K k_height);
K k_skia_delete(K k_skia);

K k_skia_add_circle(K k_skia, K k_x, K k_y, K k_radius);
K k_skia_add_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2);
K k_skia_add_dashed_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2, K k_on, K k_off);
K k_skia_add_path(K k_skia, K k_close, K k_xs, K k_ys);
K k_skia_add_rect(K k_skia, K k_x, K k_y, K k_width, K k_height);

K k_skia_multi_fill_circle(K k_skia, K k_xs, K k_ys, K k_rs, K k_ffs);
K k_skia_multi_stroke_circle(K k_skia, K k_xs, K k_ys, K k_rs, K k_cs, K k_ws);

K k_skia_set_fontface(K k_skia, K k_fontfamily, K k_bold, K k_italic);
K k_skia_add_text(K k_skia, K k_x, K k_y, K k_str);
K k_skia_add_text_middle_anchor(K k_skia, K k_x, K k_y, K k_str);
K k_skia_add_text_left_anchor(K k_skia, K k_x, K k_y, K k_str);
K k_skia_add_text_right_anchor(K k_skia, K k_x, K k_y, K k_str);

K k_skia_set_background_colour(K k_skia, K k_argb);
K k_skia_set_fill_colour(K k_skia, K k_argb);
K k_skia_set_stroke_colour(K k_skia, K k_argb);
K k_skia_set_stroke_width(K k_skia, K k_width);
K k_skia_render_to_memory(K k_skia);
K k_skia_render_to_rgb(K k_skia);

K k_skia_set_font_size(K k_skia, K k_font_size);
K k_skia_measure_text(K k_skia, K k_str);

K k_skia_rotate_canvas(K k_skia, K k_degrees, K k_x, K k_y);
K k_skia_restore_canvas(K k_skia);

K k_skia_multi_fill_rect(K k_skia, K k_xs, K k_ys, K k_ws, K k_hs, K k_ffs);
K k_skia_multi_stroke_rect(K k_skia, K k_xs, K k_ys, K k_ws, K k_hs, K k_ffs, K k_sws);
K k_skia_multi_line(K k_skia, K k_x1, K k_y1, K k_x2, K k_y2, K k_ffs, K k_ws);
K k_skia_multi_fill_path(K k_skia, K k_close, K k_xs, K k_ys, K k_fs);
K k_skia_multi_stroke_path(K k_skia, K k_close, K k_xs, K k_ys, K k_fs, K k_ws);
K k_skia_add_pixels(K k_skia, K k_width, K k_height, K k_px, K k_py, K k_pixels);

EXPORT K1(kexport) {
    K sv=ktn(KS,0),fv=ktn(0,0);
    #define _(s,f,a) js(&sv,ss((S)#s));jk(&fv,dl((V*)k_skia_##f,a));
    
    _(init,init,1)_(new,new,2)_(delete,delete,1)
    _(addCircle,add_circle,4)_(addLine,add_line,5)_(addDashedLine,add_dashed_line,7)
    _(addPath,add_path,4)_(addRect,add_rect,5)
    _(multiFillCircle,multi_fill_circle,5)_(multiStrokeCircle,multi_stroke_circle,6)
    _(setFontFace,set_fontface,4)
    
    _(addText,add_text,4)_(addTextMiddleAnchor,add_text_middle_anchor,4)
    _(addTextLeftAnchor,add_text_left_anchor,4)_(addTextRightAnchor,add_text_right_anchor,4)
    _(setFillColour,set_fill_colour,2)_(setStrokeColour,set_stroke_colour,2)_(setStrokeWidth,set_stroke_width,2)

    _(setBackgroundColour,set_background_colour,2)_(toPNG,render_to_memory,1)_(toRGB,render_to_rgb,1)
    _(setFontSize,set_font_size,2)_(textWidth,measure_text,2)
    _(rotate,rotate_canvas,4)_(restore,restore_canvas,1)

    _(multiFillRect,multi_fill_rect,6)_(multiStrokeRect,multi_stroke_rect,7)
    _(multiLine,multi_line,7)_(multiFillPath,multi_fill_path,5)_(multiStrokePath,multi_stroke_path,6)

    _(addPixels,add_pixels,6)

    R xD(sv, fv);
}
}
