//
//  main.m
//  p02_ob-c_getIP
//
//  Created by Atiq Rahman on 10/9/15.
//  Copyright (c) 2015
//

#import <Foundation/Foundation.h>
#import "CpuInfo.h"
//System Network info related
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>

//Uses related
#include <sys/sysctl.h>
#include <netinet/in.h>
#include <net/route.h>

//System memory related
#include <mach/vm_statistics.h>
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/mach_host.h>


static unsigned long long _previousTotalTicks = 0;
static unsigned long long _previousIdleTicks = 0;

// Returns 1.0f for "CPU fully pinned", 0.0f for "CPU idle", or somewhere in between
// You'll need to call this at regular intervals, since it measures the load between
// the previous call and the current one.
float CalculateCPULoad(unsigned long long idleTicks, unsigned long long totalTicks) {
    unsigned long long totalTicksSinceLastTime = totalTicks-_previousTotalTicks;
    unsigned long long idleTicksSinceLastTime  = idleTicks-_previousIdleTicks;
    float ret = 1.0f-((totalTicksSinceLastTime > 0) ? ((float)idleTicksSinceLastTime)/totalTicksSinceLastTime : 0);
    _previousTotalTicks = totalTicks;
    _previousIdleTicks  = idleTicks;
    return ret;
}

float getCPULoad() {
    host_cpu_load_info_data_t cpuinfo;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    if (host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&cpuinfo, &count) == KERN_SUCCESS) {
        unsigned long long totalTicks = 0;
        for(int i=0; i<CPU_STATE_MAX; i++) totalTicks += cpuinfo.cpu_ticks[i];
        float sysLoadPercentage = CalculateCPULoad(cpuinfo.cpu_ticks[CPU_STATE_IDLE], totalTicks);
        printf("sysLoadPercentage: %f\n", sysLoadPercentage);
        return 1;
    }
    else return -1.0f;
}

void getRamUses() {
    vm_size_t page_size;
    mach_port_t mach_port;
    mach_msg_type_number_t count;
    vm_statistics64_data_t vm_stats;
    
    mach_port = mach_host_self();
    count = sizeof(vm_stats) / sizeof(natural_t);
    if (KERN_SUCCESS == host_page_size(mach_port, &page_size) &&
        KERN_SUCCESS == host_statistics64(mach_port, HOST_VM_INFO,
                                          (host_info64_t)&vm_stats, &count)) {
            long long free_memory = (int64_t)vm_stats.free_count * (int64_t)page_size;
            
            long long used_memory = ((int64_t)vm_stats.active_count +
                                     (int64_t)vm_stats.inactive_count +
                                     (int64_t)vm_stats.wire_count) *  (int64_t)page_size;
            printf("free memory: %lld\nused memory: %lld\n", free_memory, used_memory);
        }
}

void getNetworkInfo() {
    NSLog(@"\nMACOSX - System Info Extraction Program!\n");
    struct ifaddrs *allInterfaces;
    
    // Get list of all interfaces on the local machine:
    if (getifaddrs(&allInterfaces) == 0) {
        struct ifaddrs *interface;
        
        // For each interface ...
        for (interface = allInterfaces; interface != NULL; interface = interface->ifa_next) {
            unsigned int flags = interface->ifa_flags;
            struct sockaddr *addr = interface->ifa_addr;
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if ((flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) {
                char host[NI_MAXHOST];
                if (addr->sa_family == AF_INET || addr->sa_family == AF_INET6) {
                    printf("Interface name: %s\n", interface->ifa_name);
                    getnameinfo(addr, addr->sa_len, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
                }
                //Probable inactive devices, uncomment to list all
                else
                    printf("Interface name: %s\n", interface->ifa_name);
                // AF_INET - ipv4
                // AF_INET - ipv6
                // if (addr->sa_family == AF_INET) {
                
                // For the same interface it is showing IP info
                // Convert interface address to a human readable string:
                if (addr->sa_family == AF_INET)
                    printf("IPv4 address:%s\n", host);
                else if (addr->sa_family == AF_INET6)
                    printf("IPv6 address:%s\n", host);
            }
        }
        freeifaddrs(allInterfaces);
    }
}
void getNetworkUses() {
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
    printf("Total ibytes %qu\tobytes %qu\n", totalibytes, totalobytes);
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        getNetworkInfo();
        getNetworkUses();
        getCPULoad();
        getRamUses();
        CpuInfo *cpuInfo = [[CpuInfo alloc]init];
        [cpuInfo applicationDidFinishLaunching];
    }
    return 0;
}
