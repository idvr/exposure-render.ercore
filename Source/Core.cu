
#include "Core.cuh"

texture<short, 3, cudaReadModeNormalizedFloat>	gTexDensity;
texture<short, 3, cudaReadModeNormalizedFloat>	gTexExtinction;

#include "Blur.cuh"
#include "ComputeEstimate.cuh"
#include "Utilities.cuh"
#include "SingleScattering.cuh"
#include "MultipleScattering.cuh"

void BindDensityVolume(short* pDensityBuffer, cudaExtent Size)
{
	cudaArray* gpDensity = NULL;

	// create 3D array
	cudaChannelFormatDesc ChannelDesc = cudaCreateChannelDesc<short>();
	cudaMalloc3DArray(&gpDensity, &ChannelDesc, Size);

	// copy data to 3D array
	cudaMemcpy3DParms copyParams	= {0};
	copyParams.srcPtr				= make_cudaPitchedPtr(pDensityBuffer, Size.width * sizeof(short), Size.width, Size.height);
	copyParams.dstArray				= gpDensity;
	copyParams.extent				= Size;
	copyParams.kind					= cudaMemcpyHostToDevice;
	cudaMemcpy3D(&copyParams);

	// Set texture parameters
	gTexDensity.normalized		= true;
	gTexDensity.filterMode		= cudaFilterModeLinear;      
	gTexDensity.addressMode[0]	= cudaAddressModeClamp;  
	gTexDensity.addressMode[1]	= cudaAddressModeClamp;
 	gTexDensity.addressMode[2]	= cudaAddressModeClamp;

	// Bind array to 3D texture
	cudaBindTextureToArray(gTexDensity, gpDensity, ChannelDesc);
}

void BindExtinctionVolume(short* pExtinctionBuffer, cudaExtent Size)
{
	cudaArray* gpExtinction = NULL;

	// create 3D array
	cudaChannelFormatDesc ChannelDesc = cudaCreateChannelDesc<short>();
	cudaMalloc3DArray(&gpExtinction, &ChannelDesc, Size);

	// copy data to 3D array
	cudaMemcpy3DParms copyParams	= {0};
	copyParams.srcPtr				= make_cudaPitchedPtr(pExtinctionBuffer, Size.width * sizeof(short), Size.width, Size.height);
	copyParams.dstArray				= gpExtinction;
	copyParams.extent				= Size;
	copyParams.kind					= cudaMemcpyHostToDevice;
	cudaMemcpy3D(&copyParams);

	// Set texture parameters
	gTexExtinction.normalized		= true;
	gTexExtinction.filterMode		= cudaFilterModePoint;      
	gTexExtinction.addressMode[0]	= cudaAddressModeClamp;  
	gTexExtinction.addressMode[1]	= cudaAddressModeClamp;
// 	gTexExtinction.addressMode[2]	= cudaAddressModeClamp;

	// Bind array to 3D texture
	cudaBindTextureToArray(gTexExtinction, gpExtinction, ChannelDesc);
}

void Render(const int& Type, CScene* pScene, CScene* pDevScene, unsigned int* pSeeds, CColorXyz* pDevEstFrameXyz, CColorXyz* pDevEstFrameBlurXyz, CColorXyz* pDevAccEstXyz, unsigned char* pDevEstRgbLdr, int N)
{
	switch (Type)
	{
		case 0:
		{
			SingleScattering(pScene, pDevScene, pSeeds, pDevEstFrameXyz);
			BlurImageXyz(pDevEstFrameXyz, pDevEstFrameBlurXyz, CResolution2D(pScene->m_Camera.m_Film.m_Resolution.GetResX(), pScene->m_Camera.m_Film.m_Resolution.GetResY()), 1.3f);
  			ComputeEstimate(pScene->m_Camera.m_Film.m_Resolution.GetResX(), pScene->m_Camera.m_Film.m_Resolution.GetResY(), pDevEstFrameXyz, pDevAccEstXyz, N, 500.0f, pDevEstRgbLdr);
			
			break;
		}

		case 1:
		{
			break;
		}
	}
}