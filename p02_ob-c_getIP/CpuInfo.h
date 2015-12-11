//
//  CpuInfo.h
//  p02_ob-c_getIP
//
//  Created by Milan Mia on 12/12/15.
//  Copyright © 2015 Social Network Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>
//Uses related
#include <sys/sysctl.h>
#include <netinet/in.h>
#include <net/route.h>
//System Network info related
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>
//System memory related
#include <mach/vm_statistics.h>
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/mach_host.h>

@interface CpuInfo : NSObject {
    processor_info_array_t cpuInfo, prevCpuInfo;
    mach_msg_type_number_t numCpuInfo, numPrevCpuInfo;
    unsigned numCPUs;
    NSTimer *updateTimer;
    NSLock *CPUUsageLock;
}
- (void)applicationDidFinishLaunching;
- (void)updateInfo:(NSTimer *)timer;
@end
