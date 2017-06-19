var animation_number = 0;
var animations = [];

$(document).keydown(function(event) {
    key_event('down', event);
//    console.log('down ' + event.keyCode);
});
/*
$(document).keypress(function(event) {
    console.log('press ' + event.keyCode);
});
$(document).keyup(function(event) {
    console.log('up ' + event.keyCode);
});
*/

function key_event(type, event) {
    console.log('Handler for ' + type + ' called. - ' + event.keyCode);
    var code = event.keyCode;
    if (code == 8 || code == 37) {
        event.preventDefault();
        previous_step();
    }
    else if (code == 32 || code == 39) {
        event.preventDefault();
        next_step();
    }
    else if (code == 33) {
        event.preventDefault();
        previous_page();
    }
    else if (code == 34) {
        event.preventDefault();
        goto_next_page();
    }
    else if (code == 38) {
        event.preventDefault();
        goto_index();
    }
}

function register_animation(id, num, type) {
    animations[num-1] = { "type" : type, "id" : id };
}
function previous_step() {
    previous_page();
}
function next_step() {
    console.log(animation_number);
    var ani = animations[animation_number];
    if (animation_number < animations.length) {
        next_animation();
        return;
    }
    goto_next_page();
}
function goto_next_page() {
    location.href = next_page;
}
function previous_page() {
    location.href = prev_page;
}
function goto_index() {
    location.href = 'index.html';
}
function next_animation() {
    var ani = animations[animation_number];
    animation_number++;
    if (! ani) {
        next_step();
        return;
    }
    console.log(ani);
    var type = ani["type"];
    var id = ani["id"];
    console.log(id);
    var elem = $('#' + id);
    if (type == 'appear') {
        elem.hide();
        elem.fadeIn(400);
    }
    else if (type == 'flyin') {
        var currWidth = $(window).width();
        var margin = elem.css('margin-left');
        elem.css('margin-left', currWidth + 'px');
        elem.show();
        elem.animate({"margin-left": margin}, 400);
    }
}

