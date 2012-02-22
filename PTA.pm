package PTA::PTA;

use vars qw( @ISA );
use PTA::Parser;

@ISA = qw( PTA::Parser );

sub new {
    my($self) = new PTA::Parser;
    bless $self;
}

# load various parts of the object
sub parse {
    my($self, $filename) = @_;

    $self->load_text($filename);
    $self->load_list;
}

sub load_text {
    my($self, $filename) = @_;

    $self->clear_text;
    $self->{'text'} = [];
    open(IN, $filename) or die "Unable to open $filename";
    @{$self->{'text'}} = <IN>;
    close IN;
}

sub load_list {
    my($self) = @_;
    my($x, @list);

    $self->clear_list;
    $self->{'list'} = [];
    $self->tagged_text;

    # pointer to the beginning
    $self->{'start'} = $self->{'list'}[0];

    # create the links
    for ($x = 0; $x <= $#{$self->{'list'}}; $x++) {
	if ($x > 0) {
	    $self->{'list'}[$x]{'prev'} = $self->{'list'}[$x - 1];
	}
	if ($x < $#{$self->{'list'}}) {
	    $self->{'list'}[$x]{'next'} = $self->{'list'}[$x + 1];
	}
    }

    # alphabetize
    @list = @{$self->{'list'}};
    @list = sort { $a->{'word'} cmp $b->{'word'} ||
		   $a->{'line'} <=> $b->{'line'} ||
		   $a->{'col'}  <=> $b->{'col'} } @list;
    $self->{'list'} = \@list;
}

sub load_freq {
    my($self) = @_;
    my($item);

    $self->clear_freq;
    $self->{'freq'} = {};
    foreach $item (@{$self->{'list'}}) {
	$self->{'freq'}{$item->{'word'}} ||
	    ($self->{'freq'}{$item->{'word'}} = 0);
	$self->{'freq'}{$item->{'word'}} ++;
    }
}

sub load_coll {
    my($self, $width) = @_;
    my($item, $x, %p);

    $self->clear_coll;
    $self->load_freq;

    $self->{'coll'} = {};
    foreach $item (@{$self->{'list'}}) {
	$self->{'coll'}{$item->{'word'}} ||
	    ($self->{'coll'}{$item->{'word'}} = {});

	for ($x = 0, $p = $item->{'prev'};
	     (($x < $width) && $p);
	     $x++, $p = $p->{'prev'}) {
	    $self->{'coll'}{$item->{'word'}}{$p->{'word'}} ||
		($self->{'coll'}{$item->{'word'}}{$p->{'word'}} = 0);
	    $self->{'coll'}{$item->{'word'}}{$p->{'word'}}++;
	}

	for ($x = 0, $p = $item->{'next'};
	     (($x < $width) && $p);
	     $x++, $p = $p->{'next'}) {
	    $self->{'coll'}{$item->{'word'}}{$p->{'word'}} ||
		($self->{'coll'}{$item->{'word'}}{$p->{'word'}} = 0);
	    $self->{'coll'}{$item->{'word'}}{$p->{'word'}}++;
	}
    }
}

sub load {
    my($self, $filename) = @_;

    $self->clear;
    $self->load_text($filename);
    $self->load_list;
    # load_coll calls load_freq
    $self->load_coll;
}

# clear various parts of the object
sub clear_text {
    my($self) = @_;

    delete $self->{'text'};
}

sub clear_list {
    my($self) = @_;

    delete $self->{'list'};
    delete $self->{'start'};
}

sub clear_freq {
    my($self) = @_;

    delete $self->{'freq'};
}

sub clear_coll {
    my($self) = @_;

    delete $self->{'coll'};
}

sub clear {
    my($self) = @_;

    $self->clear_text;
    $self->clear_list;
    $self->clear_freq;
    $self->clear_coll;
}


1;
