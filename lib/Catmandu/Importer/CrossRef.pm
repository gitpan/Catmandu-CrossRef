package Catmandu::Importer::CrossRef;

=head1 NAME

  Catmandu::Importer::CrossRef - Package that imports data form CrossRef

=cut

use Catmandu::Sane;
use Furl;
use XML::LibXML::Simple qw(XMLin);
use Moo;

with 'Catmandu::Importer';

use constant BASE_URL => 'http://doi.crossref.org/search/doi';

has base => (is => 'ro', default => sub { return BASE_URL; });
has doi => (is => 'ro', required => 1);
has usr => (is => 'ro', required => 1); 
has pwd => (is => 'ro', required => 0);
has fmt => (is => 'ro', default => sub { 'unixref' }); 

has _api_key => (is => 'lazy', builder => '_get_api_key');
has _current_result => (is => 'ro');

sub _request {
  my ($self, $url) = @_;

  my $furl = Furl->new(
    agent => 'Mozilla/5.0',
    timeout => 10,
  );
  my $res = $furl->get($url);
  die $res->status_line unless $res->is_success;

  return $res->content;
}

sub _hashify {
  my ($self, $in) = @_;

  my $xs = XML::LibXML::Simple->new();
  my $out = $xs->XMLin($in);

  return $out;
}

sub _get_api_key {
	my ($self) = @_;
	
	my $key = $self->usr;
  $key .= ':'.$self->pwd if $self->pwd;
  return $key;
}

sub _api_call {
  my ($self) = @_;

  my $url = $self->base;
  $url .= '?pid='.$self->_api_key;
  $url .= '&doi='.$self->doi;
  $url .= '&format='.$self->fmt;

  my $res = $self->_request($url);

  return $res;
}

sub _get_record {
  my ($self) = @_;

  unless ($self->_current_result) {
	  my $xml = $self->_api_call;
	  my $hash = $self->_hashify($xml);

	  $self->{_current_result} = $hash->{doi_record}->{crossref};
  };

  return $self->_current_result;
}

sub to_array {
  return [ $_[0]->_get_record ];
}

sub first {
  return [ $_[0]->_get_record ];
}

*last = \&first;

sub generator {
  my ($self) = @_;
  my $return = 1;

  return sub {
	  # hack to make iterator stop.
	  if ($return) {
		  $return = 0;
		  return $self->_get_record;
	  }
	  return undef;
  };
}

1;

=head1 SYNOPSIS

  use Catmandu::Importer::DOI;

  my %attrs = (
    doi => '<doi>',
    usr => '<your-crossref-username>',
	  pwd => '<your-crossref-password>',
	  fmt => '<xsd_xml | unixref | unixsd | info>'
  );

  my $importer = Catmandu::Importer::DOI->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # do something here
  });

=head1 DESCRIPTION

  This L<Catmandu::Importer::CrossRef> imports data from the CrossRef API given a DOI.

=head1 CONFIGURATION

=over

=item base

Base url of the API. Default is to http://doi.crossref.org/search/doi.

=item doi

Required. The DOI you want data about.

=item usr

Required. Your CrossRef username. Register first!

=item fmt

Optional. The output format. Default is to unixref.
Other possible values are xsd_xml, unixsd, info

=back

=begin HTML

<p>
<img src="https://travis-ci.org/vpeil/Catmandu-CrossRef.svg?branch=master" alt="build status" />
<img src="https://coveralls.io/repos/vpeil/Catmandu-CrossRef/badge.png?branch=master" alt="coverage status" />
</p>

=end HTML

=head1 SEE ALSO

  L<Catmandu::Importer::DOI> is an older version of this module.
  L<Catmandu::Iterable>, L<Catmandu::Importer>

=cut
