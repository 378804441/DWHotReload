//
//  main.m
//  DWDebugHR
//
//  Created by 丁巍 on 2020/12/27.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MachOCheck.h"
#import "BundleInjection.h"

#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <mach-o/getsect.h>




#ifndef __LP64__
#define mach_header mach_header
#else
#define mach_header mach_header_64
#endif


const struct mach_header *machHeader = NULL;
static NSString *configuration = @"/Users/dingwei/Desktop/自研/DWDebugHR/DWDebugHR/dw6.dylib";



static NSArray<NSString *>* BHReadConfiguration()
{
    NSMutableArray *configs = [NSMutableArray array];
    
    Dl_info info;
    dladdr((__bridge const void *)(configuration), &info);
    
#ifndef __LP64__
    // const struct mach_header *mhp = _dyld_get_image_header(0); // both works as below line
    const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
    unsigned long size = 0;
    // 找到之前存储的数据段(Module找BeehiveMods段 和 Service找BeehiveServices段)的一片内存
    uint32_t *memory = (uint32_t*)getsectiondata(mhp, "__DATA",  "__objc_classlist", & size);
#else /* defined(__LP64__) */
    const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
    unsigned long size = 0;
    uint64_t *memory = (uint64_t*)getsectiondata(mhp, "__DATA",  "__objc_classlist", & size);
#endif /* defined(__LP64__) */
    
    // 把特殊段里面的数据都转换成字符串存入数组中
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
        char *string = (char*)memory[idx];
        
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        
        if(str) [configs addObject:str];
    }
    
    return configs;
}



typedef struct {
    void*                       vTable;
    const char*                    fPath;
    const char*                    fRealPath;
    dev_t                        fDevice;
    ino_t                        fInode;
    time_t                        fLastModified;
    uint32_t                    fPathHash;
    uint32_t                    fDlopenReferenceCount;    // count of how many dlopens have been done on this image
    void*                fInitializerRecursiveLock;
    uint16_t                    fDepth;
    uint16_t                    fLoadOrder;
    uint32_t                    fState : 8,
                                fLibraryCount : 10,
                                fAllLibraryChecksumsAndLoadAddressesMatch : 1,
                                fLeaveMapped : 1,        // when unloaded, leave image mapped in cause some other code may have pointers into it
                                fNeverUnload : 1,        // image was statically loaded by main executable
                                fHideSymbols : 1,        // ignore this image's exported symbols when linking other images
                                fMatchByInstallName : 1,// look at image's install-path not its load path
                                fInterposed : 1,
                                fRegisteredDOF : 1,
                                fAllLazyPointersBound : 1,
                                fMarkedInUse : 1,
                                fBeingRemoved : 1,
                                fAddFuncNotified : 1,
                                fPathOwnedByImage : 1,
                                fIsReferencedDownward : 1,
                                fWeakSymbolsBound : 1;
    uint64_t                                fCoveredCodeLength;
    const uint8_t*                            fMachOData;
    const uint8_t*                            fLinkEditBase; // add any internal "offset" to this to get mapped address
    uintptr_t                                fSlide;
    uint32_t                                fEHFrameSectionOffset;
    uint32_t                                fUnwindInfoSectionOffset;
    uint32_t                                fDylibIDOffset;
    uint32_t                                fSegmentsCount : 8,
                                            fIsSplitSeg : 1,
                                            fInSharedCache : 1,
#if TEXT_RELOC_SUPPORT
                                            fTextSegmentRebases : 1,
                                            fTextSegmentBinds : 1,
#endif
#if __i386__
                                            fReadOnlyImportSegment : 1,
#endif
                                            fHasSubLibraries : 1,
                                            fHasSubUmbrella : 1,
                                            fInUmbrella : 1,
                                            fHasDOFSections : 1,
                                            fHasDashInit : 1,
                                            fHasInitializers : 1,
                                            fHasTerminators : 1,
                                            fNotifyObjC : 1,
                                            fRetainForObjC : 1,
                                            fRegisteredAsRequiresCoalescing : 1,     // <rdar://problem/7886402> Loading MH_DYLIB_STUB causing coalescable miscount
                                            fOverrideOfCacheImageNum : 12;

                                            
//    static uint32_t                    fgSymbolTableBinarySearchs;
} MachoImage;


int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
  
//    MachoImage* image = (MachoImage*)dlopen("/Users/dingwei/Desktop/自研/DWDebugHR/DWDebugHR/libDWHotReload.dylib",RTLD_NOW);
    
    char *dylibPatch = "/Users/dingwei/Desktop/自研/DWDebugHR/DWDebugHR/dw6.dylib";
    if (dlopen(dylibPatch, RTLD_NOW) != nil) {
        int32_t nModNums= _dyld_image_count();
        const char *pszModName = NULL;
        void* base;
        long slide;
        for (uint32_t i = 0; i < nModNums; i++)
        {
            pszModName = _dyld_get_image_name(i);
            if(!strcmp(pszModName, dylibPatch)){
                base  = (void*)_dyld_get_image_header(i);
                slide = _dyld_get_image_vmaddr_slide(i);
            }

        }
        
        uintptr_t cur = (uintptr_t)base + sizeof(mach_header_t);
        
        unsigned long byteCount = 0;

        if (machHeader == NULL)
        {
            Dl_info info;
            dladdr((mach_header_t*)base, &info);
            machHeader = (struct mach_header_64*)info.dli_fbase;
            
            uint64_t size = 0;
            char *referencesSection = getsectdatafromheader_64(machHeader,
                                                               "__DATA", "__objc_classlist", &size );
            
            unsigned int count;
            const char **classes;
            classes = objc_copyClassNamesForImage(info.dli_fname, &count);
            
            Class *classReferences = (Class *)(void *)((char *)info.dli_fbase+(uint64_t)referencesSection);
            for (int i = 0; i < count; i++) {
                Class testClass = classReferences[i];
                NSLog(@"%@", testClass);
                Class newClass = [BundleInjection loadedClass:testClass notify:false];
                if ([[[newClass alloc] init] respondsToSelector:@selector(print)]) {
                    SEL startEngine = NSSelectorFromString(@"print");
                    [[[newClass alloc] init] performSelector:startEngine];
                }
            }
        }
    }
    
    
   
    
//    NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
//    Class testClass2    = NSClassFromString(className);
//
//    uintptr_t* data = (uintptr_t *) getsectiondata(machHeader, "__DATA", "__objc_classlist", &byteCount);
//    NSUInteger counter = byteCount/sizeof(void*);
//    for(NSUInteger idx = 0; idx < counter; ++idx)
//    {
////
//        Class1 cls =(Class1)data[idx];
////        cls->superclass;
////        printf("~~~~~~   %s", cls);
////        if (cls != NULL) {
////
////        }
//
////        NSLog(@"class:%@",  data[idx]);
////        if (data[idx] != NULL) {
//////
//////
////        }
//
//    }
    
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

