EXEC := test
ROOT := ../../
ARGS := -I../../src

SRC1 :=	 $(wildcard $(ROOT)*.cpp) \
		 $(wildcard $(ROOT)*/*.cpp) \
		 $(wildcard $(ROOT)*/*/*.cpp) \
		 $(wildcard $(ROOT)*/*/*/*.cpp) \
		 $(wildcard $(ROOT)*/*/*/*/*.cpp)

SRC2 :=  $(wildcard $(ROOT)*.c) \
		 $(wildcard $(ROOT)*/*.c) \
		 $(wildcard $(ROOT)*/*/*.c) \
		 $(wildcard $(ROOT)*/*/*/*.c) \
		 $(wildcard $(ROOT)*/*/*/*/*.c)

OBJS := $(SRC2:$(ROOT)%.c=obj/%.o)
OBJS += $(SRC1:$(ROOT)%.cpp=obj/%.o)


all:$(OBJS)
	@echo [M]Link...
	@mkdir -p bin
	g++ $(OBJS) -o bin/$(EXEC) $(ARGS) -L/usr/local/lib/ -lGL -lGLU -lX11 


obj/%.o:$(ROOT)%.cpp
	@echo [M]Compile CXX...
	@mkdir -p $(@D)
	g++ -c $< -o $@ $(ARGS)

obj/%.o:$(ROOT)%.c
	@echo [M]Compile C...
	@mkdir -p $(@D)
	g++ -c $< -o $@ $(ARGS)

run: all
	./bin/$(EXEC)

test:
	@echo $(OBJS)

clean:
	rm -rf bin
	rm -rf obj
	rm -rf out















