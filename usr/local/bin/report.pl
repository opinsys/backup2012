#!/usr/bin/perl -w

# This script formats html report and creates pie graphs
use strict;
use GD::Graph::pie;

my @data = `cat /var/run/daily_backup_report`;

@data = sort @data;
# How many slices we want (besides "OTHER")
my $SLICES = 25;
# HTTP server IP address
my $HTTP_SERVER_IP_ADDR=shift;
# WWW server base dir
my $WWWDIR = '/var/www';
# reports base dir
my $BASEDIR = "backup/report";
# image dir
my $IMAGEDIR = "$BASEDIR/images";
# HTML Report template filename
my $TEMPLATE = "$WWWDIR/$BASEDIR/.template";
# Hostnames
my @hosts_total = ();
my @hosts_transferred = ();
# Total data amounts
my @total_datas = ();
# Transferred data amounts
my @transferred_datas = ();
# Cumulative transferred amount (sum)
my $total_transferred = 0;
# Cumulative total data amount (sum)
my $total_data = 0;
# Date string
my $date = `date '+%Y.%m.%d'`;

my $human_total = '';
my $human_transferred = '';

chomp $date;
# Array for errors
my @errors = ();
# Array for images (graphs)
my @images = ();
my $transferred_first_slices = 0;
my $total_first_slices = 0;
foreach (@data) { 
   push @errors, "<li class='error'>$1: Failed: FORCE KILLED</li>" if /^(\S+) 3.*force/i;
   next unless( / 1 / );


   if( /^(\S+) .*Total file size: ([\d\.]+.).*ransferred file size: ([\d\.]+.)/ ) {
      $human_total = $2;
      $human_transferred = $3;
   }

   # If needed, we convert teras, gigas etc back to bytes
   s/([\d\.]+)K/int($1*1024)/eg; 
   s/([\d\.]+)M/int($1*(1024*1024))/eg; 
   s/([\d\.]+)G/int($1*(1024*1024*1024))/eg; 
   s/([\d\.]+)T/int($1*(1024*1024*1024*1024))/eg; 

   chomp; 
   # If we find size datas on this row, we save them for future use
   if( /^(\S+) .*Total file size: ([\d\.]+).*ransferred file size: ([\d\.]+)/ ) {
      my $host = $1;
      my $total = $2;
      my $transferred = $3;
      $total_data += $total;
      $total_transferred += $transferred;
      push @hosts_total, $host . ": " . $human_total;
      push @hosts_transferred, $host . ": " . $human_transferred;
      push @total_datas, $total;
      push @transferred_datas, $transferred;
   }
   else {
      /^(\S+) 1 (.*)/;
      my $host = $1;
      my $desc = $2 || 'UNKNOWN ERROR (SSH, TIMEOUT, KEY?)';
      push @errors, "<li class='error'>$host: $desc</li>";
   }
}
my @report_template_array = `cat $TEMPLATE`;
my $report_template = join("", @report_template_array);
$report_template =~ s/ERRORLIST/join("\n", @errors)/e;
$report_template =~ s/DATE/$date/ge;

# As the GD::Graph wants it's data as an array of arrayrefs, we give him those

# We want to sort hostnames (and total data amounts): "ORDER BY total data DESCENDING"
# For that we create a helper array containing numbers in the right order and use that array for sorting.
$SLICES = $#total_datas if $SLICES > $#total_datas;
my @permutation = sort { $total_datas[$b] <=> $total_datas[$a] } (0..$#total_datas);
my @hosts_according_to_total = (@hosts_total[@permutation])[0..$SLICES];
@total_datas = (@total_datas[@permutation])[0..$SLICES];
# We calculate the total data of first slices...
foreach (@total_datas) { $total_first_slices += $_ };
# So that we can push the remaining data for the "OTHER" slice
push @total_datas, ( $total_data - $total_first_slices + 1 );
push @hosts_according_to_total, "OTHER";

# Again we want to sort hostnames (and transferred data amounts): "ORDER BY transferred data DESCENDING"
@permutation = sort { $transferred_datas[$b] <=> $transferred_datas[$a] } (0..$#transferred_datas);
my @hosts_according_to_transferred = (@hosts_transferred[@permutation])[0..$SLICES];
@transferred_datas = (@transferred_datas[@permutation])[0..$SLICES];
foreach (@transferred_datas) { $transferred_first_slices += $_ };
push @transferred_datas, ( $total_transferred - $transferred_first_slices + 1);
push @hosts_according_to_transferred, "OTHER";


my $total_transferred_human = sprintf( "%.1f", $total_transferred / (1024*1024*1024) );
my $total_data_human = sprintf( "%.1f", $total_data / (1024*1024*1024) );

my $totals  = "<li>Total customer data: ${total_data_human} GB</li>\n";
$totals .= "<li>Total transferred data: ${total_transferred_human} GB</li>\n";
# We draw a couple of pie charts and output them as PNG images.
my $graph = GD::Graph::pie->new(800,800);
my @gdata = ( \@hosts_according_to_total, \@total_datas );
my $gd = $graph->plot(\@gdata);
my $filename = "$IMAGEDIR/total_${date}.png";
push @images, "<li><a title='Total Data ${total_data_human} GB' class='graph' href='/$filename'><img class='thumb' src='/$filename' alt='Total data'></a></li>";
open(IMG, ">$WWWDIR/$filename") or die$!;
binmode IMG;
print IMG $gd->png;
close IMG;

my $graph2 = GD::Graph::pie->new(800,800);
my @gdata2 = ( \@hosts_according_to_transferred, \@transferred_datas );
my $gd2 = $graph2->plot(\@gdata2);
$filename = "$IMAGEDIR/transferred_${date}.png";
push @images, "<li><a title='Transferred data ${total_transferred_human} GB' class='graph' href='/$filename'><img class='thumb' src='/$filename' alt='Transferred data'></a></li>";
open(IMG, ">$WWWDIR/$filename") or die$!;
binmode IMG;
print IMG $gd2->png;
close IMG;


# We populate the tempplate and print it out
$report_template =~ s/GRAPHLIST/join("\n", @images)/e;
$report_template =~ s/REPORT/join("", @data)/e;
$report_template =~ s/TOTALS/$totals/e;
$filename = "$IMAGEDIR/transferred_${date}.png";
my $report_url = "$BASEDIR/report_${date}.html";
open(REPORT,">$WWWDIR/$report_url");
print REPORT $report_template;
close REPORT;
print "http://${HTTP_SERVER_IP_ADDR}/$report_url";
