package Data::SearchEngine::Zebra::Results;

use Carp;
use ZOOM;
use XML::Simple;
use Data::Dumper;
use MARC::Record;
use Moose;
use Data::SearchEngine::Item;
use Data::SearchEngine::Query;
use Data::SearchEngine::Paginator;

extends 'Data::SearchEngine::Results';

use strict;
use warnings;

has query => ( is => 'rw', isa => 'Data::SearchEngine::Query' );
has entries_per_page => ( is => 'rw', isa => 'Int');

sub BUILD {
    my $self = shift;
    
}

sub retrieve{
    my ($self, $tmpresults, $zconn) = @_;
    my $offset = $self->query->{"page"};
    $offset = 0 unless ($offset);
    
	my $results = Data::SearchEngine::Results->new(
		query       => $self->query
	);
    
	while ((my $i = ZOOM::event([$zconn])) != 0) {
	    my $event = $zconn->last_event();
		if ( $event == ZOOM::Event::ZEND ) {
            my @sorted_products; # fill with a search or something
            my $scores; # fill with search scores
    
            my $start = time;
            
            # Items start
			my $first_record = defined( $offset ) ? $offset+1 : 1;
			my $hits = $tmpresults->size();
            $results->{pager} = Data::SearchEngine::Paginator->new(
					               current_page => $offset,
					               entries_per_page => $self->query->{"count"},
					               total_entries => $hits
		                        );

			my $last_record = $hits;
			if ( defined $self->query->{"count"} && $offset + $self->query->{"count"} < $hits ) {
				$last_record  = $offset + $self->query->{"count"};
			}

			for my $j ( $first_record..$last_record ) {
				my $record = $tmpresults->record( $j-1 )->raw(); # 0 indexed
				my $_record = MARC::Record->new_from_usmarc($record);
				my $field = $_record->field('999');
	            my $item = Data::SearchEngine::Item->new(
	                id      => $field->subfield('c'),
	                score   => 0
	            );
	            $item->set_value('record', $record);
	            $results->add($item);
			}
            # Items end

            $results->elapsed(time - $start);
		}
	}

    return ($results);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::SearchEngine::Zebra::Results - Zebra search engine abstraction.

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 query

Data::SearchEngine::Query object

=head2 entries_per_page

Number of entries per page.

=head1 METHODS

=head2 retrieve

Returns a Data::SearchEngine::Results object from a ZOOM::Connection resultset

=head1 AUTHOR

Juan Romay Sieira <juan.sieira@xercode.es>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Xercode Media Software.

This is free software, licensed under:

    The GNU General Public License, Version 3, 29 June 2007

=cut