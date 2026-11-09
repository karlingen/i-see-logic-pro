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

int main(void) {
   @autoreleasepool {
      testGrayRule();
      testSettings();
      testFieldColors();
      testColorList();
   }
   printf(failures ? "%d tests failed\n" : "All tests passed\n", failures);
   return failures ? 1 : 0;
}
