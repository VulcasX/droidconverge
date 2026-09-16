#!/bin/bash

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var p=panels()[0];
var drawers=p.widgets().filter(function(w){
    return w.type==="p-connor.plasma-drawer";
});

if(drawers.length > 0) {
    drawers.forEach(function(w){
        print("Toggle: Desktop mode, rimuovo Drawer ID="+w.id);
        w.remove();
    });
    p.height=46;
    print("Toggle: DESKTOP MODE");
} else {
    p.height=64;
    var w=p.addWidget("p-connor.plasma-drawer");
    print("Toggle: TABLET MODE, Drawer ID="+w.id);
}
'
