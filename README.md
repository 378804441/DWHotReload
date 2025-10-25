每次从开发Flutter开发切回到原生开发时候最不习惯的就是原生没有热重载功能。
简单地调一下字体颜色，view大小都要重新编译，既耗时又费力。

所以想了一下可不可以让原生开发也可以享受到热重载功能，在UI调试下可以做到 "即写即看"。

iOS端的热更新主要可以分成俩大块。

一种是基于JSCore。
它建立起了Objective-C 与 JavaScript通的桥梁。
代表框架有，React Native， Weex，JSPatch  等等优秀框架。

还有一种是更为小众一些的。
自己实现了一个 OC 语法的简单解释器，包含了基础的词法分析与语法分析，从而能够在运行期将 OC 代码生成抽象语法树 AST 然后进行执行。再通过 runtime 进行方法替换 方法添加等操作，进而实现了动态化的效果。
代表框架有，OCEval, OCRunner 等框架 (据我观察貌似都是独立开发者，目前暂时还无法做到商用级别。但也可以拿他们的基础框架进行魔改，大部分基础工作已经做完了)。

React Native 与 Weex 比较重，需要项目级支持。
JSPatch 是需要下发js代码进行热修复，虽然可以满足需求，但弊端也比较明显，那就是需要将OC代码强行翻译成JS语法，大段落使用时候不是很方便。
用OC语法解释器，虽然可以做到OC代码不转译, 但还是需要对框架做一些魔改才可以按照自己习惯方便使用  (自己做语法分析, 生成抽象语法树 这块还是值得研究的。理论上可以做到 下发OC代码, 可以基于 解释器+runtime 做到整个app都动态化)。

我设想的场景是只是在debug环境下，即写即看。
线上修复不想打擦边球, 以及引入一些不可靠的因素。
所以才去的方案是通过动态库来在开发阶段做到动态化。

众所周知Objective-C 这门语言天生具有动态性，可以任意的在运行时替换方法, 成员变量等等。那这样就联想到可不可以下发动态库，在运行时加载这个动态库并替换新加载进来的动态库里类对象/元类对象的一些信息。这样就可以再开发环境下做到 "即写即看"的效果。

![2819245-013aeec97c724cf5](https://github.com/user-attachments/assets/87f70991-b221-4456-a14b-e30e172b4ee7)

实践
<img width="1500" height="242" alt="image" src="https://github.com/user-attachments/assets/17c8cdd8-d81b-40d0-868a-bb9d5992ef08" />
项目搭建
项目分俩部分。

第一部分:  macOS项目(监听热重载项目文件变化)

第二部分:  iOS项目(热重载目标项目)

第一部分 （监听文件变化项目）
首先我们需要有一个mac端程序监听指定文件夹下文件的变化，从而将保存变化后的.m文件通过运行预先编写好的 shell脚本进行 编译 成 .o 文件并打包成 一个dylib，发送给app。

shell脚本整体流程思路 ：
1) 接收 要编译的 .m 文件路径 以及 .m引用的其他类的 .o文件路径 (这一步是生成动态库必要的，不然会因为LinkFileList 引用出错而无法编译出一个dylib)
2) 通过clang 先将 .m 编译成 .o 并储存起来
3) 再将重新编译后的 .o 文件编译成dylib
4) 这时候可以多加一个参数判断是向真机还是模拟器发送动态库。如果向真机发送的话需要做个签名操作，不然真机无法dlopen 这个 dylib
5) 向目标传输编译好的dylib

<img width="1500" height="1028" alt="image" src="https://github.com/user-attachments/assets/ccf37908-f724-4392-bb72-26eb837740ab" />
监听软件部分

这部分可以通过 FSEventStream 来实现监听文件变化。
shell脚本方面可以使用 NSTask 来执行脚本名。
* 我是在这里生成了LinkFileList。是从变化文件字符串中提取出 引入文件并遍历拼接成一个有效 依赖链接。不知道有没有更好的方法生成该文件需要依赖的 LinkFileList。
<img width="960" height="596" alt="image" src="https://github.com/user-attachments/assets/610c7142-bdcd-441f-8dfa-919764ac1b27" />

这里勾选中真机 并 键入手机ip地址将会热重载手机端app。解除勾选将会热重载模拟器。这样的话俩者都可以兼顾了。

第一个部分这样就差不多可以了。

第二部分 （热重载目标项目)
首先项目里面要搭建一个http服务，我们这里选择的是用 GCDWebServer。

GCDWebServer 是一个基于GCD 可以用于macOS & iOS 上的一个轻量的HTTP server，该库实现了基于web的文件上传等功能。

然后要开始编写解析mac上编译并连接好的dylib了。

① 通过 dlopen 打开传进来的 dylib
    dlopen(dylibPatch,RTLD_NOW)
② 获取内存中所有镜像
    int32_t images= _dyld_image_count();    // 所有内存中镜像
③ 循环镜像获取刚刚注入的动态库镜像。(这个步骤是必须的，不然会踩坑)
        for(uint32_ti =0; i < images; i++) {
            pszModName =_dyld_get_image_name(i);
            if(!strcmp(pszModName, dylibPatch)){  // 判断镜像地址是否与传进来的dylib地址一致           
                base  = (void*)_dyld_get_image_header(i);
                slide =_dyld_get_image_vmaddr_slide(i);
            }
        }
④ 获取注入动态库结构体地址
        Dl_infoinfo;
        dladdr((mach_header_t*)base, &info);
        machHeader1 = (structmach_header_64*)info.dli_fbase;
⑤ mach-O 文件里面的 class列表信息存在Data断。获取data段 classList 信息 (这个节列出了所有的class，包括元类对象)
        uint64_tsize =0;
        char*referencesSection =getsectdatafromheader_64(machHeader1,            "__DATA","__objc_classlist", &size );
<img width="1500" height="1367" alt="image" src="https://github.com/user-attachments/assets/254ce97f-5d2a-476e-884a-69b781cca82b" />

⑥ 获取注入dylib 类对象
    Class class = classReferences[i];
⑦ 对象替换
    // 获取要替换类名称
    constchar*className = class_getName(newClass);
    // 获取当前内存中类对象
    Class oldClass = objc_getClass(className);
    // 判断是否是注入进来的类对象
    if  ( newClass != oldClass ) {
        开始进行方法替换
    }
⑧ 删除掉传上来的动态库
    [[NSFileManager defaultManager] removeItemAtPath:patch error:nil];
⑨ 发送广播
    dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DWHotReload" object:nil];
    });
   * 这一步可以优化成通过消息转发来调用。demo图省事直接发了个广播

待解决问题
上述步骤就是个大概的一个解析流程。
如果想要做到真正项目应用级的话，需要润色点是shell脚本, 引用三方库时候链接编译问题。
支持swift。

期待最后的落地场景
最终期望落地是，测试的同学在debug页面开启接收dylib开关，开发同学只要本地修复问题后直接下发dylib，直接在测试同学设备上修正好。 因为是直接编写的OC/swift 代码所以，不会像是使用jspatch 需要最终回归一下正式代码。这条路很漫长。。。 慢慢走。

推荐框架
强烈推荐injection的框架。oc项目无侵入的可以直接热重载。但swift 项目在有些bridge时候会发生异常。

误区
网上很多文章都再说dlopen只能在模拟器上使用，其实并不正确的。
真机上无法dlopen加载dylib，大体是犯了俩个错误。
一，编译时target依赖的是x86架构
二，打包成dylib后没有做有效签名
如果这俩点都做了其实dylib可以在真机上dlopen加载成功 (逆向开发后的插件就是dylib，它能注入到真机二进制文件里咱们自己的也必然可以)

* 本demo也参考了部分injection思路，并使用了该工程里的方法互换方法。




