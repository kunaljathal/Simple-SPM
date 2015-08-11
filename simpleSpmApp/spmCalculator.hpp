#ifndef SPMCALCULATOR_H
#define SPMCALCULATOR_H


class spmCalculator
{
public:
    
    static int spmCalculate(double *xAccValues, double *yAccValues, double *zAccValues, unsigned int samplingRate, unsigned int windowSizeInSeconds);
    
    
    
private:
    static double singleAxisEstimate(double *accValues, const unsigned int windowSizeSamples, const unsigned int samplesPerMinute);
};

#endif
