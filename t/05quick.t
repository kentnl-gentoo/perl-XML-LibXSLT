use Test;
BEGIN { plan tests => 7 }
use XML::LibXSLT;
use XML::LibXML;

# this test is here because Mark Cox found a segfault
# that occurs when parse_stylesheet is immediately followed
# by a transform()

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();
ok($parser); ok($xslt);
my $source = $parser->parse_file('example/1.xml');
ok($source);
my $style_doc = $parser->parse_file('example/1.xsl');
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($source);
ok($stylesheet->output_string($results));

$source = $parser->parse_file('example/2.xml');
ok($source);
$style_doc = $parser->parse_file('example/2.xsl');
$stylesheet = $xslt->parse_stylesheet($style_doc);
$results = $stylesheet->transform($source);
ok($stylesheet->media_type);
ok($stylesheet->output_string($results));
