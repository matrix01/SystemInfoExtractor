//
//  CpuInfo.m
//  p02_ob-c_getIP
//
//  Created by Milan Mia on 12/12/15.
//  Copyright © 2015 Social Network Team. All rights reserved.
//

#import "CpuInfo.h"

@implementation CpuInfo
- (void) getNetworkUses {
    int mib[] = {
        CTL_NET,
        PF_ROUTE,
        0,
        0,
        NET_RT_IFLIST2,
        0
    };
    size_t len;
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        fprintf(stderr, "sysctl: %s\n", strerror(errno));
        exit(1);
    }
    char *buf = (char *)malloc(len);
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        fprintf(stderr, "sysctl: %s\n", strerror(errno));
        exit(1);
    }
    char *lim = buf + len;
    char *next = NULL;
    u_int64_t totalibytes = 0;
    u_int64_t totalobytes = 0;
    for (next = buf; next < lim; ) {
        struct if_msghdr *ifm = (struct if_msghdr *)next;
        next += ifm->ifm_msglen;
        if (ifm->ifm_type == RTM_IFINFO2) {
            struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
            //            totalibytes += if2m->ifm_data.ifi_ibytes;
            //            totalobytes += if2m->ifm_data.ifi_obytes;
            totalibytes += if2m->ifm_data.ifi_ipackets;
            totalobytes += if2m->ifm_data.ifi_opackets;
        }
    }
    printf("\nTotal iPackets %qu\toPackets %qu\n", totalibytes, totalobytes);
}

- (void)applicationDidFinishLaunching
{
    int mib[2U] = { CTL_HW, HW_NCPU };
    size_t sizeOfNumCPUs = sizeof(numCPUs);
    int status = sysctl(mib, 2U, &numCPUs, &sizeOfNumCPUs, NULL, 0U);
    if(status)
        numCPUs = 1;
    
    CPUUsageLock = [[NSLock alloc] init];
    
    
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                    target:self
                                                  selector:@selector(updateInfo:)
                                                  userInfo:nil
                                                   repeats:YES];

    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:60];
    while ([timeout timeIntervalSinceNow]>0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void)updateInfo:(NSTimer *)timer
{
    //Show network Info
    [self getNetworkUses];
    
    natural_t numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    if(err == KERN_SUCCESS) {
        [CPUUsageLock lock];
        
        for(unsigned i = 0U; i < numCPUs; ++i) {
            float inUse, total;
            if(prevCpuInfo) {
                inUse = (
                         (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                         );
                total = inUse + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                inUse = cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total = inUse + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            
            NSLog(@"Core: %u Usage: %f",i,inUse / total);
        }
        [CPUUsageLock unlock];
        
        if(prevCpuInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * numPrevCpuInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)prevCpuInfo, prevCpuInfoSize);
        }
        
        prevCpuInfo = cpuInfo;
        numPrevCpuInfo = numCpuInfo;
        
        cpuInfo = NULL;
        numCpuInfo = 0U;
    } else {
        NSLog(@"Error!");
    }
}

@end
