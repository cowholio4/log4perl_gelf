##################################################
package Log::Log4perl::Layout::GELF;
##################################################

use strict;
use warnings;

use JSON::XS;
use IO::Compress::Gzip qw( gzip $GzipError );
use Data::Dumper::Simple;

use base qw(Log::Log4perl::Layout::PatternLayout);

sub new {
    my $class = shift;
    $class = ref ($class) || $class;

    my $options       = ref $_[0] eq "HASH" ? shift : {};
    my $gelf_format = { 
        "version" => "1.0",
        "host" => "%H",
        "short_message" => "%m{chomp}",
        "timestamp" => "%Z", # write my own spec
        "level"=> "%Y", # write my own spec
        "facility"=> "%M",
        "file"=> "%F",
        "line"=> "%L",
        "_pid" => "%P", 
    };
    my $conversion_pattern = encode_json($gelf_format);
    $options->{ConversionPattern} = { value => $conversion_pattern } ;
    $options->{cspec} = { 
        'Z' => { value => sub {return time } }, 
        'Y' => { value => \&_level_converter } ,
    } ;
    warn $conversion_pattern;
    my $self = $class->SUPER::new($options);
    
    return $self;
}
# 0 Emergency: system is unusable 
# 1 Alert: action must be taken immediately 
# 2 Critical: critical conditions 
# 3 Error: error conditions 
# 4 Warning: warning conditions 
# 5 Notice: normal but significant condition 
# 6 Informational: informational messages 
# 7 Debug: debug-level messages


sub _level_converter {
    my ($layout, $message, $category, $priority, $caller_level) = @_;
    my $levels = {
        "DEBUG" => 7,
        "INFO"  => 6,
        "NOTICE"=> 5,
        "WARN"  => 4,
        "ERROR" => 3,
        "FATAL" => 2
    };
    return $levels->{$priority};
}
sub render {
  my($self, $message, $category, $priority, $caller_level) = @_;
  my $encoded_message = $self->SUPER::render($message, $category, $priority, $caller_level);
  my $gzipped_message;
  warn $encoded_message;
  gzip \$encoded_message =>  \$gzipped_message or die "gzip failed: $GzipError\n";
  return  $gzipped_message;
}
1;
