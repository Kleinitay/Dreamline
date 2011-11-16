// eigenface.c, by Robin Hewitt, 2007
//
// Example program showing how to implement eigenface with OpenCV

// Usage:
//
// First, you need some face images. I used the ORL face database.
// You can download it for free at
//    www.cl.cam.ac.uk/research/dtg/attarchive/facedatabase.html
//
// List the training and test face images you want to use in the
// input files train.txt and test.txt. (Example input files are provided
// in the download.) To use these input files exactly as provided, unzip
// the ORL face database, and place train.txt, test.txt, and eigenface.exe
// at the root of the unzipped database.
//
// To run the learning phase of eigenface, enter
//    eigenface train
// at the command prompt. To run the recognition phase, enter
//    eigenface test


#include <stdio.h>
#include <string.h>
#include "cv.h"
#include "cvaux.h"
#include "highgui.h"
#define SKIN_PIX_THRESH_PERCENT 70
#define TIME_DIFF_THRESHOLD 1
#define X_POS_THRESHOLD 5
#define Y_POS_THRESHOLD 5
#define EIGEN_IMG_DIM 40
#define NEAREST_NEIGHBOR_THRESHOLD 1500000
#define NORM_THRESHOLD 3000
#define MAX_FACES 1000

/* Macros to get the max/min of 3 values */
#define MAX3(r,g,b) ((r)>(g)?((r)>(b)?(r):(b)):((g)>(b)?(g):(b)))
#define MIN3(r,g,b) ((r)<(g)?((r)<(b)?(r):(b)):((g)<(b)?(g):(b)))

struct DlTimeSegment
{
	int start_time;
	int end_time;
};

struct DlFaceAndTime
{
	int id;
	char pathToSave[1024];
	IplImage *face;
	IplImage *StandardizedFaces[20];
	float *eigenVecs[20];
	int numOfFacesFound;
	CvRect location;
	int numOfTimeSegments;
	DlTimeSegment timeSegments[100];
	int lastTimeStamp;
	bool lastSegmentClosed;

};
//// Global variables
//Eigen faces
IplImage ** faceImgArr        = 0; // array of face images
CvMat    *  personNumTruthMat = 0; // array of person numbers
int nTrainFaces               = 0; // the number of training images
int nEigens                   = 0; // the number of eigenvalues
IplImage * pAvgTrainImg       = 0; // the average image
IplImage ** eigenVectArr      = 0; // eigenvectors
CvMat * eigenValMat           = 0; // eigenvalues
CvMat * projectedTrainFaceMat = 0; // projected training faces

//Face detection
// Create memory for calculations
CvMemStorage* storage;
//faces for computation
IplImage ** faces;
// avg eigen face
bool isInitialized;
// Haar classifier for face detection
CvHaarClassifierCascade* cascade;

//Faces and time segments
DlFaceAndTime dlFaces[MAX_FACES];
int numOfDlFaces;
int curNumTrainFaces;


//// Function prototypes
void learn();
void recognize();
void doPCA();
void storeTrainingData();
int  loadTrainingData(CvMat ** pTrainPersonNumMat);
int  findNearestNeighbor(float * projectedTestFace);
int  loadFaceImgArray(char * filename);
void printUsage();

void myLearn();

void  addStartSegment(int time, DlFaceAndTime *fandt);
void addEndTime(int time, DlFaceAndTime *fandt);
int findNearestNeighbor(float *testVec, double threshold);
void setEigenVecsToDlFaces();
int findTotalNumOfFaces();
void fillFaceImgArr();
void doTheEigenFaces();
int recognizeAndAddFace(IplImage *inputImg, float *projectedVec);
void standardizeImage(IplImage *inputImg, IplImage **outputImg,  int width, int height);
bool isSameFace (IplImage *img, DlFaceAndTime face, int timeCount, CvRect *location);
int skinColorPixelsCounter(IplImage *img, int skinPixelsThreshold);
bool isSkinPixelsInImg(IplImage *img, int skinPixelsThreshold);
void detectFace( IplImage* img, CvSeq** outSec, bool scaleDown);
void saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
	char *outputPath, int minPixels, int timeDelta, bool scaleDown);
void Dreamline(char *movieClipPath, char *outputPath, char *haarClassifierPath, char *ThumbPath, char *smallThumbPath);
void saveToXML(char *outputPath);

int main( int argc, char** argv )
{
	// validate that an input was specified
	if( argc < 2 )
	{
		printUsage();
		return 0;
	}

	if( !strcmp(argv[1], "train") ) learn();
	else if( !strcmp(argv[1], "test") ) recognize();
	else if ( !strcmp(argv[1], "Dreamline_test") ) Dreamline( "C:\\TestData\\Movies\\IMG_1411_mpeg1video.mpg", 
		"C:\\TestOutputs", "C:\\OpenCV2.2\\data\\haarcascades\\haarcascade_frontalface_alt_tree.xml", "C:\\TestOutputs\\tn.jpg", "C:\\TestOutputs\\tn_s.jpg");
	else if ( !strcmp(argv[1], "Dreamline") && argc < 4 ) Dreamline( argv[2], argv[3], 
		"./haarcascades/haarcascade_frontalface_alt_tree.xml", NULL, NULL);
	else if ( !strcmp(argv[1],  "Dreamline") && argc < 5 ) Dreamline( argv[2], argv[3],argv[4], NULL, NULL);
	//args: 2 = input path, 3 = output dir, 4 = haar cascade, 5 = thumbnale path
	else if ( !strcmp(argv[1], "Dreamline") ) Dreamline( argv[2], argv[3],argv[4], argv[5], argv[6]);

	else
	{
		printf("Unknown command: %s\n", argv[1]);
		printUsage();
	}

	return 0;
}


void Dreamline(char *movieClipPath, char *outputPath, char *haarClassifierPath, char *thumbPath, char *smallThumbPath)
{
	if (!movieClipPath || strlen(movieClipPath) < 2)
	{
		printf("error in input path");
		return;
	}
	char *filename = movieClipPath;
	CvCapture* cap  = cvCreateFileCapture(filename);
	if (cap == NULL)
	{
		printf("error in input file");
	}
	printf("starting the run");
	storage = cvCreateMemStorage(0);
	cascade = (CvHaarClassifierCascade*)cvLoad( haarClassifierPath, 0, 0, 0 );
	if (thumbPath && strlen(thumbPath) > 0)
	{
		IplImage *thumb = cvCreateImage(cvSize(134, 110), IPL_DEPTH_8U, 3);
		
		IplImage *frm = cvQueryFrame(cap);
		if (frm)
		{
			cvResize(frm, thumb);
			
			cvSaveImage(thumbPath, thumb);
			if (smallThumbPath && strlen(smallThumbPath) > 0)
			{
				IplImage *thumb_s = cvCreateImage(cvSize(90, 48), IPL_DEPTH_8U, 3);
				cvResize(frm, thumb_s);
				cvSaveImage(smallThumbPath, thumb_s);
			}
		}
		cvReleaseImage(&thumb);
	}
	saveFacesToDiskAndGetTimeStamps(cap, outputPath, 3, 1, false);
	cvReleaseCapture(&cap);
	char outputFilePath[256];
	sprintf(outputFilePath, "%s/faces.xml", outputPath);
	printf("saving to xml");
	saveToXML(outputFilePath);
}

void addStartSegment(int time, DlFaceAndTime *fandt)
{

	fandt->timeSegments[fandt->numOfTimeSegments].start_time = time;
	fandt->timeSegments[fandt->numOfTimeSegments].end_time = time;
	fandt->numOfTimeSegments++;
	fandt->lastTimeStamp = time;
	fandt->lastSegmentClosed = false;
}

void addEndTime(int time, DlFaceAndTime *fandt)
{
	fandt->timeSegments[fandt->numOfTimeSegments - 1].end_time = time;
	fandt->lastTimeStamp = time;
}


#ifndef region_MyEigenfaces
///////////////////////////////////////////Eigenfaces////////////////////////////////////////////
int findNearestNeighbor(float *testVec, double threshold)
{
	int resVal = -1;
	double minVal = DBL_MAX;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			double distance = 0;
			for (int k = 0 ; k < nEigens ; ++k)
			{
				double val = testVec[k] - dlFaces[i].eigenVecs[j][k];
				double valSq = val * val;
				distance += valSq;
			}
			if (distance < minVal && distance < threshold)
			{
				minVal = distance;
				resVal = i;
				//printf("------%d\t%f\n-------",i,distance);
			}
			else
			{
				//printf("%d\t%f\n",i,distance);
			}
		}
	}
	return resVal;
}

void setEigenVecsToDlFaces()
{
	int offset = projectedTrainFaceMat->step / sizeof(float);
	int index = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			dlFaces[i].eigenVecs[j] = (float *)malloc(nEigens * sizeof(float));
			for (int k = 0 ; k < nEigens ; ++k)
			{
				dlFaces[i].eigenVecs[j][k] = (projectedTrainFaceMat->data.fl + index * offset)[k];
			}
			index++;
		}
	}
}

int findTotalNumOfFaces()
{
	int resval = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		resval += dlFaces[i].numOfFacesFound; 
	}
	return resval;
}

void fillFaceImgArr()
{
	int totNumOfFaces = findTotalNumOfFaces();
	faceImgArr = (IplImage **)cvAlloc(totNumOfFaces * sizeof(IplImage *));
	int index = 0;
	for (int i = 0 ; i < numOfDlFaces ; ++i)
	{
		for (int j = 0 ; j < dlFaces[i].numOfFacesFound ; ++j)
		{
			faceImgArr[index++] = dlFaces[i].StandardizedFaces[j];
		}
	}
	nTrainFaces = index;
}

void doTheEigenFaces()
{
	fillFaceImgArr();
	myLearn();
	//IplImage *tmp = cvCreateImage(cvGetSize(pAvgTrainImg), IPL_DEPTH_8U, 1);
	//cvConvert(pAvgTrainImg, tmp);
	//cvSaveImage("C:\\TestOutputs\\avg.tif", tmp);
	//cvReleaseImage(&tmp);
	setEigenVecsToDlFaces();
}

int recognizeAndAddFace(IplImage *inputImg, float **projectedTestFace)
{

	*projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );
	// project the test image onto the PCA subspace
	cvEigenDecomposite(
		inputImg,
		nEigens,
		eigenVectArr,
		0, 0,
		pAvgTrainImg,
		*projectedTestFace);
	int nearest = findNearestNeighbor(*projectedTestFace, NEAREST_NEIGHBOR_THRESHOLD);
	if (nearest == -1) return -1;
	if (dlFaces[nearest].numOfFacesFound < 20)
	{
		dlFaces[nearest].StandardizedFaces[dlFaces[nearest].numOfFacesFound] = inputImg;
		dlFaces[nearest].eigenVecs[dlFaces[nearest].numOfFacesFound] = *projectedTestFace; 
		dlFaces[nearest].numOfFacesFound++;
	}
	return nearest;
}

void standardizeImage(IplImage *inputImg, IplImage **outputImg,  int width, int height)
{
	*outputImg = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
	IplImage *tmpGrayImage = cvCreateImage(cvGetSize(inputImg), IPL_DEPTH_8U, 1);
	cvCvtColor(inputImg, tmpGrayImage, CV_BGR2GRAY );
	cvResize(tmpGrayImage, *outputImg, CV_INTER_LINEAR);
	cvEqualizeHist(*outputImg, *outputImg);
}

bool isSameFace (IplImage *img, DlFaceAndTime face, int timeCount, CvRect *location)
{
	if ( abs(timeCount - face.lastTimeStamp < TIME_DIFF_THRESHOLD)
		&& abs(face.location.x - location->x) < X_POS_THRESHOLD
		&& abs(face.location.y - location->y) < Y_POS_THRESHOLD )
		return true;


	//add more face comparison logic here
	IplImage *workImg;
	standardizeImage(img, &workImg, EIGEN_IMG_DIM, EIGEN_IMG_DIM);
	//just compare the face to the one found
	if (numOfDlFaces == 1)
	{
		double images_diff = cvNorm(workImg, dlFaces[0].StandardizedFaces[0]);
		return (images_diff < NORM_THRESHOLD);
	}
	static int count = 0;
	float *projectedVec;
	int faceIndex = nTrainFaces > 1 ? recognizeAndAddFace(workImg, &projectedVec) : -1;
	if (faceIndex != -1)
	{
		//this already happensin the recognize function
		/*if (dlFaces[faceIndex].numOfFacesFound < 20)
		{
		int numberOfFaceCurrntllyFoundForFace = dlFaces[faceIndex].numOfFacesFound;
		dlFaces[faceIndex].StandardizedFaces[numberOfFaceCurrntllyFoundForFace] = workImg;
		dlFaces[faceIndex].eigenVecs[numberOfFaceCurrntllyFoundForFace] = projectedVec;
		dlFaces[faceIndex].numOfFacesFound++;
		}*/
		return true;
	}
	/*char stam[256];
	sprintf(stam, "C:\\TestOutputs\\standard_%d.tif", count++);
	cvSaveImage(stam, workImg);
	cvReleaseImage(&workImg);*/
	return false;
}

int skinColorPixelsCounter(IplImage *img, int skinPixelsThreshold)
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
	/*static int t = 0;
	char stam[256];
	sprintf(stam, "C:\\TestOutputs\\test_%d.tif", t++);
	cvSaveImage(stam, outputImg); 
	cvReleaseImage(&outputImg);*/
	return skinColorPixelsCounter;
}

bool isSkinPixelsInImg(IplImage *img, int skinPixelsThreshold)
{
	static int countEntrances = 0;
	int numOfPix = skinColorPixelsCounter(img, skinPixelsThreshold);
	bool isItTrue = numOfPix >= skinPixelsThreshold;
	return isItTrue;
}

void detectFace( IplImage* img, CvSeq** outSec, bool scaleDown)
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
	cvClearMemStorage( storage );

	// Find whether the cascade is loaded, to find the faces. If yes, then:
	if( cascade )
	{

		// There can be more than one face in an image. So create a growable sequence of faces.
		// Detect the objects and store them in the sequence
		*outSec = cvHaarDetectObjects( small_image, cascade, storage,
			1.2, 2, CV_HAAR_DO_CANNY_PRUNING,
			cvSize(40, 40) );
	}

	if( scaleDown )
	{
		// Release the temp image created.
		cvReleaseImage( &small_image );
	}
}

void addToDlFacesVec(IplImage *img, int timestamp, char *outputPath, CvRect location)
{
	DlFaceAndTime faceAndTime;
	faceAndTime.numOfFacesFound = 1;
	faceAndTime.numOfTimeSegments = 0;
	faceAndTime.face = img;
	addStartSegment(timestamp, &faceAndTime);
	faceAndTime.lastTimeStamp = timestamp;
	faceAndTime.location = location;
	strcpy(faceAndTime.pathToSave, outputPath);
	faceAndTime.id = numOfDlFaces;

	IplImage *standardizedImg;
	standardizeImage(img, &standardizedImg, EIGEN_IMG_DIM, EIGEN_IMG_DIM);
	faceAndTime.StandardizedFaces[0] = standardizedImg;

	dlFaces[numOfDlFaces] = faceAndTime;
	numOfDlFaces++;
}

void doThEigensWhen(int modWhen)
{
	int totNumOfFaces = findTotalNumOfFaces();
	if (totNumOfFaces > 1 && (totNumOfFaces == 2 || totNumOfFaces % modWhen == 0))
	{
		doTheEigenFaces();
	}

}

void saveFacesToDiskAndGetTimeStamps(CvCapture* movieClip, 
	char *outputPath, int minPixels, int timeDelta, bool scaleDown)
{
	int scale = scaleDown ? 2 : 1;
	char imgOutputPath[256];
	int timeCount = 0;
	int count = 0;
	int id = 0;
	while (1)
	{
		cvClearMemStorage(storage);
		//char tmppath[256];
		//sprintf(tmppath, "%s/%s%d.tif", outputPath, "frame", timeCount);
		IplImage *img = NULL;
		img = cvQueryFrame(movieClip);
		if (img == NULL)
		{
			printf("End of clip\n");
			break;
		}
		//cvSaveImage(tmppath, img);
		//printf("Frame aquired\n");
		CvSeq *faces;
		detectFace(img, &faces, scaleDown);
		//printf("After face detect found %d faces\n", faces->total);
		CvRect *faceRect;
		int foundFaces[100];
		int foundFacesCount = 0;
		for( int i = 0; i < (faces ? faces->total : 0); i++ )
		{
			faceRect = (CvRect*)cvGetSeqElem( faces, i );
			if ((faceRect->height < 1) || (faceRect->width < 1)) continue; 
			CvRect roi = cvRect(faceRect->x *scale, faceRect->y * scale, faceRect->width * scale, faceRect->height);
			IplImage* imgToSave = cvCreateImage(cvSize(roi.width, roi.height), img->depth, img->nChannels);
			cvSetImageROI(img, roi);
			cvCopy(img, imgToSave);
			cvResetImageROI(img);
			if (!isSkinPixelsInImg(imgToSave, imgToSave->width * imgToSave->height * SKIN_PIX_THRESH_PERCENT / 100))
			{

				cvReleaseImage(&imgToSave);
				continue;
			}
			bool matchFound = false;
			for (int j = 0; j < numOfDlFaces; ++j)
			{
				if (isSameFace(imgToSave, dlFaces[j], timeCount, faceRect))
				{
					foundFaces[foundFacesCount++] = j;

					matchFound = true;
					if (dlFaces[j].lastSegmentClosed)
					{
						addStartSegment(timeCount, &dlFaces[j]);
					}
					else
					{
						addEndTime(timeCount, &dlFaces[j]);
					}
					doThEigensWhen(5);
					break;
				}
			}
			if (matchFound)
			{
				continue;
			}
			sprintf(imgOutputPath, "%s/face_%d_%d.jpg", outputPath, numOfDlFaces + 1, i);
			addToDlFacesVec(imgToSave, timeCount, imgOutputPath, *faceRect);
			cvSaveImage(imgOutputPath, imgToSave);			
			//dont release it is kept in vector - cvReleaseImage(&imgToSave);
			int fnum = cvGetCaptureProperty(movieClip, CV_CAP_PROP_POS_FRAMES);
			printf("found face at frame %d\t pos: %d %d\t size %d X %d\ttime count:%d\n", fnum, faceRect->x, faceRect->y, faceRect->width, faceRect->height, timeCount);

			doThEigensWhen(1);
		}
		for (int j = 0 ; j < numOfDlFaces ; ++j)
		{
			bool found = false;
			for (int k = 0; k < foundFacesCount; k++)
			{
				if (foundFaces[k] == j)
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				//addEndTime(timeCount, &dlFaces[j]);
				dlFaces[j].lastSegmentClosed = true;
			}
		}
		timeCount++;
		//cvReleaseImage(&img);
		//if((cvWaitKey(timeDelta) & 255) == 27) break;
	}
}

void saveToXML(char *outputPath)
{
	FILE *file = fopen(outputPath, "w");
	if (!file) return;
	fprintf(file, "<?xml version=\"1.0\"?>\n");
	fprintf(file, "<faces>\n");
	for (int i = 0; i < numOfDlFaces; i++)
	{
		fprintf(file, "<face id=\"%d\" path=\"%s\">\n", dlFaces[i].id, dlFaces[i].pathToSave);
		for (int j = 0; j < dlFaces[i].numOfTimeSegments; j++)
		{
			fprintf(file, "\t<timesegment start=\"%d\" end =\"%d\"/>\n", dlFaces[i].timeSegments[j].start_time, dlFaces[i].timeSegments[j].end_time);
		}
		fprintf(file, "</face>");
	}
	fprintf(file, "</faces>\n");
	fclose(file);
}
/////////////////////////////////////////////////////////////////////////////////////////////////
#endif


#ifndef region_theircode 
//////////////////////////////////
// learn()
//
void learn()
{
	int i, offset;

	// load training data
	nTrainFaces = loadFaceImgArray("train.txt");
	if( nTrainFaces < 2 )
	{
		fprintf(stderr,
			"Need 2 or more training faces\n"
			"Input file contains only %d\n", nTrainFaces);
		return;
	}

	// do PCA on the training faces
	doPCA();

	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			//projectedTrainFaceMat->data.fl + i*nEigens);
			projectedTrainFaceMat->data.fl + i*offset);
	}

	// store the recognition data as an xml file
	storeTrainingData();
}

//////////////////////////////////
// learn()
//
void myLearn()
{
	int i, offset;

	// do PCA on the training faces
	doPCA();
	printf(",");
	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			//projectedTrainFaceMat->data.fl + i*nEigens);
			projectedTrainFaceMat->data.fl + i*offset);
	}
}

//////////////////////////////////
// recognize()
//
void recognize()
{
	int i, nTestFaces  = 0;         // the number of test images
	CvMat * trainPersonNumMat = 0;  // the person numbers during training
	float * projectedTestFace = 0;
	int correct = 0; // number of correct matches

	// load test images and ground truth for person number
	nTestFaces = loadFaceImgArray("test.txt");
	printf("%d test faces loaded\n", nTestFaces);

	// load the saved training data
	if( !loadTrainingData( &trainPersonNumMat ) ) return;

	// project the test images onto the PCA subspace
	projectedTestFace = (float *)cvAlloc( nEigens*sizeof(float) );
	for(i=0; i<nTestFaces; i++)
	{
		int iNearest, nearest, truth;

		// project the test image onto the PCA subspace
		cvEigenDecomposite(
			faceImgArr[i],
			nEigens,
			eigenVectArr,
			0, 0,
			pAvgTrainImg,
			projectedTestFace);

		iNearest = findNearestNeighbor(projectedTestFace);
		truth    = personNumTruthMat->data.i[i];
		nearest  = trainPersonNumMat->data.i[iNearest];

		printf("nearest = %d, Truth = %d\n", nearest, truth);

		if(nearest==truth)
			correct++;
	}

	printf("The percentage of correct recognitions is %f \n", (double)correct/(double)nTestFaces);
}


//////////////////////////////////
// loadTrainingData()
//
int loadTrainingData(CvMat ** pTrainPersonNumMat)
{
	CvFileStorage * fileStorage;
	int i;

	// create a file-storage interface
	fileStorage = cvOpenFileStorage( "facedata.xml", 0, CV_STORAGE_READ );
	if( !fileStorage )
	{
		fprintf(stderr, "Can't open facedata.xml\n");
		return 0;
	}

	nEigens = cvReadIntByName(fileStorage, 0, "nEigens", 0);
	nTrainFaces = cvReadIntByName(fileStorage, 0, "nTrainFaces", 0);
	*pTrainPersonNumMat = (CvMat *)cvReadByName(fileStorage, 0, "trainPersonNumMat", 0);
	eigenValMat  = (CvMat *)cvReadByName(fileStorage, 0, "eigenValMat", 0);
	projectedTrainFaceMat = (CvMat *)cvReadByName(fileStorage, 0, "projectedTrainFaceMat", 0);
	pAvgTrainImg = (IplImage *)cvReadByName(fileStorage, 0, "avgTrainImg", 0);
	eigenVectArr = (IplImage **)cvAlloc(nTrainFaces*sizeof(IplImage *));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		eigenVectArr[i] = (IplImage *)cvReadByName(fileStorage, 0, varname, 0);
	}

	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );

	return 1;
}


//////////////////////////////////
// storeTrainingData()
//
void storeTrainingData()
{
	CvFileStorage * fileStorage;
	int i;

	// create a file-storage interface
	fileStorage = cvOpenFileStorage( "facedata.xml", 0, CV_STORAGE_WRITE );

	// store all the data
	cvWriteInt( fileStorage, "nEigens", nEigens );
	cvWriteInt( fileStorage, "nTrainFaces", nTrainFaces );
	cvWrite(fileStorage, "trainPersonNumMat", personNumTruthMat, cvAttrList(0,0));
	cvWrite(fileStorage, "eigenValMat", eigenValMat, cvAttrList(0,0));
	cvWrite(fileStorage, "projectedTrainFaceMat", projectedTrainFaceMat, cvAttrList(0,0));
	cvWrite(fileStorage, "avgTrainImg", pAvgTrainImg, cvAttrList(0,0));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		cvWrite(fileStorage, varname, eigenVectArr[i], cvAttrList(0,0));
	}

	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
}


//////////////////////////////////
// findNearestNeighbor()
//
int findNearestNeighbor(float * projectedTestFace)
{
	//double leastDistSq = 1e12;
	double leastDistSq = DBL_MAX;
	int i, iTrain, iNearest = 0;

	for(iTrain=0; iTrain<nTrainFaces; iTrain++)
	{
		double distSq=0;

		for(i=0; i<nEigens; i++)
		{
			float d_i = projectedTestFace[i] - projectedTrainFaceMat->data.fl[iTrain*nEigens + i];
			//distSq += d_i*d_i / eigenValMat->data.fl[i];  // Mahalanobis
			distSq += d_i*d_i; // Euclidean
		}

		if(distSq < leastDistSq)
		{
			leastDistSq = distSq;
			iNearest = iTrain;
		}
	}

	return iNearest;
}


//////////////////////////////////
// doPCA()
//
void doPCA()
{
	int i;
	CvTermCriteria calcLimit;
	CvSize faceImgSize;

	// set the number of eigenvalues to use
	nEigens = nTrainFaces-1;

	// allocate the eigenvector images
	faceImgSize.width  = faceImgArr[0]->width;
	faceImgSize.height = faceImgArr[0]->height;
	eigenVectArr = (IplImage**)cvAlloc(sizeof(IplImage*) * nEigens);
	for(i=0; i<nEigens; i++)
		eigenVectArr[i] = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);

	// allocate the eigenvalue array
	eigenValMat = cvCreateMat( 1, nEigens, CV_32FC1 );

	// allocate the averaged image
	pAvgTrainImg = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);

	// set the PCA termination criterion
	calcLimit = cvTermCriteria( CV_TERMCRIT_ITER, nEigens, 1);

	// compute average image, eigenvalues, and eigenvectors
	cvCalcEigenObjects(
		nTrainFaces,
		(void*)faceImgArr,
		(void*)eigenVectArr,
		CV_EIGOBJ_NO_CALLBACK,
		0,
		0,
		&calcLimit,
		pAvgTrainImg,
		eigenValMat->data.fl);

	cvNormalize(eigenValMat, eigenValMat, 1, 0, CV_L1, 0);
}


//////////////////////////////////
// loadFaceImgArray()
//
int loadFaceImgArray(char * filename)
{
	FILE * imgListFile = 0;
	char imgFilename[512];
	int iFace, nFaces=0;


	// open the input file
	if( !(imgListFile = fopen(filename, "r")) )
	{
		fprintf(stderr, "Can\'t open file %s\n", filename);
		return 0;
	}

	// count the number of faces
	while( fgets(imgFilename, 512, imgListFile) ) ++nFaces;
	rewind(imgListFile);

	// allocate the face-image array and person number matrix
	faceImgArr        = (IplImage **)cvAlloc( nFaces*sizeof(IplImage *) );
	personNumTruthMat = cvCreateMat( 1, nFaces, CV_32SC1 );

	// store the face images in an array
	for(iFace=0; iFace<nFaces; iFace++)
	{
		// read person number and name of image file
		fscanf(imgListFile,
			"%d %s", personNumTruthMat->data.i+iFace, imgFilename);

		// load the face image
		faceImgArr[iFace] = cvLoadImage(imgFilename, CV_LOAD_IMAGE_GRAYSCALE);

		if( !faceImgArr[iFace] )
		{
			fprintf(stderr, "Can\'t load image from %s\n", imgFilename);
			return 0;
		}
	}

	fclose(imgListFile);

	return nFaces;
}


//////////////////////////////////
// printUsage()
//
void printUsage()
{
	printf("Usage: eigenface <command>\n",
		"  Valid commands are\n"
		"    train\n"
		"    test\n");
}

#endif
class EigenFaceDetector
{
public:
	EigenFaceDetector(void);
	~EigenFaceDetector(void);
};

