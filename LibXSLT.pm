# $Id$

package XML::LibXSLT;

use strict;
use vars qw($VERSION @ISA);

use XML::LibXML;

require Exporter;

$VERSION = "0.94";

require DynaLoader;

@ISA = qw(DynaLoader);

bootstrap XML::LibXSLT $VERSION;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    return $self;
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

When calling C<new()>, the following options are available (passed in
as a hash of key/value pairs):

=over

=item error_handler

A subroutine reference or function name that is called whenever an XSLT
processsing error occurs. Note that this is not the same as an XML
parsing error - for that see L<XML::LibXSLT>.

=item debug_handler

This is identical to error_handler above, except for libxslt debug 
messages.

=item max_depth

Maximum recurse depth. If your stylesheet recurses, XML::LibXSLT will by
default stop at 250 recursions. Set this if you want that value increased.

=back

=head1 API

The following methods are available on the new XML::LibXSLT object:

=head2 parse_stylesheet($doc)

C<$doc> here is an XML::LibXML::Document object (see L<XML::LibXML>)
representing an XSLT file. This method will return a 
XML::LibXSLT::Stylesheet object, or undef on failure.

=head2 parse_file($filename)

Parses the file given in $filename, returning a XML::LibXSLT::Stylesheet
object, or undef on failure.

=head1 XML::LibXSLT::Stylesheet

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of XML::LibXSLT is that you have a generic
stylesheet object which you call the transform() method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=head2 add_param($param)

Add a string as a parameter passed to the stylesheet (for xsl:param).

=head2 transform($doc)

Transforms the passed in XML::LibXML::Document object, and returns a
new XML::LibXML::Document.

=head2 output_string($result)

Returns a scalar that is the XSLT rendering of the XML::LibXML::Document
object using the desired output format (specified in the xsl:output tag
in the stylesheet). Note that you can also call $result->toString, but
that will *always* output the document in XML format, and in UTF8, which
may not be what you asked for in the xsl:output tag.

=head2 output_fh($result, $fh)

Outputs the result to the filehandle given in C<$fh>.

=head2 output_file($result, $filename)

Outputs the result to the file named in C<$filename>.

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
