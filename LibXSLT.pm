# $Id: LibXSLT.pm,v 1.46 2003/02/12 16:48:02 matt Exp $

package XML::LibXSLT;

use strict;
use vars qw($VERSION @ISA $USE_LIBXML_DATA_TYPES);

use XML::LibXML 1.49;
use XML::LibXML::Literal;
use XML::LibXML::Boolean;
use XML::LibXML::Number;
use XML::LibXML::NodeList;

require Exporter;

$VERSION = "1.53";

require DynaLoader;

@ISA = qw(DynaLoader);

bootstrap XML::LibXSLT $VERSION;

$USE_LIBXML_DATA_TYPES = 0;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    return $self;
}

# ido - perl dispatcher
sub perl_dispatcher {
    my $func = shift;
    my @params = @_;
    my @perlParams;
    
    my $i = 0;
    while (@params) {
        my $type = shift(@params);
        if ($type eq 'XML::LibXML::Literal' or 
            $type eq 'XML::LibXML::Number' or
            $type eq 'XML::LibXML::Boolean')
        {
            my $val = shift(@params);
            unshift(@perlParams, $USE_LIBXML_DATA_TYPES ? $type->new($val) : $val);
        }
        elsif ($type eq 'XML::LibXML::NodeList') {
            my $node_count = shift(@params);
            my @nodes = splice(@params, 0, $node_count);
            # warn($_->getName) for @nodes;
            unshift(@perlParams, $type->new(@nodes));
        }
    }
    
    $func = "main::$func" unless ref($func) || $func =~ /(.+)::/;
    no strict 'refs';
    my $res = $func->(@perlParams);
    return $res;
}


sub xpath_to_string {
    my @results;
    while (@_) {
        my $value = shift(@_); $value = '' unless defined $value;
        push @results, $value;
        if (@results % 2) {
            # key
            $results[-1] =~ s/:/_/g; # XSLT doesn't like names with colons
        }
        else {
            if ($value =~ s/'/', "'", '/g) {
	        $results[-1] = "concat('$value')";
            }
            else {
                $results[-1] = "'$results[-1]'";
            }
        }
    }
    return @results;
}

sub callbacks {
    die "callbacks() never worked and has been removed."
}

sub match_callback {
    die "match_callback never worked and has been removed.\nPlease set \$XML::LibXML::match_cb instead";
}

sub open_callback {
    die "open_callback never worked and has been removed.\nPlease set \$XML::LibXML::open_cb instead";
}

sub read_callback {
    die "read_callback never worked and has been removed.\nPlease set \$XML::LibXML::read_cb instead";
}

sub close_callback {
    die "close_callback never worked and has been removed.\nPlease set \$XML::LibXML::close_cb instead";
}

sub parse_stylesheet {
    my $self = shift;
    if (!ref($self) || !$self->{XML_LIBXSLT_MATCH}) {
        return $self->_parse_stylesheet(@_);
    }
    local $XML::LibXML::match_cb = $self->{XML_LIBXSLT_MATCH};
    local $XML::LibXML::open_cb = $self->{XML_LIBXSLT_OPEN};
    local $XML::LibXML::read_cb = $self->{XML_LIBXSLT_READ};
    local $XML::LibXML::close_cb = $self->{XML_LIBXSLT_CLOSE};
    $self->_parse_stylesheet(@_);
}

sub parse_stylesheet_file {
    my $self = shift;
    if (!ref($self) || !$self->{XML_LIBXSLT_MATCH}) {
        return $self->_parse_stylesheet_file(@_);
    }
    local $XML::LibXML::match_cb = $self->{XML_LIBXSLT_MATCH};
    local $XML::LibXML::open_cb = $self->{XML_LIBXSLT_OPEN};
    local $XML::LibXML::read_cb = $self->{XML_LIBXSLT_READ};
    local $XML::LibXML::close_cb = $self->{XML_LIBXSLT_CLOSE};
    $self->_parse_stylesheet_file(@_);
}

sub register_xslt_module {
    my $self = shift;
    my $module = shift;
    # Not implemented
}

1;
__END__

=head1 NAME

XML::LibXSLT - Interface to the gnome libxslt library

=head1 SYNOPSIS

  use XML::LibXSLT;
  use XML::LibXML;
  
  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  
  my $source = $parser->parse_file('foo.xml');
  my $style_doc = $parser->parse_file('bar.xsl');
  
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  
  my $results = $stylesheet->transform($source);
  
  print $stylesheet->output_string($results);

=head1 DESCRIPTION

This module is an interface to the gnome project's libxslt. This is an
extremely good XSLT engine, highly compliant and also very fast. I have
tests showing this to be more than twice as fast as Sablotron.

=head1 OPTIONS

XML::LibXSLT has some global options. Note that these are probably not
thread or even fork safe - so only set them once per process. Each one
of these options can be called either as class methods, or as instance
methods. However either way you call them, it still sets global options.

Each of the option methods returns its previous value, and can be called
without a parameter to retrieve the current value.

=head2 max_depth

  XML::LibXSLT->max_depth(1000);

This option sets the maximum recursion depth for a stylesheet. See the
very end of section 5.4 of the XSLT specification for more details on
recursion and detecting it. If your stylesheet or XML file requires
seriously deep recursion, this is the way to set it. Default value is
250.

=head2 debug_callback

  XML::LibXSLT->debug_callback($subref);

Sets a callback to be used for debug messages. If you don't set this,
debug messages will be ignored.

=head2 register_function

  XML::LibXSLT->register_function($uri, $name, $subref);

Registers an XSLT extension function mapped to the given URI. For example:

  XML::LibXSLT->register_function("urn:foo", "bar",
    sub { scalar localtime });

Will register a C<bar> function in the C<urn:foo> namespace (which you
have to define in your XSLT using C<xmlns:...>) that will return the
current date and time as a string:

  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo">
  <xsl:template match="/">
    The time is: <xsl:value-of select="foo:bar()"/>
  </xsl:template>
  </xsl:stylesheet>

Parameters can be in whatever format you like. If you pass in a nodelist
it will be a XML::LibXML::NodeList object in your perl code, but ordinary
values (strings, numbers and booleans) will be ordinary perl scalars. If
you wish them to be C<XML::LibXML::Literal>, C<XML::LibXML::Number> and
C<XML::LibXML::Number> values respectively then set the variable
C<$XML::LibXSLT::USE_LIBXML_DATA_TYPES> to a true value. Return values can
be a nodelist or a plain value - the code will just do the right thing.
But only a single return value is supported (a list is not converted to
a nodelist).

=head1 API

The following methods are available on the new XML::LibXSLT object:

=head2 parse_stylesheet($doc)

C<$doc> here is an XML::LibXML::Document object (see L<XML::LibXML>)
representing an XSLT file. This method will return a 
XML::LibXSLT::Stylesheet object, or undef on failure. If the XSLT is
invalid, an exception will be thrown, so wrap the call to 
parse_stylesheet in an eval{} block to trap this.

=head2 parse_stylesheet_file($filename)

Exactly the same as the above, but parses the given filename directly.

=head1 XML::LibXSLT::Stylesheet

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of XML::LibXSLT is that you have a generic
stylesheet object which you call the transform() method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=head2 transform(doc, %params)

  my $results = $stylesheet->transform($doc, foo => "value);

Transforms the passed in XML::LibXML::Document object, and returns a
new XML::LibXML::Document. Extra hash entries are used as parameters.

=head2 transform_file(filename, %params)

  my $results = $stylesheet->transform_file($filename, bar => "value");

=head2 output_string(result)

Returns a scalar that is the XSLT rendering of the XML::LibXML::Document
object using the desired output format (specified in the xsl:output tag
in the stylesheet). Note that you can also call $result->toString, but
that will *always* output the document in XML format, and in UTF8, which
may not be what you asked for in the xsl:output tag.

=head2 output_fh(result, fh)

Outputs the result to the filehandle given in C<$fh>.

=head2 output_file(result, filename)

Outputs the result to the file named in C<$filename>.

=head2 output_encoding

Returns the output encoding of the results. Defaults to "UTF-8".

=head2 media_type

Returns the output media_type of the results. Defaults to "text/html".

=head1 Parameters

LibXSLT expects parameters in XPath format. That is, if you wish to pass
a string to the XSLT engine, you actually have to pass it as a quoted
string:

  $stylesheet->transform($doc, param => "'string'");

Note the quotes within quotes there!

Obviously this isn't much fun, so you can make it easy on yourself:

  $stylesheet->transform($doc, XML::LibXSLT::xpath_to_string(
        param => "string"
        ));

The utility function does the right thing with respect to strings in XPath,
including when you have quotes already embedded within your string.

=head1 BENCHMARK

Included in the distribution is a simple benchmark script, which has two
drivers - one for LibXSLT and one for Sablotron. The benchmark requires
the testcases files from the XSLTMark distribution which you can find
at http://www.datapower.com/XSLTMark/

Put the testcases directory in the directory created by this distribution,
and then run:

  perl benchmark.pl -h

to get a list of options.

The benchmark requires XML::XPath at the moment, but I hope to factor that
out of the equation fairly soon. It also requires Time::HiRes, which I
could be persuaded to factor out, replacing it with Benchmark.pm, but I
haven't done so yet.

I would love to get drivers for XML::XSLT and XML::Transformiix, if you
would like to contribute them. Also if you get this running on Win32, I'd
love to get a driver for MSXSLT via OLE, to see what we can do against
those Redmond boys!

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

Copyright 2001, AxKit.com Ltd. All rights reserved.

=head1 SEE ALSO

XML::LibXML

=cut
