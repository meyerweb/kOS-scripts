run once "common_lib.ks".
clearvecdraws().

set sc to 10.

set controlpart to ship:controlpart.

triple(v(0,0,0), ship:facing, RGBA(1,0,0,1)).
triple(controlpart:position, controlpart:facing, RGBA(0,0,1,1)).
triple(controlpart:position, controlpart:portfacing, RGBA(0,1,0,1)).


declare function triple {
    parameter position.
    parameter direction.
    parameter color is RGBA(1,0,1,1).

    drawvec(position, direction:vector:normalized, color, "F").
    drawvec(position, (direction * R (-90, 0, 0)):vector:normalized, color, "U").
    drawvec(position, (direction * R (0, 90, 0)):vector:normalized, color, "S").
}


declare function drawvec {
    parameter startpoint is v(0,0,0).
    parameter vector is v(0,0,0).
    parameter color is RGBA(1,1,1,0.5).
    parameter label is "".
    parameter scale is 1.
    parameter size is 0.33.
    parameter show is TRUE.

    VECDRAW(
        startpoint,
        vector * sc,
        color,
        label,
        scale,
        show,
        size  
    ).

}