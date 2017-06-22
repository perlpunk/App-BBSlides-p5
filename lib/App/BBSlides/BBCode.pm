use strict;
use warnings;
package App::BBSlides::BBCode;

use base qw/ Parse::BBCode /;

my %colors = (
    aqua    => 1,
    black   => 1,
    blue    => 1,
    fuchsia => 1,
    gray    => 1,
    grey    => 1,
    green   => 1,
    lime    => 1,
    maroon  => 1,
    navy    => 1,
    olive   => 1,
    purple  => 1,
    red     => 1,
    silver  => 1,
    teal    => 1,
    white   => 1,
    yellow  => 1,
);

my %default_tags = (
    'h1'    => '<h1 id="node_%id" class="bbslides-h1">%s</h1>',
    'title' => '<h1 id="node_%id" class="bbslides-h1">%s</h1>',
    'color' => '<span id="node_%id" style="color: %{htmlcolor}a">%s</span>',
    'bgcolor' => '<span id="node_%id" style="background-color: %{htmlcolor}a">%s</span>',
    codebox => {
        parse => 1,
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            my $id = $tag->get_id;
            if ($info->{tags}->{codebox}) {
                $$content =~ s/<br>$//gm;
            }
            my $html = <<"EOM";
<div id="node_$id" class="codebox">$$content</div>
EOM
            return $html;
        },
    },
    codeboxsmall => {
        parse => 1,
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            my $id = $tag->get_id;
            if ($info->{tags}->{codeboxsmall}) {
                $$content =~ s/<br>$//gm;
            }
            my $html = <<"EOM";
<div id="node_$id" class="codebox codeboxsmall">$$content</div>
EOM
            return $html;
        },
    },
    'tab' => '<span id="node_%id" class="bbslides-tab">%s</span>',
    'trspace' => '<span id="node_%id" class="bbslides-trspace">%s</span>',
    'indent' => '<span id="node_%id" class="bbslides-indent">%s</span>',
    'comment' => '<span id="node_%id" class="bbslides-comment">%s</span>',
    'anchor' => '<span id="node_%id" class="bbslides-anchor">%s</span>',
    'alias' => '<span id="node_%id" class="bbslides-alias">%s</span>',
    'horizontal' => '<div id="node_%id" class="bbslides-horizontal">%s</div>',
    'span' => '<span id="node_%id">%s</span>',
    'div' => '<div id="node_%id">%s</div>',
);

my %default_escapes = (
    htmlcolor => sub {
        my $color = $_[2];
        ($color =~ m/^(?:#[0-9a-fA-F]{6})\z/ || exists $colors{lc $color})
        ? $color : 'inherit'
    },
);

my %optional_tags = (
);

sub defaults {
    my ($class, @keys) = @_;
    return @keys
        ? (map { $_ => $default_tags{$_} } grep { defined $default_tags{$_} } @keys)
        : %default_tags;
}

sub default_escapes {
    my ($class, @keys) = @_;
    return @keys
        ? (map { $_ => $default_escapes{$_} } grep  { defined $default_escapes{$_} } @keys)
        : %default_escapes;
}

sub optional {
    my ($class, @keys) = @_;
    return @keys
        ? (map { $_ => $optional_tags{$_} } grep  { defined $optional_tags{$_} } @keys)
        : %optional_tags;
}



1;
