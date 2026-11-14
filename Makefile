# laser-gimbal build: every parts/<name>.scad -> stl/<name>.stl, then validate.
#   make            all STLs + checks
#   make stl/base.stl
#   make check      validate existing STLs
#   make renders    assembly PNGs
#   make interference
#   make viewer     meshes for the browser viewer (viewer/meshes/)
#   make view       serve the viewer at http://localhost:8000
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

# preview (OpenCSG) renders: keep per-part colours; a CGAL --render of the whole
# machine (3 herringbones) takes many minutes and drops the colours
RENDER := $(OPENSCAD) -q --imgsize=1400,1100 --colorscheme=Tomorrow
renders: assembly.scad $(PARTS) $(LIBS)
	@mkdir -p renders
	$(RENDER) -o renders/assembly_front.png -D pan=-20 -D tilt=15 --camera=0,0,100,62,0,115,680 assembly.scad
	$(RENDER) -o renders/assembly_side.png -D pan=0 -D tilt=45 -D show_beam_stop=true --camera=0,0,100,80,0,90,700 assembly.scad
	$(RENDER) -o renders/exploded.png -D explode=1 -D pan=-20 --camera=0,0,225,72,0,130,1400 assembly.scad

interference:
	bash tools/interference.sh

VIEWER_OBJS := tools/viewer_objs.scad assembly.scad $(PARTS) $(LIBS)
viewer: viewer/meshes/kinematics.json
viewer/meshes/kinematics.json: $(VIEWER_OBJS) tools/export_viewer.sh tools/stl2bin.py
	bash tools/export_viewer.sh

view: viewer/meshes/kinematics.json
	@echo "open http://localhost:8000  (Ctrl+C to stop)"
	cd viewer && python3 -m http.server 8000 --bind 127.0.0.1

clean:
	rm -f stl/*.stl

.PHONY: all check renders interference viewer view clean
