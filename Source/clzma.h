#ifndef __CLZMA_H__
#define __CLZMA_H__

#include "Platform.h"

#ifndef _WIN32
# include <pthread.h>
#endif

#include "compressor.h"
#include "7zip/7zip/IStream.h"
#include "7zip/7zip/Compress/LZMA/LZMAEncoder.h"
#include "7zip/Common/MyCom.h"
#include "7zip/Common/Defs.h"

#define LZMA_BAD_CALL -1
#define LZMA_INIT_ERROR -2
#define LZMA_THREAD_ERROR -3
#define LZMA_IO_ERROR -4
#define LZMA_MEM_ERROR -5

class CLZMA:
  public ICompressor,
  public ISequentialInStream,
  public ISequentialOutStream,
  public CMyUnknownImp
{
private:
  NCompress::NLZMA::CEncoder *_encoder;

#ifdef _WIN32
  HANDLE hCompressionThread;
#else
  pthread_t hCompressionThread;
#endif
  HANDLE hNeedIOEvent;
  HANDLE hIOReadyEvent;

  BYTE *next_in; /* next input byte */
  UINT avail_in; /* number of bytes available at next_in */

  BYTE *next_out; /* next output byte should be put there */
  UINT avail_out; /* remaining free space at next_out */

  int res;

  BOOL finish;
  BOOL compressor_finished;

  int ConvertError(HRESULT result);

  void GetMoreIO();
  int CompressReal();

#ifdef _WIN32
  static DWORD WINAPI lzmaCompressThread(LPVOID lpParameter);
#else
  static void* lzmaCompressThread(void *lpParameter);
#endif

public:
  MY_UNKNOWN_IMP

  CLZMA();
  virtual ~CLZMA();

  virtual int Init(int level);
  virtual int Init(int level, UINT32 dicSize);
  virtual int End();
  virtual int Compress(bool flush);

  STDMETHOD(Read)(void *data, UINT32 size, UINT32 *processedSize);
  STDMETHOD(ReadPart)(void *data, UINT32 size, UINT32 *processedSize);
  STDMETHOD(Write)(const void *data, UINT32 size, UINT32 *processedSize);
  STDMETHOD(WritePart)(const void *data, UINT32 size, UINT32 *processedSize);

  virtual void SetNextIn(char *in, unsigned int size);
  virtual void SetNextOut(char *out, unsigned int size);

  virtual char *GetNextOut();
  virtual unsigned int GetAvailIn();
  virtual unsigned int GetAvailOut();
  virtual const char *GetName();

  virtual const char* GetErrStr(int err);
};

#endif
