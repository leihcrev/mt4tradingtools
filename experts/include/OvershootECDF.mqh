// OvershootECDF
#import "OvershootECDF.ex4"

void OvershootECDF_CountUp(double &level[], int &count[], double overshootLevel);
void OvershootECDF_Write(string filename, double &level[], int &count[]);
void OvershootECDF_Read(string filename, double &level[], int &count[]);
void OvershootECDF_MultiRead(string symbol, double thresholds[], int &index[], double &level[], int &count[]);
double OvershootECDF_Refer(double &level[], int &count[], double overshootLevel);
double OvershootECDF_MultiRefer(int thresholdIndex, int &index[], double &level[], int &count[], double overshootLevel);
double OvershootECDF_ReverseRefer(double &level[], int &count[], double p);
double OvershootECDF_MultiReverseRefer(int thresholdIndex, int &index[], double &level[], int &count[], double p);

