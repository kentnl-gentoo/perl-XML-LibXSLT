# $Id: LibXSLT.pm,v 1.7 2001/03/14 21:01:50 matt Exp $

package XML::LibXSLT;

use strict;
use vars qw($VERSION @ISA);

use XML::LibXML;

require Exporter;

$VERSION = "0.95";

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

=head1 API

The following methods are available on the new XML::LibXSLT object:

=head2 parse_stylesheet($doc)

C<$doc> here is an XML::LibXML::Document object (see L<XML::LibXML>)
representing an XSLT file. This method will return a 
XML::LibXSLT::Stylesheet object, or undef on failure. If the XSLT is
invalid, an exception will be thrown, so wrap the call to 
parse_stylesheet in an eval{} block to trap this.

=head2 parse_file($filename)

Exactly the same as the above, but parses the given filename directly.

=head1 XML::LibXSLT::Stylesheet

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of XML::LibXSLT is that you have a generic
stylesheet object which you call the transform() method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=head2 transform(doc)

  my $results = $stylesheet->transform($doc);

Transforms the passed in XML::LibXML::Document object, and returns a
new XML::LibXML::Document.

=head2 transform_file(filename)

  my $results = $stylesheet->transform_file($filename);

=head2 add_param(param)

Add a string as a parameter passed to the stylesheet (for xsl:param).

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
