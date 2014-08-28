package Catmandu::Importer::CrossRef;

=head1 NAME

  Catmandu::Importer::CrossRef - Package that imports data form CrossRef

=cut

use Catmandu::Sane;
use Catmandu::Importer::XML;
use Furl;
use Moo;

with 'Catmandu::Importer';

use constant BASE_URL => 'http://doi.crossref.org/search/doi';

has base => ( is => 'ro', default => sub { return BASE_URL; } );
has doi => ( is => 'ro', required => 1 );
has usr => ( is => 'ro', required => 1 );
has pwd => ( is => 'ro', required => 0 );
has fmt => ( is => 'ro', default  => sub {'unixref'} );

has _api_key => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;

        my $key = $self->usr;
        $key .= ':' . $self->pwd if $self->pwd;
        return $key;
    }
);

sub _request {
    my ( $self, $url ) = @_;

    my $ua = Furl->new( timeout => 20 );

    my $res;
    try {
        $res = $ua->get($url);
        die $res->status_line unless $res->is_success;

        return $res->content;
    }
    catch {
        Catmandu::Error->throw("Status code: $res->status_line");
    };

}

sub _hashify {
    my ( $self, $in ) = @_;

    my $xml = Catmandu::Importer::XML->new( file => \$in );
    return $xml->to_array;
}

sub _api_call {
    my ($self) = @_;

    my $url = $self->base;
    $url .= '?pid=' . $self->_api_key;
    $url .= '&doi=' . $self->doi;
    $url .= '&format=' . $self->fmt;

    my $res = $self->_request($url);

    return $res;
}

sub _get_record {
    my ($self) = @_;

    my $xml = $self->_api_call;

    return $self->_hashify($xml);
}

sub generator {
    my ($self) = @_;

    return sub {
        state $stack = $self->_get_record;
        my $rec = pop @$stack;
        $rec->{doi_record}->{crossref}
            ? return $rec->{doi_record}->{crossref}
            : return undef;
    };
}

1;

=head1 SYNOPSIS

  use Catmandu::Importer::CrossRef;

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

=head1 SEE ALSO

  L<Catmandu::Importer::DOI> is an older version of this module.
  L<Catmandu::Iterable>, L<Catmandu::Importer>

=cut
