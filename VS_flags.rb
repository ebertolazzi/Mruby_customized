VSFLAGS_DEFINE  = %w(/D_WINDOWS /D_SCL_SECURE_NO_WARNINGS /DHAVE_STRING_H /DNO_GETTIMEOFDAY /DYAML_DECLARE_STATIC /DPCRE_STATIC)
VSFLAGS_COMMON  = %w(/nologo /GS /W3 /WX- /Gm- /fp:precise /EHsc) # /FS /Gd /sdl
VSFLAGS_CXX     = []
VSFLAGS_R       = %w(/O2 /MD)
######  /RTC1
VSFLAGS_D       = %w(/Od /Ob0 /MDd /Z7 /D_DEBUG /DMECHATRONIX_DEBUG)
VSFLAGS_RELEASE = VSFLAGS_COMMON + VSFLAGS_DEFINE + VSFLAGS_R
VSFLAGS_DEBUG   = VSFLAGS_COMMON + VSFLAGS_DEFINE + VSFLAGS_D

CLANG_COMMON   = %w(-fPIC -Weverything -Wno-weak-vtables -Wno-implicit-fallthrough -Wno-float-equal -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-padded -Wno-reserved-id-macro)
CLANG_CXX      = %w(-std=c++11 -stdlib=libc++)
CLANG_R        = %w(-msse4.2 -msse4.1 -mssse3 -msse3 -msse2 -msse -mmmx -funroll-loops -O2 -g0)
CLANG_D        = %w(-O0 -gfull -DMECHATRONIX_DEBUG -DDEBUG)
CLANG_RELEASE  = CLANG_COMMON + CLANG_R
CLANG_DEBUG    = CLANG_COMMON + CLANG_D

GCC_COMMON   = %w(-fPIC -m64 -Wall -Wno-float-equal -Wno-padded)
GCC_CXX      = %w(-std=c++11)
GCC_R        = %w(-msse4.2 -msse4.1 -mssse3 -msse3 -msse2 -msse -mmmx -funroll-loops -O2 -g0)
GCC_D        = %w(-O0 -g3 -DMECHATRONIX_DEBUG -DDEBUG)
GCC_RELEASE  = GCC_COMMON + GCC_R
GCC_DEBUG    = GCC_COMMON + GCC_D

#-m32 -m64 --debug -gdwarf /D_CRT_SECURE_NO_DEPRECATE /D_CRT_SECURE_NO_WARNINGS
