use strict;
use warnings;
use 5.010;
package App::BBSlides;

use File::Share qw/ dist_dir /;
use App::BBSlides::BBCode;
use IO::All;
use File::Copy qw/ copy /;
use Encode;
use HTML::Entities qw/ encode_entities /;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/ slides output source bbc datadir htmldatadir /);

my $help = <<"EOM";
<span id="usage">next: ( space or -&gt; ) | previous: ( backspace or &lt;- ) |
next page: ( page down ) | previous page: ( page up ) |
index: ( arrow-up )</span>
EOM

sub write {
    my ($self) = @_;
    my $output = $self->output;
    my $slides = $self->slides;
    my $source = $self->source;
    my $datadir = $self->datadir;
    my $p = App::BBSlides::BBCode->new({
        linebreaks => 0,
        datadir => $self->datadir,
        tags => {
            Parse::BBCode::HTML->defaults(qw/
                b i p size list * html url noparse img
            /),
            App::BBSlides::BBCode->defaults,
        },
        escapes => {
            Parse::BBCode::HTML->default_escapes,
            App::BBSlides::BBCode->default_escapes,
        },
        attribute_quote => q/'"/,
    });
    $self->bbc($p);

    $self->copy_static($output);
    for my $i (0 .. $#$slides) {
        $self->generate_slide(num => $i + 1, slide => $slides->[$i], max => scalar @$slides);
    }
    $self->generate_index(max => scalar @$slides, slides => $slides);
    $self->generate_source($source);
    $self->copy_static($output);

}

sub generate_slide {
    my ($self, %args) = @_;
    my $output = $self->output;
    my $p = $self->bbc;
    my $slide = $args{slide};
    my $i = $args{num};
    my $max = $args{max};
    my $title = $slide->{title};
    my $code = $slide->{content};
    my $tree = $p->parse($code);
    if (my $error = $p->error) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$error], ['error']);
        my $tree = $p->get_tree;
        my $corrected = $tree->raw_text;
        die "error: $corrected";
    }
    my $script = '';
    $tree->walk( bfs => sub {
        my ($tag) = @_;
        my $content = $tag->get_content;
        if ($tag->get_name eq 'title') {
            if (@$content == 1 and $content->[0] eq '') {
                $content->[0] = $title;
            }
        }
        my %attributes = map { defined $_->[1] ? ($_->[0] => $_->[1]) : ('' => $_->[0] )} @{ $tag->{attr} };
        my $id = $tag->get_id;
        my $name = $tag->get_name;
        if (keys %attributes) {
            if (my $ani = $attributes{animation}) {
                if ($tag->get_name eq 'list') {
                    my ($num, $type, $args) = split m/,/, $ani, 3;
                    for my $n (@$content) {
                        if (ref $n and $n->get_name eq '*') {
                            $num++;
                            my $attr = $n->get_attr;
                            $args //= '';
                            push @$attr, [ animation => "$num,$type,$args" ];
                        }
                    }
                }
                else {
                    my ($num, $type, $args) = split m/,/, $ani, 3;
                    $args ||= '{}';
                    $script .= <<"EOM";
register_animation('node_$id', $num, '$type', $args);
EOM
                }
            }
        }
        return 0;
    });
    my $html = $p->render_tree($tree);

    my $next = sprintf "slide%03d.html", $i + 1;
    my $prev = sprintf "slide%03d.html", $i - 1;
    if ($i == 1) {
        $prev = "index.html";
    }
    if ($i == $max) {
        $next = "index.html";
    }
    my $page = <<"EOM";
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="Cache-Control" content="no-store" />
<title>$title</title>
<link rel="prev" href="$prev" />
<link rel="next" href="$next" />
<script src="js/jquery-3.1.1.min.js"></script>
<script src="js/bbslides.js"></script>
<script src="js/navi.js"></script>
<link rel="stylesheet" type="text/css" href="css/slides.css">
<link rel="stylesheet" type="text/css" href="css/ansicolor.css">
</head>

<body>
<!--
<div id="test"></div>
-->
<div id="bbslides-slide" class="bbslides-frame">
$html
</div>
<script type="text/javascript">
$script
var prev_page = '$prev';
var next_page = '$next';
</script>
<div id="bbslides-navi">
Slide $i/$max
<a href="$prev" onclick="previous_step();return false">BACK</a>
<a href="index.html">UP</a>
<a href="$next" onclick="next_step(); return false">NEXT</a>
$help
<br>
<progress id="slide-progress" value="$i" max="$max"></progress>
</div>
</body>
</html>
EOM
    my $filename = sprintf "$output/slide%03d.html", $i;
    say "Generated $filename";
    io($filename)->utf8->print($page);

}

sub generate_index {
    my ($self, %args) = @_;
    my $output = $self->output;

    my $slides = $args{slides};
    my $list;
    for my $i (0 .. $#$slides) {
        my $num = $i + 1;
        my $slide = $slides->[ $i ];
        my $title = $slide->{title};
        my $filename = sprintf "slide%03d.html", $num;
        $list .= qq{<li><a href="$filename">$num - $title</a></li>\n};
    }
    my $first = sprintf "slide%03d.html", 1;
    my $index = <<"EOM";
<html><head><title>Presentation</title>
<meta charset="utf-8">
<script src="js/jquery-3.1.1.min.js"></script>
<script src="js/bbslides.js"></script>
<link rel="stylesheet" type="text/css" href="css/slides.css">
<script type="text/javascript">
var next_page = '$first';
</script>
</head>
<body>
<div class="bbslides-frame">
<ul>
$list
<li><a href="source.yaml">YAML/BBCode Source for this presentation</a></li>
</ul>
</div>
<div id="bbslides-navi">
<a href="$first" onclick="next_step()">NEXT</a>
$help
</div>
</body>
</html>
EOM
    my $filename = "$output/index.html";
    say "Generated $filename";
    io($filename)->print($index);
}

sub generate_source {
    my ($self, $file) = @_;
    my $output = $self->output;
    copy($file, "$output/source.yaml");
}

sub copy_static {
    my ($self, $output) = @_;
    mkdir $output;
    mkdir "$output/js";
    mkdir "$output/css";
    my $share = dist_dir("App-BBSlides");
    system("cp $share/js/*.js $output/js/");
    system("cp $share/css/*.css $output/css/");
    my $datadir = $self->datadir;
    my $htmldatadir = $self->htmldatadir;
    if ($htmldatadir) {
        mkdir "$output/data";
        system("cp $htmldatadir/* $output/data/");
    }
}
1;
