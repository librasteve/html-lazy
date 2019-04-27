use v6.c;
unit module HTML::Lazy:ver<0.0.1>;
use HTML::Escape;

=begin pod

=head1 NAME

HTML::Lazy - Declarative HTML generation

=head1 SYNOPSIS

=begin code :lang<perl6>

use HTML::Lazy (:ALL);

my $document = html-en
    head( Map,
        title(Map, text('HTML::Lazy'))
    ),
    body( Map,
        text('Hello world!')
    );

# Execute the generator
put render($document)

=end code

=head1 DESCRIPTION

HTML::Lazy is a declarative HTML document generation module.
It provides declarative functions for creating lazy HTML generation closures.
The lazy generation can be overridden through an eager renderer and generation can be performed in parrallel with a hyper-renderer.

=head1 AUTHOR

= Sam Gillespie <samgwise@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 = Sam Gillespie

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

our sub as-list($v --> List) {
    #= maps Any to Positional or Positional to Positional.
    #= Internal utility for simplifying attribute generation.
    return List if !$v.so;
    return $v if $v ~~ Positional;
    List($v)
}

our sub render(&tag --> Str) is export(:DEFAULT) {
    #= calls a no argument Callable to produce the defined content.
    #= This routine is here to show programmer intention but is equivilent to the many ways to execute CALL-ME on a Callable.
    tag
}

our sub pre-render(&tag --> Callable) is export(:DEFAULT) {
    #= Executes a render and stores the result so it may be rendered later.
    #= Use this function to eagerly evaluate a document or sub document and store the resulting Str for use in other documents.
    my $content = render &tag;
    -> {
        $content
    }
}

our sub hyper-render(*@children --> Callable) is export(:DEFAULT) {
    #= Children of a hyper-render function will be rendered in parrallel when called.
    #= The results will be reassembled without change to order.
    -> {
        my @promises = do for @children -> $child {
            start { render $child }
        }

        join("\n", @promises.map( -> $promise { await $promise } ))
    }
}

our sub text(Str $text --> Callable) is export(:DEFAULT) {
    #= Create a closure to emit the text provided.
    #= Text is escaped for HTML, use text-raw for including text which should not be sanitised.
    #= The escaping uses escape-html from L<HTML::Escape | https://modules.perl6.org/dist/HTML::Escape:cpan:MOZNION>.
    -> {
        escape-html $text
    }
}

our sub text-raw(Str $text --> Callable) is export(:DEFAULT) {
    #= Create a closure to emit the text provided.
    #= The text is returned with no escaping.
    #= This function is appropriate for inserting HTML from other sources, scripts or CSS.
    #= If you are looking to add text content to a page you should look at the C<text> function as it will sanitize the input, so as to avoid any accidental or malicious inclusion of HTML or script content.
    -> { $text }
}
our sub node(Str:D $tag, Associative $attributes, *@children --> Callable) is export(:DEFAULT) {
    #= Generalised html element generator.
    #= This function provides the core rules for generating html tags.
    #= All tag generators are built upon this function.
    #= To create specialised versions of this function use the C<tag-factory> and then further specialised with the C<with-attributes> function.
    -> {
        '<'
        ~ $tag
        ~ ($attributes.so
            ?? ' ' ~ $attributes.kv
                    .map( -> $attr, $val { $attr ~ '="' ~ as-list($val).join(' ') ~'"'} )
                    .join(' ')
            !! ''
        )
        ~ '>'
        ~ (
        ~ (@children.so ?? "\n" ~ @children.map( { .() } ).join("\n").indent(4) ~ "\n" !! '')
        )
        ~ '</'
        ~ $tag
        ~ '>'
        # " # fix syntax highlighting...
    }
}

our sub tag-factory(Str:D $tag --> Callable) is export(:DEFAULT) {
    #= Make functions to create specific tags.
    #= Returns a Callable with the signiture (Associative $attributes, *@children --> Callable).
    #= The closure created by this routine wraps up an instance of the C<node>.
    -> Associative $attributes, *@children {
        node $tag, $attributes, |@children
    }
}

our sub with-attributes(&tag, Associative $attributes --> Callable) is export(:DEFAULT) {
    #= Create a tag with preset attributes.
    #= Allows for further specialisation of tag closures from the C<tag-factory> routine.
    #= The closure returned from this routine has the following signiture (*@children --> Callable).
    -> *@children {
        tag $attributes, |@children
    }
}

our sub html-en(Associative :$attributes = {:lang<en>, :dir<ltr>}, *@children --> Callable) is export(:DEFAULT) {
    #= Create a HTML tag with DOCTYPE defenition.
    #= Use this function as the top of your document.
    #= The default arguments to attributes are set for English, C<{:lang<en>, :dir<ltr>}>, but a new Map or hash can be used to tailor this routine to your needs.
    -> {
        "<!DOCTYPE html>\n"
        ~ render node 'html', $attributes, |@children
    }
}

our sub include-file(Str:D $file --> Callable) is export(:DEFAULT) {
    #= Include content from a file.
    #= Use this function to include external files such as scripts and CSS in your templates.
    #= Content is included without any sanitisation of the input.
    -> { $file.IO.slurp }
}

#
# Common tags
#

# Header tags
our &head is export( :tags ) = tag-factory 'head';
our &title is export( :tags ) = tag-factory 'title';

# Content sections
our &body is export( :tags) = tag-factory 'body';
our &div is export( :tags) = tag-factory 'div';
our &footer is export( :tags) = tag-factory 'foorter';
our &header is export( :tags) = tag-factory 'header';

# Formatting
our &br is export( :tags) = tag-factory 'br';
our &col is export( :tags) = tag-factory 'col';
our &colgroup is export( :tags) = tag-factory 'colgroup';
our &ul is export( :tags) = tag-factory 'ul';
our &ol is export( :tags) = tag-factory 'ol';
our &li is export( :tags) = tag-factory 'li';
our &code is export( :tags) = tag-factory 'code';
our &pre is export( :tags) = tag-factory 'pre';
our &table is export( :tags) = tag-factory 'table';
our &thead is export( :tags) = tag-factory 'thead';
our &tbody is export( :tags) = tag-factory 'tbody';
our &tfoot is export( :tags) = tag-factory 'tfoot';
our &tr is export( :tags) = tag-factory 'tr';
our &th is export( :tags) = tag-factory 'th';
our &td is export( :tags) = tag-factory 'td';
our &caption is export( :tags) = tag-factory 'caption';

# Content
our &a is export( :tags) = tag-factory 'a';
our &img is export( :tags) = tag-factory 'img';
our &audio is export( :tags) = tag-factory 'audio';
our &video is export( :tags) = tag-factory 'video';
our &canvas is export( :tags) = tag-factory 'canvas';
our &link is export( :tags) = tag-factory 'link';
our &script is export( :tags) = tag-factory 'script';
our &style is export( :tags) = tag-factory 'style';
our &asource is export( :tags) = tag-factory 'source';
our &svg is export( :tags) = tag-factory 'svg';
our &noscript is export( :tags) = tag-factory 'noscript';
our &iframe is export( :tags) = tag-factory 'iframe';

# input
our &form is export( :tags) = tag-factory 'form';
our &input is export( :tags) = tag-factory 'input';
our &label is export( :tags) = tag-factory 'label';
our &optgroup is export( :tags) = tag-factory 'optgroup';
our &option is export( :tags) = tag-factory 'option';
our &select is export( :tags) = tag-factory 'select';
our &textarea is export( :tags) = tag-factory 'textarea';
our &button is export( :tags) = tag-factory 'button';

# Text
our &span is export( :tags) = tag-factory 'span';
our &p is export( :tags) = tag-factory 'p';
our &i is export( :tags) = tag-factory 'i';
our &b is export( :tags) = tag-factory 'b';
our &q is export( :tags) = tag-factory 'q';
our &blockquote is export( :tags) = tag-factory 'blockquote';
our &em is export( :tags) = tag-factory 'em';
our &sub is export( :tags) = tag-factory 'sub';
our &sup is export( :tags) = tag-factory 'sup';
our &h1 is export( :tags) = tag-factory 'h1';
our &h2 is export( :tags) = tag-factory 'h2';
our &h3 is export( :tags) = tag-factory 'h3';
our &h4 is export( :tags) = tag-factory 'h4';
our &h5 is export( :tags) = tag-factory 'h5';
our &h6 is export( :tags) = tag-factory 'h6';
