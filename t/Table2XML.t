use strict;
use Test::More;
use Test::XML;
BEGIN {use_ok('XML::Table2XML', qw(parseHeaderForXML addXMLLine commonParent offsetNodesXML)) };
my @xmltests = glob('../testdir/*.txt');
# 19 internal function tests + ? XML tests:
plan tests => (19 + @xmltests);

## commonParent:
ok(commonParent("/a/b/c", "/a/d/e") eq "/a", "commonParent");
ok(commonParent("/a/b", "/a/b/c") eq "/a/b", "commonParent");
ok(commonParent("/a/b/c", "/a/b") eq "/a/b", "commonParent");
ok(commonParent("/a/b/c", "/x/d/e") eq "", "commonParent");
ok(commonParent("/a/b/c", "/a/b/c") eq "/a/b/c", "commonParent");
ok(commonParent("/a/b/c", "") eq "", "commonParent");
ok(commonParent("", "/a/b/c") eq "", "commonParent");

# offsetNodesXML, openXML:
ok(offsetNodesXML("/a/b/c", "/a/d/e") eq "<b>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "/x/d/e") eq "<a><b>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "/a/b/c") eq "", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "") eq "<a><b>", "offsetNodesXML");
ok(offsetNodesXML("", "/a/b/c") eq "", "offsetNodesXML");

# offsetNodesXML, closeXML:
ok(offsetNodesXML("/a/b/c", "/a/d/e", 1) eq "</c></b>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/a/g/d/e", 1) eq "</c></b>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/t/w/d/e", 1) eq "</c></b></g></a>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/d/e", "/a/g", 1) eq "</e></d>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/a/g/b/c", 1) eq "</c>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "", 1) eq "</c></b></a>", "offsetNodesXML");
ok(offsetNodesXML("/a/z", "/a/b/c", 1, 1) eq "</z></a>", "offsetNodesXML");

for my $testfilename (@xmltests) {
	my $rootNodeName; my @headerLine; my @datarows; my $expectedXML;
	readTxtFile($testfilename, \$rootNodeName, \@headerLine, \@datarows);
	readXMLFile($testfilename, \$expectedXML);
	my $testXML = "";
	# first parse the column path headers for attribute names, id columns and special common sibling mark ("//")
	# also resets all global parameters...
	parseHeaderForXML($rootNodeName, \@headerLine);
	# then walk through the whole data to build the actual XML string (in $testxml->{strXML})
	for my $lineData (@datarows) {
		$testXML.=addXMLLine($lineData);
	}
	#finally finish the XML and reset the static vars
	$testXML.=addXMLLine(undef);
	is_xml($expectedXML,$testXML, "XML comparison");
}


sub readTxtFile {
	my ($testfilename, $rootNodeName, $headerLine, $datarows) = @_;

  open (TESTOUT, ">testout");
  open (TXTIN, "<$testfilename");
	$_ = <TXTIN>; chomp;
	$$rootNodeName = $_;
  print TESTOUT $$rootNodeName."\n";
	$_ = <TXTIN>;chomp;
	@$headerLine = split "\t";
  print TESTOUT $_ for (@$headerLine); print TESTOUT "\n";
	while (<TXTIN>) {
		chomp;
		my @dataline = split "\t";
		push @$datarows, \@dataline;
    print TESTOUT $_ for (@dataline); print TESTOUT "\n";
	}
	close TXTIN;
  close TESTOUT;
}

sub readXMLFile {
	my ($testfilename, $expectedXML) = @_;

	$testfilename =~ s/\.txt/\.xml/;
	open (TXTIN, "<$testfilename");
	my $oldRecSep = $/;
	undef $/;
	$$expectedXML = <TXTIN>;
	$/ = $oldRecSep;
	close TXTIN;
}
