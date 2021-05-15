#include <stdint.h>
#import <mach/mach.h>
#import <Foundation/Foundation.h>

//https://github.com/rpetrich/ldid/blob/master/ldid.cpp

#include "MachOInfo.h"

class MachOParser{
public:
    void* base;
    long slide;
public:
    MachOParser();
    MachOParser(const char* base);
    MachOParser(void* base, local_addr slide);
    
    /**
     find mach-o load command load dylib name

     @return array of dylibs
     */
    NSArray* find_load_dylib();
    
    /**
     get mach-o segment

     @param segname segment name
     @return segment struct
     */
    segment_info_t* find_segment(const char* segname);
   
    /**
     get mach-o section

     @param segname segment name
     @param secname section name
     @return section struct
     */
    section_info_t* find_section(const char* segname,const char* secname);
    
    /**
     get md5 value from text in memory

     @return md5 string
     */
    NSString* get_text_data_md5();
private:
    local_addr vm2real(local_addr vmaddr);
};
