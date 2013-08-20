// OvershootECDF
#property copyright "Copyright 2013 KIKUCHI Shunsuke"
#property library

void OvershootECDF_CountUp(double &level[], int &count[], double overshootLevel) {
  int size = ArraySize(count);
  if (size == 0) {
    ArrayResize(level, 1);
    ArrayResize(count, 1);
    level[0] = overshootLevel;
    count[0] = 1;
    return;
  }

  int i;
  if (overshootLevel < level[0]) {
    i = -1;
  }
  else {
    i = ArrayBsearch(level, overshootLevel);
    if (level[i] == overshootLevel) {
      count[i]++;
      return;
    }
  }

  if (i == size - 1) {
    ArrayResize(level, size + 1);
    ArrayResize(count, size + 1);
  }
  else {
    ArrayCopy(level, level, i + 2, i + 1);
    ArrayCopy(count, count, i + 2, i + 1);
  }
  level[i + 1] = overshootLevel;
  count[i + 1] = 1;
}

void OvershootECDF_Write(string filename, double &level[], int &count[]) {
  int handle = FileOpen(filename + ".dat", FILE_BIN | FILE_WRITE);
  if (handle < 1) {
    Print(GetLastError());
    return;
  }

  int size = ArraySize(count);
  FileWriteInteger(handle, size);
  int cumsum = 0;
  int i;
  for (i = 0; i < size; i++) {
    cumsum += count[i];
    FileWriteDouble(handle, level[i]);
    FileWriteInteger(handle, cumsum);
  }

  FileClose(handle);

  handle = FileOpen(filename + ".csv", FILE_CSV | FILE_WRITE, ",");
  if (handle < 1) {
    Print(GetLastError());
    return;
  }

  FileWrite(handle, size);
  cumsum = 0;
  for (i = 0; i < size; i++) {
    cumsum += count[i];
    FileWrite(handle, level[i], cumsum);
  }

  FileClose(handle);
}

void OvershootECDF_Read(string filename, double &level[], int &count[]) {
  int handle = FileOpen(filename + ".dat", FILE_BIN | FILE_READ);
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

