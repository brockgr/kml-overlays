package GSImaps;

use strict;
use warnings;

use CGI::PSGI;

my @scales = (
  [ 1500,  750 ],
  [ 3000, 1500 ],
  [ 5000, 3000 ],
  [ 10000, 6000 ],
  [ 20000, 12000 ],
  [ 40000, 24000 ],
  [ 80000, 48000 ],
  [ 160000, 96000 ],
  [ 320000, 192000 ],
  [ 640000, 384000 ],
  # Ignore 768000, 1536000, 3072000
);

sub escapeHTML {
  my ($toencode) = @_;
  $toencode =~ s{&}{&amp;}gso;
  $toencode =~ s{<}{&lt;}gso;
  $toencode =~ s{>}{&gt;}gso;
  return $toencode;
}

sub url ($) {
  my ($grid) = @_;
  my $key = substr($grid,0,4);
  return "http://cyberjapan.jp/watchizu_data/$key/$grid.png";
}

sub kml_header {
  return <<'EOD';
<?xml version="8.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Folder>
<name>Japan GSI Overlays</name>
<ScreenOverlay><name>Data is (c) Japan Geographical Survey Institute</name>
<Icon>http://www.gsi.go.jp/photo/gis/densi-kokudo.jpg</Icon>
<screenXY x="55" y="55" xunits="pixels" yunits="pixels" />
<color>80ffffff</color>
</ScreenOverlay>
EOD
}

sub kml_overlay {
  my ($url,$s,$w,$n,$e,$rot) = @_;
  return <<EOD;
<GroundOverlay>
<name>OS Overlay</name>
<description>$s,$w,$n,$e</description>
<Icon><href>$url</href></Icon>
<LatLonBox>
<north>$n</north><south>$s</south>
<east>$e</east><west>$w</west>
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

  # E.g. /gsimaps?BBOX=39.20154470372334,141.2146100118758,3238.53
  my ($lat,$long,$range) = ($ENV->{QUERY_STRING} =~ /BBOX=([-\d.]+),([-\d.]+),([-\d.]+)/);
  
  eval {
    die "Way off" if ( ($long <121) || ($lat < 20.2) || ($long > 154) || ($lat > 46.5) || ($range > 1000000));
  };

  if (! $@) {

    my $scale;
    foreach my $dist (@scales) {
      if ($range < $dist->[0]) {
        $scale = $dist->[1];
        last;
      }
    }

    my $rot = 0;

    my $orig_longs = int($long * 100 * 60 * 60 / $scale)*$scale;
    my $orig_lats = int($lat * 100 * 60 * 60 / $scale)*$scale;

    for my $i (-4..4) {
      for my $j (-3..3) {
    
        my $longs = $orig_longs + $i * $scale;
        my $lats  = $orig_lats  + $j * $scale;

        my $w = $longs / (100 *60 * 60);
        my $s = $lats / (100 *60 * 60);
        my $e = ($longs + $scale) / (100 *60 * 60);
        my $n = ($lats + $scale) / (100 *60 * 60);
    
        my $url =  "http://cyberjapan.jp/data/".($scale/100)."/new/$longs/$longs-$lats-img.png";

        #my $url = url($w,$s,$e,$n); 
        $url = escapeHTML($url);
        $body .= kml_overlay($url,$s,$w,$n,$e,$rot);
      }
    }
  }
  $body .= kml_footer();

  return [ $req->psgi_header("application/vnd.google-earth.kml+xml"), [ $body ] ];

}
