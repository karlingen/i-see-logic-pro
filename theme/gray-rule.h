// The gray rule of the theme and its limits. theme/light-theme.m and the launcher app both
// include this file, so that the preview in the app always matches the theme.
#include <math.h>

// Black text at 0.18 keeps a contrast of about 5.6:1 on this gray.
#define SURFACE_MAX_MIN 0.65
#define GAMMA_MIN 0.5
#define GAMMA_MAX 1.5
// The selected row in a list is this fraction of the lightest gray.
#define SELECTED_ROW_WHITE 0.95
// The preferences domain of the launcher app, which is also its bundle identifier.
#define SETTINGS_DOMAIN_NAME "io.github.karlingen.i-see-logic-pro"

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
