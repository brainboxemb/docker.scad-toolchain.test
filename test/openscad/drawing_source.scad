// Minimal source geometry for the external drawing-publication contract.
$fn = 48;

difference() {
    square([40, 25], center = true);
    circle(d = 8);
}

translate([0, 18])
    text("SOURCE", size = 4, halign = "center");
