use strict;
use warnings;
package App::BBSlides::BBCode;

use base qw/ Parse::BBCode /;
__PACKAGE__->mk_accessors(qw/ datadir /);

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
    'h2'    => '<h2 id="node_%id" class="bbslides-h2">%s</h2>',
    'title' => '<h1 id="node_%id" class="bbslides-h1">%s</h1>',
    'color' => '<span id="node_%id" style="color: %{htmlcolor}a">%s</span>',
    'bgcolor' => '<span id="node_%id" style="background-color: %{htmlcolor}a">%s</span>',
    'codebox' => '<div id="node_%id" class="codebox">%s</div>',
    'codeboxsmall' => '<div id="node_%id" class="codebox codeboxsmall">%s</div>',
    '*' => {
        parse => 1,
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            $$content =~ s/\n+\z//;
            my $id = $tag->get_id;
            if ($info->{stack}->[-2] eq 'list') {
                return qq{<li id="node_$id">$$content</li>},
            }
            return Parse::BBCode::escape_html($tag->raw_text);
        },
        close => 0,
        class => 'block',
    },
    include => {
        single => 1,
        parse => 1,
        code => sub {
            my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
            # TODO disallow absolute paths or ..
            my $data = $parser->get_datadir or die "No data directory given";
            open my $fh, '<', "$data/$attr" or die $!;
            $content = do { local $/; <$fh> };
            close $fh;
            return $content;
        },

    },
    'br' => {
        single => 1,
        parse => 1,
        code => sub {
            return '<br>';
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
