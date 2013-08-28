// OvershootECDF
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

int OvershootECDF_CountUp(double &level[], int &count[], int elements, double overshootLevel) {
  if (elements == 0) {
    level[0] = overshootLevel;
    count[0] = 1;
    return(1);
  }

  int i;
  if (overshootLevel < level[0]) {
    i = -1;
  }
  else {
    i = ArrayBsearch(level, overshootLevel, elements, 0);
    if (level[i] == overshootLevel) {
      count[i]++;
      return(elements);
    }
  }

  int size = ArraySize(count);
  if (size <= elements) {
    int newsize = size * 2;
    ArrayResize(level, newsize);
    ArrayResize(count, newsize);
  }
  if (i != elements - 1) {
    ArrayCopy(level, level, i + 2, i + 1, elements - i - 1);
    ArrayCopy(count, count, i + 2, i + 1, elements - i - 1);
  }

  level[i + 1] = overshootLevel;
  count[i + 1] = 1;
  return(elements + 1);
}

void OvershootECDF_Write(string symbol, double threshold, double &level[], int &count[], int elements) {
  int handle = FileOpen(StringConcatenate("OvershootECDF_", symbol, "_", DoubleToStr(threshold, 8), ".dat"), FILE_BIN | FILE_WRITE);
  if (handle < 1) {
    Print(GetLastError());
    return;
  }

  FileWriteInteger(handle, elements);
  int cumsum = 0;
  int i;
  for (i = 0; i < elements; i++) {
    cumsum += count[i];
    FileWriteDouble(handle, level[i]);
    FileWriteInteger(handle, cumsum);
  }

  FileClose(handle);

  handle = FileOpen(StringConcatenate("csv\\OvershootECDF_", symbol, "_", DoubleToStr(threshold, 8), ".csv"), FILE_CSV | FILE_WRITE, ",");
  if (handle < 1) {
    Print(GetLastError());
    return;
  }

  FileWrite(handle, elements);
  cumsum = 0;
  for (i = 0; i < elements; i++) {
    cumsum += count[i];
    FileWrite(handle, level[i], cumsum);
  }

  FileClose(handle);
}

void OvershootECDF_Read(string symbol, double threshold, double &level[], int &count[]) {
  int handle = FileOpen(StringConcatenate("OvershootECDF_", symbol, "_", DoubleToStr(threshold, 8), ".dat"), FILE_BIN | FILE_READ);
  if (handle < 1) {
    Print(GetLastError());
    return;
  }

  int size = FileReadInteger(handle);
  ArrayResize(level, size);
  ArrayResize(count, size);
  for (int i = 0; i < size; i++) {
    level[i] = FileReadDouble(handle);
    count[i] = FileReadInteger(handle);
  }

  FileClose(handle);
}

void OvershootECDF_MultiRead(string symbol, double thresholds[], int &index[], double &level[], int &count[]) {
  int n = ArraySize(thresholds);
  ArrayResize(index, n);
  int idx = 0;
  for (int i = 0; i < n; i++) {
    double l[0];
    int c[0];
    OvershootECDF_Read(symbol, thresholds[i], l, c);
    ArrayCopy(level, l, idx);
    ArrayCopy(count, c, idx);
    idx += ArraySize(c);
    index[i] = idx;
  }
}

double OvershootECDF_Refer(double &level[], int &count[], double overshootLevel) {
  int size = ArraySize(count);
  double total = count[size - 1];
  double x1, x2, y1, y2;
  if (overshootLevel < level[0]) {
    x1 = 0.0;
    y1 = 0.0;
    x2 = level[0];
    y2 = count[0] / total;
  }
  else {
    int i = ArrayBsearch(level, overshootLevel);
    if (i == size - 1) {
      return(1.0);
    }
    x1 = level[i];
    y1 = count[i] / total;
    if (x1 == overshootLevel) {
      return(y1);
    }
    x2 = level[i + 1];
    y2 = count[i + 1] / total;
  }
  return((overshootLevel - x1) / (x2 - x1) * (y2 - y1) + y1);
}

double OvershootECDF_MultiRefer(int thresholdIndex, int &index[], double &level[], int &count[], double overshootLevel) {
  int to = index[thresholdIndex];
  int from;
  if (thresholdIndex == 0) {
    from = 0;
  }
  else {
    from = index[thresholdIndex - 1];
  }
  double total = count[to - 1];
  double x1, x2, y1, y2;
  if (overshootLevel < level[from]) {
    x1 = 0.0;
    y1 = 0.0;
    x2 = level[from];
    y2 = count[from] / total;
  }
  else {
    int i = ArrayBsearch(level, overshootLevel, to - from, from);
    if (i >= to - 1) {
      return(1.0);
    }
    x1 = level[i];
    y1 = count[i] / total;
    if (x1 == overshootLevel) {
      return(y1);
    }
    x2 = level[i + 1];
    y2 = count[i + 1] / total;
  }
  return((overshootLevel - x1) / (x2 - x1) * (y2 - y1) + y1);
}

double OvershootECDF_ReverseRefer(double &level[], int &count[], double p) {
  int size = ArraySize(count);
  double total = count[size - 1];
  double c = total * p;
  double x1, x2, y1, y2;
  if (c < count[0]) {
    x1 = 0.0;
    y1 = 0.0;
    x2 = count[0];
    y2 = level[0];
  }
  else {
    int i = ArrayBsearch(count, c);
    if (i == size - 1) {
      return(level[size - 1]);
    }
    x1 = count[i];
    y1 = level[i];
    if (x1 == c) {
      return(y1);
    }
    x2 = count[i + 1];
    y2 = level[i + 1];
  }
  return((c - x1) / (x2 - x1) * (y2 - y1) + y1);
}

double OvershootECDF_MultiReverseRefer(int thresholdIndex, int &index[], double &level[], int &count[], double p) {
  int to = index[thresholdIndex];
  int from;
  if (thresholdIndex == 0) {
    from = 0;
  }
  else {
    from = index[thresholdIndex - 1];
  }
  double total = count[to - 1];
  double c = total * p;
  double x1, x2, y1, y2;
  if (c < count[from]) {
    x1 = 0.0;
    y1 = 0.0;
    x2 = count[from];
    y2 = level[from];
  }
  else {
    int i = ArrayBsearch(count, c, to - from, from);
    if (i >= to - 1) {
      return(level[to - 1]);
    }
    x1 = count[i];
    y1 = level[i];
    if (x1 == c) {
      return(y1);
    }
    x2 = count[i + 1];
    y2 = level[i + 1];
  }
  return((c - x1) / (x2 - x1) * (y2 - y1) + y1);
}

