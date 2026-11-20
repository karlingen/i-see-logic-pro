// Tests for the parts of the theme that run outside Logic Pro. The theme hooks start only
// inside Logic Pro, so this program can include the theme source and call its functions.
#include "../theme/light-theme.m"

#define TOLERANCE 0.0001

static int failures = 0;

/**
 * Records a failed check and prints it.
 *
 * @param isPassed BOOL - the result of the check
 * @param label const char * - what the check tests
 */
static void check(BOOL isPassed, const char *label) {
   if (!isPassed) {
      failures++;
      printf("FAIL: %s\n", label);
   }
}

static BOOL isClose(double a, double b) {
   return fabs(a - b) < TOLERANCE;
}

static void testGrayRule(void) {
   check(isClose(mapGrayLevel(0, 1, 0.75), 1), "the darkest gray becomes white at Light");
   check(isClose(mapGrayLevel(1, 1, 0.75), 0), "white becomes black");
   check(isClose(mapGrayLevel(0, 0.68, 1), 0.68), "the darkest gray becomes surfaceMax");
   check(isClose(mapGrayLevel(0.5, 1, 1), 0.5), "gamma 1 is linear");
   check(mapGrayLevel(0.5, 1, 1.5) < mapGrayLevel(0.5, 1, 0.75), "a higher gamma makes middle grays darker");
   surfaceMax = 0.8;
   grayGamma = 1;
   check(isClose(mapGray(0.2, 1), 0.64), "mapGray uses surfaceMax and gamma");
   check(isClose(mapGray(0.05, 0.5), 0.05), "a transparent near-black shadow does not change");
}

static double contrastOn(double text, double surface) {
   return (toLinear(surface) + 0.05) / (toLinear(text) + 0.05);
}

static void testTextContrast(void) {
   double grayButton = mapGrayLevel(STOCK_TEXT_BACKGROUND, 0.68, 1);
   double lightButton = mapGrayLevel(STOCK_TEXT_BACKGROUND, 1, 0.75);

   check(contrastOn(mapTextLevel(0.7, 0.68, 1, TEXT_CONTRAST), grayButton) >= TEXT_CONTRAST - 0.01, "secondary text keeps its contrast at Gray");
   // At the darkest setting, even black cannot reach TEXT_CONTRAST on a button, so all text is black.
   check(isClose(mapTextLevel(FOREGROUND_MIN, SURFACE_MAX_MIN, GAMMA_MAX, TEXT_CONTRAST), 0), "all text is black at the darkest setting");
   check(contrastOn(mapTextLevel(0.7, 1, 0.75, TEXT_CONTRAST), lightButton) >= TEXT_CONTRAST - 0.01, "secondary text keeps its contrast at Light");
   check(isClose(mapGrayLevel(0.7, 0.68, 1), 0.68 * 0.3), "a light gray that is not text keeps the curve");
   check(mapTextAlpha(1, 0.35, 0.68, 1, TEXT_CONTRAST) > 0.8, "translucent text gets more opacity at Gray");
   check(isClose(mapTextAlpha(1, 0.7, 1, 0.75, TEXT_CONTRAST), 0.7), "translucent text with enough contrast does not change");
   check(isClose(mapTextAlpha(1, 0.1, 0.68, 1, TEXT_CONTRAST), 0.1), "a light overlay keeps its opacity");
   check(isClose(mapTextAlpha(0.2, 0.5, 0.68, 1, TEXT_CONTRAST), 0.5), "a translucent surface gray keeps its opacity");
}

static void testSettings(void) {
   const char *name = "LP_TEST_SETTING";
   NSString *key = @"testKeyThatIsNeverStored";

   setenv(name, "9", 1);
   check(isClose(readSetting(name, key, 1, GAMMA_MIN, GAMMA_MAX), GAMMA_MAX), "a high value is clamped");
   setenv(name, "0.1", 1);
   check(isClose(readSetting(name, key, 1, SURFACE_MAX_MIN, 1), SURFACE_MAX_MIN), "a low value is clamped");
   setenv(name, "0.8", 1);
   check(isClose(readSetting(name, key, 1, SURFACE_MAX_MIN, 1), 0.8), "the environment value is used");
   unsetenv(name);
   check(isClose(readSetting(name, key, 0.75, GAMMA_MIN, GAMMA_MAX), 0.75), "the fallback is used");
}

static void testTint(void) {
   parseTint("0.45,0.475,0.5");
   check(isTinted && isClose(tint[0], 0.9) && isClose(tint[2], 1), "a tint is scaled so the largest part is 1");
   parseTint("not a tint");
   check(isTinted && isClose(tint[0], 0.9), "a bad tint leaves the tint as it is");
   parseTint("0.5,0.5,0.5");
   check(!isTinted, "a gray tint is no tint");
}

static void testFieldColors(void) {
   NSColor *dark = [NSColor colorWithSRGBRed:0.2 green:0.2 blue:0.2 alpha:1];
   NSColor *light = [NSColor colorWithSRGBRed:0.9 green:0.9 blue:0.9 alpha:1];
   NSColor *red = [NSColor colorWithSRGBRed:0.8 green:0.1 blue:0.1 alpha:1];

   surfaceMax = 0.8;
   grayGamma = 1;
   check(isClose(mappedGrayColor(dark, FIELD_DARK_MAX).redComponent, 0.64), "a dark field gray is mapped");
   check(mappedGrayColor(light, FIELD_DARK_MAX) == light, "a light field gray, already mapped, does not change");
   check(mappedGrayColor(red, 1) == red, "a saturated color does not change");
}

static void testColorList(void) {
   NSMutableDictionary<NSString *, NSMutableSet *> *appearances = [NSMutableDictionary dictionary];
   NSString *json = @"[ { \"AssetStorageVersion\": \"x\" },"
      " { \"AssetType\": \"Color\", \"Name\": \"OneLook\" },"
      " { \"AssetType\": \"Color\", \"Name\": \"TwoLooks\" },"
      " { \"AssetType\": \"Color\", \"Name\": \"TwoLooks\", \"Appearance\": \"NSAppearanceNameDarkAqua\" },"
      " { \"AssetType\": \"Image\", \"Name\": \"Picture\" },"
      " { \"AssetType\": \"Color\" }, \"text\", 7 ]";

   addColorItems([json dataUsingEncoding:NSUTF8StringEncoding], appearances);
   check(appearances.count == 2, "only named colors are read");
   check(appearances[@"OneLook"].count == 1, "a color with one appearance");
   check(appearances[@"TwoLooks"].count == 2, "a color with two appearances");
   addColorItems([@"not json" dataUsingEncoding:NSUTF8StringEncoding], appearances);
   addColorItems(nil, appearances);
   check(appearances.count == 2, "bad output adds nothing");
}

static void testClassicRule(void) {
   check(isClose(mapClassicLevel(0), 0), "black stays black in the classic mode");
   check(isClose(mapClassicLevel(0.149), 0.341), "a track row gets the Logic Pro 12 gray");
   check(isClose(mapClassicLevel(0.7), 0.7), "text grays do not change in the classic mode");
   check(mapClassicLevel(0.1) > 0.1 && mapClassicLevel(0.1) < mapClassicLevel(0.2), "the classic curve lifts and keeps the order");
}

/**
 * Checks the contrast setting: a higher value must darken secondary text, never lighten it,
 * and must keep the requested contrast where the surfaces allow it.
 */
static void testContrastSetting(void) {
   double light = 1;
   double gamma = 0.75;

   check(mapTextLevel(0.7, light, gamma, 4.5) > mapTextLevel(0.7, light, gamma, 9),
      "a higher contrast darkens secondary text");
   check(mapTextLevel(0.7, light, gamma, 12) <= mapTextLevel(0.7, light, gamma, 4.5),
      "the darkest setting is never lighter");
   check(contrastOn(mapTextLevel(0.7, light, gamma, 9), mapGrayLevel(STOCK_TEXT_BACKGROUND, light, gamma)) >= 8.5,
      "the requested contrast is kept at Light");
   // Measured from the rule: the text limit of the Light preset is 0.340 at 4.5 and 0.053 at 12.
   check(isClose(textLimit(1, 0.75, 4.5), 0.340), "the text limit at 4.5 is 0.340");
   check(isClose(textLimit(1, 0.75, 12), 0.053), "the text limit at 12 is 0.053");
}

int main(void) {
   @autoreleasepool {
      testGrayRule();
      testTextContrast();
      testSettings();
      testTint();
      testFieldColors();
      testColorList();
      testClassicRule();
   }
   printf(failures ? "%d tests failed\n" : "All tests passed\n", failures);
   return failures ? 1 : 0;
}
