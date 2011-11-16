#include "MovieFaceExtractor.h"

#include <math.h>
#include <string>

#define SKIN_PIX_THRESH_PERCENT 70
#define TIME_DIFF_THRESHOLD 10
#define X_POS_THRESHOLD 50
#define Y_POS_THRESHOLD 50
/* Macros to get the max/min of 3 values */
#define MAX3(r,g,b) ((r)>(g)?((r)>(b)?(r):(b)):((g)>(b)?(g):(b)))
#define MIN3(r,g,b) ((r)<(g)?((r)<(b)?(r):(b)):((g)<(b)?(g):(b)))

using namespace std;

CvMemStorage* MovieFaceExtractor::s_storage;
bool MovieFaceExtractor::m_isInitialized;
CvHaarClassifierCascade* MovieFaceExtractor::s_cascade;



MovieFaceExtractor::MovieFaceExtractor(void)
{
}


MovieFaceExtractor::~MovieFaceExtractor(void)
{
}

void MovieFaceExtractor::init()
{
	s_storage = cvCreateMemStorage(0);
	s_cascade = (CvHaarClassifierCascade*)cvLoad( "C:\\OpenCV2.2\\data\\haarcascades\\haarcascade_frontalface_alt_tree.xml", 0, 0, 0 );
}

void MovieFaceExtractor::saveFacesToDisk(CvCapture* movieClip, char *outputPath, int minPixels, int timeDelta, bool scaleDown)
{
	int scale = scaleDown ? 2 : 1;
	char imgOutputPath[256];
	int count = 0;
	while (1)
	{
		cvClearMemStorage(s_storage);
		IplImage *img = cvQueryFrame(movieClip);
		if (img == NULL) return;
		CvSeq *faces;
		detectFace(img, &faces, scaleDown);
		for( int i = 0; i < (faces ? faces->total : 0); i++ )
		{
			CvRect* faceRect = (CvRect*)cvGetSeqElem( faces, i );
			if ((faceRect->height < 1) || (faceRect->width < 1)) continue; 
			CvRect roi = cvRect(faceRect->x *scale, faceRect->y * scale, faceRect->width * scale, faceRect->height);
			IplImage* imgToSave = cvCreateImage(cvSize(roi.width, roi.height), img->depth, img->nChannels);
			cvSetImageROI(img, roi);
			cvCopy(img, imgToSave);
			cvResetImageROI(img);
			sprintf(imgOutputPath, "%s\\face_%d_%d.tif", outputPath, count++, i);
			cvSaveImage(imgOutputPath, imgToSave);			
			cvReleaseImage(&imgToSave);
			int fnum = cvGetCaptureProperty(movieClip, CV_CAP_PROP_POS_FRAMES);
			printf("found face at frame %d\t pos: %d %d\t size %d X %d\n", fnum, faceRect->x, faceRect->y, faceRect->width, faceRect->height);
		}
		if((cvWaitKey(timeDelta) & 255) == 27) break;
	}
}

void MovieFaceExtractor::saveFacesToDiskByFrames(CvCapture* movieClip, char *outputPath, int minPixels, int framesDelta, bool scaleDown)
{
	int scale = scaleDown ? 2 : 1;
	char imgOutputPath[256];
	int count = 0;
	int fps = cvGetCaptureProperty(movieClip, CV_CAP_PROP_FPS);
	int nof = cvGetCaptureProperty(movieClip, CV_CAP_PROP_FRAME_COUNT);
	for ( int j = 0 ; (j < nof) ; j += framesDelta )
	{

		cvSetCaptureProperty(movieClip, CV_CAP_PROP_POS_FRAMES, j);
		cvClearMemStorage(s_storage);
		IplImage *img = cvQueryFrame(movieClip);
		if (img == NULL) return;
		CvSeq *faces;
		detectFace(img, &faces, scaleDown);
		for( int i = 0; i < (faces ? faces->total : 0); i++ )
		{
			CvRect* faceRect = (CvRect*)cvGetSeqElem( faces, i );
			printf("found face at frame %d\t pos: %d %d\t size %d X %d\n", faceRect->x, faceRect->y, faceRect->width, faceRect->height);
			if ((faceRect->height < 1) || (faceRect->width < 1)) continue; 
			CvRect roi = cvRect(faceRect->x *scale, faceRect->y * scale, faceRect->width * scale, faceRect->height);
			IplImage* imgToSave = cvCreateImage(cvSize(roi.width, roi.height), img->depth, img->nChannels);
			cvSetImageROI(img, roi);
			cvCopy(img, imgToSave);
			cvResetImageROI(img);
			sprintf(imgOutputPath, "%s\\face_%d_%d.tif", outputPath, count++, i);
			cvSaveImage(imgOutputPath, imgToSave);			
			cvReleaseImage(&imgToSave);
		}
	}
}

void MovieFaceExtractor::detectFace( IplImage* img, CvSeq** outSec, bool scaleDown)
{
	static int i = 0;
	
	int scale = scaleDown ? 2 : 1;
	IplImage* small_image = img;
	if( scaleDown )
    {
        small_image = cvCreateImage( cvSize(img->width / 2, img->height / 2), IPL_DEPTH_8U, 3 );
        cvPyrDown( img, small_image, CV_GAUSSIAN_5x5 );
        scale = 2;
    }
	//char stam[256];
	//sprintf(stam, "C:\\TestOutputs\\img_%d.tif", i++);
	//cvSaveImage(stam, small_image);
    // Create a new image based on the input image
    IplImage* temp = cvCreateImage( cvSize(small_image->width/scale,small_image->height/scale), 8, 3 );

    // Create two points to represent the face locations
    CvPoint pt1, pt2;

    // Clear the memory storage which was used before
    cvClearMemStorage( s_storage );

    // Find whether the cascade is loaded, to find the faces. If yes, then:
    if( s_cascade )
    {

        // There can be more than one face in an image. So create a growable sequence of faces.
        // Detect the objects and store them in the sequence
        *outSec = cvHaarDetectObjects( small_image, s_cascade, s_storage,
                                            1.2, 2, CV_HAAR_DO_CANNY_PRUNING,
                                            cvSize(40, 40) );
    }

	if( scaleDown )
    {
		// Release the temp image created.
		cvReleaseImage( &small_image );
	}
}

//#ifndef region_Eigenfaces
/////////////////////////////////////////////Eigenfaces////////////////////////////////////////////
//int MovieFaceExtractor::findNearestNeighbor(float *testVec, double threshold)
//{
//	int resVal = -1;
//	double minVal = DBL_MAX;
//	for (int i = 0 ; i < s_dlFaces.size() ; ++i)
//	{
//		for (int j = 0 ; j < s_dlFaces[i].numOfFacesFound ; ++j)
//		{
//			for (int k = 0 ; k < nEigens ; ++k)
//			{
//				double val = testVec[k] - s_dlFaces[i].eigenVecs[j][k];
//				double valSq = val * val;
//				if (valSq < minVal && valSq < threshold)
//				{
//					minVal = val;
//					resVal = i;
//				}
//			}
//		}
//	}
//	return resVal;
//}
//
//void MovieFaceExtractor::setEigenVecsToDlFaces()
//{
//	int offset = projectedTrainFaceMat->step / sizeof(float);
//	int index = 0;
//	for (int i = 0 ; i < s_dlFaces.size() ; ++i)
//	{
//		for (int j = 0 ; j < s_dlFaces[i].numOfFacesFound ; ++j)
//		{
//			
//			for (int k = 0 ; k < nEigens ; ++k)
//			{
//				s_dlFaces[i].eigenVecs[j][k] = (projectedTrainFaceMat->data.fl + index * offset)[k];
//			}
//			index++;
//		}
//	}
//}
//
//void MovieFaceExtractor::fillFaceImgArr()
//{
//	int totNumOfFaces = findTotalNumOfFaces();
//	faceImgArr = (IplImage **)cvAlloc(totNumOfFaces * sizeof(IplImage *));
//	int index = 0;
//	for (int i = 0 ; i < s_dlFaces.size() ; ++i)
//	{
//		for (int j = 0 ; j < s_dlFaces[i].numOfFacesFound ; ++j)
//		{
//			faceImgArr[index++] = s_dlFaces[i].StandardizedFaces[j];
//		}
//	}
//}
//
//int MovieFaceExtractor::findTotalNumOfFaces()
//{
//	int resval = 0;
//	for (int i = 0 ; i < s_dlFaces.size() ; ++i)
//	{
//		resval += s_dlFaces[i].numOfFacesFound; 
//	}
//	return resval;
//}
//
//void MovieFaceExtractor::doTheEigenFaces()
//{
//	fillFaceImgArr();
//	learn();
//	setEigenVecsToDlFaces();
//}
//
//int MovieFaceExtractor::recognizeAndAddFace(IplImage *inputImg)
//{
//	float *projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );
//	// project the test image onto the PCA subspace
//	cvEigenDecomposite(
//		inputImg,
//		nEigens,
//		eigenVectArr,
//		0, 0,
//		pAvgTrainImg,
//		projectedTestFace);
//	int nearest = findNearestNeighbor(projectedTestFace, 1);
//	if (nearest == -1) return -1;
//	if (s_dlFaces[nearest].numOfFacesFound < 20)
//	{
//		s_dlFaces[nearest].StandardizedFaces[s_dlFaces[nearest].numOfFacesFound++] = inputImg;
//		s_dlFaces[nearest].eigenVecs[s_dlFaces[nearest].numOfFacesFound] = projectedTestFace; 
//	}
//	return nearest;
//}
///////////////////////////////////////////////////////////////////////////////////////////////////
//#endif

void standardizeImage1(IplImage *inputImg, IplImage **outputImg,  int width, int height)
{
	*outputImg = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
	IplImage *tmpGrayImage = cvCreateImage(cvGetSize(inputImg), IPL_DEPTH_8U, 1);
	cvCvtColor(inputImg, tmpGrayImage, CV_BGR2GRAY );
	cvResize(tmpGrayImage, *outputImg, CV_INTER_LINEAR);
	cvEqualizeHist(*outputImg, *outputImg);
}

bool isSameFace1 (IplImage *img, DlFaceAndTime face, int timeCount, CvRect *location)
{
	if ( abs(timeCount - face.lastTimeStamp < TIME_DIFF_THRESHOLD)
		&& abs(face.location.x - location->x) < X_POS_THRESHOLD
		&& abs(face.location.y - location->y) < Y_POS_THRESHOLD )
		return true;
	//add more face comparison logic here
	IplImage *workImg;
	//standardizeImage(img, &workImg, face.face->width, face.face->height);
	static int count = 0;
	char stam[256];
	sprintf(stam, "C:\\TestOutputs\\standard_%d.tif", count++);
	cvSaveImage(stam, workImg); 
	cvReleaseImage(&workImg);
	return false;
}



int skinColorPixelsCounter1(IplImage *img, int skinPixelsThreshold)
{
	int skinColorPixelsCounter = 0;
	int maxCOunter = img->width * img->height * skinPixelsThreshold / 100;
	IplImage *outputImg = cvCloneImage(img);
	uchar *aPixelIn, *aPixelOut;
	aPixelIn = (uchar *)img->imageData;
	aPixelOut = (uchar *)outputImg->imageData;
	
    for ( int iRow = 0; iRow < img->height; iRow++ ) 
	{
        for ( int iCol = 0; iCol < img->width; iCol++ ) 
		{
            int R, B, G, F, I, X, H, S, V;

            /* Get RGB values -- OpenCV stores RGB images in BGR order!! */
            B = aPixelIn[ iRow * img->widthStep + iCol * 3 + 0 ];
            G = aPixelIn[ iRow * img->widthStep + iCol * 3 + 1 ];
            R = aPixelIn[ iRow * img->widthStep + iCol * 3 + 2 ];

            /* Convert RGB to HSV */
            X = MIN3( R, G, B );
            V = MAX3( R, G, B );
            if ( V == X ) 
			{
                H = 0; S = 0;
            } 
			else 
			{
                S = (float)(V-X)/(float)V * 255.0;
                F = ( R==V ) ? (G-B) : (( G==V ) ? ( B-R ) : ( R-G ));
                I = ( R==V ) ? 0 : (( G==V ) ? 2 : 4 );
                H = ( I + (float)F/(float)(V-X) )/6.0*255.0;
                if ( H < 0 ) H += 255;
                if ( H < 0 || H > 255 || V < 0 || V > 255 ) 
				{
                    fprintf( stderr, "%s %d: bad HS values: %d,%d\n",
                             __FILE__, __LINE__, H, S );
                    exit( -1 );
                }
            }
			float sVal = (float)S / 255.0;
			if (H > 0 && H < 50)// && sVal > 0.23 && sVal < 0.68)
			{
				if (skinColorPixelsCounter++ > maxCOunter);
					//return skinColorPixelsCounter;
				aPixelOut[ iRow * img->widthStep + iCol * 3 + 0 ] = 255;
			}
        }
    }
	static int t = 0;
	char stam[256];
	sprintf(stam, "C:\\TestOutputs\\test_%d.tif", t++);
	cvSaveImage(stam, outputImg); 
	cvReleaseImage(&outputImg);
	return skinColorPixelsCounter;
}

bool isSkinPixelsInImg1(IplImage *img, int skinPixelsThreshold)
{
	static int countEntrances = 0;
	if (126 == countEntrances++)
	{
		printf("why?\n");
	}
	int numOfPix = skinColorPixelsCounter1(img, skinPixelsThreshold);
	bool isItTrue = numOfPix >= skinPixelsThreshold;
	return isItTrue;
}

DlFacesVec MovieFaceExtractor::saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
		char *outputPath, int minPixels, int timeDelta, bool scaleDown)
{
	DlFacesVec retval;
	DlFacesVec facesVec;
	int scale = scaleDown ? 2 : 1;
	char imgOutputPath[256];
	int timeCount = 0;
	int count = 0;
	int id = 0;
	while (1)
	{
		cvClearMemStorage(s_storage);
		IplImage *img = cvQueryFrame(movieClip);
		if (img == NULL)
		{
			printf("End of clip\n");
			break;
		}
		CvSeq *faces;
		detectFace(img, &faces, scaleDown);
		CvRect *faceRect;
		for( int i = 0; i < (faces ? faces->total : 0); i++ )
		{
			faceRect = (CvRect*)cvGetSeqElem( faces, i );
			if ((faceRect->height < 1) || (faceRect->width < 1)) continue; 
			CvRect roi = cvRect(faceRect->x *scale, faceRect->y * scale, faceRect->width * scale, faceRect->height);
			IplImage* imgToSave = cvCreateImage(cvSize(roi.width, roi.height), img->depth, img->nChannels);
			cvSetImageROI(img, roi);
			cvCopy(img, imgToSave);
			cvResetImageROI(img);
			if (!isSkinPixelsInImg1(imgToSave, imgToSave->width * imgToSave->height * SKIN_PIX_THRESH_PERCENT / 100))
			{
				
				cvReleaseImage(&imgToSave);
				continue;
			}
			bool matchFound = false;
			for (int j = 0; j < facesVec.size(); ++j)
			{
				if (isSameFace1(imgToSave, facesVec[j], timeCount, faceRect))
				{
					matchFound = true;
					if (facesVec[j].lastSegmentClosed)
					{
						facesVec[j].addStartSegment(timeCount);
					}
					else
					{
						facesVec[j].addEndTime(timeCount);
					}
					break;
				}
			}
			if (matchFound)
			{
				continue;
			}
			DlFaceAndTime faceAndTime;
			sprintf(imgOutputPath, "%s\\face_%d_%d.tif", outputPath, count++, i);
			faceAndTime.face = imgToSave;
			faceAndTime.addStartSegment(timeCount);
			faceAndTime.lastTimeStamp = timeCount;
			faceAndTime.location = *faceRect;
			faceAndTime.pathToSave = imgOutputPath;
			faceAndTime.id = id++;
			facesVec.push_back(faceAndTime);
			cvSaveImage(imgOutputPath, imgToSave);			
			//dont release it is kept in vector - cvReleaseImage(&imgToSave);
			int fnum = cvGetCaptureProperty(movieClip, CV_CAP_PROP_POS_FRAMES);
			printf("found face at frame %d\t pos: %d %d\t size %d X %d\ttime count:%d\n", fnum, faceRect->x, faceRect->y, faceRect->width, faceRect->height, timeCount);
			
		}
		for (int j = 0 ; j < facesVec.size() ; ++j)
		{
			if (facesVec[j].lastTimeStamp != timeCount)
			{
				facesVec[j].lastSegmentClosed = true;
			}
		}
		timeCount++;
		//cvReleaseImage(&img);
		//if((cvWaitKey(timeDelta) & 255) == 27) break;
	}
	for (int j = 0 ; j < facesVec.size() ; ++j)
	{
		cvReleaseImage(&facesVec[j].face);
	}
	return facesVec;
}