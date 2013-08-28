// OvershootECDF
#import "OvershootECDF.ex4"

int OvershootECDF_CountUp(double &level[], int &count[], int elements, double overshootLevel);
void OvershootECDF_Write(string symbol, double threshold, double &level[], int &count[], int elements);
void OvershootECDF_Read(string symbol, double threshold, double &level[], int &count[]);
void OvershootECDF_MultiRead(string symbol, double thresholds[], int &index[], double &level[], int &count[]);
double OvershootECDF_Refer(double &level[], int &count[], double overshootLevel);
double OvershootECDF_MultiRefer(int thresholdIndex, int &index[], double &level[], int &count[], double overshootLevel);
double OvershootECDF_ReverseRefer(double &level[], int &count[], double p);
double OvershootECDF_MultiReverseRefer(int thresholdIndex, int &index[], double &level[], int &count[], double p);

