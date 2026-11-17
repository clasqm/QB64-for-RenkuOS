
ifeq ($(OS),hai)
	# Haiku provides GLUT in the base system (libglut). The modified FreeGLUT
	# bundled here is X11/Win32 only, so it is not built on Haiku; GLEW is
	# compiled directly into libqb.cpp instead.
	QB_CORE_LIB :=
	GLEW_OBJS :=
else

FREEGLUT_SRCS := $(wildcard $(PATH_INTERNAL_C)/parts/core/src/*.c)
FREEGLUT_OBJS := $(FREEGLUT_SRCS:.c=.o)

FREEGLUT_LIB := $(PATH_INTERNAL_C)/parts/core/src.a

$(PATH_INTERNAL_C)/parts/core/src/%.o: $(PATH_INTERNAL_C)/parts/core/src/%.c
	$(CC) -O2 -c $< -o $@

$(FREEGLUT_LIB): $(FREEGLUT_OBJS)
	$(AR) rcs $@ $(FREEGLUT_OBJS)

QB_CORE_LIB := $(FREEGLUT_LIB)

CLEAN_LIST += $(FREEGLUT_LIB) $(FREEGLUT_OBJS)

endif

