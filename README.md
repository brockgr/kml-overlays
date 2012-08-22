kml-overlays
============

PSGI application to generate bitmap tile overlays in KML



** WARNING ** This code is being cleaned up - it probably doesn't work for you
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



Required Perl Modules:

  Use cpan or cpanm to install the following:
    Task::Plack
    Geo::Coordinates::OSGB
    Math::Trig


The service use PSGI to provide a generic interface into various
web servers - however to test on your own, you can use the lightweight
plackuop server:

  plackup OSmaps.psgi

or 

  plackup GSImaps.psgi
