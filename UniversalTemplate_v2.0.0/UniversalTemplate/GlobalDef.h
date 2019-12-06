//
//  GlobalDef.h
//  PCM0
//
//  Created by Jason liang on 17/3/22.
//  Copyright © 2017年 Jason liang. All rights reserved.
//

#ifndef GlobalDef_h
#define GlobalDef_h

//#define SCREEN_WIDTH        1176
//#define SCREEN_HEIGHT       750
#define SCREEN_WIDTH ([NSScreen mainScreen].frame.size.width - 100)
#define SCREEN_HEIGHT ([NSScreen mainScreen].frame.size.height - 60)

#define TITLEVIEW_X         20
#define TITLEVIEW_WIDTH     (SCREEN_WIDTH - 2*TITLEVIEW_X)
#define TITLEVIEW_HEIGHT    100
#define TITLEVIEW_Y         0

#define FIXTURESTATUSVIEW_X      20
#define FIXTURESTATUSVIEW_WIDTH     (SCREEN_WIDTH - 2*FIXTURESTATUSVIEW_X)
#define FIXTURESTATUSVIEW_HEIGHT    26
#define FIXTURESTATUSVIEW_Y    (SCREEN_HEIGHT - FIXTURESTATUSVIEW_HEIGHT - 8)

#define SEGMENTEDCONTROL_WIDTH 240
#define SEGMENTEDCONTROL_HEIGHT 40
#define SEGMENTEDCONTROL_X (SCREEN_WIDTH - SEGMENTEDCONTROL_WIDTH)/2
#define SEGMENTEDCONTROL_Y SCREEN_HEIGHT - 70

#define SNVIEW_X    20
#define SNVIEW_Y    (TITLEVIEW_Y + TITLEVIEW_HEIGHT + 5)
#define SNVIEW_WIDTH     (SCREEN_WIDTH - 2*SNVIEW_X)/MULTIPLE_NUMBERS - 10
#define SNVIEW_HEIGHT    120

#define TABVIEW_X           20
#define TABVIEW_WIDTH       (SCREEN_WIDTH - 2*TABVIEW_X)
#define TABVIEW_HEIGHT      (SCREEN_HEIGHT - TITLEVIEW_HEIGHT - SNVIEW_HEIGHT - 2*SEGMENTEDCONTROL_HEIGHT - 10)
#define TABVIEW_Y           (TITLEVIEW_Y + TITLEVIEW_HEIGHT + 10 + SNVIEW_HEIGHT + 5)



#endif /* GlobalDef_h */
