//
// NopSCADlib Copyright Chris Palmer 2018
// nop.head@gmail.com
// hydraraptor.blogspot.com
//
// This file is part of NopSCADlib.
//
// NopSCADlib is free software: you can redistribute it and/or modify it under the terms of the
// GNU General Public License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// NopSCADlib is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with NopSCADlib.
// If not, see <https://www.gnu.org/licenses/>.
//

//
//! Bill Of Materials generation via echo and the `bom.py` script. Also handles exploded assembly views and posing.
//! Assembly instructions can precede the module definition that makes the assembly.
//!
//! Assembly views shown in the instructions can be large or small and this is deduced by looking at the size of the printed parts involved and if any routed
//! parts are used.
//! This heuristic isn't always correct, so the default can be overridden by setting the `big` parameter of `assembly` to `true` or `false`.
//!
//! Setting the `ngb` parameter of `assembly` to `true` removes its column from the global BOM and merges it parts into its parent assembly column of the global BOM.
//! This is to prevent the global BOM page becoming too wide in large projects by having it include just the major assemblies.
//!
//! The example below shows how to define a vitamin and incorporate it into an assembly with sub-assemblies and make an exploded view.
//! The resulting flat BOM is shown but hierarchical BOMs are also generated for real projects.
//!
//! If the code to make an STL, DXF or SVG is made a child of the `stl()`, `dxf()` or `svg()` module then the STL, DXF or SVG will be used in the assembly views generated by `views.py` instead of generating
//! it with code.
//! This can speed up the generation of the build instructions greatly but isn't compatible with STLs that include support structures.
//!
//! The `pose()` module allows assembly views in the readme to be posed differently to the default view in the GUI:
//!
//! * Setting the `exploded` parameter to `true` allows just the exploded version to be posed and setting to `false` allows just the assembled view to be posed, the default is both.
//! * If the `d` parameter is set to specify the camera distance then the normal `viewall` and `autocenter` options are suppressed allowing a small section to be zoomed in to fill the view.
//! * To get the parameter values make the GUI window square, pose the view with the mouse and then copy the viewport parameters from the Edit menu and paste them into the pose invocation.
//! * Two `pose()` modules can be chained to allow different poses for exploded and assembled views.
//!
//! The `pose_stl()` module allows an STL child to be posed for its rendered image used in the readme for the project.
//
function bom_mode(n = 1) = (is_undef($bom) ? 0 : $bom) >= n && (is_undef($on_bom) || $on_bom);  //! Current BOM mode, 0 = none, 1 = printed and routed parts and assemblies, 2 includes vitamins as well
function exploded() = is_undef($exploded_parent) ? is_undef($explode) ? 0 : $explode : 0;   //! Returns the value of `$explode` if it is defined, else `0`
function show_supports() = !$preview || exploded();                 //! True if printed support material should be shown

module no_explode()                                                 //! Prevent children being exploded
    let($exploded_parent = true) children();

module explode(d, explode_children = false, offset = [0,0,0], show_line = true) {     //! Explode children by specified Z distance or vector `d`, option to explode grand children
    v = is_list(d) ? d : [0, 0, d];
    o = is_list(offset) ? offset : [0, 0, offset];
    if(exploded() && norm(v)) {
        if(show_line)
            translate(o)                                                // Draw the line first in case the child is transparent
                color("yellow") hull() {
                    sphere(0.2);

                    translate(v * exploded())
                        sphere(0.2);
                }

        translate(v * exploded())
            let($exploded_parent = explode_children ? undef : true)
                children();
    }
    else
        children();
}

module no_pose()                                                    //! Force children not to be posed even if parent is
    let($posed = true, $zoomed = undef) children();

module pose(a = [55, 0, 25], t = [0, 0, 0], exploded = undef, d = undef) //! Pose an assembly for rendering to png by specifying rotation `a`, translation `t` and optionally `d`, `exploded = true for` just the exploded view or `false` for unexploded only.
    let($zoomed = is_undef(d)
            ? is_undef($zoomed)
                ? undef
                : $zoomed
            : is_undef(exploded)
                ? 3
                : exploded
                    ? 2
                    : 1)
        if(is_undef($pose) || !is_undef($posed) || (!is_undef(exploded) && exploded != !!exploded()))
            children();
        else
            let($posed = true) // only pose the top level
                rotate([55, 0, 25])
                    translate_z(is_undef(d) ? 0 : 140 - d)
                        rotate([-a.x, 0, 0])
                            rotate([0, -a.y, 0])
                                rotate([0, 0, -a.z])
                                    translate(-t)
                                        children();

module pose_hflip(exploded = undef)       //! Pose an STL or assembly for rendering to png by flipping around the Y axis, `exploded = true for` just the exploded view or `false` for unexploded only.
    if(is_undef($pose) || !is_undef($posed) || (!is_undef(exploded) && exploded != !!exploded()))
        children();
    else
        let($posed = true) // only pose the top level
            hflip()
                children();

module pose_vflip(exploded = undef)       //! Pose an STL or assembly for rendering to png by flipping around the X axis, `exploded = true for` just the exploded view or `false` for unexploded only.
    if(is_undef($pose) || !is_undef($posed) || (!is_undef(exploded) && exploded != !!exploded()))
        children();
    else
        let($posed = true) // only pose the top level
            vflip()
                children();

module assembly(name, big = undef, ngb = false) {    //! Name an assembly that will appear on the BOM, there needs to a module named `<name>_assembly` to make it. `big` can force big or small assembly diagrams.
    if(bom_mode()) {
        zoom = is_undef($zoomed) ? 0 : $zoomed;
        arglist = str(arg(big, undef, "big"), arg(ngb, false, "ngb"), arg(zoom, 0, "zoomed"));
        args = len(arglist) ? str("(", slice(arglist, 2), ")") : "";
        echo(str("~", name, "_assembly", args, "{"));
    }
    no_pose()
        if(is_undef($child_assembly))
            let($child_assembly = true)
                children();
        else
            no_explode()
                children();

    if(bom_mode())
        echo(str("~}", name, "_assembly"));
}

module stl_colour(colour = pp1_colour, alpha = 1) { //! Colour an stl where it is placed in an assembly. `alpha` can be used to make it appear transparent.
    $stl_colour = colour;
    color(colour, alpha)
        children();
}

module pose_stl(a = [70, 0, 315], t = [0, 0, 0], d = 500) //! Pose an STL for its render, `a`, `t`, & `d` are camera parameters.
    let($stl_camera = str(t.x, ",", t.y, ",", t.z, ",", a.x, ",", a.y, ",", a.z, ",", d))
        children();

module stl(name) {                      //! Name an stl that will appear on the BOM, there needs to a module named `<name>_stl` to make it
    if(bom_mode() && is_undef($in_stl)) {
        colour = is_undef($stl_colour) ? pp1_colour : $stl_colour;
        camera = is_undef($stl_camera) ? "0,0,0,70,0,315,500" : $stl_camera;
        echo(str("~", name, ".stl(colour='", colour, "'| camera='", camera, "')" ));
    }
    if($children)
        if(is_undef($pose))
            let($in_stl = true, $cnc_bit_r = 0)
                children();
        else {
            path = is_undef($target) ? "/stls/" : str("/", $target, "/stls/");
            import(str($cwd, path, name, ".stl"));
        }
}

module dxf(name) {                      //! Name a dxf that will appear on the BOM, there needs to a module named `<name>_dxf` to make it
    if(bom_mode() && is_undef($in_dxf)) {
        if(is_undef($dxf_colour))
            echo(str("~", name, ".dxf"));
        else
            echo(str("~", name, ".dxf(colour='", $dxf_colour, "')"));
    }
    if($children)
        if(is_undef($pose))
            let($in_dfx = true)
                children();
        else {
            path = is_undef($target) ? "/dxfs/" : str("/", $target, "/dxfs/");
            import(str($cwd, path, name, ".dxf"));
        }
}

module svg(name) {                      //! Name an svg that will appear on the BOM, there needs to a module named `<name>_svg` to make it
    if(bom_mode() && is_undef($in_svg)) {
        if(is_undef($dxf_colour))
            echo(str("~", name, ".svg"));
        else
            echo(str("~", name, ".svg(colour='", $dxf_colour, "')"));
    }
    if($children)
        if(is_undef($pose))
            let($in_svg = true)
                children();
        else {
            path = is_undef($target) ? "/svgs/" : str("/", $target, "/svgs/");
            import(str($cwd, path, name, ".svg"));
        }
}

module use_stl(name)                //! Import an STL to make a build platter
    assert(false);                  // Here for documentation only, real version in core.scad

module use_dxf(name)                //! Import a DXF to make a build panel
    assert(false);                  // Here for documentation only, real version in core.scad

module use_svg(name)                //! Import an SVG to make a build panel
    assert(false);                  // Here for documentation only, real version in core.scad

function value_string(value) = is_string(value) ? str("\"", value, "\"") : str(value); //! Convert `value` to a string or quote it if it is already a string

function arg(value, default, name = "") =   //! Create string for arg if not default, helper for `vitamin()`
    value == default ? ""
                     : name ? str(", ", name, " = ", value_string(value))
                            : str(", ", value_string(value));

module vitamin(description) {                //! Describe a vitamin for the BOM entry and precede it with a module call that creates it, eg. "widget(42): Widget size 42"
    if(bom_mode(2))
        echo(str("~", description, !is_undef($hidden) ? " - not shown" : ""));
}

module not_on_bom(on = false)               //! Specify the following child parts are not on the BOM, for example when they are on a PCB that comes assembled
    let($on_bom = on)
        children();

module hidden()                             //! Make item invisible, except on the BOM
    scale(1 / sqr(1024))
        let($hidden = true)
            children();
