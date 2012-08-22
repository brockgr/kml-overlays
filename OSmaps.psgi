
use strict;
use warnings;

use CGI::PSGI;

use Geo::Coordinates::OSGB qw(ll_to_grid grid_to_ll shift_ll_into_WGS84 shift_ll_from_WGS84);
use Math::Trig ;

## Get these by registering at http://www.ordnancesurvey.co.uk/oswebsite/web-services/os-openspace/api/
my $os_site = "http://www.example.com";
my $os_key  = "0123456789ABCDEF0123456789ABCDEF";


#0# http://openspace.ordnancesurvey.co.uk/osmapapi/ts?FORMAT=image%2Fpng&KEY=4627B6C1B43447B4E0405F0AF1605E65&URL=http%3A%2F%2Fwww.brock-family.org%2Fmap1.html&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&EXCEPTIONS=application%2Fvnd.ogc.se_inimage&LAYERS=1&SRS=EPSG%3A27700&BBOX=438250,114000,438500,114250&WIDTH=250&HEIGHT=250
#1# http://openspace.ordnancesurvey.co.uk/osmapapi/ts?FORMAT=image%2Fpng&KEY=4627B6C1B43447B4E0405F0AF1605E65&URL=http%3A%2F%2Fwww.brock-family.org%2Fmap1.html&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&EXCEPTIONS=application%2Fvnd.ogc.se_inimage&LAYERS=5&SRS=EPSG%3A27700&BBOX=437000,114000,438000,115000&WIDTH=200&HEIGHT=200
#2# http://openspace.ordnancesurvey.co.uk/osmapapi/ts?FORMAT=image%2Fpng&KEY=4627B6C1B43447B4E0405F0AF1605E65&URL=http%3A%2F%2Fwww.brock-family.org%2Fmap1.html&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&EXCEPTIONS=application%2Fvnd.ogc.se_inimage&LAYERS=25&SRS=EPSG%3A27700&BBOX=440000,110000,445000,115000&WIDTH=200&HEIGHT=200
#3# http://openspace.ordnancesurvey.co.uk/osmapapi/ts?FORMAT=image%2Fpng&KEY=4627B6C1B43447B4E0405F0AF1605E65&URL=http%3A%2F%2Fwww.brock-family.org%2Fmap1.html&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&EXCEPTIONS=application%2Fvnd.ogc.se_inimage&LAYERS=100&SRS=EPSG%3A27700&BBOX=400000,100000,420000,120000&WIDTH=200&HEIGHT=200

my $types = [
  { scale => 250,   w => 250, h => 250, layers => 1 },
  { scale => 1000,  w => 200, h => 200, layers => 5 },
  { scale => 5000,  w => 200, h => 200, layers => 25 },
  { scale => 20000, w => 200, h => 200, layers => 100 },
];

sub escapeHTML {
  my ($toencode) = @_;
  $toencode =~ s{&}{&amp;}gso;
  $toencode =~ s{<}{&lt;}gso;
  $toencode =~ s{>}{&gt;}gso;
  return $toencode;
}

sub latlong2noreast ($$) {
  my ($lat,$long) = @_;
  ($lat, $long) = shift_ll_from_WGS84($lat, $long);
  my ($e, $n) = ll_to_grid($lat, $long);
  return(int $n,int $e);
}

sub noreast2latlong ($$) {
  my ($nor,$east) = @_;
  my ($lat, $lon) = grid_to_ll($east, $nor);
  ($lat, $lon) = shift_ll_into_WGS84($lat, $lon);
  return ($lat,$lon);
}

sub convergence ($$) {
  my ($lat,$long) = @_;
  return ($long + 2) * sin ( $lat *  pi / 180);
}

sub url ($$$$$) {
  my ($e_from,$n_from,$e_to,$n_to,$type) = @_;

  my $w = $types->[$type]->{w};
  my $h = $types->[$type]->{h};
  my $layer = $types->[$type]->{layers};
  return "http://openspace.ordnancesurvey.co.uk/osmapapi/ts?".
    "FORMAT=image%2Fpng&".
    "KEY=4627B6C1B43447B4E0405F0AF1605E65&".
    "URL=http%3A%2F%2Fwww.brock-family.org%2Fwosmaps&".
    "SERVICE=WMS&".
    "VERSION=1.1.1&".
    "REQUEST=GetMap&".
    "STYLES=&".
    "EXCEPTIONS=application%2Fvnd.ogc.se_inimage&".
    "LAYERS=$layer&".
    "SRS=EPSG%3A27700&".
    "BBOX=$e_from,$n_from,$e_to,$n_to&".
    "WIDTH=$w&HEIGHT=$h";

#  return "http://xxexplore.ordnancesurvey.co.uk/OSMapAPIWebApp/osmapapiwms".
#    "?SERVICE=WMS&".
#    "VERSION=1.1.0&".
#    "REQUEST=GetMap&".
#    "LAYERS=0,1,2,3,4,5,6,7,8&".
#    "STYLES=raster&".
#    "SRS=EPSG:27700&".
#    "BBOX=$e_from,$n_from,$e_to,$n_to&".
#    "WIDTH=200&".
#    "HEIGHT=200&".
#    "BGCOLOR=0x9CCEFF&".
#    "FORMAT=image/png";
}

sub kml_header {
  return <<'EOD';
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Folder>
<name>Unofficial OS Overlays</name>
<ScreenOverlay><name><![CDATA[© Crown Copyright and database right 2008. All rights reserved. <a href="http://openspace.ordnancesurvey.co.uk/openspace/developeragreement.html#enduserlicense">End User License Agreement</a>]]></name>
<Icon>http://www.ordnancesurvey.co.uk/oswebsite/images/userImages/misc/media/cg.gif</Icon>
<screenXY x="105" y="45" xunits="pixels" yunits="pixels" />
<color>80ffffff</color>
</ScreenOverlay>
EOD
}

sub kml_overlay {
  my ($url,$s,$w,$n,$e,$t,$b,$r,$l,$rot) = @_;
  return <<EOD;
<GroundOverlay>
<name>OS Overlay</name>
<description>$s,$w,$n,$e</description>
<Icon><href>$url</href></Icon>
<LatLonBox>
<north>$t</north><south>$b</south>
<east>$r</east><west>$l</west>
<rotation>$rot</rotation>
</LatLonBox>
</GroundOverlay>
EOD
}

sub kml_footer {
  return <<'EOD';
</Folder>
</kml>
EOD
}


my $app = sub {
  my $env = shift;
  my $body = '';

  my $req = CGI::PSGI->new($env);

  $body .= kml_header();

  # E.g. ?BBOX=54.39842700542721,-2.036022996438413,5744.95
  my ($lat,$long,$range) = ($env->{QUERY_STRING} =~ /BBOX=([-\d.]+),([-\d.]+),([-\d.]+)/);
  
  my ($no,$ea,$type);
  eval {
    die "Way off" if ( ($long < -9) || ($lat < 49) || ($long > 3) || ($lat > 62) || ($range > 1000000));
     ($no,$ea) = latlong2noreast($lat,$long);
    die "no origin" unless (defined($no) && defined($ea));
  };

  if (! $@) {

    if ($range > 45000) {
      $type = 3;
    } elsif ($range > 10000) {
      $type = 2;
    } elsif ($range > 2000) {
      $type = 1;
    } else {
      $type = 0;
    }

    my $unit = $types->[$type]->{scale};

    my $orig_s = $no - ($no % $unit);
    my $orig_w = $ea - ($ea % $unit);

    foreach my $i (-5..5) {
      my $s = $orig_s + ($unit * $i);
      #foreach my $j (0) {
      foreach my $j (-5..5) {
        my $w = $orig_w + ($unit * $j);
        my $n = $s + $unit;
        my $e = $w + $unit;
  
        my $url = url($w,$s,$e,$n,$type); 
        $url = escapeHTML($url);

        my $b = (noreast2latlong($s,$w+(0.5*$unit)))[0];
        my $t = (noreast2latlong($n,$w+(0.5*$unit)))[0];
        my $r = (noreast2latlong($s+(0.5*$unit),$e))[1];
        my $l = (noreast2latlong($s+(0.5*$unit),$w))[1];

        my ($c_lat,$c_lon) = noreast2latlong($s+(0.5*$unit),$w+(0.5*$unit));

        my $rot = -1 * convergence($c_lat,$c_lon);

        $body .= kml_overlay($url,$s,$w,$n,$e,$t,$b,$r,$l,$rot);
      }
    }
  }
  $body .= kml_footer();

  return [ $req->psgi_header("application/vnd.google-earth.kml+xml"), [ $body ] ];
}
