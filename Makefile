# laser-gimbal build: every parts/<name>.scad -> stl/<name>.stl, then validate.
#   make            all STLs + checks
#   make stl/base.stl
#   make check      validate existing STLs
#   make renders    assembly PNGs
#   make interference
OPENSCAD ?= openscad
PARTS := $(wildcard parts/*.scad)
STLS  := $(patsubst parts/%.scad,stl/%.stl,$(PARTS))
LIBS  := $(wildcard lib/*.scad)

all: $(STLS) check

stl/%.stl: parts/%.scad $(LIBS)
	@mkdir -p stl
	$(OPENSCAD) -q -o $@ $<

check: $(STLS)
	python3 -I tools/check_stl.py $(STLS)

renders: assembly.scad $(PARTS) $(LIBS)
	@mkdir -p renders
	$(OPENSCAD) -q -o renders/assembly_front.png --imgsize=1400,1100 --colorscheme=Tomorrow --render=1 \
		-D pan=25 -D tilt=15 --camera=0,0,110,62,0,40,620 assembly.scad
	$(OPENSCAD) -q -o renders/assembly_side.png --imgsize=1400,1100 --colorscheme=Tomorrow --render=1 \
		-D pan=0 -D tilt=45 --camera=0,0,110,80,0,90,620 assembly.scad
	$(OPENSCAD) -q -o renders/exploded.png --imgsize=1400,1100 --colorscheme=Tomorrow --render=1 \
		-D explode=1 --camera=0,0,160,62,0,40,900 assembly.scad

interference:
	bash tools/interference.sh

clean:
	rm -f stl/*.stl

.PHONY: all check renders interference clean
