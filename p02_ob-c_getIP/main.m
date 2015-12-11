//
//  main.m
//  p02_ob-c_getIP
//
//  Created by Atiq Rahman on 10/9/15.
//  Copyright (c) 2015
//

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>

#include <sys/sysctl.h>
#include <netinet/in.h>
#include <net/route.h>

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
            totalibytes += if2m->ifm_data.ifi_ibytes;
            totalobytes += if2m->ifm_data.ifi_obytes;
        }
    }
    printf("total ibytes %qu\tobytes %qu\n", totalibytes, totalobytes);
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        getNetworkInfo();
        getNetworkUses();
    }
    return 0;
}
