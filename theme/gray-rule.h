// The gray rule of the theme and its limits. theme/light-theme.m and the launcher app both
// include this file, so that the preview in the app always matches the theme.
#include <math.h>

// Black text at 0.18 keeps a contrast of about 5.6:1 on this gray.
#define SURFACE_MAX_MIN 0.65
#define GAMMA_MIN 0.5
#define GAMMA_MAX 1.5
// The selected row in a list is this fraction of the lightest gray.
#define SELECTED_ROW_WHITE 0.95
// Stock grays from this level up are text, glyphs and some control bodies, such as knobs.
#define FOREGROUND_MIN 0.55
// The stock gray of buttons, the darkest surface that often holds text.
#define STOCK_TEXT_BACKGROUND 0.26
// The default contrast that text keeps on that surface. The launcher can set a higher one.
#define TEXT_CONTRAST 4.5
/* The contrast that secondary text keeps. Higher values darken the text, so the interface
   looks less washed out; 4.5 is the minimum the rule was built on. (20.11.2026) */
#define TEXT_CONTRAST_MIN 4.5
#define TEXT_CONTRAST_MAX 12.0
// Translucent text grays at or above this opacity get more opacity when they need it. Lighter
// overlays, such as hover fills, keep their opacity.
#define TEXT_ALPHA_MIN 0.3
// The preferences domain of the launcher app, which is also its bundle identifier.
#define SETTINGS_DOMAIN_NAME "io.github.karlingen.i-see-logic-pro"

static inline double toLinear(double level) {
   return level <= 0.04045 ? level / 12.92 : pow((level + 0.055) / 1.055, 2.4);
}

static inline double toSRGB(double linear) {
   return linear <= 0.0031308 ? linear * 12.92 : 1.055 * pow(linear, 1 / 2.4) - 0.055;
}

/**
 * Returns the themed gray of a button, the darkest surface that often holds text.
 *
 * @param surfaceMax double - the lightest themed gray
 * @param gamma double - the curve between the two ends
 * @return double - the themed gray level of STOCK_TEXT_BACKGROUND
 */
static inline double textBackground(double surfaceMax, double gamma) {
   return surfaceMax * pow(1 - STOCK_TEXT_BACKGROUND, gamma);
}

/**
 * Returns the lightest text gray that keeps the given contrast on a themed button.
 *
 * @param surfaceMax double - the lightest themed gray
 * @param gamma double - the curve between the two ends
 * @param contrast double - the contrast ratio, from TEXT_CONTRAST_MIN to TEXT_CONTRAST_MAX
 * @return double - the gray level, 0 if no gray keeps the contrast
 */
static inline double textLimit(double surfaceMax, double gamma, double contrast) {
   return toSRGB(fmax(0, (toLinear(textBackground(surfaceMax, gamma)) + 0.05) / contrast - 0.05));
}

/**
 * Maps a stock gray level to the themed gray level. The darkest stock gray becomes surfaceMax,
 * and white becomes black.
 *
 * @param white double - the stock gray level from 0 to 1
 * @param surfaceMax double - the lightest themed gray
 * @param gamma double - the curve between the two ends
 * @return double - the themed gray level
 */
static inline double mapGrayLevel(double white, double surfaceMax, double gamma) {
   return surfaceMax * pow(1 - white, gamma);
}

/**
 * Maps the gray level of a color that is only for text. At the darker settings, the curve puts
 * secondary text close to the surfaces, so the level is at most textLimit.
 *
 * @param white double - the stock gray level from 0 to 1
 * @param surfaceMax double - the lightest themed gray
 * @param gamma double - the curve between the two ends
 * @param contrast double - the contrast that secondary text keeps
 * @return double - the themed gray level
 */
static inline double mapTextLevel(double white, double surfaceMax, double gamma, double contrast) {
   return fmin(mapGrayLevel(white, surfaceMax, gamma), textLimit(surfaceMax, gamma, contrast));
}

/**
 * Returns the opacity of a translucent text gray. The surface shows through translucent text,
 * so the opacity rises until the text on a themed button reaches the contrast, or 1.
 *
 * @param white double - the stock gray level from 0 to 1
 * @param alpha double - the stock opacity from 0 to 1
 * @param surfaceMax double - the lightest themed gray
 * @param gamma double - the curve between the two ends
 * @param contrast double - the contrast that secondary text keeps
 * @return double - the new opacity
 */
static inline double mapTextAlpha(double white, double alpha, double surfaceMax, double gamma,
                                  double contrast) {
   double back = textBackground(surfaceMax, gamma);
   double text = mapTextLevel(white, surfaceMax, gamma, contrast);

   if (white < FOREGROUND_MIN || alpha < TEXT_ALPHA_MIN || alpha >= 1 || back <= text) {
      return alpha;
   }
   return fmin(1, fmax(alpha, (back - textLimit(surfaceMax, gamma, contrast)) / (back - text)));
}

// The classic mode lifts the opaque Logic Pro 13 grays to the Logic Pro 12 grays. Each pair is a
// Logic Pro 13 level and the Logic Pro 12 level of the same surface, for example the Tracks area,
// the track rows and the selected row. Black stays black, and text grays do not change.
#define CLASSIC_POINT_COUNT 5
static const double CLASSIC_POINTS[CLASSIC_POINT_COUNT][2] = {
   { 0.04, 0.04 }, { 0.078, 0.18 }, { 0.149, 0.341 }, { 0.251, 0.45 }, { FOREGROUND_MIN, FOREGROUND_MIN },
};

/**
 * Maps a stock gray level to the classic gray level, by linear steps between CLASSIC_POINTS.
 *
 * @param white double - the stock gray level from 0 to 1
 * @return double - the classic gray level
 */
static inline double mapClassicLevel(double white) {
   for (int i = 1; i < CLASSIC_POINT_COUNT; i++) {
      const double *low = CLASSIC_POINTS[i - 1], *high = CLASSIC_POINTS[i];

      if (white >= low[0] && white <= high[0]) {
         return low[1] + (white - low[0]) * (high[1] - low[1]) / (high[0] - low[0]);
      }
   }
   return white;
}
