# wifistatd

  wifistatd is a simple program written in Perl for monitoring signal/
  noise/link levels on selected wireless interface. The result is a 
  simple PNG image, which may be used at web-page.

## description
  wifistatd is an easy program written in Perl for monitoring signal/
  noise/link levels on selected wireless interface. The result is a 
  simple PNG image, which may be used at web-page.

## changelog
  06/10/2002: bugfix: corrected missed install call (thx to Paul Bettinger)
  02/10/2002: initial release

## install
  Required packages:
  Perl    (Tested with 5.6.1)
  rrdtool (Tested with v. 1.0.39)
    
  To install wifistatd on a UNIX machine untar the archive with program.
  Then you should type:

    ./wifistatd.pl install

  If everything went OK (it should), you'll get the 'db.rrd' database file
  in your current working directory.

  To configure daemon edit the head part of wifistatd.pl.
  
## getting started
  To start, just type:
  
    ./wifistatd.pl start

  To stop, just type:
  
    ./wifistatd.pl stop

 bugs
  Nothing found...

