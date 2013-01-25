//
//  Constants.h
//  AppSendr
//
//  Created by Nolan Brown on 4/10/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#ifndef AppSendr_Constants_h
#define AppSendr_Constants_h

#ifdef DEBUG

#	define ASLog(fmt, ...)NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#else
#	define ASLog(fmt, ...);
#endif

static NSString * const kASFileName = @"app.sendr";
static NSString * const kAppSendrBaseURLString = @"https://api.appsendr.com";

#endif
