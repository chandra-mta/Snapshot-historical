package RDB;

use fields qw( fh col defs ncols pos comments loc mode file bindvals
	       bindmap bindsub nsplitcols hdrvars hdr_written );

use strict;
use vars qw( $VERSION $DEFN_RE );

$DEFN_RE = '^\s*' .
           '(?:(\d+)\s+)?' .
           '([\w%:@=,.][\w%:@=,.#-]*)' .
           '\s+' .
           '(\d*)' .
           '([SsNnMm])' .
           '([<=>]?)' .
           '(?:\s*$|\s+(.+))' .
           '$'; #'

$VERSION = '1.42';

use FileHandle;
use Carp qw( carp croak );

=head1 NAME

RDB - object methods for dealing with rdb files

=head1 SYNOPSIS

  use RDB;

  $rdb = new RDB;
  $rdb->open( 'foo.rdb' ) || die;

  $rdb = new RDB 'foo.rdb' or die;

  $rdb = new RDB \*STDIN or die;

  $rdb = new RDB ( 'name' => 'S', 'id' => 'N' );

  $rdb->init( );
  $rdb->init( 'name' => 'S', 'id' => 'N' );

  $rdb->add_col( 'slap' => 'S', 'gurgle' => 'N' );
  $rdb->add_col( $other_rdb );

  $rdb->delete_col( 'gurgle' );

  @defs = ( 'name' => 'S', 'id' => 'N' );
  $rdb->init( \@defs );
  
  $rdb->init( $other_rdb );

  $rdb->rewind;

  $rdb->bind( { col1 => \$col1, col2 => \$col2 } );
  while ( $rdb->read( ) ) { print $col1, $cols, "\n"; }

  while( $rdb->read( \%data ) ) { ... }
  while( $rdb->read( \@data ) ) { ... }

  while( $verbatim_line = $rdb->read_line ) { print $verbatim_line };

  $rdb->write_hdr( );
  $rdb->write_hdr( \*STDOUT );

  $rdb->write( \%data );
  $rdb->write( \@data );
  $rdb->write( @data );

  $rdb->set( \%attr );
  $rdb->set( { AlwaysBind => 1 } );
  
  @header_var_names = $rdb->vars;

  $foo = $rdb->getvar( 'foo' );
  $rdb->setvar( foo => 33 );
  $hdrvars = $rdb->getvars;
  print $hdrvars->{foo};
  $rdb->delvar ( 'foo' );

=head1 DESCRIPTION

This module eases use of RDB data files.  It creates RDB objects
which contain the necessary information for interpreting and
manipulating RDB files.

=head1 Constructor

=over 8 

=item new [I<file or filehandle>, [I<mode>]]|I<\@defs>]

B<new> is the constructor, and must be called before any other methods
are invoked.  It creates an B<RDB> object.  It can optionally be
passed a filename to be opened and an optional mode or a reference to a glob
(which is interpreted as an already open file handle).  It then
invokes the RDB::open method on the file/file handle.  If a mode is
not specified, it is opened with mode C<<>.  If the passed argument
is a reference to an array, RDB::init is invoked with
that argument.

=cut

sub new
{ 
  my $this = shift;
  my $class = ref($this) || $this;
  my $rdb = {
	     fh       => undef,
	     col      => [],
	     defs     => {},
	     ncols    => undef,
	     'pos'    => {},
	     comments => [],
	     hdrvars  => {},
	     loc      => undef,
	     mode     => undef,
	     file     => undef,
	     bindmap  => [],
	     bindsub  => undef,
	     attr     => { AlwaysBind => 0 },
	     hdr_written => 0,	# true if header has been written
	     nsplitcols => 0,	# number of columns to pass to split;
				# used only if variables are bound to
				# columns
	    };

  bless $rdb, $class;

  if ( @_ )
  {
    if ( ! ref($_[0]) or ref($_[0]) eq 'GLOB' )
    {
      my ( $file, $mode ) = @_;
      $rdb->open( $file, $mode ) or return undef;
    }
    elsif( ref( $_[0]) ne 'CODE' )
    {
      $rdb->init( $_[0] );
    }
    else
    {
      croak 'RDB::new called with bogus argument';
    }
  }

  return $rdb;
}

=back

=head1 Object action methods

=over 4

=cut

=item bind( \%bindhash [, \%attrs ] )

B<bind> simplifies the processing of rdb files by allowing the
automatic assignment of values read from the rdb file to Perl
variables or arrays. Each time that the read method is called with no
arguments, it will update the variables specified in preceding calls
to C<bind>.  B<bind> takes a hash of columns to be bound; the keys are
the column names, their values are references to either scalars or
arrays.  In the former case, the scalar will be assigned the column's
value.  In the latter case, the column's value is pushed onto the end
of the array.  ( Note that the argument to bind is a hash just to
enforce the correct number of items.)  For example,

	$rdb->bind( { col1 => \$col1, col2 => \$col2 } );
	while ( $rdb->read( ) )
	{
	  print "$col1, $cols\n";
	}

Or, using arrays,

	my ( @col1, @col2 );
	$rdb->bind( { col1 => \@col1, col2 => \@col2 } );
	1 while ( $rdb->read( ) );
	for( $i = 0 ; $i < @col1 ; $i++ )
	{
	  print $col1[$i], ' ', $col2[$i], "\n";
	}


If the same column is specified in I<succeeding> calls to B<bind>, the
new binding will override the previous binding.

However, if the same column should be bound to multiple variables, the
pC<Override> attribute may be reset using the second argument to
B<bind>:

	$rdb->bind( { col1 => \$col1, col2 => \$col2 } );
	$rdb->bind( { col1 => \$col1_copy }, { Override => 0 } );

The column C<col1> will now be written to both C<$col1> and C<$col1_copy>.

=cut

sub bind
{
  @_ == 2 || @_ == 3 or croak 'usage: $rdb->bind( \%bindmap [, \%attrs] )';

  my $rdb = shift;
  my $bindmap = shift;
  
  croak 'RDB::bind: argument not a hash' 
    unless ref $bindmap eq 'HASH';

  my $attrs = shift;
  croak 'RDB::bind: attrs not a hash' 
    if $attrs && ref $attrs ne 'HASH';

  $attrs = { Override => 1, $attrs ? %$attrs : () };

  my @bindmap = @{$rdb->{bindmap}};

  # if overriding existing map, retain entries from old map which
  # aren't being overridden
  if ( $attrs->{Override} )
  {
    my @new;
    while ( @bindmap )
    {
      my $bindval = shift @bindmap;
      push @new, $bindval
	unless $bindmap->{$bindval->[0]};
    }
    @bindmap = @new;
  }


  while( my ( $col, $var ) = each %$bindmap )
  {
    push @bindmap, [ $col, $var ];
  }

  $rdb->{bindmap} = \@bindmap;

  $rdb->__bind_sub;
}


# optimizations here must take into account a non one-to-one mapping
# i.e., more than one variable may be bound to a column.
sub __bind_sub
{
  my $rdb = shift;

  my @sub;

  return unless @{ $rdb->{bindmap} };

  for ( my $i = 0 ; $i < @{ $rdb->{bindmap} } ; $i++ )
  {
    my ($col, $var) = @{ $rdb->{bindmap}[$i] };

    croak( "RDB::bind: column `$col' not defined in rdb file")
      unless exists $rdb->{'pos'}->{$col};

    $rdb->{nsplitcols} = $rdb->{'pos'}{$col} + 2
      if $rdb->{nsplitcols} < $rdb->{'pos'}{$col} + 2 ;

    if ( 'SCALAR' eq ref($var) )
    {
      push @sub, sprintf( '${$rdb->{bindmap}[%d][1]} = $data[%d];',
		       $i, $rdb->{'pos'}->{$col} );
    }
    elsif ( 'ARRAY' eq ref($var) )
    {
      push @sub, sprintf( 'push @{$rdb->{bindmap}[%d][1]}, $data[%d];',
		       $i, $rdb->{'pos'}->{$col} );
    }
    else
    {
      croak( "RDB::bind: column `$col' -> must bind to \\\@ or \\\$" )
    }
  }

  my $sub = join( "\n",
	       'use integer;',
	       'my $rdb = shift;',
	       qq{my \@data = split( "\\t", shift, $rdb->{nsplitcols});},
	       @sub );

  $rdb->{bindsub} = $rdb->__make_sub( $sub );
  croak if $@;
}

sub __make_sub
{
  my ( $rdb, $statements ) = @_;

  my $sub;
  eval qq( \$sub = sub { $statements } );
  return $sub;
}

=item close

explicitly close an rdb file.  This usually need not be called, as the
file will be closed when the RDB object is destroyed.

=cut

sub close
{
  1 == @_ or croak 'usage: $rdb->close()';

  my ( $rdb ) = @_;

  if ( $rdb->{fh} )
  {
    $rdb->write_hdr if _is_write( $rdb->{mode} ) && !$rdb->{hdr_written};
    $rdb->{loc} = tell($rdb->{fh});
    close $rdb->{fh};
    $rdb->{fh} = undef;
  }
}

sub _is_write
{
  my $mode = shift;
  return $mode =~ />/;
}

=item init( I<@defs>|I<\@defs>|I<$rdb>)

Initialize the rdb object with a set of columns.  A column is
specified by both a name and a definition.  Definitions technically
consist of four parts: the column name, it's type, output alignment,
and description.  The latter are optional and are usually omitted.
Column types are one of C<N>, C<S>, or C<M>, for numeric, string, and
month data.  Alignment is one of C<<> or C<>>.

B<init> is passed either an array (or list), an array reference, or a
reference to another B<RDB> object.  In the latter case, the column
definitions of the other object are duplicated.  In the former cases,
the array must contain column name and definition pairs.

The definition may take any of the following forms:

=over 8

=item *

If the definition is a scalar, it should be the column type:

  $rdb->init( c1 => 'N' );

=item *

if the definition is a hash reference, it should have at least
the key C<type>, and may optionally have the keys C<width>, C<align>,
or C<desc>

  $rdb->init( c1 => { type => 'N', width => 3, align => '<',
                      desc => 'This column is meaningless } );

=item *

if the definition is an array reference, it may have up to four
elements; the type, width, alignment, and description, in order.
The last three are optional.  

  $rdb->init( c1 => [ 'N', 3, '<', 'This column is meaningless' ] );

=back

Any of these forms may be mixed:

  $rdb->init( c1 => 'N', 
              c2 => [ 'N', 32 ],
              c3 => { type => 'N', desc => 'What A Nice Column' } );

=cut

sub init
{
  2 <= @_ or croak 'usage: $rdb->init(@defs|\@defs)';
  my $rdb = shift;

  $rdb->{ncols} = 0;
  $rdb->{col} = [];
  $rdb->{defs} = {};
  $rdb->{pos} = {};
  $rdb->{comments} = [];
  $rdb->{hdrvars} = {};

  if ( UNIVERSAL::isa( $_[0], 'RDB' ) )
  {
    my $orig = $_[0];
    $rdb->{comments} = [ @{$orig->{comments}} ];
    $rdb->{hdrvars}  = { %{$orig->{hdrvars}}  };
  }


  eval { $rdb->_addcols(@_); };
  croak "RDB::init $@" if $@;
}

=item init_tpl( $file_name | \$tpl_string )

Initialize an RDB object from an RDB header template. If the passed
argument is a scalar, it should contain the name of a file containing
the template.  If it's a reference it should be a reference to a
scalar containing the template.  An RDB header template is description
of the header in the following format.

Each column is specified on a separate line, and contains up to
four white space delimited fields:

=over 8

=item 1

an optional field containing the column's zero based index.  If not specified,
the ordering of the field in the template is used.  For example,

   fee S
   fie N
   fo  N
   fum N
	
is equivalent to

   0 fee S
   1 fie N
   2 fo  N
   3 fum N

Be careful when mixing lines with and without an index: 

     fee S
   2 fie N
     fo  N
     fum N

is equivalent to

   0 fee S
   2 fie N
   2 fo  N
   3 fum N

which will result in an error.  Indices must be unique.

There's a further degeneracy which must be avoided:

   3 N S

Is that an index of C<3>, a name of C<N> and a type of C<S>, or is
that a name of C<3>, a type of C<N> and a description of C<S>?
It is parsed as the former.  To get the latter interpretation,
you'll have to include an index field.


=item 2

the column name.  it may appear in quotes.

=item 3

the column type.  it may include the column width as a prefix

=item 4

an optional column description

=back

Comment lines may be present, and are indicated by a leading C<#> character.

For example,

  # P-to-H Decenter parameters derived from XRCF HSI off-axis images
  # (single shell); used pitch=0, yaw=-20 arcmin data.
  #
   0               fee  6S	what i get paid
   1               fie 10N	upon you
   2               fo  10N	fight or no?
   3               fum  9N	ble

=cut


sub init_tpl
{
  my $rdb = shift;

  my $tpl = shift;

  $rdb->{ncols} = 0;
  $rdb->{col} = [];
  $rdb->{defs} = {};
  $rdb->{pos} = {};
  $rdb->{comments} = [];
  $rdb->{hdrvars} = {};

  my @cols;

  my $idx = 0;
  unless ( 'SCALAR' eq ref $tpl )
  {
    my $fh = new IO::File $tpl, "r" or
      croak( "unable to open $tpl\n" );

    while ( <$fh> )
    {
      chomp;
      $rdb->_parse_template( \@cols, $idx++, $_ );
    }
  }
  else
  {
    $rdb->_parse_template( \@cols, $idx++, $_ ) for  split( "\n", $tpl );
  }

  # ensure that there are no duplicate indices
  my %idxs = map { ( $_->{index}, 1 ) } @cols;
  croak( "duplicate index values in template\n" )
    if keys %idxs != @cols ;

  $rdb->_addcols( map { ( $_->{name}, $_ ) }
		    sort { $a->{index} <=> $b->{index} } @cols );
}

sub _parse_template
{
  my ( $rdb, $cols, $idx, $tpl ) = @_;
  
  local $_ = $tpl;

  # store comments
  if ( /^\s*\#/ )
  {
    s/^#//;
    $rdb->add_comments( $_ ) ;
  }
  else
  {
    
    if ( $tpl =~ /$DEFN_RE/ )
    {
      push @$cols, { 
		  index => defined $1 ? $1 : $idx,
		  name => $2,
		  width => $3,
		  type => $4,
		  align => $5,
		  desc => $6 };
    }
    else
    {
      croak( "illegal template definition `$tpl'\n");
    }
    
  }
}


=item write_tpl( $filename | $fh)

Write an RDB template for the current RDB object.  The argument may be
a scalar, it which case it should contain the name of a file to which
to write the template, or a filehandle.

=cut

sub write_tpl
{
  my $rdb = shift;
  
  my $fh = shift;
  unless ( ref $fh )
  {
    my $fh_t = new IO::File $fh, "w"
      or croak( "unable to create $fh\n" );
    $fh = $fh_t;
  }
  $rdb->_write_hdr_comments( $fh );

  # turn off warnings here; don't care about undefined values, as
  # they are just attributes that haven't been defined.
  local $^W = 0;

  # index, name, type, desc
  my %max = ( name => 0, width => 0);
  foreach (  @{$rdb->{col}} )
  {
    $max{name} = length( $_ ) if $max{name} < length( $_ );
    $max{width} = length( $rdb->{defs}{$_}{width} ) if $max{width} < length( $rdb->{defs}{$_}{width} );
  }

  foreach ( sort { $rdb->{pos}{$a} <=> $rdb->{pos}{$b} } @{$rdb->{col}} )
  {
    printf $fh "%4d\t%$max{name}s\t%-$max{width}s%s%s\t%s\n",
          $rdb->{pos}{$_}, $_,
               $rdb->{defs}{$_}{width},
               $rdb->{defs}{$_}{type},
	       ($rdb->{defs}{$_}{align} || ' '),
	       $rdb->{defs}{$_}{desc};
  }
}

=item add_col( I<@defs>|I<\@defs>|I<$rdb>)

Add new columns to the rdb object.  See the description of the
B<init()> method for the specification of the column names and
definitions.  Existing columns are not duplicated; their definitions
are changed to the passed type.

=cut

sub add_col
{
  2 <= @_ or croak 'usage: $rdb->add_col(@defs|\@defs)';
  my $rdb = shift;

  eval { $rdb->_addcols(@_); };
  croak "RDB::add_col $@" if $@;
}

sub _addcols
{
  my $rdb = shift;

  my @defs;

  if ( 2 <= @_ )
  {
    @defs = @_;
    @defs % 2 and die 'missing definition';
  }
  else
  {
    ref($_[0]) or die 'argument must be list or reference to array';
    if ( ref $_[0] eq 'ARRAY' )
    {
      @defs = @{$_[0]};    
    }
    else
    {
      my $src = shift;

      if ( UNIVERSAL::isa( $src, 'RDB' ) )
      {
	push @defs, map { $_, $src->{defs}{$_} }  @{$src->{col}};
      }
      else
      {
	die( "don't know what to make of argument" );
      }
    }
  }
  
  my @fields = qw( type width align desc );

  # slurp column name, definition pairs 
  while( my ( $col, $def ) = splice( @defs, 0, 2 ) )
  {
    unless ( exists $rdb->{defs}{$col} )
    {
      push @{$rdb->{col}}, $col;
      $rdb->{pos}{$col} = $rdb->{ncols};
      $rdb->{ncols}++;
    }

    # it's a hash; it should have 'width', 'type', 'align', 'desc' fields
    if ( 'HASH' eq ref $def  )
    {
      $rdb->{defs}{$col}{$_} = $def->{$_} || ''
	foreach @fields;
    }

    # it's an array; it should have 4 fields, as above
    elsif ( 'ARRAY' eq ref $def )
    {
      my @tmp = @{$def};
      $rdb->{defs}{$col}{$_} = shift @tmp || ''
	foreach @fields;
    }

    # any other type of ref is bogus
    elsif( ref $def )
    {
      croak( "RDB::init: illegal reference in def for `$col'" );
    }

    # ordinary scalar, it's the type
    else
    {
      @{$rdb->{defs}{$col}}{@fields} = ( '', $def, '', '' );
    }
  }
}



=item delete_col( @cols )

delete the specified columns from the object.  This is only applicable
to RDB files open for writing, and only before the RDB header has
been written out.

	$rdb->delete_col( 'a', 'b' );

=cut

sub delete_col
{
  @_ > 1 or croak 'RDB::delete_col( @cols )';
 
  my $rdb = shift;
  my @cols = @_;

  return if ($rdb->{mode} && ! _is_write($rdb->{mode}) ) 
    || $rdb->{hdr_written};

  foreach my $col ( @cols )
  {
    croak( "RDB::delete_col `$col' not defined" )
      unless exists $rdb->{'pos'}->{$col};

    delete $rdb->{'defs'}->{$col};

    $rdb->{bindmap} = [ grep { $_->[0] ne $col } @{$rdb->{bindmap}} ];
    $rdb->{col} = [ grep { $_ ne $col } @{$rdb->{col}} ];
    $rdb->__bind_sub;
    $rdb->{ncols}--;
  }
  $rdb->{'pos'} = {};
  @{$rdb->{'pos'}}{@{$rdb->{'col'}}} = ( 0..$#{$rdb->{col}} );

}

=item set( \%attr )

B<set> specifies the values of various attributes for the object.
The passed reference should point to a hash which may contain
the following keys:

=over 8

=item AlwaysBind

If this is set, e.g.,

  $rdb->set( { AlwaysBind => 1} )

if B<RDB::bind> has been called to set up bindings between columns and
Perl variables, the Perl variables will always be updated, regardless of which 
form of B<RDB::read> is called.

=back

=cut

sub set
{
  my $rdb = shift;

  my $attr = shift;

  croak 'usage $rdb->attr( \%attr )' unless 'HASH' eq ref $attr;

  $rdb->{attr} = { %{$rdb->{attr}}, $attr ? %$attr : () };
}


=item open( I<file or filehandle> [, I<mode>] )

B<open> connects to a file (if it is passed a scalar) or to an
existing file handle (if it is passed a reference to a glob).
If mode is not specified, it is opened as read only, otherwise
that specified.  Modes are the standard Perl-ish ones (see
the Perl open command).  If the mode is read only or read/write, it reads
and parses the RDB header.  It returns the
undefined value upon error.

=cut

sub open
{
  @_ >=2 or croak 'usage : $rdb->open( $file [, $mode] )';
  my ( $rdb, $file, $mode ) = @_;

  $mode = '<' if ! defined $mode;
  $rdb->{mode} = $mode;
  my $fh = new FileHandle;

  if ( ref($file) )
  {
    $fh->fdopen( $file, $mode ) || return undef;
  }
  else
  {
    $fh->open( $file, $mode ) || return undef;
  }

  $rdb->{file} = $file;

  # if this is open for reading, suck in the header
  if ( $mode =~ /[<+]/ )
  {
    $rdb->{comments} = [];
    while( <$fh> )
    {
      last unless /^\s*\#/;
      chop;

      s/^\s*#//;
      push @{$rdb->{comments}}, $_;

      # grab header variable
      if ( /^:\s*(\w+)\s*=\s*(.*)/ )
      {
	$rdb->{hdrvars}{$1} = $2;
      }
    }
    return undef unless defined $_;
    $rdb->{'col'} = [];
    $rdb->{'defs'} = {};
    $rdb->{'pos'} = {};

    chop;
    @{$rdb->{'col'}} = split( "\t" );
    @{$rdb->{'pos'}}{@{$rdb->{'col'}}} = ( 0..$#{$rdb->{col}} );
    $_ = <$fh>;
    return undef unless defined $_;
    chop;

    # chop up definition into width, type, alignment, and description
    @{$rdb->{'defs'}}{@{$rdb->{'col'}}} = 
      map{ /(\d+)?([nNsSmM]|-+)([<>])?(?:\s+(.*))?/; 
	   { width => $1,
	     type  => $2,
	     align => $3,
	     desc  => $4} } split( "\t" );

    # ensure that we got valid definitions
    while( my ( $col, $def ) = each ( %{$rdb->{defs}} ) )
    {
      croak "unrecognized definition for column `$col'"
	unless defined $def->{type};
      # handle old /rdb format
      $def->{type} = 'S' if $def->{type} =~ /-+/;
    }

    $rdb->{start} = tell;
    $rdb->{ncols} = @{$rdb->{'col'}};
  }

  $rdb->{fh} = $fh;
  $rdb->{loc} = tell($rdb->{fh});
  1;
}

=item read( [I<\%data>|I<\@data>] )

Read in the next line from the rdb database, storing the columns into
either a hash keyed off of the column names (if passed a reference to
the hash), an array (if passed a reference to the array), or into
scalars specified by previous calls to the C<bind> method (if C<read>
is called with no arguments). It returns the undefined value upon end
of file.  It does not check to ensure that there are enough columns in
the input.  For example:

	$rdb->read(\%data);
	print "foo = $data{foo}\n";

	$rdb->read(\@data);
	print "The first column has value $data[0]\n";

	$rdb->bind( { foo => \$foo } );
	$rdb->read();
	print "Foo = $foo\n";

=cut

sub read
{
  @_ >=1 or croak 'usage : $rdb->read( [\%data|\@data] )';

  my $rdb = shift;


  my $fh = $rdb->{fh};
  return undef unless defined( $_ = <$fh> );
  chomp;
  $rdb->{loc} = tell($rdb->{fh});

  my $data = shift;

  if ( ref $data eq 'HASH' )
  {
    @{$data}{@{$rdb->{col}}} = split( "\t", $_, $rdb->{ncols} );
  }
  elsif ( ref $data eq 'ARRAY' )
  {
    @{$data} = split( "\t", $_, $rdb->{ncols} );
  }

  if ( ! defined $data || $rdb->{attr}{AlwaysBind} )
  {
    # use bound variables to return data

    croak 'RDB::read no variables have been bound'
      unless defined $rdb->{bindsub};

    &{$rdb->{bindsub}}( $rdb, $_ );
  }
  1;
}

=item read_line

C<read_line> reads a line from the rdb file without parsing it (even
to chop off the end).  It returns C<undef> upon end of file.

=cut

sub read_line
{
  @_ ==1 or croak 'usage : $rdb->read_line(  )';

  my $rdb = shift;

  my $fh = $rdb->{fh};
  $_ = <$fh>;
  $rdb->{loc} = tell($rdb->{fh});

  return undef unless defined $_;
  chomp;

  return $_;
}

=item rename( \%renamehash )

B<rename> is passed a hash of columns to be renamed; the keys are
the old column names, their values are the new names.  It's a hash
just to enforce the correct number of items.  For example,

	$rdb->rename( { oldcol => 'newcol', foocol => 'boocol' } );

=cut
#'
sub rename
{
  @_ == 2 or croak 'RDB::rename( \%renamevals )';
 
  my $rdb = shift;
  my $renames = shift;

  croak 'RDB::rename: argument not a hash'
    unless ref $renames eq 'HASH';

  while ( my ( $old, $new ) = each %$renames )
  {
    # ignore 'em if they're the same; saves grief later
    next if $old eq $new;

    croak( "RDB::rename `$old' not defined in rdb file" )
      unless exists $rdb->{'pos'}->{$old};

    croak( "RDB::rename '$new' already defined in rdb file" )
      if exists  $rdb->{'pos'}->{$new};

    $rdb->{'defs'}->{$new} = $rdb->{'defs'}->{$old};
    delete $rdb->{'defs'}->{$old};

    $rdb->{'pos'}->{$new} = $rdb->{'pos'}->{$old};
    delete $rdb->{'pos'}->{$old};

    foreach ( @{$rdb->{bindmap}} )
    {
      $_->[0] = $new if $_->[0] = $old;
    }
  }

  foreach ( @{$rdb->{'col'}} )
  {
    $_ = $renames->{$_} if exists $renames->{$_};
  }
}


=item reopen

B<reopen> reopens a file that has previously been opened and closed,
positioning the filepointer to where it was before it was closed.  It
retains the previous access mode.  It does not reopen files passed to
the original call of rdb::open as references.  It returns the
undefined value upon error.

=cut

sub reopen
{
  @_ == 1 or croak 'usage : $rdb->reopen()';
  my ( $rdb ) = @_;

  return undef unless defined $rdb->{loc};

  my $fh = new FileHandle;

  if ( ref($rdb->{file}) )
  {
    croak "can't reopen a reference";
  }
  else
  {
    $fh->open( $rdb->{file}, $rdb->{mode} ) || return undef;
  }

  $rdb->{fh} = $fh;


  # if $rdb->{loc} is -1, at EOF (empirically determined)
  if ( $rdb->{loc} > 0 )
  {
    seek( $rdb->{fh}, $rdb->{loc}, 0 )
  }
  else
  {
    seek( $rdb->{fh}, 0, 2 )
  }

  1;
}

=item rewind

Rewind the file back to the first data position (i.e., after
the header).  Obviously this only works if the file is truly
a file, and not a pipe.

=cut

sub rewind
{
  1 == @_ or croak 'usage: $rdb->rewind()';

  my ( $rdb ) = @_;

  if ( defined $rdb->{start} )
  {
    # if $rdb->{loc} is -1, at EOF (empirically determined)
    if ( $rdb->{start} > 0 )
    {
      seek( $rdb->{fh}, $rdb->{start}, 0 )
    }
    else
    {
      seek( $rdb->{fh}, 0, 2 )
    }
  }
  $rdb->{loc} = $rdb->{start};
}



=item write( @data|\@data|\%data )

Write the passed data to the rdb file. If an array or a
reference to an array is passed, it must have the correct number
of columns, and must be in the same order as the columns in the
rdb file.  If a reference to a hash is passed, the data are
extracted from the hash.

=cut

sub write
{
  @_ >= 2 or croak 'usage : $rdb->write( @data|\@data|\%data )';
  
  my $rdb = shift;
  my $fh = $rdb->{'fh'};

  # turn off warnings here; don't care about undefined values, as
  # they will just get mapped to empty (undefined) columns.

  local $^W = 0;

  $rdb->write_hdr unless $rdb->{hdr_written};

  if ( @_ > 1  or ! ref( $_[0]) )
  {
    # must be an array.  assume it's in the same order as the columns
    croak (
	   'RDB::write -> incorrect number of data elements: got ',
	   scalar @_, ' expected ', $rdb->{ncols} )
      if @_ != $rdb->{ncols};
    print $fh join( "\t", @_ ), "\n";
  }
  elsif ( ref( $_[0] ) eq 'HASH' )
  {
    # must be a hash.
    print $fh join( "\t", @{$_[0]}{@{$rdb->{'col'}}} ), "\n";
  }
  elsif ( ref( $_[0] ) eq 'ARRAY' )
  {
    # must be an array
    croak (
	   'RDB::write -> incorrect number of data elements: got ',
	   scalar @{$_[0]}, ' expected ', $rdb->{ncols} )
      if @{$_[0]} != $rdb->{ncols};

    print $fh join( "\t", @{$_[0]} ), "\n";
  }
  $rdb->{loc} = tell($rdb->{fh});
}

=item write_hdr( [<I<filehandle>>] )

Write the RDB header to the passed file handle, if present,
or to the filehandle associated with the RDB object.  Header lines
containing header variables will be updated with the most recent
value.  New header variables are appended to the end of the header.
B<write_hdr> is automatically called for you if you try to B<write>
or B<close> the object.

=cut

sub write_hdr
{
  @_ >=1 or croak 'usage : $rdb->write_hdr( [$fh] )';
  
  my ( $rdb, $fh ) = @_;

  return if $rdb->{hdr_written};

  $fh = $rdb->{fh} unless defined $fh;

  return unless defined $fh;

  $rdb->_write_hdr_comments( $fh );


  # turn off warnings here; don't care about undefined values, as
  # they are just attributes that haven't been defined.
  {
    local $^W = 0;
    
    print $fh join( "\t", @{$rdb->{'col'}} ), "\n";
    print $fh join( "\t", 
		    map { "$_->{width}$_->{type}$_->{align}" .
			    ( $_->{desc} ? " $_->{desc}" : '' )} 
		    @{$rdb->{'defs'}}{@{$rdb->{'col'}}}),
    "\n";
    $rdb->{loc} = tell($rdb->{fh});
  }
  $rdb->{hdr_written}++;
}

sub _write_hdr_comments
{
  my $rdb = shift;
  my $fh = shift;

  my %hdrvar_written;
  foreach ( @{$rdb->{comments}}) 
  {
    # update header variables
    if ( /^(:\s*(\w+)\s*=\s*).*/ )
    {
      print $fh "#$1", $rdb->{hdrvars}{$2}, "\n";
      $hdrvar_written{$2}++;
    }
    else
    {
      print $fh "#$_\n";
    }
  }

  # now write out header variables that weren't in the comments
  print $fh "#: $_ = ", $rdb->{hdrvars}{$_}, "\n" 
    foreach grep { !$hdrvar_written{$_} } sort keys %{$rdb->{hdrvars}};
}


sub DESTROY
{
  my ( $rdb ) = @_;
  $rdb->close();
}

=back

=cut

#################################################################
# object access methods

=head1 Object data methods

Once the object is created, you can access the object's
attributes using the following functions:

=over 4

=item add_comments( @comments )

Append the passed list of comments to the header comment lines.  The
comments should neither begin with a leading pound sign nor end with a
newline.  This method doesn't add any leading white space to the
comment, so you may wish to do that for the sake of legibility.  If
the comment line defines a header variable, the first character must
be a C<:>.  You can later change it's value with B<setvar()> or
re-read it with B<getvar()>.

=cut

sub add_comments
{
  my $rdb = shift;

  foreach ( @_ )
  {
    push @{$rdb->{comments}}, $_;
    
    if ( /^:\s*(\w+)\s*=\s*(.*)/ )
    {
      $rdb->{hdrvars}{$1} = $2;
    }
    
  }
}

=item col

This returns a list containing the names of the columns in the
RDB table if the calling routine is expecting a list, otherwise
it returns a reference to the list of columns.

	@cols = $rdb->col;
	$cols_ref = $rdb->col;

=cut

sub col
{
  my $rdb = shift;
  return wantarray ? @{$rdb->{col}} : [ @{$rdb->{col}} ];
}

=item comments( [@comments] )

This returns a list containing the header comment lines.  The
leading pound signs and trailing newline are
removed.

	@comments = $rdb->comments;
	$rdb->comments( @replacement_comments );

B<comments> takes as an optional argument a list containing new
comments.  These will I<replace> the existing ones.  This method
doesn't add any leading white space to the comment, so you may wish to
do that for the sake of legibility.  To delete the comments, pass
it C<undef>:

	$rdb->comments( undef );

=cut

sub comments
{
  my $rdb = shift;

  if ( 1 == @_ && ! defined $_[0] )
  {
    $rdb->{comments} = [];
  }
  elsif ( @_ )
  {
    $rdb->{comments} = [];
    $rdb->add_comments( @_ );
  }

  return @{$rdb->{comments}};
}

=item defs( [$name | @names] )

This method is deprecated.  Use B<type> instead.

=cut

sub defs
{
   my $rdb = shift;
   $rdb->type( @_ );
}

=item defn( [$name | @names] )

If called with no arguments, C<defn> returns a hash containing the
column definitions, keyed off of the column names.  The optional arguments
are names of columns for which to return a definition.  In a scalar context
it returns the definition for the first argument; in an array context it
returns an array of definitions.  If a column doesn't exist, its definition is
given as the undefined value.

A definition is returned as a hash reference.  The hash has keys
C<type>, C<width>, C<align>, and C<desc>.  Don't change the contents
of the hashes returned!!

=cut

sub defn
{
  my $rdb = shift;

  return
    @_ ? 
      (wantarray ? map { $rdb->{defs}{$_} } @_ 
                 : $rdb->{defs}{$_[0]} )
       : %{$rdb->{defs}};
}


=item fh

This returns the filehandle to which the RDB file is attached,
or the undefined value if it hasn't yet been attached.
To attach a filehandle to an existing B<RDB> object, use
the C<RDB::open> method.

	$fh = $rdb->fh;

=cut
#'
sub fh
{
  my $rdb = shift;
  return $rdb->{fh};
}

=item file

returns the filename or handle passed to the C<new> or C<open> method.

=cut

sub file
{
  my $rdb = shift;
  return $rdb->{file};
}

=item ncols

This returns the number of columns in the file.

	$ncols = $rdb->ncols;

=cut

sub ncols
{
  my $rdb = shift;
  return $rdb->{ncols};
}

=item pos

If called with no arguments, C<pos> returns a hash relating the column
names to their zero-indexed position, keyed off of the column names.
The optional arguments
are names of columns for which to return a position.  In a scalar context
it returns the position for the first argument; in an array context it
returns an array of positions.  If a column doesn't exist, its position
is given as the undefined value.

	%pos = $rdb->pos;
	$pos_of_col = $rdb->pos( $col );
        @pos{@cols} = $rdb->defs(@cols);

=cut

sub pos
{
  my $rdb = shift;
  return
    @_ ? 
      wantarray ? map { $rdb->{'pos'}{$_} } @_ : $rdb->{'pos'}{$_[0]} :
	%{$rdb->{'pos'}};
}

=item vars

Returns the names of the header variables.

=cut

sub vars
{
  @_ == 1 or croak 'usage : $rdb->vars;';

  my $rdb = shift;

  return keys %{$rdb->{hdrvars}};
}


=item getvar( $var )

Returns the value of the header variable I<$var> if it exists.
Otherwise it returns C<undef>.

=cut

sub getvar
{
  @_ == 2 or croak 'usage : $rdb->getvar( $var )';

  my ( $rdb, $var ) = @_;

  return $rdb->{hdrvars}{$var};
}

=item getvars

Returns a reference to an hash containing all of the header 
variables.

=cut

sub getvars
{
  @_ == 1 or croak 'usage : $rdb->getvars';

  my $rdb = shift;

  return { %{$rdb->{hdrvars}} };
}

=item setvar( $var, $value )

Set the header variable I<$var> to I<$value>.  The variable is
created if it doesn't exist.

=cut

sub setvar
{
  @_ == 3 or croak 'usage : $rdb->setvar( $var, $value )';

  my ( $rdb, $var, $value ) = @_;
  $rdb->{hdrvars}{$var} = $value;
}

=item delvar( $var )

Delete the header variable I<$var>.  This also deletes the header comment
line which defines it.

=cut

sub delvar
{
  @_ == 2 or croak 'usage : $rdb->delvar( $var )';

  my ( $rdb, $var ) = @_;
  delete $rdb->{hdrvars}{$var};

  # delete from the comments list
  $rdb->{comments} = [ grep { !( /^:\s*(\w+)\s*=/ && $1 eq $var ) }
                       @{$rdb->{comments}} ];
}



=item type( [ $name | @names ] )

If called with no arguments, C<type> returns a hash containing the
column types, keyed off of the column names.  The optional arguments
are names of columns for which to return a type.  In a scalar context
it returns the type for the first argument; in an array context it
returns an array of types.  If a column doesn't exist, its type is
given as the undefined value.

	%types = $rdb->type;
	$type_of_col = $rdb->type($col);
        @types{@cols} = $rdb->type(@cols);

=cut
#'
sub type
{
  my $rdb = shift;

  return
    @_ ? 
      (wantarray ? map { $rdb->{defs}{$_}{type} } @_ 
                 : $rdb->{defs}{$_[0]}{type} )
       : map { ($_, $rdb->{defs}{$_}{type}) } @{$rdb->{col}} ;
}

# Expression parsing stuff

use vars qw( %cmpop  %assignop %optype  %mathop %punct %resw
	     %builtin %spec_var %spec_defs );

# comparison operators
%cmpop =
  (
   N => {
	 'lt' => '<',
	 'le' => '<=',
	 'gt' => '>',
	 'ge' => '>=',
	 'eq' => '==',
	 'ne' => '!=',
	 'mat' => '=~',
	 'nmat' => '!~',
	 # not really a comparison operator, but it works better here
	 'subst' => 's',
	},
   S => {
	 'lt' => 'lt',
	 'le' => 'le',
	 'gt' => 'gt',
	 'ge' => 'ge',
	 'eq' => 'eq',
	 'ne' => 'ne',
	 'mat' => '=~',
	 'nmat' => '!~',
	 # not really a comparison operator, but it works better here
	 'subst' => 's',
	}
	  );

%assignop = 
  (
   '='   => { op => '=',   type => ''  },
   '-='  => { op => '-=',  type => 'N' },
   '+='  => { op => '+=',  type => 'N' },
   '*='  => { op => '*=',  type => 'N' },
   '/='  => { op => '/=',  type => 'N' },
   '<<=' => { op => '<<=', type => 'N' },
   '>>=' => { op => '>>=', type => 'N' },
   '%='  => { op => '%=',  type => 'N' },
   '.='  => { op => '.=',  type => 'S' },
   '=~'  => { op => '=~',  type => 'N' },
  );

%mathop = map { $_, $_ } qw( - + * / << >> && || & ^ ? : % ** . <=> );

%punct = map { $_, $_ } ( '(', ')', ',', ';', '{', '}' );
$punct{'{'} = "{\n";
$punct{'}'} = "}\n";
$punct{';'} = ";\n";

# reserved words
%resw  = 
  (
   'or'     => '||',
   'and'    => '&&',
   'null'   => '""',
   'any'    => '$_',
   'if'     => 'if',
   'else'   => 'else',
   'elsif'  => 'elsif',
   'unless' => 'unless'
  );

%builtin = 
  (
   # builtin functions that take a numeric argument
   ( map { $_ => { func => $_, type => 'N' } }
     qw( abs atan2 cos exp hex int log oct rand sin sqrt )), 
   
   # builtin functions that take a string argument
   ( map { $_ => { func => $_, type => 'S' } } 
     qw( lc uc sprintf ) ) 
  );

# special "force type" functions
$builtin{ '_fX'} = { func =>'', type => 'X' };
$builtin{ '_fN'} = { func =>'', type => 'N' };
$builtin{ '_fS'} = { func =>'', type => 'S' };

%spec_var  = ( _NR => '$.' );
%spec_defs = ( '$.' => 'N' );

=item expr( I<reference> or I<string> )

B<This is deprecated and will be removed in the future.>

Given an rdb expression (see the B<rdb_expr> documentation), it
returns a string which evaluates the expression.  If passed a
reference, the reference must be to an array of tokens.  If passed a
scalar, the scalar is parsed into tokens.  Note that the whitespace
requirements for the passed scalar is the same as that in the
B<rdb_expr> documentation.

The returned expression assumes that an input row of the RDB
table is available in the C<F> list.

For example, given the following RDB table,

  Name    Address Zip
  S       S       N
  me      here    20
  you     there   30

the function call

  print $rdb->expr( 'Name eq "Bill plus jane" and Zip eq 3' );

produces the following B<eval>'able string.

  $F[0] eq 'Bill plus jane' && $F[2] == 3

=cut
#'
sub expr
{
  @_ >= 2 or croak 'usage : $rdb->expr( \@args ) or $rdb->expr( $string )';
  my ($rdb, $args) = @_;
  my ( $defs ) = $rdb->{'defs'};
  my ( $pos ) = $rdb->{'pos'};
  my ( @args, $arg, $oper_type, $pcol, $poper, $expect_type );

  if ( ! ref( $args ) )
  {
    require 'shellwords.pl';
    @args = shellwords( $args );
    $args = \@args;
  }
  elsif ( 'ARRAY' ne ref( $args ) )
  {
    croak 'usage : $rdb->expr( \@args ) or $rdb->expr( $string )';
  }

  for $arg ( @$args )
  {
    if ( $$defs{$arg} )
    {
      $poper = "COL" ;
      $pcol = $arg ;	# prev col name
      $oper_type = ( $$defs{$arg} =~ /(\S+)/i && $1 =~ /N/i ) ? 'N' : 'S';
      $arg = '$F[' . $$pos{$arg} . ']' ;
      next;
    }

    if ( $arg =~ /^_/ && defined $spec_var{$arg} )
    {
      $arg = $spec_var{$arg} ;
      
      # numerical data flag
      $oper_type = ($spec_defs{$arg} =~ /(\S+)/ && $1 =~ /N/i ) ? 'N' : 'S';
      next;
    }

    # cmp oper
    if( $cmpop{N}{$arg} || $cmpop{S}{$arg})
    {
      $poper = "CMP";		# prev oper, for next cycle

      if ( $arg =~ /mat$/ )
      {
	carp "Warning, Pattern Match on numeric column ($pcol)\n"
	  if $oper_type eq 'N';
	$poper = "CMPM";
      }

      $arg = $cmpop{ $oper_type ? $oper_type : 'N'}{$arg};

      next;
    }

    # reserved word 
    if( $resw{$arg} )
    {
      $arg = $resw{$arg} ;
      $poper = "RES" ;
      next;
      $oper_type = '' ;
    }

    if ( $builtin{$arg} )
    {
      $oper_type = $builtin{$arg}->{type} ;
      $poper = "FUNC" ;
      $arg = $builtin{$arg}->{func};
      next;
    }

    if ( $assignop{$arg} )
    {
      $expect_type = $assignop{$arg}->{type};
      $arg = $assignop{$arg}->{op};
      # make up for ambiguity of '=' op by using previous operand type,
      # if available
      $expect_type = $oper_type if $arg eq '=';
      $poper = "OP";
      $oper_type = '' ;
      next;
    }

    if( $punct{$arg} )
    {
      $arg = $punct{$arg};
      next;
    }

    if( $mathop{$arg} )
    {
      $arg = $mathop{$arg};
      $poper = "OP" ;
      $oper_type = '' ;
      next;
    }

    # if it begins with a '$', assume it's a local Perl variable,
    # and leave it alone
    if ( '$' eq substr( $arg, 0, 1 ) ) #'
    {
      $poper = "VAL";
      $oper_type = '';
      next;
    }

    # numeric data
    if ( $oper_type eq 'N' )
    {
      # it's supposed to be numerical, but if it's not, make it a string
      if ( _is_numeric( $arg ) )
      {
	_handle_numeric( \$arg, \$poper );
      }
      else
      {
	_handle_string( \$arg, \$poper );
      }
      $oper_type = '';
      next;
    }

    # string data stick it in quotes
    if ( $oper_type eq 'S' )
    {
      _handle_string( \$arg, \$poper );
      $oper_type = '';
      next;
    }

    # as-is
    if ( $oper_type eq 'X' )
    {
      next;
    }

    # this data didn't follow a comparison operator (probably
    # from an assignment expression).  If it's a number, assume
    # it's not a string.
    # first ensure there's not a string assignment operator
    if ( $expect_type ne 'S' && _is_numeric( $arg ) )
    {
      _handle_numeric( \$arg, \$poper );
      $oper_type = 'N';
      next;
    }

    # everything else is assumed to be a string
    _handle_string( \$arg, \$poper );
    $poper = "VAL" ;
    $oper_type = 'S';

  }

  return join( ' ', @args );
}

sub _is_numeric
{
  my ( $arg ) = @_;

  $arg =~ /^[+-]?(\d+[.]?\d*|[.]\d+)([eE][+-]?\d+)?$/;
}

sub _handle_string
{
  my ( $arg, $poper ) = @_;
  # if the last operand was a match, don't quote it
  if ( $$poper ne 'CMPM' )
  {
    # if the first character in the string is a `\',
    # it's been put there to escape the second character.
    # this isn't a means of escaping control characters, but
    # to avoid recognition as a column name or local variable
    # we need to remove it
    $$arg =~ s/^[\\]//;
    $$arg =~ s/[\\]?([\'])/\\$1/g;
    $$arg = "'$$arg'" ;
  }
  $$poper = "VAL" ;
}

sub _handle_numeric
{
  my ( $arg, $poper ) = @_;

  # remove any leading zeros as they'll be interpreted
  # as octal
  $$arg =~ s/^0+([1-9]+)/$1/;
  $$poper = "VAL" ;
}

=back

=head1 AUTHOR

Diab Jerius ( djerius@cfa.harvard.edu )

=cut

1;
