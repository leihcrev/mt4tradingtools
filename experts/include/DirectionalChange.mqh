// DirectionalChange
#import "DirectionalChange.ex4"

/**
 * Update DC status.
 * Return true when DC occured.
 */
bool UpdateDCStatus(double currentPrice, double threshold,
    int &mode, double &extremaPrice, double &dcPrice, double &currentLevel, double &overshootLevel,
    int &prevMode, double &prevExtremaPrice, double &prevDcPrice, double &prevCurrentLevel, double &prevOvershootLevel);

