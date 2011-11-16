#pragma once
#include "cv.h"
#include "highgui.h"
//#include "EigenFaceDetector.h"
#define EIGEN_IMG_DIM 40

using namespace std;


typedef pair<IplImage *, int> DlImageToSecondPair;


struct DlFaceAndTime
{
	int id;
	string pathToSave;
	IplImage *face;
	IplImage *StandardizedFaces[20];
	float *eigenVecs[20];
	int numOfFacesFound;
	CvRect location;
	std::vector<pair<int, int>> timeSegments;
	int lastTimeStamp;
	bool lastSegmentClosed;


	void addStartSegment(int time)
	{
		timeSegments.push_back(pair<int, int>(time, time));
		lastSegmentClosed = false;
	}

	void addEndTime(int time)
	{
		timeSegments[timeSegments.size() - 1].second = time;
	}
};

typedef vector<DlFaceAndTime> DlFacesVec;

class MovieFaceExtractor
{
public:
	MovieFaceExtractor(void);
	~MovieFaceExtractor(void);
	static void init();
	static void detectFace( IplImage* img, CvSeq** outSec, bool scaleDown = 1);
	static void saveFacesToDisk(CvCapture* movieClip, char *outputPath, int minPixels, int timeDelta, bool scaleDown);
	static void saveFacesToDiskByFrames(CvCapture* movieClip, char *outputPath, int minPixels, int framesDelta, bool scaleDown);

	static DlFacesVec saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
		char *outputPath, int minPixels, int timeDelta, bool scaleDown);
	//eigen
	static void fillFaceImgArr();
	static void doTheEigenFaces();
	static int findNearestNeighbor(float *testVec, double threshold);
	static int findTotalNumOfFaces();
	static void setEigenVecsToDlFaces();
	static int recognizeAndAddFace(IplImage *inputImg);
private:
	
	// Create memory for calculations
	static CvMemStorage* s_storage;
	//faces for computation
	static vector<IplImage *> s_faces;
	// avg eigen face
	static IplImage *s_AvgFace;
	static bool m_isInitialized;
	// Haar classifier for face detection
	static CvHaarClassifierCascade* s_cascade;
	static DlFacesVec s_dlFaces;
	static int curNumTrainFaces;

};

